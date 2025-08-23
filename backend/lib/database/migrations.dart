import 'package:mysql1/mysql1.dart';
import 'database_service.dart';

/// Helper function to create table with DDL error handling
Future<void> _createTableSafely(MySqlConnection conn, String tableName, String createTableSql) async {
  try {
    await DatabaseService.query(createTableSql);
    print('✓ $tableName table created/verified');
  } catch (e) {
    if (e.toString().contains('DDL operations are not allowed')) {
      print('⚠ DDL operations not allowed - $tableName table may already exist');
      // Check if table exists
      try {
        await DatabaseService.query('SELECT 1 FROM $tableName LIMIT 1');
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
Future<void> _createIndexSafely(MySqlConnection conn, String indexName, String tableName, String indexSql) async {
  try {
    await DatabaseService.query(indexSql);
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

/// Create all indexes needed for tickets report service optimization
Future<void> _createTicketsReportIndexes(MySqlConnection conn) async {
  print('Creating indexes for tickets report service optimization...');

  // =============================================================================
  // TICKETS TABLE INDEXES
  // =============================================================================

  // Most frequently used WHERE condition: company filtering
  await _createIndexSafely(conn, 'idx_tickets_company_id', 'tickets',
    'CREATE INDEX idx_tickets_company_id ON tickets(company_id)');

  // Status filtering (very common in WHERE clauses)
  await _createIndexSafely(conn, 'idx_tickets_status', 'tickets',
    'CREATE INDEX idx_tickets_status ON tickets(status)');

  // Priority filtering
  await _createIndexSafely(conn, 'idx_tickets_priority', 'tickets',
    'CREATE INDEX idx_tickets_priority ON tickets(priority)');

  // Date range filtering
  await _createIndexSafely(conn, 'idx_tickets_created_at', 'tickets',
    'CREATE INDEX idx_tickets_created_at ON tickets(created_at)');

  // Foreign key indexes for JOINs
  await _createIndexSafely(conn, 'idx_tickets_customer_id', 'tickets',
    'CREATE INDEX idx_tickets_customer_id ON tickets(customer_id)');

  await _createIndexSafely(conn, 'idx_tickets_ticket_cat_id', 'tickets',
    'CREATE INDEX idx_tickets_ticket_cat_id ON tickets(ticket_cat_id)');

  await _createIndexSafely(conn, 'idx_tickets_created_by', 'tickets',
    'CREATE INDEX idx_tickets_created_by ON tickets(created_by)');

  await _createIndexSafely(conn, 'idx_tickets_closed_by', 'tickets',
    'CREATE INDEX idx_tickets_closed_by ON tickets(closed_by)');

  // Composite indexes for common WHERE condition combinations
  await _createIndexSafely(conn, 'idx_tickets_company_status', 'tickets',
    'CREATE INDEX idx_tickets_company_status ON tickets(company_id, status)');

  await _createIndexSafely(conn, 'idx_tickets_company_priority', 'tickets',
    'CREATE INDEX idx_tickets_company_priority ON tickets(company_id, priority)');

  await _createIndexSafely(conn, 'idx_tickets_company_date', 'tickets',
    'CREATE INDEX idx_tickets_company_date ON tickets(company_id, created_at)');

  await _createIndexSafely(conn, 'idx_tickets_company_customer', 'tickets',
    'CREATE INDEX idx_tickets_company_customer ON tickets(company_id, customer_id)');

  await _createIndexSafely(conn, 'idx_tickets_company_category', 'tickets',
    'CREATE INDEX idx_tickets_company_category ON tickets(company_id, ticket_cat_id)');

  // Composite index for the most common query pattern: company + date range + status
  await _createIndexSafely(conn, 'idx_tickets_company_date_status', 'tickets',
    'CREATE INDEX idx_tickets_company_date_status ON tickets(company_id, created_at, status)');

  // Full composite index for complex filtering
  await _createIndexSafely(conn, 'idx_tickets_complex_filter', 'tickets',
    'CREATE INDEX idx_tickets_complex_filter ON tickets(company_id, customer_id, ticket_cat_id, status, priority, created_at)');

  // =============================================================================
  // CUSTOMERS TABLE INDEXES
  // =============================================================================

  await _createIndexSafely(conn, 'idx_customers_company_id', 'customers',
    'CREATE INDEX idx_customers_company_id ON customers(company_id)');

  await _createIndexSafely(conn, 'idx_customers_governomate_id', 'customers',
    'CREATE INDEX idx_customers_governomate_id ON customers(governomate_id)');

  await _createIndexSafely(conn, 'idx_customers_city_id', 'customers',
    'CREATE INDEX idx_customers_city_id ON customers(city_id)');

  await _createIndexSafely(conn, 'idx_customers_created_by', 'customers',
    'CREATE INDEX idx_customers_created_by ON customers(created_by)');

  await _createIndexSafely(conn, 'idx_customers_name', 'customers',
    'CREATE INDEX idx_customers_name ON customers(name)');

  await _createIndexSafely(conn, 'idx_customers_company_name', 'customers',
    'CREATE INDEX idx_customers_company_name ON customers(company_id, name)');

  // =============================================================================
  // TICKET_CATEGORIES TABLE INDEXES
  // =============================================================================

  await _createIndexSafely(conn, 'idx_ticket_categories_name', 'ticket_categories',
    'CREATE INDEX idx_ticket_categories_name ON ticket_categories(name)');

  await _createIndexSafely(conn, 'idx_ticket_categories_company_id', 'ticket_categories',
    'CREATE INDEX idx_ticket_categories_company_id ON ticket_categories(company_id)');

  // =============================================================================
  // TICKET_ITEMS TABLE INDEXES
  // =============================================================================

  await _createIndexSafely(conn, 'idx_ticket_items_ticket_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_ticket_id ON ticket_items(ticket_id)');

  await _createIndexSafely(conn, 'idx_ticket_items_product_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_product_id ON ticket_items(product_id)');

  await _createIndexSafely(conn, 'idx_ticket_items_request_reason_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_request_reason_id ON ticket_items(request_reason_id)');

  await _createIndexSafely(conn, 'idx_ticket_items_created_by', 'ticket_items',
    'CREATE INDEX idx_ticket_items_created_by ON ticket_items(created_by)');

  await _createIndexSafely(conn, 'idx_ticket_items_company_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_id ON ticket_items(company_id)');

  await _createIndexSafely(conn, 'idx_ticket_items_ticket_created', 'ticket_items',
    'CREATE INDEX idx_ticket_items_ticket_created ON ticket_items(ticket_id, created_at)');

  await _createIndexSafely(conn, 'idx_ticket_items_batch_query', 'ticket_items',
    'CREATE INDEX idx_ticket_items_batch_query ON ticket_items(ticket_id, product_id, request_reason_id, created_at)');

  // =============================================================================
  // TICKETCALL TABLE INDEXES
  // =============================================================================

  await _createIndexSafely(conn, 'idx_ticketcall_ticket_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_ticket_id ON ticketcall(ticket_id)');

  await _createIndexSafely(conn, 'idx_ticketcall_company_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_company_id ON ticketcall(company_id)');

  await _createIndexSafely(conn, 'idx_ticketcall_call_cat_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_call_cat_id ON ticketcall(call_cat_id)');

  await _createIndexSafely(conn, 'idx_ticketcall_created_by', 'ticketcall',
    'CREATE INDEX idx_ticketcall_created_by ON ticketcall(created_by)');

  await _createIndexSafely(conn, 'idx_ticketcall_count_optimization', 'ticketcall',
    'CREATE INDEX idx_ticketcall_count_optimization ON ticketcall(ticket_id, company_id)');

  // =============================================================================
  // LOOKUP TABLES INDEXES
  // =============================================================================

  await _createIndexSafely(conn, 'idx_product_info_company_id', 'product_info',
    'CREATE INDEX idx_product_info_company_id ON product_info(company_id)');

  await _createIndexSafely(conn, 'idx_product_info_created_by', 'product_info',
    'CREATE INDEX idx_product_info_created_by ON product_info(created_by)');

  await _createIndexSafely(conn, 'idx_request_reasons_company_id', 'request_reasons',
    'CREATE INDEX idx_request_reasons_company_id ON request_reasons(company_id)');

  await _createIndexSafely(conn, 'idx_request_reasons_created_by', 'request_reasons',
    'CREATE INDEX idx_request_reasons_created_by ON request_reasons(created_by)');

  await _createIndexSafely(conn, 'idx_users_company_id', 'users',
    'CREATE INDEX idx_users_company_id ON users(company_id)');

  await _createIndexSafely(conn, 'idx_users_is_active', 'users',
    'CREATE INDEX idx_users_is_active ON users(is_active)');

  // =============================================================================
  // ADDITIONAL PERFORMANCE INDEXES
  // =============================================================================

  await _createIndexSafely(conn, 'idx_tickets_updated_at', 'tickets',
    'CREATE INDEX idx_tickets_updated_at ON tickets(updated_at)');

  await _createIndexSafely(conn, 'idx_customers_updated_at', 'customers',
    'CREATE INDEX idx_customers_updated_at ON customers(updated_at)');

  await _createIndexSafely(conn, 'idx_ticket_items_updated_at', 'ticket_items',
    'CREATE INDEX idx_ticket_items_updated_at ON ticket_items(updated_at)');

  await _createIndexSafely(conn, 'idx_ticketcall_created_at', 'ticketcall',
    'CREATE INDEX idx_ticketcall_created_at ON ticketcall(created_at)');

  // =============================================================================
  // SEARCH OPTIMIZATION INDEXES
  // =============================================================================

  // For search functionality - prefix indexes for LIKE queries
  await _createIndexSafely(conn, 'idx_tickets_description_prefix', 'tickets',
    'CREATE INDEX idx_tickets_description_prefix ON tickets(description(50))');

  await _createIndexSafely(conn, 'idx_customers_name_prefix', 'customers',
    'CREATE INDEX idx_customers_name_prefix ON customers(name(50))');

  print('✓ All tickets report indexes created successfully.');
}

Future<void> runMigrations(MySqlConnection conn) async {
  try {


    // audit_logs
    await _createTableSafely(conn, 'audit_logs', '''
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
    await _createTableSafely(conn, 'call_categories', '''
      CREATE TABLE IF NOT EXISTS call_categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255),
        created_by INT,
        created_at DATETIME,
        updated_at DATETIME,
        company_id INT
      )
    ''');

    // cities
    await _createTableSafely(conn, 'cities', '''
      CREATE TABLE IF NOT EXISTS cities (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        governorate_id INT UNSIGNED NOT NULL,
        KEY (governorate_id)
      )
    ''');

    // companies
    await _createTableSafely(conn, 'companies', '''
      CREATE TABLE IF NOT EXISTS companies (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        KEY (name)
      )
    ''');

    // customer_phones
    await _createTableSafely(conn, 'customer_phones', '''
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
    await _createTableSafely(conn, 'customercall', '''
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
    await _createTableSafely(conn, 'customers', '''
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
    await _createTableSafely(conn, 'governorates', '''
      CREATE TABLE IF NOT EXISTS governorates (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL
      )
    ''');

 
    // permissions (duplicate - should be reviewed)
    await _createTableSafely(conn, 'permissions', '''
      CREATE TABLE IF NOT EXISTS permissions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title TEXT,
        description TEXT
      )
    ''');

    // product_info
    await _createTableSafely(conn, 'product_info', '''
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
    await _createTableSafely(conn, 'request_reasons', '''
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
    await _createTableSafely(conn, 'ticket_categories', '''
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
    await _createTableSafely(conn, 'ticket_item_change_another', '''
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
    await _createTableSafely(conn, 'ticket_item_change_same', '''
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
    await _createTableSafely(conn, 'ticket_item_maintenance', '''
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
    await _createTableSafely(conn, 'ticket_items', '''
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
    await _createTableSafely(conn, 'ticketcall', '''
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
    await _createTableSafely(conn, 'tickets', '''
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
    await _createTableSafely(conn, 'users', '''
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
    await _createTableSafely(conn, 'entities', '''
      CREATE TABLE IF NOT EXISTS entities (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // activities
    await _createTableSafely(conn, 'activities', '''
      CREATE TABLE IF NOT EXISTS activities (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // activity_logs
    await _createTableSafely(conn, 'activity_logs', '''
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

    // Add permissions column to existing users table if it doesn't exist


    // Create indexes for tickets report service optimization
    await _createTicketsReportIndexes(conn);

    print('✓ All migrations completed: database schema and indexes ensured.');
  } catch (e) {
    print('✗ Migration failed: $e');
    rethrow;
  }
}
