'use client';

import React from 'react';
import { ReportConfig } from '../../types';
import styles from './ReportCard.module.css';

interface ReportCardProps {
  report: ReportConfig;
  index: number;
  onClick: () => void;
}

export function ReportCard({ report, index, onClick }: ReportCardProps) {
  return (
    <div className={styles.reportCard} onClick={onClick}>
      {/* Report Number */}
      <div className={styles.reportNumber}>
        {index}
      </div>

      {/* Report Content */}
      <div className={styles.reportContent}>
        <div className={styles.reportHeader}>
          <span className={styles.reportIcon}>{report.icon}</span>
          <h3 className={styles.reportTitle}>
            {report.name}
          </h3>
        </div>
        
        <p className={styles.reportDescription}>
          {report.description}
        </p>

        {/* Subtabs Preview */}
        {report.subtabs && report.subtabs.length > 0 && (
          <div className={styles.subtabsPreview}>
            <span className={styles.subtabsLabel}>
              Subtabs:
            </span>
            <div className={styles.subtabsList}>
              {report.subtabs.slice(0, 3).map((subtab, idx) => (
                <span key={idx} className={styles.subtabItem}>
                  {subtab.name}
                </span>
              ))}
              {report.subtabs.length > 3 && (
                <span className={styles.moreSubtabs}>
                  +{report.subtabs.length - 3} more
                </span>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Arrow Icon */}
      <div className={styles.arrowIcon}>
        →
      </div>
    </div>
  );
}