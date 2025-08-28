import React from 'react';
import LoadingSpinner from './LoadingSpinner';
import styles from './LoadingRow.module.css';

interface LoadingRowProps {
  columnCount: number;
}

const LoadingRow: React.FC<LoadingRowProps> = ({ columnCount }) => {
  return (
    <tr className={styles.loadingRow}>
      <td className={styles.checkboxCell}>
        <div className={styles.checkboxSkeleton}></div>
      </td>
      {Array.from({ length: columnCount - 1 }).map((_, index) => (
        <td key={index} className={styles.cellSkeleton}>
          <div className={styles.skeletonContent}>
            <div className={styles.skeletonLine}></div>
          </div>
        </td>
      ))}
    </tr>
  );
};

export default LoadingRow;
