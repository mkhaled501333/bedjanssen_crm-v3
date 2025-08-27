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

/// Create optimized indexes for tickets report service
Future<void> _createOptimizedTicketsReportIndexes(MySqlConnection conn) async {
  print('Creating optimized indexes for tickets report service...');

  // =============================================================================
  // CORE TICKETS TABLE INDEXES (المهم فقط)
  // =============================================================================
  
  // فهرس معرف الشركة - للفلترة الأساسية
  await _createIndexSafely(conn, 'idx_tickets_company_id', 'tickets',
    'CREATE INDEX idx_tickets_company_id ON tickets(company_id)');
  
  // فهرس حالة التذكرة - للفلترة حسب الحالة
  await _createIndexSafely(conn, 'idx_tickets_status', 'tickets',
    'CREATE INDEX idx_tickets_status ON tickets(status)');
  
  // فهرس أولوية التذكرة - للفلترة حسب الأولوية
  await _createIndexSafely(conn, 'idx_tickets_priority', 'tickets',
    'CREATE INDEX idx_tickets_priority ON tickets(priority)');
  
  // فهرس تاريخ الإنشاء - للترتيب والفلترة الزمنية
  await _createIndexSafely(conn, 'idx_tickets_created_at', 'tickets',
    'CREATE INDEX idx_tickets_created_at ON tickets(created_at)');
  
  // فهرس معرف العميل - لربط التذاكر بالعملاء
  await _createIndexSafely(conn, 'idx_tickets_customer_id', 'tickets',
    'CREATE INDEX idx_tickets_customer_id ON tickets(customer_id)');
  
  // فهرس فئة التذكرة - للفلترة حسب الفئة
  await _createIndexSafely(conn, 'idx_tickets_ticket_cat_id', 'tickets',
    'CREATE INDEX idx_tickets_ticket_cat_id ON tickets(ticket_cat_id)');
  
  // فهرس منشئ التذكرة - للفلترة حسب المستخدم
  await _createIndexSafely(conn, 'idx_tickets_created_by', 'tickets',
    'CREATE INDEX idx_tickets_created_by ON tickets(created_by)');
  
  // فهرس من أغلق التذكرة - للتقارير
  await _createIndexSafely(conn, 'idx_tickets_closed_by', 'tickets',
    'CREATE INDEX idx_tickets_closed_by ON tickets(closed_by)');
  
  // فهرس مركب للشركة والحالة - للفلترة المتقدمة
  await _createIndexSafely(conn, 'idx_tickets_company_status', 'tickets',
    'CREATE INDEX idx_tickets_company_status ON tickets(company_id, status)');
  
  // فهرس مركب للشركة والأولوية - للفلترة المتقدمة
  await _createIndexSafely(conn, 'idx_tickets_company_priority', 'tickets',
    'CREATE INDEX idx_tickets_company_priority ON tickets(company_id, priority)');
  
  // فهرس مركب للشركة والتاريخ - للتقارير الزمنية
  await _createIndexSafely(conn, 'idx_tickets_company_date', 'tickets',
    'CREATE INDEX idx_tickets_company_date ON tickets(company_id, created_at)');
  
  // فهرس مركب للشركة والعميل - للفلترة المتقدمة
  await _createIndexSafely(conn, 'idx_tickets_company_customer', 'tickets',
    'CREATE INDEX idx_tickets_company_customer ON tickets(company_id, customer_id)');
  
  // فهرس مركب للشركة والفئة - للفلترة المتقدمة
  await _createIndexSafely(conn, 'idx_tickets_company_category', 'tickets',
    'CREATE INDEX idx_tickets_company_category ON tickets(company_id, ticket_cat_id)');
  
  // فهرس مركب للشركة والتاريخ والحالة - للتقارير المتقدمة
  await _createIndexSafely(conn, 'idx_tickets_company_date_status', 'tickets',
    'CREATE INDEX idx_tickets_company_date_status ON tickets(company_id, created_at, status)');
  
  // فهرس شامل للفلترة المعقدة - يغطي جميع شروط البحث
  await _createIndexSafely(conn, 'idx_tickets_complex_filter', 'tickets',
    'CREATE INDEX idx_tickets_complex_filter ON tickets(company_id, customer_id, ticket_cat_id, status, priority, created_at)');

  // =============================================================================
  // CUSTOMERS TABLE INDEXES (فهارس العملاء)
  // =============================================================================
  
  // فهرس معرف الشركة - للفلترة الأساسية
  await _createIndexSafely(conn, 'idx_customers_company_id', 'customers',
    'CREATE INDEX idx_customers_company_id ON customers(company_id)');
  
  // فهرس معرف المحافظة - للفلترة الجغرافية
  await _createIndexSafely(conn, 'idx_customers_governomate_id', 'customers',
    'CREATE INDEX idx_customers_governomate_id ON customers(governomate_id)');
  
  // فهرس معرف المدينة - للفلترة الجغرافية
  await _createIndexSafely(conn, 'idx_customers_city_id', 'customers',
    'CREATE INDEX idx_customers_city_id ON customers(city_id)');
  
  // فهرس منشئ العميل - للتقارير
  await _createIndexSafely(conn, 'idx_customers_created_by', 'customers',
    'CREATE INDEX idx_customers_created_by ON customers(created_by)');
  
  // فهرس اسم العميل - للبحث
  await _createIndexSafely(conn, 'idx_customers_name', 'customers',
    'CREATE INDEX idx_customers_name ON customers(name)');
  
  // فهرس مركب للشركة والاسم - للبحث المتقدم
  await _createIndexSafely(conn, 'idx_customers_company_name', 'customers',
    'CREATE INDEX idx_customers_company_name ON customers(company_id, name)');

  // =============================================================================
  // TICKET_CATEGORIES TABLE INDEXES (فئات التذاكر)
  // =============================================================================
  
  // فهرس اسم فئة التذكرة - للبحث
  await _createIndexSafely(conn, 'idx_ticket_categories_name', 'ticket_categories',
    'CREATE INDEX idx_ticket_categories_name ON ticket_categories(name)');
  
  // فهرس معرف الشركة - للفلترة
  await _createIndexSafely(conn, 'idx_ticket_categories_company_id', 'ticket_categories',
    'CREATE INDEX idx_ticket_categories_company_id ON ticket_categories(company_id)');

  // =============================================================================
  // TICKET_ITEMS TABLE INDEXES (عناصر التذاكر - الأهم للأداء)
  // =============================================================================
  
  // فهرس معرف التذكرة - للربط الأساسي
  await _createIndexSafely(conn, 'idx_ticket_items_ticket_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_ticket_id ON ticket_items(ticket_id)');
  
  // فهرس معرف المنتج - للفلترة
  await _createIndexSafely(conn, 'idx_ticket_items_product_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_product_id ON ticket_items(product_id)');
  
  // فهرس سبب الطلب - للفلترة
  await _createIndexSafely(conn, 'idx_ticket_items_request_reason_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_request_reason_id ON ticket_items(request_reason_id)');
  
  // فهرس منشئ العنصر - للتقارير
  await _createIndexSafely(conn, 'idx_ticket_items_created_by', 'ticket_items',
    'CREATE INDEX idx_ticket_items_created_by ON ticket_items(created_by)');
  
  // فهرس معرف الشركة - للفلترة
  await _createIndexSafely(conn, 'idx_ticket_items_company_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_id ON ticket_items(company_id)');
  
  // فهرس مركب للتذكرة والتاريخ - للترتيب الزمني
  await _createIndexSafely(conn, 'idx_ticket_items_ticket_created', 'ticket_items',
    'CREATE INDEX idx_ticket_items_ticket_created ON ticket_items(ticket_id, created_at)');
  
  // فهرس شامل للاستعلامات المعقدة - يغطي جميع شروط البحث
  await _createIndexSafely(conn, 'idx_ticket_items_batch_query', 'ticket_items',
    'CREATE INDEX idx_ticket_items_batch_query ON ticket_items(ticket_id, product_id, request_reason_id, created_at)');

  // =============================================================================
  // TICKETCALL TABLE INDEXES (مكالمات التذاكر)
  // =============================================================================
  
  // فهرس معرف التذكرة - للربط الأساسي
  await _createIndexSafely(conn, 'idx_ticketcall_ticket_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_ticket_id ON ticketcall(ticket_id)');
  
  // فهرس معرف الشركة - للفلترة
  await _createIndexSafely(conn, 'idx_ticketcall_company_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_company_id ON ticketcall(company_id)');
  
  // فهرس فئة المكالمة - للفلترة
  await _createIndexSafely(conn, 'idx_ticketcall_call_cat_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_call_cat_id ON ticketcall(call_cat_id)');
  
  // فهرس منشئ المكالمة - للتقارير
  await _createIndexSafely(conn, 'idx_ticketcall_created_by', 'ticketcall',
    'CREATE INDEX idx_ticketcall_created_by ON ticketcall(created_by)');
  
  // فهرس مركب للعد السريع - لتحسين أداء العد
  await _createIndexSafely(conn, 'idx_ticketcall_count_optimization', 'ticketcall',
    'CREATE INDEX idx_ticketcall_count_optimization ON ticketcall(ticket_id, company_id)');

  // =============================================================================
  // PRODUCT_INFO TABLE INDEXES (معلومات المنتجات)
  // =============================================================================
  
  // فهرس معرف الشركة - للفلترة
  await _createIndexSafely(conn, 'idx_product_info_company_id', 'product_info',
    'CREATE INDEX idx_product_info_company_id ON product_info(company_id)');
  
  // فهرس منشئ المنتج - للتقارير
  await _createIndexSafely(conn, 'idx_product_info_created_by', 'product_info',
    'CREATE INDEX idx_product_info_created_by ON product_info(created_by)');

  // =============================================================================
  // REQUEST_REASONS TABLE INDEXES (أسباب الطلبات)
  // =============================================================================
  
  // فهرس معرف الشركة - للفلترة
  await _createIndexSafely(conn, 'idx_request_reasons_company_id', 'request_reasons',
    'CREATE INDEX idx_request_reasons_company_id ON request_reasons(company_id)');
  
  // فهرس منشئ سبب الطلب - للتقارير
  await _createIndexSafely(conn, 'idx_request_reasons_created_by', 'request_reasons',
    'CREATE INDEX idx_request_reasons_created_by ON request_reasons(created_by)');

  // =============================================================================
  // COMPANIES TABLE INDEXES (الشركات)
  // =============================================================================
  
  // فهرس اسم الشركة موجود بالفعل من المايجريشنز

  // =============================================================================
  // GOVERNORATES TABLE INDEXES (المحافظات)
  // =============================================================================
  
  // فهرس معرف المحافظة موجود بالفعل كـ PRIMARY KEY

  // =============================================================================
  // CITIES TABLE INDEXES (المدن)
  // =============================================================================
  
  // فهرس معرف المدينة موجود بالفعل كـ PRIMARY KEY وفهرس المحافظة موجود من المايجريشنز

  // =============================================================================
  // USERS TABLE INDEXES (المستخدمين)
  // =============================================================================
  
  // فهرس معرف الشركة - للفلترة
  await _createIndexSafely(conn, 'idx_users_company_id', 'users',
    'CREATE INDEX idx_users_company_id ON users(company_id)');
  
  // فهرس حالة النشاط - للفلترة
  await _createIndexSafely(conn, 'idx_users_is_active', 'users',
    'CREATE INDEX idx_users_is_active ON users(is_active)');

  // =============================================================================
  // ADDITIONAL OPTIMIZATION INDEXES (فهارس تحسين إضافية)
  // =============================================================================
  
  // فهرس بادئة وصف التذكرة - لتحسين البحث النصي
  await _createIndexSafely(conn, 'idx_tickets_description_prefix', 'tickets',
    'CREATE INDEX idx_tickets_description_prefix ON tickets(description(50))');
  
  // فهرس بادئة اسم العميل - لتحسين البحث النصي
  await _createIndexSafely(conn, 'idx_customers_name_prefix', 'customers',
    'CREATE INDEX idx_customers_name_prefix ON customers(name(50))');

  // =============================================================================
  // PERFORMANCE MONITORING INDEXES (فهارس مراقبة الأداء)
  // =============================================================================
  
  // فهرس تاريخ التحديث للتذاكر - لمراقبة الأداء
  await _createIndexSafely(conn, 'idx_tickets_updated_at', 'tickets',
    'CREATE INDEX idx_tickets_updated_at ON tickets(updated_at)');
  
  // فهرس تاريخ التحديث للعملاء - لمراقبة الأداء
  await _createIndexSafely(conn, 'idx_customers_updated_at', 'customers',
    'CREATE INDEX idx_customers_updated_at ON customers(updated_at)');
  
  // فهرس تاريخ التحديث لعناصر التذاكر - لمراقبة الأداء
  await _createIndexSafely(conn, 'idx_ticket_items_updated_at', 'ticket_items',
    'CREATE INDEX idx_ticket_items_updated_at ON ticket_items(updated_at)');
  
  // فهرس تاريخ إنشاء مكالمات التذاكر - لمراقبة الأداء
  await _createIndexSafely(conn, 'idx_ticketcall_created_at', 'ticketcall',
    'CREATE INDEX idx_ticketcall_created_at ON ticketcall(created_at)');

  // =============================================================================
  // TICKET ITEMS REPORT VIEW PERFORMANCE INDEXES (فهارس تحسين أداء تقرير عناصر التذاكر)
  // =============================================================================
  
  // فهارس أساسية للفلترة حسب الإجراء (استبدال، صيانة)
  await _createIndexSafely(conn, 'idx_ticket_items_action', 'ticket_items',
    'CREATE INDEX idx_ticket_items_action ON ticket_items(action)');
  
  // فهارس مركبة للشركة والإجراء - للفلترة المتقدمة
  await _createIndexSafely(conn, 'idx_ticket_items_company_action', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_action ON ticket_items(company_id, action)');
  
  // فهارس حالة السحب والتسليم - لتتبع حالة العناصر
  await _createIndexSafely(conn, 'idx_ticket_items_pulled_status', 'ticket_items',
    'CREATE INDEX idx_ticket_items_pulled_status ON ticket_items(pulled_status)');
  await _createIndexSafely(conn, 'idx_ticket_items_delivered_status', 'ticket_items',
    'CREATE INDEX idx_ticket_items_delivered_status ON ticket_items(delivered_status)');
  
  // فهارس مركبة للشركة وحالة السحب والتسليم
  await _createIndexSafely(conn, 'idx_ticket_items_company_pulled', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_pulled ON ticket_items(company_id, pulled_status)');
  await _createIndexSafely(conn, 'idx_ticket_items_company_delivered', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_delivered ON ticket_items(company_id, delivered_status)');
  
  // فهارس الفحص والتاريخ - للفلترة الزمنية
  await _createIndexSafely(conn, 'idx_ticket_items_inspected', 'ticket_items',
    'CREATE INDEX idx_ticket_items_inspected ON ticket_items(inspected)');
  await _createIndexSafely(conn, 'idx_ticket_items_inspection_date', 'ticket_items',
    'CREATE INDEX idx_ticket_items_inspection_date ON ticket_items(inspection_date)');
  
  // فهرس مركب للشركة والفحص والتاريخ
  await _createIndexSafely(conn, 'idx_ticket_items_company_inspection', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_inspection ON ticket_items(company_id, inspected, inspection_date)');
  
  // فهارس جغرافية مركبة - للفلترة حسب الموقع
  await _createIndexSafely(conn, 'idx_ticket_items_company_location', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_location ON ticket_items(company_id, governomate_id, city_id)');
  await _createIndexSafely(conn, 'idx_ticket_items_location_customer', 'ticket_items',
    'CREATE INDEX idx_ticket_items_location_customer ON ticket_items(governomate_id, city_id, customer_id)');
  
  // فهارس المنتجات - للفلترة حسب المنتج
  await _createIndexSafely(conn, 'idx_ticket_items_company_product', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_product ON ticket_items(company_id, product_id)');
  await _createIndexSafely(conn, 'idx_ticket_items_product_size', 'ticket_items',
    'CREATE INDEX idx_ticket_items_product_size ON ticket_items(product_id, product_size)');
  
  // فهرس مركب للشركة والعميل - للفلترة المتقدمة
  await _createIndexSafely(conn, 'idx_ticket_items_company_customer', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_customer ON ticket_items(company_id, customer_id)');
  
  // فهارس مركبة للفلترة المعقدة - تغطي جميع شروط البحث
  await _createIndexSafely(conn, 'idx_ticket_items_company_action_status', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_action_status ON ticket_items(company_id, action, pulled_status, delivered_status)');
  
  // فهرس شامل للتقارير المتقدمة - يغطي جميع شروط البحث الشائعة
  await _createIndexSafely(conn, 'idx_ticket_items_comprehensive_report', 'ticket_items',
    'CREATE INDEX idx_ticket_items_comprehensive_report ON ticket_items(company_id, governomate_id, city_id, action, inspected, inspection_date)');

  print('✓ Optimized tickets report indexes created successfully.');
}

/// Create additional indexes for ticket items report view optimization
Future<void> _createTicketItemsReportIndexes(MySqlConnection conn) async {
  print('Creating additional indexes for ticket items report view optimization...');

  // =============================================================================
  // TICKET ITEM CHANGE TABLES INDEXES (فهارس جداول تغيير عناصر التذاكر)
  // =============================================================================
  
  // فهارس لجدول استبدال المنتج المماثل
  await _createIndexSafely(conn, 'idx_ticket_item_change_same_ticket_item', 'ticket_item_change_same',
    'CREATE INDEX idx_ticket_item_change_same_ticket_item ON ticket_item_change_same(ticket_item_id)');
  await _createIndexSafely(conn, 'idx_ticket_item_change_same_pulled', 'ticket_item_change_same',
    'CREATE INDEX idx_ticket_item_change_same_pulled ON ticket_item_change_same(pulled)');
  await _createIndexSafely(conn, 'idx_ticket_item_change_same_delivered', 'ticket_item_change_same',
    'CREATE INDEX idx_ticket_item_change_same_delivered ON ticket_item_change_same(delivered)');
  
  // فهارس لجدول استبدال المنتج المختلف
  await _createIndexSafely(conn, 'idx_ticket_item_change_another_ticket_item', 'ticket_item_change_another',
    'CREATE INDEX idx_ticket_item_change_another_ticket_item ON ticket_item_change_another(ticket_item_id)');
  await _createIndexSafely(conn, 'idx_ticket_item_change_another_pulled', 'ticket_item_change_another',
    'CREATE INDEX idx_ticket_item_change_another_pulled ON ticket_item_change_another(pulled)');
  await _createIndexSafely(conn, 'idx_ticket_item_change_another_delivered', 'ticket_item_change_another',
    'CREATE INDEX idx_ticket_item_change_another_delivered ON ticket_item_change_another(delivered)');
  
  // فهارس لجدول الصيانة
  await _createIndexSafely(conn, 'idx_ticket_item_maintenance_ticket_item', 'ticket_item_maintenance',
    'CREATE INDEX idx_ticket_item_maintenance_ticket_item ON ticket_item_maintenance(ticket_item_id)');
  await _createIndexSafely(conn, 'idx_ticket_item_maintenance_pulled', 'ticket_item_maintenance',
    'CREATE INDEX idx_ticket_item_maintenance_pulled ON ticket_item_maintenance(pulled)');
  await _createIndexSafely(conn, 'idx_ticket_item_maintenance_delivered', 'ticket_item_maintenance',
    'CREATE INDEX idx_ticket_item_maintenance_delivered ON ticket_item_maintenance(delivered)');

  // =============================================================================
  // ADDITIONAL TICKET ITEMS INDEXES (فهارس إضافية لعناصر التذاكر)
  // =============================================================================
  
  // فهرس مركب للشركة والمنتج وحجم المنتج
  await _createIndexSafely(conn, 'idx_ticket_items_company_product_size', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_product_size ON ticket_items(company_id, product_id, product_size)');
  
  // فهرس مركب للشركة وسبب الطلب
  await _createIndexSafely(conn, 'idx_ticket_items_company_request_reason', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_request_reason ON ticket_items(company_id, request_reason_id)');
  
  // فهرس مركب للشركة والفحص والتاريخ
  await _createIndexSafely(conn, 'idx_ticket_items_company_inspection_date', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_inspection_date ON ticket_items(company_id, inspected, inspection_date)');
  
  // فهرس شامل للتقارير المتقدمة - يغطي جميع شروط البحث الشائعة
  await _createIndexSafely(conn, 'idx_ticket_items_advanced_reporting', 'ticket_items',
    'CREATE INDEX idx_ticket_items_advanced_reporting ON ticket_items(company_id, governomate_id, city_id, action, inspected, pulled_status, delivered_status)');

  print('✓ Additional ticket items report indexes created successfully.');
}


/// Analyze and optimize existing indexes
Future<void> analyzeTicketsIndexUsage(MySqlConnection conn) async {
  print('Analyzing tickets indexes usage...');
  
  try {
    // تحقق من استخدام الفهارس
    final indexUsage = await DatabaseService.query('''
      SHOW INDEX FROM tickets 
      WHERE Key_name != 'PRIMARY'
    ''');
    
    print('Current tickets indexes:');
    for (final index in indexUsage) {
      print('- ${index['Key_name']}: ${index['Column_name']}');
    }
    
    // تحقق من إحصائيات الجداول
    final tableStats = await DatabaseService.query('''
      SELECT 
        TABLE_NAME,
        TABLE_ROWS,
        DATA_LENGTH,
        INDEX_LENGTH,
        (INDEX_LENGTH / DATA_LENGTH) * 100 as INDEX_RATIO
      FROM information_schema.TABLES 
      WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME IN ('tickets', 'ticket_items', 'customers', 'ticketcall')
    ''');
    
    print('Table statistics:');
    for (final stat in tableStats) {
      print('${stat['TABLE_NAME']}: ${stat['TABLE_ROWS']} rows, Index ratio: ${stat['INDEX_RATIO']?.toStringAsFixed(2)}%');
    }
    
  } catch (e) {
    print('Could not analyze index usage: $e');
  }
}

/// Create ticket items report view
Future<void> _createTicketItemsReportView(MySqlConnection conn) async {
  print('Creating ticket items report view...');

  try {
    await DatabaseService.query('''
      CREATE OR REPLACE VIEW ticket_items_report AS
      SELECT 
          c.id AS customer_id,
          c.name AS customer_name,
          c.governomate_id,
          g.name AS governorate_name,
          c.city_id,
          city.name AS city_name,
          t.id AS ticket_id,
          t.company_id,
          t.ticket_cat_id,
          tc.name AS ticket_category_name,
          t.status AS ticket_status,
          ti.id AS ticket_item_id,
          ti.product_id,
          pi.product_name,
          ti.product_size,
          ti.request_reason_id,
          rr.name AS request_reason_name,
          ti.inspected,
          ti.inspection_date,
          ti.client_approval,
          
          CASE 
              WHEN tica.ticket_item_id IS NOT NULL THEN 'استبدال لنفس النوع'
              WHEN tics.ticket_item_id IS NOT NULL THEN 'استبدال لنوع اخر'
              WHEN tim.ticket_item_id IS NOT NULL THEN 'صيانه'
              ELSE NULL
          END AS action,
          
          CASE 
              WHEN tica.ticket_item_id IS NOT NULL THEN tica.pulled
              WHEN tics.ticket_item_id IS NOT NULL THEN tics.pulled
              WHEN tim.ticket_item_id IS NOT NULL THEN tim.pulled
              ELSE NULL
          END AS pulled_status,
          
          CASE 
              WHEN tica.ticket_item_id IS NOT NULL THEN tica.delivered
              WHEN tics.ticket_item_id IS NOT NULL THEN tics.delivered
              WHEN tim.ticket_item_id IS NOT NULL THEN tim.delivered
              ELSE NULL
          END AS delivered_status

      FROM ticket_items ti

      LEFT JOIN product_info pi ON ti.product_id = pi.id
      LEFT JOIN request_reasons rr ON ti.request_reason_id = rr.id
      LEFT JOIN tickets t ON ti.ticket_id = t.id
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN governorates g ON c.governomate_id = g.id
      LEFT JOIN cities city ON c.city_id = city.id
      LEFT JOIN ticket_item_change_another tica ON ti.id = tica.ticket_item_id
      LEFT JOIN ticket_item_change_same tics ON ti.id = tics.ticket_item_id
      LEFT JOIN ticket_item_maintenance tim ON ti.id = tim.ticket_item_id

      ORDER BY ti.id
    ''');
    print('✓ Ticket items report view created successfully');
  } catch (e) {
    if (e.toString().contains('DDL operations are not allowed')) {
      print('⚠ DDL operations not allowed - ticket items report view may already exist');
    } else {
      print('✗ Error creating ticket items report view: $e');
      rethrow;
    }
  }
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
    await _createOptimizedTicketsReportIndexes(conn);

    // Create additional indexes for ticket items report view optimization
    await _createTicketItemsReportIndexes(conn);

    // Create ticket items report view
    await _createTicketItemsReportView(conn);

    // Insert activities data
    await _insertActivitiesData(conn);

    print('✓ All migrations completed: database schema and indexes ensured.');
  } catch (e) {
    print('✗ Migration failed: $e');
    rethrow;
  }
}

/// Insert activities data into the database
Future<void> _insertActivitiesData(MySqlConnection conn) async {
  print('Inserting activities data...');

  try {
    // Insert entities data
    await _insertEntitiesData(conn);
    
    // Insert activities data
    await _insertActivitiesTableData(conn);
    
    print('✓ Activities data inserted successfully.');
  } catch (e) {
    print('⚠ Could not insert activities data: $e');
    print('Activities data insertion skipped - tables may already contain data');
  }
}

/// Insert entities data
Future<void> _insertEntitiesData(MySqlConnection conn) async {
  final entities = [
    {'id': 1, 'name': 'users'},
    {'id': 2, 'name': 'customers'},
    {'id': 3, 'name': 'tickets'},
    {'id': 4, 'name': 'ticket_items'},
    {'id': 5, 'name': 'customercall'},
    {'id': 6, 'name': 'ticketcall'},
    {'id': 7, 'name': 'customer_phones'},
    {'id': 8, 'name': 'call_categories'},
    {'id': 9, 'name': 'cities'},
    {'id': 10, 'name': 'governorates'},
    {'id': 11, 'name': 'product_info'},
    {'id': 12, 'name': 'request_reasons'},
    {'id': 13, 'name': 'ticket_categories'},
    {'id': 14, 'name': 'companies'},
    {'id': 15, 'name': 'roles'},
    {'id': 16, 'name': 'permissions'},
    {'id': 17, 'name': 'ticket_item_change_same'},
    {'id': 18, 'name': 'ticket_item_change_another'},
    {'id': 19, 'name': 'ticket_item_maintenance'},
  ];

  for (final entity in entities) {
    try {
      await DatabaseService.query(
        'INSERT IGNORE INTO entities (id, name) VALUES (?, ?)',
        parameters: [entity['id'], entity['name']]
      );
    } catch (e) {
      // Ignore duplicate key errors
      if (!e.toString().contains('Duplicate entry')) {
        print('⚠ Error inserting entity ${entity['name']}: $e');
      }
    }
  }
}

/// Insert activities data
Future<void> _insertActivitiesTableData(MySqlConnection conn) async {
  final activities = [
    // Auth Activities (ID Range: 1-99)
    {'id': 1, 'name': 'User login', 'description': 'تسجيل دخول المستخدم إلى النظام'},
    {'id': 2, 'name': 'User logout', 'description': 'تسجيل خروج المستخدم من النظام'},
    {'id': 3, 'name': 'Get user profile', 'description': 'الحصول على ملف تعريف المستخدم'},
    {'id': 4, 'name': 'Update user profile', 'description': 'تحديث ملف تعريف المستخدم'},

    // Customer Activities (ID Range: 100-199)
    {'id': 100, 'name': 'Get customer details', 'description': 'استرداد معلومات مفصلة عن عميل محدد بما في ذلك التفاصيل الشخصية وأرقام الهواتف والبيانات المرتبطة'},
    {'id': 101, 'name': 'Update customer details', 'description': 'تحديث معلومات العميل بما في ذلك الاسم والعنوان والملاحظات والمحافظة والمدينة'},
    {'id': 102, 'name': 'Get customer phones', 'description': 'استرداد جميع أرقام الهواتف المرتبطة بعميل محدد'},
    {'id': 103, 'name': 'Add customer phone', 'description': 'إضافة رقم هاتف جديد للعميل'},
    {'id': 104, 'name': 'Update customer phone', 'description': 'تحديث رقم هاتف موجود للعميل'},
    {'id': 105, 'name': 'Delete customer phone', 'description': 'حذف رقم هاتف من العميل'},
    {'id': 106, 'name': 'Get customer calls', 'description': 'استرداد جميع المكالمات المرتبطة بعميل محدد'},
    {'id': 107, 'name': 'Create customer call', 'description': 'إنشاء سجل مكالمة جديد للعميل'},
    {'id': 108, 'name': 'Get customer tickets', 'description': 'استرداد جميع التذاكر المرتبطة بعميل محدد'},
    {'id': 109, 'name': 'Create customer ticket', 'description': 'إنشاء تذكرة جديدة للعميل'},
    {'id': 110, 'name': 'Create customer with call', 'description': 'إنشاء عميل جديد مع سجل مكالمة أولي في معاملة واحدة'},
    {'id': 111, 'name': 'Create customer with ticket', 'description': 'إنشاء عميل جديد مع تذكرة أولية في معاملة واحدة'},
    {'id': 112, 'name': 'Update customer name', 'description': 'تحديث اسم العميل'},
    {'id': 113, 'name': 'Update customer address', 'description': 'تحديث عنوان العميل'},
    {'id': 114, 'name': 'Update customer notes', 'description': 'تحديث ملاحظات العميل'},
    {'id': 115, 'name': 'Update customer governorate', 'description': 'تحديث محافظة العميل'},
    {'id': 116, 'name': 'Update customer city', 'description': 'تحديث مدينة العميل'},

    // Masterdata Activities (ID Range: 200-299)
    {'id': 200, 'name': 'Get all call categories', 'description': 'استرداد جميع فئات المكالمات من النظام'},
    {'id': 201, 'name': 'Create call category', 'description': 'إنشاء فئة مكالمة جديدة'},
    {'id': 202, 'name': 'Get call category by ID', 'description': 'استرداد فئة مكالمة محددة بواسطة المعرف'},
    {'id': 203, 'name': 'Update call category', 'description': 'تحديث فئة مكالمة موجودة'},
    {'id': 204, 'name': 'Delete call category', 'description': 'حذف فئة مكالمة من النظام'},
    {'id': 205, 'name': 'Get all cities', 'description': 'استرداد جميع المدن من النظام'},
    {'id': 206, 'name': 'Create city', 'description': 'إنشاء مدينة جديدة'},
    {'id': 207, 'name': 'Get city by ID', 'description': 'استرداد مدينة محددة بواسطة المعرف'},
    {'id': 208, 'name': 'Update city', 'description': 'تحديث مدينة موجودة'},
    {'id': 209, 'name': 'Delete city', 'description': 'حذف مدينة من النظام'},
    {'id': 210, 'name': 'Get all companies', 'description': 'استرداد جميع الشركات من النظام'},
    {'id': 211, 'name': 'Get all governorates', 'description': 'استرداد جميع المحافظات من النظام'},
    {'id': 212, 'name': 'Create governorate', 'description': 'إنشاء محافظة جديدة'},
    {'id': 213, 'name': 'Get governorate by ID', 'description': 'استرداد محافظة محددة بواسطة المعرف'},
    {'id': 214, 'name': 'Update governorate', 'description': 'تحديث محافظة موجودة'},
    {'id': 215, 'name': 'Delete governorate', 'description': 'حذف محافظة من النظام'},
    {'id': 216, 'name': 'Get all governorates with cities', 'description': 'استرداد جميع المحافظات مع المدن المرتبطة بها'},
    {'id': 217, 'name': 'Get all products', 'description': 'استرداد جميع المنتجات من النظام'},
    {'id': 218, 'name': 'Create product', 'description': 'إنشاء منتج جديد'},
    {'id': 219, 'name': 'Get product by ID', 'description': 'استرداد منتج محدد بواسطة المعرف'},
    {'id': 220, 'name': 'Update product', 'description': 'تحديث منتج موجود'},
    {'id': 221, 'name': 'Delete product', 'description': 'حذف منتج من النظام'},
    {'id': 222, 'name': 'Get all request reasons', 'description': 'استرداد جميع أسباب الطلبات من النظام'},
    {'id': 223, 'name': 'Create request reason', 'description': 'إنشاء سبب طلب جديد'},
    {'id': 224, 'name': 'Get request reason by ID', 'description': 'استرداد سبب طلب محدد بواسطة المعرف'},
    {'id': 225, 'name': 'Update request reason', 'description': 'تحديث سبب طلب موجود'},
    {'id': 226, 'name': 'Delete request reason', 'description': 'حذف سبب طلب من النظام'},
    {'id': 227, 'name': 'Get all ticket categories', 'description': 'استرداد جميع فئات التذاكر من النظام'},
    {'id': 228, 'name': 'Create ticket category', 'description': 'إنشاء فئة تذكرة جديدة'},
    {'id': 229, 'name': 'Get ticket category by ID', 'description': 'استرداد فئة تذكرة محددة بواسطة المعرف'},
    {'id': 230, 'name': 'Update ticket category', 'description': 'تحديث فئة تذكرة موجودة'},
    {'id': 231, 'name': 'Delete ticket category', 'description': 'حذف فئة تذكرة من النظام'},

    // Reports Activities (ID Range: 300-399)
    {'id': 300, 'name': 'Get agent calls report', 'description': 'استرداد جميع المكالمات (مكالمات العملاء ومكالمات التذاكر) التي أنشأها مستخدم محدد خلال نطاق زمني'},
    {'id': 301, 'name': 'Get tickets report', 'description': 'استرداد تقرير التذاكر المقسم إلى صفحات للشركة مع خيارات التصفية الاختيارية'},
    {'id': 302, 'name': 'Export tickets report as CSV', 'description': 'تصدير تقرير التذاكر بتنسيق CSV مع جميع خيارات التصفية'},
    {'id': 303, 'name': 'Export tickets report as Excel', 'description': 'تصدير تقرير التذاكر بتنسيق Excel مع جميع خيارات التصفية'},
    {'id': 304, 'name': 'Export tickets report as PDF', 'description': 'تصدير تقرير التذاكر بتنسيق PDF مع جميع خيارات التصفية'},

    // Search Activities (ID Range: 400-499)
    {'id': 400, 'name': 'Search customers by name', 'description': 'البحث عن العملاء بالاسم باستخدام المطابقة الجزئية'},
    {'id': 401, 'name': 'Search customers by phone', 'description': 'البحث عن العملاء برقم الهاتف باستخدام المطابقة الجزئية'},
    {'id': 402, 'name': 'Auto-detect customer search', 'description': 'الكشف التلقائي عما إذا كان الاستعلام رقم هاتف أم اسم وتنفيذ البحث المناسب'},

    // Tickets Activities (ID Range: 500-599)
    {'id': 500, 'name': 'Create ticket with call and item', 'description': 'إنشاء تذكرة جديدة مع سجل مكالمة وعنصر مرتبط في معاملة واحدة'},
    {'id': 501, 'name': 'Close ticket', 'description': 'إغلاق تذكرة موجودة مع ملاحظات الإغلاق'},
    {'id': 502, 'name': 'Update ticket category', 'description': 'تحديث فئة التذكرة الموجودة'},
    {'id': 503, 'name': 'Add call log to ticket', 'description': 'إضافة إدخال سجل مكالمة جديد إلى تذكرة موجودة'},
    {'id': 504, 'name': 'Get ticket items', 'description': 'استرداد جميع العناصر المرتبطة بتذكرة محددة'},
    {'id': 505, 'name': 'Add item to ticket', 'description': 'إضافة عنصر جديد إلى تذكرة موجودة'},
    {'id': 506, 'name': 'Update item company ID', 'description': 'تحديث معرف الشركة لعنصر التذكرة'},
    {'id': 507, 'name': 'Update item product ID', 'description': 'تحديث معرف المنتج لعنصر التذكرة'},
    {'id': 508, 'name': 'Update item quantity', 'description': 'تحديث كمية عنصر التذكرة'},
    {'id': 509, 'name': 'Update item product size', 'description': 'تحديث حجم منتج عنصر التذكرة'},
    {'id': 510, 'name': 'Update item purchase date', 'description': 'تحديث تاريخ شراء عنصر التذكرة'},
    {'id': 511, 'name': 'Update item purchase location', 'description': 'تحديث موقع شراء عنصر التذكرة'},
    {'id': 512, 'name': 'Update item request reason ID', 'description': 'تحديث معرف سبب طلب عنصر التذكرة'},
    {'id': 513, 'name': 'Update item request reason detail', 'description': 'تحديث تفاصيل سبب طلب عنصر التذكرة'},
    {'id': 514, 'name': 'Delete ticket item', 'description': 'حذف عنصر من التذكرة'},

    // Ticket Items Activities (ID Range: 600-699)
    // Different Product Replacement Activities (600-610)
    {'id': 600, 'name': 'Create different product replacement', 'description': 'إنشاء سجل استبدال منتج مختلف جديد لعنصر التذكرة'},
    {'id': 601, 'name': 'Update different product replacement product ID', 'description': 'تحديث معرف المنتج لاستبدال المنتج المختلف'},
    {'id': 602, 'name': 'Update different product replacement product size', 'description': 'تحديث حجم المنتج لاستبدال المنتج المختلف'},
    {'id': 603, 'name': 'Update different product replacement cost', 'description': 'تحديث تكلفة استبدال المنتج المختلف'},
    {'id': 604, 'name': 'Update different product replacement client approval', 'description': 'تحديث حالة موافقة العميل لاستبدال المنتج المختلف'},
    {'id': 605, 'name': 'Update different product replacement refusal reason', 'description': 'تحديث سبب رفض استبدال المنتج المختلف'},
    {'id': 606, 'name': 'Mark different product replacement as pulled', 'description': 'تحديد استبدال المنتج المختلف كمسحوب'},
    {'id': 607, 'name': 'Update different product replacement pull date', 'description': 'تحديث تاريخ السحب لاستبدال المنتج المختلف'},
    {'id': 608, 'name': 'Mark different product replacement as delivered', 'description': 'تحديد استبدال المنتج المختلف كمسلم'},
    {'id': 609, 'name': 'Update different product replacement delivery date', 'description': 'تحديث تاريخ التسليم لاستبدال المنتج المختلف'},
    {'id': 610, 'name': 'Delete different product replacement', 'description': 'حذف سجل استبدال المنتج المختلف من النظام'},
    {'id': 638, 'name': 'Mark different product replacement as unpulled', 'description': 'تحديد استبدال المنتج المختلف كغير مسحوب'},
    {'id': 639, 'name': 'Mark different product replacement as undelivered', 'description': 'تحديد استبدال المنتج المختلف كغير مسلم'},

    // Same Product Replacement Activities (611-621)
    {'id': 611, 'name': 'Create same product replacement', 'description': 'إنشاء سجل استبدال منتج مماثل جديد لعنصر التذكرة'},
    {'id': 612, 'name': 'Update same product replacement product ID', 'description': 'تحديث معرف المنتج لاستبدال المنتج المماثل'},
    {'id': 613, 'name': 'Update same product replacement product size', 'description': 'تحديث حجم المنتج لاستبدال المنتج المماثل'},
    {'id': 614, 'name': 'Update same product replacement cost', 'description': 'تحديث تكلفة استبدال المنتج المماثل'},
    {'id': 615, 'name': 'Update same product replacement client approval', 'description': 'تحديث حالة موافقة العميل لاستبدال المنتج المماثل'},
    {'id': 616, 'name': 'Update same product replacement refusal reason', 'description': 'تحديث سبب رفض استبدال المنتج المماثل'},
    {'id': 617, 'name': 'Mark same product replacement as pulled', 'description': 'تحديد استبدال المنتج المماثل كمسحوب'},
    {'id': 618, 'name': 'Update same product replacement pull date', 'description': 'تحديث تاريخ السحب لاستبدال المنتج المماثل'},
    {'id': 619, 'name': 'Mark same product replacement as delivered', 'description': 'تحديد استبدال المنتج المماثل كمسلم'},
    {'id': 620, 'name': 'Update same product replacement delivery date', 'description': 'تحديث تاريخ التسليم لاستبدال المنتج المماثل'},
    {'id': 621, 'name': 'Delete same product replacement', 'description': 'حذف سجل استبدال المنتج المماثل من النظام'},
    {'id': 640, 'name': 'Mark same product replacement as unpulled', 'description': 'تحديد استبدال المنتج المماثل كغير مسحوب'},
    {'id': 641, 'name': 'Mark same product replacement as undelivered', 'description': 'تحديد استبدال المنتج المماثل كغير مسلم'},

    // Item Inspection Activities (622-625)
    {'id': 622, 'name': 'Mark item as inspected', 'description': 'تعيين العنصر كمفحوص'},
    {'id': 623, 'name': 'Mark item as uninspected', 'description': 'تعيين العنصر كغير مفحوص'},
    {'id': 624, 'name': 'Update item inspection date', 'description': 'تحديث تاريخ فحص العنصر'},
    {'id': 625, 'name': 'Update item inspection result', 'description': 'تحديث نتيجة فحص العنصر'},

    // Maintenance Activities (626-635)
    {'id': 626, 'name': 'Create maintenance option', 'description': 'إنشاء سجل خيار صيانة جديد لعنصر التذكرة'},
    {'id': 627, 'name': 'Update maintenance steps', 'description': 'تحديث خطوات الصيانة لخيار الصيانة'},
    {'id': 628, 'name': 'Update maintenance cost', 'description': 'تحديث تكلفة الصيانة لخيار الصيانة'},
    {'id': 629, 'name': 'Update maintenance client approval', 'description': 'تحديث حالة موافقة العميل لخيار الصيانة'},
    {'id': 630, 'name': 'Update maintenance refusal reason', 'description': 'تحديث سبب رفض خيار الصيانة'},
    {'id': 631, 'name': 'Mark maintenance as pulled', 'description': 'تحديد خيار الصيانة كمسحوب'},
    {'id': 632, 'name': 'Update maintenance pull date', 'description': 'تحديث تاريخ السحب لخيار الصيانة'},
    {'id': 633, 'name': 'Mark maintenance as delivered', 'description': 'تحديد خيار الصيانة كمسلم'},
    {'id': 634, 'name': 'Update maintenance delivery date', 'description': 'تحديث تاريخ التسليم لخيار الصيانة'},
    {'id': 635, 'name': 'Delete maintenance option', 'description': 'حذف سجل خيار الصيانة من النظام'},
    {'id': 636, 'name': 'Mark maintenance as unpulled', 'description': 'تحديد خيار الصيانة كغير مسحوب'},
    {'id': 637, 'name': 'Mark maintenance as undelivered', 'description': 'تحديد خيار الصيانة كغير مسلم'},
  ];

  for (final activity in activities) {
    try {
      await DatabaseService.query(
        'INSERT IGNORE INTO activities (id, name, description) VALUES (?, ?, ?)',
        parameters: [activity['id'], activity['name'], activity['description']]
      );
    } catch (e) {
      // Ignore duplicate key errors
      if (!e.toString().contains('Duplicate entry')) {
        print('⚠ Error inserting activity ${activity['name']}: $e');
      }
    }
  }
}
