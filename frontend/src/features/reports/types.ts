// Reports module types

export interface ReportData {
  id: string;
  name: string;
  description: string;
  type: ReportType;
  data: unknown[];
  createdAt: string;
  updatedAt: string;
}

export type ReportType = 
  | 'tickets-summary'
  | 'tickets-by-status'
  | 'tickets-by-agent'
  | 'customer-activity'
  | 'current-agent'
  | 'product-performance'
  | 'monthly-trends'
  | 'employee-report'
  | 'tickets-display'
  | 'tickets-report'
  | 'agent-call-logs';

export interface ReportFilter {
  dateRange?: {
    start: string;
    end: string;
  };
  status?: string[];
  agents?: string[];
  categories?: string[];
}

export interface ReportConfig {
  id: string;
  name: string;
  icon: string;
  description: string;
  type: ReportType;
  hasSubtabs?: boolean;
  subtabs?: ReportSubtab[];
}

export interface ReportSubtab {
  id: string;
  name: string;
  icon: string;
  component: string;
}

export interface ReportsProps {
  onClose?: () => void;
}