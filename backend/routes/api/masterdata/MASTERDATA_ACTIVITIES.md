# Masterdata API Activities

This document lists all the activities available in the masterdata API routes with their corresponding activity names.

## Call Categories Routes (`/api/masterdata/call-categories`)

### Get All Call Categories
- **Route**: `GET /api/masterdata/call-categories`
- **Activity Name**: Get all call categories
- **Description**: Retrieves all call categories from the system

### Create Call Category
- **Route**: `POST /api/masterdata/call-categories`
- **Activity Name**: Create call category
- **Description**: Creates a new call category
- **Parameters**:
  - `name` (required): Name of the call category

### Get Call Category by ID
- **Route**: `GET /api/masterdata/call-categories/{id}`
- **Activity Name**: Get call category by ID
- **Description**: Retrieves a specific call category by its ID

### Update Call Category
- **Route**: `PUT /api/masterdata/call-categories/{id}`
- **Activity Name**: Update call category
- **Description**: Updates an existing call category
- **Parameters**:
  - `name` (required): Updated name of the call category

### Delete Call Category
- **Route**: `DELETE /api/masterdata/call-categories/{id}`
- **Activity Name**: Delete call category
- **Description**: Removes a call category from the system

## Cities Routes (`/api/masterdata/cities`)

### Get All Cities
- **Route**: `GET /api/masterdata/cities`
- **Activity Name**: Get all cities
- **Description**: Retrieves all cities from the system

### Create City
- **Route**: `POST /api/masterdata/cities`
- **Activity Name**: Create city
- **Description**: Creates a new city

### Get City by ID
- **Route**: `GET /api/masterdata/cities/{id}`
- **Activity Name**: Get city by ID
- **Description**: Retrieves a specific city by its ID

### Update City
- **Route**: `PUT /api/masterdata/cities/{id}`
- **Activity Name**: Update city
- **Description**: Updates an existing city

### Delete City
- **Route**: `DELETE /api/masterdata/cities/{id}`
- **Activity Name**: Delete city
- **Description**: Removes a city from the system

## Companies Routes (`/api/masterdata/companies`)

### Get All Companies
- **Route**: `GET /api/masterdata/companies`
- **Activity Name**: Get all companies
- **Description**: Retrieves all companies from the system

## Governorates Routes (`/api/masterdata/governorates`)

### Get All Governorates
- **Route**: `GET /api/masterdata/governorates`
- **Activity Name**: Get all governorates
- **Description**: Retrieves all governorates from the system

### Create Governorate
- **Route**: `POST /api/masterdata/governorates`
- **Activity Name**: Create governorate
- **Description**: Creates a new governorate

### Get Governorate by ID
- **Route**: `GET /api/masterdata/governorates/{id}`
- **Activity Name**: Get governorate by ID
- **Description**: Retrieves a specific governorate by its ID

### Update Governorate
- **Route**: `PUT /api/masterdata/governorates/{id}`
- **Activity Name**: Update governorate
- **Description**: Updates an existing governorate

### Delete Governorate
- **Route**: `DELETE /api/masterdata/governorates/{id}`
- **Activity Name**: Delete governorate
- **Description**: Removes a governorate from the system

## Governorates with Cities Routes (`/api/masterdata/governorates-with-cities`)

### Get All Governorates with Cities
- **Route**: `GET /api/masterdata/governorates-with-cities`
- **Activity Name**: Get all governorates with cities
- **Description**: Retrieves all governorates along with their associated cities

## Products Routes (`/api/masterdata/products`)

### Get All Products
- **Route**: `GET /api/masterdata/products`
- **Activity Name**: Get all products
- **Description**: Retrieves all products from the system

### Create Product
- **Route**: `POST /api/masterdata/products`
- **Activity Name**: Create product
- **Description**: Creates a new product
- **Parameters**:
  - `product_name` (required): Name of the product
  - `company_id` (required): ID of the associated company
  - `created_by` (required): ID of the user creating the product

### Get Product by ID
- **Route**: `GET /api/masterdata/products/{id}`
- **Activity Name**: Get product by ID
- **Description**: Retrieves a specific product by its ID

### Update Product
- **Route**: `PUT /api/masterdata/products/{id}`
- **Activity Name**: Update product
- **Description**: Updates an existing product
- **Parameters**:
  - `product_name` (required): Updated name of the product

### Delete Product
- **Route**: `DELETE /api/masterdata/products/{id}`
- **Activity Name**: Delete product
- **Description**: Removes a product from the system

## Request Reasons Routes (`/api/masterdata/request-reasons`)

### Get All Request Reasons
- **Route**: `GET /api/masterdata/request-reasons`
- **Activity Name**: Get all request reasons
- **Description**: Retrieves all request reasons from the system

### Create Request Reason
- **Route**: `POST /api/masterdata/request-reasons`
- **Activity Name**: Create request reason
- **Description**: Creates a new request reason

### Get Request Reason by ID
- **Route**: `GET /api/masterdata/request-reasons/{id}`
- **Activity Name**: Get request reason by ID
- **Description**: Retrieves a specific request reason by its ID

### Update Request Reason
- **Route**: `PUT /api/masterdata/request-reasons/{id}`
- **Activity Name**: Update request reason
- **Description**: Updates an existing request reason

### Delete Request Reason
- **Route**: `DELETE /api/masterdata/request-reasons/{id}`
- **Activity Name**: Delete request reason
- **Description**: Removes a request reason from the system

## Ticket Categories Routes (`/api/masterdata/ticket-categories`)

### Get All Ticket Categories
- **Route**: `GET /api/masterdata/ticket-categories`
- **Activity Name**: Get all ticket categories
- **Description**: Retrieves all ticket categories from the system

### Create Ticket Category
- **Route**: `POST /api/masterdata/ticket-categories`
- **Activity Name**: Create ticket category
- **Description**: Creates a new ticket category

### Get Ticket Category by ID
- **Route**: `GET /api/masterdata/ticket-categories/{id}`
- **Activity Name**: Get ticket category by ID
- **Description**: Retrieves a specific ticket category by its ID

### Update Ticket Category
- **Route**: `PUT /api/masterdata/ticket-categories/{id}`
- **Activity Name**: Update ticket category
- **Description**: Updates an existing ticket category

### Delete Ticket Category
- **Route**: `DELETE /api/masterdata/ticket-categories/{id}`
- **Activity Name**: Delete ticket category
- **Description**: Removes a ticket category from the system

## Summary of All Activities

1. Get all call categories
2. Create call category
3. Get call category by ID
4. Update call category
5. Delete call category
6. Get all cities
7. Create city
8. Get city by ID
9. Update city
10. Delete city
11. Get all companies
12. Get all governorates
13. Create governorate
14. Get governorate by ID
15. Update governorate
16. Delete governorate
17. Get all governorates with cities
18. Get all products
19. Create product
20. Get product by ID
21. Update product
22. Delete product
23. Get all request reasons
24. Create request reason
25. Get request reason by ID
26. Update request reason
27. Delete request reason
28. Get all ticket categories
29. Create ticket category
30. Get ticket category by ID
31. Update ticket category
32. Delete ticket category

---

**Note**: All masterdata endpoints support CORS and follow RESTful conventions. Most entities support full CRUD operations (Create, Read, Update, Delete) except for companies which currently only supports read operations.