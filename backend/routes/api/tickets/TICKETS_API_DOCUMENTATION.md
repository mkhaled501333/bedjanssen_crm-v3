# Tickets API Documentation

This document describes the ticket management endpoints in the CRM system. The tickets API provides comprehensive functionality for creating, managing, and tracking customer support tickets with associated calls and items.

## Base Endpoint
`/api/tickets`

## Endpoints Overview

### 1. Create Ticket with Call and Item
**POST** `/api/tickets`

Creates a new ticket with an associated call log and item in a single transaction.

#### Request Body
```json
{
  "companyId": 1,
  "customerId": 123,
  "ticketCatId": 5,
  "description": "Customer complaint about product quality",
  "status": "open",
  "priority": "medium",
  "createdBy": 10,
  "call": {
    "callType": "incoming",
    "callCatId": 2,
    "description": "Initial customer call",
    "callNotes": "Customer reported issue with product",
    "callDuration": 300
  },
  "item": {
    "productId": 456,
    "quantity": 1,
    "productSize": "Large",
    "purchaseDate": "2024-01-15",
    "purchaseLocation": "Online Store",
    "requestReasonId": 3,
    "requestReasonDetail": "Product defect reported"
  }
}
```

#### Response
- **201 Created**: Ticket created successfully with complete ticket details including call and item
- **400 Bad Request**: Validation errors
- **404 Not Found**: Customer, ticket category, or call category not found
- **500 Internal Server Error**: Database or server error

#### Validation Rules
- `companyId`, `customerId`, `ticketCatId`, `createdBy` are required integers
- `description` is optional string
- `status` can be "open" or "closed" (defaults to "open")
- `priority` can be "low", "medium", or "high" (defaults to "medium")
- `call.callType` must be "incoming" or "outgoing"
- `call.callCatId` is required integer
- `item.productId`, `item.requestReasonId` are required integers
- `item.quantity` is required number
- `item.purchaseDate` is required string (YYYY-MM-DD format)
- `item.purchaseLocation`, `item.requestReasonDetail` are required strings

---

### 2. Add Call Log to Ticket
**POST** `/api/tickets/{id}/calls`

Adds a new call log entry to an existing ticket.

#### Request Body
```json
{
  "companyId": 1,
  "callType": "outgoing",
  "callCatId": 3,
  "description": "Follow-up call to customer",
  "callNotes": "Discussed resolution options",
  "callDuration": 180,
  "createdBy": 10
}
```

#### Response
- **201 Created**: Call log added successfully
- **400 Bad Request**: Invalid ticket ID or validation errors
- **404 Not Found**: Ticket not found
- **500 Internal Server Error**: Database or server error

#### Validation Rules
- `companyId`, `callCatId`, `createdBy` are required integers
- `callType` must be "incoming" or "outgoing"
- `description` is required non-empty string
- `callNotes` and `callDuration` are optional

---

### 3. Update Ticket Category
**PUT** `/api/tickets/{id}/category`

Updates the category of an existing ticket.

#### Request Body
```json
{
  "ticketCatId": 7
}
```

#### Response
- **200 OK**: Category updated successfully with updated ticket details
- **400 Bad Request**: Invalid ticket ID, validation errors, or invalid category
- **404 Not Found**: Ticket not found
- **500 Internal Server Error**: Database or server error

#### Validation Rules
- `ticketCatId` is required integer
- Category must exist in the system

---

### 4. Close Ticket
**PUT** `/api/tickets/{id}/close`

Closes an existing ticket with closing notes.

#### Request Body
```json
{
  "closingNotes": "Issue resolved - replacement product sent",
  "closedBy": 10
}
```

#### Response
- **200 OK**: Ticket closed successfully
- **400 Bad Request**: Invalid ticket ID or validation errors
- **404 Not Found**: Ticket not found or already closed
- **500 Internal Server Error**: Database or server error

#### Validation Rules
- `closingNotes` is required non-empty string
- `closedBy` is required integer
- Ticket must exist and not be already closed

---

### 5. Get Ticket Items
**GET** `/api/tickets/{id}/items`

Retrieves all items associated with a specific ticket.

