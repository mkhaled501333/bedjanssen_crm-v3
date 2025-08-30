import React, { useState, useEffect } from 'react';
import styles from '../TicketReport.module.css';
import { DateRange } from '../types';

interface DateRangePickerProps {
  value: DateRange;
  onChange: (value: DateRange) => void;
  onApply: () => void;
}

const DateRangePicker: React.FC<DateRangePickerProps> = ({
  value,
  onChange,
  onApply,
}) => {
  const [localValue, setLocalValue] = useState<DateRange>(value);
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

  const handleFromChange = (dateString: string) => {
    const date = dateString ? new Date(dateString) : null;
    setLocalValue(prev => ({ ...prev, from: date }));
  };

  const handleToChange = (dateString: string) => {
    const date = dateString ? new Date(dateString) : null;
    setLocalValue(prev => ({ ...prev, to: date }));
  };

  const handleApply = () => {
    onChange(localValue);
    setShouldApply(true); // Trigger apply after state update
  };

  const handleClear = () => {
    const clearedValue = { from: null, to: null };
    setLocalValue(clearedValue);
    onChange(clearedValue);
    setShouldApply(true); // Trigger apply after state update
  };

  const formatDateForInput = (date: Date | null): string => {
    if (!date) return '';
    return date.toISOString().split('T')[0];
  };

  return (
    <div className={styles.dateRangePicker}>
      <div className={styles.dateRangeInputs}>
        <div className={styles.dateInputGroup}>
          <label>From:</label>
          <input
            type="date"
            value={formatDateForInput(localValue.from)}
            onChange={(e) => handleFromChange(e.target.value)}
            className={styles.dateInput}
          />
        </div>
        <div className={styles.dateInputGroup}>
          <label>To:</label>
          <input
            type="date"
            value={formatDateForInput(localValue.to)}
            onChange={(e) => handleToChange(e.target.value)}
            className={styles.dateInput}
          />
        </div>
      </div>
      <div className={styles.dateRangeActions}>
        <button 
          className={styles.applyButton} 
          onClick={handleApply}
          disabled={!localValue.from && !localValue.to}
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

export default DateRangePicker;
