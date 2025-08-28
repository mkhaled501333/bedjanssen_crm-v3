import React, { useState, useEffect } from 'react';
import styles from '../TicketReport.module.css';

interface TextFilterProps {
  value: string;
  onChange: (value: string) => void;
  onApply: () => void;
  onClear: () => void;
}

const TextFilter: React.FC<TextFilterProps> = ({
  value,
  onChange,
  onApply,
  onClear,
}) => {
  const [localValue, setLocalValue] = useState<string>(value);
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

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setLocalValue(e.target.value);
  };

  const handleApply = () => {
    onChange(localValue);
    setShouldApply(true); // Trigger apply after state update
  };

  const handleClear = () => {
    setLocalValue('');
    onChange('');
    setShouldApply(true); // Trigger apply after state update
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleApply();
    }
  };

  const handleClearInput = () => {
    setLocalValue('');
  };

  return (
    <div className={styles.textFilter}>
      <div className={styles.textInputContainer}>
        <input
          type="text"
          value={localValue}
          onChange={handleChange}
          onKeyPress={handleKeyPress}
          placeholder="Type to search..."
          className={styles.textFilterInput}
        />
        {localValue && (
          <button 
            className={styles.clearTextButton}
            onClick={handleClearInput}
            title="Clear input"
          >
            ✕
          </button>
        )}
      </div>
      <div className={styles.textActions}>
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

export default TextFilter;
