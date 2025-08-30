
# Plan for Implementing Filters in Ticket Report

This document outlines the plan to implement the available filters from the backend in the frontend ticket report table.

## 1. Backend API Filters

The backend API endpoint at `/api/reports/ticket-items` accepts a `POST` request with a JSON body containing a `filters` object. The available filters are:

- `companyId`: `int` (required)
- `customerIds`: `List<int>`
- `governorateIds`: `List<int>`
- `cityIds`: `List<int>`
- `ticketIds`: `List<int>`
- `companyIds`: `List<int>`
- `ticketCatIds`: `List<int>`
- `ticketStatus`: `String`
- `productIds`: `List<int>`
- `requestReasonIds`: `List<int>`
- `inspected`: `bool`
- `inspectionDateFrom`: `DateTime` (as `String`)
- `inspectionDateTo`: `DateTime` (as `String`)
- `actions`: `List<String>`
- `pulledStatus`: `bool`
- `deliveredStatus`: `bool`
- `clientApproval`: `bool`

## 2. Frontend Implementation Plan

The frontend component `TicketReport.tsx` will be modified to incorporate the filters.

### 2.1. Filter Mapping

The following mapping will be used to connect frontend columns to backend filters. Note that not all columns have a direct filter counterpart.

| Frontend Column     | Backend Filter Key    | Filter Type      | UI Component        |
| ------------------- | --------------------- | ---------------- | ------------------- |
| ID                  | `ticketIds`           | `List<int>`      | Multi-select list   |
| Customer            | `customerIds`         | `List<int>`      | Multi-select list   |
| Governorate         | `governorateIds`      | `List<int>`      | Multi-select list   |
| City                | `cityIds`             | `List<int>`      | Multi-select list   |
| Ticket ID           | `ticketIds`           | `List<int>`      | Multi-select list   |
| Category            | `ticketCatIds`        | `List<int>`      | Multi-select list   |
| Status              | `ticketStatus`        | `String`         | Text input          |
| Product             | `productIds`          | `List<int>`      | Multi-select list   |
| Request Reason      | `requestReasonIds`    | `List<int>`      | Multi-select list   |
| Inspected           | `inspected`           | `bool`           | Dropdown (Yes/No)   |
| Inspection Date     | `inspectionDateFrom` / `inspectionDateTo` | `DateTime` range | Date range picker   |
| Client Approval     | `clientApproval`      | `bool`           | Dropdown (Yes/No)   |
| Action              | `actions`              | `List<String>`         | Multi-select list          |
| Pulled Status       | `pulledStatus`        | `bool`           | Dropdown (Yes/No)   |
| Delivered Status    | `deliveredStatus`     | `bool`           | Dropdown (Yes/No)   |

### 2.2. State Management

The existing `useTicketReportFilters` hook will be extended to manage the state for the new filter types, including date ranges and boolean values.

### 2.3. UI Components

- **Multi-select list:** The existing `FilterHeader` with its dropdown and checklist can be used for `List<int>` filters.
- **Text input:** A text input field will be added to the filter dropdown for `String` filters.
- **Dropdown (Yes/No):** A simple dropdown with "Yes", "No", and "All" options will be added for `bool` filters.
- **Date range picker:** A date range picker component will be integrated for date range filters.

### 2.4. API Integration

The `useEffect` hook in `TicketReport.tsx` will be updated to correctly format the `activeFilters` into the `apiFilters` object that the backend expects. This will involve:
- Mapping the frontend filter keys to the backend filter keys.
- Handling the different data types (e.g., converting date objects to ISO strings).

```javascript
// Example of the updated useEffect hook in TicketReport.tsx

useEffect(() => {
  const apiFilters = {
    companyId,
    ...Object.entries(activeFilters).reduce((acc, [key, value]) => {
      switch (key) {
        case 'ID':
        case 'Ticket ID':
          acc.ticketIds = value;
          break;
        case 'Customer':
          acc.customerIds = value;
          break;
        case 'Governorate':
          acc.governorateIds = value;
          break;
        case 'City':
          acc.cityIds = value;
          break;
        case 'Category':
          acc.ticketCatIds = value;
          break;
        case 'Status':
          acc.ticketStatus = value; // Assuming single value for now
          break;
        case 'Product':
          acc.productIds = value;
          break;
        case 'Request Reason':
          acc.requestReasonIds = value;
          break;
        case 'Inspected':
          acc.inspected = value; // Assuming 'Yes'/'No' converted to true/false
          break;
        case 'Inspection Date':
          // Assuming value is an object with { from: Date, to: Date }
          acc.inspectionDateFrom = value.from?.toISOString();
          acc.inspectionDateTo = value.to?.toISOString();
          break;
        case 'Client Approval':
          acc.clientApproval = value;
          break;
        case 'Action':
          acc.action = value;
          break;
        case 'Pulled Status':
          acc.pulledStatus = value;
          break;
        case 'Delivered Status':
          acc.deliveredStatus = value;
          break;
        default:
          break;
      }
      return acc;
    }, {}),
  };

  fetchData(apiFilters, currentPage, itemsPerPage);
  resetPagination();
}, [activeFilters, currentPage, itemsPerPage, fetchData, resetPagination, companyId]);
```

## 3. Task Breakdown

1.  **Update `useTicketReportFilters` hook:**
    - Add state for new filter types (date range, boolean).
    - Implement logic to handle these new filter types.

2.  **Create new filter UI components:**
    - Create a `DateRangePicker` component.
    - Create a `BooleanFilter` component (dropdown with Yes/No/All).
    - Create a `TextFilter` component.

3.  **Update `FilterHeader` component:**
    - Conditionally render the appropriate filter UI component based on the column/filter type.

4.  **Update `TicketReport.tsx`:**
    - Implement the filter conversion logic in the `useEffect` hook as described above.
    - Pass the necessary props to the `FilterHeader` component.

5.  **Testing:**
    - Test each filter individually to ensure it correctly filters the data.
    - Test combinations of filters.
    - Test clearing filters.
