import { storage } from './index';

// User interface matching the backend response
export interface User {
  id: number;
  username: string;
  name: string;
  company_id: number;
  company_name?: string;
  permissions?: number[];
}

/**
 * Get the current authenticated user from localStorage
 * @returns User object or null if not authenticated
 */
export function getCurrentUser(): User | null {
  return storage.get<User>('user');
}

/**
 * Get the current user's company ID
 * @returns Company ID or null if not authenticated
 */
export function getCurrentUserCompanyId(): number | null {
  const user = getCurrentUser();
  return user?.company_id || null;
}

/**
 * Get the current user's ID
 * @returns User ID or null if not authenticated
 */
export function getCurrentUserId(): number | null {
  const user = getCurrentUser();
  return user?.id || null;
}

/**
 * Check if user is authenticated
 * @returns boolean indicating authentication status
 */
export function isAuthenticated(): boolean {
  const token = storage.get<string>('token');
  const user = getCurrentUser();
  return !!(token && user);
}

/**
 * Get the current user's name
 * @returns User name or null if not authenticated
 */
export function getCurrentUserName(): string | null {
  const user = getCurrentUser();
  return user?.name || null;
}

/**
 * Get the current user's company name
 * @returns Company name or null if not available
 */
export function getCurrentUserCompanyName(): string | null {
  const user = getCurrentUser();
  return user?.company_name || null;
}

/**
 * Check if the current user has a specific permission
 * @param permissionId The permission ID to check
 * @returns boolean indicating if user has the permission
 */
export function hasPermission(permissionId: number): boolean {
  const user = getCurrentUser();
  return user?.permissions?.includes(permissionId) || false;
}

/**
 * Check if the current user has any of the specified permissions
 * @param permissionIds Array of permission IDs to check
 * @returns boolean indicating if user has any of the permissions
 */
export function hasAnyPermission(permissionIds: number[]): boolean {
  const user = getCurrentUser();
  if (!user?.permissions) return false;
  return permissionIds.some(id => user.permissions!.includes(id));
}

/**
 * Get the current user's permissions
 * @returns Array of permission IDs or empty array if not authenticated
 */
export function getCurrentUserPermissions(): number[] {
  const user = getCurrentUser();
  return user?.permissions || [];
}