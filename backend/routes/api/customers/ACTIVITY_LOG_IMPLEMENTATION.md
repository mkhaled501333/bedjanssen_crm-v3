# Customer Activity Log Implementation

This document describes the activity logging implementation for the customer management system in the CRM backend.

## Overview

Activity logging has been implemented across all customer-related operations to track user actions and maintain an audit trail. The system automatically logs activities when users perform operations on customer data.

## Implemented Activity Logging

### Customer Management Activities

#### Customer Information Updates
- **Activity ID 112**: Update customer name
- **Activity ID 113**: Update customer address
- **Activity ID 114**: Update customer notes
- **Activity ID 115**: Update customer governorate
- **Activity ID 116**: Update customer city

**Route**: `PUT /api/customers/id/{id}`
**Implementation**: Logs specific activities only for fields that are actually updated

#### Customer Phone Management
- **Activity ID 103**: Add customer phone
- **Activity ID 104**: Update customer phone
- **Activity ID 105**: Delete customer phone

**Routes**:
- `POST /api/customers/id/{id}/phones` - Logs phone creation
- `PUT /api/customers/id/{id}/phones/{phoneId}` - Logs phone updates
- `DELETE /api/customers/id/{id}/phones/{phoneId}` - Logs phone deletion

#### Customer Call Management
- **Activity ID 107**: Create customer call

**Route**: `POST /api/customers/id/{id}/calls` - Logs call creation

#### Customer Ticket Management
- **Activity ID 109**: Create customer ticket

**Route**: `POST /api/customers/id/{id}/tickets` - Logs ticket creation

### Activity Log Retrieval

#### Get Customer Activity Logs
**Route**: `GET /api/customers/id/{id}/activity-logs`

**Query Parameters**:
- `limit` (optional): Number of records to return (default: 50)
- `offset` (optional): Number of records to skip (default: 0)
- `fromDate` (optional): Start date filter (YYYY-MM-DD format)
- `toDate` (optional): End date filter (YYYY-MM-DD format)

**Response**: Returns detailed activity logs including:
- Activity timestamp
- Activity name and description
- Username of the user who performed the action
- Entity and record information

## Technical Implementation

### User Authentication
The system extracts the user ID from the JWT payload in the request context:

```dart
// Extract user ID from JWT payload
int userId = 1; // Default fallback
try {
  final jwtPayload = context.read<Map<String, dynamic>>();
  userId = jwtPayload['id'] as int? ?? 1;
} catch (e) {
  print('Failed to extract user ID from JWT payload: $e');
}
```

### Activity Logging
Activities are logged using the `ActivityLogService`:

```dart
// Log activity
try {
  await ActivityLogService.log(
    entityId: 2, // customers entity
    recordId: customerId,
    activityId: activityId,
    userId: userId,
  );
} catch (e) {
  print('Failed to log activity: $e');
}
```

### Error Handling
- All activity logging operations are wrapped in try-catch blocks
- Logging failures do not affect the main operation
- Errors are logged to the console for debugging

## Database Schema

The activity logging system uses the following tables:

- **entities**: Defines entity types (customers = entity_id 2)
- **activities**: Defines activity types with descriptions
- **activity_logs**: Stores individual activity log entries

## Usage Examples

### Update Customer Information
```http
PUT /api/customers/id/123
Content-Type: application/json
Authorization: Bearer <jwt_token>

{
  "name": "Updated Customer Name",
  "address": "New Address"
}
```
This will log two specific activities: "Update customer name" (ID: 112) and "Update customer address" (ID: 113) for each field that was actually updated

### Add Customer Phone
```http
POST /api/customers/id/123/phones
Content-Type: application/json
Authorization: Bearer <jwt_token>

{
  "phone": "+1234567890",
  "phone_type": 1,
  "company_id": 1
}
```
This will log one activity: "Add customer phone"

### Retrieve Activity Logs
```http
GET /api/customers/id/123/activity-logs?limit=20&offset=0&fromDate=2024-01-01
Authorization: Bearer <jwt_token>
```
This will return the last 20 activity logs for customer 123 from January 1, 2024

## Benefits

1. **Audit Trail**: Complete tracking of all customer-related operations
2. **User Accountability**: Each action is tied to a specific user
3. **Compliance**: Helps meet regulatory requirements for data tracking
4. **Debugging**: Assists in troubleshooting data changes
5. **Analytics**: Provides insights into user behavior and system usage

## Future Enhancements

- Add activity logging for customer deletion (when implemented)
- Implement activity logging for bulk operations
- Add more granular logging for complex operations
- Implement activity log retention policies
- Add activity log export functionality