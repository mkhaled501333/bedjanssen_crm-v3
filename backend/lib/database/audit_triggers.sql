-- =====================================================
-- AUDIT TRIGGERS FOR JANSSEN CRM DATABASE
-- =====================================================
-- This file contains triggers to automatically log all
-- INSERT, UPDATE, and DELETE operations to audit_logs table
-- =====================================================

-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS users_insert_audit;
DROP TRIGGER IF EXISTS users_update_audit;
DROP TRIGGER IF EXISTS users_delete_audit;

DROP TRIGGER IF EXISTS customers_insert_audit;
DROP TRIGGER IF EXISTS customers_update_audit;
DROP TRIGGER IF EXISTS customers_delete_audit;

DROP TRIGGER IF EXISTS tickets_insert_audit;
DROP TRIGGER IF EXISTS tickets_update_audit;
DROP TRIGGER IF EXISTS tickets_delete_audit;

DROP TRIGGER IF EXISTS companies_insert_audit;
DROP TRIGGER IF EXISTS companies_update_audit;
DROP TRIGGER IF EXISTS companies_delete_audit;

DROP TRIGGER IF EXISTS roles_insert_audit;
DROP TRIGGER IF EXISTS roles_update_audit;
DROP TRIGGER IF EXISTS roles_delete_audit;

DROP TRIGGER IF EXISTS permissions_insert_audit;
DROP TRIGGER IF EXISTS permissions_update_audit;
DROP TRIGGER IF EXISTS permissions_delete_audit;

DROP TRIGGER IF EXISTS user_roles_insert_audit;
DROP TRIGGER IF EXISTS user_roles_update_audit;
DROP TRIGGER IF EXISTS user_roles_delete_audit;

DROP TRIGGER IF EXISTS user_permissions_insert_audit;
DROP TRIGGER IF EXISTS user_permissions_update_audit;
DROP TRIGGER IF EXISTS user_permissions_delete_audit;

DROP TRIGGER IF EXISTS role_permissions_insert_audit;
DROP TRIGGER IF EXISTS role_permissions_update_audit;
DROP TRIGGER IF EXISTS role_permissions_delete_audit;

DROP TRIGGER IF EXISTS ticket_items_insert_audit;
DROP TRIGGER IF EXISTS ticket_items_update_audit;
DROP TRIGGER IF EXISTS ticket_items_delete_audit;

-- =====================================================
-- USERS TABLE AUDIT TRIGGERS
-- =====================================================

DELIMITER //

