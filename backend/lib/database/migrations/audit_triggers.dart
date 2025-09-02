import 'package:mysql1/mysql1.dart';
import '../database_service.dart';

/// Create audit triggers for all tables
Future<void> createAuditTriggers(MySqlConnection conn) async {
  print('Creating audit triggers...');

  try {
    await _dropExistingTriggers(conn);
    await _createBasicTriggers(conn);
    print('✓ All audit triggers created successfully');
  } catch (e) {
    print('✗ Error creating audit triggers: $e');
    rethrow;
  }
}

/// Drop existing triggers if they exist
Future<void> _dropExistingTriggers(MySqlConnection conn) async {
  final triggers = [
    'users_insert_audit', 'users_update_audit', 'users_delete_audit',
    'customers_insert_audit', 'customers_update_audit', 'customers_delete_audit',
    'tickets_insert_audit', 'tickets_update_audit', 'tickets_delete_audit',
    'companies_insert_audit', 'companies_update_audit', 'companies_delete_audit',
    'ticket_items_insert_audit', 'ticket_items_update_audit', 'ticket_items_delete_audit',
    'customer_phones_insert_audit', 'customer_phones_update_audit', 'customer_phones_delete_audit',
    'call_categories_insert_audit', 'call_categories_update_audit', 'call_categories_delete_audit',
    'call_types_insert_audit', 'call_types_update_audit', 'call_types_delete_audit',
    'cities_insert_audit', 'cities_update_audit', 'cities_delete_audit',
    'governorates_insert_audit', 'governorates_update_audit', 'governorates_delete_audit',
    'customercall_insert_audit', 'customercall_update_audit', 'customercall_delete_audit',
    'product_info_insert_audit', 'product_info_update_audit', 'product_info_delete_audit',
    'request_reasons_insert_audit', 'request_reasons_update_audit', 'request_reasons_delete_audit',
    'ticket_categories_insert_audit', 'ticket_categories_update_audit', 'ticket_categories_delete_audit',
    'ticket_item_maintenance_insert_audit', 'ticket_item_maintenance_update_audit', 'ticket_item_maintenance_delete_audit',
    'ticketcall_insert_audit', 'ticketcall_update_audit', 'ticketcall_delete_audit',
    'ticket_item_change_same_insert_audit', 'ticket_item_change_same_update_audit', 'ticket_item_change_same_delete_audit',
    'ticket_item_change_another_insert_audit', 'ticket_item_change_another_update_audit', 'ticket_item_change_another_delete_audit'
  ];

  for (final trigger in triggers) {
    try {
      await DatabaseService.query(
        'DROP TRIGGER IF EXISTS $trigger',
        userId: 1,
      );
    } catch (e) {
      print('⚠ Could not drop trigger $trigger: $e');
    }
  }
}

/// Create basic audit triggers for key tables
Future<void> _createBasicTriggers(MySqlConnection conn) async {
  await _createUsersTriggers(conn);
  await _createCustomersTriggers(conn);
  await _createTicketsTriggers(conn);
  await _createCompaniesTriggers(conn);
  await _createCallCategoriesTriggers(conn);
  await _createCallTypesTriggers(conn);
  await _createCitiesTriggers(conn);
  await _createGovernoratesTriggers(conn);
  await _createCustomerPhonesTriggers(conn);
  await _createTicketItemsTriggers(conn);
  await _createCustomercallTriggers(conn);
  await _createProductInfoTriggers(conn);
  await _createRequestReasonsTriggers(conn);
  await _createTicketCategoriesTriggers(conn);
  await _createTicketItemMaintenanceTriggers(conn);
  await _createTicketcallTriggers(conn);
  await _createTicketItemChangeSameTriggers(conn);
  await _createTicketItemChangeAnotherTriggers(conn);
}

/// Create users table audit triggers
Future<void> _createUsersTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER users_insert_audit
    AFTER INSERT ON users
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'users',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'name', NEW.name,
                'username', NEW.username,
                'password', NEW.password,
                'is_active', NEW.is_active,
                'permissions', NEW.permissions,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER users_update_audit
    AFTER UPDATE ON users
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'users',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'name', OLD.name,
                'username', OLD.username,
                'password', OLD.password,
                'is_active', OLD.is_active,
                'permissions', OLD.permissions,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'name', NEW.name,
                'username', NEW.username,
                'password', NEW.password,
                'is_active', NEW.is_active,
                'permissions', NEW.permissions,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER users_delete_audit
    AFTER DELETE ON users
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'users',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'name', OLD.name,
                'username', OLD.username,
                'password', OLD.password,
                'is_active', OLD.is_active,
                'permissions', OLD.permissions,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Users audit triggers created');
}

