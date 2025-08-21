# User Permissions Implementation in CRM System

This document provides a comprehensive overview of how user permissions are implemented in the Janssen CRM system, covering both frontend and backend components.

## Table of Contents

1. [System Overview](#system-overview)
2. [Permission System Architecture](#permission-system-architecture)
3. [Backend Implementation](#backend-implementation)
4. [Frontend Implementation](#frontend-implementation)
5. [Database Schema](#database-schema)
6. [API Endpoints](#api-endpoints)
7. [Security Features](#security-features)
8. [Usage Examples](#usage-examples)
9. [Best Practices](#best-practices)

## System Overview

The CRM system implements a role-based access control (RBAC) system using numeric permission IDs. Each user can have multiple permissions assigned to them, allowing for granular control over system features and operations.

### Key Features

- **Numeric Permission IDs**: Simple integer-based permission system (1-99)
- **Multiple Permissions per User**: Users can have multiple permissions simultaneously
- **Role-Based Templates**: Predefined permission sets for common roles
- **Activity Logging**: All permission changes are logged for audit purposes
- **Frontend Validation**: UI elements are conditionally rendered based on permissions
- **Backend Validation**: API endpoints validate permissions before processing requests

## Permission System Architecture

### Permission Categories

The system organizes permissions into logical categories:

| Category | Permission IDs | Description |
|----------|----------------|-------------|
| User Management | 1-9 | User account operations |
| Ticket Management | 10-19 | Support ticket operations |
| Customer Management | 20-29 | Customer record operations |
| Reporting | 30-39 | Report viewing and export |
| Master Data | 40-49 | System configuration data |
| System Administration | 50-69 | Administrative functions |

### Standard Permission Sets

#### Basic User
```json
[1, 10, 20, 30, 40]
```
- View users, tickets, customers, reports, and master data
- Read-only access to most system features

#### Customer Service Representative
```json
[1, 10, 11, 12, 14, 20, 21, 22, 30, 40]
```
- Can manage tickets and customers
- Can create, edit, and close tickets
- Can create and edit customers
- Can view reports

#### Manager
```json
[1, 10, 11, 12, 13, 14, 20, 21, 22, 23, 30, 31, 40, 50]
```
- Full access to tickets and customers
- Can delete tickets and customers
- Can export reports
- Can view activity logs

#### System Administrator
```json
[1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 20, 21, 22, 23, 30, 31, 40, 41, 50, 60]
```
- Full access to all system features
- Can perform all operations
- Complete system administration rights

## Backend Implementation

### Technology Stack

- **Framework**: Dart Frog (Dart)
- **Database**: MySQL with JSON field for permissions
- **Authentication**: JWT-based with middleware
- **Architecture**: RESTful API with route-based handlers

### Core Components

#### 1. User Model (`backend/lib/models/user.dart`)

```dart
class User {
  final int? id;
  final int companyId;
  final String name;
  final String username;
  final String password;
  final int? createdBy;
  final bool isActive;
  final List<int> permissions;  // Core permissions field
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // ... constructor, methods, and database operations
}
```

**Key Features:**
- Permissions stored as JSON array in database
- Automatic serialization/deserialization
- Database operations with permission support

#### 2. Permission Management API (`backend/routes/api/users-management/[id]/permissions/index.dart`)

**Endpoints:**
- `GET /api/users-management/{id}/permissions` - Retrieve user permissions
- `PUT /api/users-management/{id}/permissions` - Replace all permissions
- `POST /api/users-management/{id}/permissions` - Add new permissions

**Key Functions:**
```dart
/// Validate permissions against valid permission list
Future<Map<String, dynamic>> _validatePermissions(List<int> permissions)

/// Get valid permissions mapping from database
Future<Map<int, String>> _getValidPermissions()

/// Get permission details with names
Future<List<Map<String, dynamic>>> _getPermissionDetails(List<int> permissions)
```

#### 3. Authentication Middleware (`backend/lib/auth_middleware.dart`)

```dart
Middleware jwtAuthentication({required String secretKey}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];
      // JWT validation and user context attachment
      final updatedRequest = request.change(context: {'user': jwt.payload});
      return await innerHandler(updatedRequest);
    };
  };
}
```

### Database Schema

#### Users Table
```sql
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  company_id INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  username VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  created_by INT,
  is_active BOOLEAN DEFAULT TRUE,
  permissions JSON DEFAULT '[]',  -- Permissions stored as JSON array
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
```

#### Permissions Table (Reference)
```sql
CREATE TABLE IF NOT EXISTS permissions (
  id INT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
```

### Permission Validation

The backend validates permissions at multiple levels:

1. **Input Validation**: Ensures permission IDs are valid before saving
2. **Database Constraints**: JSON field validation
3. **Business Logic**: Permission-specific operation validation
4. **Activity Logging**: All permission changes are logged

## Frontend Implementation

### Technology Stack

- **Framework**: Next.js with TypeScript
- **State Management**: React hooks and local state
- **API Communication**: Custom fetch utilities with authentication
- **UI Components**: Custom CSS modules

### Core Components

#### 1. Authentication Utilities (`frontend/src/shared/utils/auth.ts`)

```typescript
export interface User {
  id: number;
  username: string;
  name: string;
  company_id: number;
  company_name?: string;
  permissions?: number[];  // User permissions array
}

/**
 * Check if the current user has a specific permission
 */
export function hasPermission(permissionId: number): boolean {
  const user = getCurrentUser();
  return user?.permissions?.includes(permissionId) || false;
}

/**
 * Check if the current user has any of the specified permissions
 */
export function hasAnyPermission(permissionIds: number[]): boolean {
  const user = getCurrentUser();
  if (!user?.permissions) return false;
  return permissionIds.some(id => user.permissions!.includes(id));
}
```

#### 2. User Management Component (`frontend/src/features/masterdata/ui/components/UserManagement.tsx`)

**Key Features:**
- Permission management modal
- Checkbox-based permission selection
- Real-time permission updates
- Permission validation

**Permission Management Modal:**
```typescript
const renderPermissionsModal = () => {
  if (!showPermissions) return null;

  return (
    <div style={{ /* modal styles */ }}>
      <h3>Manage User Permissions</h3>
      <div>
        {Object.entries(PERMISSIONS).map(([id, name]) => (
          <label key={id}>
            <input
              type="checkbox"
              checked={userPermissions.includes(parseInt(id))}
              onChange={() => togglePermission(parseInt(id))}
            />
            {name}
          </label>
        ))}
      </div>
      {/* Save/Cancel buttons */}
    </div>
  );
};
```

#### 3. API Integration (`frontend/src/features/masterdata/api.ts`)

```typescript
export async function getUserPermissions(id: number): Promise<{ permissions: number[] }> {
  const response = await authFetch(`${getApiBaseURL()}/api/users-management/${id}/permissions`, {
    method: 'GET',
  });
  if (!response.ok) {
    throw new Error('Failed to get user permissions');
  }
  return await response.json();
}

export async function updateUserPermissions(id: number, permissions: number[]): Promise<{ permissions: number[] }> {
  const response = await authFetch(`${getApiBaseURL()}/api/users-management/${id}/permissions`, {
    method: 'PUT',
    body: JSON.stringify({ permissions }),
  });
  if (!response.ok) {
    throw new Error('Failed to update user permissions');
  }
  return await response.json();
}
```

### Permission-Based UI Rendering

The frontend conditionally renders UI elements based on user permissions:

```typescript
// Example: Show delete button only if user has permission
{hasPermission(23) && (
  <button onClick={handleDeleteCustomer}>
    Delete Customer
  </button>
)}

// Example: Show admin panel only for system administrators
{hasPermission(60) && (
  <AdminPanel />
)}
```

## API Endpoints

### User Management Endpoints

| Method | Endpoint | Description | Permission Required |
|--------|----------|-------------|-------------------|
| GET | `/api/users-management` | List all users | 1 (View Users) |
| POST | `/api/users-management` | Create new user | 2 (Create Users) |
| GET | `/api/users-management/{id}` | Get user by ID | 1 (View Users) |
| PUT | `/api/users-management/{id}` | Update user | 3 (Edit Users) |
| DELETE | `/api/users-management/{id}` | Delete user | **DISABLED** |

### Permission Management Endpoints

| Method | Endpoint | Description | Permission Required |
|--------|----------|-------------|-------------------|
| GET | `/api/users-management/{id}/permissions` | Get user permissions | 1 (View Users) |
| PUT | `/api/users-management/{id}/permissions` | Replace all permissions | 5 (Manage User Permissions) |
| POST | `/api/users-management/{id}/permissions` | Add permissions | 5 (Manage User Permissions) |

### Response Formats

#### User Permissions Response
```json
{
  "userId": 1,
  "username": "john.doe",
  "name": "John Doe",
  "permissions": [1, 2, 3, 10, 20],
  "permissionDetails": [
    {
      "id": 1,
      "name": "View Users",
      "valid": true
    },
    {
      "id": 2,
      "name": "Create Users",
      "valid": true
    }
  ]
}
```

## Security Features

### 1. Permission Validation

- **Backend Validation**: All permission operations validate against valid permission list
- **Input Sanitization**: Permission IDs are validated before database operations
- **Role Escalation Prevention**: Users cannot grant themselves higher permissions

### 2. Authentication & Authorization

- **JWT Tokens**: Secure token-based authentication
- **Middleware Protection**: Route-level permission checking
- **Session Management**: Secure session handling with localStorage

### 3. Activity Logging

All permission-related operations are logged:

```dart
await ActivityLogService.logByNames(
  entityName: 'users',
  recordId: userId,
  activityName: 'UPDATE',
  userId: updatedBy,
  details: {
    'username': savedUser.username,
    'action': 'update_permissions',
    'newPermissions': newPermissions,
    'permissionCount': newPermissions.length,
  },
);
```

### 4. Data Protection

- **Password Security**: Passwords stored in database (consider hashing for production)
- **CORS Protection**: Cross-origin request handling
- **Input Validation**: Comprehensive input validation and sanitization

## Usage Examples

### 1. Checking Permissions in Frontend

```typescript
import { hasPermission, hasAnyPermission } from '@/shared/utils/auth';

// Check single permission
if (hasPermission(11)) {
  // User can create tickets
  showCreateTicketButton();
}

// Check multiple permissions
if (hasAnyPermission([21, 22])) {
  // User can create or edit customers
  showCustomerManagementTools();
}
```

### 2. Conditional UI Rendering

```typescript
function CustomerActions({ customerId }: { customerId: number }) {
  return (
    <div>
      {hasPermission(20) && (
        <button onClick={() => viewCustomer(customerId)}>
          View Details
        </button>
      )}
      
      {hasPermission(22) && (
        <button onClick={() => editCustomer(customerId)}>
          Edit Customer
        </button>
      )}
      
      {hasPermission(23) && (
        <button onClick={() => deleteCustomer(customerId)}>
          Delete Customer
        </button>
      )}
    </div>
  );
}
```

### 3. API Permission Checking

```typescript
// In API service functions
export async function deleteCustomer(customerId: number) {
  if (!hasPermission(23)) {
    throw new Error('Insufficient permissions to delete customers');
  }
  
  const response = await authFetch(`/api/customers/${customerId}`, {
    method: 'DELETE',
  });
  
  return response.json();
}
```

### 4. Backend Permission Validation

```dart
// Example: Validate user can edit tickets
Future<Response> handleEditTicket(RequestContext context, int ticketId) async {
  final user = getCurrentUser(context);
  
  if (!user.permissions.contains(12)) { // Edit Tickets permission
    return Response.json(
      statusCode: 403,
      body: {'error': 'Insufficient permissions to edit tickets'},
    );
  }
  
  // Process ticket edit...
}
```

## Best Practices

### 1. Permission Design

- **Principle of Least Privilege**: Grant minimum permissions needed
- **Role-Based Templates**: Use predefined permission sets for common roles
- **Regular Audits**: Review permissions periodically
- **Documentation**: Maintain clear permission documentation

### 2. Implementation

- **Frontend Validation**: Always check permissions before showing UI elements
- **Backend Validation**: Never rely solely on frontend permission checks
- **Error Handling**: Provide clear error messages for permission violations
- **Logging**: Log all permission-related activities

### 3. Security

- **Input Validation**: Validate all permission inputs
- **Escalation Prevention**: Prevent users from granting themselves higher permissions
- **Session Security**: Secure token storage and handling
- **Regular Reviews**: Audit permission assignments regularly

### 4. Performance

- **Permission Caching**: Cache permissions for performance (with proper invalidation)
- **Efficient Queries**: Optimize database queries for permission checks
- **Minimal Overhead**: Keep permission checking lightweight

## Future Enhancements

### Planned Features

1. **Permission Groups/Roles**: Create reusable permission sets
2. **Time-Based Permissions**: Temporary access grants
3. **IP-Based Restrictions**: Location-based permission controls
4. **Multi-Factor Authentication**: Enhanced security for sensitive permissions
5. **Permission Inheritance**: Hierarchical permission structures

### Extensibility

- **Permission IDs 70-99**: Reserved for future features
- **Custom Categories**: Business-specific permission categories
- **External Integration**: Integration with external authentication systems
- **Audit Reports**: Advanced permission usage analytics

## Conclusion

The user permissions system in the Janssen CRM provides a robust, scalable foundation for access control. The combination of numeric permission IDs, comprehensive validation, and activity logging ensures security while maintaining flexibility for different user roles and requirements.

The system successfully balances simplicity with functionality, making it easy to manage while providing granular control over system access. Regular audits and adherence to security best practices will ensure the system remains secure and effective as the application grows.


