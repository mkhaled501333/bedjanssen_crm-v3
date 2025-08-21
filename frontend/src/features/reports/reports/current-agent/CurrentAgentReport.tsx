'use client';

import React, { useState, useEffect } from 'react';
import { format } from 'date-fns';
import { Calendar, Phone, Clock, TrendingUp, Download, RefreshCw } from 'lucide-react';
import type { CurrentAgentProps, CallFilters } from './types';
import { getCurrentAgentCalls, exportCurrentAgentReport } from './api';
import { getCurrentUserId } from '@/shared/utils/auth';
import SummaryTab from './components/SummaryTab';
import CallsTab from './components/CallsTab';
import ActivityTab from './components/ActivityTab';
import styles from './CurrentAgentReport.module.css';

const CurrentAgentReport: React.FC<CurrentAgentProps> = ({
  data,
  loading: externalLoading,
  error: externalError,
  onRefresh,
  onExport,
  onDateRangeChange
}) => {
  const [activeTab, setActiveTab] = useState('summary');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [reportData, setReportData] = useState(data);
  const [tabLoading, setTabLoading] = useState(false);
  
  // Get current user ID from auth context
  const currentUserId = getCurrentUserId();
  
  const [filters, setFilters] = useState<CallFilters>({
    userId: currentUserId || 1, // Fallback to 1 if no user found
    startDate: format(new Date().setDate(new Date().getDate() - 30), 'yyyy-MM-dd'),
    endDate: format(new Date(), 'yyyy-MM-dd'),
  });

  useEffect(() => {
    if (data) {
      setReportData(data);
    }
  }, [data]);

  useEffect(() => {
    if (externalError) {
      setError(externalError);
    }
  }, [externalError]);

  // Update filters when user ID changes
  useEffect(() => {
    if (currentUserId) {
      setFilters(prev => ({ ...prev, userId: currentUserId }));
    }
  }, [currentUserId]);

  // Fetch data when filters change
  useEffect(() => {
    if (filters.userId && !data) {
      handleRefresh();
    }
  }, [filters.userId, data]);

  const handleRefresh = async () => {
    if (onRefresh) {
      onRefresh();
      return;
    }

    setLoading(true);
    setError(null);
    
    try {
      const newData = await getCurrentAgentCalls(filters);
      setReportData(newData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch report data');
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async (format: 'pdf' | 'excel' | 'csv') => {
    if (onExport) {
      onExport();
      return;
    }

    try {
      const blob = await exportCurrentAgentReport(filters, format);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `agent-report-${filters.startDate}-${filters.endDate}.${format}`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to export report');
    }
  };

  const handleDateRangeChange = (startDate: string, endDate: string) => {
    const newFilters = { ...filters, startDate, endDate };
    setFilters(newFilters);
    
    if (onDateRangeChange) {
      onDateRangeChange(startDate, endDate);
    }
  };

  const handleTabChange = async (tabId: string) => {
    setTabLoading(true);
    setActiveTab(tabId);
    
    // Simulate data loading
    setTimeout(() => {
      setTabLoading(false);
    }, 1000);
  };

  const tabs = [
    { id: 'summary', name: 'Summary', icon: TrendingUp },
    { id: 'calls', name: 'Calls', icon: Phone },
    { id: 'activity', name: 'Activity', icon: Clock },
  ];

  const isLoading = loading || externalLoading;

  return (
    <div className={styles.container}>
      {/* Compact Header */}
      <div className={styles.compactHeader}>
        <div className={styles.dateRange}>
          <Calendar className={styles.calendarIcon} />
          <input
            type="date"
            value={filters.startDate}
            onChange={(e) => handleDateRangeChange(e.target.value, filters.endDate)}
            className={styles.dateInput}
          />
          <span>to</span>
          <input
            type="date"
            value={filters.endDate}
            onChange={(e) => handleDateRangeChange(filters.startDate, e.target.value)}
            className={styles.dateInput}
          />
        </div>
        
        <div className={styles.actions}>
          <button
            onClick={handleRefresh}
            disabled={isLoading}
            className={styles.actionButton}
          >
            <RefreshCw className={`${styles.icon} ${isLoading ? styles.spinning : ''}`} />
            Refresh
          </button>
          
          <button className={styles.actionButton}>
            <Download className={styles.icon} />
            Export
          </button>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className={styles.error}>
          <p>{error}</p>
          <button onClick={handleRefresh} className={styles.retryButton}>
            Try Again
          </button>
        </div>
      )}

      {/* Tabs */}
      <div className={styles.tabs}>
        {tabs.map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.id}
              onClick={() => handleTabChange(tab.id)}
              className={`${styles.tab} ${activeTab === tab.id ? styles.activeTab : ''}`}
            >
              <Icon className={styles.tabIcon} />
              {tab.name}
            </button>
          );
        })}
      </div>

      {/* Tab Content */}
      <div className={styles.tabContent}>
        {isLoading || tabLoading ? (
          <div className={styles.loading}>
            <RefreshCw className={styles.spinning} />
            <p>Loading report data...</p>
          </div>
        ) : (
          <>
            {activeTab === 'summary' && (
              <div className={styles.placeholder}>
                <h3>Summary Tab</h3>
                <p>Summary content will be implemented later</p>
              </div>
            )}
            {activeTab === 'calls' && (
              <div className={styles.callsTableContainer}>
                <div className={styles.tableHeader}>
                  <h3>Calls List</h3>
                </div>
                <table className={styles.callsTable}>
                  <thead>
                    <tr>
                      <th>الملاحظات</th>
                      <th>الوصف</th>
                      <th>الفئة</th>
                      <th>التحميل</th>
                      <th>الوكيل</th>
                      <th>المدة</th>
                      <th>النوع</th>
                      <th>التاريخ</th>
                      <th>#</th>
                    </tr>
                  </thead>
                  <tbody>
                    {reportData && reportData.calls ? (
                      reportData.calls.map((call, index) => {
                        const formatDuration = (seconds) => {
                          const minutes = Math.floor(seconds / 60);
                          const remainingSeconds = seconds % 60;
                          return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
                        };
                        
                        const formatDate = (dateString) => {
                          // Display the raw date string as received from database
                          return dateString;
                        };
                        
                        return (
                           <tr key={`call-${call.id || call.createdAt || index}-${index}`}>
                             <td>{call.callNotes || ''}</td>
                             <td>{call.description || ''}</td>
                             <td>{call.category || ''}</td>
                             <td>{call.customerName || call.customerPhone || ''}</td>
                             <td>{call.createdBy || 'janssen'}</td>
                             <td>{formatDuration(call.callDuration || 0)}</td>
                             <td className={call.callType === 'incoming' ? styles.incomingBadge : styles.outgoingBadge}>
                               {call.callType === 'incoming' ? 'واردة' : 'صادرة'}
                             </td>
                             <td>{formatDate(call.createdAt)}</td>
                             <td>{index + 1}</td>
                           </tr>
                         );
                      })
                    ) : (
                      <tr>
                        <td colSpan={9} style={{ textAlign: 'center', padding: '20px', color: '#6b7280' }}>
                          لا توجد مكالمات متاحة
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            )}
            {activeTab === 'activity' && (
              <div className={styles.placeholder}>
                <h3>Activity Tab</h3>
                <p>Activity content will be implemented later</p>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
};

export default CurrentAgentReport;