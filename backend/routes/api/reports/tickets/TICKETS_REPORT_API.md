# Tickets Report API (Detailed)

This document provides a comprehensive and detailed description of the Tickets Report API endpoint, including all the available parameters, filters, functionalities, and response formats.

## Endpoint URL

`http://localhost:8081/api/reports/tickets`

## HTTP Method

`GET`

## Authentication

Authentication is required to access this endpoint. The API uses JWT Bearer tokens. You need to include an `Authorization` header with your request:

`Authorization: Bearer <your_jwt_token>`

## Query Parameters

| Parameter | Type | Description |
|---|---|---|
| `companyId` | `integer` | **Required.** The ID of the company to get the report for. |
| `page` | `integer` | The page number for pagination. Defaults to `1`. |
| `limit` | `integer` | The number of items per page. Defaults to `10`. |
| `status` | `string` | Filter by ticket status. Can be a single status or a comma-separated list of statuses (e.g., `open,in_progress`). |
| `categoryId` | `integer` | Filter by ticket category ID. |
| `customerId` | `integer` | Filter by customer ID. |
| `startDate` | `string` | The start date for the date range filter (format: `YYYY-MM-DD`). |
| `endDate` | `string` | The end date for the date range filter (format: `YYYY-MM-DD`). |
| `searchTerm` | `string` | A search term to filter by ticket description, customer name, or category name. |
| `governorate` | `string` | Filter by governorate. Can be a single governorate or a comma-separated list of governorates. |
| `city` | `string` | Filter by city. Can be a single city or a comma-separated list of cities. |
| `productName` | `string` | Filter by product name. Can be a single product name or a comma-separated list of product names. |
| `companyName` | `string` | Filter by company name. Can be a single company name or a comma-separated list of company names. |
| `requestReasonName` | `string` | Filter by request reason name. Can be a single request reason name or a comma-separated list of request reason names. |
| `inspected` | `boolean` | Filter by inspection status (`true` or `false`). |

## Multiple Value Filters

The following string-based filter parameters support multiple comma-separated values:

- `governorate`
- `city`
- `status`
- `productName`
- `companyName`
- `requestReasonName`

When you provide multiple values, the API will return all tickets that match any of the specified values (using an `IN` clause in the database query).

## Response Format

The API returns a JSON object with the following structure:

```json
{
  "tickets": [
    {
      "id": 1,
      "company_id": 1,
      "customer_id": 123,
      "ticket_cat_id": 1,
      "description": "Ticket description",
      "status": "open",
      "priority": "high",
      "created_by": 1,
      "created_at": "2024-08-26T10:00:00.000Z",
      "updated_at": "2024-08-26T10:00:00.000Z",
      "closed_at": null,
      "closing_notes": null,
      "customer_name": "Customer Name",
      "company_name": "Company Name",
      "governorate_name": "Governorate Name",
      "city_name": "City Name",
      "category_name": "Category Name",
      "created_by_name": "User Name",
      "calls_count": 2,
      "items_count": 3,
      "items": [
        {
          "id": 1,
          "ticket_id": 1,
          "product_id": 1,
          "product_name": "Product A",
          "product_size": "Large",
          "quantity": 1,
          "purchase_date": "2024-08-20",
          "purchase_location": "Store X",
          "request_reason_id": 1,
          "request_reason_name": "Defective",
          "request_reason_detail": "The product is not working as expected.",
          "inspected": true,
          "inspection_date": "2024-08-22",
          "inspection_result": "Repaired",
          "client_approval": true,
          "created_at": "2024-08-26T10:00:00.000Z",
          "updated_at": "2024-08-26T10:00:00.000Z"
        }
      ]
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 10,
    "totalItems": 100,
    "itemsPerPage": 10,
    "hasNextPage": true,
    "hasPreviousPage": false
  },
  "summary": {
    "statusCounts": {
      "open": 50,
      "closed": 30,
      "in_progress": 20
    }
  },
  "filters": {
    "companyId": 1,
    "status": "open,in_progress",
    "governorate": "الجيزة,الغربية"
  },
  "available_filters": {
    "governorates": ["الجيزة", "الغربية", "الشرقيه"],
    "cities": ["بلبيس", "الزقازيق", "6أكتوبر"],
    "categories": ["Category A", "Category B"],
    "statuses": ["open", "closed", "in_progress"],
    "productNames": ["Product A", "Product B"],
    "companyNames": ["Company X", "Company Y"],
    "requestReasonNames": ["Defective", "Maintenance"]
  }
}
```

