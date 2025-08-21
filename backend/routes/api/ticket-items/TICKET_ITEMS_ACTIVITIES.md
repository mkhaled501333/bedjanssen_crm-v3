# Ticket Items API Activities

This document lists all the activities available in the ticket-items API routes with their corresponding activity names.

## Change Another Product Routes (`/api/ticket-items/{itemId}/change-another`)

### Create Different Product Replacement
- **Route**: `POST /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Create different product replacement
- **Description**: Creates a new different product replacement record for a ticket item

### Update Different Product Replacement Product ID
- **Route**: `PUT /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Update different product replacement product ID
- **Description**: Updates the product ID of a different product replacement

### Update Different Product Replacement Product Size
- **Route**: `PUT /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Update different product replacement product size
- **Description**: Updates the product size of a different product replacement

### Update Different Product Replacement Cost
- **Route**: `PUT /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Update different product replacement cost
- **Description**: Updates the cost of a different product replacement

### Update Different Product Replacement Client Approval
- **Route**: `PUT /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Update different product replacement client approval
- **Description**: Updates the client approval status of a different product replacement

### Update Different Product Replacement Refusal Reason
- **Route**: `PUT /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Update different product replacement refusal reason
- **Description**: Updates the refusal reason of a different product replacement

### Update Different Product Replacement Pulled Status
- **Route**: `PUT /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Update different product replacement pulled status
- **Description**: Updates the pulled status of a different product replacement

### Update Different Product Replacement Pull Date
- **Route**: `PUT /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Update different product replacement pull date
- **Description**: Updates the pull date of a different product replacement

### Update Different Product Replacement Delivered Status
- **Route**: `PUT /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Update different product replacement delivered status
- **Description**: Updates the delivered status of a different product replacement

### Update Different Product Replacement Delivery Date
- **Route**: `PUT /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Update different product replacement delivery date
- **Description**: Updates the delivery date of a different product replacement

### Mark Different Product Replacement as Unpulled
- **Route**: `PUT /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Mark different product replacement as unpulled
- **Description**: Marks a different product replacement as unpulled (sets pulled status to false)

### Mark Different Product Replacement as Undelivered
- **Route**: `PUT /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Mark different product replacement as undelivered
- **Description**: Marks a different product replacement as undelivered (sets delivered status to false)

### Delete Different Product Replacement
- **Route**: `DELETE /api/ticket-items/{itemId}/change-another`
- **Activity Name**: Delete different product replacement
- **Description**: Removes a different product replacement record from the system

## Change Same Product Routes (`/api/ticket-items/{itemId}/change-same`)

### Create Same Product Replacement
- **Route**: `POST /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Create same product replacement
- **Description**: Creates a new same product replacement record for a ticket item
 
### Update Same Product Replacement Product ID
- **Route**: `PUT /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Update same product replacement product ID
- **Description**: Updates the product ID of a same product replacement

### Update Same Product Replacement Product Size
- **Route**: `PUT /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Update same product replacement product size
- **Description**: Updates the product size of a same product replacement

### Update Same Product Replacement Cost
- **Route**: `PUT /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Update same product replacement cost
- **Description**: Updates the cost of a same product replacement

### Update Same Product Replacement Client Approval
- **Route**: `PUT /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Update same product replacement client approval
- **Description**: Updates the client approval status of a same product replacement

### Update Same Product Replacement Refusal Reason
- **Route**: `PUT /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Update same product replacement refusal reason
- **Description**: Updates the refusal reason of a same product replacement

### Update Same Product Replacement Pulled Status
- **Route**: `PUT /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Update same product replacement pulled status
- **Description**: Updates the pulled status of a same product replacement

### Update Same Product Replacement Pull Date
- **Route**: `PUT /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Update same product replacement pull date
- **Description**: Updates the pull date of a same product replacement

### Update Same Product Replacement Delivered Status
- **Route**: `PUT /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Update same product replacement delivered status
- **Description**: Updates the delivered status of a same product replacement

### Update Same Product Replacement Delivery Date
- **Route**: `PUT /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Update same product replacement delivery date
- **Description**: Updates the delivery date of a same product replacement

### Mark Same Product Replacement as Unpulled
- **Route**: `PUT /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Mark same product replacement as unpulled
- **Description**: Marks a same product replacement as unpulled (sets pulled status to false)

### Mark Same Product Replacement as Undelivered
- **Route**: `PUT /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Mark same product replacement as undelivered
- **Description**: Marks a same product replacement as undelivered (sets delivered status to false)

