# Tickets API Activities

This document lists all the activities available in the tickets API routes with their corresponding activity names.

## Main Tickets Route (`/api/tickets`)

### Create Ticket with Call and Item
- **Route**: `POST /api/tickets`
- **Activity Name**: Create ticket with call and item
- **Description**: Creates a new ticket with an associated call log and item in a single transaction

## Ticket Management Routes (`/api/tickets/{id}`)

### Close Ticket
- **Route**: `PUT /api/tickets/{id}/close`
- **Activity Name**: Close ticket
- **Description**: Closes an existing ticket with closing notes

### Update Ticket Category
- **Route**: `PUT /api/tickets/{id}/category`
- **Activity Name**: Update ticket category
- **Description**: Updates the category of an existing ticket

## Call Management Routes (`/api/tickets/{id}/calls`)

### Add Call Log to Ticket
- **Route**: `POST /api/tickets/{id}/calls`
- **Activity Name**: Add call log to ticket
- **Description**: Adds a new call log entry to an existing ticket

## Item Management Routes (`/api/tickets/{id}/items`)

### Get Ticket Items
- **Route**: `GET /api/tickets/{id}/items`
- **Activity Name**: Get ticket items
- **Description**: Retrieves all items associated with a specific ticket

### Add Item to Ticket
- **Route**: `POST /api/tickets/{id}/items`
- **Activity Name**: Add item to ticket
- **Description**: Adds a new item to an existing ticket

## Individual Item Management Routes (`/api/tickets/{ticketId}/items/{itemId}`)

### Update Ticket Item Product ID
- **Route**: `PUT /api/tickets/{ticketId}/items/{itemId}`
- **Activity Name**: Update item product ID
- **Description**: Updates the product ID of a ticket item

### Update Ticket Item Quantity
- **Route**: `PUT /api/tickets/{ticketId}/items/{itemId}`
- **Activity Name**: Update item quantity
- **Description**: Updates the quantity of a ticket item

### Update Ticket Item Product Size
- **Route**: `PUT /api/tickets/{ticketId}/items/{itemId}`
- **Activity Name**: Update item product size
- **Description**: Updates the product size of a ticket item

### Update Ticket Item Purchase Date
- **Route**: `PUT /api/tickets/{ticketId}/items/{itemId}`
- **Activity Name**: Update item purchase date
- **Description**: Updates the purchase date of a ticket item

### Update Ticket Item Purchase Location
- **Route**: `PUT /api/tickets/{ticketId}/items/{itemId}`
- **Activity Name**: Update item purchase location
- **Description**: Updates the purchase location of a ticket item

### Update Ticket Item Request Reason ID
- **Route**: `PUT /api/tickets/{ticketId}/items/{itemId}`
- **Activity Name**: Update item request reason ID
- **Description**: Updates the request reason ID of a ticket item

### Update Ticket Item Request Reason Detail
- **Route**: `PUT /api/tickets/{ticketId}/items/{itemId}`
- **Activity Name**: Update item request reason detail
- **Description**: Updates the request reason detail of a ticket item

### Delete Ticket Item
- **Route**: `DELETE /api/tickets/{ticketId}/items/{itemId}`
- **Activity Name**: Delete ticket item
- **Description**: Removes an item from a ticket

## Summary of All Activities

1. Create ticket with call and item
2. Close ticket
3. Update ticket category
4. Add call log to ticket
5. Get ticket items
6. Add item to ticket
7. Update item product ID
8. Update item quantity
9. Update item product size
10. Update item purchase date
11. Update item purchase location
12. Update item request reason ID
13. Update item request reason detail
14. Delete ticket item

---

**Note**: The PUT endpoint for updating ticket items (`/api/tickets/{ticketId}/items/{itemId}`) supports updating multiple fields in a single request, but each field update represents a distinct activity as listed above.