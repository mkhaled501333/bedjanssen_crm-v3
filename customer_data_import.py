#!/usr/bin/env python3
"""
Enhanced JanssenCRM Data Import Script
This script imports Excel data from the customer folder into the corresponding database tables.
Features:
- Configuration file support
- Batch processing for large datasets
- Better error handling and retry logic
- Data validation before import
- Progress tracking
"""

import pandas as pd
import mysql.connector
from mysql.connector import Error
import os
import sys
from datetime import datetime
import logging
import time
from typing import Dict, List, Tuple, Optional
import json

# Import configuration
try:
    from config import DATABASE_CONFIG, IMPORT_SETTINGS, DEFAULT_VALUES # type: ignore
except ImportError:
    print("Warning: config.py not found. Using default values.")
    DATABASE_CONFIG = {
        'host': 'localhost',
        'user': 'root',
        'password': 'Admin@1234',
        'database': 'janssencrm',
        'port': 3306,
        'charset': 'utf8mb4',
        'collation': 'utf8mb4_unicode_ci'
    }
    IMPORT_SETTINGS = {
        'batch_size': 1000,
        'max_retries': 3,
        'log_level': 'INFO'
    }
    DEFAULT_VALUES = {
        'company_id': 0,
        'created_by': 0,
        'phone_type': 0,
        'governorate_id': 0,
        'city_id': 0
    }

