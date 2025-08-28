import React from 'react';
import styles from './LoadingSpinner.module.css';

interface LoadingSpinnerProps {
  size?: 'small' | 'medium' | 'large';
  color?: string;
  text?: string;
}

const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({ 
  size = 'medium', 
  color = '#217346',
  text = 'Loading...'
}) => {
  return (
    <div className={`${styles.loadingContainer} ${styles[size]}`}>
      <div className={styles.spinnerWrapper}>
        <div 
          className={styles.spinner} 
          style={{ borderTopColor: color }}
        ></div>
        <div 
          className={styles.spinnerInner} 
          style={{ borderTopColor: color }}
        ></div>
      </div>
      {text && <div className={styles.loadingText}>{text}</div>}
    </div>
  );
};

export default LoadingSpinner;