/// Create customers table audit triggers
Future<void> _createCustomersTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER customers_insert_audit
    AFTER INSERT ON customers
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'customers',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'name', NEW.name,
                'governomate_id', NEW.governomate_id,
                'city_id', NEW.city_id,
                'address', NEW.address,
                'notes', NEW.notes,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER customers_update_audit
    AFTER UPDATE ON customers
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'customers',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'name', OLD.name,
                'governomate_id', OLD.governomate_id,
                'city_id', OLD.city_id,
                'address', OLD.address,
                'notes', OLD.notes,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'name', NEW.name,
                'governomate_id', NEW.governomate_id,
                'city_id', NEW.city_id,
                'address', NEW.address,
                'notes', NEW.notes,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER customers_delete_audit
    AFTER DELETE ON customers
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'customers',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'name', OLD.name,
                'governomate_id', OLD.governomate_id,
                'city_id', OLD.city_id,
                'address', OLD.address,
                'notes', OLD.notes,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Customers audit triggers created');
}

/// Create tickets table audit triggers
Future<void> _createTicketsTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER tickets_insert_audit
    AFTER INSERT ON tickets
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'tickets',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'customer_id', NEW.customer_id,
                'ticket_cat_id', NEW.ticket_cat_id,
                'description', NEW.description,
                'status', NEW.status,
                'priority', NEW.priority,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'closed_at', NEW.closed_at,
                'updated_at', NEW.updated_at,
                'closing_notes', NEW.closing_notes,
                'closed_by', NEW.closed_by
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER tickets_update_audit
    AFTER UPDATE ON tickets
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'tickets',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'customer_id', OLD.customer_id,
                'ticket_cat_id', OLD.ticket_cat_id,
                'description', OLD.description,
                'status', OLD.status,
                'priority', OLD.priority,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'closed_at', OLD.closed_at,
                'updated_at', OLD.updated_at,
                'closing_notes', OLD.closing_notes,
                'closed_by', OLD.closed_by
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'customer_id', NEW.customer_id,
                'ticket_cat_id', NEW.ticket_cat_id,
                'description', NEW.description,
                'status', NEW.status,
                'priority', NEW.priority,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'closed_at', NEW.closed_at,
                'updated_at', NEW.updated_at,
                'closing_notes', NEW.closing_notes,
                'closed_by', NEW.closed_by
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER tickets_delete_audit
    AFTER DELETE ON tickets
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'tickets',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'customer_id', OLD.customer_id,
                'ticket_cat_id', OLD.ticket_cat_id,
                'description', OLD.description,
                'status', OLD.status,
                'priority', OLD.priority,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'closed_at', OLD.closed_at,
                'updated_at', OLD.updated_at,
                'closing_notes', OLD.closing_notes,
                'closed_by', OLD.closed_by
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Tickets audit triggers created');
}

/// Create companies table audit triggers
Future<void> _createCompaniesTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER companies_insert_audit
    AFTER INSERT ON companies
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            'SYSTEM',
            'INSERT',
            'companies',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'created_at', NEW.created_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER companies_update_audit
    AFTER UPDATE ON companies
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            'SYSTEM',
            'UPDATE',
            'companies',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'created_at', OLD.created_at
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'created_at', NEW.created_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER companies_delete_audit
    AFTER DELETE ON companies
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            'SYSTEM',
            'DELETE',
            'companies',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'created_at', OLD.created_at
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Companies audit triggers created');
}
/// Create call_categories table audit triggers
Future<void> _createCallCategoriesTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER call_categories_insert_audit
    AFTER INSERT ON call_categories
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'call_categories',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at,
                'company_id', NEW.company_id
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER call_categories_update_audit
    AFTER UPDATE ON call_categories
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'call_categories',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at,
                'company_id', OLD.company_id
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at,
                'company_id', NEW.company_id
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER call_categories_delete_audit
    AFTER DELETE ON call_categories
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'call_categories',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at,
                'company_id', OLD.company_id
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Call categories audit triggers created');
}

/// Create call_types table audit triggers
Future<void> _createCallTypesTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER call_types_insert_audit
    AFTER INSERT ON call_types
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'call_types',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER call_types_update_audit
    AFTER UPDATE ON call_types
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'call_types',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER call_types_delete_audit
    AFTER DELETE ON call_types
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'call_types',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Call types audit triggers created');
}

