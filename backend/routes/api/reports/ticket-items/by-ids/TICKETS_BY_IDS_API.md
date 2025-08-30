# Tickets by IDs API

This endpoint retrieves detailed information about tickets based on a list of ticket IDs, including customer information, location details, and associated ticket items.

## Endpoint

```
POST /api/reports/ticket-items/by-ids
```

## Request Body

```json
{
  "ticketIds": [5428, 5429, 5430]
}
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ticketIds` | `Array<number>` | Yes | Array of ticket IDs to retrieve |

## Response Format

### Success Response (200)

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
      "adress": "123 شارع النصر",
      "phones": [
        "01225462948"
      ],
      "description": "مشكلة في المرتبة",
      "createdByName": "يوسف",
      "items": [
        {
          "productName": "الماني",
          "productSize": "0*120*25",
          "quantity": 2,
          "purchaseDate": "2016-12-31",
          "purchaseLocation": "محل النصر",
          "requestReasonName": "هبوط",
          "requestReasonDetail": "العميل يشكو من هبوط وتم ابلاغ العميل بارسال البادج وصور المرتبه"
        }
      ]
    }
  ]
}
```

### Error Responses

#### Bad Request (400) - Missing ticketIds
```json
{
  "success": false,
  "error": "ticketIds is required and must not be empty"
}
```

#### Bad Request (400) - Empty ticketIds
```json
{
  "success": false,
  "error": "ticketIds is required and must not be empty"
}
```

#### Internal Server Error (500)
```json
{
  "success": false,
  "error": "Internal server error: [error details]"
}
```

## Response Fields

### Ticket Object

| Field | Type | Description |
|-------|------|-------------|
| `id` | `number` | Ticket ID |
| `customerName` | `string` | Customer's full name |
| `companyName` | `string` | Company name |
| `governorateName` | `string` | Governorate/region name |
| `cityName` | `string` | City name |
| `adress` | `string` | Customer's address |
| `phones` | `Array<string>` | Array of customer phone numbers |
| `description` | `string` | Ticket description |
| `createdByName` | `string` | Name of user who created the ticket |
| `items` | `Array<object>` | Array of ticket items |

### Ticket Item Object

| Field | Type | Description |
|-------|------|-------------|
| `productName` | `string` | Product name |
| `productSize` | `string` | Product dimensions/size |
| `quantity` | `number` | Quantity of items |
| `purchaseDate` | `string` | Purchase date (YYYY-MM-DD format) |
| `purchaseLocation` | `string` | Location where item was purchased |
| `requestReasonName` | `string` | Reason for the request |
| `requestReasonDetail` | `string` | Detailed description of the request reason |

## Database Queries

The endpoint performs the following database operations:

1. **Main Ticket Query**: Retrieves ticket information with customer, company, location, and user details
2. **Customer Phones Query**: Gets all phone numbers associated with each customer
3. **Ticket Items Query**: Retrieves all items associated with each ticket

## Usage Examples

### Get Multiple Tickets
```bash
curl -X POST http://localhost:8081/api/reports/ticket-items/by-ids \
  -H "Content-Type: application/json" \
  -d '{"ticketIds": [5428, 5429, 5430]}'
```

### Get Single Ticket
```bash
curl -X POST http://localhost:8081/api/reports/ticket-items/by-ids \
  -H "Content-Type: application/json" \
  -d '{"ticketIds": [5428]}'
```

## Notes

- The endpoint supports Arabic text in all string fields
- Phone numbers are retrieved based on customer name matching
- Purchase dates are formatted as YYYY-MM-DD strings
- Empty or null values are returned as empty strings
- The response maintains the exact structure requested in the specification
