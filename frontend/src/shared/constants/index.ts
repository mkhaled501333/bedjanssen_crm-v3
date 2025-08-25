// API endpoints
export const API_ENDPOINTS = {
  AUTH: {
    LOGIN: '/api/auth/login',
    REGISTER: '/api/auth/register',
    LOGOUT: '/api/auth/logout',
    REFRESH: '/api/auth/refresh',
    PROFILE: '/api/auth/profile',
  },
  USERS: {
    LIST: '/api/users',
    CREATE: '/api/users',
    UPDATE: (id: string) => `/api/users/${id}`,
    DELETE: (id: string) => `/api/users/${id}`,
  },
} as const;

// Application constants
export const APP_CONFIG = {
  NAME: 'Janssen CRM',
  VERSION: '1.0.0',
  PAGINATION: {
    DEFAULT_PAGE_SIZE: 10,
    MAX_PAGE_SIZE: 100,
  },
  VALIDATION: {
    PASSWORD_MIN_LENGTH: 8,
    EMAIL_REGEX: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  },
} as const;

// Local storage keys
export const STORAGE_KEYS = {
  ACCESS_TOKEN: 'access_token',
  REFRESH_TOKEN: 'refresh_token',
  USER_PREFERENCES: 'user_preferences',
  THEME: 'theme',
} as const;

// Route paths
export const ROUTES = {
  HOME: '/',
  ABOUT: '/about',
  AUTH: {
    LOGIN: '/auth/login',
    REGISTER: '/auth/register',
    FORGOT_PASSWORD: '/auth/forgot-password',
  },
  DASHBOARD: '/dashboard',
  USERS: '/users',
  PROFILE: '/profile',
} as const;

// Default apps configuration
export type AppType = {
  id: string;
  name: string;
  icon: string;
  gradient: string;
  requiredPermission?: number;
};

export const DEFAULT_APPS: AppType[] = [
  { id: 'mail', name: 'Mail', icon: '✉', gradient: 'linear-gradient(135deg, #3498db, #2980b9)' },
  { id: 'calendar', name: 'Calendar', icon: '📅', gradient: 'linear-gradient(135deg, #9b59b6, #8e44ad)' },
  { id: 'notes', name: 'Notes', icon: '📝', gradient: 'linear-gradient(135deg, #e67e22, #d35400)' },
  { id: 'tasks', name: 'Tasks', icon: '✓', gradient: 'linear-gradient(135deg, #2ecc71, #27ae60)' },
  { id: 'masterdata', name: 'Master Data', icon: '🗃️', gradient: 'linear-gradient(135deg, #8e44ad, #6c3483)', requiredPermission: 2 },
  { id: 'usermanagement', name: 'User Management', icon: '👥', gradient: 'linear-gradient(135deg, #e74c3c, #c0392b)', requiredPermission: 1 },
  { id: 'reports', name: 'Reports', icon: '📊', gradient: 'linear-gradient(135deg, #1abc9c, #16a085)' },
  { id: 'bookmarks', name: 'Bookmarks', icon: '🔖', gradient: 'linear-gradient(135deg, #f39c12, #e67e22)' }
];