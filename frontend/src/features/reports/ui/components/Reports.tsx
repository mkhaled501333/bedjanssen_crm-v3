import React, { useState } from 'react';
import { TicketReport } from './TicketReport';

export const Reports: React.FC = () => {
  const [activeSubTab, setActiveSubTab] = useState('reports-list');
  const [subTabs, setSubTabs] = useState([
    { id: 'reports-list', name: 'Reports List', icon: '📋', type: 'reports-list', canClose: false }
  ]);

  const handleSubTabClick = (tabId: string) => {
    setActiveSubTab(tabId);
  };

  const closeSubTab = (tabId: string) => {
    if (tabId === 'reports-list') return; // Cannot close the fixed first tab
    setSubTabs(prevTabs => prevTabs.filter(tab => tab.id !== tabId));
    if (activeSubTab === tabId) {
      setActiveSubTab('reports-list');
    }
  };

  const openReportTab = (reportType: string, reportName: string, reportIcon: string) => {
    // Check if a tab of this type already exists
    const existingTab = subTabs.find(tab => tab.type === reportType);
    
    if (existingTab) {
      // If tab exists, just switch to it
      setActiveSubTab(existingTab.id);
    } else {
      // If tab doesn't exist, create a new one
      const newTabId = `${reportType}-${Date.now()}`;
      const newTab = {
        id: newTabId,
        name: reportName,
        icon: reportIcon,
        type: reportType,
        canClose: true
      };
      
      setSubTabs(prevTabs => [...prevTabs, newTab]);
      setActiveSubTab(newTabId);
    }
  };

  const renderSubTabContent = () => {
    if (activeSubTab === 'reports-list') {
      return (
        <div style={{ padding: '20px' }}>
          <h2>Available Reports</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '20px', marginTop: '20px' }}>
            <div style={{ border: '1px solid #ddd', borderRadius: '8px', padding: '20px', backgroundColor: '#f9f9f9' }}>
              <h3>Customer Reports</h3>
              <p>Generate reports about customer data, activities, and interactions.</p>
              <button 
                onClick={() => openReportTab('customer-reports', 'Customer Reports', '👥')}
                style={{ 
                  backgroundColor: '#1abc9c', 
                  color: 'white', 
                  border: 'none', 
                  padding: '8px 16px', 
                  borderRadius: '4px', 
                  cursor: 'pointer' 
                }}
              >
                Open Report
              </button>
            </div>
            
            <div style={{ border: '1px solid #ddd', borderRadius: '8px', padding: '20px', backgroundColor: '#f9f9f9' }}>
              <h3>Ticket Reports</h3>
              <p>Analyze ticket data, performance metrics, and resolution times.</p>
              <button 
                onClick={() => openReportTab('ticket-reports', 'Ticket Reports', '🎫')}
                style={{ 
                  backgroundColor: '#1abc9c', 
                  color: 'white', 
                  border: 'none', 
                  padding: '8px 16px', 
                  borderRadius: '4px', 
                  cursor: 'pointer' 
                }}
              >
                Open Report
              </button>
            </div>
            
            <div style={{ border: '1px solid #ddd', borderRadius: '8px', padding: '20px', backgroundColor: '#f9f9f9' }}>
              <h3>Activity Reports</h3>
              <p>Track user activities, system usage, and audit logs.</p>
              <button 
                onClick={() => openReportTab('activity-reports', 'Activity Reports', '📊')}
                style={{ 
                  backgroundColor: '#1abc9c', 
                  color: 'white', 
                  border: 'none', 
                  padding: '8px 16px', 
                  borderRadius: '4px', 
                  cursor: 'pointer' 
                }}
              >
                Open Report
              </button>
            </div>
          </div>
        </div>
      );
    }
    
         // For other tabs, show the report content
     const activeTabData = subTabs.find(tab => tab.id === activeSubTab);
     if (activeTabData && activeTabData.type !== 'reports-list') {
       if (activeTabData.type === 'ticket-reports') {
         return <TicketReport />;
       }
       return (
         <div style={{ padding: '20px' }}>
           <h2>{activeTabData.name}</h2>
           <p>{activeTabData.name} content will be displayed here.</p>
         </div>
       );
     }
    
    return (
      <div style={{ padding: '20px' }}>
        <h2>Reports</h2>
        <p>Select a report type from the tabs above.</p>
      </div>
    );
  };

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Subtabs Header */}
      <div style={{ 
        borderBottom: '1px solid #ddd', 
        backgroundColor: '#f5f5f5',
        display: 'flex',
        overflowX: 'auto'
      }}>
        {subTabs.map((tab) => (
          <div
            key={tab.id}
            style={{
              display: 'flex',
              alignItems: 'center',
              padding: '12px 20px',
              borderRight: '1px solid #ddd',
              backgroundColor: activeSubTab === tab.id ? '#1abc9c' : 'transparent',
              color: activeSubTab === tab.id ? 'white' : '#333',
              cursor: 'pointer',
              minWidth: 'fit-content',
              position: 'relative'
            }}
            onClick={() => handleSubTabClick(tab.id)}
          >
            <span style={{ marginRight: '8px' }}>{tab.icon}</span>
            <span>{tab.name}</span>
            {tab.canClose && (
              <span 
                style={{ 
                  marginLeft: '12px', 
                  fontSize: '18px', 
                  fontWeight: 'bold',
                  color: activeSubTab === tab.id ? 'white' : '#666'
                }}
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

      {/* Subtabs Content */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        {renderSubTabContent()}
      </div>
    </div>
  );
};
