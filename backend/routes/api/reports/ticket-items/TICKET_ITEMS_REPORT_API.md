# Ticket Items Report API

## Overview

The Ticket Items Report API provides comprehensive reporting capabilities for ticket items with **dynamic filtering**. This endpoint returns everything in a single response: available filters, applied filters, filter summary, and paginated report data.

**Route**: `POST /api/reports/ticket-items`

## Key Features

- **Dynamic Filtering**: Available filter options automatically update based on currently applied filters
- **Single Response**: Everything returned in one API call for optimal performance
- **Comprehensive Data**: Includes customer, ticket, product, and geographic information
- **Pagination Support**: Built-in pagination with configurable page size
- **Real-time Updates**: Filter options update in real-time as filters are applied
- **CORS Support**: Full CORS support with OPTIONS method handling

## Request Format

```json
{
  "filters": {
    "companyId": 1,
    "customerIds": [1, 2],
    "governomateIds": [1],
    "cityIds": [5, 6],
    "ticketIds": [100, 200],
    "companyIds": [1, 2],
    "ticketCatIds": [1, 2],
    "ticketStatus": "مفتوح",
    "productIds": [10, 20],
    "requestReasonIds": [5, 6],
    "inspected": true,
    "inspectionDateFrom": "2024-01-01T00:00:00Z",
    "inspectionDateTo": "2024-12-31T23:59:59Z",
    "ticketCreatedDateFrom": "2024-01-01T00:00:00Z",
    "ticketCreatedDateTo": "2024-12-31T23:59:59Z",
    "actions": ["صيانه"],
    "pulledStatus": false,
    "deliveredStatus": true,
    "clientApproval": true
  },
  "page": 1,
  "limit": 50
}
```

## Filter Parameters

### Required Filters
- **companyId** (int): Company identifier - always required

### Optional Filters

#### Geographic Filters
- **governomateIds** (List<int>): Filter by governorate IDs
- **cityIds** (List<int>): Filter by city IDs

#### Customer & Ticket Filters
- **customerIds** (List<int>): Filter by customer IDs
- **ticketIds** (List<int>): Filter by ticket IDs
- **companyIds** (List<int>): Filter by additional company IDs (secondary companies)
- **ticketCatIds** (List<int>): Filter by ticket category IDs
- **ticketStatus** (string): Filter by ticket status

#### Product & Request Filters
- **productIds** (List<int>): Filter by product IDs
- **requestReasonIds** (List<int>): Filter by request reason IDs

#### Action & Status Filters
- **actions** (List<string>): Filter by action types (can select multiple):
  - `استبدال لنفس النوع` (Replacement - Same Type)
  - `استبدال لنوع اخر` (Replacement - Different Type)
  - `صيانه` (Maintenance)
- **inspected** (boolean): Filter by inspection status
- **pulledStatus** (boolean): Filter by pulled status
- **deliveredStatus** (boolean): Filter by delivered status
- **clientApproval** (boolean): Filter by client approval status

#### Date Filters
- **inspectionDateFrom** (string): Filter by inspection date from (ISO 8601)
- **inspectionDateTo** (string): Filter by inspection date to (ISO 8601)
- **ticketCreatedDateFrom** (string): Filter by ticket creation date from (ISO 8601)
- **ticketCreatedDateTo** (string): Filter by ticket creation date to (ISO 8601)

#### Pagination
- **page** (int): Page number (default: 1)
- **limit** (int): Records per page (default: 50)

## Response Structure

