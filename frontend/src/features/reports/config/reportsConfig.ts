// Reports configuration
import { ReportConfig } from '../types';

export const AVAILABLE_REPORTS: ReportConfig[] = [
  {
    id: 'current-agent',
    name: 'Current Agent Report',
    icon: '👤',
    description: 'View detailed call activity and performance metrics for the current agent',
    type: 'current-agent',
    hasSubtabs: true,
    subtabs: [
      {
        id: 'summary',
        name: 'Summary',
        icon: '📊',
        component: 'SummaryTab'
      },
      {
        id: 'calls',
        name: 'Calls',
        icon: '📞',
        component: 'CallsTab'
      },
      {
        id: 'activity',
        name: 'Activity',
        icon: '📈',
        component: 'ActivityTab'
      }
    ]
  },
  {
    id: 'tickets-report',
    name: 'Tickets Report',
    icon: '🎫',
    description: 'Detailed tickets report with pagination, filtering, and export capabilities',
    type: 'tickets-report',
    hasSubtabs: false
  }
];

export function getReportById(id: string): ReportConfig | undefined {
  return AVAILABLE_REPORTS.find(report => report.id === id);
}

export function getReportsByType(type: string): ReportConfig[] {
  return AVAILABLE_REPORTS.filter(report => report.type === type);
}