/// Create cities table audit triggers
Future<void> _createCitiesTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER cities_insert_audit
    AFTER INSERT ON cities
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'cities',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'governorate_id', NEW.governorate_id
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER cities_update_audit
    AFTER UPDATE ON cities
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'cities',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'governorate_id', OLD.governorate_id
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'governorate_id', NEW.governorate_id
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER cities_delete_audit
    AFTER DELETE ON cities
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'cities',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'governorate_id', OLD.governorate_id
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Cities audit triggers created');
}

/// Create governorates table audit triggers
Future<void> _createGovernoratesTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER governorates_insert_audit
    AFTER INSERT ON governorates
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'governorates',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER governorates_update_audit
    AFTER UPDATE ON governorates
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'governorates',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER governorates_delete_audit
    AFTER DELETE ON governorates
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'governorates',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Governorates audit triggers created');
}

/// Create customer_phones table audit triggers
Future<void> _createCustomerPhonesTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER customer_phones_insert_audit
    AFTER INSERT ON customer_phones
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'customer_phones',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'customer_id', NEW.customer_id,
                'phone', NEW.phone,
                'phone_type', NEW.phone_type,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER customer_phones_update_audit
    AFTER UPDATE ON customer_phones
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'customer_phones',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'customer_id', OLD.customer_id,
                'phone', OLD.phone,
                'phone_type', OLD.phone_type,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'customer_id', NEW.customer_id,
                'phone', NEW.phone,
                'phone_type', NEW.phone_type,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER customer_phones_delete_audit
    AFTER DELETE ON customer_phones
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'customer_phones',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'customer_id', OLD.customer_id,
                'phone', OLD.phone,
                'phone_type', OLD.phone_type,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Customer phones audit triggers created');
}

/// Create ticket_items table audit triggers
Future<void> _createTicketItemsTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER ticket_items_insert_audit
    AFTER INSERT ON ticket_items
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'ticket_items',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'ticket_id', NEW.ticket_id,
                'product_id', NEW.product_id,
                'product_size', NEW.product_size,
                'quantity', NEW.quantity,
                'purchase_date', NEW.purchase_date,
                'purchase_location', NEW.purchase_location,
                'request_reason_id', NEW.request_reason_id,
                'request_reason_detail', NEW.request_reason_detail,
                'inspected', NEW.inspected,
                'inspection_date', NEW.inspection_date,
                'inspection_result', NEW.inspection_result,
                'client_approval', NEW.client_approval,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticket_items_update_audit
    AFTER UPDATE ON ticket_items
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'ticket_items',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'ticket_id', OLD.ticket_id,
                'product_id', OLD.product_id,
                'product_size', OLD.product_size,
                'quantity', OLD.quantity,
                'purchase_date', OLD.purchase_date,
                'purchase_location', OLD.purchase_location,
                'request_reason_id', OLD.request_reason_id,
                'request_reason_detail', OLD.request_reason_detail,
                'inspected', OLD.inspected,
                'inspection_date', OLD.inspection_date,
                'inspection_result', OLD.inspection_result,
                'client_approval', OLD.client_approval,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'ticket_id', NEW.ticket_id,
                'product_id', NEW.product_id,
                'product_size', NEW.product_size,
                'quantity', NEW.quantity,
                'purchase_date', NEW.purchase_date,
                'purchase_location', NEW.purchase_location,
                'request_reason_id', NEW.request_reason_id,
                'request_reason_detail', NEW.request_reason_detail,
                'inspected', NEW.inspected,
                'inspection_date', NEW.inspection_date,
                'inspection_result', NEW.inspection_result,
                'client_approval', NEW.client_approval,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticket_items_delete_audit
    AFTER DELETE ON ticket_items
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'ticket_items',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'ticket_id', OLD.ticket_id,
                'product_id', OLD.product_id,
                'product_size', OLD.product_size,
                'quantity', OLD.quantity,
                'purchase_date', OLD.purchase_date,
                'purchase_location', OLD.purchase_location,
                'request_reason_id', OLD.request_reason_id,
                'request_reason_detail', OLD.request_reason_detail,
                'inspected', OLD.inspected,
                'inspection_date', OLD.inspection_date,
                'inspection_result', OLD.inspection_result,
                'client_approval', OLD.client_approval,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Ticket items audit triggers created');
}