```json
{
  "success": true,
  "data": {
    "available_filters": {
      "governorates": [{"id": 1, "name": "Governorate X"}],
      "cities": [{"id": 5, "name": "City E"}],
      "customers": [{"id": 1, "name": "Customer A"}],
      "tickets": [{"id": 100, "name": "Ticket 100"}],
      "ticket_categories": [{"id": 1, "name": "Category A"}],
      "ticket_statuses": [{"id": "مفتوح", "name": "مفتوح"}],
      "products": [{"id": 10, "name": "Product X"}],
      "request_reasons": [{"id": 5, "name": "Maintenance Required"}],
      "actions": [{"id": "صيانه", "name": "صيانه"}]
    },
    "applied_filters": {
      "companyId": 1,
      "governomateIds": [1],
      "cityIds": [5]
    },
    "filter_summary": {
      "total_applied_filters": 2,
      "active_filters": ["governomateIds", "cityIds"]
    },
    "report_data": {
      "ticket_items": [
        {
          "ticket_item_id": 1,
          "customer_id": 1,
          "customer_name": "Customer A",
          "governomate_id": 1,
          "governorate_name": "Governorate X",
          "city_id": 5,
          "city_name": "City E",
          "ticket_id": 100,
          "company_id": 1,
          "ticket_cat_id": 1,
          "ticket_category_name": "Category A",
          "ticket_status": "مفتوح",
          "product_id": 10,
          "product_name": "Product X",
          "product_size": "Large",
          "request_reason_id": 5,
          "request_reason_name": "Maintenance Required",
          "inspected": true,
          "inspection_date": "2024-01-15T10:00:00Z",
          "client_approval": true,
          "ticket_created_at": "2024-01-10T08:30:00Z",
          "action": "صيانه",
          "pulled_status": false,
          "delivered_status": true
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 50,
        "total": 150,
        "total_pages": 3,
        "has_next": true,
        "has_previous": false
      }
    }
  }
}

## Response Fields

The API returns comprehensive ticket item data including:

### Core Ticket Item Fields
- **ticket_item_id**: Unique identifier for the ticket item
- **product_id**: Product identifier
- **product_name**: Name of the product
- **product_size**: Size specification of the product
- **request_reason_id**: Reason for the request
- **request_reason_name**: Description of the request reason
- **inspected**: Whether the item was inspected
- **inspection_date**: Date of inspection (ISO 8601 format)
- **client_approval**: Client approval status

### Ticket Information
- **ticket_id**: Unique identifier for the ticket
- **ticket_status**: Current status of the ticket
- **ticket_category_name**: Category of the ticket
- **ticket_created_at**: Date when the ticket was created (ISO 8601 format)

### Customer & Location Information
- **customer_id**: Customer identifier
- **customer_name**: Name of the customer
- **governomate_id**: Governorate identifier
- **governorate_name**: Name of the governorate
- **city_id**: City identifier
- **city_name**: Name of the city

### Action & Status Fields
- **action**: Type of action performed ('استبدال لنفس النوع', 'استبدال لنوع اخر', 'صيانه')
- **pulled_status**: Whether the item was pulled
- **delivered_status**: Whether the item was delivered
```

## Dynamic Filtering Examples

### Example 1: Geographic Filtering

**Initial Request (Company only):**
```json
{
  "filters": {"companyId": 1},
  "page": 1,
  "limit": 50
}
```

**Response includes all available options:**
- All governorates in company
- All cities in company
- All customers in company
- All products in company

**After applying Governorate filter:**
```json
{
  "filters": {
    "companyId": 1,
    "governomateIds": [1]
  },
  "page": 1,
  "limit": 50
}
```

**Available filters now show only:**
- Cities in governorate 1
- Customers in governorate 1
- Products available in governorate 1

### Example 2: Action-Based Filtering

**Request with Action filter:**
```json
{
  "filters": {
    "companyId": 1,
    "action": "صيانه"
  },
  "page": 1,
  "limit": 50
}
```

**Available filters show only:**
- Products that have maintenance actions
- Request reasons related to maintenance
- Customers with maintenance tickets

## Error Responses

### Validation Error (400)
```json
{
  "success": false,
  "error": "companyId is required"
}
```

### Server Error (500)
```json
{
  "success": false,
  "error": "Internal server error: Database connection failed"
}
```

### Method Not Allowed (405)
```
Method not allowed
```

## HTTP Methods

- **POST**: Get ticket items report with dynamic filtering
- **OPTIONS**: CORS preflight request (returns 200 with CORS headers)

## CORS Headers

The API includes proper CORS headers for cross-origin requests:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: POST, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type, Authorization`

## Usage Examples

### Basic Report
```bash
curl -X POST http://localhost:8081/api/reports/ticket-items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "filters": {"companyId": 1},
    "page": 1,
    "limit": 50
  }'
