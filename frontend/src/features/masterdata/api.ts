import type { Governorate, TicketCategory, City, CallCategory, RequestReason, Product, Company, User, UserCreateRequest, UserUpdateRequest } from './types';
import { authFetch, getApiBaseUrl } from '../../shared/utils';

const getApiBaseURL = () => getApiBaseUrl();

// Governorates
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

export async function getGovernorates(): Promise<Governorate[]> {
  try {
    const response = await authFetch(`${getApiBaseURL()}/api/masterdata/governorates`, {
      method: 'GET',
    });
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const result = await response.json();
    return result.data || result;
  } catch (error) {
    console.error('Get governorates API error:', error);
    throw error;
  }
}

export async function createGovernorate(name: string): Promise<Governorate> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/governorates`, {
    method: 'POST',
    body: JSON.stringify({ name }),
  });
  if (!response.ok) {
    throw new Error('Failed to create governorate');
  }
  const result = await response.json();
  return result.data || result;
}

export async function updateGovernorate(id: number, name: string): Promise<Governorate> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/governorates/${id}`, {
    method: 'PUT',
    body: JSON.stringify({ name }),
  });
  if (!response.ok) {
    throw new Error('Failed to update governorate');
  }
  const result = await response.json();
  return result.data || result;
}

export async function deleteGovernorate(id: number): Promise<void> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/governorates/${id}`, {
    method: 'DELETE',
  });
  if (!response.ok) {
    throw new Error('Failed to delete governorate');
  }
}

// Cities
export async function getCities(governorateId?: number): Promise<City[]> {
  try {
    const url = governorateId 
      ? `${getApiBaseURL()}/api/masterdata/cities?governorateId=${governorateId}`
      : `${getApiBaseURL()}/api/masterdata/cities`;
    const response = await authFetch(url, { method: 'GET' });
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const result = await response.json();
    return result.data || result;
  } catch (error) {
    console.error('Get cities API error:', error);
    throw error;
  }
}

export async function createCity(name: string, governorateId: number): Promise<City> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/cities`, {
    method: 'POST',
    body: JSON.stringify({ name, governorate_id: governorateId }),
  });
  if (!response.ok) {
    throw new Error('Failed to create city');
  }
  const result = await response.json();
  return result.data || result;
}

export async function updateCity(id: number, name: string, governorateId: number): Promise<City> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/cities/${id}`, {
    method: 'PUT',
    body: JSON.stringify({ name, governorate_id: governorateId }),
  });
  if (!response.ok) {
    throw new Error('Failed to update city');
  }
  const result = await response.json();
  return result.data || result;
}

export async function deleteCity(id: number): Promise<void> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/cities/${id}`, {
    method: 'DELETE',
  });
  if (!response.ok) {
    throw new Error('Failed to delete city');
  }
}

// Call Categories
export async function getCallCategories(): Promise<CallCategory[]> {
  try {
    const response = await authFetch(`${getApiBaseURL()}/api/masterdata/call-categories`, { method: 'GET' });
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

export async function createCallCategory(name: string, description?: string): Promise<CallCategory> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/call-categories`, {
    method: 'POST',
    body: JSON.stringify({ name, description }),
  });
  if (!response.ok) {
    throw new Error('Failed to create call category');
  }
  const result = await response.json();
  return result.data || result;
}

export async function updateCallCategory(id: number, data: { name?: string; description?: string; active?: boolean }): Promise<CallCategory> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/call-categories/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
  if (!response.ok) {
    throw new Error('Failed to update call category');
  }
  const result = await response.json();
  return result.data || result;
}

export async function deleteCallCategory(id: number): Promise<void> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/call-categories/${id}`, {
    method: 'DELETE',
  });
  if (!response.ok) {
    throw new Error('Failed to delete call category');
  }
}

