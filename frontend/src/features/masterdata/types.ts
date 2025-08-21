export interface TicketCategory {
  id: number;
  name: string;
  created_by?: number;
  company_id?: number;
  created_at?: string;
  updated_at?: string;
  active?: boolean;
}

export interface Governorate {
  id: number;
  name: string;
  cities?: City[];
}

export interface City {
  id: number;
  name: string;
  governorate_id?: number;
}

export interface CallCategory {
  id: number;
  name: string;
  description?: string;
  active?: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface RequestReason {
  id: number;
  name: string;
  created_by?: number;
  company_id?: number;
  created_at?: string;
  updated_at?: string;
  active?: boolean;
}

export interface Product {
  id: number;
  product_name: string;
  company_id?: number;
  created_by?: number;
  created_at?: string;
  updated_at?: string;
  active?: boolean;
}

export interface Company {
  id: number;
  name: string;
  created_at?: string;
  updated_at?: string;
  active?: boolean;
}

export interface User {
  id: number;
  name: string;
  username: string;
  company_id?: number;
  company_name?: string;
  created_by?: number;
  is_active?: boolean;
  permissions?: number[];
  created_at?: string;
  updated_at?: string;
}

export interface UserCreateRequest {
  name: string;
  username: string;
  password: string;
  companyId: number;
  isActive?: boolean;
  permissions?: number[];
}

export interface UserUpdateRequest {
  name?: string;
  username?: string;
  password?: string;
  companyId?: number;
  isActive?: boolean;
  permissions?: number[];
}