#### Response
- **200 OK**: List of ticket items
- **400 Bad Request**: Invalid ticket ID
- **404 Not Found**: Ticket not found
- **500 Internal Server Error**: Database or server error

#### Response Format
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "companyId": 1,
      "ticketId": 123,
      "productId": 456,
      "productName": "Premium Widget",
      "quantity": 1,
      "productSize": "Large",
      "purchaseDate": "2024-01-15",
      "purchaseLocation": "Online Store",
      "requestReasonId": 3,
      "requestReasonDetail": "Product defect reported",
      "createdBy": "John Doe",
      "createdAt": "2024-01-20T10:30:00Z",
      "updatedAt": "2024-01-20T10:30:00Z"
    }
  ]
}
```

---

### 6. Add Item to Ticket
**POST** `/api/tickets/{id}/items`

Adds a new item to an existing ticket.

#### Request Body
```json
{
  "companyId": 1,
  "productId": 789,
  "quantity": 2,
  "product_size": "Medium",
  "purchase_date": "2024-01-10",
  "purchase_location": "Retail Store",
  "request_reason_id": 4,
  "request_reason_detail": "Wrong size delivered",
  "createdBy": 10
}
```

#### Response
- **201 Created**: Item added successfully with item details
- **400 Bad Request**: Invalid ticket ID or validation errors
- **404 Not Found**: Ticket not found
- **500 Internal Server Error**: Database or server error

#### Validation Rules
- `companyId`, `productId`, `createdBy` are required integers
- `quantity` is required number
- Optional fields: `product_size`, `purchase_date`, `purchase_location`, `request_reason_id`, `request_reason_detail`

---

### 7. Update Ticket Item
**PUT** `/api/tickets/{ticketId}/items/{itemId}`

Updates an existing item within a ticket.

#### Request Body
```json
{
  "quantity": 3,
  "product_size": "Large",
  "purchase_location": "Updated Store Location"
}
```

#### Response
- **200 OK**: Item updated successfully with updated item details
- **400 Bad Request**: Invalid IDs or no fields to update
- **404 Not Found**: Ticket item not found
- **500 Internal Server Error**: Database or server error

#### Updatable Fields
- `productId`
- `quantity`
- `product_size`
- `purchase_date`
- `purchase_location`
- `request_reason_id`
- `request_reason_detail`

---

### 8. Delete Ticket Item
**DELETE** `/api/tickets/{ticketId}/items/{itemId}`

Removes an item from a ticket.

#### Response
- **200 OK**: Item deleted successfully
- **400 Bad Request**: Invalid ticket or item ID
- **404 Not Found**: Ticket item not found
- **500 Internal Server Error**: Database or server error

---

## Common Response Format

All endpoints return JSON responses with the following structure:

### Success Response
```json
{
  "success": true,
  "data": { /* endpoint-specific data */ },
  "message": "Operation completed successfully"
}
```

### Error Response
```json
{
  "success": false,
  "message": "Human-readable error message",
  "error": "Technical error details"
}
```

## CORS Support

All endpoints support CORS with the following headers:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS`
- `Access-Control-Allow-Headers: Content-Type, Authorization`

## Database Tables

The tickets API interacts with the following database tables:
- `tickets` - Main ticket information
- `ticketcall` - Call logs associated with tickets
- `ticket_items` - Items/products associated with tickets
- `ticket_categories` - Ticket categorization
- `call_categories` - Call categorization
- `customers` - Customer information
- `product_info` - Product details
- `request_reasons` - Reason codes for requests
- `users` - User information for audit trails

## Status and Priority Mappings

### Ticket Status
- `0` = "open"
- `1` = "in progress" 
- `2` = "closed"

### Ticket Priority
- `0` = "low"
- `1` = "medium"
- `2` = "high"

### Call Type
- `0` = "incoming"
- `1` = "outgoing"

## Transaction Safety

The following operations are wrapped in database transactions to ensure data consistency:
- Creating ticket with call and item (POST /api/tickets)
- Adding call logs to tickets
- Adding items to tickets

This ensures that if any part of the operation fails, all changes are rolled back to maintain data integrity.