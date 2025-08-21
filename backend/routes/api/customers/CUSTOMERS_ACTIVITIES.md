# Customers API Activities

This document lists all the activities available in the customers API routes with their corresponding activity names.

## Customer Management Routes (`/api/customers/id/{id}`)

### Get Customer Details
- **Route**: `GET /api/customers/id/{id}`
- **Activity Name**: Get customer details
- **Description**: Retrieves detailed information about a specific customer including personal details, phones, and associated data
- **Parameters**:
  - `id` (required): Customer ID

### Update Customer Details
- **Route**: `PUT /api/customers/id/{id}`
- **Activity Name**: Update customer details
- **Description**: Updates customer information including name, address, notes, governorate, and city
- **Parameters**:
  - `id` (required): Customer ID
  - Request body with customer fields to update

## Customer Phone Management Routes (`/api/customers/id/{id}/phones`)

### Get Customer Phones
- **Route**: `GET /api/customers/id/{id}/phones`
- **Activity Name**: Get customer phones
- **Description**: Retrieves all phone numbers associated with a specific customer
- **Parameters**:
  - `id` (required): Customer ID

### Add Customer Phone
- **Route**: `POST /api/customers/id/{id}/phones`
- **Activity Name**: Add customer phone
- **Description**: Adds a new phone number to a customer
- **Parameters**:
  - `id` (required): Customer ID
  - `phone` (required): Phone number
  - `phoneType` (required): Type of phone (mobile, home, work, etc.)

### Update Customer Phone
- **Route**: `PUT /api/customers/id/{id}/phones/{phoneId}`
- **Activity Name**: Update customer phone
- **Description**: Updates an existing phone number for a customer
- **Parameters**:
  - `id` (required): Customer ID
  - `phoneId` (required): Phone record ID
  - `phone` (required): Updated phone number
  - `phoneType` (required): Updated phone type

### Delete Customer Phone
- **Route**: `DELETE /api/customers/id/{id}/phones/{phoneId}`
- **Activity Name**: Delete customer phone
- **Description**: Removes a phone number from a customer
- **Parameters**:
  - `id` (required): Customer ID
  - `phoneId` (required): Phone record ID

## Customer Calls Management Routes (`/api/customers/id/{id}/calls`)

### Get Customer Calls
- **Route**: `GET /api/customers/id/{id}/calls`
- **Activity Name**: Get customer calls
- **Description**: Retrieves all calls associated with a specific customer
- **Parameters**:
  - `id` (required): Customer ID

### Create Customer Call
- **Route**: `POST /api/customers/id/{id}/calls`
- **Activity Name**: Create customer call
- **Description**: Creates a new call record for a customer
- **Parameters**:
  - `id` (required): Customer ID
  - `callType` (required): Type of call
  - `categoryId` (required): Call category ID
  - `description` (required): Call description
  - `callNotes` (optional): Additional call notes
  - `callDuration` (optional): Duration of the call

## Customer Tickets Management Routes (`/api/customers/id/{id}/tickets`)

### Get Customer Tickets
- **Route**: `GET /api/customers/id/{id}/tickets`
- **Activity Name**: Get customer tickets
- **Description**: Retrieves all tickets associated with a specific customer
- **Parameters**:
  - `id` (required): Customer ID

### Create Customer Ticket
- **Route**: `POST /api/customers/id/{id}/tickets`
- **Activity Name**: Create customer ticket
- **Description**: Creates a new ticket for a customer
- **Parameters**:
  - `id` (required): Customer ID
  - `ticketCatId` (required): Ticket category ID
  - `status` (required): Ticket status
  - `priority` (required): Ticket priority
  - `description` (required): Ticket description

## Customer Creation with Call Routes (`/api/customers/with-call`)

### Create Customer with Call
- **Route**: `POST /api/customers/with-call`
- **Activity Name**: Create customer with call
- **Description**: Creates a new customer along with an initial call record in a single transaction
- **Parameters**:
  - `companyId` (required): Company ID
  - `name` (required): Customer name
  - `address` (optional): Customer address
  - `notes` (optional): Customer notes
  - `governorateId` (optional): Governorate ID
  - `cityId` (optional): City ID
  - `phones` (required): Array of phone objects
  - `call` (required): Call object with call details
  - `createdBy` (required): User ID who created the record

## Customer Creation with Ticket Routes (`/api/customers/with-ticket`)

### Create Customer with Ticket
- **Route**: `POST /api/customers/with-ticket`
- **Activity Name**: Create customer with ticket
- **Description**: Creates a new customer along with an initial ticket in a single transaction
- **Parameters**:
  - `companyId` (required): Company ID
  - `name` (required): Customer name
  - `address` (optional): Customer address
  - `notes` (optional): Customer notes
  - `governorateId` (optional): Governorate ID
  - `cityId` (optional): City ID
  - `phones` (required): Array of phone objects
  - `ticket` (required): Ticket object with ticket details
  - `createdBy` (required): User ID who created the record

## Summary of All Activities

1. Get customer details
2. Update customer details
3. Get customer phones
4. Add customer phone
5. Update customer phone
6. Delete customer phone
7. Get customer calls
8. Create customer call
9. Get customer tickets
10. Create customer ticket
11. Create customer with call
12. Create customer with ticket

---

**Note**: All customer endpoints support CORS and include comprehensive validation. The creation endpoints with call/ticket use database transactions to ensure data consistency. Phone types and call/ticket statuses are validated against predefined values in the system.