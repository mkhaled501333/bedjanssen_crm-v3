import React, { useState } from 'react';
import styles from './Reports.module.css';
import { TicketsReport } from './tickets-report';

export const Reports: React.FC = () => {
  const [activeSubTab, setActiveSubTab] = useState('reports-list');
  const [subTabs, setSubTabs] = useState([
    { id: 'reports-list', name: 'Reports List', icon: '📋', type: 'reports-list' }
  ]);

  const addSubTab = (name: string, type: string) => {
    // Check if a tab with this type already exists
    const existingTab = subTabs.find(tab => tab.type === type);
    if (existingTab) {
      // If tab exists, just switch to it instead of creating a new one
      setActiveSubTab(existingTab.id);
      return;
    }
    
    const newTabId = `${type}-${Date.now()}`;
    const newTab = {
      id: newTabId,
      name: name,
      icon: '📊',
      type: type
    };
    setSubTabs(prev => [...prev, newTab]);
    setActiveSubTab(newTabId);
  };

  const closeSubTab = (tabId: string) => {
    if (tabId === 'reports-list') return; // Cannot close the fixed first tab
    setSubTabs(prev => prev.filter(tab => tab.id !== tabId));
    if (activeSubTab === tabId) {
      setActiveSubTab('reports-list');
    }
  };

  const renderSubTabContent = () => {
    // Find the active tab data to get its type
    const activeTabData = subTabs.find(tab => tab.id === activeSubTab);
    const activeTabType = activeTabData?.type || 'reports-list';
    
    switch (activeTabType) {
      case 'reports-list':
        return (
          <div className={styles.contentContainer}>
            <h2 className={styles.contentTitle}>Available Reports</h2>
            <div className={styles.reportsGrid}>
              <div 
                className={`${styles.reportCard} ${styles.customerReportsCard}`}
                onClick={() => addSubTab('Customer Reports', 'customer-reports')}
              >
                <h3 className={styles.reportCardTitle}>👥 Customer Reports</h3>
                <p className={styles.reportCardText}>Generate reports on customer data, activities, and interactions</p>
              </div>
              
              <div 
                className={`${styles.reportCard} ${styles.ticketReportsCard}`}
                onClick={() => addSubTab('Ticket Reports', 'ticket-reports')}
              >
                <h3 className={styles.reportCardTitle}>🎫 Ticket Reports</h3>
                <p className={styles.reportCardText}>Analyze ticket data, performance metrics, and trends</p>
              </div>
              
              <div 
                className={`${styles.reportCard} ${styles.callReportsCard}`}
                onClick={() => addSubTab('Call Reports', 'call-reports')}
              >
                <h3 className={styles.reportCardTitle}>📞 Call Reports</h3>
                <p className={styles.reportCardText}>Review call logs, duration, and customer service metrics</p>
              </div>
              
              <div 
                className={`${styles.reportCard} ${styles.performanceReportsCard}`}
                onClick={() => addSubTab('Performance Reports', 'performance-reports')}
              >
                <h3 className={styles.reportCardTitle}>📈 Performance Reports</h3>
                <p className={styles.reportCardText}>Track team performance, productivity, and KPIs</p>
              </div>
            </div>
          </div>
        );
      
      case 'customer-reports':
        return (
          <div className={styles.contentContainer}>
            <h2 className={styles.contentTitle}>Customer Reports</h2>
            <div className={styles.placeholderContent}>
              <p className={styles.placeholderText}>
                Customer Reports functionality coming soon...
              </p>
            </div>
          </div>
        );
      
      case 'ticket-reports':
        return <TicketsReport />;
      
      case 'call-reports':
        return (
          <div className={styles.contentContainer}>
            <h2 className={styles.contentTitle}>Call Reports</h2>
            <div className={styles.placeholderContent}>
              <p className={styles.placeholderText}>
                Call Reports functionality coming soon...
              </p>
            </div>
          </div>
        );
      
      case 'performance-reports':
        return (
          <div className={styles.contentContainer}>
            <h2 className={styles.contentTitle}>Performance Reports</h2>
            <div className={styles.placeholderContent}>
              <p className={styles.placeholderText}>
                Performance Reports functionality coming soon...
              </p>
            </div>
          </div>
        );
      
      default:
        return (
          <div className={styles.contentContainer}>
            <h2 className={styles.contentTitle}>Report</h2>
            <div className={styles.placeholderContent}>
              <p className={styles.placeholderText}>
                Report functionality coming soon...
              </p>
            </div>
          </div>
        );
    }
  };

  return (
    <div className={styles.reportsContainer}>
      {/* Sub-tabs Header */}
      <div className={styles.subTabsHeader}>
        <div className={styles.subTabsContainer}>
          {subTabs.map((tab) => (
            <div
              key={tab.id}
              className={`${styles.subTabItem} ${activeSubTab === tab.id ? styles.active : ''}`}
              onClick={() => setActiveSubTab(tab.id)}
            >
              <span className={styles.subTabIcon}>{tab.icon}</span>
              <span className={styles.subTabName}>
                {tab.name}
              </span>
              {tab.id !== 'reports-list' && (
                <span 
                  className={styles.subTabClose}
                  onClick={(e) => {
                    e.stopPropagation();
                    closeSubTab(tab.id);
                  }}
                >
                  ×
                </span>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Sub-tab Content */}
      <div className={styles.subTabContent}>
        {renderSubTabContent()}
      </div>
    </div>
  );
};
