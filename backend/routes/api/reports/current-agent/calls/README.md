# Current Agent Reports API

This API endpoint provides reports for calls created by a specific user (agent) within a date range.

## Endpoint

@baseUrl = http://localhost:8081

`GET /api/reports/currentagent`

## Query Parameters

- `userId` (required): The ID of the user/agent to get calls for
- `startDate` (required): Start date in YYYY-MM-DD format
- `endDate` (required): End date in YYYY-MM-DD format

## Example Request

```
GET /api/reports/currentagent?userId=123&startDate=2024-01-01&endDate=2025-08-31
```

## Response Format

```json
{
  "success": true,
  "data": {
    "userId": 123,
    "startDate": "2024-01-01",
    "endDate": "2025-08-31",
    "totalCalls": 25,
    "customerCalls": 15,
    "ticketCalls": 10,
    "calls": [
      {
        "id": 1,
        "type": "customer_call",
        "companyId": 1,
        "customerId": 456,
        "customerName": "John Doe",
        "customerPhone": "+1234567890",
        "callType": "incoming",
        "categoryId": 1,
        "category": "General Inquiry",
        "description": "Customer called about product information",
        "callNotes": "Customer was interested in pricing",
        "callDuration": 300,
        "createdBy": "Agent Name",
        "createdAt": "2024-01-15T10:30:00Z",
        "updatedAt": "2024-01-15T10:30:00Z"
      },
      {
        "id": 2,
        "type": "ticket_call",
        "companyId": 1,
        "ticketId": 789,
        "ticketNumber": "TKT-2024-001",
        "ticketTitle": "Technical Support Request",
        "customerName": "Jane Smith",
        "customerPhone": "+0987654321",
        "callType": "outgoing",
        "callCatId": 2,
        "category": "Technical Support",
        "description": "Follow-up call about technical issue",
        "callNotes": "Issue resolved successfully",
        "callDuration": 450,
        "createdBy": "Agent Name",
        "createdAt": "2024-01-16T14:20:00Z",
        "updatedAt": "2024-01-16T14:20:00Z"
      }
    ]
  },
  "message": "Agent calls report retrieved successfully"
}
```

## Error Responses

### Missing Parameters (400)
```json
{
  "success": false,
  "message": "Missing required parameters: userId, startDate, endDate",
  "error": "All query parameters are required"
}
```

### Invalid User ID (400)
```json
{
  "success": false,
  "message": "Invalid userId format",
  "error": "userId must be a valid integer"
}
```

### Invalid Date Format (400)
```json
{
  "success": false,
  "message": "Invalid date format",
  "error": "Dates must be in YYYY-MM-DD format"
}
```

### User Not Found (404)
```json
{
  "success": false,
  "message": "User not found",
  "error": "No user found with the provided ID"
}
```

### Server Error (500)
```json
{
  "success": false,
  "message": "Internal server error occurred while retrieving report",
  "error": "Error details"
}
```

## Call Types

The API returns two types of calls:

1. **customer_call**: Calls made directly to customers
2. **ticket_call**: Calls made in relation to support tickets

## Data Sources

- Customer calls are retrieved from the `customercall` table
- Ticket calls are retrieved from the `ticketcall` table
- Both are joined with related tables to provide complete information

## Sorting

Results are sorted by creation date in ascending order (oldest first). 