// Shared types across the application
export interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'user';
  createdAt: Date;
  updatedAt: Date;
}

export interface ApiResponse<T> {
  data: T;
  message: string;
  success: boolean;
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export interface SearchParams {
  query?: string;
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

// Common error types
export interface AppError {
  code: string;
  message: string;
  details?: unknown;
}

// Navigation types
export interface Tab {
  id: string;
  name: string;
  icon: string;
  type: string;
}

export interface App {
  id: string;
  name: string;
  icon: string;
  gradient: string;
}