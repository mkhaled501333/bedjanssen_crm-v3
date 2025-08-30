import 'package:mysql1/mysql1.dart';
import 'base_migrations.dart';

/// Create additional indexes for ticket items report view optimization
Future<void> createTicketItemsReportIndexes(MySqlConnection conn) async {
  print('Creating additional indexes for ticket items report view optimization...');

  // =============================================================================
  // TICKET ITEMS REPORT VIEW PERFORMANCE INDEXES (فهارس تحسين أداء تقرير عناصر التذاكر)
  // =============================================================================
  
  // فهارس أساسية للفلترة حسب الإجراء (استبدال، صيانة)
  await createIndexSafely(conn, 'idx_ticket_items_action', 'ticket_items',
    'CREATE INDEX idx_ticket_items_action ON ticket_items(action)');
  
  // فهارس مركبة للشركة والإجراء - للفلترة المتقدمة
  await createIndexSafely(conn, 'idx_ticket_items_company_action', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_action ON ticket_items(company_id, action)');
  
  // فهارس حالة السحب والتسليم - لتتبع حالة العناصر
  await createIndexSafely(conn, 'idx_ticket_items_pulled_status', 'ticket_items',
    'CREATE INDEX idx_ticket_items_pulled_status ON ticket_items(pulled_status)');
  await createIndexSafely(conn, 'idx_ticket_items_delivered_status', 'ticket_items',
    'CREATE INDEX idx_ticket_items_delivered_status ON ticket_items(delivered_status)');
  
  // فهارس مركبة للشركة وحالة السحب والتسليم
  await createIndexSafely(conn, 'idx_ticket_items_company_pulled', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_pulled ON ticket_items(company_id, pulled_status)');
  await createIndexSafely(conn, 'idx_ticket_items_company_delivered', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_delivered ON ticket_items(company_id, delivered_status)');
  
  // فهارس الفحص والتاريخ - للفلترة الزمنية
  await createIndexSafely(conn, 'idx_ticket_items_inspected', 'ticket_items',
    'CREATE INDEX idx_ticket_items_inspected ON ticket_items(inspected)');
  await createIndexSafely(conn, 'idx_ticket_items_inspection_date', 'ticket_items',
    'CREATE INDEX idx_ticket_items_inspection_date ON ticket_items(inspection_date)');
  
  // فهرس مركب للشركة والفحص والتاريخ
  await createIndexSafely(conn, 'idx_ticket_items_company_inspection', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_inspection ON ticket_items(company_id, inspected, inspection_date)');
  
  // فهارس جغرافية مركبة - للفلترة حسب الموقع
  await createIndexSafely(conn, 'idx_ticket_items_company_location', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_location ON ticket_items(company_id, governomate_id, city_id)');
  await createIndexSafely(conn, 'idx_ticket_items_location_customer', 'ticket_items',
    'CREATE INDEX idx_ticket_items_location_customer ON ticket_items(governomate_id, city_id, customer_id)');
  
  // فهارس المنتجات - للفلترة حسب المنتج
  await createIndexSafely(conn, 'idx_ticket_items_company_product', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_product ON ticket_items(company_id, product_id)');
  await createIndexSafely(conn, 'idx_ticket_items_product_size', 'ticket_items',
    'CREATE INDEX idx_ticket_items_product_size ON ticket_items(product_id, product_size)');
  
  // فهرس مركب للشركة والعميل - للفلترة المتقدمة
  await createIndexSafely(conn, 'idx_ticket_items_company_customer', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_customer ON ticket_items(company_id, customer_id)');
  
  // فهارس مركبة للفلترة المعقدة - تغطي جميع شروط البحث
  await createIndexSafely(conn, 'idx_ticket_items_company_action_status', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_action_status ON ticket_items(company_id, action, pulled_status, delivered_status)');
  
  // فهرس شامل للتقارير المتقدمة - يغطي جميع شروط البحث الشائعة
  await createIndexSafely(conn, 'idx_ticket_items_comprehensive_report', 'ticket_items',
    'CREATE INDEX idx_ticket_items_comprehensive_report ON ticket_items(company_id, governomate_id, city_id, action, inspected, inspection_date)');

  // =============================================================================
  // TICKET ITEM CHANGE TABLES INDEXES (فهارس جداول تغيير عناصر التذاكر)
  // =============================================================================
  
  // فهارس لجدول استبدال المنتج المماثل
  await createIndexSafely(conn, 'idx_ticket_item_change_same_ticket_item', 'ticket_item_change_same',
    'CREATE INDEX idx_ticket_item_change_same_ticket_item ON ticket_item_change_same(ticket_item_id)');
  await createIndexSafely(conn, 'idx_ticket_item_change_same_pulled', 'ticket_item_change_same',
    'CREATE INDEX idx_ticket_item_change_same_pulled ON ticket_item_change_same(pulled)');
  await createIndexSafely(conn, 'idx_ticket_item_change_same_delivered', 'ticket_item_change_same',
    'CREATE INDEX idx_ticket_item_change_same_delivered ON ticket_item_change_same(delivered)');
  
  // فهارس لجدول استبدال المنتج المختلف
  await createIndexSafely(conn, 'idx_ticket_item_change_another_ticket_item', 'ticket_item_change_another',
    'CREATE INDEX idx_ticket_item_change_another_ticket_item ON ticket_item_change_another(ticket_item_id)');
  await createIndexSafely(conn, 'idx_ticket_item_change_another_pulled', 'ticket_item_change_another',
    'CREATE INDEX idx_ticket_item_change_another_pulled ON ticket_item_change_another(pulled)');
  await createIndexSafely(conn, 'idx_ticket_item_change_another_delivered', 'ticket_item_change_another',
    'CREATE INDEX idx_ticket_item_change_another_delivered ON ticket_item_change_another(delivered)');
  
  // فهارس لجدول الصيانة
  await createIndexSafely(conn, 'idx_ticket_item_maintenance_ticket_item', 'ticket_item_maintenance',
    'CREATE INDEX idx_ticket_item_maintenance_ticket_item ON ticket_item_maintenance(ticket_item_id)');
  await createIndexSafely(conn, 'idx_ticket_item_maintenance_pulled', 'ticket_item_maintenance',
    'CREATE INDEX idx_ticket_item_maintenance_pulled ON ticket_item_maintenance(pulled)');
  await createIndexSafely(conn, 'idx_ticket_item_maintenance_delivered', 'ticket_item_maintenance',
    'CREATE INDEX idx_ticket_item_maintenance_delivered ON ticket_item_maintenance(delivered)');

  // =============================================================================
  // ADDITIONAL TICKET ITEMS INDEXES (فهارس إضافية لعناصر التذاكر)
  // =============================================================================
  
  // فهرس مركب للشركة والمنتج وحجم المنتج
  await createIndexSafely(conn, 'idx_ticket_items_company_product_size', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_product_size ON ticket_items(company_id, product_id, product_size)');
  
  // فهرس مركب للشركة وسبب الطلب
  await createIndexSafely(conn, 'idx_ticket_items_company_request_reason', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_request_reason ON ticket_items(company_id, request_reason_id)');
  
  // فهرس مركب للشركة والفحص والتاريخ
  await createIndexSafely(conn, 'idx_ticket_items_company_inspection_date', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_inspection_date ON ticket_items(company_id, inspected, inspection_date)');
  
  // فهرس شامل للتقارير المتقدمة - يغطي جميع شروط البحث الشائعة
  await createIndexSafely(conn, 'idx_ticket_items_advanced_reporting', 'ticket_items',
    'CREATE INDEX idx_ticket_items_advanced_reporting ON ticket_items(company_id, governomate_id, city_id, action, inspected, pulled_status, delivered_status)');

  print('✓ Additional ticket items report indexes created successfully.');
}
