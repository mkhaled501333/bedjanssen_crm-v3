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

## Request Format

```json
{
  "filters": {
    "companyId": 1,
    "customerIds": [1, 2],
    "governomateIds": [1],
    "cityIds": [5, 6],
    "ticketIds": [100, 200],
    "ticketCatIds": [1, 2],
    "ticketStatus": "مفتوح",
    "productIds": [10, 20],
    "requestReasonIds": [5, 6],
    "inspected": true,
    "inspectionDateFrom": "2024-01-01T00:00:00Z",
    "inspectionDateTo": "2024-12-31T23:59:59Z",
    "action": "صيانه",
    "pulledStatus": false,
    "deliveredStatus": true
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
- **ticketCatIds** (List<int>): Filter by ticket category IDs
- **ticketStatus** (string): Filter by ticket status

#### Product & Request Filters
- **productIds** (List<int>): Filter by product IDs
- **requestReasonIds** (List<int>): Filter by request reason IDs

#### Action & Status Filters
- **action** (string): Filter by action type:
  - `استبدال لنفس النوع` (Replacement - Same Type)
  - `استبدال لنوع اخر` (Replacement - Different Type)
  - `صيانه` (Maintenance)
- **inspected** (boolean): Filter by inspection status
- **pulledStatus** (boolean): Filter by pulled status
- **deliveredStatus** (boolean): Filter by delivered status

#### Date Filters
- **inspectionDateFrom** (string): Filter by inspection date from (ISO 8601)
- **inspectionDateTo** (string): Filter by inspection date to (ISO 8601)

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

### Validation Error
```json
{
  "success": false,
  "error": "companyId is required"
}
```

### Server Error
```json
{
  "success": false,
  "error": "Internal server error: Database connection failed"
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
      "action": "صيانه",
      "inspected": true
    },
    "page": 1,
    "limit": 100
  }'
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

## Best Practices

### Frontend Implementation
1. **Debounce Filter Changes**: Wait 300-500ms before sending API requests
2. **Progressive Loading**: Load essential filters first, then secondary options
3. **Filter State Management**: Maintain filter state and sync with backend
4. **Error Handling**: Provide fallback options when filters fail

### Backend Optimization
1. **Query Optimization**: Use prepared statements and parameterized queries
2. **Index Strategy**: Create composite indexes for common filter combinations
3. **Connection Pooling**: Use database connection pooling for concurrent requests
4. **Response Compression**: Compress large responses for better performance

## Migration Notes

This endpoint requires:

1. **Database View**: `ticket_items_report` view with proper joins
2. **Service Layer**: `TicketItemsReportService` implementation
3. **Database Indexes**: Performance optimization indexes
4. **CORS Configuration**: Proper CORS headers for cross-origin requests

## Support

For issues with the Ticket Items Report API:

1. Check database view structure and joins
2. Verify database indexes are properly created
3. Monitor API performance and response times
4. Review filter combinations and dependencies
5. Check database connection and query performance