/// Create customercall table audit triggers
Future<void> _createCustomercallTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER customercall_insert_audit
    AFTER INSERT ON customercall
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'customercall',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'customer_id', NEW.customer_id,
                'call_type', NEW.call_type,
                'category_id', NEW.category_id,
                'description', NEW.description,
                'call_notes', NEW.call_notes,
                'call_duration', NEW.call_duration,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER customercall_update_audit
    AFTER UPDATE ON customercall
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'customercall',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'customer_id', OLD.customer_id,
                'call_type', OLD.call_type,
                'category_id', OLD.category_id,
                'description', OLD.description,
                'call_notes', OLD.call_notes,
                'call_duration', OLD.call_duration,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'customer_id', NEW.customer_id,
                'call_type', NEW.call_type,
                'category_id', NEW.category_id,
                'description', NEW.description,
                'call_notes', NEW.call_notes,
                'call_duration', NEW.call_duration,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER customercall_delete_audit
    AFTER DELETE ON customercall
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'customercall',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'customer_id', OLD.customer_id,
                'call_type', OLD.call_type,
                'category_id', OLD.category_id,
                'description', OLD.description,
                'call_notes', OLD.call_notes,
                'call_duration', OLD.call_duration,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Customercall audit triggers created');
}

/// Create product_info table audit triggers
Future<void> _createProductInfoTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER product_info_insert_audit
    AFTER INSERT ON product_info
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'product_info',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'product_name', NEW.product_name,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER product_info_update_audit
    AFTER UPDATE ON product_info
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'product_info',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'product_name', OLD.product_name,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'product_name', NEW.product_name,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER product_info_delete_audit
    AFTER DELETE ON product_info
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'product_info',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'product_name', OLD.product_name,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Product info audit triggers created');
}

/// Create request_reasons table audit triggers
Future<void> _createRequestReasonsTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER request_reasons_insert_audit
    AFTER INSERT ON request_reasons
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'request_reasons',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at,
                'company_id', NEW.company_id
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER request_reasons_update_audit
    AFTER UPDATE ON request_reasons
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'request_reasons',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at,
                'company_id', OLD.company_id
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at,
                'company_id', NEW.company_id
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER request_reasons_delete_audit
    AFTER DELETE ON request_reasons
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'request_reasons',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at,
                'company_id', OLD.company_id
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Request reasons audit triggers created');
}

/// Create ticket_categories table audit triggers
Future<void> _createTicketCategoriesTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER ticket_categories_insert_audit
    AFTER INSERT ON ticket_categories
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'ticket_categories',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at,
                'company_id', NEW.company_id
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticket_categories_update_audit
    AFTER UPDATE ON ticket_categories
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'ticket_categories',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at,
                'company_id', OLD.company_id
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'name', NEW.name,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at,
                'company_id', NEW.company_id
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticket_categories_delete_audit
    AFTER DELETE ON ticket_categories
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'ticket_categories',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'name', OLD.name,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at,
                'company_id', OLD.company_id
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Ticket categories audit triggers created');
}

