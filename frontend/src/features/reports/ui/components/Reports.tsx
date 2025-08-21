'use client';

import React, { useState } from 'react';
import { CurrentAgentReport } from '../../reports/current-agent';
import { TicketsReport } from '../../reports/tickets';
import { ReportCard } from './ReportCard';
import { AVAILABLE_REPORTS } from '../../config/reportsConfig';
import { ReportConfig } from '../../types';
import styles from './Reports.module.css';

export function Reports(): JSX.Element {
  const [selectedReport, setSelectedReport] = useState<ReportConfig | null>(null);
  const [openTabs, setOpenTabs] = useState<ReportConfig[]>([]);
  const [activeTab, setActiveTab] = useState<string>('all-reports');

  const handleReportClick = (report: ReportConfig) => {
    // Check if tab is already open
    const existingTab = openTabs.find(tab => tab.id === report.id);
    
    if (!existingTab) {
      // Add new tab
      setOpenTabs(prev => [...prev, report]);
    }
    
    // Set as active tab
    setActiveTab(report.id);
    setSelectedReport(report);
  };

  const handleTabClose = (reportId: string) => {
    // Prevent closing the "All Reports" tab
    if (reportId === 'all-reports') return;
    
    setOpenTabs(prev => {
      const newTabs = prev.filter(tab => tab.id !== reportId);
      
      // If closing active tab, switch to another tab or go back to all reports
      if (activeTab === reportId) {
        if (newTabs.length > 0) {
          const newActiveTab = newTabs[newTabs.length - 1];
          setActiveTab(newActiveTab.id);
          setSelectedReport(newActiveTab);
        } else {
          setActiveTab('all-reports');
          setSelectedReport(null);
        }
      }
      
      return newTabs;
    });
  };

  const handleBackToDashboard = () => {
    setSelectedReport(null);
    setActiveTab('all-reports');
  };

  const renderReportContent = (report: ReportConfig) => {
    switch (report.type) {
      case 'current-agent':
        return <CurrentAgentReport />;
      case 'tickets-report':
        return <TicketsReport />;
      default:
        return (
          <div className={styles.placeholder}>
            <h3>{report.name}</h3>
            <p>This report is coming soon...</p>
          </div>
        );
    }
  };

  const renderTabContent = () => {
    if (activeTab === 'all-reports') {
      return (
        <div style={{ padding: '24px' }}>
          <h1 style={{ fontSize: '24px', fontWeight: '600', color: '#1f2937', margin: '0 0 24px 0' }}>
            All Reports
          </h1>
          <div className={styles.reportsGrid}>
            {AVAILABLE_REPORTS.map((report, index) => (
              <ReportCard
                key={report.id}
                report={report}
                index={index + 1}
                onClick={() => handleReportClick(report)}
              />
            ))}
          </div>
        </div>
      );
    }
    
    if (selectedReport) {
      return renderReportContent(selectedReport);
    }
    
    return null;
  };

  return (
    <div className={styles.reportsContainer}>
      <div className={styles.reportWrapper}>
        {/* Tabs section - always visible */}
        <div className={styles.tabsSection}>
          <div className={styles.tabsHeader}>
            <div className={styles.tabsList}>
              {/* Fixed "All Reports" tab */}
              <div
                className={`${styles.tab} ${activeTab === 'all-reports' ? styles.activeTab : ''}`}
                onClick={() => {
                  setActiveTab('all-reports');
                  setSelectedReport(null);
                }}
              >
                <span className={styles.tabIcon}>📊</span>
                <span className={styles.tabName}>All Reports</span>
              </div>
              
              {/* Dynamic report tabs */}
              {openTabs.map((tab) => (
                <div
                  key={tab.id}
                  className={`${styles.tab} ${activeTab === tab.id ? styles.activeTab : ''}`}
                  onClick={() => {
                    setActiveTab(tab.id);
                    setSelectedReport(tab);
                  }}
                >
                  <span className={styles.tabIcon}>{tab.icon}</span>
                  <span className={styles.tabName}>{tab.name}</span>
                  <button
                    className={styles.tabCloseBtn}
                    onClick={(e) => {
                      e.stopPropagation();
                      handleTabClose(tab.id);
                    }}
                  >
                    ×
                  </button>
                </div>
              ))}
            </div>
          </div>
          <div className={styles.tabContent}>
            {renderTabContent()}
          </div>
        </div>
      </div>
    </div>
  );
}