```

### Filtered Report
```bash
curl -X POST http://localhost:8081/api/reports/ticket-items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "filters": {
      "companyId": 1,
      "governomateIds": [1, 2],
      "action": "صيانه",
      "inspected": true
    },
    "page": 1,
    "limit": 100
  }'
```

### Report with Ticket Creation Date Range
```bash
curl -X POST http://localhost:8081/api/reports/ticket-items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "filters": {
      "companyId": 1,
      "ticketCreatedDateFrom": "2024-01-01T00:00:00Z",
      "ticketCreatedDateTo": "2024-03-31T23:59:59Z",
      "ticketStatus": "مفتوح"
    },
    "page": 1,
    "limit": 50
  }'
```

### CORS Preflight
```bash
curl -X OPTIONS http://localhost:8081/api/reports/ticket-items \
  -H "Origin: http://localhost:3000"
```

## Performance Considerations

### Database Indexes
The following indexes are recommended for optimal performance:

```sql
-- Composite indexes for common filter combinations
CREATE INDEX idx_ticket_items_company_location ON ticket_items(company_id, governomate_id, city_id);
CREATE INDEX idx_ticket_items_company_action ON ticket_items(company_id, action);
CREATE INDEX idx_ticket_items_company_product ON ticket_items(company_id, product_id);

-- Covering indexes for filter queries
CREATE INDEX idx_ticket_items_filter_covering ON ticket_items(
  company_id, governomate_id, city_id, action, product_id, 
  customer_id, ticket_id, inspected, pulled_status, delivered_status
);
```

### Caching Strategy
- Cache filter options for common company/filter combinations
- Implement Redis caching for frequently accessed filter data
- Use database query result caching for complex filter combinations

## Implementation Details

### Service Layer
The API uses `TicketItemsReportService.getTicketItemsReport()` method which:
- Validates required parameters
- Builds dynamic WHERE clauses based on applied filters
- Fetches available filter options from the filtered dataset
- Provides comprehensive error handling and fallbacks
- Converts DateTime fields to ISO 8601 strings for JSON serialization

### Database View
The API relies on a `ticket_items_report` database view that joins:
- `ticket_items` - Core ticket item data
- `tickets` - Ticket information
- `customers` - Customer details
- `governorates` - Geographic data
- `cities` - City information
- `product_info` - Product details
- `request_reasons` - Request reason data
- Action-specific tables (maintenance, change same, change another)

### Error Handling
- Graceful fallbacks when database views are empty
- Comprehensive error logging for debugging
- Safe type casting for filter parameters
- JSON serialization error handling

## Best Practices

### Frontend Implementation
1. **Debounce Filter Changes**: Wait 300-500ms before sending API requests
2. **Progressive Loading**: Load essential filters first, then secondary options
3. **Filter State Management**: Maintain filter state and sync with backend
4. **Error Handling**: Provide fallback options when filters fail
5. **CORS Handling**: Handle preflight requests properly

### Backend Optimization
1. **Query Optimization**: Use prepared statements and parameterized queries
2. **Index Strategy**: Create composite indexes for common filter combinations
3. **Connection Pooling**: Use database connection pooling for concurrent requests
4. **Response Compression**: Compress large responses for better performance
5. **Error Logging**: Comprehensive logging for debugging and monitoring

## Migration Notes

This endpoint requires:

1. **Database View**: `ticket_items_report` view with proper joins
2. **Service Layer**: `TicketItemsReportService` implementation
3. **Database Indexes**: Performance optimization indexes
4. **CORS Configuration**: Proper CORS headers for cross-origin requests
5. **Authentication**: Bearer token authentication required

## Support

For issues with the Ticket Items Report API:

1. Check database view structure and joins
2. Verify database indexes are properly created
3. Monitor API performance and response times
4. Review filter combinations and dependencies
5. Check database connection and query performance
6. Verify CORS configuration for frontend integration
7. Check authentication token validity

## Testing

Use the provided `ticket-items-api.http` file for comprehensive API testing:
- Basic functionality tests
- Filter combination tests
- Pagination tests
- Error handling tests
- CORS and authentication tests