/// Create ticket_item_maintenance table audit triggers
Future<void> _createTicketItemMaintenanceTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER ticket_item_maintenance_insert_audit
    AFTER INSERT ON ticket_item_maintenance
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'ticket_item_maintenance',
            CAST(NEW.ticket_item_id AS CHAR),
            NULL,
            JSON_OBJECT(
                'ticket_item_id', NEW.ticket_item_id,
                'maintenance_steps', NEW.maintenance_steps,
                'maintenance_cost', NEW.maintenance_cost,
                'client_approval', NEW.client_approval,
                'refusal_reason', NEW.refusal_reason,
                'pulled', NEW.pulled,
                'pull_date', NEW.pull_date,
                'delivered', NEW.delivered,
                'delivery_date', NEW.delivery_date,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at,
                'company_id', NEW.company_id
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticket_item_maintenance_update_audit
    AFTER UPDATE ON ticket_item_maintenance
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'ticket_item_maintenance',
            CAST(NEW.ticket_item_id AS CHAR),
            JSON_OBJECT(
                'ticket_item_id', OLD.ticket_item_id,
                'maintenance_steps', OLD.maintenance_steps,
                'maintenance_cost', OLD.maintenance_cost,
                'client_approval', OLD.client_approval,
                'refusal_reason', OLD.refusal_reason,
                'pulled', OLD.pulled,
                'pull_date', OLD.pull_date,
                'delivered', OLD.delivered,
                'delivery_date', OLD.delivery_date,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at,
                'company_id', OLD.company_id
            ),
            JSON_OBJECT(
                'ticket_item_id', NEW.ticket_item_id,
                'maintenance_steps', NEW.maintenance_steps,
                'maintenance_cost', NEW.maintenance_cost,
                'client_approval', NEW.client_approval,
                'refusal_reason', NEW.refusal_reason,
                'pulled', NEW.pulled,
                'pull_date', NEW.pull_date,
                'delivered', NEW.delivered,
                'delivery_date', NEW.delivery_date,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at,
                'company_id', NEW.company_id
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticket_item_maintenance_delete_audit
    AFTER DELETE ON ticket_item_maintenance
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'ticket_item_maintenance',
            CAST(OLD.ticket_item_id AS CHAR),
            JSON_OBJECT(
                'ticket_item_id', OLD.ticket_item_id,
                'maintenance_steps', OLD.maintenance_steps,
                'maintenance_cost', OLD.maintenance_cost,
                'client_approval', OLD.client_approval,
                'refusal_reason', OLD.refusal_reason,
                'pulled', OLD.pulled,
                'pull_date', OLD.pull_date,
                'delivered', OLD.delivered,
                'delivery_date', OLD.delivery_date,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at,
                'company_id', OLD.company_id
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Ticket item maintenance audit triggers created');
}

/// Create ticketcall table audit triggers
Future<void> _createTicketcallTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER ticketcall_insert_audit
    AFTER INSERT ON ticketcall
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'ticketcall',
            CAST(NEW.id AS CHAR),
            NULL,
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'ticket_id', NEW.ticket_id,
                'call_type', NEW.call_type,
                'call_cat_id', NEW.call_cat_id,
                'description', NEW.description,
                'call_notes', NEW.call_notes,
                'call_duration', NEW.call_duration,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticketcall_update_audit
    AFTER UPDATE ON ticketcall
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'ticketcall',
            CAST(NEW.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'ticket_id', OLD.ticket_id,
                'call_type', OLD.call_type,
                'call_cat_id', OLD.call_cat_id,
                'description', OLD.description,
                'call_notes', OLD.call_notes,
                'call_duration', OLD.call_duration,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            JSON_OBJECT(
                'id', NEW.id,
                'company_id', NEW.company_id,
                'ticket_id', NEW.ticket_id,
                'call_type', NEW.call_type,
                'call_cat_id', NEW.call_cat_id,
                'description', NEW.description,
                'call_notes', NEW.call_notes,
                'call_duration', NEW.call_duration,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticketcall_delete_audit
    AFTER DELETE ON ticketcall
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'ticketcall',
            CAST(OLD.id AS CHAR),
            JSON_OBJECT(
                'id', OLD.id,
                'company_id', OLD.company_id,
                'ticket_id', OLD.ticket_id,
                'call_type', OLD.call_type,
                'call_cat_id', OLD.call_cat_id,
                'description', OLD.description,
                'call_notes', OLD.call_notes,
                'call_duration', OLD.call_duration,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Ticketcall audit triggers created');
}

/// Create ticket_item_change_same table audit triggers
Future<void> _createTicketItemChangeSameTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER ticket_item_change_same_insert_audit
    AFTER INSERT ON ticket_item_change_same
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'ticket_item_change_same',
            CAST(NEW.ticket_item_id AS CHAR),
            NULL,
            JSON_OBJECT(
                'company_id', NEW.company_id,
                'ticket_item_id', NEW.ticket_item_id,
                'product_id', NEW.product_id,
                'product_size', NEW.product_size,
                'cost', NEW.cost,
                'client_approval', NEW.client_approval,
                'refusal_reason', NEW.refusal_reason,
                'pulled', NEW.pulled,
                'pull_date', NEW.pull_date,
                'delivered', NEW.delivered,
                'delivery_date', NEW.delivery_date,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticket_item_change_same_update_audit
    AFTER UPDATE ON ticket_item_change_same
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'ticket_item_change_same',
            CAST(NEW.ticket_item_id AS CHAR),
            JSON_OBJECT(
                'company_id', OLD.company_id,
                'ticket_item_id', OLD.ticket_item_id,
                'product_id', OLD.product_id,
                'product_size', OLD.product_size,
                'cost', OLD.cost,
                'client_approval', OLD.client_approval,
                'refusal_reason', OLD.refusal_reason,
                'pulled', OLD.pulled,
                'pull_date', OLD.pull_date,
                'delivered', OLD.delivered,
                'delivery_date', OLD.delivery_date,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            JSON_OBJECT(
                'company_id', NEW.company_id,
                'ticket_item_id', NEW.ticket_item_id,
                'product_id', NEW.product_id,
                'product_size', NEW.product_size,
                'cost', NEW.cost,
                'client_approval', NEW.client_approval,
                'refusal_reason', NEW.refusal_reason,
                'pulled', NEW.pulled,
                'pull_date', NEW.pull_date,
                'delivered', NEW.delivered,
                'delivery_date', NEW.delivery_date,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticket_item_change_same_delete_audit
    AFTER DELETE ON ticket_item_change_same
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'ticket_item_change_same',
            CAST(OLD.ticket_item_id AS CHAR),
            JSON_OBJECT(
                'company_id', OLD.company_id,
                'ticket_item_id', OLD.ticket_item_id,
                'product_id', OLD.product_id,
                'product_size', OLD.product_size,
                'cost', OLD.cost,
                'client_approval', OLD.client_approval,
                'refusal_reason', OLD.refusal_reason,
                'pulled', OLD.pulled,
                'pull_date', OLD.pull_date,
                'delivered', OLD.delivered,
                'delivery_date', OLD.delivery_date,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Ticket item change same audit triggers created');
}

/// Create ticket_item_change_another table audit triggers
Future<void> _createTicketItemChangeAnotherTriggers(MySqlConnection conn) async {
  await DatabaseService.query('''
    CREATE TRIGGER ticket_item_change_another_insert_audit
    AFTER INSERT ON ticket_item_change_another
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'INSERT',
            'ticket_item_change_another',
            CAST(NEW.ticket_item_id AS CHAR),
            NULL,
            JSON_OBJECT(
                'company_id', NEW.company_id,
                'ticket_item_id', NEW.ticket_item_id,
                'product_id', NEW.product_id,
                'product_size', NEW.product_size,
                'cost', NEW.cost,
                'client_approval', NEW.client_approval,
                'refusal_reason', NEW.refusal_reason,
                'pulled', NEW.pulled,
                'pull_date', NEW.pull_date,
                'delivered', NEW.delivered,
                'delivery_date', NEW.delivery_date,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticket_item_change_another_update_audit
    AFTER UPDATE ON ticket_item_change_another
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'UPDATE',
            'ticket_item_change_another',
            CAST(NEW.ticket_item_id AS CHAR),
            JSON_OBJECT(
                'company_id', OLD.company_id,
                'ticket_item_id', OLD.ticket_item_id,
                'product_id', OLD.product_id,
                'product_size', OLD.product_size,
                'cost', OLD.cost,
                'client_approval', OLD.client_approval,
                'refusal_reason', OLD.refusal_reason,
                'pulled', OLD.pulled,
                'pull_date', OLD.pull_date,
                'delivered', OLD.delivered,
                'delivery_date', OLD.delivery_date,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            JSON_OBJECT(
                'company_id', NEW.company_id,
                'ticket_item_id', NEW.ticket_item_id,
                'product_id', NEW.product_id,
                'product_size', NEW.product_size,
                'cost', NEW.cost,
                'client_approval', NEW.client_approval,
                'refusal_reason', NEW.refusal_reason,
                'pulled', NEW.pulled,
                'pull_date', NEW.pull_date,
                'delivered', NEW.delivered,
                'delivery_date', NEW.delivery_date,
                'created_by', NEW.created_by,
                'created_at', NEW.created_at,
                'updated_at', NEW.updated_at
            ),
            NOW()
        );
    END
  ''', userId: 1);

  await DatabaseService.query('''
    CREATE TRIGGER ticket_item_change_another_delete_audit
    AFTER DELETE ON ticket_item_change_another
    FOR EACH ROW
    BEGIN
        INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
        VALUES (
            COALESCE(@current_user_id, 'SYSTEM'),
            'DELETE',
            'ticket_item_change_another',
            CAST(OLD.ticket_item_id AS CHAR),
            JSON_OBJECT(
                'company_id', OLD.company_id,
                'ticket_item_id', OLD.ticket_item_id,
                'product_id', OLD.product_id,
                'product_size', OLD.product_size,
                'cost', OLD.cost,
                'client_approval', OLD.client_approval,
                'refusal_reason', OLD.refusal_reason,
                'pulled', OLD.pulled,
                'pull_date', OLD.pull_date,
                'delivered', OLD.delivered,
                'delivery_date', OLD.delivery_date,
                'created_by', OLD.created_by,
                'created_at', OLD.created_at,
                'updated_at', OLD.updated_at
            ),
            NULL,
            NOW()
        );
    END
  ''', userId: 1);

  print('✓ Ticket item change another audit triggers created');
}
