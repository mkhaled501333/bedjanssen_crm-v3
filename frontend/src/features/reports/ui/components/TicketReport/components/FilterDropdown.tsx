import React from 'react';
import styles from '../TicketReport.module.css';

interface FilterDropdownProps {
  column: string;
  isOpen: boolean;
  uniqueValues: string[];
  selectedValues: string[];
  onFilterSelection: (column: string, value: string, checked: boolean) => void;
  onSelectAllFilter: (column: string, checked: boolean, uniqueValues: string[]) => void;
  onApplyFilter: (column: string) => void;
  onClearFilter: (column: string) => void;
}

const FilterDropdown: React.FC<FilterDropdownProps> = ({
  column,
  isOpen,
  uniqueValues,
  selectedValues,
  onFilterSelection,
  onSelectAllFilter,
  onApplyFilter,
  onClearFilter,
}) => {
  if (!isOpen) return null;

  const allSelected = uniqueValues.length > 0 && selectedValues.length === uniqueValues.length;

  return (
    <div className={styles.filterDropdown}>
      <div className={styles.filterHeader}>
        Filter {column}
      </div>
      <div className={styles.filterOptions}>
        <div className={styles.filterOption}>
          <input
            type="checkbox"
            checked={allSelected}
            onChange={(e) => onSelectAllFilter(column, e.target.checked, uniqueValues)}
          />
          <label>Select All</label>
        </div>
        {uniqueValues.map((value) => (
          <div key={value} className={styles.filterOption}>
            <input
              type="checkbox"
              checked={selectedValues.includes(value)}
              onChange={(e) => onFilterSelection(column, value, e.target.checked)}
            />
            <label>{value}</label>
          </div>
        ))}
      </div>
      <div className={styles.filterActions}>
        <button 
          className={styles.clear} 
          onClick={() => onClearFilter(column)}
        >
          Clear
        </button>
        <button 
          className={styles.apply} 
          onClick={() => onApplyFilter(column)}
        >
          Apply
        </button>
      </div>
    </div>
  );
};

export default FilterDropdown;
