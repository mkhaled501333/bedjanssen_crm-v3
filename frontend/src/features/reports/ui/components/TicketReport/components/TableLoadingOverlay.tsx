import React from 'react';
import LoadingSpinner from './LoadingSpinner';
import styles from './TableLoadingOverlay.module.css';

interface TableLoadingOverlayProps {
  isLoading: boolean;
  loadingText?: string;
}

const TableLoadingOverlay: React.FC<TableLoadingOverlayProps> = ({ 
  isLoading, 
  loadingText = 'Updating data...' 
}) => {
  if (!isLoading) return null;

  return (
    <div className={styles.overlay}>
      <div className={styles.overlayContent}>
        <LoadingSpinner 
          size="medium" 
          color="#217346" 
          text={loadingText}
        />
      </div>
    </div>
  );
};

export default TableLoadingOverlay;
