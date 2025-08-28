# Ticket Items Report Endpoint

## Overview

This directory contains the implementation of the **Ticket Items Report API** endpoint, which provides comprehensive reporting capabilities for ticket items with dynamic filtering.

**Endpoint**: `POST /api/reports/ticket-items`

## Files

- **`index.dart`** - Main endpoint implementation with request handling and CORS support
- **`ticket-items-api.http`** - HTTP test file with examples and usage patterns
- **`TICKET_ITEMS_REPORT_API.md`** - Complete API documentation and specifications
- **`README.md`** - This file explaining the endpoint structure

## Key Features

### Dynamic Filtering
- Available filter options automatically update based on currently applied filters
- Prevents users from selecting filter combinations that would return empty results
- Real-time filter dependency management

### Comprehensive Response
- **Available Filters**: Dynamic filter options based on current state
- **Applied Filters**: Currently active filter values
- **Filter Summary**: Summary of active filters and counts
- **Report Data**: Paginated ticket items with full details
- **Pagination**: Built-in pagination with metadata

### Filter Types Supported
- **Geographic**: Governorate, City
- **Ticket**: Categories, Status
- **Product & Request**: Product IDs, Request Reason IDs
- **Action & Status**: Action type, Inspection status, Pulled/Delivered status
- **Date Range**: Inspection date filtering

## Implementation Details

### Service Layer
The endpoint uses `TicketItemsReportService` located at:
```
backend/lib/services/reports/ticket_items_report_service.dart
```

### Database Requirements
- Requires `ticket_items_report` database view
- Optimized with composite indexes for performance
- Supports complex JOIN operations across multiple tables

### Response Format
```json
{
  "success": true,
  "data": {
    "available_filters": { ... },
    "applied_filters": { ... },
    "filter_summary": { ... },
    "report_data": {
      "ticket_items": [ ... ],
      "pagination": { ... }
    }
  }
}
```

## Usage Examples

### Basic Report
```bash
curl -X POST http://localhost:8080/api/reports/ticket-items \
  -H "Content-Type: application/json" \
  -d '{
    "filters": {"companyId": 1},
    "page": 1,
    "limit": 50
  }'
```

### Filtered Report
```bash
curl -X POST http://localhost:8080/api/reports/ticket-items \
  -H "Content-Type: application/json" \
  -d '{
    "filters": {
      "companyId": 1,
      "governomateIds": [1, 2],
      "action": "صيانه"
    },
    "page": 1,
    "limit": 100
  }'
```

## Dependencies

- **Database Service**: `DatabaseService` for query execution
- **Dart Frog**: Web framework for HTTP handling
- **CORS Support**: Built-in CORS headers for cross-origin requests

## Performance Considerations

- **Indexing**: Requires specific database indexes for optimal performance
- **Caching**: Recommended to implement caching for filter options
- **Pagination**: Built-in pagination prevents large result sets
- **Query Optimization**: Uses parameterized queries and prepared statements

## Error Handling

- **Validation**: Required field validation (companyId)
- **Database Errors**: Graceful handling of database connection issues
- **CORS Support**: Proper CORS headers for all response types
- **HTTP Status Codes**: Appropriate status codes for different error types

## Testing

Use the `ticket-items-api.http` file to test the endpoint with various filter combinations and verify the dynamic filtering behavior.

## Related Documentation

- **Main Documentation**: `TICKET_ITEMS_REPORT_USAGE.md` in the docs folder
- **API Reference**: `TICKET_ITEMS_REPORT_API.md` in this directory
- **Reports Overview**: `REPORTS_ACTIVITIES.md` in the parent directory
