// Format date utilities
export const formatDate = {
  short: (date: Date | string) => {
    return new Intl.DateTimeFormat('en-GB', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    }).format(new Date(date));
  },
  long: (date: Date | string) => {
    return new Intl.DateTimeFormat('en-GB', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    }).format(new Date(date));
  },
  time: (date: Date | string) => {
    return new Intl.DateTimeFormat('en-GB', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    }).format(new Date(date));
  },
};



// String utilities
export const stringUtils = {
  capitalize: (str: string): string => {
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
  },
  truncate: (str: string, length: number): string => {
    return str.length > length ? `${str.substring(0, length)}...` : str;
  },
  slugify: (str: string): string => {
    return str
      .toLowerCase()
      .replace(/[^\w\s-]/g, '')
      .replace(/[\s_-]+/g, '-')
      .replace(/^-+|-+$/g, '');
  },
};

// Local storage utilities
export const storage = {
  get: <T>(key: string, defaultValue?: T): T | null => {
    if (typeof window === 'undefined') return defaultValue || null;
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : defaultValue || null;
    } catch {
      return defaultValue || null;
    }
  },
  set: (key: string, value: unknown): void => {
    if (typeof window === 'undefined') return;
    try {
      window.localStorage.setItem(key, JSON.stringify(value));
    } catch {
      // Handle storage errors silently
    }
  },
  remove: (key: string): void => {
    if (typeof window === 'undefined') return;
    try {
      window.localStorage.removeItem(key);
    } catch {
      // Handle storage errors silently
    }
  },
};

// Debounce utility
export function debounce<T extends (...args: unknown[]) => unknown>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout;
  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
}

// Generate unique ID
export function generateId(): string {
  return Math.random().toString(36).substring(2) + Date.now().toString(36);
}

// Error handling utility
export function handleError(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === 'string') {
    return error;
  }
  return 'An unexpected error occurred';
}

// Get dynamic API base URL
export function getApiBaseUrl(): string {
  if (typeof window !== 'undefined' && window.location.hostname !== 'localhost') {
    return `http://${window.location.hostname}:8081`;
  }
  return 'http://localhost:8081';
}

// Authenticated fetch utility
export async function authFetch(input: RequestInfo, init: RequestInit = {}) {
  let token: string | null = null;
  if (typeof window !== 'undefined') {
    token = window.localStorage.getItem('token');
  }
  const headers = new Headers(init.headers || {});
  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }
  // Always set Content-Type if not present
  if (!headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }
  
  const response = await fetch(input, { ...init, headers });
  
  // Check for 401 Unauthorized response (token expired)
  if (response.status === 401) {
    console.warn('Token expired or invalid. Logging out user.');
    logout();
    throw new Error('Authentication token expired. Please log in again.');
  }
  
  return response;
}

// Token expiration utilities
export function isTokenExpired(token: string): boolean {
  try {
    // Decode JWT token to check expiration
    const payload = JSON.parse(atob(token.split('.')[1]));
    const currentTime = Math.floor(Date.now() / 1000);
    return payload.exp < currentTime;
  } catch {
    // If token is malformed, consider it expired
    return true;
  }
}

export function getTokenExpirationTime(token: string): number | null {
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.exp * 1000; // Convert to milliseconds
  } catch {
    return null;
  }
}

// Global token monitoring
let tokenCheckInterval: NodeJS.Timeout | null = null;

export function startTokenMonitoring() {
  if (typeof window === 'undefined') return;
  
  // Clear existing interval
  if (tokenCheckInterval) {
    clearInterval(tokenCheckInterval);
  }
  
  // Check token every 30 seconds
  tokenCheckInterval = setInterval(() => {
    const token = localStorage.getItem('token');
    if (token && isTokenExpired(token)) {
      console.warn('Token has expired. Logging out user.');
      logout();
    }
  }, 30000); // Check every 30 seconds
}

export function stopTokenMonitoring() {
  if (tokenCheckInterval) {
    clearInterval(tokenCheckInterval);
    tokenCheckInterval = null;
  }
}

// Logout utility
export function logout() {
  if (typeof window !== 'undefined') {
    // Stop token monitoring
    stopTokenMonitoring();
    
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    // Call backend logout endpoint with proper URL and auth
    authFetch(`${getApiBaseUrl()}/api/auth/logout`, { method: 'POST' }).catch(() => {});
    window.location.href = '/auth/login';
  }
}