# Current Agent Report

A comprehensive report component for displaying the current agent's call activity and performance metrics.

## Features

- **Summary Tab**: Overview of key metrics including total calls, duration, categories, and call type distribution
- **Calls Tab**: Detailed list of all calls with search and filtering capabilities
- **Activity Tab**: Daily activity charts and insights showing call patterns over time

## Components

### Main Components

- `CurrentAgentReport.tsx` - Main report component with tabs and controls
- `SummaryTab.tsx` - Summary statistics and metrics overview
- `CallsTab.tsx` - Detailed calls list with search and filters
- `ActivityTab.tsx` - Daily activity charts and insights

### Supporting Files

- `types.ts` - TypeScript interfaces and types
- `api.ts` - API functions for data fetching and export
- `hooks/useCurrentAgentReport.ts` - Custom hook for state management

## Usage

```tsx
import { CurrentAgentReport } from '@/features/reports/reports/current-agent';

function MyPage() {
  return (
    <div>
      <CurrentAgentReport />
    </div>
  );
}
```

## API Integration

The component integrates with the backend API endpoint:
- `GET /api/reports/currentagent` - Fetches agent call data

### Required Parameters

- `userId` (number): The ID of the agent
- `startDate` (string): Start date in YYYY-MM-DD format
- `endDate` (string): End date in YYYY-MM-DD format

### Response Format

```json
{
  "success": true,
  "data": {
    "userId": 123,
    "startDate": "2024-01-01",
    "endDate": "2024-01-31",
    "totalCalls": 25,
    "customerCalls": 15,
    "ticketCalls": 10,
    "calls": [...]
  }
}
```

## Features

### Summary Tab
- Total calls, customer calls, and ticket calls
- Total and average call duration
- Incoming vs outgoing call distribution
- Top call categories with percentages
- Visual progress bars and statistics cards

### Calls Tab
- Searchable list of all calls
- Filter by call type (customer/ticket) and direction (incoming/outgoing)
- Detailed call information including customer details, duration, and notes
- Color-coded call types and directions

### Activity Tab
- Daily activity overview with key metrics
- Interactive bar chart showing calls and duration by day
- Daily breakdown table
- Activity insights (busiest day, longest day, most efficient day)

## Styling

The component uses CSS modules for styling:
- `CurrentAgentReport.module.css` - Main component styles
- `SummaryTab.module.css` - Summary tab styles
- `CallsTab.module.css` - Calls tab styles
- `ActivityTab.module.css` - Activity tab styles

## Dependencies

- `date-fns` - Date formatting and manipulation
- `lucide-react` - Icons
- React hooks for state management

## Customization

The component can be customized by:
- Modifying the CSS modules for styling changes
- Extending the types for additional data fields
- Adding new tabs or modifying existing ones
- Customizing the API integration for different data sources

## Future Enhancements

- Export functionality (PDF, Excel, CSV)
- Real-time data updates
- Advanced filtering options
- Performance analytics
- Call quality metrics
- Integration with other agent activities (tickets, tasks, etc.) 