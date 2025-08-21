# Tickets Report API

This API provides comprehensive reporting functionality for tickets with support for pagination, filtering, data aggregation, and export capabilities.

## Endpoints

### Main Report Endpoint
```
GET /api/reports/tickets
```

### Export Endpoint
```
GET /api/reports/tickets/export
```

## Authentication

All endpoints require JWT authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

**Note**: Requests without valid authentication will return a 401 Unauthorized response.

## Query Parameters

### Required Parameters

- `companyId` (integer): The company ID to filter tickets for

### Pagination Parameters

- `page` (integer, default: 1): Page number (minimum: 1)
- `limit` (integer, default: 10): Number of items per page (minimum: 1, maximum: 100)

### Filter Parameters

- `status` (string, optional): Filter by ticket status
  - Valid values: `open`, `in_progress`, `closed`
- `priority` (string, optional): Filter by ticket priority
  - Valid values: `low`, `medium`, `high`
- `categoryId` (integer, optional): Filter by ticket category ID
- `customerId` (integer, optional): Filter by customer ID
- `startDate` (string, optional): Start date for date range filter (YYYY-MM-DD format)
- `endDate` (string, optional): End date for date range filter (YYYY-MM-DD format)
  - Note: Both `startDate` and `endDate` must be provided together
- `searchTerm` (string, optional): Search term to filter tickets by description, customer name, or category name (max 255 characters)

## Example Requests

### Basic Request
```
GET /api/reports/tickets?companyId=1
```

### With Pagination
```
GET /api/reports/tickets?companyId=1&page=2&limit=20
```

### With Filters
```
GET /api/reports/tickets?companyId=1&status=open&priority=high&categoryId=5
```

### With Date Range
```
GET /api/reports/tickets?companyId=1&startDate=2024-01-01&endDate=2024-01-31
```

### With Search
```
GET /api/reports/tickets?companyId=1&searchTerm=product%20issue
```

### Combined Filters
```
GET /api/reports/tickets?companyId=1&status=open&priority=high&startDate=2024-01-01&endDate=2024-01-31&searchTerm=urgent&page=1&limit=25
```

## Export Functionality

The export endpoint allows you to download tickets data in various formats.

### Export Query Parameters

All the same query parameters as the main endpoint are supported, plus:

- `format` (string, required): Export format
  - Valid values: `csv`, `excel`, `pdf`

### Export Examples

#### CSV Export
```
GET /api/reports/tickets/export?companyId=1&format=csv
```

#### Excel Export with Filters
```
GET /api/reports/tickets/export?companyId=1&format=excel&status=open&priority=high
```

#### PDF Export with Date Range
```
GET /api/reports/tickets/export?companyId=1&format=pdf&startDate=2024-01-01&endDate=2024-01-31
```

### Export Response

Export endpoints return file downloads with appropriate headers:

