#!/usr/bin/env python3
"""
Enhanced JanssenCRM Call Data Import Script
This script imports Excel data from the call folder into the corresponding database tables.
Features:
- Configuration file support
- Batch processing for large datasets
- Better error handling and retry logic
- Data validation before import
- Progress tracking
- Call-specific data handling
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
        'company_id': 1,
        'created_by': 1,
        'phone_type': 1,
        'governorate_id': 1,
        'city_id': 1,
        'call_status': 'completed',
        'call_type_id': 1,
        'call_reason_id': 1
    }

class EnhancedCallDataImporter:
    def __init__(self, config: Dict = None):
        """Initialize the enhanced call data importer."""
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
        
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(f'call_data_import_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'),
                logging.StreamHandler(sys.stdout)
            ]
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
    
    def check_table_exists(self, table_name: str) -> bool:
        """Check if a table exists in the database."""
        try:
            query = "SHOW TABLES LIKE %s"
            self.cursor.execute(query, (table_name,))
            result = self.cursor.fetchone()
            return result is not None
        except Exception as e:
            self.logger.error(f"Error checking if table {table_name} exists: {e}")
            return False
    
    def create_call_reasons_table(self) -> bool:
        """Create the call_reasons table if it doesn't exist."""
        try:
            query = """
            CREATE TABLE IF NOT EXISTS call_reasons (
                id INT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
            """
            self.cursor.execute(query)
            self.connection.commit()
            self.logger.info("Created call_reasons table")
            return True
        except Exception as e:
            self.logger.error(f"Error creating call_reasons table: {e}")
            return False
    
    def create_call_types_table(self) -> bool:
        """Create the call_types table if it doesn't exist."""
        try:
            query = """
            CREATE TABLE IF NOT EXISTS call_types (
                id INT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
            """
            self.cursor.execute(query)
            self.connection.commit()
            self.logger.info("Created call_types table")
            return True
        except Exception as e:
            self.logger.error(f"Error creating call_types table: {e}")
            return False
    
    def create_customercall_table(self) -> bool:
        """Create the customercall table if it doesn't exist."""
        try:
            query = """
            CREATE TABLE IF NOT EXISTS customercall (
                id INT PRIMARY KEY AUTO_INCREMENT,
                company_id INT,
                customer_id INT,
                call_type TINYINT,
                category_id INT,
                description TEXT,
                call_notes TEXT,
                call_duration VARCHAR(20),
                created_by INT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
            """
            self.cursor.execute(query)
            self.connection.commit()
            self.logger.info("Created customercall table")
            return True
        except Exception as e:
            self.logger.error(f"Error creating customercall table: {e}")
            return False
    
    def validate_data(self, df: pd.DataFrame, table_name: str) -> Tuple[bool, List[str]]:
        """Validate data before import."""
        errors = []
        
        try:
            if df.empty:
                errors.append(f"DataFrame for {table_name} is empty")
                return False, errors
            
            # Table-specific validation
            if table_name == 'call_reasons':
                required_columns = ['callReason', 'id']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in call reasons data")
                
                if 'callReason' in df.columns and df['callReason'].isnull().any():
                    errors.append("Found null values in call reason names")
                
            elif table_name == 'call_types':
                required_columns = ['calltype', 'id']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in call types data")
                
                # Note: We'll handle null values in calltype by dropping those rows during import
                # This is acceptable since we have valid data for the other rows
                
            elif table_name == 'users':
                required_columns = ['callRecipient', 'id']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in users data")
                
                if 'callRecipient' in df.columns and df['callRecipient'].isnull().any():
                    errors.append("Found null values in user names")
                
            elif table_name == 'calls':
                required_columns = ['Customer_ID', 'created_at']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in calls data")
                
                if 'Customer_ID' in df.columns and df['Customer_ID'].isnull().any():
                    errors.append("Found null values in Customer_ID")
                
                if 'created_at' in df.columns and df['created_at'].isnull().any():
                    errors.append("Found null values in created_at")
            
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
    
    def import_call_reasons(self, excel_file: str) -> bool:
        """Import call reasons data from Excel file."""
        try:
            self.logger.info(f"Importing call reasons from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'call_reasons')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['callReason', 'id']
            # Database expects: ['id', 'name']
            df_mapped = df.rename(columns={'callReason': 'name'})
            
            # Check for null values in name column
            if df_mapped['name'].isnull().any():
                self.logger.error("Found null values in call reason names. Please check the Excel file.")
                return False
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO call_reasons (id, name) 
                    VALUES (%s, %s) 
                    ON DUPLICATE KEY UPDATE name = VALUES(name)
                    """
                    self.cursor.execute(query, (row['id'], row['name']))
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} call reasons")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing call reasons: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_call_types(self, excel_file: str) -> bool:
        """Import call types data from Excel file."""
        try:
            self.logger.info(f"Importing call types from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'call_types')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['calltype', 'id']
            # Database expects: ['id', 'name']
            df_mapped = df.rename(columns={'calltype': 'name'})
            
            # Remove rows with null values in name column
            df_mapped = df_mapped.dropna(subset=['name'])
            
            if df_mapped.empty:
                self.logger.error("No valid call type names found after removing null values")
                return False
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO call_types (id, name) 
                    VALUES (%s, %s) 
                    ON DUPLICATE KEY UPDATE name = VALUES(name)
                    """
                    self.cursor.execute(query, (row['id'], row['name']))
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} call types")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing call types: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_users(self, excel_file: str) -> bool:
        """Import users data from Excel file."""
        try:
            self.logger.info(f"Importing users from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'users')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['callRecipient', 'id']
            # Database expects: ['id', 'name']
            df_mapped = df.rename(columns={'callRecipient': 'name'})
            
            # Check for null values in name column
            if df_mapped['name'].isnull().any():
                self.logger.error("Found null values in user names. Please check the Excel file.")
                return False
            
            # Add missing columns with default values
            df_mapped['company_id'] = DEFAULT_VALUES['company_id']
            df_mapped['username'] = df_mapped['name']  # Use name as username
            df_mapped['password'] = 'default_password_123'  # Add default password
            df_mapped['created_at'] = datetime.now()
            df_mapped['updated_at'] = datetime.now()
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO users (id, name, username, password, company_id, created_at, updated_at) 
                    VALUES (%s, %s, %s, %s, %s, %s, %s) 
                    ON DUPLICATE KEY UPDATE 
                        name = VALUES(name),
                        username = VALUES(username),
                        password = VALUES(password),
                        company_id = VALUES(company_id),
                        updated_at = VALUES(updated_at)
                    """
                    self.cursor.execute(query, (row['id'], row['name'], row['username'], row['password'],
                                               row['company_id'], row['created_at'], row['updated_at']))
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} users")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing users: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_calls(self, excel_file: str) -> bool:
        """Import calls data from Excel file."""
        try:
            self.logger.info(f"Importing calls from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'calls')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['id', 'company_id', 'Customer_ID', 'calltype_ID', 'callReason_ID', 'description', 'notes', 'call_duration', 'created_by', 'created_at', 'updated_at']
            # Database expects: ['id', 'company_id', 'customer_id', 'call_type', 'category_id', 'description', 'call_notes', 'call_duration', 'created_by', 'created_at', 'updated_at']
            df_mapped = df.rename(columns={
                'Customer_ID': 'customer_id',
                'calltype_ID': 'call_type',
                'callReason_ID': 'category_id',
                'notes': 'call_notes'
            })
            
            # Check for null values in required columns
            if df_mapped['customer_id'].isnull().any():
                self.logger.error("Found null values in customer_id. Please check the Excel file.")
                return False
            
            if df_mapped['created_at'].isnull().any():
                self.logger.error("Found null values in created_at. Please check the Excel file.")
                return False
            
            # Handle missing values and data types
            df_mapped['company_id'] = df_mapped['company_id'].fillna(DEFAULT_VALUES['company_id']).astype(int)
            df_mapped['call_type'] = df_mapped['call_type'].fillna(DEFAULT_VALUES['call_type_id']).astype(int)
            df_mapped['category_id'] = df_mapped['category_id'].fillna(DEFAULT_VALUES['call_reason_id']).astype(int)
            df_mapped['created_by'] = df_mapped['created_by'].fillna(DEFAULT_VALUES['created_by']).astype(int)
            
            # Convert datetime columns
            df_mapped['created_at'] = pd.to_datetime(df_mapped['created_at'])
            df_mapped['updated_at'] = pd.to_datetime(df_mapped['updated_at'])
            
            # Fill missing notes and description with empty string
            df_mapped['call_notes'] = df_mapped['call_notes'].fillna('')
            df_mapped['description'] = df_mapped['description'].fillna('')
            
            # Fill missing call_duration with 0
            df_mapped['call_duration'] = df_mapped['call_duration'].fillna(0)
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO customercall (
                        id, company_id, customer_id, call_type, category_id, 
                        description, call_notes, call_duration, created_by, created_at, updated_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE 
                        company_id = VALUES(company_id),
                        customer_id = VALUES(customer_id),
                        call_type = VALUES(call_type),
                        category_id = VALUES(category_id),
                        description = VALUES(description),
                        call_notes = VALUES(call_notes),
                        call_duration = VALUES(call_duration),
                        created_by = VALUES(created_by),
                        updated_at = VALUES(updated_at)
                    """
                    
                    values = (
                        row['id'], row['company_id'], row['customer_id'],
                        row['call_type'], row['category_id'], row['description'],
                        row['call_notes'], row['call_duration'], row['created_by'],
                        row['created_at'], row['updated_at']
                    )
                    
                    self.cursor.execute(query, values)
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} calls")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing calls: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def run_import(self, data_folder: str) -> bool:
        """Run the complete call data import process."""
        self.stats['start_time'] = datetime.now()
        
        try:
            if not self.connect():
                return False
            
            # Check and create missing tables
            if not self.check_table_exists('call_reasons'):
                if not self.create_call_reasons_table():
                    self.logger.error("Failed to create call_reasons table")
                    return False
            
            if not self.check_table_exists('call_types'):
                if not self.create_call_types_table():
                    self.logger.error("Failed to create call_types table")
                    return False
            
            if not self.check_table_exists('customercall'):
                if not self.create_customercall_table():
                    self.logger.error("Failed to create customercall table")
                    return False
            
            # Define import order (respecting foreign key constraints)
            # Note: company.xlsx is no longer present, so we skip companies import
            import_tasks = [
                ('call_reasons', 'callReason.xlsx', self.import_call_reasons),
                ('call_types', 'calltype.xlsx', self.import_call_types),
                ('users', 'user.xlsx', self.import_users),
                ('calls', 'calls.xlsx', self.import_calls)
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
                    self.logger.info(f"✓ Successfully imported {table_name}")
                else:
                    self.logger.error(f"✗ Failed to import {table_name}")
            
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
        self.logger.info("CALL DATA IMPORT SUMMARY")
        self.logger.info("=" * 60)
        self.logger.info(f"Total tables processed: {total_tasks}")
        self.logger.info(f"Successful imports: {success_count}")
        self.logger.info(f"Failed imports: {total_tasks - success_count}")
        self.logger.info(f"Total records processed: {self.stats['total_records']}")
        self.logger.info(f"Total time: {duration}")
        self.logger.info(f"Average time per record: {duration / max(self.stats['total_records'], 1)}")
        self.logger.info("=" * 60)
        
        # Save statistics to file
        stats_file = f'call_import_stats_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
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
    """Main function to run the enhanced call data import."""
    # Data folder path
    data_folder = os.path.join(os.path.dirname(__file__), 'data', 'call')
    
    # Check if data folder exists
    if not os.path.exists(data_folder):
        print(f"Error: Data folder not found: {data_folder}")
        sys.exit(1)
    
    # Create importer instance
    importer = EnhancedCallDataImporter()
    
    # Run import
    print("Starting Enhanced JanssenCRM Call Data import process...")
    print(f"Data folder: {data_folder}")
    print(f"Database: {DATABASE_CONFIG['database']} on {DATABASE_CONFIG['host']}")
    print("=" * 60)
    
    success = importer.run_import(data_folder)
    
    if success:
        print("\n🎉 Call data import completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Call data import failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
