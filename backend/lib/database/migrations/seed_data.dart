// ignore_for_file: lines_longer_than_80_chars, avoid_print, always_use_package_imports

import 'package:mysql1/mysql1.dart';
import '../database_service.dart';

/// Insert activities data into the database
Future<void> insertActivitiesData(MySqlConnection conn) async {
  print('Inserting activities data...');

  try {
    // Insert entities data
    await insertEntitiesData(conn);
    
    // Insert permissions data
    await insertPermissionsData(conn);
    
    // Insert activities data
    await insertActivitiesTableData(conn);
    
    print('✓ Activities data inserted successfully.');
  } catch (e) {
    print('⚠ Could not insert activities data: $e');
    print('Activities data insertion skipped - tables may already contain data');
  }
}

/// Insert entities data
Future<void> insertEntitiesData(MySqlConnection conn) async {
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
        parameters: [entity['id'], entity['name']],
        userId: 1, // System user for seeding
      );
    } catch (e) {
      // Ignore duplicate key errors
      if (!e.toString().contains('Duplicate entry')) {
        print('⚠ Error inserting entity ${entity['name']}: $e');
      }
    }
  }
}

/// Insert permissions data
Future<void> insertPermissionsData(MySqlConnection conn) async {
  print('Inserting permissions data...');

  final permissions = [
    {'id': 1, 'title': 'View Users', 'description': 'Can view user information and user lists'},
    {'id': 40, 'title': 'View Master Data', 'description': 'Can view master data (categories, products, etc.)'},
  ];

  for (final permission in permissions) {
    try {
      await DatabaseService.query(
        'INSERT IGNORE INTO permissions (id, title, description) VALUES (?, ?, ?)',
        parameters: [permission['id'], permission['title'], permission['description']],
        userId: 1, // System user for seeding
      );
    } catch (e) {
      // Ignore duplicate key errors
      if (!e.toString().contains('Duplicate entry')) {
        print('⚠ Error inserting permission ${permission['title']}: $e');
      }
    }
  }
  
  print('✓ Permissions data inserted successfully.');
}

/// Insert activities data
Future<void> insertActivitiesTableData(MySqlConnection conn) async {
  final activities = [
    // Auth Activities (ID Range: 1-99)
    {'id': 1, 'name': 'User login', 'description': 'تسجيل دخول المستخدم إلى النظام'},
    {'id': 2, 'name': 'User logout', 'description': 'تسجيل خروج المستخدم من النظام'},
    {'id': 3, 'name': 'Get user profile', 'description': 'الحصول على ملف تعريف المستخدم'},
    {'id': 4, 'name': 'Update user profile', 'description': 'تحديث ملف تعريف المستخدم'},

    // Customer Activities (ID Range: 100-199)
    {'id': 100, 'name': 'Get customer details', 'description': 'استرداد معلومات مفصلة عن عميل محدد بما في ذلك التفاصيل الشخصية وأرقام الهواتف والبيانات المرتبطة'},
    {'id': 103, 'name': 'Add customer phone', 'description': 'إضافة رقم هاتف جديد للعميل'},
    {'id': 104, 'name': 'Update customer phone', 'description': 'تحديث رقم هاتف موجود للعميل'},
    {'id': 105, 'name': 'Delete customer phone', 'description': 'حذف رقم هاتف من العميل'},
    {'id': 107, 'name': 'Create customer call', 'description': 'إنشاء سجل مكالمة جديد للعميل'},
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
    {'id': 305, 'name': 'Get ticket items report', 'description': 'استرداد تقرير عناصر التذاكر مع التصفية الديناميكية والتصفح'},
    {'id': 306, 'name': 'print data as pdf', 'description': 'طباعه البيانات بصيغه pdf'},

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
        parameters: [activity['id'], activity['name'], activity['description']],
        userId: 1, // System user for seeding
      );
    } catch (e) {
      // Ignore duplicate key errors
      if (!e.toString().contains('Duplicate entry')) {
        print('⚠ Error inserting activity ${activity['name']}: $e');
      }
    }
  }
}