### Delete Same Product Replacement
- **Route**: `DELETE /api/ticket-items/{itemId}/change-same`
- **Activity Name**: Delete same product replacement
- **Description**: Removes a same product replacement record from the system

## Inspection Routes (`/api/ticket-items/{itemId}/inspection`)

### Mark Item as Inspected
- **Route**: `PUT /api/ticket-items/{itemId}/inspection`
- **Activity Name**: Mark item as inspected
- **Description**: Marks a ticket item as inspected (sets inspected status to true)

### Mark Item as Uninspected
- **Route**: `PUT /api/ticket-items/{itemId}/inspection`
- **Activity Name**: Mark item as uninspected
- **Description**: Marks a ticket item as uninspected (sets inspected status to false)

### Update Item Inspection Date
- **Route**: `PUT /api/ticket-items/{itemId}/inspection`
- **Activity Name**: Update item inspection date
- **Description**: Updates the inspection date of a ticket item

### Update Item Inspection Result
- **Route**: `PUT /api/ticket-items/{itemId}/inspection`
- **Activity Name**: Update item inspection result
- **Description**: Updates the inspection result of a ticket item

## Maintenance Routes (`/api/ticket-items/{itemId}/maintenance`)

### Create Maintenance Option
- **Route**: `POST /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Create maintenance option
- **Description**: Creates a new maintenance option record for a ticket item

### Update Maintenance Steps
- **Route**: `PUT /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Update maintenance steps
- **Description**: Updates the maintenance steps of a maintenance option

### Update Maintenance Cost
- **Route**: `PUT /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Update maintenance cost
- **Description**: Updates the maintenance cost of a maintenance option

### Update Maintenance Client Approval
- **Route**: `PUT /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Update maintenance client approval
- **Description**: Updates the client approval status of a maintenance option

### Update Maintenance Refusal Reason
- **Route**: `PUT /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Update maintenance refusal reason
- **Description**: Updates the refusal reason of a maintenance option

### Update Maintenance Pulled Status
- **Route**: `PUT /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Update maintenance pulled status
- **Description**: Updates the pulled status of a maintenance option

### Update Maintenance Pull Date
- **Route**: `PUT /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Update maintenance pull date
- **Description**: Updates the pull date of a maintenance option

### Update Maintenance Delivered Status
- **Route**: `PUT /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Update maintenance delivered status
- **Description**: Updates the delivered status of a maintenance option

### Update Maintenance Delivery Date
- **Route**: `PUT /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Update maintenance delivery date
- **Description**: Updates the delivery date of a maintenance option

### Mark Maintenance as Unpulled
- **Route**: `PUT /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Mark maintenance as unpulled
- **Description**: Marks a maintenance option as unpulled (sets pulled status to false)

### Mark Maintenance as Undelivered
- **Route**: `PUT /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Mark maintenance as undelivered
- **Description**: Marks a maintenance option as undelivered (sets delivered status to false)

### Delete Maintenance Option
- **Route**: `DELETE /api/ticket-items/{itemId}/maintenance`
- **Activity Name**: Delete maintenance option
- **Description**: Removes a maintenance option record from the system

## Summary of All Activities

1. Create different product replacement
2. Update different product replacement product ID
3. Update different product replacement product size
4. Update different product replacement cost
5. Update different product replacement client approval
6. Update different product replacement refusal reason
7. Update different product replacement pulled status
8. Update different product replacement pull date
9. Update different product replacement delivered status
10. Update different product replacement delivery date
11. Mark different product replacement as unpulled
12. Mark different product replacement as undelivered
13. Delete different product replacement
14. Create same product replacement
15. Update same product replacement product ID
16. Update same product replacement product size
17. Update same product replacement cost
18. Update same product replacement client approval
19. Update same product replacement refusal reason
20. Update same product replacement pulled status
21. Update same product replacement pull date
22. Update same product replacement delivered status
23. Update same product replacement delivery date
24. Mark same product replacement as unpulled
25. Mark same product replacement as undelivered
26. Delete same product replacement
27. Mark item as inspected
28. Mark item as uninspected
29. Update item inspection date
30. Update item inspection result
31. Create maintenance option
32. Update maintenance steps
33. Update maintenance cost
34. Update maintenance client approval
35. Update maintenance refusal reason
36. Update maintenance pulled status
37. Update maintenance pull date
38. Update maintenance delivered status
39. Update maintenance delivery date
40. Mark maintenance as unpulled
41. Mark maintenance as undelivered
42. Delete maintenance option

---

**Note**: The PUT endpoints for updating ticket items support updating multiple fields in a single request, but each field update represents a distinct activity as listed above.