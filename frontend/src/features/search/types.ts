// Simple types for the search feature

export interface SearchSuggestion {
  id: string;
  text: string;
  category?: string;
  description?: string;
}

export interface SearchBarProps {
  placeholder?: string;
  onSearch?: (query: string) => void;
  className?: string;
  suggestions?: SearchSuggestion[];
  showSuggestions?: boolean;
  maxSuggestions?: number;
  onAddNew?: (query: string) => void;
  showAddNewButton?: boolean;
  onCustomerClick?: (customerId: string, customerName: string) => void;
}

export interface SearchState {
  query: string;
  suggestions: SearchSuggestion[];
  isLoading: boolean;
  showDropdown: boolean;
  selectedIndex: number;
}

export interface SearchResult {
  id: string;
  title: string;
  description?: string;
  category?: string;
  type?: string;
}

export interface SearchFilters {
  category?: string;
  type?: string;
  dateRange?: {
    start?: Date;
    end?: Date;
  };
}

export interface UseSearchProps {
  suggestions?: SearchSuggestion[];
  showSuggestions?: boolean;
  maxSuggestions?: number;
  onSearch?: (query: string) => void;
  onAddNew?: (query: string) => void;
  onCustomerClick?: (customerId: string, customerName: string) => void;
}