// Ticket Categories
export const getTicketCategories = async (): Promise<TicketCategory[]> => {
  try {
    const response = await authFetch(`${getApiBaseURL()}/api/masterdata/ticket-categories`, { method: 'GET' });
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

export const addTicketCategory = async (name: string): Promise<TicketCategory> => {
    const response = await authFetch(`${getApiBaseURL()}/api/masterdata/ticket-categories`, {
      method: 'POST',
      body: JSON.stringify({ name, created_by: 1, company_id: 1 }),
    });
    if (!response.ok) {
      throw new Error('Failed to add ticket category');
    }
    return response.json();
};

export const updateTicketCategory = async (id: number, name: string): Promise<TicketCategory> => {
    const response = await authFetch(`${getApiBaseURL()}/api/masterdata/ticket-categories/${id}`, {
        method: 'PUT',
        body: JSON.stringify({ name }),
    });
    if (!response.ok) {
        throw new Error('Failed to update ticket category');
    }
    return response.json();
};

export async function deleteTicketCategory(id: number): Promise<void> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/ticket-categories/${id}`, {
    method: 'DELETE',
  });
  if (!response.ok) {
    throw new Error('Failed to delete ticket category');
  }
}

// Request Reasons
export const getRequestReasons = async (): Promise<RequestReason[]> => {
  try {
    const response = await authFetch(`${getApiBaseURL()}/api/masterdata/request-reasons`, { method: 'GET' });
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    const result = await response.json();
    if(!result.success){
        throw new Error(result.message || 'Failed to fetch request reasons');
    }
    return result.data;
  } catch(error) {
    console.error('Get request reasons API error:', error);
    throw error;
  }
};

export async function createRequestReason(name: string): Promise<RequestReason> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/request-reasons`, {
    method: 'POST',
    body: JSON.stringify({ name, created_by: 1, company_id: 1 }),
  });
  if (!response.ok) {
    throw new Error('Failed to create request reason');
  }
  const result = await response.json();
  return result.data || result;
}

export async function updateRequestReason(id: number, name: string): Promise<RequestReason> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/request-reasons/${id}`, {
    method: 'PUT',
    body: JSON.stringify({ name }),
  });
  if (!response.ok) {
    throw new Error('Failed to update request reason');
  }
  const result = await response.json();
  return result.data || result;
}

export async function deleteRequestReason(id: number): Promise<void> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/request-reasons/${id}`, {
    method: 'DELETE',
  });
  if (!response.ok) {
    throw new Error('Failed to delete request reason');
  }
}

// Products
export const getProducts = async (): Promise<Product[]> => {
  try {
    const response = await authFetch(`${getApiBaseURL()}/api/masterdata/products`, { method: 'GET' });
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    const result = await response.json();
    if(!result.success){
        throw new Error(result.message || 'Failed to fetch products');
    }
    return result.data;
  } catch(error) {
    console.error('Get products API error:', error);
    throw error;
  }
};

export async function createProduct(productName: string, companyId: number): Promise<Product> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/products`, {
    method: 'POST',
    body: JSON.stringify({ product_name: productName, company_id: companyId, created_by: 1 }),
  });
  if (!response.ok) {
    throw new Error('Failed to create product');
  }
  const result = await response.json();
  return result.data || result;
}

export async function updateProduct(id: number, productName: string, companyId: number): Promise<Product> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/products/${id}`, {
    method: 'PUT',
    body: JSON.stringify({ product_name: productName, company_id: companyId }),
  });
  if (!response.ok) {
    throw new Error('Failed to update product');
  }
  const result = await response.json();
  return result.data || result;
}

