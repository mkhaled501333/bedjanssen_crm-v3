import React, { useState, useEffect } from 'react';
import styles from '../TicketReport.module.css';

interface BooleanFilterProps {
  value: boolean | null;
  onChange: (value: boolean | null) => void;
  onApply: () => void;
  onClear: () => void;
}

const BooleanFilter: React.FC<BooleanFilterProps> = ({
  value,
  onChange,
  onApply,
  onClear,
}) => {
  const [localValue, setLocalValue] = useState<boolean | null>(value);
  const [shouldApply, setShouldApply] = useState(false);

  // Apply filter after state update
  useEffect(() => {
    if (shouldApply) {
      onApply();
      setShouldApply(false);
    }
  }, [shouldApply, onApply]);

  // Sync local state with prop value (for localStorage restoration)
  useEffect(() => {
    setLocalValue(value);
  }, [value]);

  const handleChange = (newValue: string) => {
    let booleanValue: boolean | null = null;
    if (newValue === 'true') booleanValue = true;
    else if (newValue === 'false') booleanValue = false;
    setLocalValue(booleanValue);
  };

  const handleApply = () => {
    onChange(localValue);
    setShouldApply(true); // Trigger apply after state update
  };

  const handleClear = () => {
    setLocalValue(null);
    onChange(null);
    setShouldApply(true); // Trigger apply after state update
  };

  const getDisplayValue = (value: boolean | null): string => {
    if (value === null) return 'All';
    return value ? 'Yes' : 'No';
  };

  return (
    <div className={styles.booleanFilter}>
      <div className={styles.booleanSelect}>
        <select
          value={localValue === null ? 'all' : localValue.toString()}
          onChange={(e) => handleChange(e.target.value)}
          className={styles.booleanSelectInput}
        >
          <option value="all">All</option>
          <option value="true">Yes</option>
          <option value="false">No</option>
        </select>
      </div>
      <div className={styles.booleanActions}>
        <button 
          className={styles.applyButton} 
          onClick={handleApply}
        >
          Apply
        </button>
        <button 
          className={styles.clearButton} 
          onClick={handleClear}
        >
          Clear
        </button>
      </div>
    </div>
  );
};

export default BooleanFilter;
