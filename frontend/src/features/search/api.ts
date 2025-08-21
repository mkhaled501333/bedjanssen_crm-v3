// Simple API service for search functionality

import type { SearchSuggestion } from './types';
import { authFetch, getApiBaseUrl } from '../../shared/utils';

const getApiBaseURL = () => getApiBaseUrl();

export interface CustomerSearchResult {
  id: number;
  name: string;
  company?: string;
  phones: string[];
}

export interface CustomerSearchResponse {
  success: boolean;
  data: {
    customers: CustomerSearchResult[];
    total: number;
    query: string;
    type: string;
    limit: number;
  };
  message: string;
}

export async function searchCustomers(query: string, limit: number = 8): Promise<SearchSuggestion[]> {
  try {
    if (!query.trim()) {
      return [];
    }

    const response = await authFetch(
      `${getApiBaseURL()}/api/search/customers?q=${encodeURIComponent(query)}&limit=${limit}`,
      {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data: CustomerSearchResponse = await response.json();
    
    if (!data.success) {
      throw new Error(data.message || 'Search failed');
    }

    // Transform backend response to SearchSuggestion format
    return data.data.customers.map(customer => ({
      id: customer.id.toString(),
      text: customer.name,
      category: customer.company || 'Customer',
      description: customer.phones.length > 0 ? customer.phones.join(', ') : undefined,
    }));

  } catch (error) {
    console.error('Search API error:', error);
    // Return empty array on error - don't break the UI
    return [];
  }
}