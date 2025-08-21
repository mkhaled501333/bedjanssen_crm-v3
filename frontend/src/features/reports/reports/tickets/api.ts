// Tickets Report API functions

import type { TicketsReportData, TicketsFilters } from './types';
import { authFetch, getApiBaseUrl } from '@/shared/utils';

export interface Company {
  id: number;
  name: string;
}

export async function getCompanies(): Promise<Company[]> {
  try {
    const response = await authFetch(`${getApiBaseUrl()}/api/masterdata/companies`, {
      method: 'GET',
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch companies: ${response.statusText}`);
    }

    const result = await response.json();
    
    if (!result.success) {
      throw new Error(result.message || 'Failed to fetch companies');
    }

    return result.data;
  } catch (error) {
    console.error('Error fetching companies:', error);
    throw error;
  }
}

export async function getTicketsReport(filters: TicketsFilters, page: number = 1, limit: number = 10): Promise<TicketsReportData> {
  try {
    const queryParams = new URLSearchParams({
      companyId: filters.companyId.toString(),
      page: page.toString(),
      limit: limit.toString(),
    });

    // Add optional filters
    if (filters.status) {
      queryParams.append('status', filters.status);
    }
    if (filters.priority) {
      queryParams.append('priority', filters.priority);
    }
    if (filters.categoryId) {
      queryParams.append('categoryId', filters.categoryId.toString());
    }
    if (filters.customerId) {
      queryParams.append('customerId', filters.customerId.toString());
    }
    if (filters.startDate) {
      queryParams.append('startDate', filters.startDate);
    }
    if (filters.endDate) {
      queryParams.append('endDate', filters.endDate);
    }
    if (filters.searchTerm) {
      queryParams.append('searchTerm', filters.searchTerm);
    }

    const response = await authFetch(`${getApiBaseUrl()}/api/reports/tickets?${queryParams}`, {
      method: 'GET',
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch tickets report: ${response.statusText}`);
    }

    const result = await response.json();
    
    if (!result.success) {
      throw new Error(result.message || 'Failed to fetch tickets report');
    }

    return result.data;
  } catch (error) {
    console.error('Error fetching tickets report:', error);
    throw error;
  }
}

export async function exportTicketsReport(
  filters: TicketsFilters, 
  format: 'pdf' | 'excel' | 'csv'
): Promise<Blob> {
  try {
    const queryParams = new URLSearchParams({
      companyId: filters.companyId.toString(),
      format: format
    });

    // Add optional filters
    if (filters.status) {
      queryParams.append('status', filters.status);
    }
    if (filters.priority) {
      queryParams.append('priority', filters.priority);
    }
    if (filters.categoryId) {
      queryParams.append('categoryId', filters.categoryId.toString());
    }
    if (filters.customerId) {
      queryParams.append('customerId', filters.customerId.toString());
    }
    if (filters.startDate) {
      queryParams.append('startDate', filters.startDate);
    }
    if (filters.endDate) {
      queryParams.append('endDate', filters.endDate);
    }
    if (filters.searchTerm) {
      queryParams.append('searchTerm', filters.searchTerm);
    }

    const response = await authFetch(`${getApiBaseUrl()}/api/reports/tickets/export?${queryParams}`, {
      method: 'GET',
    });

    if (!response.ok) {
      throw new Error(`Failed to export tickets report: ${response.statusText}`);
    }

    return await response.blob();
  } catch (error) {
    console.error('Error exporting tickets report:', error);
    throw error;
  }
}