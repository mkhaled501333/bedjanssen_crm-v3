# Auth Activity Log Implementation

This document describes the activity logging implementation for the authentication system in the CRM backend.

## Overview

Activity logging has been implemented for authentication operations to track user login and logout activities, providing an audit trail for security and compliance purposes.

## Implemented Activity Logging

### Authentication Activities

#### User Login
- **Activity ID 1**: User login
- **Description**: تسجيل دخول المستخدم إلى النظام (User login to the system)
- **Route**: `POST /api/auth/login`
- **Entity**: users (entity_id: 1)
- **Implementation**: Logs successful user authentication

#### User Logout
- **Activity ID 2**: User logout
- **Description**: تسجيل خروج المستخدم من النظام (User logout from the system)
- **Route**: `POST /api/auth/logout`
- **Entity**: users (entity_id: 1)
- **Implementation**: Logs user logout activity

## Technical Implementation

### Login Activity Logging
The login endpoint logs activity after successful authentication:

```dart
// Log login activity
try {
  await ActivityLogService.log(
    entityId: 1, // users entity
    recordId: user.id,
    activityId: 1, // User login activity
    userId: user.id,
  );
} catch (e) {
  print('Failed to log login activity: $e');
}
```

### Logout Activity Logging
The logout endpoint extracts user ID from JWT token and logs the activity:

```dart
// Extract user ID from JWT token for activity logging
int userId = 1; // Default fallback
try {
  final authHeader = request.headers['authorization'];
  if (authHeader != null && authHeader.startsWith('Bearer ')) {
    final token = authHeader.substring(7);
    final jwt = JWT.verify(token, SecretKey('your-secret-key'));
    userId = jwt.payload['id'] as int? ?? 1;
  }
} catch (e) {
  print('Failed to extract user ID from JWT token: $e');
}

// Log logout activity
try {
  await ActivityLogService.log(
    entityId: 1, // users entity
    recordId: userId,
    activityId: 2, // User logout activity
    userId: userId,
  );
} catch (e) {
    print('Failed to log logout activity: $e');
}
```

### Error Handling
- All activity logging operations are wrapped in try-catch blocks
- Logging failures do not affect the main authentication operation
- Errors are logged to the console for debugging
- Default fallback user ID (1) is used if JWT extraction fails

## Database Schema

The activity logging system uses the following tables:

- **entities**: Defines entity types (users = entity_id 1)
- **activities**: Defines activity types with descriptions
- **activity_logs**: Stores individual activity log entries

## Usage Examples

### User Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "john.doe",
  "password": "password123"
}
```
This will log one activity: "User login" (ID: 1) for the authenticated user

### User Logout
```http
POST /api/auth/logout
Authorization: Bearer <jwt_token>
```
This will log one activity: "User logout" (ID: 2) for the user extracted from the JWT token

## Security Considerations

1. **JWT Token Validation**: The logout endpoint validates JWT tokens before logging
2. **Fallback Mechanism**: Default user ID is used if token extraction fails
3. **Error Isolation**: Activity logging errors don't affect authentication flow
4. **Audit Trail**: All login/logout activities are tracked for security monitoring

## Benefits

1. **Security Monitoring**: Track all authentication activities
2. **Audit Compliance**: Meet regulatory requirements for access logging
3. **User Accountability**: Each authentication action is tied to a specific user
4. **Debugging**: Assists in troubleshooting authentication issues
5. **Analytics**: Provides insights into user login patterns

## Future Enhancements

- Add IP address and user agent logging for enhanced security
- Implement failed login attempt logging
- Add session duration tracking