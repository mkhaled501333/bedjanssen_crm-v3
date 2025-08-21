'use client';

import type { SearchBarProps } from '../../types';
import { useSearch } from '../hooks/useSearch';
import styles from './SearchBar.module.css';

export function SearchBar({ 
  placeholder = "Search...", 
  onSearch, 
  className = "",
  suggestions = [],
  showSuggestions = true,
  maxSuggestions = 8,
  onAddNew,
  showAddNewButton = true,
  onCustomerClick
}: SearchBarProps) {
  const {
    searchQuery,
    filteredSuggestions,
    showDropdown,
    selectedIndex,
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
  } = useSearch({
    suggestions,
    showSuggestions,
    maxSuggestions,
    onSearch,
    onAddNew,
    onCustomerClick
  });

  return (
    <div className={`${styles.searchContainer} ${className}`}>
      <div className={`${styles.searchInputWrapper} ${isSearching ? styles.shimmer : ''}`}>
        <span className={styles.searchIcon}>🔍</span>
        <input
          ref={inputRef}
          type="text"
          className={styles.searchInput}
          placeholder={placeholder}
          value={searchQuery}
          onChange={handleInputChange}
          onKeyDown={handleKeyDown}
          onFocus={handleFocus}
          onBlur={handleBlur}
          autoComplete="off"
        />
        {searchQuery && (
          <button
            type="button"
            className={styles.clearButton}
            onMouseDown={(e) => {
              // Prevent blur event from firing
              e.preventDefault();
            }}
            onClick={() => {
              setSearchQuery('');
              if (onSearch) onSearch('');
              // Keep focus on input
              inputRef.current?.focus();
            }}
          >
            ✕
          </button>
        )}
      </div>
      
      {showDropdown && (
        <div ref={dropdownRef} className={`${styles.suggestionsDropdown} ${isSearching ? styles.shimmerDropdown : ''}`}>
          {isSearching ? (
            // Skeleton loading placeholders
            Array.from({ length: 3 }).map((_, index) => (
              <div key={`skeleton-${index}`} className={styles.skeletonItem}>
                <div className={styles.skeletonMain}>
                  <div className={`${styles.skeletonText} ${
                    index === 0 ? styles.skeletonTextLong :
                    index === 1 ? styles.skeletonTextMedium :
                    styles.skeletonTextShort
                  }`}></div>
                  <div className={styles.skeletonCategory}></div>
                </div>
                <div className={styles.skeletonDescription}></div>
              </div>
            ))
          ) : filteredSuggestions.length > 0 ? (
            <>
              <div className={styles.suggestionsHeader}>
                <div className={styles.suggestionsCount}>
                  {filteredSuggestions.length} result{filteredSuggestions.length !== 1 ? 's' : ''}
                </div>
              </div>
              
              {filteredSuggestions.map((suggestion, index) => (
                <div
                  key={suggestion.id}
                  className={`${styles.suggestionItem} ${selectedIndex === index ? styles.suggestionSelected : ''}`}
                  onClick={() => handleSuggestionClick(suggestion)}
                  onMouseEnter={() => {}}
                >
                  <div className={styles.suggestionMain}>
                    <span className={styles.suggestionText}>
                      {suggestion.text}
                    </span>
                    {suggestion.category && (
                      <span className={styles.suggestionCategory}>
                        {suggestion.category}
                      </span>
                    )}
                  </div>
                  {suggestion.description && (
                    <div className={styles.suggestionDescription}>
                      {suggestion.description}
                    </div>
                  )}
                </div>
              ))}
            </>
           ) : (
             showAddNewButton && onAddNew && (
              <>
                <div className={styles.suggestionsHeader}>
                  <div className={styles.suggestionsCount}>
                    No results found
                  </div>
                </div>
                <div
                  className={`${styles.suggestionItem} ${styles.addNewItem}`}
                  onClick={handleAddNewClick}
                >
                  <div className={styles.suggestionMain}>
                    <span className={styles.addNewIcon}>👤</span>
                    <span className={styles.suggestionText}>
                      Create new customer
                    </span>
                  </div>
                  <div className={styles.suggestionDescription}>
                    Press Enter or click here to create a new customer with &quot;{searchQuery}&quot;
                  </div>
                </div>
              </>
            )
          )}
        </div>
      )}
    </div>
  );
}