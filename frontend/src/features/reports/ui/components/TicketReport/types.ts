export interface TicketItem {
  ticket_item_id: number;
  customer_id: number;
  customer_name: string;
  governomate_id: number;
  governorate_name: string;
  city_id: number;
  city_name: string;
  ticket_id: number;
  company_id: number;
  ticket_cat_id: number;
  ticket_category_name: string;
  ticket_status: string;
  product_id: number;
  product_name: string;
  product_size: string;
  request_reason_id: number;
  request_reason_name: string;
  inspected: boolean;
  inspection_date: string | null;
  ticket_created_at: string | null;
  client_approval: number;
  action: string;
  pulled_status: boolean;
  delivered_status: boolean;
}

export interface FilterOption {
  id: number | string;
  name: string;
}

export interface AvailableFilters {
  governorates: FilterOption[];
  cities: FilterOption[];
  ticket_categories: FilterOption[];
  ticket_statuses: FilterOption[];
  products: FilterOption[];
  request_reasons: FilterOption[];
  actions: FilterOption[];
}

export interface AppliedFilters {
  companyId: number;
  governomateIds?: number[];
  cityIds?: number[];
  ticketCatIds?: number[];
  ticketStatus?: string;
  productIds?: number[];
  requestReasonIds?: number[];
  inspected?: boolean;
  inspectionDateFrom?: string;
  inspectionDateTo?: string;
  ticketCreatedDateFrom?: string;
  ticketCreatedDateTo?: string;
  actions?: string[];
  pulledStatus?: boolean;
  deliveredStatus?: boolean;
  clientApproval?: number[];
}

export interface FilterSummary {
  total_applied_filters: number;
  active_filters: string[];
}

export interface PaginationInfo {
  page: number;
  limit: number;
  total: number;
  total_pages: number;
  has_next: boolean;
  has_previous: boolean;
}

export interface ReportData {
  ticket_items: TicketItem[];
  pagination: PaginationInfo;
}

export interface TicketItemsReportResponse {
  success: boolean;
  data: {
    available_filters: AvailableFilters;
    applied_filters: AppliedFilters;
    filter_summary: FilterSummary;
    report_data: ReportData;
  };
  error?: string;
}

export interface TicketItemsReportRequest {
  filters: AppliedFilters;
  page: number;
  limit: number;
}

export interface ColumnMapping {
  [key: string]: keyof TicketItem;
}

export interface FilterState {
  [column: string]: FilterValue;
}

export interface FilterDropdownState {
  [column: string]: boolean;
}

export type FilterValue = 
  | string[] 
  | string 
  | boolean 
  | DateRange 
  | null;

export interface DateRange {
  from: Date | null;
  to: Date | null;
}

export interface FilterConfig {
  column: string;
  filterType: 'multiSelect' | 'text' | 'boolean' | 'dateRange' | 'radio';
  backendKey: string;
  dataType: 'string' | 'number' | 'boolean' | 'date';
}

export const COLUMN_FILTER_CONFIG: FilterConfig[] = [
  { column: 'Status', filterType: 'radio', backendKey: 'ticketStatus', dataType: 'string' },
  { column: 'Governorate', filterType: 'multiSelect', backendKey: 'governomateIds', dataType: 'number' },
  { column: 'City', filterType: 'multiSelect', backendKey: 'cityIds', dataType: 'number' },
  { column: 'Category', filterType: 'multiSelect', backendKey: 'ticketCatIds', dataType: 'number' },
  { column: 'Product', filterType: 'multiSelect', backendKey: 'productIds', dataType: 'number' },
  { column: 'Size', filterType: 'text', backendKey: 'productSize', dataType: 'string' },
  { column: 'Request Reason', filterType: 'multiSelect', backendKey: 'requestReasonIds', dataType: 'number' },
  { column: 'Inspected', filterType: 'boolean', backendKey: 'inspected', dataType: 'boolean' },
  { column: 'Inspection Date', filterType: 'dateRange', backendKey: 'inspectionDate', dataType: 'date' },
  { column: 'Ticket Creation Date', filterType: 'dateRange', backendKey: 'ticketCreatedDate', dataType: 'date' },
  { column: 'Client Approval', filterType: 'multiSelect', backendKey: 'clientApproval', dataType: 'number' },
  { column: 'Action', filterType: 'multiSelect', backendKey: 'actions', dataType: 'string' },
  { column: 'Pulled Status', filterType: 'radio', backendKey: 'pulledStatus', dataType: 'boolean' },
  { column: 'Delivered Status', filterType: 'radio', backendKey: 'deliveredStatus', dataType: 'boolean' },
];
