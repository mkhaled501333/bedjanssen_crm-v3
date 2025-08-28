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
  client_approval: boolean;
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
  customers: FilterOption[];
  tickets: FilterOption[];
  ticket_categories: FilterOption[];
  ticket_statuses: FilterOption[];
  products: FilterOption[];
  request_reasons: FilterOption[];
  actions: FilterOption[];
}

export interface AppliedFilters {
  companyId: number;
  customerIds?: number[];
  governomateIds?: number[];
  cityIds?: number[];
  ticketIds?: number[];
  companyIds?: number[];
  ticketCatIds?: number[];
  ticketStatus?: string;
  productIds?: number[];
  requestReasonIds?: number[];
  inspected?: boolean;
  inspectionDateFrom?: string;
  inspectionDateTo?: string;
  action?: string;
  pulledStatus?: boolean;
  deliveredStatus?: boolean;
  clientApproval?: boolean;
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
  [column: string]: string[];
}

export interface FilterDropdownState {
  [column: string]: boolean;
}
