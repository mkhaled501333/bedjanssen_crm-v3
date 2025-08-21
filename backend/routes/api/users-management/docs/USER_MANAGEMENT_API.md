# User Management API Documentation

This document provides comprehensive documentation for the User Management API endpoints.

## Overview

The User Management API allows you to:
- Create new users
- View user information
- Update user details
- Delete users
- Manage user permissions
- Search and paginate through users

## Base URL

```
/api/users-management
```

## Authentication

All endpoints require proper authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Endpoints

### 1. Get All Users

**GET** `/api/users-management`

Retrieve a list of all users with pagination support.

#### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `limit` | integer | No | 10 | Number of users to return |
| `offset` | integer | No | 0 | Number of users to skip |
| `search` | string | No | - | Search term for name or username |

#### Response

```json
{
  "users": [
    {
      "id": 1,
      "companyId": 1,
      "name": "John Doe",
      "username": "john.doe",
      "createdBy": 1,
      "isActive": true,
      "permissions": [1, 2, 3],
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "pagination": {
    "total": 50,
    "limit": 10,
    "offset": 0,
    "hasMore": true
  }
}
```

### 2. Create User

**POST** `/api/users-management`

Create a new user.

#### Request Body

```json
{
  "name": "John Doe",
  "username": "john.doe",
  "password": "secure_password",
  "companyId": 1,
  "createdBy": 1,
  "isActive": true,
  "permissions": [1, 2, 3],
}
```

#### Required Fields

- `name`: User's full name
- `username`: Unique username
- `password`: User's password
- `companyId`: Company ID the user belongs to

#### Optional Fields

- `createdBy`: ID of the user creating this user
- `isActive`: Whether the user is active (default: true)
- `permissions`: Array of permission IDs (default: [])

#### Response

```json
{
  "message": "User created successfully",
  "user": {
    "id": 1,
    "companyId": 1,
    "name": "John Doe",
    "username": "john.doe",
    "createdBy": 1,
    "isActive": true,
    "permissions": [1, 2, 3],
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### 3. Get User by ID

**GET** `/api/users-management/{id}`

Retrieve a specific user by their ID.

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | User ID |

#### Response

```json
{
  "user": {
    "id": 1,
    "companyId": 1,
    "name": "John Doe",
    "username": "john.doe",
    "createdBy": 1,
    "isActive": true,
    "permissions": [1, 2, 3],
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

### 4. Update User

**PUT** `/api/users-management/{id}`

Update an existing user's information.

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | User ID |

#### Request Body

```json
{
  "name": "John Smith",
  "username": "john.smith",
  "password": "new_password",
  "companyId": 1,
  "isActive": true,
  "permissions": [1, 2, 3, 4]
}
```

**Note:** All fields are optional. Only provided fields will be updated.

#### Response

```json
{
  "message": "User updated successfully",
  "user": {
    "id": 1,
    "companyId": 1,
    "name": "John Smith",
    "username": "john.smith",
    "createdBy": 1,
    "isActive": true,
    "permissions": [1, 2, 3, 4],
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T12:00:00.000Z"
  }
}
```

### 5. Delete User

**DELETE** `/api/users-management/{id}` - **DISABLED**

⚠️ **This functionality has been disabled for security purposes.**

#### Response

```json
{
  "error": "Delete user functionality has been disabled"
}
```

**Status Code:** 403 Forbidden

### 6. Get User Permissions

**GET** `/api/users-management/{id}/permissions`

Retrieve a user's permissions with detailed information.

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | User ID |

#### Response

```json
{
  "userId": 1,
  "username": "john.doe",
  "name": "John Doe",
  "permissions": [1, 2, 3],
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
    },
    {
      "id": 3,
      "name": "Edit Users",
      "valid": true
    }
  ]
}
```

### 7. Update User Permissions (Replace)

**PUT** `/api/users-management/{id}/permissions`

Replace all user permissions with new ones.

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | User ID |

#### Request Body

```json
{
  "permissions": [1, 2, 3, 4, 5],
  "updatedBy": 1
}
```

#### Response

```json
{
  "message": "User permissions updated successfully",
  "userId": 1,
  "username": "john.doe",
  "permissions": [1, 2, 3, 4, 5],
  "permissionDetails": [
    {
      "id": 1,
      "name": "View Users",
      "valid": true
    }
    // ... more permissions
  ]
}
```

### 8. Add User Permissions

**POST** `/api/users-management/{id}/permissions`

Add new permissions to a user (keeps existing permissions).

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | User ID |

#### Request Body

```json
{
  "permissions": [4, 5],
  "updatedBy": 1
}
```

#### Response

```json
{
  "message": "Permissions added successfully",
  "userId": 1,
  "username": "john.doe",
  "permissions": [1, 2, 3, 4, 5],
  "permissionDetails": [
    // ... permission details
  ],
  "addedPermissions": [4, 5]
}
```

## Permission System

### Available Permissions

| ID | Permission Name | Description |
|----|-----------------|-------------|
| 1 | View Users | Can view user information |
| 2 | Create Users | Can create new users |
| 3 | Edit Users | Can edit user information |
| 4 | Delete Users | Can delete users |
| 5 | Manage User Permissions | Can modify user permissions |
| 10 | View Tickets | Can view tickets |
| 11 | Create Tickets | Can create new tickets |
| 12 | Edit Tickets | Can edit tickets |
| 13 | Delete Tickets | Can delete tickets |
| 14 | Close Tickets | Can close tickets |
| 20 | View Customers | Can view customer information |
| 21 | Create Customers | Can create new customers |
| 22 | Edit Customers | Can edit customer information |
| 23 | Delete Customers | Can delete customers |
| 30 | View Reports | Can view reports |
| 31 | Export Reports | Can export reports |
| 40 | View Master Data | Can view master data |
| 41 | Edit Master Data | Can edit master data |
| 50 | View Activity Logs | Can view activity logs |
| 60 | System Administration | Full system administration access |

## Error Responses

### Common Error Codes

| Status Code | Description |
|-------------|-------------|
| 400 | Bad Request - Invalid input data |
| 401 | Unauthorized - Invalid or missing authentication |
| 404 | Not Found - User not found |
| 409 | Conflict - Username already exists |
| 500 | Internal Server Error - Server error |

### Error Response Format

```json
{
  "error": "Error message describing what went wrong"
}
```

## Activity Logging

All user management operations are automatically logged to the activity log system with the following actions:

- `create`: User creation
- `update`: User information update
- `delete`: User deletion
- `update_permissions`: Permission updates
- `add_permissions`: Permission additions

## Security Notes

1. **Password Security**: Passwords are stored as plain text in the current implementation. Consider implementing proper password hashing.
2. **Permission Validation**: All permission operations validate against the defined permission system.
3. **Activity Logging**: All operations are logged for audit purposes.
4. **CORS**: CORS headers are included for cross-origin requests.

## Examples

See the accompanying HTTP test file (`users-management-api.http`) for practical examples of all API endpoints.