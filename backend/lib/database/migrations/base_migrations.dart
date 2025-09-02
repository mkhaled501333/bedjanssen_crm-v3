import 'package:mysql1/mysql1.dart';
import '../database_service.dart';

/// Helper function to create table with DDL error handling
Future<void> createTableSafely(MySqlConnection conn, String tableName, String createTableSql) async {
  try {
    await DatabaseService.query(
      createTableSql,
      userId: 1, // System user for migrations
    );
    print('✓ $tableName table created/verified');
  } catch (e) {
    if (e.toString().contains('DDL operations are not allowed')) {
      print('⚠ DDL operations not allowed - $tableName table may already exist');
      // Check if table exists
      try {
        await DatabaseService.query(
          'SELECT 1 FROM $tableName LIMIT 1',
          userId: 1, // System user for migrations
        );
        print('✓ $tableName table exists and is accessible');
      } catch (tableError) {
        print('✗ $tableName table does not exist and cannot be created due to DDL restrictions');
        print('Please ask your database administrator to create the $tableName table manually');
      }
    } else {
      print('✗ Error creating $tableName table: $e');
      rethrow;
    }
  }
}

/// Helper function to create index with error handling
Future<void> createIndexSafely(MySqlConnection conn, String indexName, String tableName, String indexSql) async {
  try {
    await DatabaseService.query(
      indexSql,
      userId: 1, // System user for migrations
    );
    print('✓ Index $indexName created on $tableName');
  } catch (e) {
    if (e.toString().contains('Duplicate key name') || e.toString().contains('already exists')) {
      print('✓ Index $indexName already exists on $tableName');
    } else if (e.toString().contains('DDL operations are not allowed')) {
      print('⚠ DDL operations not allowed - $indexName index may already exist on $tableName');
    } else {
      print('✗ Error creating index $indexName on $tableName: $e');
      rethrow;
    }
  }
}

