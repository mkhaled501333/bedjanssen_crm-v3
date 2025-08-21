# User Permissions Reference

This document provides a comprehensive reference for the user permission system in the CRM application.

## Overview

The permission system uses numeric IDs to represent different access levels and capabilities within the application. Each user can have multiple permissions assigned to them.

## Permission Categories

### User Management (1-9)

| ID | Permission Name | Description | Typical Users |
|----|-----------------|-------------|---------------|
| 1 | View Users | Can view user information and user lists | All users, HR, Managers |
| 2 | Create Users | Can create new user accounts | HR, System Admins |
| 3 | Edit Users | Can modify user information | HR, System Admins |
| 4 | Delete Users | Can delete user accounts | System Admins only |
| 5 | Manage User Permissions | Can modify user permissions | System Admins, HR Managers |

### Ticket Management (10-19)

| ID | Permission Name | Description | Typical Users |
|----|-----------------|-------------|---------------|
| 10 | View Tickets | Can view ticket information | All users |
| 11 | Create Tickets | Can create new tickets | Customer Service, Sales |
| 12 | Edit Tickets | Can modify ticket information | Customer Service, Managers |
| 13 | Delete Tickets | Can delete tickets | Managers, System Admins |
| 14 | Close Tickets | Can close/resolve tickets | Customer Service, Managers |

### Customer Management (20-29)

| ID | Permission Name | Description | Typical Users |
|----|-----------------|-------------|---------------|
| 20 | View Customers | Can view customer information | All users |
| 21 | Create Customers | Can create new customer records | Sales, Customer Service |
| 22 | Edit Customers | Can modify customer information | Sales, Customer Service |
| 23 | Delete Customers | Can delete customer records | Managers, System Admins |

### Reporting (30-39)

| ID | Permission Name | Description | Typical Users |
|----|-----------------|-------------|---------------|
| 30 | View Reports | Can view reports and analytics | Managers, Analysts |
| 31 | Export Reports | Can export reports to files | Managers, Analysts |

### Master Data Management (40-49)

| ID | Permission Name | Description | Typical Users |
|----|-----------------|-------------|---------------|
| 40 | View Master Data | Can view master data (categories, products, etc.) | All users |
| 41 | Edit Master Data | Can modify master data | System Admins, Data Managers |

### System Administration (50-69)

| ID | Permission Name | Description | Typical Users |
|----|-----------------|-------------|---------------|
| 50 | View Activity Logs | Can view system activity logs | Managers, System Admins |
| 60 | System Administration | Full system administration access | System Admins only |

## Permission Hierarchies

### Basic User
```json
[1, 10, 20, 30, 40]
```
- Can view users, tickets, customers, reports, and master data
- Read-only access to most system features

### Customer Service Representative
```json
[1, 10, 11, 12, 14, 20, 21, 22, 30, 40]
```
- Can manage tickets and customers
- Can create, edit, and close tickets
- Can create and edit customers
- Can view reports

### Sales Representative
```json
[1, 10, 11, 20, 21, 22, 30, 40]
```
- Can create tickets for customer issues
- Can manage customer information
- Can view reports for sales analytics

### Manager
```json
[1, 10, 11, 12, 13, 14, 20, 21, 22, 23, 30, 31, 40, 50]
```
- Full access to tickets and customers
- Can delete tickets and customers
- Can export reports
- Can view activity logs

### HR Manager
```json
[1, 2, 3, 5, 10, 20, 30, 31, 40, 50]
```
- Can manage users and their permissions
- Can view system activity
- Limited access to operational data

### System Administrator
```json
[1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 20, 21, 22, 23, 30, 31, 40, 41, 50, 60]
```
- Full access to all system features
- Can perform all operations
- Complete system administration rights

## Permission Validation

### Frontend Validation
The frontend should check user permissions before displaying UI elements:

```javascript
// Example: Check if user can create tickets
if (user.permissions.includes(11)) {
  // Show "Create Ticket" button
}

// Example: Check if user can delete customers
if (user.permissions.includes(23)) {
  // Show "Delete Customer" button
}
```

### Backend Validation
The backend should validate permissions for each API endpoint:

```dart
// Example: Validate user can edit tickets
if (!user.permissions.contains(12)) {
  return Response.json(
    statusCode: 403,
    body: {'error': 'Insufficient permissions'},
  );
}
```

## Best Practices

### 1. Principle of Least Privilege
- Grant users only the minimum permissions needed for their role
- Regularly review and audit user permissions
- Remove unnecessary permissions promptly

### 2. Role-Based Assignment
- Define standard permission sets for common roles
- Use role templates when creating new users
- Document permission requirements for each role

### 3. Permission Inheritance
- Consider creating permission groups or roles
- Higher-level permissions may imply lower-level ones
- Document permission dependencies

### 4. Audit and Monitoring
- Log all permission changes
- Monitor for unusual permission usage
- Regular permission reviews

## API Usage Examples

### Checking User Permissions
```http
GET /api/users-management/123/permissions
```

### Setting Basic User Permissions
```http
PUT /api/users-management/123/permissions
Content-Type: application/json

{
  "permissions": [1, 10, 20, 30, 40],
  "updatedBy": 1
}
```

### Adding Manager Permissions
```http
POST /api/users-management/123/permissions
Content-Type: application/json

{
  "permissions": [13, 23, 31, 50],
  "updatedBy": 1
}
```

## Security Considerations

### 1. Permission Escalation
- Users should not be able to grant themselves higher permissions
- Validate that the user making permission changes has the authority to do so
- Log all permission changes for audit purposes

### 2. Session Management
- Permissions should be checked on each request
- Consider caching permissions for performance but ensure cache invalidation
- Re-validate permissions after any user updates

### 3. Default Permissions
- New users should have minimal default permissions
- Require explicit permission grants for sensitive operations
- Consider approval workflows for high-privilege permissions

## Troubleshooting

### Common Issues

1. **User can't access feature**: Check if user has required permission ID
2. **Permission not working**: Verify permission ID is in the valid permissions list
3. **Changes not reflected**: Check if frontend is using cached permission data

### Debugging

1. Check user's current permissions:
   ```http
   GET /api/users-management/{userId}/permissions
   ```

2. Review activity logs for permission changes:
   ```http
   GET /api/activity-logs/user/{userId}
   ```

3. Validate permission IDs against the reference list in this document

## Future Enhancements

### Planned Features
- Permission groups/roles for easier management
- Time-based permissions (temporary access)
- IP-based permission restrictions
- Multi-factor authentication for sensitive permissions

### Extensibility
- Permission IDs 70-99 reserved for future features
- Custom permission categories for specific business needs
- Integration with external authentication systems