// Export simplified search feature

// Main UI components and hooks
export { SearchBar, useSearch } from './ui';

// API service
export { searchCustomers } from './api';
export type { CustomerSearchResult, CustomerSearchResponse } from './api';

// Types
export type {
  SearchSuggestion,
  SearchBarProps,
  SearchState,
  SearchResult,
  SearchFilters,
  UseSearchProps
} from './types';