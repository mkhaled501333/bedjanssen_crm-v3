import React, { useState, useEffect } from 'react';
import styles from './ActivityLogsModal.module.css';
import { getApiBaseUrl, authFetch } from '@/shared/utils';

export type ActivityLog = {
  id: number;
  entity_name: string;
  record_id: number;
  activity_name: string;
  username: string;
  activity_description?: string;
  created_at: string;
};

export type ActivityLogsModalProps = {
  onClose: () => void;
  itemId?: number;
  ticketId?: number;
  customerId?: number;
};

function formatDate(dateString: string): string {
  try {
    // Handle different date formats from database
    let date: Date;
    if (dateString.includes('T') || dateString.includes('Z')) {
      // Already in ISO format
      date = new Date(dateString);
    } else {
      // Assume format like "2025-08-03 15:44:55" and treat as UTC
      date = new Date(dateString + 'Z');
    }
    
    if (isNaN(date.getTime())) {
      return dateString; // Return original if parsing fails
    }
    
    return date.toLocaleDateString('en-CA', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      timeZone: 'UTC'
    });
  } catch (error) {
    console.error('Error formatting date:', error);
    return dateString;
  }
}

function formatTime(dateString: string): string {
  try {
    // Handle different date formats from database
    let date: Date;
    if (dateString.includes('T') || dateString.includes('Z')) {
      // Already in ISO format
      date = new Date(dateString);
    } else {
      // Assume format like "2025-08-03 15:44:55" and treat as UTC
      date = new Date(dateString + 'Z');
    }
    
    if (isNaN(date.getTime())) {
      return dateString; // Return original if parsing fails
    }
    
    return date.toLocaleTimeString('en-GB', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
      timeZone: 'UTC'
    });
  } catch (error) {
    console.error('Error formatting time:', error);
    return dateString;
  }
}

export function ActivityLogsModal({ onClose, itemId, ticketId, customerId }: ActivityLogsModalProps) {
  const [activityLogs, setActivityLogs] = useState<ActivityLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchActivityLogs = async () => {
      try {
        setLoading(true);
        setError(null);
        
        let apiUrl: string;
        
        if (ticketId) {
          // Fetch activity logs for tickets entity with the specific ticket record ID
          apiUrl = `${getApiBaseUrl()}/api/activity-logs/entity/tickets/${ticketId}?detailed=true`;
        } else if (itemId) {
          // Fetch activity logs for ticket_items entity with the specific item record ID
          apiUrl = `${getApiBaseUrl()}/api/activity-logs/entity/ticket_items/${itemId}?detailed=true`;
        } else if (customerId) {
          // Fetch activity logs for customers entity with the specific customer record ID
          apiUrl = `${getApiBaseUrl()}/api/activity-logs/entity/customers/${customerId}?detailed=true`;
        } else {
          throw new Error('Either itemId, ticketId, or customerId must be provided');
        }
        
        const response = await authFetch(apiUrl, {
          method: 'GET',
        });

        if (!response.ok) {
          throw new Error(`Failed to fetch activity logs: ${response.statusText}`);
        }

        const result = await response.json();
        
        if (!result.success) {
          throw new Error(result.message || 'Failed to fetch activity logs');
        }

        setActivityLogs(result.data.activityLogs || []);
      } catch (error) {
        console.error('Error fetching activity logs:', error);
        setError(error instanceof Error ? error.message : 'Unknown error occurred');
      } finally {
        setLoading(false);
      }
    };

    fetchActivityLogs();
  }, [itemId, ticketId]);

  return (
    <div className={styles.modalOverlay}>
      <div className={styles.modalContent}>
        <div className={styles.modalHeader}>
          <h2 className={styles.modalTitle}>
            <span>📋</span>
            {ticketId ? `سجل أنشطة التذكرة (${activityLogs.length})` : `سجل الأنشطة للمنتج (${activityLogs.length})`}
          </h2>
          <button onClick={onClose} className={styles.closeButton}>
            &times;
          </button>
        </div>
        <div className={styles.modalBody}>
          {loading ? (
            <div className={styles.loadingState}>
              <span>⏳</span>
              <p>جاري تحميل سجل الأنشطة...</p>
            </div>
          ) : error ? (
            <div className={styles.errorState}>
              <span>❌</span>
              <p>خطأ في تحميل سجل الأنشطة: {error}</p>
            </div>
          ) : (
            <div className={styles.tableContainer}>
              <table className={styles.logsTable}>
                <thead>
                  <tr>
                    <th>#</th>
                    <th>النشاط</th>
                    <th>التاريخ</th>
                    <th>الوقت</th>
                    <th>المستخدم</th>
                    <th>التفاصيل</th>
                  </tr>
                </thead>
                <tbody>
                  {activityLogs.map((log, index) => (
                    <tr key={log.id} className={styles.logRow}>
                      <td>{index + 1}</td>
                      <td>
                        <span className={styles.activity}>{log.activity_name}</span>
                      </td>
                      <td>{formatDate(log.created_at)}</td>
                      <td>{formatTime(log.created_at)}</td>
                      <td>
                        <span className={styles.user}>👤 {log.username}</span>
                      </td>
                      <td>
                        <span className={styles.details}>{log.activity_description || '-'}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {activityLogs.length === 0 && (
                <div className={styles.emptyState}>
                  <span>📋</span>
                  <p>{ticketId ? 'لا توجد أنشطة مسجلة لهذه التذكرة' : 'لا توجد أنشطة مسجلة لهذا المنتج'}</p>
                </div>
              )}
            </div>
          )}
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