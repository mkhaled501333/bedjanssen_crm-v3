import React, { useState, useMemo } from 'react';
import styles from '../TicketReport.module.css';

interface MultiSelectFilterProps {
  uniqueValues: string[];
  selectedValues: string[];
  onFilterSelection: (value: string[]) => void;
  onApplyFilter: () => void;
  onClearFilter: () => void;
  isLoading?: boolean;
}

const MultiSelectFilter: React.FC<MultiSelectFilterProps> = ({
  uniqueValues = [],
  selectedValues = [],
  onFilterSelection,
  onApplyFilter,
  onClearFilter,
  isLoading = false,
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  
  // Ensure we have valid arrays
  const safeUniqueValues = Array.isArray(uniqueValues) ? uniqueValues : [];
  const safeSelectedValues = Array.isArray(selectedValues) ? selectedValues : [];
  
  // Filter values based on search term
  const filteredValues = useMemo(() => {
    if (!searchTerm.trim()) return safeUniqueValues;
    return safeUniqueValues.filter(value => 
      value.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [safeUniqueValues, searchTerm]);
  
  const allSelected = filteredValues.length > 0 && 
    filteredValues.every(value => safeSelectedValues.includes(value));

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      // Add all filtered values to selection
      const newSelection = [...safeSelectedValues];
      filteredValues.forEach(value => {
        if (!newSelection.includes(value)) {
          newSelection.push(value);
        }
      });
      onFilterSelection(newSelection);
    } else {
      // Remove all filtered values from selection
      onFilterSelection(safeSelectedValues.filter(value => !filteredValues.includes(value)));
    }
  };

  const handleIndividualSelection = (value: string, checked: boolean) => {
    if (checked) {
      onFilterSelection([...safeSelectedValues, value]);
    } else {
      onFilterSelection(safeSelectedValues.filter(v => v !== value));
    }
  };

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(e.target.value);
  };

  const handleClearSearch = () => {
    setSearchTerm('');
  };

  // If no unique values, show a message
  if (safeUniqueValues.length === 0) {
    return (
      <div className={styles.multiSelectFilter}>
        <div className={styles.filterOptions}>
          <div className={styles.noDataMessage}>No data available for filtering</div>
        </div>
        <div className={styles.filterActions}>
          <button 
            className={styles.clear} 
            onClick={onClearFilter}
            disabled={isLoading}
          >
            Clear
          </button>
          <button 
            className={styles.apply} 
            onClick={onApplyFilter}
            disabled
          >
            Apply
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.multiSelectFilter}>
      <div className={styles.searchContainer}>
        <input
          type="text"
          placeholder="Search options..."
          value={searchTerm}
          onChange={handleSearchChange}
          className={styles.searchInput}
        />
        {searchTerm && (
          <button 
            className={styles.clearSearchButton}
            onClick={handleClearSearch}
            title="Clear search"
          >
            ✕
          </button>
        )}
      </div>
      
      <div className={styles.filterOptions}>
        {filteredValues.length === 0 ? (
          <div className={styles.noSearchResults}>
            No options match "{searchTerm}"
          </div>
        ) : (
          <>
            <div className={styles.filterOption}>
              <input
                type="checkbox"
                checked={allSelected}
                onChange={(e) => handleSelectAll(e.target.checked)}
              />
              <label>Select All ({filteredValues.length})</label>
            </div>
            {filteredValues.map((value) => (
              <div key={value} className={styles.filterOption}>
                <input
                  type="checkbox"
                  checked={safeSelectedValues.includes(value)}
                  onChange={(e) => handleIndividualSelection(value, e.target.checked)}
                />
                <label>{value}</label>
              </div>
            ))}
          </>
        )}
      </div>
      
      <div className={styles.filterActions}>
        <button 
          className={styles.clear} 
          onClick={onClearFilter}
        >
          Clear
        </button>
                  <button 
            className={styles.apply} 
            onClick={onApplyFilter}
            disabled={isLoading}
          >
            {isLoading ? 'Applying...' : 'Apply'}
          </button>
      </div>
    </div>
  );
};

export default MultiSelectFilter;
