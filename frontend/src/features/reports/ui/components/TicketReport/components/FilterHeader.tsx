import React from 'react';
import styles from '../TicketReport.module.css';
import FilterDropdown from './FilterDropdown';
import { FilterValue } from '../types';

interface FilterHeaderProps {
  column: string;
  displayName: string;
  isFiltered: boolean;
  filterCount: number;
  isDropdownOpen: boolean;
  uniqueValues: string[];
  selectedValues: FilterValue;
  onToggleFilter: (column: string) => void;
  onFilterSelection: (column: string, value: FilterValue) => void;
  onApplyFilter: (column: string) => void;
  onClearFilter: (column: string) => void;
  customClassName?: string;
  isLoading?: boolean;
}

const FilterHeader: React.FC<FilterHeaderProps> = ({
  column,
  displayName,
  isFiltered,
  filterCount,
  isDropdownOpen,
  uniqueValues,
  selectedValues,
  onToggleFilter,
  onFilterSelection,
  onApplyFilter,
  onClearFilter,
  customClassName,
  isLoading = false,
}) => {


  // Columns that should not show filter icons
  const columnsWithoutFilters = ['ID', 'Customer', 'Ticket ID', 'Size'];
  const shouldShowFilters = !columnsWithoutFilters.includes(column);

  return (
    <th className={`${isFiltered ? styles.columnFiltered : ''} ${customClassName || ''}`.trim()}>
      {displayName} 
      {shouldShowFilters && (
        <>
          <span className={styles.filterIcon} onClick={() => onToggleFilter(column)}>
            {isFiltered ? '🔽' : '🔽'}
          </span>
          {isFiltered && filterCount > 0 && (
            <span className={styles.filterCount}>{filterCount}</span>
          )}
          <FilterDropdown
            column={column}
            isOpen={isDropdownOpen}
            uniqueValues={uniqueValues}
            selectedValues={selectedValues}
            onFilterSelection={onFilterSelection}
            onApplyFilter={onApplyFilter}
            onClearFilter={onClearFilter}
            isLoading={isLoading}
          />
        </>
      )}
    </th>
  );
};

export default FilterHeader;
