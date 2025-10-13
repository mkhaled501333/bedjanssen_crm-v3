// API service for customer data functionality

import type { CustomerDetailsResponse, Governorate } from './types';
import { authFetch, getApiBaseUrl } from '../../shared/utils';
import { getCurrentUserId } from '../../shared/utils/auth';

const getApiBaseURL = () => getApiBaseUrl();

export async function getGovernoratesWithCities(): Promise<Governorate[]> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/masterdata/governorates-with-cities`,
      {
        method: 'GET',
      }
    );
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Governorates API error:', error);
    throw error;
  }
}

export async function addCustomerPhone(
  customerId: string,
  phoneData: {
    phone: string;
    phone_type: number;
    company_id: number;
    created_by: number;
  }
): Promise<unknown> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/customers/id/${customerId}/phones`,
      {
        method: 'POST',
        body: JSON.stringify(phoneData),
      }
    );
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Add phone API error:', error);
    throw error;
  }
}

export async function updateCustomerPhone(
  customerId: string,
  phoneId: number,
  phone: string
): Promise<unknown> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/customers/id/${customerId}/phones/${phoneId}`,
      {
        method: 'PUT',
        body: JSON.stringify({ phone }),
      }
    );
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Update phone API error:', error);
    throw error;
  }
}

export async function deleteCustomerPhone(
  customerId: string,
  phoneId: number
): Promise<void> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/customers/id/${customerId}/phones/${phoneId}`,
      {
        method: 'DELETE',
      }
    );
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
  } catch (error) {
    console.error('Delete phone API error:', error);
    throw error;
  }
}

export async function getCustomerDetails(customerId: string): Promise<CustomerDetailsResponse> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/customers/id/${customerId}`,
      {
        method: 'GET',
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data: CustomerDetailsResponse = await response.json();
    
    if (!data.success) {
      throw new Error(data.message || 'Failed to fetch customer details');
    }

    return data;

  } catch (error) {
    console.error('Customer details API error:', error);
    throw error;
  }
}

export async function updateCustomerDetails(
  customerId: string, 
  updates: {
    name?: string;
    address?: string;
    notes?: string;
    governorateId?: number;
    cityId?: number;
  }
): Promise<CustomerDetailsResponse> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/customers/id/${customerId}`,
      {
        method: 'PUT',
        body: JSON.stringify(updates),
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data: CustomerDetailsResponse = await response.json();
    
    if (!data.success) {
      throw new Error(data.message || 'Failed to update customer details');
    }

    return data;

  } catch (error) {
    console.error('Customer update API error:', error);
    throw error;
  }
}

export async function addTicketCall(
  ticketId: string,
  callData: {
    companyId: number;
    callType: string;
    callCatId: number;
    description: string;
    callNotes?: string;
    callDuration?: string;
    createdBy: number;
  }
): Promise<unknown> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/tickets/${ticketId}/calls`,
      {
        method: 'POST',
        body: JSON.stringify(callData),
      }
    );
    if (!response.ok) {
      const errorBody = await response.json();
      throw new Error(errorBody.message || `HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Add ticket call API error:', error);
    throw error;
  }
}

export async function addCustomerCall(
  customerId: string,
  callData: {
    companyId: number;
    callType: string;
    categoryId: number;
    description: string;
    notes?: string;
    callDuration?: number | string;
    createdBy: number;
  }
): Promise<unknown> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/customers/id/${customerId}/calls`,
      {
        method: 'POST',
        body: JSON.stringify(callData),
      }
    );
    if (!response.ok) {
      const errorBody = await response.json();
      throw new Error(errorBody.message || `HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Add call API error:', error);
    throw error;
  }
}

export async function addTicketItem(
  ticketId: string,
  itemData: {
    companyId: number;
    productId: number;
    quantity: number;
    createdBy: number;
    product_size?: string;
    purchase_date: string;
    purchase_location?: string;
    request_reason_id: number;
    request_reason_detail?: string;
  }
): Promise<unknown> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/tickets/${ticketId}/items`,
      {
        method: 'POST',
        body: JSON.stringify(itemData),
      }
    );
    if (!response.ok) {
      const errorBody = await response.json();
      throw new Error(errorBody.message || `HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Add ticket item API error:', error);
    throw error;
  }
}

export async function getCallCategories(): Promise<{ id: number; name: string }[]> {
  try {
    const response = await authFetch(`${getApiBaseURL()}/api/masterdata/call-categories`);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const result = await response.json();
    if (!result.success) {
      throw new Error(result.message || 'Failed to fetch call categories');
    }
    return result.data;
  } catch (error) {
    console.error('Get call categories API error:', error);
    throw error;
  }
}

