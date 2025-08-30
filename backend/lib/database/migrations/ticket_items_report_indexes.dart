import 'package:mysql1/mysql1.dart';
import 'base_migrations.dart';

/// Create additional indexes for ticket items report view optimization
Future<void> createTicketItemsReportIndexes(MySqlConnection conn) async {
  print('Creating additional indexes for ticket items report view optimization...');

  // =============================================================================
  // TICKET ITEMS REPORT VIEW PERFORMANCE INDEXES (فهارس تحسين أداء تقرير عناصر التذاكر)
  // =============================================================================
  
  // فهارس أساسية للفلترة حسب المنتج والسبب
  await createIndexSafely(conn, 'idx_ticket_items_product_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_product_id ON ticket_items(product_id)');
  
  // فهارس مركبة للشركة والمنتج - للفلترة المتقدمة
  await createIndexSafely(conn, 'idx_ticket_items_company_product', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_product ON ticket_items(company_id, product_id)');
  
  // فهارس الفحص والتاريخ - للفلترة الزمنية
  await createIndexSafely(conn, 'idx_ticket_items_inspected', 'ticket_items',
    'CREATE INDEX idx_ticket_items_inspected ON ticket_items(inspected)');
  await createIndexSafely(conn, 'idx_ticket_items_inspection_date', 'ticket_items',
    'CREATE INDEX idx_ticket_items_inspection_date ON ticket_items(inspection_date)');
  
  // فهرس مركب للشركة والفحص والتاريخ
  await createIndexSafely(conn, 'idx_ticket_items_company_inspection', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_inspection ON ticket_items(company_id, inspected, inspection_date)');
  
  // فهارس جغرافية مركبة - للفلترة حسب الموقع (من خلال التذكرة)
  await createIndexSafely(conn, 'idx_ticket_items_company_ticket', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_ticket ON ticket_items(company_id, ticket_id)');
  
  // فهارس المنتجات - للفلترة حسب المنتج
  await createIndexSafely(conn, 'idx_ticket_items_product_size', 'ticket_items',
    'CREATE INDEX idx_ticket_items_product_size ON ticket_items(product_id, product_size)');
  
  // فهرس مركب للشركة وسبب الطلب - للفلترة المتقدمة
  await createIndexSafely(conn, 'idx_ticket_items_company_request_reason', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_request_reason ON ticket_items(company_id, request_reason_id)');
  
  // فهارس مركبة للفلترة المعقدة - تغطي جميع شروط البحث المتاحة
  await createIndexSafely(conn, 'idx_ticket_items_company_inspection_status', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_inspection_status ON ticket_items(company_id, inspected, inspection_date)');
  
  // فهرس شامل للتقارير المتقدمة - يغطي جميع شروط البحث الشائعة
  await createIndexSafely(conn, 'idx_ticket_items_comprehensive_report', 'ticket_items',
    'CREATE INDEX idx_ticket_items_comprehensive_report ON ticket_items(company_id, product_id, request_reason_id, inspected, inspection_date)');

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
  
  // فهرس مركب للشركة والفحص والتاريخ
  await createIndexSafely(conn, 'idx_ticket_items_company_inspection_date', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_inspection_date ON ticket_items(company_id, inspected, inspection_date)');
  
  // فهرس شامل للتقارير المتقدمة - يغطي جميع شروط البحث الشائعة
  await createIndexSafely(conn, 'idx_ticket_items_advanced_reporting', 'ticket_items',
    'CREATE INDEX idx_ticket_items_advanced_reporting ON ticket_items(company_id, product_id, request_reason_id, inspected, inspection_date)');

  print('✓ Additional ticket items report indexes created successfully.');
}
