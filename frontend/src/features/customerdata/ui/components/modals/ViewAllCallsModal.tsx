import React from 'react';
import styles from './ViewAllCallsModal.module.css';

export type ViewAllCallsModalProps = {
  onClose: () => void;
  calls: Array<{
    id: string;
    companyId: number;
    callType: string;
    category: string;
    createdAt: string;
    createdBy: string;
    callDuration: string;
    notes?: string;
    description?: string;
  }>;
  getCompanyName: (companyId: number) => string;
  customerId: number;
  companyId: number;
};

const formatDate = (dateString: string) => {
  if (!dateString) return 'N/A';
  // Extract only the date part (YYYY-MM-DD)
  if (dateString.includes(' ')) {
    return dateString.split(' ')[0]; // Get only the date part before space
  }
  if (dateString.includes('T')) {
    return dateString.split('T')[0]; // Handle ISO format
  }
  return dateString;
};

const formatTime = (dateString: string) => {
  if (!dateString) return 'N/A';
  // Extract only the time part (HH:MM)
  if (dateString.includes(' ') && dateString.includes(':')) {
    const timePart = dateString.split(' ')[1]; // Get time part after space
    return timePart.substring(0, 5); // Keep only HH:MM
  }
  if (dateString.includes('T') && dateString.includes(':')) {
    const timePart = dateString.split('T')[1]; // Handle ISO format
    return timePart.substring(0, 5); // Keep only HH:MM
  }
  return dateString;
};

export function ViewAllCallsModal({ onClose, calls, getCompanyName }: ViewAllCallsModalProps) {
  return (
    <div className={styles.modalOverlay}>
      <div className={styles.modalContent}>
        <div className={styles.modalHeader}>
          <h2 className={styles.modalTitle}>
            <span>📞</span>
            جميع المكالمات ({calls.length})
          </h2>
          <button onClick={onClose} className={styles.closeButton}>
            &times;
          </button>
        </div>
        <div className={styles.modalBody}>
          <div className={styles.tableContainer}>
            <table className={styles.callsTable}>
              <thead>
                <tr>
                  <th>#</th>
                  <th>النوع</th>
                  <th>التاريخ</th>
                  <th>الوقت</th>
                  <th>الفئة</th>
                  <th>المدة</th>
                  <th>المسؤول</th>
                  <th>الشركة</th>
                  <th>الوصف</th>
                  <th>الملاحظات</th>
                </tr>
              </thead>
              <tbody>
                {calls.map((call, index) => (
                  <tr key={call.id} className={styles.callRow}>
                    <td>{index + 1}</td>
                    <td>
                      <div className={`${styles.callType} ${call.callType === '0' ? styles.incoming : styles.outgoing}`}>
                        <span role="img" aria-label={call.callType === '0' ? "Incoming call" : "Outgoing call"}>
                          {call.callType === '0' ? '↙️' : '↗️'}
                        </span>
                        {call.callType === '0' ? 'واردة' : 'صادرة'}
                      </div>
                    </td>
                    <td>{formatDate(call.createdAt)}</td>
                    <td>{formatTime(call.createdAt)}</td>
                    <td>
                      <span className={styles.category}>{call.category}</span>
                    </td>
                    <td>
                      <span className={styles.duration}>⏱️ {call.callDuration}</span>
                    </td>
                    <td>
                      <span className={styles.agent}>👤 {call.createdBy}</span>
                    </td>
                    <td>
                      <span className={styles.company}>🏢 {getCompanyName(call.companyId)}</span>
                    </td>
                    <td>
                      <span className={styles.description}>{call.description || '-'}</span>
                    </td>
                    <td>
                      <span className={styles.notes}>{call.notes || '-'}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {calls.length === 0 && (
              <div className={styles.emptyState}>
                <span>📞</span>
                <p>لا توجد مكالمات مسجلة</p>
              </div>
            )}
          </div>
        </div>
        <div className={styles.modalFooter}>
          <button onClick={onClose} className={`${styles.button} ${styles.closeBtn}`}>
            إغلاق
          </button>
        </div>
      </div>
    </div>
  );
}