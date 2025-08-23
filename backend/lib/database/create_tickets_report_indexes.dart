import 'database_service.dart';
import 'database_config.dart';

/// Standalone script to create indexes for tickets report service optimization
/// Run this script to add performance indexes to the database
///
/// Usage: dart run backend/lib/database/create_tickets_report_indexes.dart
Future<void> main() async {
  try {
    print('🚀 Starting tickets report indexes creation...');

    // Initialize database connection
    await DatabaseConfig.initialize();

    // Execute the indexes creation
    await _createTicketsReportIndexes();

    print('✅ All tickets report indexes created successfully!');
    print('📊 Your tickets report queries should now be significantly faster.');

  } catch (e) {
    print('❌ Error creating indexes: $e');
    rethrow;
  } finally {
    await DatabaseConfig.close();
  }
}

/// Helper function to create index with error handling
Future<void> _createIndexSafely(String indexName, String tableName, String indexSql) async {
  try {
    await DatabaseService.query(indexSql);
    print('✅ Index $indexName created on $tableName');
  } catch (e) {
    if (e.toString().contains('Duplicate key name') || e.toString().contains('already exists')) {
      print('✅ Index $indexName already exists on $tableName');
    } else if (e.toString().contains('DDL operations are not allowed')) {
      print('⚠️  DDL operations not allowed - $indexName index may already exist on $tableName');
      print('   Please ask your database administrator to run the SQL script manually');
    } else {
      print('❌ Error creating index $indexName on $tableName: $e');
      rethrow;
    }
  }
}