/// Create basic tables without activity_logs foreign keys
Future<void> createBasicTablesWithoutForeignKeys(MySqlConnection conn) async {
  print('Creating basic tables...');

  // audit_logs
  await createTableSafely(conn, 'audit_logs', '''
    CREATE TABLE IF NOT EXISTS audit_logs (
      id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      user_id VARCHAR(255),
      action VARCHAR(10) NOT NULL,
      target_entity VARCHAR(100),
      target_id VARCHAR(255),
      old_value TEXT,
      new_value TEXT,
      timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      KEY (user_id),
      KEY (action),
      KEY (target_entity),
      KEY (timestamp)
    )
  ''');

  // call_categories
  await createTableSafely(conn, 'call_categories', '''
    CREATE TABLE IF NOT EXISTS call_categories (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(255),
      created_by INT,
      created_at DATETIME,
      updated_at DATETIME,
      company_id INT
    )
  ''');

  // call_types
  await createTableSafely(conn, 'call_types', '''
    CREATE TABLE IF NOT EXISTS call_types (
      id INT PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  ''');

  // cities
  await createTableSafely(conn, 'cities', '''
    CREATE TABLE IF NOT EXISTS cities (
      id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      governorate_id INT UNSIGNED NOT NULL,
      KEY (governorate_id)
    )
  ''');

  // companies
  await createTableSafely(conn, 'companies', '''
    CREATE TABLE IF NOT EXISTS companies (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      KEY (name)
    )
  ''');

  // customer_phones
  await createTableSafely(conn, 'customer_phones', '''
    CREATE TABLE IF NOT EXISTS customer_phones (
      id INT AUTO_INCREMENT PRIMARY KEY,
      company_id INT NOT NULL,
      customer_id INT NOT NULL,
      phone VARCHAR(20),
      phone_type INT,
      created_by INT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  ''');

  // customercall
  await createTableSafely(conn, 'customercall', '''
    CREATE TABLE IF NOT EXISTS customercall (
      id INT AUTO_INCREMENT PRIMARY KEY,
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
  ''');

  // customers
  await createTableSafely(conn, 'customers', '''
    CREATE TABLE IF NOT EXISTS customers (
      id INT AUTO_INCREMENT PRIMARY KEY,
      company_id INT,
      name VARCHAR(100),
      governomate_id INT,
      city_id INT,
      address VARCHAR(255),
      notes TEXT,
      created_by INT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  ''');

  // governorates
  await createTableSafely(conn, 'governorates', '''
    CREATE TABLE IF NOT EXISTS governorates (
      id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL
    )
  ''');

  // permissions
  await createTableSafely(conn, 'permissions', '''
    CREATE TABLE IF NOT EXISTS permissions (
      id INT AUTO_INCREMENT PRIMARY KEY,
      title TEXT,
      description TEXT
    )
  ''');

  // product_info
  await createTableSafely(conn, 'product_info', '''
    CREATE TABLE IF NOT EXISTS product_info (
      id INT AUTO_INCREMENT PRIMARY KEY,
      company_id INT,
      product_name VARCHAR(255),
      created_by INT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  ''');

  // request_reasons
  await createTableSafely(conn, 'request_reasons', '''
    CREATE TABLE IF NOT EXISTS request_reasons (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(45),
      created_by INT,
      created_at DATETIME,
      updated_at DATETIME,
      company_id INT
    )
  ''');

  // ticket_categories
  await createTableSafely(conn, 'ticket_categories', '''
    CREATE TABLE IF NOT EXISTS ticket_categories (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(45),
      created_by INT,
      created_at DATETIME,
      updated_at DATETIME,
      company_id INT
    )
  ''');

  // ticket_item_change_another
  await createTableSafely(conn, 'ticket_item_change_another', '''
    CREATE TABLE IF NOT EXISTS ticket_item_change_another (
      ticket_item_id INT PRIMARY KEY,
      product_id INT,
      product_size VARCHAR(100),
      cost DOUBLE,
      client_approval TINYINT,
      refusal_reason TEXT,
      pulled TINYINT(1),
      pull_date DATE,
      delivered TINYINT(1),
      delivery_date DATE,
      created_by INT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      company_id INT
    )
  ''');

  // ticket_item_change_same
  await createTableSafely(conn, 'ticket_item_change_same', '''
    CREATE TABLE IF NOT EXISTS ticket_item_change_same (
      ticket_item_id INT PRIMARY KEY,
      product_id INT,
      product_size VARCHAR(100),
      cost DOUBLE,
      client_approval TINYINT,
      refusal_reason TEXT,
      pulled TINYINT(1),
      pull_date DATE,
      delivered TINYINT(1),
      delivery_date DATE,
      created_by INT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      company_id INT
    )
  ''');

  // ticket_item_maintenance
  await createTableSafely(conn, 'ticket_item_maintenance', '''
    CREATE TABLE IF NOT EXISTS ticket_item_maintenance (
      ticket_item_id INT PRIMARY KEY,
      maintenance_steps TEXT,
      maintenance_cost DOUBLE,
      client_approval TINYINT,
      refusal_reason TEXT,
      pulled TINYINT(1),
      pull_date DATE,
      delivered TINYINT(1),
      delivery_date DATE,
      created_by INT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      company_id INT
    )
  ''');

  // ticket_items
  await createTableSafely(conn, 'ticket_items', '''
    CREATE TABLE IF NOT EXISTS ticket_items (
      id INT AUTO_INCREMENT PRIMARY KEY,
      company_id INT,
      ticket_id INT,
      product_id INT,
      product_size VARCHAR(100),
      quantity INT,
      purchase_date DATE,
      purchase_location VARCHAR(255),
      request_reason_id INT,
      request_reason_detail TEXT,
      inspected TINYINT(1),
      inspection_date DATE,
      inspection_result TEXT,
      client_approval TINYINT(1),
      created_by INT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  ''');

  // ticketcall
  await createTableSafely(conn, 'ticketcall', '''
    CREATE TABLE IF NOT EXISTS ticketcall (
      id INT AUTO_INCREMENT PRIMARY KEY,
      company_id INT,
      ticket_id INT,
      call_type TINYINT,
      call_cat_id INT,
      description TEXT,
      call_notes TEXT,
      call_duration VARCHAR(20),
      created_by INT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  ''');

  // tickets
  await createTableSafely(conn, 'tickets', '''
    CREATE TABLE IF NOT EXISTS tickets (
      id INT AUTO_INCREMENT PRIMARY KEY,
      company_id INT,
      customer_id INT,
      ticket_cat_id INT,
      description TEXT,
      status TINYINT,
      priority INT,
      created_by INT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      closed_at DATETIME,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      closing_notes TEXT,
      closed_by INT
    )
  ''');

  // users
  await createTableSafely(conn, 'users', '''
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      company_id INT NOT NULL,
      name VARCHAR(255) NOT NULL,
      username VARCHAR(255) NOT NULL UNIQUE,
      password VARCHAR(255) NOT NULL,
      created_by INT,
      is_active TINYINT(1) DEFAULT 1,
      permissions JSON,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )
  ''');

  // entities
  await createTableSafely(conn, 'entities', '''
    CREATE TABLE IF NOT EXISTS entities (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL UNIQUE,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  // activities
  await createTableSafely(conn, 'activities', '''
    CREATE TABLE IF NOT EXISTS activities (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(100) NOT NULL UNIQUE,
      description TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  ''');



  print('✓ Basic tables created successfully.');
}

/// Create activity_logs table with foreign keys (after entities and activities exist)
Future<void> createActivityLogsTable(MySqlConnection conn) async {
  print('Creating activity_logs table...');
  
  await createTableSafely(conn, 'activity_logs', '''
    CREATE TABLE IF NOT EXISTS activity_logs (
      id BIGINT AUTO_INCREMENT PRIMARY KEY,
      entity_id INT NOT NULL,
      record_id INT NOT NULL,
      activity_id INT NOT NULL,
      user_id INT NOT NULL,
      details JSON,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      KEY (entity_id),
      KEY (record_id),
      KEY (activity_id),
      KEY (user_id),
      KEY (created_at),
      FOREIGN KEY (entity_id) REFERENCES entities(id),
      FOREIGN KEY (activity_id) REFERENCES activities(id)
    )
  ''');
  
  print('✓ Activity logs table created successfully.');
}
