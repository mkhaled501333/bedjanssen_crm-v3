#!/usr/bin/env python3
"""
Enhanced JanssenCRM Ticket Data Import Script
This script imports Excel data from the tickets folder into the corresponding database tables.
Features:
- Configuration file support
- Batch processing for large datasets
- Better error handling and retry logic
- Data validation before import
- Progress tracking
- Ticket-specific data handling
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
        'city_id': 0,
        'call_status': 0,
        'call_type_id': 0,
        'call_reason_id': 0,
        'ticket_status': 0,
        'ticket_priority': 0
    }

class EnhancedTicketDataImporter:
    def __init__(self, config: Dict = None):
        """Initialize the enhanced ticket data importer."""
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
                logging.FileHandler(f'ticket_data_import_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'),
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
    
    def create_call_categories_table(self) -> bool:
        """Create the call_categories table if it doesn't exist."""
        try:
            query = """
            CREATE TABLE IF NOT EXISTS call_categories (
                id INT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                created_by INT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                company_id INT
            )
            """
            self.cursor.execute(query)
            self.connection.commit()
            self.logger.info("Created call_categories table")
            return True
        except Exception as e:
            self.logger.error(f"Error creating call_categories table: {e}")
            return False
    
    def create_ticket_categories_table(self) -> bool:
        """Create the ticket_categories table if it doesn't exist."""
        try:
            query = """
            CREATE TABLE IF NOT EXISTS ticket_categories (
                id INT PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                created_by INT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                company_id INT
            )
            """
            self.cursor.execute(query)
            self.connection.commit()
            self.logger.info("Created ticket_categories table")
            return True
        except Exception as e:
            self.logger.error(f"Error creating ticket_categories table: {e}")
            return False
    
    def create_tickets_table(self) -> bool:
        """Create the tickets table if it doesn't exist."""
        try:
            query = """
            CREATE TABLE IF NOT EXISTS tickets (
                id INT PRIMARY KEY AUTO_INCREMENT,
                company_id INT,
                customer_id INT,
                ticket_cat_id INT,
                description TEXT,
                status TINYINT DEFAULT 1,
                priority TINYINT DEFAULT 1,
                created_by INT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                closed_at DATETIME,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                closing_notes TEXT,
                closed_by INT
            )
            """
            self.cursor.execute(query)
            self.connection.commit()
            self.logger.info("Created tickets table")
            return True
        except Exception as e:
            self.logger.error(f"Error creating tickets table: {e}")
            return False
    
    def create_ticketcall_table(self) -> bool:
        """Create the ticketcall table if it doesn't exist."""
        try:
            query = """
            CREATE TABLE IF NOT EXISTS ticketcall (
                id INT PRIMARY KEY AUTO_INCREMENT,
                company_id INT,
                ticket_id INT,
                call_type TINYINT,
                call_cat_id INT,
                description TEXT,
                call_notes TEXT,
                call_duration VARCHAR(20),
                created_by INT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
            """
            self.cursor.execute(query)
            self.connection.commit()
            self.logger.info("Created ticketcall table")
            return True
        except Exception as e:
            self.logger.error(f"Error creating ticketcall table: {e}")
            return False
    
    def validate_data(self, df: pd.DataFrame, table_name: str) -> Tuple[bool, List[str]]:
        """Validate data before import."""
        errors = []
        
        try:
            if df.empty:
                errors.append(f"DataFrame for {table_name} is empty")
                return False, errors
            
            # Table-specific validation
            if table_name == 'call_categories':
                required_columns = ['callReason', 'callReason_id']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in call categories data")
                
                if 'callReason' in df.columns and df['callReason'].isnull().any():
                    errors.append("Found null values in call reason names")
                
            elif table_name == 'ticket_categories':
                required_columns = ['TicketType', 'TicketType_ID']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in ticket categories data")
                
                if 'TicketType' in df.columns and df['TicketType'].isnull().any():
                    errors.append("Found null values in ticket type names")
                
            elif table_name == 'tickets':
                required_columns = ['id', 'Customer_ID', 'created_at']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in tickets data")
                
                if 'Customer_ID' in df.columns and df['Customer_ID'].isnull().any():
                    errors.append("Found null values in Customer_ID")
                
                if 'created_at' in df.columns and df['created_at'].isnull().any():
                    errors.append("Found null values in created_at")
                
            elif table_name == 'ticket_calls':
                required_columns = ['id', 'ticket_ID', 'datetime']
                for col in required_columns:
                    if col not in df.columns:
                        errors.append(f"Required column '{col}' not found in ticket calls data")
                
                if 'ticket_ID' in df.columns and df['ticket_ID'].isnull().any():
                    errors.append("Found null values in ticket_ID")
                
                if 'datetime' in df.columns and df['datetime'].isnull().any():
                    errors.append("Found null values in datetime")
            
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
    
    def import_call_categories(self, excel_file: str) -> bool:
        """Import call categories data from Excel file (callReason_tickets.xlsx)."""
        try:
            self.logger.info(f"Importing call categories from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'call_categories')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['callReason', 'callReason_id']
            # Database expects: ['id', 'name', 'created_by', 'company_id']
            df_mapped = df.rename(columns={
                'callReason': 'name',
                'callReason_id': 'id'
            })
            
            # Check for null values in name column
            if df_mapped['name'].isnull().any():
                self.logger.error("Found null values in call reason names. Please check the Excel file.")
                return False
            
            # Add missing columns with default values
            df_mapped['created_by'] = DEFAULT_VALUES['created_by']
            df_mapped['company_id'] = DEFAULT_VALUES['company_id']
            df_mapped['created_at'] = datetime.now()
            df_mapped['updated_at'] = datetime.now()
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO call_categories (id, name, created_by, company_id, created_at, updated_at) 
                    VALUES (%s, %s, %s, %s, %s, %s) 
                    ON DUPLICATE KEY UPDATE 
                        name = VALUES(name),
                        created_by = VALUES(created_by),
                        company_id = VALUES(company_id),
                        updated_at = VALUES(updated_at)
                    """
                    self.cursor.execute(query, (row['id'], row['name'], row['created_by'], 
                                               row['company_id'], row['created_at'], row['updated_at']))
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} call categories")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing call categories: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_ticket_categories(self, excel_file: str) -> bool:
        """Import ticket categories data from Excel file (TicketType.xlsx)."""
        try:
            self.logger.info(f"Importing ticket categories from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'ticket_categories')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['TicketType', 'TicketType_ID']
            # Database expects: ['id', 'name', 'created_by', 'company_id']
            df_mapped = df.rename(columns={
                'TicketType': 'name',
                'TicketType_ID': 'id'
            })
            
            # Check for null values in name column
            if df_mapped['name'].isnull().any():
                self.logger.error("Found null values in ticket type names. Please check the Excel file.")
                return False
            
            # Add missing columns with default values
            df_mapped['created_by'] = DEFAULT_VALUES['created_by']
            df_mapped['company_id'] = DEFAULT_VALUES['company_id']
            df_mapped['created_at'] = datetime.now()
            df_mapped['updated_at'] = datetime.now()
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO ticket_categories (id, name, created_by, company_id, created_at, updated_at) 
                    VALUES (%s, %s, %s, %s, %s, %s) 
                    ON DUPLICATE KEY UPDATE 
                        name = VALUES(name),
                        created_by = VALUES(created_by),
                        company_id = VALUES(company_id),
                        updated_at = VALUES(updated_at)
                    """
                    self.cursor.execute(query, (row['id'], row['name'], row['created_by'], 
                                               row['company_id'], row['created_at'], row['updated_at']))
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} ticket categories")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing ticket categories: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_tickets(self, excel_file: str) -> bool:
        """Import tickets data from Excel file (tickets.xlsx)."""
        try:
            self.logger.info(f"Importing tickets from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'tickets')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['id', 'company_id', 'Customer_ID', 'ticket_cat_id', 'description', 'status', 'Ticketresolved', 'notes', 'priority', 'created_by', 'created_at', 'closed_at', 'updated_at']
            # Database expects: ['id', 'company_id', 'customer_id', 'ticket_cat_id', 'description', 'status', 'priority', 'created_by', 'created_at', 'closed_at', 'updated_at', 'closing_notes', 'closed_by']
            df_mapped = df.rename(columns={
                'Customer_ID': 'customer_id'
            })
            
            # Check for null values in required columns
            if df_mapped['customer_id'].isnull().any():
                self.logger.error("Found null values in customer_id. Please check the Excel file.")
                return False
            
            if df_mapped['created_at'].isnull().any():
                self.logger.error("Found null values in created_at. Please check the Excel file.")
                return False
            
            # Handle missing values and data types
            df_mapped['company_id'] = df_mapped['company_id'].fillna(DEFAULT_VALUES['company_id']).astype('Int64')
            df_mapped['ticket_cat_id'] = df_mapped['ticket_cat_id'].fillna(1).astype('Int64')  # Default to first category
            df_mapped['status'] = df_mapped['status'].fillna(DEFAULT_VALUES['ticket_status']).astype('Int64')
            df_mapped['priority'] = df_mapped['priority'].fillna(DEFAULT_VALUES['ticket_priority']).astype('Int64')
            df_mapped['created_by'] = df_mapped['created_by'].fillna(DEFAULT_VALUES['created_by']).astype('Int64')
            
            # Convert datetime columns
            df_mapped['created_at'] = pd.to_datetime(df_mapped['created_at'])
            df_mapped['updated_at'] = pd.to_datetime(df_mapped['updated_at'])
            
            # Fill missing description with empty string
            df_mapped['description'] = df_mapped['description'].fillna('')
            
            # Fill missing closing_notes and closed_by with null
            df_mapped['closing_notes'] = None
            df_mapped['closed_by'] = None
            
            # Ensure all numeric columns are integers, handling NaN values properly
            df_mapped['id'] = df_mapped['id'].astype('Int64')
            df_mapped['company_id'] = df_mapped['company_id'].astype('Int64')
            df_mapped['customer_id'] = df_mapped['customer_id'].astype('Int64')
            df_mapped['ticket_cat_id'] = df_mapped['ticket_cat_id'].astype('Int64')
            df_mapped['status'] = df_mapped['status'].astype('Int64')
            df_mapped['priority'] = df_mapped['priority'].astype('Int64')
            df_mapped['created_by'] = df_mapped['created_by'].astype('Int64')
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO tickets (
                        id, company_id, customer_id, ticket_cat_id, description, 
                        status, priority, created_by, created_at, 
                        closed_at, updated_at, closing_notes, closed_by
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE 
                        company_id = VALUES(company_id),
                        customer_id = VALUES(customer_id),
                        ticket_cat_id = VALUES(ticket_cat_id),
                        description = VALUES(description),
                        status = VALUES(status),
                        priority = VALUES(priority),
                        closed_at = VALUES(closed_at),
                        updated_at = VALUES(updated_at),
                        closing_notes = VALUES(closing_notes),
                        closed_by = VALUES(closed_by)
                    """
                    
                    values = (
                        int(row['id']), int(row['company_id']), int(row['customer_id']),
                        int(row['ticket_cat_id']), str(row['description']), int(row['status']),
                        int(row['priority']), int(row['created_by']), 
                        row['created_at'].to_pydatetime() if pd.notna(row['created_at']) else None,
                        row['closed_at'].to_pydatetime() if pd.notna(row['closed_at']) else None,
                        row['updated_at'].to_pydatetime() if pd.notna(row['updated_at']) else None,
                        str(row['closing_notes']) if pd.notna(row['closing_notes']) else None, 
                        int(row['closed_by']) if pd.notna(row['closed_by']) else None
                    )
                    
                    # Debug: Print first row values
                    if _ == batch.index[0]:
                        self.logger.info(f"Sample values for first row: {values}")
                        self.logger.info(f"Number of placeholders: {query.count('%s')}")
                        self.logger.info(f"Number of values: {len(values)}")
                    
                    self.cursor.execute(query, values)
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} tickets")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing tickets: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def import_ticket_calls(self, excel_file: str) -> bool:
        """Import ticket calls data from Excel file (ticket_calls.xlsx)."""
        try:
            self.logger.info(f"Importing ticket calls from {excel_file}")
            df = pd.read_excel(excel_file)
            
            # Handle duplicate IDs by keeping only the first occurrence
            if df['id'].duplicated().any():
                duplicate_count = df['id'].duplicated().sum()
                self.logger.warning(f"Found {duplicate_count} duplicate IDs. Keeping only the first occurrence of each.")
                df = df.drop_duplicates(subset=['id'], keep='first')
                self.logger.info(f"After removing duplicates: {len(df)} records remaining")
            
            # Validate data
            is_valid, errors = self.validate_data(df, 'ticket_calls')
            if not is_valid:
                for error in errors:
                    self.logger.error(f"Validation error: {error}")
                return False
            
            # Map Excel columns to database columns
            # Excel has: ['id', 'ticket_ID', 'Customer_ID', 'callRecipient_id', 'calltype_id', 'callReason_id', 'datetime', 'callresult', 'notes']
            # Database expects: ['id', 'company_id', 'ticket_id', 'call_type', 'call_cat_id', 'description', 'call_notes', 'call_duration', 'created_by', 'created_at']
            df_mapped = df.rename(columns={
                'ticket_ID': 'ticket_id',
                'calltype_id': 'call_type',
                'callReason_id': 'call_cat_id',
                'callresult': 'description',
                'datetime': 'created_at'
            })
            
            # Check for null values in required columns
            if df_mapped['ticket_id'].isnull().any():
                self.logger.error("Found null values in ticket_id. Please check the Excel file.")
                return False
            
            if df_mapped['created_at'].isnull().any():
                self.logger.error("Found null values in created_at. Please check the Excel file.")
                return False
            
            # Handle missing values and data types
            df_mapped['company_id'] = DEFAULT_VALUES['company_id']  # Default company_id
            df_mapped['call_type'] = df_mapped['call_type'].fillna(0).astype(int)
            df_mapped['call_cat_id'] = df_mapped['call_cat_id'].fillna(1).astype(int)
            df_mapped['created_by'] = df_mapped['callRecipient_id'].fillna(DEFAULT_VALUES['created_by']).astype(int)
            
            # Convert datetime columns
            df_mapped['created_at'] = pd.to_datetime(df_mapped['created_at'])
            
            # Fill missing description and call_notes with empty string
            df_mapped['description'] = df_mapped['description'].fillna('')
            df_mapped['call_notes'] = df_mapped['notes'].fillna('')
            
            # Fill missing call_duration with 0
            df_mapped['call_duration'] = 0
            
            # Process in batches
            total_records = len(df_mapped)
            self.stats['total_records'] += total_records
            
            for i in range(0, total_records, IMPORT_SETTINGS['batch_size']):
                batch = df_mapped.iloc[i:i + IMPORT_SETTINGS['batch_size']]
                
                for _, row in batch.iterrows():
                    query = """
                    INSERT INTO ticketcall (
                        id, company_id, ticket_id, call_type, call_cat_id, 
                        description, call_notes, call_duration, created_by, created_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE 
                        company_id = VALUES(company_id),
                        ticket_id = VALUES(ticket_id),
                        call_type = VALUES(call_type),
                        call_cat_id = VALUES(call_cat_id),
                        description = VALUES(description),
                        call_notes = VALUES(call_notes),
                        call_duration = VALUES(call_duration),
                        created_by = VALUES(created_by)
                    """
                    
                    values = (
                        row['id'], row['company_id'], row['ticket_id'],
                        row['call_type'], row['call_cat_id'], row['description'],
                        row['call_notes'], row['call_duration'], row['created_by'], row['created_at']
                    )
                    
                    self.cursor.execute(query, values)
                
                self.connection.commit()
                self.logger.info(f"Processed batch {i//IMPORT_SETTINGS['batch_size'] + 1}/{(total_records-1)//IMPORT_SETTINGS['batch_size'] + 1}")
            
            self.stats['successful_imports'] += 1
            self.logger.info(f"Successfully imported {total_records} ticket calls")
            return True
            
        except Exception as e:
            self.logger.error(f"Error importing ticket calls: {e}")
            self.stats['failed_imports'] += 1
            if self.connection:
                self.connection.rollback()
            return False
    
    def run_import(self, data_folder: str) -> bool:
        """Run the complete ticket data import process."""
        self.stats['start_time'] = datetime.now()
        
        try:
            if not self.connect():
                return False
            
            # Check and create missing tables
            if not self.check_table_exists('call_categories'):
                if not self.create_call_categories_table():
                    self.logger.error("Failed to create call_categories table")
                    return False
            
            if not self.check_table_exists('ticket_categories'):
                if not self.create_ticket_categories_table():
                    self.logger.error("Failed to create ticket_categories table")
                    return False
            
            if not self.check_table_exists('tickets'):
                if not self.create_tickets_table():
                    self.logger.error("Failed to create tickets table")
                    return False
            
            if not self.check_table_exists('ticketcall'):
                if not self.create_ticketcall_table():
                    self.logger.error("Failed to create ticketcall table")
                    return False
            
            # Define import order (respecting foreign key constraints)
            import_tasks = [
                ('call_categories', 'callReason_tickets.xlsx', self.import_call_categories),
                ('ticket_categories', 'TicketType.xlsx', self.import_ticket_categories),
                ('tickets', 'tickets.xlsx', self.import_tickets),
                ('ticket_calls', 'ticket_calls.xlsx', self.import_ticket_calls)
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
        self.logger.info("TICKET DATA IMPORT SUMMARY")
        self.logger.info("=" * 60)
        self.logger.info(f"Total tables processed: {total_tasks}")
        self.logger.info(f"Successful imports: {success_count}")
        self.logger.info(f"Failed imports: {total_tasks - success_count}")
        self.logger.info(f"Total records processed: {self.stats['total_records']}")
        self.logger.info(f"Total time: {duration}")
        self.logger.info(f"Average time per record: {duration / max(self.stats['total_records'], 1)}")
        self.logger.info("=" * 60)
        
        # Save statistics to file
        stats_file = f'ticket_import_stats_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
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
    """Main function to run the enhanced ticket data import."""
    # Data folder path
    data_folder = os.path.join(os.path.dirname(__file__), 'data', 'tickets')
    
    # Check if data folder exists
    if not os.path.exists(data_folder):
        print(f"Error: Data folder not found: {data_folder}")
        sys.exit(1)
    
    # Create importer instance
    importer = EnhancedTicketDataImporter()
    
    # Run import
    print("Starting Enhanced JanssenCRM Ticket Data import process...")
    print(f"Data folder: {data_folder}")
    print(f"Database: {DATABASE_CONFIG['database']} on {DATABASE_CONFIG['host']}")
    print("=" * 60)
    
    success = importer.run_import(data_folder)
    
    if success:
        print("\n🎉 Ticket data import completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Ticket data import failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