export const getTicketCategories = async () => {
  try {
    const response = await authFetch(`${getApiBaseURL()}/api/masterdata/ticket-categories`);
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const result = await response.json();
    if (!result.success) {
      throw new Error(result.message || 'Failed to fetch ticket categories');
    }
    return result.data;
  } catch (error) {
    console.error('Get ticket categories API error:', error);
    throw error;
  }
};

export async function closeTicket(ticketId: string, closingNotes: string, closedBy: number): Promise<void> {
  const response = await authFetch(`${getApiBaseURL()}/api/tickets/${ticketId}/close`, {
    method: 'PUT',
    body: JSON.stringify({ closingNotes, closedBy }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({ message: 'Failed to close ticket' }));
    throw new Error(errorData.message);
  }
}

export async function updateTicketCategory(ticketId: string, categoryId: number): Promise<void> {
  const response = await authFetch(`${getApiBaseURL()}/api/tickets/${ticketId}/category`, {
    method: 'PUT',
    body: JSON.stringify({ ticketCatId: categoryId }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({ message: 'Failed to update ticket category' }));
    throw new Error(errorData.message);
  }
}

export async function updateTicketPrintingNotes(ticketId: string, printingNotes: string): Promise<void> {
  const response = await authFetch(`${getApiBaseURL()}/api/tickets/${ticketId}/printing-notes`, {
    method: 'PUT',
    body: JSON.stringify({ printingNotes }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({ message: 'Failed to update ticket printing notes' }));
    throw new Error(errorData.message);
  }
}

export const getManufacturers = async () => {
  // FIXME: Update with the correct endpoint
  const response = await authFetch('/api/masterdata/manufacturers');
  if (!response.ok) {
    throw new Error('Failed to fetch manufacturers');
  }
  return response.json();
};

export const getProductsByManufacturer = async (manufacturerId: string) => {
  // FIXME: Update with the correct endpoint
  const response = await authFetch(`/api/masterdata/products?manufacturerId=${manufacturerId}`);
  if (!response.ok) {
    throw new Error('Failed to fetch products');
  }
  return response.json();
};

export const getRequestReasons = async () => {
  // FIXME: Update with the correct endpoint
  const response = await authFetch('/api/masterdata/request-reasons');
  if (!response.ok) {
    throw new Error('Failed to fetch request reasons');
  }
  return response.json();
};

export async function addCustomerTicket(
  newTicket: Record<string, unknown>
): Promise<unknown> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/tickets`,
      {
        method: 'POST',
        body: JSON.stringify(newTicket),
      }
    );
    if (!response.ok) {
      const errorBody = await response.json();
      throw new Error(errorBody.message || `HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Add ticket API error:', error);
    throw error;
  }
}

export async function updateTicketItemInspection(
  itemId: string,
  inspectionData: {
    inspected?: boolean;
    inspectionDate?: string;
    inspectionResult?: string;
  }
): Promise<unknown> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/ticket-items/${itemId}/inspection`,
      {
        method: 'PUT',
        body: JSON.stringify(inspectionData),
      }
    );
    if (!response.ok) {
      const errorBody = await response.json();
      throw new Error(errorBody.message || `HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Update inspection API error:', error);
    throw error;
  }
}

export async function addMaintenance(itemId: string, data: Record<string, unknown>): Promise<unknown> {
  const response = await authFetch(`${getApiBaseURL()}/api/ticket-items/${itemId}/maintenance`, {
    method: 'POST',
    body: JSON.stringify(data),
  });
  if (!response.ok) {
    const errorBody = await response.json();
    throw new Error(errorBody.message || 'Failed to add maintenance');
  }
  return response.json();
}

export async function addChangeSame(itemId: string, data: Record<string, unknown>): Promise<unknown> {
  const response = await authFetch(`${getApiBaseURL()}/api/ticket-items/${itemId}/change-same`, {
    method: 'POST',
    body: JSON.stringify(data),
  });
  if (!response.ok) {
    const errorBody = await response.json();
    throw new Error(errorBody.message || 'Failed to add change same');
  }
  return response.json();
}

export async function addChangeAnother(itemId: string, data: Record<string, unknown>): Promise<unknown> {
  const response = await authFetch(`${getApiBaseURL()}/api/ticket-items/${itemId}/change-another`, {
    method: 'POST',
    body: JSON.stringify(data),
  });
  if (!response.ok) {
    const errorBody = await response.json();
    throw new Error(errorBody.message || 'Failed to add change another');
  }
  return response.json();
}

