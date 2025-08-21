# Reports API Activities

This document lists all the activities available in the reports API routes with their corresponding activity names.

## Current Agent Reports (`/api/reports/current-agent/calls`)

### Get Agent Calls Report
- **Route**: `GET /api/reports/current-agent/calls?userId={id}&startDate={date}&endDate={date}`
- **Activity Name**: Get agent calls report
- **Description**: Retrieves all calls (customer calls and ticket calls) created by a specific user within a date range
- **Parameters**:
  - `userId` (required): ID of the user/agent
  - `startDate` (required): Start date in YYYY-MM-DD format
  - `endDate` (required): End date in YYYY-MM-DD format

## Tickets Reports (`/api/reports/tickets`)

### Get Tickets Report
- **Route**: `GET /api/reports/tickets?companyId={id}&page={num}&limit={num}`
- **Activity Name**: Get tickets report
- **Description**: Retrieves paginated tickets report for a company with optional filtering
- **Parameters**:
  - `companyId` (required): Company ID
  - `page` (optional): Page number for pagination
  - `limit` (optional): Number of records per page
  - `status` (optional): Filter by ticket status
  - `priority` (optional): Filter by ticket priority
  - `categoryId` (optional): Filter by ticket category
  - `customerId` (optional): Filter by customer
  - `startDate` (optional): Filter by start date
  - `endDate` (optional): Filter by end date
  - `searchTerm` (optional): Search term for filtering

## Tickets Export (`/api/reports/tickets/export`)

### Export Tickets Report as CSV
- **Route**: `GET /api/reports/tickets/export?format=csv&companyId={id}`
- **Activity Name**: Export tickets report as CSV
- **Description**: Exports tickets report in CSV format with all filtering options
- **Parameters**: Same as tickets report plus `format=csv`

### Export Tickets Report as Excel
- **Route**: `GET /api/reports/tickets/export?format=excel&companyId={id}`
- **Activity Name**: Export tickets report as Excel
- **Description**: Exports tickets report in Excel format with all filtering options
- **Parameters**: Same as tickets report plus `format=excel`

### Export Tickets Report as PDF
- **Route**: `GET /api/reports/tickets/export?format=pdf&companyId={id}`
- **Activity Name**: Export tickets report as PDF
- **Description**: Exports tickets report in PDF format with all filtering options
- **Parameters**: Same as tickets report plus `format=pdf`

## Summary of All Activities

1. Get agent calls report
2. Get tickets report
3. Export tickets report as CSV
4. Export tickets report as Excel
5. Export tickets report as PDF

---

**Note**: All report endpoints support CORS and include comprehensive error handling and validation. Export endpoints retrieve all matching records without pagination limits.