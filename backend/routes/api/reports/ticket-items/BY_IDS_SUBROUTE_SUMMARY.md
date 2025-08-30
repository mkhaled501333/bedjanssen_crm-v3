# By-IDs Subroute Implementation Summary

## Overview

A new subroute has been added to the ticket-items reports API to retrieve detailed ticket information based on a list of ticket IDs.

## New Endpoint

**Route**: `POST /api/reports/ticket-items/by-ids`

**Purpose**: Retrieve comprehensive ticket information including customer details, location information, and associated ticket items.

## Implementation Details

### File Structure
```
backend/routes/api/reports/ticket-items/
├── index.dart                    # Main endpoint (existing)
├── by-ids/
│   ├── index.dart               # New by-ids endpoint
│   ├── by-ids-api.http          # HTTP test examples
│   └── TICKETS_BY_IDS_API.md   # Complete API documentation
└── BY_IDS_SUBROUTE_SUMMARY.md  # This summary
```

### Key Features

1. **Input Validation**: Accepts an array of ticket IDs in the request body
2. **Comprehensive Data**: Returns complete ticket information including:
   - Ticket details (ID, description, created by)
   - Customer information (name, company, address)
   - Location details (governorate, city)
   - Phone numbers
   - Associated ticket items with product details

3. **Error Handling**: Proper error responses for missing or invalid data
4. **CORS Support**: Full CORS headers for cross-origin requests

### Database Queries

The endpoint performs three main database operations:

1. **Main Query**: Retrieves ticket information with JOINs to related tables
2. **Phone Query**: Gets customer phone numbers
3. **Items Query**: Retrieves ticket items with product and reason details

### Response Format

The response exactly matches the requested format:

```json
{
  "success": true,
  "tickets": [
    {
      "id": 5428,
      "customerName": "محمد عبد الشافى ابراهيم",
      "companyName": "janssen",
      "governorateName": "القاهرة",
      "cityName": "عين شمس",
      "adress": "",
      "phones": ["01225462948"],
      "description": "",
      "createdByName": "يوسف",
      "items": [
        {
          "productName": "الماني",
          "productSize": "0*120*25",
          "quantity": 2,
          "purchaseDate": "2016-12-31",
          "purchaseLocation": "",
          "requestReasonName": "هبوط",
          "requestReasonDetail": "العميل يشكو من هبوط وتم ابلاغ العميل بارسال البادج وصور المرتبه"
        }
      ]
    }
  ]
}
```

## Usage

### Request Example
```bash
POST /api/reports/ticket-items/by-ids
Content-Type: application/json

{
  "ticketIds": [5428, 5429, 5430]
}
```

### Testing
Use the provided `by-ids-api.http` file to test the endpoint with various scenarios including:
- Multiple ticket IDs
- Single ticket ID
- Error cases (missing/empty ticketIds)

## Integration

This subroute complements the existing main endpoint by providing:
- **Focused Data Retrieval**: Get specific tickets by ID instead of filtered reports
- **Detailed Information**: Complete ticket details in a single request
- **Efficient Queries**: Optimized for retrieving specific ticket data

## Notes

- All string fields support Arabic text
- Phone numbers are retrieved based on customer name matching
- Purchase dates are formatted as YYYY-MM-DD strings
- Empty/null values are returned as empty strings
- The response structure exactly matches the specification provided
