-- SQL file to create activities tables and insert activities data
-- This file contains table creation statements and activity data insertion

-- Create entities table
CREATE TABLE IF NOT EXISTS entities (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create activities table
CREATE TABLE IF NOT EXISTS activities (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create activity_logs table
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
);

-- Entities data insertion
-- Entities represent the main business objects that can be tracked in activity logs
INSERT INTO entities (id, name) VALUES
(1, 'users'),
(2, 'customers'),
(3, 'tickets'),
(4, 'ticket_items'),
(5, 'customercall'),
(6, 'ticketcall'),
(7, 'customer_phones'),
(8, 'call_categories'),
(9, 'cities'),
(10, 'governorates'),
(11, 'product_info'),
(12, 'request_reasons'),
(13, 'ticket_categories'),
(14, 'companies'),
(15, 'roles'),
(16, 'permissions'),
(17, 'ticket_item_change_same'),
(18, 'ticket_item_change_another'),
(19, 'ticket_item_maintenance');

-- Activities data insertion
-- Activities table structure: id, name, description, created_at

-- Auth Activities (ID Range: 1-99)
INSERT INTO activities (id, name, description) VALUES
(1, 'User login', 'تسجيل دخول المستخدم إلى النظام'),
(2, 'User logout', 'تسجيل خروج المستخدم من النظام'),
(3, 'Get user profile', 'الحصول على ملف تعريف المستخدم'),
(4, 'Update user profile', 'تحديث ملف تعريف المستخدم');

-- Customer Activities (ID Range: 100-199)
INSERT INTO activities (id, name, description) VALUES
(100, 'Get customer details', 'استرداد معلومات مفصلة عن عميل محدد بما في ذلك التفاصيل الشخصية وأرقام الهواتف والبيانات المرتبطة'),
(101, 'Update customer details', 'تحديث معلومات العميل بما في ذلك الاسم والعنوان والملاحظات والمحافظة والمدينة'),
(102, 'Get customer phones', 'استرداد جميع أرقام الهواتف المرتبطة بعميل محدد'),
(103, 'Add customer phone', 'إضافة رقم هاتف جديد للعميل'),
(104, 'Update customer phone', 'تحديث رقم هاتف موجود للعميل'),
(105, 'Delete customer phone', 'حذف رقم هاتف من العميل'),
(106, 'Get customer calls', 'استرداد جميع المكالمات المرتبطة بعميل محدد'),
(107, 'Create customer call', 'إنشاء سجل مكالمة جديد للعميل'),
(108, 'Get customer tickets', 'استرداد جميع التذاكر المرتبطة بعميل محدد'),
(109, 'Create customer ticket', 'إنشاء تذكرة جديدة للعميل'),
(110, 'Create customer with call', 'إنشاء عميل جديد مع سجل مكالمة أولي في معاملة واحدة'),
(111, 'Create customer with ticket', 'إنشاء عميل جديد مع تذكرة أولية في معاملة واحدة'),
(112, 'Update customer name', 'تحديث اسم العميل'),
(113, 'Update customer address', 'تحديث عنوان العميل'),
(114, 'Update customer notes', 'تحديث ملاحظات العميل'),
(115, 'Update customer governorate', 'تحديث محافظة العميل'),
(116, 'Update customer city', 'تحديث مدينة العميل');

-- Masterdata Activities (ID Range: 200-299)
INSERT INTO activities (id, name, description) VALUES
(200, 'Get all call categories', 'استرداد جميع فئات المكالمات من النظام'),
(201, 'Create call category', 'إنشاء فئة مكالمة جديدة'),
(202, 'Get call category by ID', 'استرداد فئة مكالمة محددة بواسطة المعرف'),
(203, 'Update call category', 'تحديث فئة مكالمة موجودة'),
(204, 'Delete call category', 'حذف فئة مكالمة من النظام'),
(205, 'Get all cities', 'استرداد جميع المدن من النظام'),
(206, 'Create city', 'إنشاء مدينة جديدة'),
(207, 'Get city by ID', 'استرداد مدينة محددة بواسطة المعرف'),
(208, 'Update city', 'تحديث مدينة موجودة'),
(209, 'Delete city', 'حذف مدينة من النظام'),
(210, 'Get all companies', 'استرداد جميع الشركات من النظام'),
(211, 'Get all governorates', 'استرداد جميع المحافظات من النظام'),
(212, 'Create governorate', 'إنشاء محافظة جديدة'),
(213, 'Get governorate by ID', 'استرداد محافظة محددة بواسطة المعرف'),
(214, 'Update governorate', 'تحديث محافظة موجودة'),
(215, 'Delete governorate', 'حذف محافظة من النظام'),
(216, 'Get all governorates with cities', 'استرداد جميع المحافظات مع المدن المرتبطة بها'),
(217, 'Get all products', 'استرداد جميع المنتجات من النظام'),
(218, 'Create product', 'إنشاء منتج جديد'),
(219, 'Get product by ID', 'استرداد منتج محدد بواسطة المعرف'),
(220, 'Update product', 'تحديث منتج موجود'),
(221, 'Delete product', 'حذف منتج من النظام'),
(222, 'Get all request reasons', 'استرداد جميع أسباب الطلبات من النظام'),
(223, 'Create request reason', 'إنشاء سبب طلب جديد'),
(224, 'Get request reason by ID', 'استرداد سبب طلب محدد بواسطة المعرف'),
(225, 'Update request reason', 'تحديث سبب طلب موجود'),
(226, 'Delete request reason', 'حذف سبب طلب من النظام'),
(227, 'Get all ticket categories', 'استرداد جميع فئات التذاكر من النظام'),
(228, 'Create ticket category', 'إنشاء فئة تذكرة جديدة'),
(229, 'Get ticket category by ID', 'استرداد فئة تذكرة محددة بواسطة المعرف'),
(230, 'Update ticket category', 'تحديث فئة تذكرة موجودة'),
(231, 'Delete ticket category', 'حذف فئة تذكرة من النظام');

-- Reports Activities (ID Range: 300-399)
INSERT INTO activities (id, name, description) VALUES
(300, 'Get agent calls report', 'استرداد جميع المكالمات (مكالمات العملاء ومكالمات التذاكر) التي أنشأها مستخدم محدد خلال نطاق زمني'),
(301, 'Get tickets report', 'استرداد تقرير التذاكر المقسم إلى صفحات للشركة مع خيارات التصفية الاختيارية'),
(302, 'Export tickets report as CSV', 'تصدير تقرير التذاكر بتنسيق CSV مع جميع خيارات التصفية'),
(303, 'Export tickets report as Excel', 'تصدير تقرير التذاكر بتنسيق Excel مع جميع خيارات التصفية'),
(304, 'Export tickets report as PDF', 'تصدير تقرير التذاكر بتنسيق PDF مع جميع خيارات التصفية');

-- Search Activities (ID Range: 400-499)
INSERT INTO activities (id, name, description) VALUES
(400, 'Search customers by name', 'البحث عن العملاء بالاسم باستخدام المطابقة الجزئية'),
(401, 'Search customers by phone', 'البحث عن العملاء برقم الهاتف باستخدام المطابقة الجزئية'),
(402, 'Auto-detect customer search', 'الكشف التلقائي عما إذا كان الاستعلام رقم هاتف أم اسم وتنفيذ البحث المناسب');

-- Tickets Activities (ID Range: 500-599)
INSERT INTO activities (id, name, description) VALUES
(500, 'Create ticket with call and item', 'إنشاء تذكرة جديدة مع سجل مكالمة وعنصر مرتبط في معاملة واحدة'),
(501, 'Close ticket', 'إغلاق تذكرة موجودة مع ملاحظات الإغلاق'),
(502, 'Update ticket category', 'تحديث فئة التذكرة الموجودة'),
(503, 'Add call log to ticket', 'إضافة إدخال سجل مكالمة جديد إلى تذكرة موجودة'),
(504, 'Get ticket items', 'استرداد جميع العناصر المرتبطة بتذكرة محددة'),
(505, 'Add item to ticket', 'إضافة عنصر جديد إلى تذكرة موجودة'),
(506, 'Update item company ID', 'تحديث معرف الشركة لعنصر التذكرة'),
(507, 'Update item product ID', 'تحديث معرف المنتج لعنصر التذكرة'),
(508, 'Update item quantity', 'تحديث كمية عنصر التذكرة'),
(509, 'Update item product size', 'تحديث حجم منتج عنصر التذكرة'),
(510, 'Update item purchase date', 'تحديث تاريخ شراء عنصر التذكرة'),
(511, 'Update item purchase location', 'تحديث موقع شراء عنصر التذكرة'),
(512, 'Update item request reason ID', 'تحديث معرف سبب طلب عنصر التذكرة'),
(513, 'Update item request reason detail', 'تحديث تفاصيل سبب طلب عنصر التذكرة'),
(514, 'Delete ticket item', 'حذف عنصر من التذكرة');

-- Ticket Items Activities (ID Range: 600-699)
-- Different Product Replacement Activities (600-610)
INSERT INTO activities (id, name, description) VALUES
(600, 'Create different product replacement', 'إنشاء سجل استبدال منتج مختلف جديد لعنصر التذكرة'),
(601, 'Update different product replacement product ID', 'تحديث معرف المنتج لاستبدال المنتج المختلف'),
(602, 'Update different product replacement product size', 'تحديث حجم المنتج لاستبدال المنتج المختلف'),
(603, 'Update different product replacement cost', 'تحديث تكلفة استبدال المنتج المختلف'),
(604, 'Update different product replacement client approval', 'تحديث حالة موافقة العميل لاستبدال المنتج المختلف'),
(605, 'Update different product replacement refusal reason', 'تحديث سبب رفض استبدال المنتج المختلف'),
(606, 'Mark different product replacement as pulled', 'تحديد استبدال المنتج المختلف كمسحوب'),
(607, 'Update different product replacement pull date', 'تحديث تاريخ السحب لاستبدال المنتج المختلف'),
(608, 'Mark different product replacement as delivered', 'تحديد استبدال المنتج المختلف كمسلم'),
(609, 'Update different product replacement delivery date', 'تحديث تاريخ التسليم لاستبدال المنتج المختلف'),
(610, 'Delete different product replacement', 'حذف سجل استبدال المنتج المختلف من النظام');
INSERT INTO activities (id, name, description) VALUES
(638, 'Mark different product replacement as unpulled', 'تحديد استبدال المنتج المختلف كغير مسحوب'),
(639, 'Mark different product replacement as undelivered', 'تحديد استبدال المنتج المختلف كغير مسلم');
-- Same Product Replacement Activities (611-621)
INSERT INTO activities (id, name, description) VALUES
(611, 'Create same product replacement', 'إنشاء سجل استبدال منتج مماثل جديد لعنصر التذكرة'),
(612, 'Update same product replacement product ID', 'تحديث معرف المنتج لاستبدال المنتج المماثل'),
(613, 'Update same product replacement product size', 'تحديث حجم المنتج لاستبدال المنتج المماثل'),
(614, 'Update same product replacement cost', 'تحديث تكلفة استبدال المنتج المماثل'),
(615, 'Update same product replacement client approval', 'تحديث حالة موافقة العميل لاستبدال المنتج المماثل'),
(616, 'Update same product replacement refusal reason', 'تحديث سبب رفض استبدال المنتج المماثل'),
(617, 'Mark same product replacement as pulled', 'تحديد استبدال المنتج المماثل كمسحوب'),
(618, 'Update same product replacement pull date', 'تحديث تاريخ السحب لاستبدال المنتج المماثل'),
(619, 'Mark same product replacement as delivered', 'تحديد استبدال المنتج المماثل كمسلم'),
(620, 'Update same product replacement delivery date', 'تحديث تاريخ التسليم لاستبدال المنتج المماثل'),
(621, 'Delete same product replacement', 'حذف سجل استبدال المنتج المماثل من النظام');
INSERT INTO activities (id, name, description) VALUES

(640, 'Mark same product replacement as unpulled', 'تحديد استبدال المنتج المماثل كغير مسحوب'),
(641, 'Mark same product replacement as undelivered', 'تحديد استبدال المنتج المماثل كغير مسلم');
-- Item Inspection Activities (622-625)
INSERT INTO activities (id, name, description) VALUES
(622, 'Mark item as inspected', 'تعيين العنصر كمفحوص'),
(623, 'Mark item as uninspected', 'تعيين العنصر كغير مفحوص'),
(624, 'Update item inspection date', 'تحديث تاريخ فحص العنصر'),
(625, 'Update item inspection result', 'تحديث نتيجة فحص العنصر');

-- Maintenance Activities (626-635)
INSERT INTO activities (id, name, description) VALUES
(626, 'Create maintenance option', 'إنشاء سجل خيار صيانة جديد لعنصر التذكرة'),
(627, 'Update maintenance steps', 'تحديث خطوات الصيانة لخيار الصيانة'),
(628, 'Update maintenance cost', 'تحديث تكلفة الصيانة لخيار الصيانة'),
(629, 'Update maintenance client approval', 'تحديث حالة موافقة العميل لخيار الصيانة'),
(630, 'Update maintenance refusal reason', 'تحديث سبب رفض خيار الصيانة'),
(631, 'Mark maintenance as pulled', 'تحديد خيار الصيانة كمسحوب'),
(632, 'Update maintenance pull date', 'تحديث تاريخ السحب لخيار الصيانة'),
(633, 'Mark maintenance as delivered', 'تحديد خيار الصيانة كمسلم'),
(634, 'Update maintenance delivery date', 'تحديث تاريخ التسليم لخيار الصيانة'),
(635, 'Delete maintenance option', 'حذف سجل خيار الصيانة من النظام'),
(636, 'Mark maintenance as unpulled', 'تحديد خيار الصيانة كغير مسحوب'),
(637, 'Mark maintenance as undelivered', 'تحديد خيار الصيانة كغير مسلم');


-- Note: This SQL file contains all activities extracted from the API documentation files
-- Total activities: 114 activities across all modules organized in ID ranges for future expansion:
-- Auth Activities: 1-99 (Currently using: 1-4, Available: 5-99)
-- Customer Activities: 100-199 (Currently using: 100-111, Available: 112-199)
-- Masterdata Activities: 200-299 (Currently using: 200-231, Available: 232-299)
-- Reports Activities: 300-399 (Currently using: 300-304, Available: 305-399)
-- Search Activities: 400-499 (Currently using: 400-402, Available: 403-499)
-- Tickets Activities: 500-599 (Currently using: 500-513, Available: 514-599)
-- Ticket Items Activities: 600-699 (Currently using: 600-641, Available: 642-699)
-- Execute this file against your MySQL database to populate the activities table