CREATE TRIGGER users_insert_audit
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'INSERT',
        'users',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'company_id', NEW.company_id,
            'name', NEW.name,
            'username', NEW.username,
            'created_by', NEW.created_by,
            'is_active', NEW.is_active,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER users_update_audit
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'UPDATE',
        'users',
        CAST(NEW.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'company_id', OLD.company_id,
            'name', OLD.name,
            'username', OLD.username,
            'created_by', OLD.created_by,
            'is_active', OLD.is_active,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'company_id', NEW.company_id,
            'name', NEW.name,
            'username', NEW.username,
            'created_by', NEW.created_by,
            'is_active', NEW.is_active,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER users_delete_audit
AFTER DELETE ON users
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
        'DELETE',
        'users',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'company_id', OLD.company_id,
            'name', OLD.name,
            'username', OLD.username,
            'created_by', OLD.created_by,
            'is_active', OLD.is_active,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- CUSTOMERS TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER customers_insert_audit
AFTER INSERT ON customers
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
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
END//

CREATE TRIGGER customers_update_audit
AFTER UPDATE ON customers
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
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
END//

CREATE TRIGGER customers_delete_audit
AFTER DELETE ON customers
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
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
END//

-- =====================================================
-- TICKETS TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER tickets_insert_audit
AFTER INSERT ON tickets
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
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
END//

CREATE TRIGGER tickets_update_audit
AFTER UPDATE ON tickets
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(COALESCE(NEW.closed_by, NEW.created_by) AS CHAR),
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
END//

CREATE TRIGGER tickets_delete_audit
AFTER DELETE ON tickets
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
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
END//

-- =====================================================
-- COMPANIES TABLE AUDIT TRIGGERS
-- =====================================================

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
END//

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
END//

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
END//

-- =====================================================
-- ROLES TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER roles_insert_audit
AFTER INSERT ON roles
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'INSERT',
        'roles',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'name', NEW.name,
            'description', NEW.description,
            'created_by', NEW.created_by,
            'is_active', NEW.is_active,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER roles_update_audit
AFTER UPDATE ON roles
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'UPDATE',
        'roles',
        CAST(NEW.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'name', OLD.name,
            'description', OLD.description,
            'created_by', OLD.created_by,
            'is_active', OLD.is_active,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'name', NEW.name,
            'description', NEW.description,
            'created_by', NEW.created_by,
            'is_active', NEW.is_active,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER roles_delete_audit
AFTER DELETE ON roles
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
        'DELETE',
        'roles',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'name', OLD.name,
            'description', OLD.description,
            'created_by', OLD.created_by,
            'is_active', OLD.is_active,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

DELIMITER ;

-- =====================================================
-- PERMISSIONS TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER permissions_insert_audit
AFTER INSERT ON permissions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'INSERT',
        'permissions',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'title', NEW.title,
            'default_conditions', NEW.default_conditions,
            'key', NEW.key,
            'description', NEW.description,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER permissions_update_audit
AFTER UPDATE ON permissions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'UPDATE',
        'permissions',
        CAST(NEW.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'title', OLD.title,
            'default_conditions', OLD.default_conditions,
            'key', OLD.key,
            'description', OLD.description,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'title', NEW.title,
            'default_conditions', NEW.default_conditions,
            'key', NEW.key,
            'description', NEW.description,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER permissions_delete_audit
AFTER DELETE ON permissions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'DELETE',
        'permissions',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'title', OLD.title,
            'default_conditions', OLD.default_conditions,
            'key', OLD.key,
            'description', OLD.description,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- USER_ROLES TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER user_roles_insert_audit
AFTER INSERT ON user_roles
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.assigned_by AS CHAR),
        'INSERT',
        'user_roles',
        CONCAT(NEW.user_id, '-', NEW.role_id),
        NULL,
        JSON_OBJECT(
            'user_id', NEW.user_id,
            'role_id', NEW.role_id,
            'assigned_by', NEW.assigned_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER user_roles_update_audit
AFTER UPDATE ON user_roles
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.assigned_by AS CHAR),
        'UPDATE',
        'user_roles',
        CONCAT(NEW.user_id, '-', NEW.role_id),
        JSON_OBJECT(
            'user_id', OLD.user_id,
            'role_id', OLD.role_id,
            'assigned_by', OLD.assigned_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'user_id', NEW.user_id,
            'role_id', NEW.role_id,
            'assigned_by', NEW.assigned_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER user_roles_delete_audit
AFTER DELETE ON user_roles
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.assigned_by AS CHAR),
        'DELETE',
        'user_roles',
        CONCAT(OLD.user_id, '-', OLD.role_id),
        JSON_OBJECT(
            'user_id', OLD.user_id,
            'role_id', OLD.role_id,
            'assigned_by', OLD.assigned_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- ROLE_PERMISSIONS TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER role_permissions_insert_audit
AFTER INSERT ON role_permissions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'INSERT',
        'role_permissions',
        CONCAT(NEW.role_id, '-', NEW.permission_id),
        NULL,
        JSON_OBJECT(
            'role_id', NEW.role_id,
            'permission_id', NEW.permission_id,
            'conditions', NEW.conditions,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER role_permissions_update_audit
AFTER UPDATE ON role_permissions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'UPDATE',
        'role_permissions',
        CONCAT(NEW.role_id, '-', NEW.permission_id),
        JSON_OBJECT(
            'role_id', OLD.role_id,
            'permission_id', OLD.permission_id,
            'conditions', OLD.conditions,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'role_id', NEW.role_id,
            'permission_id', NEW.permission_id,
            'conditions', NEW.conditions,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER role_permissions_delete_audit
AFTER DELETE ON role_permissions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
        'DELETE',
        'role_permissions',
        CONCAT(OLD.role_id, '-', OLD.permission_id),
        JSON_OBJECT(
            'role_id', OLD.role_id,
            'permission_id', OLD.permission_id,
            'conditions', OLD.conditions,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- USER_PERMISSIONS TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER user_permissions_insert_audit
AFTER INSERT ON user_permissions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'INSERT',
        'user_permissions',
        CONCAT(NEW.user_id, '-', NEW.permission_id),
        NULL,
        JSON_OBJECT(
            'user_id', NEW.user_id,
            'permission_id', NEW.permission_id,
            'conditions', NEW.conditions,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER user_permissions_update_audit
AFTER UPDATE ON user_permissions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'UPDATE',
        'user_permissions',
        CONCAT(NEW.user_id, '-', NEW.permission_id),
        JSON_OBJECT(
            'user_id', OLD.user_id,
            'permission_id', OLD.permission_id,
            'conditions', OLD.conditions,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'user_id', NEW.user_id,
            'permission_id', NEW.permission_id,
            'conditions', NEW.conditions,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER user_permissions_delete_audit
AFTER DELETE ON user_permissions
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
        'DELETE',
        'user_permissions',
        CONCAT(OLD.user_id, '-', OLD.permission_id),
        JSON_OBJECT(
            'user_id', OLD.user_id,
            'permission_id', OLD.permission_id,
            'conditions', OLD.conditions,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- CALL_CATEGORIES TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER call_categories_insert_audit
AFTER INSERT ON call_categories
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'INSERT',
        'call_categories',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'name', NEW.name
        ),
        NOW()
    );
END//

CREATE TRIGGER call_categories_update_audit
AFTER UPDATE ON call_categories
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'UPDATE',
        'call_categories',
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
END//

CREATE TRIGGER call_categories_delete_audit
AFTER DELETE ON call_categories
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'DELETE',
        'call_categories',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'name', OLD.name
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- CITIES TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER cities_insert_audit
AFTER INSERT ON cities
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
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
END//

CREATE TRIGGER cities_update_audit
AFTER UPDATE ON cities
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
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
END//

CREATE TRIGGER cities_delete_audit
AFTER DELETE ON cities
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
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
END//

-- =====================================================
-- GOVERNORATES TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER governorates_insert_audit
AFTER INSERT ON governorates
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
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
END//

CREATE TRIGGER governorates_update_audit
AFTER UPDATE ON governorates
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
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
END//

CREATE TRIGGER governorates_delete_audit
AFTER DELETE ON governorates
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
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
END//

-- =====================================================
-- TICKET_ITEMS TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER ticket_items_insert_audit
AFTER INSERT ON ticket_items
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
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
END//

CREATE TRIGGER ticket_items_update_audit
AFTER UPDATE ON ticket_items
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
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
END//

CREATE TRIGGER ticket_items_delete_audit
AFTER DELETE ON ticket_items
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
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
END//

-- =====================================================
-- CUSTOMERCALL TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER customercall_insert_audit
AFTER INSERT ON customercall
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'INSERT',
        'customercall',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'company_id', NEW.company_id,
            'customer_id', NEW.customer_id,
            'call_category_id', NEW.call_category_id,
            'notes', NEW.notes,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER customercall_update_audit
AFTER UPDATE ON customercall
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'UPDATE',
        'customercall',
        CAST(NEW.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'company_id', OLD.company_id,
            'customer_id', OLD.customer_id,
            'call_category_id', OLD.call_category_id,
            'notes', OLD.notes,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'company_id', NEW.company_id,
            'customer_id', NEW.customer_id,
            'call_category_id', NEW.call_category_id,
            'notes', NEW.notes,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER customercall_delete_audit
AFTER DELETE ON customercall
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
        'DELETE',
        'customercall',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'company_id', OLD.company_id,
            'customer_id', OLD.customer_id,
            'call_category_id', OLD.call_category_id,
            'notes', OLD.notes,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- PRODUCT_INFO TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER product_info_insert_audit
AFTER INSERT ON product_info
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'INSERT',
        'product_info',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'name', NEW.name,
            'description', NEW.description,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER product_info_update_audit
AFTER UPDATE ON product_info
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'UPDATE',
        'product_info',
        CAST(NEW.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'name', OLD.name,
            'description', OLD.description,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'name', NEW.name,
            'description', NEW.description,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER product_info_delete_audit
AFTER DELETE ON product_info
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'DELETE',
        'product_info',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'name', OLD.name,
            'description', OLD.description,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- REQUEST_REASONS TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER request_reasons_insert_audit
AFTER INSERT ON request_reasons
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'INSERT',
        'request_reasons',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'name', NEW.name,
            'description', NEW.description
        ),
        NOW()
    );
END//

CREATE TRIGGER request_reasons_update_audit
AFTER UPDATE ON request_reasons
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'UPDATE',
        'request_reasons',
        CAST(NEW.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'name', OLD.name,
            'description', OLD.description
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'name', NEW.name,
            'description', NEW.description
        ),
        NOW()
    );
END//

CREATE TRIGGER request_reasons_delete_audit
AFTER DELETE ON request_reasons
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'DELETE',
        'request_reasons',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'name', OLD.name,
            'description', OLD.description
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- TICKET_CATEGORIES TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER ticket_categories_insert_audit
AFTER INSERT ON ticket_categories
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'INSERT',
        'ticket_categories',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'name', NEW.name,
            'description', NEW.description
        ),
        NOW()
    );
END//

CREATE TRIGGER ticket_categories_update_audit
AFTER UPDATE ON ticket_categories
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'UPDATE',
        'ticket_categories',
        CAST(NEW.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'name', OLD.name,
            'description', OLD.description
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'name', NEW.name,
            'description', NEW.description
        ),
        NOW()
    );
END//

CREATE TRIGGER ticket_categories_delete_audit
AFTER DELETE ON ticket_categories
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        'SYSTEM',
        'DELETE',
        'ticket_categories',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'name', OLD.name,
            'description', OLD.description
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- TICKET_ITEM_CHANGE_ANOTHER TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER ticket_item_change_another_insert_audit
AFTER INSERT ON ticket_item_change_another
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'INSERT',
        'ticket_item_change_another',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'ticket_item_id', NEW.ticket_item_id,
            'product_id', NEW.product_id,
            'product_size', NEW.product_size,
            'quantity', NEW.quantity,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER ticket_item_change_another_update_audit
AFTER UPDATE ON ticket_item_change_another
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'UPDATE',
        'ticket_item_change_another',
        CAST(NEW.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'ticket_item_id', OLD.ticket_item_id,
            'product_id', OLD.product_id,
            'product_size', OLD.product_size,
            'quantity', OLD.quantity,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'ticket_item_id', NEW.ticket_item_id,
            'product_id', NEW.product_id,
            'product_size', NEW.product_size,
            'quantity', NEW.quantity,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER ticket_item_change_another_delete_audit
AFTER DELETE ON ticket_item_change_another
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
        'DELETE',
        'ticket_item_change_another',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'ticket_item_id', OLD.ticket_item_id,
            'product_id', OLD.product_id,
            'product_size', OLD.product_size,
            'quantity', OLD.quantity,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- TICKET_ITEM_CHANGE_SAME TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER ticket_item_change_same_insert_audit
AFTER INSERT ON ticket_item_change_same
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'INSERT',
        'ticket_item_change_same',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'ticket_item_id', NEW.ticket_item_id,
            'quantity', NEW.quantity,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER ticket_item_change_same_update_audit
AFTER UPDATE ON ticket_item_change_same
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'UPDATE',
        'ticket_item_change_same',
        CAST(NEW.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'ticket_item_id', OLD.ticket_item_id,
            'quantity', OLD.quantity,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'ticket_item_id', NEW.ticket_item_id,
            'quantity', NEW.quantity,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER ticket_item_change_same_delete_audit
AFTER DELETE ON ticket_item_change_same
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
        'DELETE',
        'ticket_item_change_same',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'ticket_item_id', OLD.ticket_item_id,
            'quantity', OLD.quantity,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- TICKET_ITEM_MAINTENANCE TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER ticket_item_maintenance_insert_audit
AFTER INSERT ON ticket_item_maintenance
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'INSERT',
        'ticket_item_maintenance',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'ticket_item_id', NEW.ticket_item_id,
            'maintenance_type', NEW.maintenance_type,
            'description', NEW.description,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER ticket_item_maintenance_update_audit
AFTER UPDATE ON ticket_item_maintenance
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'UPDATE',
        'ticket_item_maintenance',
        CAST(NEW.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'ticket_item_id', OLD.ticket_item_id,
            'maintenance_type', OLD.maintenance_type,
            'description', OLD.description,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'ticket_item_id', NEW.ticket_item_id,
            'maintenance_type', NEW.maintenance_type,
            'description', NEW.description,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER ticket_item_maintenance_delete_audit
AFTER DELETE ON ticket_item_maintenance
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
        'DELETE',
        'ticket_item_maintenance',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'ticket_item_id', OLD.ticket_item_id,
            'maintenance_type', OLD.maintenance_type,
            'description', OLD.description,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

-- =====================================================
-- TICKETCALL TABLE AUDIT TRIGGERS
-- =====================================================

CREATE TRIGGER ticketcall_insert_audit
AFTER INSERT ON ticketcall
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'INSERT',
        'ticketcall',
        CAST(NEW.id AS CHAR),
        NULL,
        JSON_OBJECT(
            'id', NEW.id,
            'company_id', NEW.company_id,
            'ticket_id', NEW.ticket_id,
            'call_category_id', NEW.call_category_id,
            'notes', NEW.notes,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER ticketcall_update_audit
AFTER UPDATE ON ticketcall
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(NEW.created_by AS CHAR),
        'UPDATE',
        'ticketcall',
        CAST(NEW.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'company_id', OLD.company_id,
            'ticket_id', OLD.ticket_id,
            'call_category_id', OLD.call_category_id,
            'notes', OLD.notes,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'id', NEW.id,
            'company_id', NEW.company_id,
            'ticket_id', NEW.ticket_id,
            'call_category_id', NEW.call_category_id,
            'notes', NEW.notes,
            'created_by', NEW.created_by,
            'created_at', NEW.created_at,
            'updated_at', NEW.updated_at
        ),
        NOW()
    );
END//

CREATE TRIGGER ticketcall_delete_audit
AFTER DELETE ON ticketcall
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (user_id, action, target_entity, target_id, old_value, new_value, timestamp)
    VALUES (
        CAST(OLD.created_by AS CHAR),
        'DELETE',
        'ticketcall',
        CAST(OLD.id AS CHAR),
        JSON_OBJECT(
            'id', OLD.id,
            'company_id', OLD.company_id,
            'ticket_id', OLD.ticket_id,
            'call_category_id', OLD.call_category_id,
            'notes', OLD.notes,
            'created_by', OLD.created_by,
            'created_at', OLD.created_at,
            'updated_at', OLD.updated_at
        ),
        NULL,
        NOW()
    );
END//

DELIMITER ;

-- =====================================================
-- END OF AUDIT TRIGGERS
-- =====================================================
-- To apply these triggers, run this SQL file against
-- your MySQL database:
-- mysql -u username -p database_name < audit_triggers.sql
--
-- IMPORTANT NOTES:
-- 1. These triggers will automatically log all changes to the audit_logs table
-- 2. Make sure your application has proper user context for accurate user_id logging
-- 3. Consider the performance impact of these triggers on high-volume operations
-- 4. Test thoroughly in a development environment before applying to production
-- 5. You may need to adjust the JSON_OBJECT fields based on your specific requirements
-- =====================================================