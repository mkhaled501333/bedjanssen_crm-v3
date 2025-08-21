# Activity Log System Usage Guide

This guide explains how to use the activity log system in the Janssen CRM backend.

## Overview

The activity log system provides comprehensive tracking of user activities across the application. It consists of:

- **Models**: Entity, Activity, and ActivityLog
- **Service**: ActivityLogService for core functionality
- **API Endpoints**: For retrieving activity logs

## Database Schema

The system uses three main tables:

### entities
- `id` (INTEGER PRIMARY KEY)
- `name` (TEXT UNIQUE) - Entity name (e.g., 'customers', 'tickets')

### activities
- `id` (INTEGER PRIMARY KEY)
- `name` (TEXT UNIQUE) - Activity name (e.g., 'CREATE', 'UPDATE')
- `description` (TEXT) - Human-readable description
- `created_at` (TEXT) - Timestamp

### activity_logs
- `id` (INTEGER PRIMARY KEY)
- `entity_id` (INTEGER) - Foreign key to entities table
- `record_id` (INTEGER) - ID of the affected record
- `activity_id` (INTEGER) - Foreign key to activities table
- `user_id` (INTEGER) - ID of the user who performed the action
- `details` (TEXT) - JSON string with additional details
- `created_at` (TEXT) - Timestamp

## Manual Logging

### Using ActivityLogService

```dart
import 'package:janssencrm_backend/services/activity_log_service.dart';

// Log by entity and activity names (recommended)
await ActivityLogService.logByNames(
  entityName: 'customers',
  recordId: customerId,
  activityName: 'CREATE',
  userId: currentUserId,
  details: {
    'customerName': customer.name,
    'customerEmail': customer.email,
  },
);

// Log an UPDATE activity
await ActivityLogService.logByNames(
  entityName: 'tickets',
  recordId: ticketId,
  activityName: 'UPDATE',
  userId: currentUserId,
  details: {
    'oldValues': {'status': 'open', 'priority': 'low'},
    'newValues': {'status': 'in_progress', 'priority': 'high'},
    'reason': 'Customer escalation',
  },
);

// Log a DELETE activity
await ActivityLogService.logByNames(
  entityName: 'customers',
  recordId: customerId,
  activityName: 'DELETE',
  userId: currentUserId,
  details: {
    'deletedData': customerData,
  },
);

// Log a VIEW activity
await ActivityLogService.logByNames(
  entityName: 'reports',
  recordId: reportId,
  activityName: 'VIEW',
  userId: currentUserId,
  details: {'reportType': 'sales_summary'},
);

// Log LOGIN activity
await ActivityLogService.logByNames(
  entityName: 'users',
  recordId: userId,
  activityName: 'LOGIN',
  userId: userId,
  details: {
    'ipAddress': request.connectionInfo?.remoteAddress.address,
    'userAgent': request.headers.value('user-agent'),
  },
);

// Log EXPORT activity
await ActivityLogService.logByNames(
  entityName: 'customers',
  recordId: 0, // Use 0 for bulk operations
  activityName: 'EXPORT',
  userId: currentUserId,
  details: {
    'exportFormat': 'CSV',
    'recordCount': 150,
    'filters': {'status': 'active'},
  },
);

// Log by entity and activity IDs
await ActivityLogService.log(
  entityId: 1,
  recordId: customerId,
  activityId: 2,
  userId: currentUserId,
  details: {'action': 'updated'},
);
```

## API Endpoints

### Get Activity Logs

```http
GET /api/activity-logs
```

Query parameters:
- `entityId` (optional) - Filter by entity ID
- `recordId` (optional) - Filter by record ID
- `activityId` (optional) - Filter by activity ID
- `userId` (optional) - Filter by user ID
- `fromDate` (optional) - Filter from date (ISO 8601)
- `toDate` (optional) - Filter to date (ISO 8601)
- `limit` (optional) - Number of records to return (default: 50)
- `offset` (optional) - Number of records to skip (default: 0)
- `detailed` (optional) - Include entity and activity names (default: false)

### Get Activity Logs for Specific Entity/Record

```http
GET /api/activity-logs/entity/{entityName}/{recordId}
```

### Get Activity Logs for Specific User

```http
GET /api/activity-logs/user/{userId}
```

### Get All Entities

```http
GET /api/activity-logs/entities
```

### Get All Activities

```http
GET /api/activity-logs/activities
```

## Best Practices

### 1. Use Descriptive Details

