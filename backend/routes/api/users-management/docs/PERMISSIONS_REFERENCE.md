# User Permissions Reference

This document provides a comprehensive reference for the user permission system in the CRM application.

## Overview

The permission system uses numeric IDs to represent different access levels and capabilities within the application. Each user can have multiple permissions assigned to them.

## Permission Categories

### Simplified Permission System

The system now uses a simplified permission model with only two core permissions:

| ID | Permission Name | Description | Typical Users |
|----|-----------------|-------------|---------------|
| 1 | View Users | Can view user information and user lists | All users, HR, Managers |
| 40 | View Master Data | Can view master data (categories, products, etc.) | All users |

## Permission Hierarchies

### Simplified Permission System

The system now uses a simplified permission model with only two core permissions:

#### No Permissions
```json
[]
```
- Cannot access user management or master data
- Basic system access only

#### View Users Only
```json
[1]
```
- Can view user information and user lists
- Cannot access master data

#### View Master Data Only
```json
[40]
```
- Can view master data (categories, products, etc.)
- Cannot access user management

#### Full Access
```json
[1, 40]
```
- Can view both users and master data
- Complete read access to core system features

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

### Setting User Permissions
```http
PUT /api/users-management/123/permissions
Content-Type: application/json

{
  "permissions": [1, 40],
  "updatedBy": 1
}
```

### Setting No Permissions
```http
PUT /api/users-management/123/permissions
Content-Type: application/json

{
  "permissions": [],
  "updatedBy": 1
}
```

### Adding Specific Permissions
```http
POST /api/users-management/123/permissions
Content-Type: application/json

{
  "permissions": [1],
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
4. **User has no permissions**: This is valid - users can have an empty permission array `[]`

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