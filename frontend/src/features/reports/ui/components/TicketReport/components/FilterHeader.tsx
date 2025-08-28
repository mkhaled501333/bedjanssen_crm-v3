import React from 'react';
import styles from '../TicketReport.module.css';
import FilterDropdown from './FilterDropdown';

interface FilterHeaderProps {
  column: string;
  displayName: string;
  isFiltered: boolean;
  filterCount: number;
  isDropdownOpen: boolean;
  uniqueValues: string[];
  selectedValues: string[];
  onToggleFilter: (column: string) => void;
  onFilterSelection: (column: string, value: string, checked: boolean) => void;
  onSelectAllFilter: (column: string, checked: boolean, uniqueValues: string[]) => void;
  onApplyFilter: (column: string) => void;
  onClearFilter: (column: string) => void;
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
  onSelectAllFilter,
  onApplyFilter,
  onClearFilter,
}) => {
  return (
    <th className={isFiltered ? styles.columnFiltered : ''}>
      {displayName} 
      <span className={styles.filterIcon} onClick={() => onToggleFilter(column)}>
        {isFiltered ? '🔽' : '🔽'}
      </span>
      {isFiltered && (
        <span className={styles.filterCount}>{filterCount}</span>
      )}
      <FilterDropdown
        column={column}
        isOpen={isDropdownOpen}
        uniqueValues={uniqueValues}
        selectedValues={selectedValues}
        onFilterSelection={onFilterSelection}
        onSelectAllFilter={onSelectAllFilter}
        onApplyFilter={onApplyFilter}
        onClearFilter={onClearFilter}
      />
    </th>
  );
};

export default FilterHeader;