```dart
// Good
await ActivityLogService.logByNames(
  entityName: 'tickets',
  recordId: ticketId,
  activityName: 'UPDATE',
  userId: currentUserId,
  details: {
    'oldValues': {'status': 'open', 'assignee': null},
    'newValues': {'status': 'assigned', 'assignee': 'john.doe'},
    'reason': 'Customer escalation',
    'priority_changed': true,
  },
);

// Avoid
await ActivityLogService.logByNames(
  entityName: 'tickets',
  recordId: ticketId,
  activityName: 'UPDATE',
  userId: currentUserId,
);
```

### 2. Handle Errors Gracefully

```dart
try {
  await ActivityLogService.logByNames(
    entityName: 'customers',
    recordId: customerId,
    activityName: 'CREATE',
    userId: currentUserId,
    details: customerData,
  );
} catch (e) {
  // Log the error but don't fail the main operation
  print('Failed to log activity: $e');
}
```

### 3. Log Multiple Activities for Bulk Operations

```dart
// For bulk operations, log each activity individually
for (final customer in customers) {
  try {
    await ActivityLogService.logByNames(
      entityName: 'customers',
      recordId: customer.id,
      activityName: 'CREATE',
      userId: currentUserId,
      details: {'customerName': customer.name},
    );
  } catch (e) {
    print('Failed to log activity for customer ${customer.id}: $e');
  }
}
```

### 4. Consistent Entity Names

Use consistent entity names across your application:
- `customers` (not `customer` or `Customer`)
- `tickets` (not `ticket` or `Ticket`)
- `users` (not `user` or `User`)

### 5. Meaningful Activity Names

Use clear, consistent activity names:
- `CREATE`, `UPDATE`, `DELETE`, `VIEW`
- `LOGIN`, `LOGOUT`
- `EXPORT`, `IMPORT`
- `ASSIGN`, `UNASSIGN`
- `APPROVE`, `REJECT`

## Default Entities and Activities

The system initializes with these default entities and activities:

### Default Entities
- customers
- tickets
- users
- reports
- masterdata

### Default Activities
- CREATE - Record creation
- UPDATE - Record modification
- DELETE - Record deletion
- VIEW - Record viewing
- LOGIN - User login
- LOGOUT - User logout
- EXPORT - Data export
- IMPORT - Data import

## Integration Examples

### In a Customer Creation Endpoint

```dart
// routes/api/customers/index.dart
Router().post('/', (Request request) async {
  try {
    // Create customer logic
    final customer = await createCustomer(customerData);
    
    // Log the activity
    await ActivityLogService.logByNames(
      entityName: 'customers',
      recordId: customer.id,
      activityName: 'CREATE',
      userId: currentUserId,
      details: {
        'customerName': customer.name,
        'customerEmail': customer.email,
        'createdBy': currentUserId,
      },
    );
    
    return Response.json({'success': true, 'customer': customer});
  } catch (e) {
    return Response.json({'error': e.toString()}, status: 500);
  }
});
```

### In a Ticket Update Endpoint

```dart
// routes/api/tickets/[id]/index.dart
Router().put('/', (Request request, String id) async {
  try {
    final ticketId = int.parse(id);
    final oldTicket = await getTicket(ticketId);
    
    // Update ticket logic
    final updatedTicket = await updateTicket(ticketId, updateData);
    
    // Log the activity
    await ActivityLogService.logByNames(
      entityName: 'tickets',
      recordId: ticketId,
      activityName: 'UPDATE',
      userId: currentUserId,
      details: {
        'oldValues': oldTicket.toMap(),
        'newValues': updatedTicket.toMap(),
        'updatedBy': currentUserId,
      },
    );
    
    return Response.json({'success': true, 'ticket': updatedTicket});
  } catch (e) {
    return Response.json({'error': e.toString()}, status: 500);
  }
});
```

## Troubleshooting

### Common Issues

1. **Activity not logged**: Check if the entity/activity exists in the database
2. **Invalid entity/activity names**: Ensure names match exactly with database records
3. **Performance issues**: Consider logging activities asynchronously for non-critical operations
4. **Missing details**: Always provide meaningful details for better audit trails

### Debugging

Enable debug logging to see activity log operations:

```dart
// Add debug prints in your code
print('Logging activity: $activityName for entity: $entityName');
```

## Migration

The activity log tables are automatically created during database migration. The system also initializes default entities and activities.

To add custom entities or activities, use the service methods:

```dart
// Add custom entity
final entityId = await ActivityLogService.ensureEntity('custom_entity');

// Add custom activity
final activityId = await ActivityLogService.ensureActivity(
  'CUSTOM_ACTION',
  'Custom action description',
);
```