class EnhancedJanssenCRMDataImporter:
    def __init__(self, config: Dict = None):
        """Initialize the enhanced data importer."""
        self.config = config or DATABASE_CONFIG
        self.connection = None
        self.cursor = None
        self.stats = {
            'total_records': 0,
            'successful_imports': 0,
            'failed_imports': 0,
            'start_time': None,
            'end_time': None
        }
        
        # Setup logging
        self._setup_logging()
        
    def _setup_logging(self):
        """Setup logging configuration."""
        log_level = getattr(logging, IMPORT_SETTINGS['log_level'])
        
        # Create formatter
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        
        # Create file handler with UTF-8 encoding
        file_handler = logging.FileHandler(
            f'data_import_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log',
            encoding='utf-8'
        )
        file_handler.setFormatter(formatter)
        
        # Create console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(formatter)
        
        # Configure root logger
        logging.basicConfig(
            level=log_level,
            handlers=[file_handler, console_handler]
        )
        self.logger = logging.getLogger(__name__)
        
    def connect(self) -> bool:
        """Establish database connection with retry logic."""
        for attempt in range(IMPORT_SETTINGS['max_retries']):
            try:
                self.connection = mysql.connector.connect(**self.config)
                self.cursor = self.connection.cursor()
                self.logger.info("Successfully connected to database")
                return True
            except Error as e:
                self.logger.warning(f"Connection attempt {attempt + 1} failed: {e}")
                if attempt < IMPORT_SETTINGS['max_retries'] - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff
                else:
                    self.logger.error(f"Failed to connect after {IMPORT_SETTINGS['max_retries']} attempts")
                    return False
        return False
    
    def disconnect(self):
        """Close database connection."""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        self.logger.info("Database connection closed")
    
    def validate_data(self, df: pd.DataFrame, table_name: str) -> Tuple[bool, List[str]]:
        """Validate data before import."""
        errors = []
        
        try:
            if df.empty:
                errors.append(f"DataFrame for {table_name} is empty")
                return False, errors
            
            # Table-specific validation
            if table_name == 'governorates':
                required_columns = ['governorate', 'id']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in governorates data")
                
                if 'governorate' in df.columns and df['governorate'].isnull().any():
                    errors.append("Found null values in governorate names")
                
            elif table_name == 'cities':
                required_columns = ['areas', 'id', 'id_governorates']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in cities data")
                
                if 'areas' in df.columns and df['areas'].isnull().any():
                    errors.append("Found null values in city names")
                
            elif table_name == 'customers':
                required_columns = ['cusotmerName', 'id_governorates', 'id_city', 'adress']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in customers data")
                
                if 'cusotmerName' in df.columns and df['cusotmerName'].isnull().any():
                    errors.append("Found null values in customer names")
                
            elif table_name == 'customer_phones':
                required_columns = ['customer_id', 'mobilenum']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in customer phones data")
                
                if 'customer_id' in df.columns and df['customer_id'].isnull().any():
                    errors.append("Found null values in customer_id")
                
                if 'mobilenum' in df.columns:
                    # Check for extremely long phone numbers
                    phone_lengths = df['mobilenum'].astype(str).str.len()
                    if phone_lengths.max() > 50:  # Reasonable max length
                        errors.append("Found extremely long phone numbers (max length > 50)")
            
            # General validation
            if 'id' in df.columns and df['id'].isnull().any():
                errors.append("Found null values in ID column")
            
            # Check for duplicate IDs
            if 'id' in df.columns:
                duplicate_ids = df[df['id'].duplicated()]['id'].tolist()
                if duplicate_ids:
                    errors.append(f"Found duplicate IDs: {duplicate_ids[:5]}...")  # Show first 5
            
        except Exception as e:
            errors.append(f"Validation error: {str(e)}")
        
        return len(errors) == 0, errors
    
    def import_governorates(self, excel_file: str) -> bool:
        """Import governorates data from Excel file."""
        try:
            self.logger.info(f"Importing governorates from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'governorates')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['governorate', 'id']
            # Database expects: ['id', 'name']
            df_mapped = df.rename(columns={'governorate': 'name'})
            
            # Check for null values in name column
            if df_mapped['name'].isnull().any():
                self.logger.error("Found null values in governorate names. Please check the Excel file.")
                return False
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO governorates (id, name) 
                    VALUES (%s, %s) 
                    ON DUPLICATE KEY UPDATE name = VALUES(name)
                    """
                    self.cursor.execute(query, (row['id'], row['name']))
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} governorates")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing governorates: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_cities(self, excel_file: str) -> bool:
        """Import cities data from Excel file."""
        try:
            self.logger.info(f"Importing cities from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'cities')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['areas', 'id', 'id_governorates']
            # Database expects: ['id', 'name', 'governorate_id']
            df_mapped = df.rename(columns={
                'areas': 'name',
                'id_governorates': 'governorate_id'
            })
            
            # Check for null values in name column
            if df_mapped['name'].isnull().any():
                self.logger.error("Found null values in city names. Please check the Excel file.")
                return False
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO cities (id, name, governorate_id) 
                    VALUES (%s, %s, %s) 
                    ON DUPLICATE KEY UPDATE 
                        name = VALUES(name), 
                        governorate_id = VALUES(governorate_id)
                    """
                    self.cursor.execute(query, (row['id'], row['name'], row['governorate_id']))
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} cities")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing cities: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_customers(self, excel_file: str) -> bool:
        """Import customers data from Excel file."""
        try:
            self.logger.info(f"Importing customers from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'customers')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['cusotmerName', 'id_governorates', 'id_city', 'adress']
            # Database expects: ['name', 'governomate_id', 'city_id', 'address'] (note: database has typo)
            df_mapped = df.rename(columns={
                'cusotmerName': 'name',
                'id_governorates': 'governomate_id',  # Database column name has typo
                'id_city': 'city_id',
                'adress': 'address'
            })
            
            # Check for null values in name column
            if df_mapped['name'].isnull().any():
                self.logger.error("Found null values in customer names. Please check the Excel file.")
                return False
            
            # Handle missing values and data types
            df_mapped['company_id'] = df_mapped['company_id'].fillna(DEFAULT_VALUES['company_id']).astype(int)
            df_mapped['governomate_id'] = df_mapped['governomate_id'].fillna(DEFAULT_VALUES['governorate_id']).astype(int)
            df_mapped['city_id'] = df_mapped['city_id'].fillna(DEFAULT_VALUES['city_id']).astype(int)
            df_mapped['created_by'] = df_mapped['created_by'].fillna(DEFAULT_VALUES['created_by']).astype(int)
            
            # Convert datetime columns
            df_mapped['created_at'] = pd.to_datetime(df_mapped['created_at'])
            df_mapped['updated_at'] = pd.to_datetime(df_mapped['updated_at'])
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO customers (
                        id, company_id, name, governomate_id, city_id, 
                        address, notes, created_by, created_at, updated_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE 
                        company_id = VALUES(company_id),
                        name = VALUES(name),
                        governomate_id = VALUES(governomate_id),
                        city_id = VALUES(city_id),
                        address = VALUES(address),
                        notes = VALUES(notes),
                        created_by = VALUES(created_by),
                        updated_at = VALUES(updated_at)
                    """
                    
                    values = (
                        row['id'], row['company_id'], row['name'], 
                        row['governomate_id'], row['city_id'], row['address'],
                        row['notes'], row['created_by'], row['created_at'], row['updated_at']
                    )
                    
                    self.cursor.execute(query, values)
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} customers")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing customers: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def get_column_info(self, table_name: str, column_name: str) -> Optional[Dict]:
        """Get information about a specific database column."""
        try:
            query = """
            SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE, COLUMN_DEFAULT
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s
            """
            self.cursor.execute(query, (self.config['database'], table_name, column_name))
            result = self.cursor.fetchone()
            
            if result:
                return {
                    'column_name': result[0],
                    'data_type': result[1],
                    'max_length': result[2],
                    'is_nullable': result[3],
                    'default_value': result[4]
                }
            return None
        except Exception as e:
            self.logger.error(f"Error getting column info for {table_name}.{column_name}: {e}")
            return None

    def import_customer_phones(self, excel_file: str) -> bool:
        """Import customer phones data from Excel file."""
        try:
            self.logger.info(f"Importing customer phones from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'customer_phones')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['customer_id', 'mobilenum']
            # Database expects: ['customer_id', 'phone']
            df_mapped = df.rename(columns={
                'customer_id': 'customer_id',
                'mobilenum': 'phone'
            })
            
            # Check for null values in required columns
            if df_mapped['customer_id'].isnull().any():
                self.logger.error("Found null values in customer_id. Please check the Excel file.")
                return False
            
            # Get database column information for phone column
            phone_column_info = self.get_column_info('customer_phones', 'phone')
            if phone_column_info:
                self.logger.info(f"Phone column info: {phone_column_info}")
                max_db_length = phone_column_info.get('max_length', 20)
            else:
                max_db_length = 20  # Default fallback
                self.logger.warning("Could not get phone column info, using default max length of 20")
            
            # Check phone number lengths and truncate if necessary
            phone_lengths = df_mapped['phone'].astype(str).str.len()
            min_length = phone_lengths.min()
            max_length = phone_lengths.max()
            self.logger.info(f"Phone number lengths - Min: {min_length}, Max: {max_length}, DB max: {max_db_length}")
            
            if max_length > max_db_length:
                self.logger.warning(f"Some phone numbers exceed {max_db_length} characters. Truncating to fit database column.")
                df_mapped['phone'] = df_mapped['phone'].astype(str).str[:max_db_length]
                
                # Log some examples of truncated numbers
                long_numbers = df_mapped[phone_lengths > max_db_length]['phone'].head(3)
                if not long_numbers.empty:
                    self.logger.info(f"Examples of truncated numbers: {long_numbers.tolist()}")
            
            # Add missing columns with default values
            df_mapped['company_id'] = DEFAULT_VALUES['company_id']
            df_mapped['phone_type'] = DEFAULT_VALUES['phone_type']
            df_mapped['created_by'] = DEFAULT_VALUES['created_by']
            df_mapped['created_at'] = datetime.now()
            df_mapped['updated_at'] = datetime.now()
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO customer_phones (
                        customer_id, company_id, phone, phone_type, 
                        created_by, created_at, updated_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE 
                        company_id = VALUES(company_id),
                        phone = VALUES(phone),
                        phone_type = VALUES(phone_type),
                        updated_at = VALUES(updated_at)
                    """
                    
                    values = (
                        row['customer_id'], row['company_id'], row['phone'],
                        row['phone_type'], row['created_by'], row['created_at'], row['updated_at']
                    )
                    
                    self.cursor.execute(query, values)
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} customer phones")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing customer phones: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def run_import(self, data_folder: str) -> bool:
        """Run the complete import process."""
        self.stats['start_time'] = datetime.now()
        
        try:
            if not self.connect():
                return False
            
            # Define import order (respecting foreign key constraints)
            import_tasks = [
                ('governorates', 'governorate.xlsx', self.import_governorates),
                ('cities', 'city_id.xlsx', self.import_cities),
                ('customers', 'customers.xlsx', self.import_customers),
                ('customer_phones', 'C_Mobile_id.xlsx', self.import_customer_phones)
            ]
            
            success_count = 0
            total_tasks = len(import_tasks)
            
            for table_name, excel_file, import_func in import_tasks:
                file_path = os.path.join(data_folder, excel_file)
                
                if not os.path.exists(file_path):
                    self.logger.warning(f"Excel file not found: {file_path}")
                    continue
                
                self.logger.info(f"Starting import for {table_name}...")
                if import_func(file_path):
                    success_count += 1
                    self.logger.info(f"[SUCCESS] Successfully imported {table_name}")
                else:
                    self.logger.error(f"[FAILED] Failed to import {table_name}")
            
            self.stats['end_time'] = datetime.now()
            self._print_summary(success_count, total_tasks)
            
            return success_count == total_tasks
            
        except Exception as e:
            self.logger.error(f"Unexpected error during import: {e}")
            return False
        finally:
            self.disconnect()
    
    def _print_summary(self, success_count: int, total_tasks: int):
        """Print import summary and statistics."""
        duration = self.stats['end_time'] - self.stats['start_time']
        
        self.logger.info("=" * 60)
        self.logger.info("IMPORT SUMMARY")
        self.logger.info("=" * 60)
        self.logger.info(f"Total tables processed: {total_tasks}")
        self.logger.info(f"Successful imports: {success_count}")
        self.logger.info(f"Failed imports: {total_tasks - success_count}")
        self.logger.info(f"Total records processed: {self.stats['total_records']}")
        self.logger.info(f"Total time: {duration}")
        self.logger.info(f"Average time per record: {duration / max(self.stats['total_records'], 1)}")
        self.logger.info("=" * 60)
        
        # Save statistics to file
        stats_file = f'import_stats_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
        with open(stats_file, 'w', encoding='utf-8') as f:
            json.dump({
                'success_count': success_count,
                'total_tasks': total_tasks,
                'total_records': self.stats['total_records'],
                'start_time': self.stats['start_time'].isoformat(),
                'end_time': self.stats['end_time'].isoformat(),
                'duration_seconds': duration.total_seconds()
            }, f, indent=2, ensure_ascii=False)
        
        self.logger.info(f"Statistics saved to: {stats_file}")

def main():
    """Main function to run the enhanced data import."""
    # Data folder path
    data_folder = os.path.join(os.path.dirname(__file__), 'data', 'cutomer')
    
    # Check if data folder exists
    if not os.path.exists(data_folder):
        print(f"Error: Data folder not found: {data_folder}")
        sys.exit(1)
    
    # Create importer instance
    importer = EnhancedJanssenCRMDataImporter()
    
    # Run import
    print("Starting Enhanced JanssenCRM data import process...")
    print(f"Data folder: {data_folder}")
    print(f"Database: {DATABASE_CONFIG['database']} on {DATABASE_CONFIG['host']}")
    print("=" * 60)
    
    success = importer.run_import(data_folder)
    
    if success:
        print("\n[SUCCESS] Data import completed successfully!")
        sys.exit(0)
    else:
        print("\n[FAILED] Data import failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
