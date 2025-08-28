import React, { useState, useEffect } from 'react';
import styles from '../TicketReport.module.css';

interface RadioFilterProps {
  value: string | null;
  onChange: (value: string | null) => void;
  onApply: () => void;
  onClear: () => void;
}

const RadioFilter: React.FC<RadioFilterProps> = ({
  value,
  onChange,
  onApply,
  onClear,
}) => {
  const [localValue, setLocalValue] = useState<string | null>(value);
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

  const handleRadioChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value === 'null' ? null : e.target.value;
    setLocalValue(newValue);
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

  return (
    <div className={styles.radioFilter}>
      <div className={styles.radioOptions}>
        <label className={styles.radioOption}>
          <input
            type="radio"
            name="status"
            value="null"
            checked={localValue === null}
            onChange={handleRadioChange}
          />
          <span className={styles.radioLabel}>All</span>
        </label>
        
        <label className={styles.radioOption}>
          <input
            type="radio"
            name="status"
            value="0"
            checked={localValue === '0'}
            onChange={handleRadioChange}
          />
          <span className={styles.radioLabel}>Open</span>
        </label>
        
        <label className={styles.radioOption}>
          <input
            type="radio"
            name="status"
            value="1"
            checked={localValue === '1'}
            onChange={handleRadioChange}
          />
          <span className={styles.radioLabel}>Closed</span>
        </label>
      </div>
      
      <div className={styles.radioActions}>
        <button 
          className={styles.apply} 
          onClick={handleApply}
        >
          Apply
        </button>
        <button 
          className={styles.clear} 
          onClick={handleClear}
        >
          Clear
        </button>
      </div>
    </div>
  );
};

export default RadioFilter;
