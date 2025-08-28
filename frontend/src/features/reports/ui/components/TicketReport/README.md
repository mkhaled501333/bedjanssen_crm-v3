# TicketReport Component

A modular React component for displaying ticket items reports with dynamic filtering, pagination, and export functionality.

## Structure

```
TicketReport/
├── components/
│   ├── FilterDropdown.tsx    # Filter dropdown component
│   └── FilterHeader.tsx      # Table header with filter functionality
├── types.ts                  # TypeScript type definitions
├── api.ts                    # API service functions
├── hooks.ts                  # Custom React hooks
├── utils.ts                  # Utility functions
├── TicketReport.tsx          # Main component
├── TicketReport.module.css   # Component styles
├── index.ts                  # Module exports
└── README.md                 # This file
```

## Features

- **Real-time Data**: Fetches data from the ticket-items API endpoint
- **Dynamic Filtering**: Filter by any column with real-time updates
- **Search in Dropdowns**: Search functionality in multi-select filter dropdowns for quick option finding
- **Pagination**: Built-in pagination with configurable page sizes
- **Row Selection**: Select individual rows or all rows
- **Export**: Export filtered data to CSV
- **Responsive Design**: Excel-like interface with modern styling
- **Type Safety**: Full TypeScript support with proper interfaces

## Usage

### Basic Usage

```tsx
import { TicketReport } from './TicketReport';

function App() {
  return (
    <div>
      <h1>Ticket Items Report</h1>
      <TicketReport />
    </div>
  );
}
```

### With Custom Company ID

```tsx
import { TicketReport } from './TicketReport';

function App() {
  const companyId = 2; // Custom company ID
  
  return (
    <div>
      <h1>Company {companyId} Ticket Report</h1>
      <TicketReport companyId={companyId} />
    </div>
  );
}
```

## API Integration

The component integrates with the `/api/reports/ticket-items` endpoint:

- **Method**: POST
- **Authentication**: Bearer token required
- **Filters**: Dynamic filtering with real-time updates
- **Pagination**: Server-side pagination support
- **Response**: Includes available filters, applied filters, and report data

## Custom Hooks

### useTicketReportData

Manages data fetching, loading states, and error handling.

```tsx
const {
  data,
  loading,
  error,
  availableFilters,
  pagination,
  fetchData,
  refetch
} = useTicketReportData(companyId);
```

### useTicketReportFilters

Manages filter state and filter operations.

```tsx
const {
  activeFilters,
  filterSelections,
  filterDropdowns,
  toggleFilter,
  handleFilterSelection,
  applyFilter,
  clearFilter,
  clearAllFilters
} = useTicketReportFilters();
```

### useTicketReportPagination

Manages pagination state and navigation.

```tsx
const {
  currentPage,
  itemsPerPage,
  totalPages,
  goToPage,
  goToNextPage,
  goToPreviousPage,
  changePageSize
} = useTicketReportPagination(totalItems, pageSize);
```

### useTicketReportSelection

Manages row selection state.

```tsx
const {
  selectedRows,
  toggleSelectAll,
  toggleRowSelection,
  clearSelection,
  isAllSelected,
  isIndeterminate
} = useTicketReportSelection(data);
```

## Components

### FilterDropdown

A dropdown component for column filtering with select all functionality.

```tsx
<FilterDropdown
  column="Status"
  isOpen={true}
  uniqueValues={['Open', 'Closed', 'Pending']}
  selectedValues={['Open']}
  onFilterSelection={handleFilterSelection}
  onSelectAllFilter={handleSelectAllFilter}
  onApplyFilter={applyFilter}
  onClearFilter={clearFilter}
/>
```

### FilterHeader

A table header component with integrated filter functionality.

```tsx
<FilterHeader
  column="Customer"
  displayName="Customer Name"
  isFiltered={true}
  filterCount={3}
  isDropdownOpen={false}
  uniqueValues={customerNames}
  selectedValues={selectedCustomers}
  onToggleFilter={toggleFilter}
  onFilterSelection={handleFilterSelection}
  onSelectAllFilter={handleSelectAllFilter}
  onApplyFilter={applyFilter}
  onClearFilter={clearFilter}
/>
```

## Search Functionality

The component now includes search functionality in dropdown filters:

- **MultiSelect Filters**: Search through available options in real-time
- **Text Filters**: Enhanced input fields with clear buttons
- **Smart Selection**: "Select All" works with filtered results
- **Real-time Filtering**: Options are filtered as you type

For detailed information about the search functionality, see [SEARCH_FUNCTIONALITY.md](./SEARCH_FUNCTIONALITY.md).

## Utilities

### Data Formatting

- `formatDate(dateString)`: Formats dates for display
- `formatBoolean(value)`: Converts boolean values to Yes/No
- `getDisplayValue(item, columnKey)`: Gets formatted display value for any column

### Export Functions

- `exportToCSV(data, filename)`: Exports data to CSV format

### Column Management

- `getColumnKey(columnName)`: Maps display names to data keys
- `getUniqueValues(data, columnKey)`: Gets unique values for filtering
- `getColumnDisplayName(columnKey)`: Gets human-readable column names

## Styling

The component uses CSS modules with an Excel-like design:

- `.excelContainer`: Main container
- `.excelToolbar`: Toolbar with action buttons
- `.excelTableWrapper`: Table container with scrolling
- `.excelTable`: Main data table
- `.excelFooter`: Footer with pagination and status

## Error Handling

- **Loading States**: Shows loading message while fetching data
- **Error States**: Displays error messages with retry functionality
- **Network Errors**: Handles API failures gracefully
- **Validation**: Validates API responses and data integrity

## Performance Considerations

- **Debounced Filtering**: Prevents excessive API calls
- **Memoized Hooks**: Uses React.useCallback for performance
- **Efficient Rendering**: Only re-renders when necessary
- **Pagination**: Loads data in chunks to improve performance

## Dependencies

- React 18+
- TypeScript 4.5+
- CSS Modules support
- Fetch API (or polyfill)

## Browser Support

- Modern browsers with ES6+ support
- IE11+ with appropriate polyfills

## Contributing

When modifying the component:

1. Update types in `types.ts`
2. Add new hooks in `hooks.ts`
3. Extend utilities in `utils.ts`
4. Update API functions in `api.ts`
5. Maintain component separation
6. Add proper TypeScript types
7. Update this README

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Check if auth token is valid
2. **API Connection**: Verify backend endpoint is accessible
3. **CORS Issues**: Ensure backend has proper CORS configuration
4. **Data Format**: Verify API response matches expected structure

### Debug Mode

Enable debug logging by setting environment variable:
```bash
NEXT_PUBLIC_DEBUG=true
```

## License

This component is part of the Janssen CRM system.
