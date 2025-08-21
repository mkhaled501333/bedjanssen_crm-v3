// Tickets Report Types

export interface TicketItem {
  id: number;
  productId: number;
  productName: string;
  productSize: string;
  quantity: number;
  purchaseDate: string;
  purchaseLocation: string;
  requestReasonId: number;
  requestReasonName: string;
  requestReasonDetail: string;
  inspected: boolean;
  inspectionDate: string | null;
  inspectionResult: string;
  clientApproval: boolean;
  createdAt: string;
  updatedAt: string;
  companyId?: number; // Optional for backward compatibility
}

export interface Ticket {
  id: number;
  companyId: number;
  customerId: number;
  customerName: string;
  companyName: string;
  governorateName: string;
  cityName: string;
  ticketCatId: number;
  categoryName: string;
  description: string;
  status: 'open' | 'in_progress' | 'closed';
  priority: 'low' | 'medium' | 'high';
  createdBy: number;
  createdByName: string;
  createdAt: string;
  updatedAt: string;
  closedAt: string | null;
  closingNotes: string | null;
  callsCount: number;
  itemsCount: number;
  items: TicketItem[];
}

export interface TicketsPagination {
  currentPage: number;
  totalPages: number;
  totalItems: number;
  itemsPerPage: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

export interface TicketsSummary {
  statusCounts: {
    open: number;
    in_progress: number;
    closed: number;
  };
  priorityCounts: {
    low: number;
    medium: number;
    high: number;
  };
}

export interface TicketsFilters {
  companyId: number;
  status?: 'open' | 'in_progress' | 'closed';
  priority?: 'low' | 'medium' | 'high';
  categoryId?: number;
  customerId?: number;
  startDate?: string;
  endDate?: string;
  searchTerm?: string;
}

export interface TicketsReportData {
  tickets: Ticket[];
  pagination: TicketsPagination;
  summary: TicketsSummary;
  filters: TicketsFilters;
}

export interface TicketsReportProps {
  data?: TicketsReportData;
  loading?: boolean;
  error?: string;
  onRefresh?: () => void;
  onExport?: () => void;
  onFiltersChange?: (filters: TicketsFilters) => void;
}

export interface TicketsTableProps {
  tickets: Ticket[];
  loading?: boolean;
  onTicketClick?: (ticket: Ticket) => void;
}

export interface TicketsFiltersProps {
  filters: TicketsFilters;
  onFiltersChange: (filters: TicketsFilters) => void;
  loading?: boolean;
}