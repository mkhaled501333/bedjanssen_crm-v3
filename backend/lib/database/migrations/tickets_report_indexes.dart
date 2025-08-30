import 'package:mysql1/mysql1.dart';
import 'base_migrations.dart';

/// Create optimized indexes for tickets report service
Future<void> createOptimizedTicketsReportIndexes(MySqlConnection conn) async {
  print('Creating optimized indexes for tickets report service...');

  // =============================================================================
  // CORE TICKETS TABLE INDEXES (المهم فقط)
  // =============================================================================
  
  // فهرس معرف الشركة - للفلترة الأساسية
  await createIndexSafely(conn, 'idx_tickets_company_id', 'tickets',
    'CREATE INDEX idx_tickets_company_id ON tickets(company_id)');
  
  // فهرس حالة التذكرة - للفلترة حسب الحالة
  await createIndexSafely(conn, 'idx_tickets_status', 'tickets',
    'CREATE INDEX idx_tickets_status ON tickets(status)');
  
  // فهرس أولوية التذكرة - للفلترة حسب الأولوية
  await createIndexSafely(conn, 'idx_tickets_priority', 'tickets',
    'CREATE INDEX idx_tickets_priority ON tickets(priority)');
  
  // فهرس تاريخ الإنشاء - للترتيب والفلترة الزمنية
  await createIndexSafely(conn, 'idx_tickets_created_at', 'tickets',
    'CREATE INDEX idx_tickets_created_at ON tickets(created_at)');
  
  // فهرس معرف العميل - لربط التذاكر بالعملاء
  await createIndexSafely(conn, 'idx_tickets_customer_id', 'tickets',
    'CREATE INDEX idx_tickets_customer_id ON tickets(customer_id)');
  
  // فهرس فئة التذكرة - للفلترة حسب الفئة
  await createIndexSafely(conn, 'idx_tickets_ticket_cat_id', 'tickets',
    'CREATE INDEX idx_tickets_ticket_cat_id ON tickets(ticket_cat_id)');
  
  // فهرس منشئ التذكرة - للفلترة حسب المستخدم
  await createIndexSafely(conn, 'idx_tickets_created_by', 'tickets',
    'CREATE INDEX idx_tickets_created_by ON tickets(created_by)');
  
  // فهرس من أغلق التذكرة - للتقارير
  await createIndexSafely(conn, 'idx_tickets_closed_by', 'tickets',
    'CREATE INDEX idx_tickets_closed_by ON tickets(closed_by)');
  
  // فهرس مركب للشركة والحالة - للفلترة المتقدمة
  await createIndexSafely(conn, 'idx_tickets_company_status', 'tickets',
    'CREATE INDEX idx_tickets_company_status ON tickets(company_id, status)');
  
  // فهرس مركب للشركة والأولوية - للفلترة المتقدمة
  await createIndexSafely(conn, 'idx_tickets_company_priority', 'tickets',
    'CREATE INDEX idx_tickets_company_priority ON tickets(company_id, priority)');
  
  // فهرس مركب للشركة والتاريخ - للتقارير الزمنية
  await createIndexSafely(conn, 'idx_tickets_company_date', 'tickets',
    'CREATE INDEX idx_tickets_company_date ON tickets(company_id, created_at)');
  
  // فهرس مركب للشركة والعميل - للفلترة المتقدمة
  await createIndexSafely(conn, 'idx_tickets_company_customer', 'tickets',
    'CREATE INDEX idx_tickets_company_customer ON tickets(company_id, customer_id)');
  
  // فهرس مركب للشركة والفئة - للفلترة المتقدمة
  await createIndexSafely(conn, 'idx_tickets_company_category', 'tickets',
    'CREATE INDEX idx_tickets_company_category ON tickets(company_id, ticket_cat_id)');
  
  // فهرس مركب للشركة والتاريخ والحالة - للتقارير المتقدمة
  await createIndexSafely(conn, 'idx_tickets_company_date_status', 'tickets',
    'CREATE INDEX idx_tickets_company_date_status ON tickets(company_id, created_at, status)');
  
  // فهرس شامل للفلترة المعقدة - يغطي جميع شروط البحث
  await createIndexSafely(conn, 'idx_tickets_complex_filter', 'tickets',
    'CREATE INDEX idx_tickets_complex_filter ON tickets(company_id, customer_id, ticket_cat_id, status, priority, created_at)');

  // =============================================================================
  // CUSTOMERS TABLE INDEXES (فهارس العملاء)
  // =============================================================================
  
  // فهرس معرف الشركة - للفلترة الأساسية
  await createIndexSafely(conn, 'idx_customers_company_id', 'customers',
    'CREATE INDEX idx_customers_company_id ON customers(company_id)');
  
  // فهرس معرف المحافظة - للفلترة الجغرافية
  await createIndexSafely(conn, 'idx_customers_governomate_id', 'customers',
    'CREATE INDEX idx_customers_governomate_id ON customers(governomate_id)');
  
  // فهرس معرف المدينة - للفلترة الجغرافية
  await createIndexSafely(conn, 'idx_customers_city_id', 'customers',
    'CREATE INDEX idx_customers_city_id ON customers(city_id)');
  
  // فهرس منشئ العميل - للتقارير
  await createIndexSafely(conn, 'idx_customers_created_by', 'customers',
    'CREATE INDEX idx_customers_created_by ON customers(created_by)');
  
  // فهرس اسم العميل - للبحث
  await createIndexSafely(conn, 'idx_customers_name', 'customers',
    'CREATE INDEX idx_customers_name ON customers(name)');
  
  // فهرس مركب للشركة والاسم - للبحث المتقدم
  await createIndexSafely(conn, 'idx_customers_company_name', 'customers',
    'CREATE INDEX idx_customers_company_name ON customers(company_id, name)');

  // =============================================================================
  // TICKET_CATEGORIES TABLE INDEXES (فئات التذاكر)
  // =============================================================================
  
  // فهرس اسم فئة التذكرة - للبحث
  await createIndexSafely(conn, 'idx_ticket_categories_name', 'ticket_categories',
    'CREATE INDEX idx_ticket_categories_name ON ticket_categories(name)');
  
  // فهرس معرف الشركة - للفلترة
  await createIndexSafely(conn, 'idx_ticket_categories_company_id', 'ticket_categories',
    'CREATE INDEX idx_ticket_categories_company_id ON ticket_categories(company_id)');

  // =============================================================================
  // TICKET_ITEMS TABLE INDEXES (عناصر التذاكر - الأهم للأداء)
  // =============================================================================
  
  // فهرس معرف التذكرة - للربط الأساسي
  await createIndexSafely(conn, 'idx_ticket_items_ticket_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_ticket_id ON ticket_items(ticket_id)');
  
  // فهرس معرف المنتج - للفلترة
  await createIndexSafely(conn, 'idx_ticket_items_product_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_product_id ON ticket_items(product_id)');
  
  // فهرس سبب الطلب - للفلترة
  await createIndexSafely(conn, 'idx_ticket_items_request_reason_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_request_reason_id ON ticket_items(request_reason_id)');
  
  // فهرس منشئ العنصر - للتقارير
  await createIndexSafely(conn, 'idx_ticket_items_created_by', 'ticket_items',
    'CREATE INDEX idx_ticket_items_created_by ON ticket_items(created_by)');
  
  // فهرس معرف الشركة - للفلترة
  await createIndexSafely(conn, 'idx_ticket_items_company_id', 'ticket_items',
    'CREATE INDEX idx_ticket_items_company_id ON ticket_items(company_id)');
  
  // فهرس مركب للتذكرة والتاريخ - للترتيب الزمني
  await createIndexSafely(conn, 'idx_ticket_items_ticket_created', 'ticket_items',
    'CREATE INDEX idx_ticket_items_ticket_created ON ticket_items(ticket_id, created_at)');
  
  // فهرس شامل للاستعلامات المعقدة - يغطي جميع شروط البحث
  await createIndexSafely(conn, 'idx_ticket_items_batch_query', 'ticket_items',
    'CREATE INDEX idx_ticket_items_batch_query ON ticket_items(ticket_id, product_id, request_reason_id, created_at)');

  // =============================================================================
  // TICKETCALL TABLE INDEXES (مكالمات التذاكر)
  // =============================================================================
  
  // فهرس معرف التذكرة - للربط الأساسي
  await createIndexSafely(conn, 'idx_ticketcall_ticket_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_ticket_id ON ticketcall(ticket_id)');
  
  // فهرس معرف الشركة - للفلترة
  await createIndexSafely(conn, 'idx_ticketcall_company_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_company_id ON ticketcall(company_id)');
  
  // فهرس فئة المكالمة - للفلترة
  await createIndexSafely(conn, 'idx_ticketcall_call_cat_id', 'ticketcall',
    'CREATE INDEX idx_ticketcall_call_cat_id ON ticketcall(call_cat_id)');
  
  // فهرس منشئ المكالمة - للتقارير
  await createIndexSafely(conn, 'idx_ticketcall_created_by', 'ticketcall',
    'CREATE INDEX idx_ticketcall_created_by ON ticketcall(created_by)');
  
  // فهرس مركب للعد السريع - لتحسين أداء العد
  await createIndexSafely(conn, 'idx_ticketcall_count_optimization', 'ticketcall',
    'CREATE INDEX idx_ticketcall_count_optimization ON ticketcall(ticket_id, company_id)');

  // =============================================================================
  // PRODUCT_INFO TABLE INDEXES (معلومات المنتجات)
  // =============================================================================
  
  // فهرس معرف الشركة - للفلترة
  await createIndexSafely(conn, 'idx_product_info_company_id', 'product_info',
    'CREATE INDEX idx_product_info_company_id ON product_info(company_id)');
  
  // فهرس منشئ المنتج - للتقارير
  await createIndexSafely(conn, 'idx_product_info_created_by', 'product_info',
    'CREATE INDEX idx_product_info_created_by ON product_info(created_by)');

  // =============================================================================
  // REQUEST_REASONS TABLE INDEXES (أسباب الطلبات)
  // =============================================================================
  
  // فهرس معرف الشركة - للفلترة
  await createIndexSafely(conn, 'idx_request_reasons_company_id', 'request_reasons',
    'CREATE INDEX idx_request_reasons_company_id ON request_reasons(company_id)');
  
  // فهرس منشئ سبب الطلب - للتقارير
  await createIndexSafely(conn, 'idx_request_reasons_created_by', 'request_reasons',
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
  await createIndexSafely(conn, 'idx_users_company_id', 'users',
    'CREATE INDEX idx_users_company_id ON users(company_id)');
  
  // فهرس حالة النشاط - للفلترة
  await createIndexSafely(conn, 'idx_users_is_active', 'users',
    'CREATE INDEX idx_users_is_active ON users(is_active)');

  // =============================================================================
  // ADDITIONAL OPTIMIZATION INDEXES (فهارس تحسين إضافية)
  // =============================================================================
  
  // فهرس بادئة وصف التذكرة - لتحسين البحث النصي
  await createIndexSafely(conn, 'idx_tickets_description_prefix', 'tickets',
    'CREATE INDEX idx_tickets_description_prefix ON tickets(description(50))');
  
  // فهرس بادئة اسم العميل - لتحسين البحث النصي
  await createIndexSafely(conn, 'idx_customers_name_prefix', 'customers',
    'CREATE INDEX idx_customers_name_prefix ON customers(name(50))');

  // =============================================================================
  // PERFORMANCE MONITORING INDEXES (فهارس مراقبة الأداء)
  // =============================================================================
  
  // فهرس تاريخ التحديث للتذاكر - لمراقبة الأداء
  await createIndexSafely(conn, 'idx_tickets_updated_at', 'tickets',
    'CREATE INDEX idx_tickets_updated_at ON tickets(updated_at)');
  
  // فهرس تاريخ التحديث للعملاء - لمراقبة الأداء
  await createIndexSafely(conn, 'idx_customers_updated_at', 'customers',
    'CREATE INDEX idx_customers_updated_at ON customers(updated_at)');
  
  // فهرس تاريخ التحديث لعناصر التذاكر - لمراقبة الأداء
  await createIndexSafely(conn, 'idx_ticket_items_updated_at', 'ticket_items',
    'CREATE INDEX idx_ticket_items_updated_at ON ticket_items(updated_at)');
  
  // فهرس تاريخ إنشاء مكالمات التذاكر - لمراقبة الأداء
  await createIndexSafely(conn, 'idx_ticketcall_created_at', 'ticketcall',
    'CREATE INDEX idx_ticketcall_created_at ON ticketcall(created_at)');

  print('✓ Optimized tickets report indexes created successfully.');
}