- **CSV**: `Content-Type: text/csv; charset=utf-8`
- **Excel**: `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- **PDF**: `Content-Type: application/pdf`

All exports include `Content-Disposition: attachment` header with appropriate filename.

## Response Format

### Success Response (200 OK)

```json
{
  "success": true,
  "data": {
    "tickets": [
      {
        "id": 123,
        "companyId": 1,
        "customerId": 456,
        "customerName": "John Doe",
        "governorateName": "Baghdad",
        "cityName": "Al-Karkh",
        "ticketCatId": 5,
        "categoryName": "Technical Support",
        "description": "Product not working properly",
        "status": "open",
        "priority": "high",
        "createdBy": 789,
        "createdByName": "Agent Smith",
        "createdAt": "2024-01-15T10:30:00.000Z",
        "updatedAt": "2024-01-15T10:30:00.000Z",
        "closedAt": null,
        "closingNotes": null,
        "callsCount": 2,
        "itemsCount": 1,
        "items": [
          {
            "id": 1,
            "productId": 10,
            "productName": "Product A",
            "productSize": "Large",
            "quantity": 2,
            "purchaseDate": "2024-01-10",
            "purchaseLocation": "Store XYZ",
            "requestReasonId": 3,
            "requestReasonName": "Defective",
            "requestReasonDetail": "Product stopped working after 2 days",
            "inspected": true,
            "inspectionDate": "2024-01-12",
            "inspectionResult": "Confirmed defective",
            "clientApproval": true,
            "createdAt": "2024-01-15T10:30:00.000Z",
            "updatedAt": "2024-01-15T10:30:00.000Z"
          }
        ]
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 47,
      "itemsPerPage": 10,
      "hasNextPage": true,
      "hasPreviousPage": false
    },
    "summary": {
      "statusCounts": {
        "open": 25,
        "in_progress": 15,
        "closed": 7
      },
      "priorityCounts": {
        "low": 10,
        "medium": 20,
        "high": 17
      }
    },
    "filters": {
      "companyId": 1,
      "status": "open",
      "priority": "high",
      "categoryId": null,
      "customerId": null,
      "startDate": "2024-01-01",
      "endDate": "2024-01-31",
      "searchTerm": "urgent"
    }
  },
  "message": "Tickets report retrieved successfully"
}
```

### Error Response (400 Bad Request)

```json
{
  "success": false,
  "message": "companyId is required",
  "error": "Validation failed"
}
```

### Error Response (401 Unauthorized)

```json
{
  "success": false,
  "message": "Unauthorized access",
  "error": "Invalid or missing JWT token"
}
```

### Error Response (500 Internal Server Error)

```json
{
  "success": false,
  "message": "Internal server error occurred while retrieving tickets report",
  "error": "Database connection failed"
}
```

## Common Error Scenarios

### Validation Errors (400 Bad Request)

- Missing `companyId`: "companyId is required"
- Invalid `companyId`: "companyId must be a valid positive integer"
- Invalid `page`: "page must be a positive integer (minimum 1)"
- Invalid `limit`: "limit must be a positive integer between 1 and 100"
- Invalid `status`: "status must be one of: open, in_progress, closed"
- Invalid `priority`: "priority must be one of: low, medium, high"
- Invalid date format: "Dates must be in YYYY-MM-DD format"
- Incomplete date range: "Both startDate and endDate must be provided when filtering by date"
- Invalid date range: "startDate must be before or equal to endDate"
- Search term too long: "searchTerm must not exceed 255 characters"
- Invalid export format: "Invalid or missing format parameter. Supported formats: csv, excel, pdf"

### Authentication Errors (401 Unauthorized)

- Missing token: "Authorization header is required"
- Invalid token: "Invalid JWT token"
- Expired token: "JWT token has expired"

## Data Fields

### Ticket Object

- `id`: Unique ticket identifier
- `companyId`: Company ID the ticket belongs to
- `customerId`: Customer ID associated with the ticket
- `customerName`: Name of the customer
- `governorateName`: Name of the customer's governorate
- `cityName`: Name of the customer's city
- `ticketCatId`: Ticket category ID
- `categoryName`: Name of the ticket category
- `description`: Ticket description
- `status`: Current ticket status (`open`, `in_progress`, `closed`)
- `priority`: Ticket priority (`low`, `medium`, `high`)
- `createdBy`: ID of the user who created the ticket
- `createdByName`: Name of the user who created the ticket
- `createdAt`: Ticket creation timestamp (ISO 8601 format)
- `updatedAt`: Last update timestamp (ISO 8601 format)
- `closedAt`: Ticket closure timestamp (ISO 8601 format, null if not closed)
- `closingNotes`: Notes added when closing the ticket
- `callsCount`: Number of calls associated with the ticket
- `itemsCount`: Number of items associated with the ticket
- `items`: Array of detailed ticket items (see Ticket Item Object below)

### Ticket Item Object

- `id`: Unique ticket item identifier
- `productId`: Product ID associated with the item
- `productName`: Name of the product
- `productSize`: Size specification of the product
- `quantity`: Quantity of the product
- `purchaseDate`: Date when the product was purchased (YYYY-MM-DD format)
- `purchaseLocation`: Location where the product was purchased
- `requestReasonId`: ID of the request reason
- `requestReasonName`: Name of the request reason
- `requestReasonDetail`: Detailed description of the request reason
- `inspected`: Boolean indicating if the item has been inspected
- `inspectionDate`: Date of inspection (YYYY-MM-DD format, null if not inspected)
- `inspectionResult`: Result of the inspection
- `clientApproval`: Boolean indicating client approval status
- `createdAt`: Item creation timestamp (ISO 8601 format)
- `updatedAt`: Last update timestamp (ISO 8601 format)

### Pagination Object

- `currentPage`: Current page number
- `totalPages`: Total number of pages
- `totalItems`: Total number of items matching the criteria
- `itemsPerPage`: Number of items per page
- `hasNextPage`: Boolean indicating if there's a next page
- `hasPreviousPage`: Boolean indicating if there's a previous page

### Summary Object

- `statusCounts`: Object with counts for each status
- `priorityCounts`: Object with counts for each priority

## Project Structure

```
backend/routes/api/reports/tickets/
├── index.dart                    # Main API endpoint
├── export/
│   └── index.dart               # Export functionality endpoint
├── tickets-api.http             # API testing file
└── README.md                    # This documentation

backend/lib/services/reports/
├── tickets_report_service.dart   # Business logic service
└── tickets_utils/
    ├── validation_utils.dart     # Parameter validation
    ├── response_utils.dart       # Response formatting
    └── data_transformer.dart     # Data transformation
```

## Technical Implementation

### Database Schema

The API queries the following main tables:
- `tickets` - Main ticket information
- `customers` - Customer details
- `ticket_categories` - Ticket categories
- `users` - User information for created_by fields
- `ticket_items` - Detailed ticket items
- `products` - Product information
- `request_reasons` - Request reason details
- `governorates` - Governorate information
- `cities` - City information

### Data Transformation

- **Status Mapping**: Database integers (0=open, 1=in_progress, 2=closed) are converted to readable strings
- **Priority Mapping**: Database integers (0=low, 1=medium, 2=high) are converted to readable strings
- **BLOB Handling**: Database BLOB fields are safely converted to strings
- **Date Formatting**: All timestamps are returned in ISO 8601 format

### Query Optimization

- Uses parameterized queries to prevent SQL injection
- Implements efficient pagination with LIMIT and OFFSET
- Includes proper JOIN operations for related data
- Aggregates call and item counts using subqueries
- Supports complex filtering with dynamic WHERE clauses

## Error Handling

The API includes comprehensive error handling for:

- Invalid or missing parameters
- Database connection issues
- Data transformation errors
- Unexpected server errors

All errors are returned with appropriate HTTP status codes and descriptive error messages.

## Performance Considerations

- Pagination is implemented to handle large datasets efficiently
- Database queries are optimized with proper indexing considerations
- Response data is transformed consistently for optimal client consumption
- CORS headers are included for cross-origin requests

## Security

- All database queries use parameterized statements to prevent SQL injection
- Input validation is performed on all parameters
- JWT authentication is required for all endpoints
- CORS headers are configured appropriately
- Sensitive data is properly handled and not exposed in error messages

## Testing

A comprehensive test suite is available in `tickets-api.http` which includes:

### Functional Tests
- Basic tickets report requests
- Pagination testing
- All filter combinations (status, priority, category, customer, date range, search)
- Export functionality in all formats

### Error Handling Tests
- Missing required parameters
- Invalid parameter values
- Authentication failures
- Edge cases (invalid dates, limits, etc.)

### Performance Tests
- Large dataset pagination
- Complex filter combinations
- Export with large datasets

## API Usage Guidelines

### Best Practices

1. **Pagination**: Always use reasonable page sizes (10-50 items) for better performance
2. **Filtering**: Use specific filters to reduce dataset size and improve response times
3. **Date Ranges**: When filtering by date, use specific ranges rather than open-ended queries
4. **Search Terms**: Keep search terms concise and specific for better results
5. **Export**: For large exports, consider using filters to limit the dataset

### Rate Limiting

- No explicit rate limiting is implemented, but consider implementing it for production use
- Large export requests may take longer to process

### Caching Considerations

- Results are not cached by default
- Consider implementing caching for frequently accessed reports
- Export files are generated on-demand and not stored

## Changelog

### Version 1.0
- Initial implementation with basic reporting functionality
- Support for pagination, filtering, and data aggregation
- Export functionality in CSV, Excel, and PDF formats
- Comprehensive error handling and validation
- JWT authentication integration