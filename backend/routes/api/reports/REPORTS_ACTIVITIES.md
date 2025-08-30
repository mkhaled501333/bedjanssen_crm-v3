# Reports API Activities

This document lists all the activities available in the reports API routes with their corresponding activity names.

## Ticket Items Reports (`/api/reports/ticket-items`)

### Get Ticket Items Report
- **Route**: `POST /api/reports/ticket-items`
- **Activity Name**: Get ticket items report
- **Activity ID**: 305
- **Description**: Retrieves comprehensive ticket items report with dynamic filtering, available filters, and pagination
- **Parameters** (in request body):
  - `filters.companyId` (required): Company ID
  - `filters.governomateIds` (optional): Filter by governorate IDs
  - `filters.cityIds` (optional): Filter by city IDs
  - `filters.customerIds` (optional): Filter by customer IDs
  - `filters.ticketIds` (optional): Filter by ticket IDs
  - `filters.ticketCatIds` (optional): Filter by ticket category IDs
  - `filters.ticketStatus` (optional): Filter by ticket status
  - `filters.productIds` (optional): Filter by product IDs
  - `filters.requestReasonIds` (optional): Filter by request reason IDs
  - `filters.action` (optional): Filter by action type
  - `filters.inspected` (optional): Filter by inspection status
  - `filters.inspectionDateFrom` (optional): Filter by inspection date from
  - `filters.inspectionDateTo` (optional): Filter by inspection date to
  - `filters.pulledStatus` (optional): Filter by pulled status
  - `filters.deliveredStatus` (optional): Filter by delivered status
  - `page` (optional): Page number for pagination (default: 1)
  - `limit` (optional): Number of records per page (default: 50)

### Get Ticket Items by IDs
- **Route**: `POST /api/reports/ticket-items/by-ids`
- **Activity Name**: Get ticket items by IDs
- **Activity ID**: 306
- **Description**: Retrieves detailed ticket information by specific ticket IDs
- **Parameters** (in request body):
  - `ticketIds` (required): Array of ticket IDs to retrieve

## Summary of All Activities

1. Get ticket items report (Activity ID: 305)
2. Get ticket items by IDs (Activity ID: 306)

---

**Note**: All report endpoints support CORS and include comprehensive error handling and validation. Export endpoints retrieve all matching records without pagination limits.