### `tickets` Object

An array of ticket objects, each with the following fields:

- `id`: The ticket ID.
- `company_id`: The company ID.
- `customer_id`: The customer ID.
- `ticket_cat_id`: The ticket category ID.
- `description`: The ticket description.
- `status`: The ticket status (e.g., `open`, `closed`, `in_progress`).
- `priority`: The ticket priority (e.g., `high`, `medium`, `low`).
- `created_by`: The ID of the user who created the ticket.
- `created_at`: The timestamp when the ticket was created.
- `updated_at`: The timestamp when the ticket was last updated.
- `closed_at`: The timestamp when the ticket was closed.
- `closing_notes`: The notes added when the ticket was closed.
- `customer_name`: The name of the customer.
- `company_name`: The name of the company.
- `governorate_name`: The name of the governorate.
- `city_name`: The name of the city.
- `category_name`: The name of the ticket category.
- `created_by_name`: The name of the user who created the ticket.
- `calls_count`: The number of calls associated with the ticket.
- `items_count`: The number of items associated with the ticket.
- `items`: An array of ticket item objects, each with details about the product, request reason, and inspection.

### `pagination` Object

An object containing pagination information:

- `currentPage`: The current page number.
- `totalPages`: The total number of pages.
- `totalItems`: The total number of tickets that match the filter criteria.
- `itemsPerPage`: The number of items per page.
- `hasNextPage`: A boolean indicating if there is a next page.
- `hasPreviousPage`: A boolean indicating if there is a previous page.

### `summary` Object

An object containing summary statistics, such as the count of tickets for each status.

### `filters` Object

An object containing the filters that were applied to the request.

### `available_filters` Object

An object containing the available filter options based on the current filter selection. This is useful for dynamically updating the filter options in the UI.

## Export Functionality

You can export the tickets report in CSV, Excel, or PDF format by using the `/export` endpoint:

`http://localhost:8081/api/reports/tickets/export`

This endpoint supports the same filter parameters as the main tickets report endpoint. You need to specify the desired format using the `format` query parameter (`csv`, `excel`, or `pdf`).

## Error Handling

The API uses standard HTTP status codes to indicate the success or failure of a request:

- `200 OK`: The request was successful.
- `400 Bad Request`: The request was invalid (e.g., missing required parameters, invalid parameter format).
- `401 Unauthorized`: Authentication failed (e.g., missing or invalid JWT token).
- `500 Internal Server Error`: An unexpected error occurred on the server.

## Example Requests

**Get the first page of tickets for a company:**

`GET http://localhost:8081/api/reports/tickets?companyId=1&page=1&limit=10`

This request will return the first 10 tickets for company with ID 1. The response will include the `tickets`, `pagination`, `summary`, and `available_filters` objects.

**Get all open and in-progress tickets for a company, filtered by two governorates:**

`GET http://localhost:8081/api/reports/tickets?companyId=1&status=open,in_progress&governorate=الجيزة,الغربية`

This request will return all tickets for company with ID 1 that have a status of `open` or `in_progress` and are located in either `الجيزة` or `الغربية`. The `available_filters` object in the response will be updated to reflect the current filter selection.

**Export all tickets for a company to a CSV file:**

`GET http://localhost:8081/api/reports/tickets/export?companyId=1&format=csv`

This request will return a CSV file containing all tickets for company with ID 1.