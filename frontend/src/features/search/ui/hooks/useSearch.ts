'use client';

import { useState, useRef, useEffect, useMemo, useCallback } from 'react';
import type { SearchSuggestion, UseSearchProps } from '../../types';
import { searchCustomers } from '../../api';

// Synchronized timing for shimmer and debounce
const SEARCH_DELAY_MS = 500; // Reduced from 1200ms and 300ms

export function useSearch({
  suggestions = [],
  showSuggestions = true,
  maxSuggestions = 8,
  onSearch,
  onAddNew,
  onCustomerClick
}: UseSearchProps = {}) {
  const [searchQuery, setSearchQuery] = useState('');
  const [showDropdown, setShowDropdown] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const [isFocused, setIsFocused] = useState(false);
  const [isSearching, setIsSearching] = useState(false);
  const [apiSuggestions, setApiSuggestions] = useState<SearchSuggestion[]>([]);
  const inputRef = useRef<HTMLInputElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const searchTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const apiTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Filter suggestions based on search query
  const filteredSuggestions = useMemo(() => {
    if (!showSuggestions || !searchQuery.trim()) {
      return [];
    }

    // If we have API suggestions, prioritize them
    if (apiSuggestions.length > 0) {
      return apiSuggestions.slice(0, maxSuggestions);
    }

    // Fallback to static suggestions if no API results
    return suggestions
      .filter(suggestion => 
        suggestion.text.toLowerCase().includes(searchQuery.toLowerCase()) ||
        suggestion.category?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        suggestion.description?.toLowerCase().includes(searchQuery.toLowerCase())
      )
      .slice(0, maxSuggestions);
  }, [searchQuery, suggestions, apiSuggestions, showSuggestions, maxSuggestions]);

  // Fetch suggestions from API
  const fetchApiSuggestions = useCallback(async (query: string) => {
    if (!query.trim()) {
      setApiSuggestions([]);
      return;
    }

    try {
      const results = await searchCustomers(query, maxSuggestions);
      setApiSuggestions(results);
    } catch (error) {
      console.error('Failed to fetch suggestions:', error);
      setApiSuggestions([]);
    }
  }, [maxSuggestions]);

  // Show/hide dropdown based on focus and suggestions
  useEffect(() => {
    if (isFocused && (filteredSuggestions.length > 0 || searchQuery.trim())) {
      setShowDropdown(true);
    } else if (!isFocused) {
      setShowDropdown(false);
    }
  }, [isFocused, filteredSuggestions.length, searchQuery]);

  const handleInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setSearchQuery(value);
    
    // Show shimmer effect when typing
    if (value.trim()) {
      setIsSearching(true);
      
      // Clear existing timeouts
      if (searchTimeoutRef.current) {
        clearTimeout(searchTimeoutRef.current);
      }
      if (apiTimeoutRef.current) {
        clearTimeout(apiTimeoutRef.current);
      }
      
      // Synchronized timing for both shimmer and API call
      searchTimeoutRef.current = setTimeout(() => {
        setIsSearching(false);
      }, SEARCH_DELAY_MS);

      // Same delay for API calls (synchronized with shimmer)
      apiTimeoutRef.current = setTimeout(() => {
        fetchApiSuggestions(value);
      }, SEARCH_DELAY_MS);
    } else {
      setIsSearching(false);
      setApiSuggestions([]);
      if (searchTimeoutRef.current) {
        clearTimeout(searchTimeoutRef.current);
      }
      if (apiTimeoutRef.current) {
        clearTimeout(apiTimeoutRef.current);
      }
    }
    
    setSelectedIndex(-1);
  }, [fetchApiSuggestions]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent<HTMLInputElement>) => {
    if (!showDropdown) {
      if (e.key === 'Enter' && onSearch) {
        onSearch(searchQuery);
      }
      return;
    }

    // Handle case when no suggestions but "Add new" button should be shown
    if (filteredSuggestions.length === 0 && onAddNew) {
      if (e.key === 'Enter') {
        e.preventDefault();
        onAddNew(searchQuery);
        setShowDropdown(false);
        return;
      }
      return;
    }

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setSelectedIndex(prev => 
          prev < filteredSuggestions.length - 1 ? prev + 1 : prev
        );
        break;
      case 'ArrowUp':
        e.preventDefault();
        setSelectedIndex(prev => prev > 0 ? prev - 1 : -1);
        break;
      case 'Enter':
        e.preventDefault();
        if (selectedIndex >= 0 && selectedIndex < filteredSuggestions.length) {
          selectSuggestion(filteredSuggestions[selectedIndex]);
        } else if (onSearch) {
          onSearch(searchQuery);
        }
        break;
      case 'Escape':
        setShowDropdown(false);
        setSelectedIndex(-1);
        inputRef.current?.blur();
        break;
    }
  }, [showDropdown, filteredSuggestions, onSearch, onAddNew, searchQuery, selectedIndex]);

  const selectSuggestion = useCallback((suggestion: SearchSuggestion) => {
    setSearchQuery(suggestion.text);
    setShowDropdown(false);
    setSelectedIndex(-1);
    
    // Check if this is a customer suggestion (from API) and handle customer click
    if (onCustomerClick && apiSuggestions.some(s => s.id === suggestion.id)) {
      onCustomerClick(suggestion.id, suggestion.text);
    } else if (onSearch) {
      onSearch(suggestion.text);
    }
  }, [onSearch, onCustomerClick, apiSuggestions]);

  const handleFocus = useCallback(() => {
    setIsFocused(true);
  }, []);

  const handleBlur = useCallback(() => {
    // Delay hiding dropdown to allow for suggestion clicks
    setTimeout(() => {
      setIsFocused(false);
      setShowDropdown(false);
      setSelectedIndex(-1);
    }, 150);
  }, []);

  const handleSuggestionClick = useCallback((suggestion: SearchSuggestion) => {
    selectSuggestion(suggestion);
  }, [selectSuggestion]);

  const handleAddNewClick = useCallback(() => {
    if (onAddNew) {
      onAddNew(searchQuery);
      setShowDropdown(false);
    }
  }, [onAddNew, searchQuery]);

  // Cleanup timeouts on unmount
  useEffect(() => {
    return () => {
      if (searchTimeoutRef.current) {
        clearTimeout(searchTimeoutRef.current);
      }
      if (apiTimeoutRef.current) {
        clearTimeout(apiTimeoutRef.current);
      }
    };
  }, []);

  return {
    searchQuery,
    filteredSuggestions,
    showDropdown,
    selectedIndex,
    isFocused,
    isSearching,
    inputRef,
    dropdownRef,
    handleInputChange,
    handleKeyDown,
    handleFocus,
    handleBlur,
    handleSuggestionClick,
    handleAddNewClick,
    setSearchQuery
  };
}