export async function deleteProduct(id: number): Promise<void> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/products/${id}`, {
    method: 'DELETE',
  });
  if (!response.ok) {
    throw new Error('Failed to delete product');
  }
}

// Companies
export const getCompanies = async (): Promise<Company[]> => {
  try {
    const response = await authFetch(`${getApiBaseURL()}/api/masterdata/companies`, { method: 'GET' });
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    const result = await response.json();
    if(!result.success){
        throw new Error(result.message || 'Failed to fetch companies');
    }
    return result.data;
  } catch(error) {
    console.error('Get companies API error:', error);
    throw error;
  }
};

export async function createCompany(name: string): Promise<Company> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/companies`, {
    method: 'POST',
    body: JSON.stringify({ name }),
  });
  if (!response.ok) {
    throw new Error('Failed to create company');
  }
  const result = await response.json();
  return result.data || result;
}

export async function updateCompany(id: number, name: string): Promise<Company> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/companies/${id}`, {
    method: 'PUT',
    body: JSON.stringify({ name }),
  });
  if (!response.ok) {
    throw new Error('Failed to update company');
  }
  const result = await response.json();
  return result.data || result;
}

export async function deleteCompany(id: number): Promise<void> {
  const response = await authFetch(`${getApiBaseURL()}/api/masterdata/companies/${id}`, {
    method: 'DELETE',
  });
  if (!response.ok) {
    throw new Error('Failed to delete company');
  }
}

// Users Management
export async function getUsers(page?: number, limit?: number, search?: string): Promise<{ users: User[], total: number, page: number, limit: number }> {
  try {
    let url = `${getApiBaseURL()}/api/users-management`;
    const params = new URLSearchParams();
    if (page) params.append('page', page.toString());
    if (limit) params.append('limit', limit.toString());
    if (search) params.append('search', search);
    if (params.toString()) url += `?${params.toString()}`;
    
    const response = await authFetch(url, { method: 'GET' });
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('Get users API error:', error);
    throw error;
  }
}

export async function createUser(userData: UserCreateRequest): Promise<User> {
  const response = await authFetch(`${getApiBaseURL()}/api/users-management`, {
    method: 'POST',
    body: JSON.stringify(userData),
  });
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.error || 'Failed to create user');
  }
  return await response.json();
}

export async function getUserById(id: number): Promise<User> {
  const response = await authFetch(`${getApiBaseURL()}/api/users-management/${id}`, {
    method: 'GET',
  });
  if (!response.ok) {
    throw new Error('Failed to get user');
  }
  return await response.json();
}

export async function updateUser(id: number, userData: UserUpdateRequest): Promise<User> {
  const response = await authFetch(`${getApiBaseURL()}/api/users-management/${id}`, {
    method: 'PUT',
    body: JSON.stringify(userData),
  });
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.error || 'Failed to update user');
  }
  return await response.json();
}

// Delete user functionality has been removed for security purposes
// export async function deleteUser(id: number): Promise<void> {
//   const response = await authFetch(`${getApiBaseURL()}/api/users-management/${id}`, {
//     method: 'DELETE',
//   });
//   if (!response.ok) {
//     throw new Error('Failed to delete user');
//   }
// }

export async function getUserPermissions(id: number): Promise<{ permissions: number[] }> {
  const response = await authFetch(`${getApiBaseURL()}/api/users-management/${id}/permissions`, {
    method: 'GET',
  });
  if (!response.ok) {
    throw new Error('Failed to get user permissions');
  }
  return await response.json();
}

export async function updateUserPermissions(id: number, permissions: number[]): Promise<{ permissions: number[] }> {
  const response = await authFetch(`${getApiBaseURL()}/api/users-management/${id}/permissions`, {
    method: 'PUT',
    body: JSON.stringify({ permissions }),
  });
  if (!response.ok) {
    throw new Error('Failed to update user permissions');
  }
  return await response.json();
}

export async function addUserPermissions(id: number, permissions: number[]): Promise<{ permissions: number[] }> {
  const response = await authFetch(`${getApiBaseURL()}/api/users-management/${id}/permissions`, {
    method: 'POST',
    body: JSON.stringify({ permissions }),
  });
  if (!response.ok) {
    throw new Error('Failed to add user permissions');
  }
  return await response.json();
}