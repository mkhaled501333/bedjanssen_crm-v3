# Auth API Activities

This document lists all the activities available in the auth API routes with their corresponding activity names.

## Login Routes (`/api/auth/login`)

### User Login
- **Route**: `POST /api/auth/login`
- **Activity Name**: User login
- **Activity ID**: 1
- **Entity ID**: 1 (users)
- **Description**: Authenticates a user with username and password, returns JWT token and user information
- **Activity Logging**: ✅ Implemented - Logs successful login attempts
- **Parameters**:
  - `username` (required): User's username
  - `password` (required): User's password
- **Response**: Returns JWT token and user details including:
  - `token`: JWT authentication token (expires in 8 hours)
  - `user`: User object with id, username, name, company_id, and company_name

## Logout Routes (`/api/auth/logout`)

### User Logout
- **Route**: `POST /api/auth/logout`
- **Activity Name**: User logout
- **Activity ID**: 2
- **Entity ID**: 1 (users)
- **Description**: Handles user logout (stateless JWT implementation - token invalidation handled client-side)
- **Activity Logging**: ✅ Implemented - Logs logout attempts with user ID extracted from JWT token
- **Parameters**: None required (user ID extracted from Authorization header)
- **Response**: Success confirmation message

## Summary of All Activities

1. **User login** (Activity ID: 1) - ✅ Activity logging implemented
2. **User logout** (Activity ID: 2) - ✅ Activity logging implemented

## Activity Logging Implementation Status

✅ **COMPLETED**: Activity logging has been implemented for all auth endpoints
- Login activities are logged after successful authentication
- Logout activities are logged with user ID extracted from JWT token
- Error handling ensures logging failures don't affect authentication flow
- Detailed implementation documentation available in `AUTH_ACTIVITY_LOG_IMPLEMENTATION.md`

---

**Note**: 
- The authentication system uses JWT (JSON Web Tokens) for stateless authentication
- Login endpoint validates user credentials against the database and checks if the user is active
- Logout endpoint extracts user ID from JWT token for activity logging
- All authentication activities are logged for audit and security purposes