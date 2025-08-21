// Current Agent Report Types

export interface AgentCall {
  id: number;
  type: 'customer_call' | 'ticket_call';
  companyId: number;
  customerId?: number;
  customerName: string;
  customerPhone: string;
  callType: 'incoming' | 'outgoing';
  categoryId?: number;
  callCatId?: number;
  category: string;
  description: string;
  callNotes: string;
  callDuration: number;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
  // Ticket-specific fields
  ticketId?: number;
  ticketNumber?: string;
  ticketTitle?: string;
}

export interface CurrentAgentData {
  userId: number;
  startDate: string;
  endDate: string;
  totalCalls: number;
  customerCalls: number;
  ticketCalls: number;
  calls: AgentCall[];
  // Summary statistics
  summary: {
    totalDuration: number;
    averageDuration: number;
    incomingCalls: number;
    outgoingCalls: number;
    topCategories: Array<{
      category: string;
      count: number;
      percentage: number;
    }>;
    dailyActivity: Array<{
      date: string;
      calls: number;
      duration: number;
    }>;
  };
}

export interface CurrentAgentProps {
  data?: CurrentAgentData;
  loading?: boolean;
  error?: string;
  onRefresh?: () => void;
  onExport?: () => void;
  onDateRangeChange?: (startDate: string, endDate: string) => void;
}

export interface CurrentAgentTabProps {
  data: CurrentAgentData;
  loading?: boolean;
}

export interface CallFilters {
  userId: number;
  startDate: string;
  endDate: string;
  callType?: 'incoming' | 'outgoing' | 'all';
  category?: string;
  type?: 'customer_call' | 'ticket_call' | 'all';
} 