export async function deleteMaintenance(itemId: string): Promise<unknown> {
    const userId = getCurrentUserId();
    if (!userId) {
        throw new Error('User not authenticated');
    }

    const response = await authFetch(`${getApiBaseURL()}/api/ticket-items/${itemId}/maintenance`, {
        method: 'DELETE',
        body: JSON.stringify({ userId }),
    });
    if (!response.ok) {
        const errorBody = await response.json();
        throw new Error(errorBody.message || 'Failed to delete maintenance');
    }
    return response.json();
}

export async function deleteChangeSame(itemId: string): Promise<unknown> {
    const userId = getCurrentUserId();
    if (!userId) {
        throw new Error('User not authenticated');
    }

    const response = await authFetch(`${getApiBaseURL()}/api/ticket-items/${itemId}/change-same`, {
        method: 'DELETE',
        body: JSON.stringify({ userId }),
    });
    if (!response.ok) {
        const errorBody = await response.json();
        throw new Error(errorBody.message || 'Failed to delete change-same');
    }
    return response.json();
}

export async function deleteChangeAnother(itemId: string): Promise<unknown> {
    const userId = getCurrentUserId();
    if (!userId) {
        throw new Error('User not authenticated');
    }

    const response = await authFetch(`${getApiBaseURL()}/api/ticket-items/${itemId}/change-another`, {
        method: 'DELETE',
        body: JSON.stringify({ userId }),
    });
    if (!response.ok) {
        const errorBody = await response.json();
        throw new Error(errorBody.message || 'Failed to delete change-another');
    }
    return response.json();
}

export async function updateMaintenance(itemId: string, data: Record<string, unknown>): Promise<unknown> {
  const response = await authFetch(`${getApiBaseURL()}/api/ticket-items/${itemId}/maintenance`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
  if (!response.ok) {
    const errorBody = await response.json();
    throw new Error(errorBody.message || 'Failed to update maintenance');
  }
  return response.json();
}

export async function updateChangeSame(itemId: string, data: Record<string, unknown>): Promise<unknown> {
  const response = await authFetch(`${getApiBaseURL()}/api/ticket-items/${itemId}/change-same`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
  if (!response.ok) {
    const errorBody = await response.json();
    throw new Error(errorBody.message || 'Failed to update change-same');
  }
  return response.json();
}

export async function updateChangeAnother(itemId: string, data: Record<string, unknown>): Promise<unknown> {
  const response = await authFetch(`${getApiBaseURL()}/api/ticket-items/${itemId}/change-another`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
  if (!response.ok) {
    const errorBody = await response.json();
    throw new Error(errorBody.message || 'Failed to update change-another');
  }
  return response.json();
}

// API functions for creating customers with call or ticket
export async function createCustomerWithCall(customerData: Record<string, unknown>): Promise<unknown> {
  try {
    const response = await authFetch(`${getApiBaseURL()}/api/customers/with-call`, {
      method: 'POST',
      body: JSON.stringify(customerData),
    });
    
    if (!response.ok) {
      const errorBody = await response.json().catch(() => ({ message: 'Failed to create customer with call' }));
      throw new Error(errorBody.message || `HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Create customer with call API error:', error);
    throw error;
  }
}

export async function createCustomerWithTicket(customerData: Record<string, unknown>): Promise<unknown> {
  try {
    const response = await authFetch(`${getApiBaseURL()}/api/customers/with-ticket`, {
      method: 'POST',
      body: JSON.stringify(customerData),
    });
    
    if (!response.ok) {
      const errorBody = await response.json().catch(() => ({ message: 'Failed to create customer with ticket' }));
      throw new Error(errorBody.message || `HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Create customer with ticket API error:', error);
    throw error;
  }
}

export async function updateTicketItem(
  ticketId: string,
  itemId: string,
  itemData: {
    companyId?: number;
    productId?: number;
    quantity?: number;
    product_size?: string;
    purchase_date?: string;
    purchase_location?: string;
    request_reason_id?: number;
    request_reason_detail?: string;
  }
): Promise<unknown> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/tickets/${ticketId}/items/${itemId}`,
      {
        method: 'PUT',
        body: JSON.stringify(itemData),
      }
    );
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Update ticket item API error:', error);
    throw error;
  }
}

export async function deleteTicketItem(
  ticketId: string,
  itemId: string
): Promise<unknown> {
  try {
    const response = await authFetch(
      `${getApiBaseURL()}/api/tickets/${ticketId}/items/${itemId}`,
      {
        method: 'DELETE',
      }
    );
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Delete ticket item API error:', error);
    throw error;
  }
}