# User Management Module

A comprehensive user management system for the Janssen CRM application, built with Dart Frog.

## Overview

This module provides complete user management functionality including:

- ✅ User CRUD operations (Create, Read, Update) - Delete functionality disabled
- ✅ User permission management
- ✅ User search and pagination
- ✅ Activity logging for all operations
- ✅ Comprehensive API documentation
- ✅ HTTP test files for development

## Quick Start

### 1. API Endpoints

The user management module exposes the following endpoints:

```
GET    /api/users-management              # Get all users with pagination
POST   /api/users-management              # Create new user
GET    /api/users-management/{id}         # Get user by ID
PUT    /api/users-management/{id}         # Update user
DELETE /api/users-management/{id}         # Delete user (DISABLED)
GET    /api/users-management/{id}/permissions    # Get user permissions
PUT    /api/users-management/{id}/permissions    # Update user permissions
POST   /api/users-management/{id}/permissions    # Add user permissions
```

### 2. Basic Usage

#### Create a User
```http
POST /api/users-management
Content-Type: application/json

{
  "name": "John Doe",
  "username": "john.doe",
  "password": "secure_password",
  "companyId": 1,
  "permissions": [1, 10, 20]
}
```

#### Get All Users
```http
GET /api/users-management?limit=10&offset=0
```

#### Update User Permissions
```http
PUT /api/users-management/123/permissions
Content-Type: application/json

{
  "permissions": [1, 40],
  "updatedBy": 1
}
```

## File Structure

```
users-management/
├── index.dart                    # Main users endpoint (GET, POST)
├── [id]/
│   ├── index.dart                # Individual user operations (GET, PUT, DELETE)
│   └── permissions/
│       └── index.dart            # User permissions management
└── docs/
    ├── README.md                 # This file
    ├── USER_MANAGEMENT_API.md    # Complete API documentation
    ├── PERMISSIONS_REFERENCE.md  # Permission system reference
    └── users-management-api.http # HTTP test file
```

## Features

### User Management
- **Create Users**: Add new users with validation
- **View Users**: List all users with pagination and search
- **Update Users**: Modify user information
- **Delete Users**: ⚠️ Disabled for security purposes
- **User Validation**: Username uniqueness, required fields

### Permission System
- **Granular Permissions**: 20+ different permission types
- **Permission Categories**: Users, Tickets, Customers, Reports, etc.
- **Flexible Assignment**: Add or replace permissions
- **Permission Validation**: Ensure only valid permissions are assigned

### Security Features
- **CORS Support**: Cross-origin request handling
- **Input Validation**: Comprehensive request validation
- **Activity Logging**: All operations are logged
- **Error Handling**: Proper error responses and status codes

### Developer Experience
- **Comprehensive Documentation**: Detailed API docs
- **HTTP Test Files**: Ready-to-use test requests
- **Permission Reference**: Complete permission system guide
- **Error Examples**: Common error scenarios covered

## Permission System

### Permission Categories

| Category | IDs | Description |
|----------|-----|-------------|
| User Management | 1-9 | User CRUD and permission management |
| Ticket Management | 10-19 | Ticket operations |
| Customer Management | 20-29 | Customer operations |
| Reporting | 30-39 | Report viewing and exporting |
| Master Data | 40-49 | System configuration data |
| Administration | 50-69 | System administration |

### Common Permission Sets

**Basic User**: `[1, 10, 20, 30, 40]`
- View-only access to main features

**Customer Service**: `[1, 10, 11, 12, 14, 20, 21, 22, 30, 40]`
- Full ticket and customer management

**Manager**: `[1, 10, 11, 12, 13, 14, 20, 21, 22, 23, 30, 31, 40, 50]`
- Full operational access plus reporting

**Admin**: `[1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 20, 21, 22, 23, 30, 31, 40, 41, 50, 60]`
- Complete system access

## Testing

### Using the HTTP Test File

1. Open `docs/users-management-api.http` in VS Code
2. Install the REST Client extension
3. Update the variables at the top:
   ```
   @baseUrl = http://localhost:8080
   @authToken = your-jwt-token
   ```
4. Click "Send Request" on any test case

### Test Categories

- **Basic CRUD**: Create, read, update, delete operations
- **Permission Management**: Permission assignment and validation
- **Error Handling**: Invalid inputs and edge cases
- **Pagination**: Large dataset handling
- **Search**: User search functionality

## Integration

### Frontend Integration

```javascript
// Example: Check user permissions in React
const canCreateUsers = user.permissions.includes(2);
const canDeleteTickets = user.permissions.includes(13);

// Example: API call to create user
const createUser = async (userData) => {
  const response = await fetch('/api/users-management', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify(userData)
  });
  return response.json();
};
```

### Database Schema

The module uses the existing `users` table:

```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  company_id INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  username VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  created_by INT,
  is_active BOOLEAN DEFAULT TRUE,
  permissions JSON DEFAULT '[]',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## Activity Logging

All user management operations are automatically logged:

- **User Creation**: `action: 'create'`
- **User Updates**: `action: 'update'`
- **User Deletion**: `action: 'delete'`
- **Permission Changes**: `action: 'update_permissions'` or `action: 'add_permissions'`

## Error Handling

### Common HTTP Status Codes

- `200`: Success
- `201`: Created successfully
- `400`: Bad request (validation errors)
- `401`: Unauthorized
- `404`: User not found
- `409`: Conflict (username exists)
- `500`: Internal server error

### Error Response Format

```json
{
  "error": "Descriptive error message"
}
```

## Performance Considerations

- **Pagination**: Default limit of 10 users per request
- **Search Optimization**: Indexed username and name fields
- **Permission Caching**: Consider caching user permissions
- **Database Queries**: Optimized queries with proper indexing

## Security Best Practices

1. **Authentication**: Always validate JWT tokens
2. **Authorization**: Check permissions for each operation
3. **Input Validation**: Validate all input data
4. **Password Security**: Consider implementing password hashing
5. **Audit Logging**: Log all sensitive operations

## Troubleshooting

### Common Issues

1. **"Username already exists"**: Check for duplicate usernames
2. **"Invalid permission ID"**: Verify permission IDs against reference
3. **"User not found"**: Ensure user ID exists in database
4. **CORS errors**: Check CORS headers configuration

### Debug Steps

1. Check server logs for detailed error messages
2. Verify database connectivity
3. Test with HTTP client (Postman, REST Client)
4. Review activity logs for operation history

## Contributing

### Adding New Permissions

1. Add permission ID and name to `_getValidPermissions()` in permissions endpoint
2. Update `PERMISSIONS_REFERENCE.md` documentation
3. Add test cases to HTTP test file
4. Update frontend permission checks

### Adding New Endpoints

1. Create new route file following existing patterns
2. Add CORS headers and error handling
3. Implement activity logging
4. Add documentation and tests
5. Update this README

## Support

For questions or issues:

1. Check the documentation files in the `docs/` folder
2. Review the HTTP test file for usage examples
3. Check activity logs for operation history
4. Review server logs for error details

## License

This module is part of the Janssen CRM application.