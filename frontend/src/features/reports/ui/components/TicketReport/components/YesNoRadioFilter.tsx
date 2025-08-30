import React, { useState, useEffect } from 'react';
import styles from '../TicketReport.module.css';

interface YesNoRadioFilterProps {
  value: boolean | null;
  onChange: (value: boolean | null) => void;
  onApply: () => void;
}

const YesNoRadioFilter: React.FC<YesNoRadioFilterProps> = ({
  value,
  onChange,
  onApply,
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
    console.log('YesNoRadioFilter useEffect: value changed to', value, 'type:', typeof value);
    setLocalValue(value);
  }, [value]);

  const handleRadioChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    let newValue: boolean | null = null;
    if (e.target.value === 'true') newValue = true;
    else if (e.target.value === 'false') newValue = false;
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
            name="yesno"
            value="null"
            checked={localValue === null}
            onChange={handleRadioChange}
          />
          <span className={styles.radioLabel}>All</span>
        </label>
        
        <label className={styles.radioOption}>
          <input
            type="radio"
            name="yesno"
            value="true"
            checked={localValue === true}
            onChange={handleRadioChange}
          />
          <span className={styles.radioLabel}>Yes</span>
        </label>
        
        <label className={styles.radioOption}>
          <input
            type="radio"
            name="yesno"
            value="false"
            checked={localValue === false}
            onChange={handleRadioChange}
          />
          <span className={styles.radioLabel}>No</span>
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

export default YesNoRadioFilter;
