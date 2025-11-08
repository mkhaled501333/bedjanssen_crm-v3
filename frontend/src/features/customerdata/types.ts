// Types for the customer data feature

export interface CustomerPhone {
  id: number;
  phone: string;
  phoneType: string;
  createdAt: string;
}

export interface TicketItem {
  id: number;
  ticketID?: number;
  companyId?: number;
  productId: number;
  productName: string;
  productBrand?: string;
  productSize: string;
  quantity: number;
  purchaseDate: string;
  purchaseLocation: string;
  requestReasonId: number;
  requestReasonName: string;
  requestReasonDetail: string;
  inspected?: boolean;
  inspectionDate?: string;
  inspectionResult?: string;
  actionType?: 'maintenance' | 'change-same' | 'change-another' | null;
  actionFormData?: Record<string, unknown>;
}

export interface CustomerTicket {
  ticketID: number;
  companyId: number;
  ticketCatId: number;
  ticketCat: string;
  description: string;
  status: number;
  priority: string;
  printingNotes?: string;
  closingNotes?: string;
  closedAt?: string;
  closedBy?: string;
  createdBy: string;
  ticketItems: TicketItem[];
  calls: CustomerCall[];
  createdAt: string;
}

export interface CustomerCall {
  id: number;
  companyId: number;
  callType: string;
  category: string;
  description: string;
  notes: string;
  callDuration: string;
  createdBy: string;
  createdAt: string;
}

export interface CustomerDetails {
  id: number;
  companyId: number;
  name: string;
  address: string;
  notes: string;
  governorate: string;
  city: string;
  governorateId?: number;
  cityId?: number;
  phones: CustomerPhone[];
  tickets: CustomerTicket[];
  calls: CustomerCall[];
  createdAt: string;
  updatedAt: string;
}

export interface CustomerDetailsResponse {
  success: boolean;
  data: CustomerDetails;
  message: string;
}

export interface CustomerDataProps {
  customerId: string;
  onClose?: () => void;
}

export interface UseCustomerDataProps {
  customerId: string;
}

export interface CustomerDataState {
  customer: CustomerDetails | null;
  isLoading: boolean;
  error: string | null;
}

export interface City {
  id: number;
  name: string;
  governorate_id: number;
}

export interface Governorate {
  id: number;
  name: string;
  cities: City[];
}