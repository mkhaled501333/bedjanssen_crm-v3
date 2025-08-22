#!/usr/bin/env python3
"""
Enhanced JanssenCRM Requests Data Import Script
This script imports Excel data from the requests folder into the corresponding database tables.
Features:
- Configuration file support
- Batch processing for large datasets
- Better error handling and retry logic
- Data validation before import
- Progress tracking
- Request-specific data handling
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
        'call_reason_id': 1,
        'ticket_status': 1,
        'ticket_priority': 1,
        'request_status': 1,
        'request_priority': 1
    }

class EnhancedRequestsDataImporter:
    def __init__(self, config: Dict = None):
        """Initialize the enhanced requests data importer."""
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
                logging.FileHandler(f'requests_data_import_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'),
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
    
    def safe_int(self, value, default=0):
        """Safely convert a value to integer."""
        if pd.isna(value) or value == '' or str(value).strip() == '':
            return default
        try:
            # Handle string representations of numbers
            if isinstance(value, str):
                value = value.strip()
                if value == '':
                    return default
            return int(float(value))
        except (ValueError, TypeError):
            return default
    

    
    def validate_data(self, df: pd.DataFrame, table_name: str) -> Tuple[bool, List[str]]:
        """Validate data before import."""
        errors = []
        
        try:
            if df.empty:
                errors.append(f"DataFrame for {table_name} is empty")
                return False, errors
            
            # Table-specific validation
            if table_name == 'request_reasons':
                required_columns = ['id']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in request reasons data")
                
            elif table_name == 'product_info':
                required_columns = ['id']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in product info data")
                
            elif table_name == 'ticket_item_maintenance':
                required_columns = ['id']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in ticket item maintenance data")
                
            elif table_name == 'ticket_item_change_same':
                required_columns = ['id']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in ticket item change same data")
                
            elif table_name == 'ticket_items':
                required_columns = ['id']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in ticket items data")

            elif table_name == 'ticket_item_change_another':
                required_columns = ['id']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in ticket item change another data")
            
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
    
    def import_request_reasons(self, excel_file: str) -> bool:
        """Import request reasons data from Excel file (reqreqson.xlsx)."""
        try:
            self.logger.info(f"Importing request reasons from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'request_reasons')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['reqreqson', 'id']
            # Database expects: ['id', 'name', 'created_by', 'company_id', 'created_at', 'updated_at']
            
            # Rename columns to match database structure
            df = df.rename(columns={'reqreqson': 'name'})
            
            # Add missing columns with default values
            df['created_by'] = DEFAULT_VALUES['created_by']
            df['company_id'] = DEFAULT_VALUES['company_id']
            df['created_at'] = datetime.now()
            df['updated_at'] = datetime.now()
            
            # Fill missing values
            df['name'] = df['name'].fillna('Unknown')
            
            # Process in batches
            total_records = int(len(df))
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO request_reasons (id, name, created_by, company_id, created_at, updated_at) 
                    VALUES (%s, %s, %s, %s, %s, %s) 
                    ON DUPLICATE KEY UPDATE 
                        name = VALUES(name),
                        created_by = VALUES(created_by),
                        company_id = VALUES(company_id),
                        updated_at = VALUES(updated_at)
                    """
                    self.cursor.execute(query, (int(row['id']), str(row['name']), 
                                               int(row['created_by']), int(row['company_id']), row['created_at'], row['updated_at']))
                
                self.connection.commit()
                batch_num = i//IMPORT_SETTINGS['batch_size'] + 1
                total_batches = (total_records-1)//IMPORT_SETTINGS['batch_size'] + 1
                self.logger.info(f"Processed batch {batch_num}/{total_batches}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} request reasons")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing request reasons: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_product_info(self, excel_file: str) -> bool:
        """Import product info data from Excel file (ProductName.xlsx)."""
        try:
            self.logger.info(f"Importing product info from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'product_info')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['pfodcut.ProductName', 'id']
            # Database expects: ['id', 'company_id', 'product_name', 'created_by', 'created_at', 'updated_at']
            
            # Rename columns to match database structure
            df = df.rename(columns={'pfodcut.ProductName': 'product_name'})
            
            # Add missing columns with default values
            df['company_id'] = DEFAULT_VALUES['company_id']
            df['created_by'] = DEFAULT_VALUES['created_by']
            df['created_at'] = datetime.now()
            df['updated_at'] = datetime.now()
            
            # Fill missing values
            df['product_name'] = df['product_name'].fillna('Unknown Product')
            
            # Process in batches
            total_records = int(len(df))
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO product_info (id, company_id, product_name, created_by, created_at, updated_at) 
                    VALUES (%s, %s, %s, %s, %s, %s) 
                    ON DUPLICATE KEY UPDATE 
                        company_id = VALUES(company_id),
                        product_name = VALUES(product_name),
                        created_by = VALUES(created_by),
                        updated_at = VALUES(updated_at)
                    """
                    self.cursor.execute(query, (int(row['id']), int(row['company_id']), str(row['product_name']),
                                               int(row['created_by']), row['created_at'], row['updated_at']))
                
                self.connection.commit()
                batch_num = i//IMPORT_SETTINGS['batch_size'] + 1
                total_batches = (total_records-1)//IMPORT_SETTINGS['batch_size'] + 1
                self.logger.info(f"Processed batch {batch_num}/{total_batches}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} product info records")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing product info: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_ticket_item_maintenance(self, excel_file: str) -> bool:
        """Import ticket item maintenance data from Excel file (TI_Maintenance.xlsx)."""
        try:
            self.logger.info(f"Importing ticket item maintenance from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'ticket_item_maintenance')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['id', 'company_id', 'product_id', 'product_size', 'pfodcut.ProdcutType', 'maintainace', 'maintanancedescription', 'cost3', 'choice4Accetp', 'choice4refuse', 'choice4refusereason', 'pulled3', 'pulledDate3', 'deleverd3', 'deleverdDate3', 'finalDicition', 'colsedMantananceReq', 'colsedMantananceReqreason', 'create_at', 'update_at', 'create_by']
            # Database expects: ['ticket_item_id', 'maintenance_steps', 'maintenance_cost', 'client_approval', 'refusal_reason', 'pulled', 'pull_date', 'delivered', 'delivery_date', 'created_by', 'company_id']
            
            # Map Excel columns to database columns
            df = df.rename(columns={
                'id': 'ticket_item_id',
                'maintanancedescription': 'maintenance_steps',
                'cost3': 'maintenance_cost',
                'choice4Accetp': 'client_approval',
                'choice4refusereason': 'refusal_reason',
                'pulled3': 'pulled',
                'pulledDate3': 'pull_date',
                'deleverd3': 'delivered',
                'deleverdDate3': 'delivery_date',
                'create_by': 'created_by'
            })
            
            # Add missing columns with default values
            df['company_id'] = df['company_id'].fillna(DEFAULT_VALUES['company_id'])
            df['created_at'] = df['create_at']
            df['updated_at'] = df['update_at']
            
            # Fill missing values
            df['maintenance_cost'] = df['maintenance_cost'].fillna(0.0)
            df['maintenance_steps'] = df['maintenance_steps'].fillna('')
            df['client_approval'] = df['client_approval'].fillna(0)
            df['refusal_reason'] = df['refusal_reason'].fillna('')
            df['pulled'] = df['pulled'].fillna(0)
            df['pull_date'] = df['pull_date'].fillna(pd.NaT)
            df['delivered'] = df['delivered'].fillna(0)
            df['delivery_date'] = df['delivery_date'].fillna(pd.NaT)
            df['created_by'] = df['created_by'].fillna(DEFAULT_VALUES['created_by'])
            
            # Process in batches
            total_records = int(len(df))
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO ticket_item_maintenance (
                        ticket_item_id, maintenance_steps, maintenance_cost, client_approval, 
                        refusal_reason, pulled, pull_date, delivered, delivery_date, 
                        created_by, company_id, created_at, updated_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE 
                        maintenance_steps = VALUES(maintenance_steps),
                        maintenance_cost = VALUES(maintenance_cost),
                        client_approval = VALUES(client_approval),
                        refusal_reason = VALUES(refusal_reason),
                        pulled = VALUES(pulled),
                        pull_date = VALUES(pull_date),
                        delivered = VALUES(delivered),
                        delivery_date = VALUES(delivery_date),
                        updated_at = VALUES(updated_at)
                    """
                    # Convert dates to proper format
                    pull_date = row['pull_date'] if pd.notna(row['pull_date']) else None
                    delivery_date = row['delivery_date'] if pd.notna(row['delivery_date']) else None
                    created_at = row['created_at'] if pd.notna(row['created_at']) else pd.Timestamp.now()
                    updated_at = row['updated_at'] if pd.notna(row['updated_at']) else pd.Timestamp.now()
                    
                    self.cursor.execute(query, (self.safe_int(row['ticket_item_id']), str(row['maintenance_steps']),
                                               float(row['maintenance_cost']), self.safe_int(row['client_approval']), str(row['refusal_reason']),
                                               self.safe_int(row['pulled']), pull_date, self.safe_int(row['delivered']), delivery_date,
                                               self.safe_int(row['created_by'], DEFAULT_VALUES['created_by']), self.safe_int(row['company_id'], DEFAULT_VALUES['company_id']), created_at, updated_at))
                
                self.connection.commit()
                batch_num = i//IMPORT_SETTINGS['batch_size'] + 1
                total_batches = (total_records-1)//IMPORT_SETTINGS['batch_size'] + 1
                self.logger.info(f"Processed batch {batch_num}/{total_batches}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} ticket item maintenance records")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing ticket item maintenance: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_ticket_item_change_same(self, excel_file: str) -> bool:
        """Import ticket item change same data from Excel file (TI_Change_Same.xlsx)."""
        try:
            self.logger.info(f"Importing ticket item change same from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'ticket_item_change_same')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['id', 'company_id', 'product_id', 'product_size', 'pfodcut.ProdcutType', 'replaceToSameModel', 'cost1', 'choice2Accetp', 'choice2refuse', 'create_at', 'update_at', 'create_by', 'choice2refusereason', 'pulled1', 'pulledDate1', 'deleverd1', 'deleverdDate1', 'pfodcut_replace_size2']
            # Database expects: ['ticket_item_id', 'product_id', 'product_size', 'cost', 'client_approval', 'refusal_reason', 'pulled', 'pull_date', 'delivered', 'delivery_date', 'created_by', 'company_id']
            
            # Map Excel columns to database columns
            df = df.rename(columns={
                'id': 'ticket_item_id',
                'product_id': 'product_id',
                'product_size': 'product_size',
                'cost1': 'cost',
                'choice2Accetp': 'client_approval',
                'choice2refusereason': 'refusal_reason',
                'pulled1': 'pulled',
                'pulledDate1': 'pull_date',
                'deleverd1': 'delivered',
                'deleverdDate1': 'delivery_date',
                'create_by': 'created_by'
            })
            
            # Add missing columns with default values
            df['company_id'] = df['company_id'].fillna(DEFAULT_VALUES['company_id'])
            df['created_at'] = df['create_at']
            df['updated_at'] = df['update_at']
            
            # Fill missing values
            df['cost'] = df['cost'].fillna(0.0)
            df['client_approval'] = df['client_approval'].fillna(0)
            df['refusal_reason'] = df['refusal_reason'].fillna('')
            df['pulled'] = df['pulled'].fillna(0)
            df['pull_date'] = df['pull_date'].fillna(pd.NaT)
            df['delivered'] = df['delivered'].fillna(0)
            df['delivery_date'] = df['delivery_date'].fillna(pd.NaT)
            df['created_by'] = df['created_by'].fillna(DEFAULT_VALUES['created_by'])
            
            # Process in batches
            total_records = int(len(df))
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO ticket_item_change_same (
                        ticket_item_id, product_id, product_size, cost, client_approval, 
                        refusal_reason, pulled, pull_date, delivered, delivery_date, 
                        created_by, company_id, created_at, updated_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE 
                        product_id = VALUES(product_id),
                        product_size = VALUES(product_size),
                        cost = VALUES(cost),
                        client_approval = VALUES(client_approval),
                        refusal_reason = VALUES(refusal_reason),
                        pulled = VALUES(pulled),
                        pull_date = VALUES(pull_date),
                        delivered = VALUES(delivered),
                        delivery_date = VALUES(delivery_date),
                        updated_at = VALUES(updated_at)
                    """
                    try:
                        # Convert problematic float values to int explicitly
                        ticket_item_id = int(float(row['ticket_item_id'])) if pd.notna(row['ticket_item_id']) else 0
                        product_id = int(float(row['product_id'])) if pd.notna(row['product_id']) else 0
                        product_size = str(row['product_size']) if pd.notna(row['product_size']) else ''
                        cost = float(row['cost']) if pd.notna(row['cost']) else 0.0
                        client_approval = int(float(row['client_approval'])) if pd.notna(row['client_approval']) else 0
                        refusal_reason = str(row['refusal_reason']) if pd.notna(row['refusal_reason']) else ''
                        pulled = int(float(row['pulled'])) if pd.notna(row['pulled']) else 0
                        pull_date = row['pull_date'] if pd.notna(row['pull_date']) else None
                        delivered = int(float(row['delivered'])) if pd.notna(row['delivered']) else 0
                        delivery_date = row['delivery_date'] if pd.notna(row['delivery_date']) else None
                        created_by = int(float(row['created_by'])) if pd.notna(row['created_by']) else DEFAULT_VALUES['created_by']
                        company_id = int(float(row['company_id'])) if pd.notna(row['company_id']) else DEFAULT_VALUES['company_id']
                        created_at = row['created_at'] if pd.notna(row['created_at']) else pd.Timestamp.now()
                        updated_at = row['updated_at'] if pd.notna(row['updated_at']) else pd.Timestamp.now()

                        params = (ticket_item_id, product_id, product_size, cost, client_approval,
                                 refusal_reason, pulled, pull_date, delivered, delivery_date,
                                 created_by, company_id, created_at, updated_at)

                        self.cursor.execute(query, params)
                    except Exception as e:
                        self.logger.error(f"Error executing query for row {row['ticket_item_id']}: {e}")
                        self.logger.error(f"Converted params: {params}")
                        raise
                
                self.connection.commit()
                batch_num = i//IMPORT_SETTINGS['batch_size'] + 1
                total_batches = (total_records-1)//IMPORT_SETTINGS['batch_size'] + 1
                self.logger.info(f"Processed batch {batch_num}/{total_batches}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} ticket item change same records")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing ticket item change same: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_ticket_item_change_another(self, excel_file: str) -> bool:
        """Import ticket item change another data from Excel file (TI_Change_Another.xlsx)."""
        try:
            self.logger.info(f"Importing ticket item change another from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'ticket_item_change_another')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['id', 'company_id', 'product_id', 'pfodcut.ProdcutType', 'replaceTosnotherModel', 'replaceToBrandName', 'replaceToProdcutName', 'cost2', 'choice3Accetp', 'choice3refuse', 'choice3refusereason', 'pulled2', 'pulledDate2', 'deleverd2', 'deleverdDate2', 'create_at', 'update_at', 'create_by']
            # Database expects: ['ticket_item_id', 'product_id', 'product_size', 'cost', 'client_approval', 'refusal_reason', 'pulled', 'pull_date', 'delivered', 'delivery_date', 'created_by', 'company_id']
            
            # Map Excel columns to database columns
            df = df.rename(columns={
                'id': 'ticket_item_id',
                'product_id': 'product_id',
                'cost2': 'cost',
                'choice3Accetp': 'client_approval',
                'choice3refusereason': 'refusal_reason',
                'pulled2': 'pulled',
                'pulledDate2': 'pull_date',
                'deleverd2': 'delivered',
                'deleverdDate2': 'delivery_date',
                'create_by': 'created_by'
            })
            
            # Add missing columns with default values
            df['company_id'] = df['company_id'].fillna(DEFAULT_VALUES['company_id'])
            df['product_size'] = 'Standard'  # Default size since not in Excel
            df['created_at'] = df['create_at']
            df['updated_at'] = df['update_at']
            
            # Fill missing values
            df['cost'] = df['cost'].fillna(0.0)
            df['client_approval'] = df['client_approval'].fillna(0)
            df['refusal_reason'] = df['refusal_reason'].fillna('')
            df['pulled'] = df['pulled'].fillna(0)
            df['pull_date'] = df['pull_date'].fillna(pd.NaT)
            df['delivered'] = df['delivered'].fillna(0)
            df['delivery_date'] = df['delivery_date'].fillna(pd.NaT)
            df['created_by'] = df['created_by'].fillna(DEFAULT_VALUES['created_by'])
            
            # Process in batches
            total_records = int(len(df))
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO ticket_item_change_another (
                        ticket_item_id, product_id, product_size, cost, client_approval, 
                        refusal_reason, pulled, pull_date, delivered, delivery_date, 
                        created_by, company_id, created_at, updated_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE 
                        product_id = VALUES(product_id),
                        product_size = VALUES(product_size),
                        cost = VALUES(cost),
                        client_approval = VALUES(client_approval),
                        refusal_reason = VALUES(refusal_reason),
                        pulled = VALUES(pulled),
                        pull_date = VALUES(pull_date),
                        delivered = VALUES(delivered),
                        delivery_date = VALUES(delivery_date),
                        updated_at = VALUES(updated_at)
                    """
                    try:
                        # Convert problematic float values to int explicitly
                        ticket_item_id = int(float(row['ticket_item_id'])) if pd.notna(row['ticket_item_id']) else 0
                        product_id = int(float(row['product_id'])) if pd.notna(row['product_id']) else 0
                        product_size = str(row['product_size']) if pd.notna(row['product_size']) else ''
                        cost = float(row['cost']) if pd.notna(row['cost']) else 0.0
                        client_approval = int(float(row['client_approval'])) if pd.notna(row['client_approval']) else 0
                        refusal_reason = str(row['refusal_reason']) if pd.notna(row['refusal_reason']) else ''
                        pulled = int(float(row['pulled'])) if pd.notna(row['pulled']) else 0
                        pull_date = row['pull_date'] if pd.notna(row['pull_date']) else None
                        delivered = int(float(row['delivered'])) if pd.notna(row['delivered']) else 0
                        delivery_date = row['delivery_date'] if pd.notna(row['delivery_date']) else None
                        created_by = int(float(row['created_by'])) if pd.notna(row['created_by']) else DEFAULT_VALUES['created_by']
                        company_id = int(float(row['company_id'])) if pd.notna(row['company_id']) else DEFAULT_VALUES['company_id']
                        created_at = row['created_at'] if pd.notna(row['created_at']) else pd.Timestamp.now()
                        updated_at = row['updated_at'] if pd.notna(row['updated_at']) else pd.Timestamp.now()

                        params = (ticket_item_id, product_id, product_size, cost, client_approval,
                                 refusal_reason, pulled, pull_date, delivered, delivery_date,
                                 created_by, company_id, created_at, updated_at)

                        self.cursor.execute(query, params)
                    except Exception as e:
                        self.logger.error(f"Error executing query for row {row['ticket_item_id']}: {e}")
                        self.logger.error(f"Converted params: {params}")
                        raise
                
                self.connection.commit()
                batch_num = i//IMPORT_SETTINGS['batch_size'] + 1
                total_batches = (total_records-1)//IMPORT_SETTINGS['batch_size'] + 1
                self.logger.info(f"Processed batch {batch_num}/{total_batches}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} ticket item change another records")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing ticket item change another: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False

    def import_ticket_items(self, excel_file: str) -> bool:
        """Import ticket items data from Excel file (ticket_items.xlsx)."""
        try:
            self.logger.info(f"Importing ticket items from {excel_file}")
            df = pd.read_excel(excel_file)

            # Validate data
            is_valid, errors = self.validate_data(df, 'ticket_items')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False

            # Map Excel columns to database columns
            # Excel has: ['id', 'company_id', 'ticket_ID', 'prductuionManagerdecision', 'product_id', 'pfodcut.ProdcutType', 'product_size', 'quantity', 'purchase_date', 'purchase_location', 'request_reason_id', 'request_reason_detail', 'inspected', 'inspected_date', 'inspected_result', 'client_approval', 'create_by', 'create_at', 'update_at']
            # Database has: ['id', 'company_id', 'ticket_id', 'product_id', 'product_size', 'quantity', 'purchase_date', 'purchase_location', 'request_reason_id', 'request_reason_detail', 'inspected', 'inspection_date', 'inspection_result', 'client_approval', 'created_by', 'created_at', 'updated_at']

            # Map Excel columns to database columns (only the ones that exist in DB)
            df = df.rename(columns={
                'ticket_ID': 'ticket_id',
                'inspected_date': 'inspection_date',
                'inspected_result': 'inspection_result',
                'create_by': 'created_by',
                'create_at': 'created_at',
                'update_at': 'updated_at'
            })

            # Add missing columns with default values
            df['company_id'] = df['company_id'].fillna(DEFAULT_VALUES['company_id'])
            df['created_by'] = df['created_by'].fillna(DEFAULT_VALUES['created_by'])

            # Fill missing values
            df['product_size'] = df['product_size'].fillna('')
            df['purchase_location'] = df['purchase_location'].fillna('')
            df['request_reason_detail'] = df['request_reason_detail'].fillna('')
            df['inspection_result'] = df['inspection_result'].fillna('')

            # Process in batches
            total_records = int(len(df))
            self.stats['total_records'] += total_records

            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df.iloc[i:i + IMPORT_SETTINGS['batch_size']]

                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO ticket_items (
                        id, company_id, ticket_id, product_id, product_size, quantity,
                        purchase_date, purchase_location, request_reason_id, request_reason_detail,
                        inspected, inspection_date, inspection_result, client_approval,
                        created_by, created_at, updated_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                        company_id = VALUES(company_id),
                        ticket_id = VALUES(ticket_id),
                        product_id = VALUES(product_id),
                        product_size = VALUES(product_size),
                        quantity = VALUES(quantity),
                        purchase_date = VALUES(purchase_date),
                        purchase_location = VALUES(purchase_location),
                        request_reason_id = VALUES(request_reason_id),
                        request_reason_detail = VALUES(request_reason_detail),
                        inspected = VALUES(inspected),
                        inspection_date = VALUES(inspection_date),
                        inspection_result = VALUES(inspection_result),
                        client_approval = VALUES(client_approval),
                        created_by = VALUES(created_by),
                        updated_at = VALUES(updated_at)
                    """
                    try:
                        # Convert problematic float values to int explicitly
                        ticket_item_id = int(float(row['id'])) if pd.notna(row['id']) else 0
                        company_id = int(float(row['company_id'])) if pd.notna(row['company_id']) else DEFAULT_VALUES['company_id']
                        ticket_id = int(float(row['ticket_id'])) if pd.notna(row['ticket_id']) else 0
                        product_id = int(float(row['product_id'])) if pd.notna(row['product_id']) else 0
                        product_size = str(row['product_size']) if pd.notna(row['product_size']) else ''
                        quantity = int(float(row['quantity'])) if pd.notna(row['quantity']) else 0
                        purchase_date = row['purchase_date'] if pd.notna(row['purchase_date']) else None
                        purchase_location = str(row['purchase_location']) if pd.notna(row['purchase_location']) else ''
                        request_reason_id = int(float(row['request_reason_id'])) if pd.notna(row['request_reason_id']) else 0
                        request_reason_detail = str(row['request_reason_detail']) if pd.notna(row['request_reason_detail']) else ''
                        inspected = int(float(row['inspected'])) if pd.notna(row['inspected']) else 0
                        inspection_date = row['inspection_date'] if pd.notna(row['inspection_date']) else None
                        inspection_result = str(row['inspection_result']) if pd.notna(row['inspection_result']) else ''
                        client_approval = int(float(row['client_approval'])) if pd.notna(row['client_approval']) else 0
                        created_by = int(float(row['created_by'])) if pd.notna(row['created_by']) else DEFAULT_VALUES['created_by']
                        created_at = row['created_at'] if pd.notna(row['created_at']) else pd.Timestamp.now()
                        updated_at = row['updated_at'] if pd.notna(row['updated_at']) else pd.Timestamp.now()

                        params = (ticket_item_id, company_id, ticket_id, product_id, product_size,
                                 quantity, purchase_date, purchase_location, request_reason_id,
                                 request_reason_detail, inspected, inspection_date, inspection_result,
                                 client_approval, created_by, created_at, updated_at)

                        self.cursor.execute(query, params)
                    except Exception as e:
                        self.logger.error(f"Error executing query for row {row['id']}: {e}")
                        self.logger.error(f"Converted params: {params}")
                        raise

                self.connection.commit()
                batch_num = i//IMPORT_SETTINGS['batch_size'] + 1
                total_batches = (total_records-1)//IMPORT_SETTINGS['batch_size'] + 1
                self.logger.info(f"Processed batch {batch_num}/{total_batches}")

            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} ticket items")
            return True

        except Exception as e:
            self.logger.error(f"Error importing ticket items: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False

    def run_import(self, data_folder: str) -> bool:
        """Run the complete requests data import process."""
        self.stats['start_time'] = datetime.now()
        
        try:
            if not self.connect():
                return False
            
            # Check if tables exist
            required_tables = ['request_reasons', 'product_info', 'ticket_items', 'ticket_item_maintenance', 'ticket_item_change_same', 'ticket_item_change_another']
            for table in required_tables:
                if not self.check_table_exists(table):
                    self.logger.error(f"Required table {table} does not exist")
                    return False
            
            # Define import order (respecting foreign key constraints)
            import_tasks = [
                ('request_reasons', 'reqreqson.xlsx', self.import_request_reasons),
                ('product_info', 'ProductName.xlsx', self.import_product_info),
                ('ticket_items', 'ticket_items.xlsx', self.import_ticket_items),
                ('ticket_item_maintenance', 'TI_Maintenance.xlsx', self.import_ticket_item_maintenance),
                ('ticket_item_change_same', 'TI_Change_Same.xlsx', self.import_ticket_item_change_same),
                ('ticket_item_change_another', 'TI_Change_Another.xlsx', self.import_ticket_item_change_another)
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
                    self.logger.info(f"SUCCESS: Successfully imported {table_name}")
                else:
                    self.logger.error(f"FAILED: Failed to import {table_name}")
            
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
        self.logger.info("REQUESTS DATA IMPORT SUMMARY")
        self.logger.info("=" * 60)
        self.logger.info(f"Total tables processed: {total_tasks}")
        self.logger.info(f"Successful imports: {success_count}")
        self.logger.info(f"Failed imports: {total_tasks - success_count}")
        self.logger.info(f"Total records processed: {self.stats['total_records']}")
        self.logger.info(f"Total time: {duration}")
        self.logger.info(f"Average time per record: {duration / max(self.stats['total_records'], 1)}")
        self.logger.info("=" * 60)
        
        # Save statistics to file
        stats_file = f'requests_import_stats_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
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
    """Main function to run the enhanced requests data import."""
    # Data folder path
    data_folder = os.path.join(os.path.dirname(__file__), 'data', 'requests')
    
    # Check if data folder exists
    if not os.path.exists(data_folder):
        print(f"Error: Data folder not found: {data_folder}")
        sys.exit(1)
    
    # Create importer instance
    importer = EnhancedRequestsDataImporter()
    
    # Run import
    print("Starting Enhanced JanssenCRM Requests Data import process...")
    print(f"Data folder: {data_folder}")
    print(f"Database: {DATABASE_CONFIG['database']} on {DATABASE_CONFIG['host']}")
    print("=" * 60)
    
    success = importer.run_import(data_folder)
    
    if success:
        print("\n🎉 Requests data import completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Requests data import failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