/// Create all indexes needed for tickets report service optimization
Future<void> _createTicketsReportIndexes() async {
  print('🔧 Creating indexes for tickets report service optimization...');
  print('   This may take a few minutes depending on your database size...\n');

  // =============================================================================
  // TICKETS TABLE INDEXES
  // =============================================================================
  print('📋 Creating tickets table indexes...');

  await _createIndexSafely('idx_tickets_company_id', 'tickets',
    'CREATE INDEX idx_tickets_company_id ON tickets(company_id)');

  await _createIndexSafely('idx_tickets_status', 'tickets',
    'CREATE INDEX idx_tickets_status ON tickets(status)');

  await _createIndexSafely('idx_tickets_priority', 'tickets',
    'CREATE INDEX idx_tickets_priority ON tickets(priority)');

  await _createIndexSafely('idx_tickets_created_at', 'tickets',
    'CREATE INDEX idx_tickets_created_at ON tickets(created_at)');

  await _createIndexSafely('idx_tickets_customer_id', 'tickets',
    'CREATE INDEX idx_tickets_customer_id ON tickets(customer_id)');

  await _createIndexSafely('idx_tickets_ticket_cat_id', 'tickets',
    'CREATE INDEX idx_tickets_ticket_cat_id ON tickets(ticket_cat_id)');

  await _createIndexSafely('idx_tickets_created_by', 'tickets',
    'CREATE INDEX idx_tickets_created_by ON tickets(created_by)');

  await _createIndexSafely('idx_tickets_closed_by', 'tickets',
    'CREATE INDEX idx_tickets_closed_by ON tickets(closed_by)');

  // Composite indexes
  await _createIndexSafely('idx_tickets_company_status', 'tickets',
    'CREATE INDEX idx_tickets_company_status ON tickets(company_id, status)');

  await _createIndexSafely('idx_tickets_company_priority', 'tickets',
    'CREATE INDEX idx_tickets_company_priority ON tickets(company_id, priority)');

  await _createIndexSafely('idx_tickets_company_date', 'tickets',
    'CREATE INDEX idx_tickets_company_date ON tickets(company_id, created_at)');

  await _createIndexSafely('idx_tickets_company_customer', 'tickets',
    'CREATE INDEX idx_tickets_company_customer ON tickets(company_id, customer_id)');

  await _createIndexSafely('idx_tickets_company_category', 'tickets',
    'CREATE INDEX idx_tickets_company_category ON tickets(company_id, ticket_cat_id)');

  await _createIndexSafely('idx_tickets_company_date_status', 'tickets',
    'CREATE INDEX idx_tickets_company_date_status ON tickets(company_id, created_at, status)');

  await _createIndexSafely('idx_tickets_complex_filter', 'tickets',
    'CREATE INDEX idx_tickets_complex_filter ON tickets(company_id, customer_id, ticket_cat_id, status, priority, created_at)');

  // =============================================================================
  // CUSTOMERS TABLE INDEXES
  // =============================================================================
  print('👥 Creating customers table indexes...');

  await _createIndexSafely('idx_customers_company_id', 'customers',
    'CREATE INDEX idx_customers_company_id ON customers(company_id)');

  await _createIndexSafely('idx_customers_governomate_id', 'customers',
    'CREATE INDEX idx_customers_governomate_id ON customers(governomate_id)');

  await _createIndexSafely('idx_customers_city_id', 'customers',
    'CREATE INDEX idx_customers_city_id ON customers(city_id)');

  await _createIndexSafely('idx_customers_created_by', 'customers',
    'CREATE INDEX idx_customers_created_by ON customers(created_by)');

  await _createIndexSafely('idx_customers_name', 'customers',
    'CREATE INDEX idx_customers_name ON customers(name)');

  await _createIndexSafely('idx_customers_company_name', 'customers',
    'CREATE INDEX idx_customers_company_name ON customers(company_id, name)');

  // =============================================================================
  // TICKET_CATEGORIES TABLE INDEXES
  // =============================================================================
  print('📂 Creating ticket_categories table indexes...');

  await _createIndexSafely('idx_ticket_categories_name', 'ticket_categories',
    'CREATE INDEX idx_ticket_categories_name ON ticket_categories(name)');

  await _createIndexSafely('idx_ticket_categories_company_id', 'ticket_categories',
    'CREATE INDEX idx_ticket_categories_company_id ON ticket_categories(company_id)');

  // =============================================================================
  // TICKET_ITEMS TABLE INDEXES
  // =============================================================================
  print('📦 Creating ticket_items table indexes...');

  await _createIndexSafely('idx_ticket_items_ticket_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_ticket_id ON ticket_items(ticket_id)');

  await _createIndexSafely('idx_ticket_items_product_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_product_id ON ticket_items(product_id)');

  await _createIndexSafely('idx_ticket_items_request_reason_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_request_reason_id ON ticket_items(request_reason_id)');

  await _createIndexSafely('idx_ticket_items_created_by', 'ticket_items',
    'CREATE INDEX idx_ticket_items_created_by ON ticket_items(created_by)');

  await _createIndexSafely('idx_ticket_items_company_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_id ON ticket_items(company_id)');

  await _createIndexSafely('idx_ticket_items_ticket_created', 'ticket_items',
    'CREATE INDEX idx_ticket_items_ticket_created ON ticket_items(ticket_id, created_at)');

  await _createIndexSafely('idx_ticket_items_batch_query', 'ticket_items',
    'CREATE INDEX idx_ticket_items_batch_query ON ticket_items(ticket_id, product_id, request_reason_id, created_at)');

  // =============================================================================
  // TICKETCALL TABLE INDEXES
  // =============================================================================
  print('📞 Creating ticketcall table indexes...');

  await _createIndexSafely('idx_ticketcall_ticket_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_ticket_id ON ticketcall(ticket_id)');

  await _createIndexSafely('idx_ticketcall_company_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_company_id ON ticketcall(company_id)');

  await _createIndexSafely('idx_ticketcall_call_cat_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_call_cat_id ON ticketcall(call_cat_id)');

  await _createIndexSafely('idx_ticketcall_created_by', 'ticketcall',
    'CREATE INDEX idx_ticketcall_created_by ON ticketcall(created_by)');

  await _createIndexSafely('idx_ticketcall_count_optimization', 'ticketcall',
    'CREATE INDEX idx_ticketcall_count_optimization ON ticketcall(ticket_id, company_id)');

  // =============================================================================
  // LOOKUP TABLES INDEXES
  // =============================================================================
  print('🔍 Creating lookup tables indexes...');

  await _createIndexSafely('idx_product_info_company_id', 'product_info',
    'CREATE INDEX idx_product_info_company_id ON product_info(company_id)');

  await _createIndexSafely('idx_product_info_created_by', 'product_info',
    'CREATE INDEX idx_product_info_created_by ON product_info(created_by)');

  await _createIndexSafely('idx_request_reasons_company_id', 'request_reasons',
    'CREATE INDEX idx_request_reasons_company_id ON request_reasons(company_id)');

  await _createIndexSafely('idx_request_reasons_created_by', 'request_reasons',
    'CREATE INDEX idx_request_reasons_created_by ON request_reasons(created_by)');

  await _createIndexSafely('idx_users_company_id', 'users',
    'CREATE INDEX idx_users_company_id ON users(company_id)');

  await _createIndexSafely('idx_users_is_active', 'users',
    'CREATE INDEX idx_users_is_active ON users(is_active)');

  // =============================================================================
  // ADDITIONAL PERFORMANCE INDEXES
  // =============================================================================
  print('⚡ Creating additional performance indexes...');

  await _createIndexSafely('idx_tickets_updated_at', 'tickets',
    'CREATE INDEX idx_tickets_updated_at ON tickets(updated_at)');

  await _createIndexSafely('idx_customers_updated_at', 'customers',
    'CREATE INDEX idx_customers_updated_at ON customers(updated_at)');

  await _createIndexSafely('idx_ticket_items_updated_at', 'ticket_items',
    'CREATE INDEX idx_ticket_items_updated_at ON ticket_items(updated_at)');

  await _createIndexSafely('idx_ticketcall_created_at', 'ticketcall',
    'CREATE INDEX idx_ticketcall_created_at ON ticketcall(created_at)');

  // =============================================================================
  // SEARCH OPTIMIZATION INDEXES
  // =============================================================================
  print('🔍 Creating search optimization indexes...');

  // For search functionality - prefix indexes for LIKE queries
  await _createIndexSafely('idx_tickets_description_prefix', 'tickets',
    'CREATE INDEX idx_tickets_description_prefix ON tickets(description(50))');

  await _createIndexSafely('idx_customers_name_prefix', 'customers',
    'CREATE INDEX idx_customers_name_prefix ON customers(name(50))');

  print('\n🎉 All tickets report indexes created successfully!');
}
