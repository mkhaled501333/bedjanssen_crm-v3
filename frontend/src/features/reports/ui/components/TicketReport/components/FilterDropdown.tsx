import React from 'react';
import styles from '../TicketReport.module.css';
import { FilterValue, COLUMN_FILTER_CONFIG } from '../types';
import MultiSelectFilter from './MultiSelectFilter';
import TextFilter from './TextFilter';
import BooleanFilter from './BooleanFilter';
import DateRangePicker from './DateRangePicker';
import RadioFilter from './RadioFilter';
import YesNoRadioFilter from './YesNoRadioFilter';

interface FilterDropdownProps {
  column: string;
  isOpen: boolean;
  uniqueValues: string[];
  selectedValues: FilterValue;
  onFilterSelection: (column: string, value: FilterValue) => void;
  onApplyFilter: (column: string) => void;
  onClearFilter: (column: string) => void;
  isLoading?: boolean;
}

const FilterDropdown: React.FC<FilterDropdownProps> = ({
  column,
  isOpen,
  uniqueValues = [],
  selectedValues,
  onFilterSelection,
  onApplyFilter,
  onClearFilter,
  isLoading = false,
}) => {
  if (!isOpen) return null;

  const filterConfig = COLUMN_FILTER_CONFIG.find(config => config.column === column);
  if (!filterConfig) return null;

  // Ensure uniqueValues is always an array
  const safeUniqueValues = Array.isArray(uniqueValues) ? uniqueValues : [];

  const renderFilterComponent = () => {
    switch (filterConfig.filterType) {
      case 'multiSelect':
        return (
          <MultiSelectFilter
            uniqueValues={safeUniqueValues}
            selectedValues={Array.isArray(selectedValues) ? selectedValues : []}
            onFilterSelection={(value) => onFilterSelection(column, value)}
            onApplyFilter={() => onApplyFilter(column)}
            onClearFilter={() => onClearFilter(column)}
            isLoading={isLoading}
          />
        );
      case 'text':
        return (
          <TextFilter
            value={typeof selectedValues === 'string' ? selectedValues : ''}
            onChange={(value) => onFilterSelection(column, value)}
            onApply={() => onApplyFilter(column)}
          />
        );
      case 'radio':
        // Use different radio filters based on the column
        if (column === 'Pulled Status' || column === 'Delivered Status') {
          console.log('FilterDropdown: Rendering YesNoRadioFilter for', column, 'with selectedValues:', selectedValues, 'type:', typeof selectedValues);
          return (
            <YesNoRadioFilter
              value={typeof selectedValues === 'boolean' ? selectedValues : null}
              onChange={(value) => onFilterSelection(column, value)}
              onApply={() => onApplyFilter(column)}
            />
          );
        } else {
          // Default radio filter for Status column
          return (
            <RadioFilter
              value={typeof selectedValues === 'string' ? selectedValues : null}
              onChange={(value) => onFilterSelection(column, value)}
              onApply={() => onApplyFilter(column)}
            />
          );
        }
      case 'boolean':
        return (
          <BooleanFilter
            value={typeof selectedValues === 'boolean' ? selectedValues : null}
            onChange={(value) => onFilterSelection(column, value)}
            onApply={() => onApplyFilter(column)}
          />
        );
      case 'dateRange':
        return (
          <DateRangePicker
            value={selectedValues && typeof selectedValues === 'object' && 'from' in selectedValues 
              ? selectedValues as { from: Date | null; to: Date | null } 
              : { from: null, to: null }}
            onChange={(value) => onFilterSelection(column, value)}
            onApply={() => onApplyFilter(column)}
          />
        );
      default:
        return null;
    }
  };

  return (
    <div className={styles.filterDropdown}>
      <div className={styles.filterHeader}>
        Filter {column}
      </div>
      {renderFilterComponent()}
    </div>
  );
};

export default FilterDropdown;
