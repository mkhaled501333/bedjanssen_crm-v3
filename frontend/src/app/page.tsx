'use client';

import { useState, useEffect, useCallback } from 'react';
import navStyles from './navigation.module.css';
import { SearchBar } from '../features/search';
import { DEFAULT_APPS } from '../shared/constants';
import type { AppType } from '../shared/constants';
import { NewRecordForm } from '../features/records/ui';
import { CustomerData } from '../features/customerdata';
import { MasterData, UserManagement } from '../features/masterdata/ui/components';
import { Reports } from '../features/reports';


import { logout, startTokenMonitoring, stopTokenMonitoring } from '../shared/utils';
import { getCurrentUserName, getCurrentUserCompanyName, hasPermission, isAuthenticated } from '../shared/utils/auth';



export default function Home() {
  const [activeApp, setActiveApp] = useState('mail');
  const [activeTab, setActiveTab] = useState('home');
  const [tabs, setTabs] = useState<Array<{ id: string; name: string; icon: string; type: string; query?: string; customerId?: string }>>([{ id: 'home', name: 'Home', icon: '🏠', type: 'home' }]);
  
  // Form data for multiple NewRecordForm instances to persist across tab switches
  const [newRecordFormData, setNewRecordFormData] = useState<Record<string, Record<string, unknown>>>({});

  // Start token monitoring when component mounts and user is authenticated
  useEffect(() => {
    if (isAuthenticated()) {
      startTokenMonitoring();
    }
    
    // Cleanup on unmount
    return () => {
      stopTokenMonitoring();
    };
  }, []);

  // Customer search suggestions will be dynamically loaded from the CRM backend
  // No static suggestions needed as the SearchBar will fetch real customer data

  const handleSearch = (query: string) => {
    console.log('Search query:', query);
    // Implement search logic here
  };

  const handleAddNew = (query: string) => {
    console.log('Creating new record:', query);
    
    // Create a new tab for the record form
    const newTabId = `new-record-${Date.now()}`;
    const tabName = query ? `New Record: ${query.substring(0, 20)}${query.length > 20 ? '...' : ''}` : 'New Record';
    const newTab = {
      id: newTabId,
      name: tabName,
      icon: '📝',
      type: 'new-record',
      query: query
    };
    
    // Add the new tab and switch to it
    setTabs(prevTabs => [...prevTabs, newTab]);
    setActiveTab(newTabId);
  };

  const closeTab = useCallback((tabId: string) => {
    if (tabId === 'home') return;
    setTabs(tabs.filter(tab => tab.id !== tabId));
    if (activeTab === tabId) {
      setActiveTab('home');
    }
  }, [tabs, activeTab]);

  const handleNewRecordFormChange = useCallback((tabId: string, formData: Record<string, unknown>) => {
    setNewRecordFormData(prev => ({
      ...prev,
      [tabId]: formData
    }));
  }, []);

  const handleCloseNewRecordForm = useCallback((tabId: string) => {
    setNewRecordFormData(prev => {
      const newData = { ...prev };
      delete newData[tabId]; // Remove form data for this specific tab
      return newData;
    });
    closeTab(tabId);
  }, [closeTab]);

  const handleUpdateTabName = useCallback((tabId: string, newName: string) => {
    setTabs(prevTabs => 
      prevTabs.map(tab => 
        tab.id === tabId ? { ...tab, name: newName } : tab
      )
    );
  }, []);

  const handleCustomerClick = (customerId: string, customerName: string) => {
    console.log('Opening customer:', customerId, customerName);
    
    // Check if customer tab already exists
    const existingTab = tabs.find(tab => tab.type === 'customer-data' && tab.customerId === customerId);
    if (existingTab) {
      setActiveTab(existingTab.id);
      return;
    }
    
    // Create a new tab for the customer data
    const newTabId = `customer-${customerId}-${Date.now()}`;
    const newTab = {
      id: newTabId,
      name: customerName,
      icon: '👤',
      type: 'customer-data',
      customerId: customerId
    };
    
    // Add the new tab and switch to it
    setTabs(prevTabs => [...prevTabs, newTab]);
    setActiveTab(newTabId);
  };

  // Filter apps based on user permissions
  const apps = DEFAULT_APPS.filter(app => {
    if (app.requiredPermission) {
      return hasPermission(app.requiredPermission);
    }
    return true; // Show apps without permission requirements
  });

  const handleAppClick = (app: AppType) => {
    setActiveApp(app.id);
    const existingTab = tabs.find(tab => tab.id === app.id);
    if (!existingTab) {
      setTabs([...tabs, { id: app.id, name: app.name, icon: app.icon, type: app.id }]);
    }
    setActiveTab(app.id);
  };

  const handleTabClick = (tabId: string) => {
    setActiveTab(tabId);
  };

  const renderContent = () => {
    if (activeTab === 'home') {
      return (
        <div className={navStyles.homeContent}>
          <div className={navStyles.homeContentInner}>
            <div className={navStyles.homeHeader}>
              <h1 className={navStyles.homeTitle}>Welcome to Janssen CRM</h1>
              <p className={navStyles.homeSubtitle}>Your comprehensive customer relationship management platform. Manage customers, tickets, and business operations efficiently.</p>
            </div>
          </div>
        </div>
      );
    } 
    
    const activeTabData = tabs.find(tab => tab.id === activeTab);

    if (!activeTabData) {
      return (
        <div className={navStyles.defaultContent}>
           <div className={navStyles.defaultContentInner}>
             <h1 className={navStyles.defaultTitle}>Janssen CRM</h1>
             <p className={navStyles.defaultSubtitle}>Select an application from the sidebar to get started.</p>
           </div>
        </div>
      )
    }

    // Render all components but only show the active one
    return (
      <div>
        {/* New Record Forms - render all but only show active */}
        {tabs.filter(tab => tab.type === 'new-record').map(tab => (
          <div key={tab.id} style={{ display: activeTab === tab.id ? 'block' : 'none' }}>
            {tab.query ? (
              <NewRecordForm
                initialQuery={tab.query}
                onSubmit={(customerId, customerName) => {
                  if (customerId) {
                    const newTabId = `customer-${customerId}-${Date.now()}`;
                    setTabs(prevTabs => {
                      const updatedTabs = [
                        ...prevTabs,
                        {
                          id: newTabId,
                          name: customerName || 'Customer',
                          icon: '👤',
                          type: 'customer-data',
                          customerId: customerId.toString(),
                        },
                      ];
                      console.log('Tabs after adding new customer tab:', updatedTabs);
                      return updatedTabs;
                    });
                    console.log('Switching to new tab:', newTabId);
                    setActiveTab(newTabId);
                    // Clear form data for this specific tab after successful submission
                    setNewRecordFormData(prev => {
                      const newData = { ...prev };
                      delete newData[tab.id];
                      return newData;
                    });
                  }
                }}
                onFormChange={(formData) => handleNewRecordFormChange(tab.id, formData)}
                initialFormData={newRecordFormData[tab.id] || null}
                onCancel={() => handleCloseNewRecordForm(tab.id)}
                onTabNameUpdate={(newName) => handleUpdateTabName(tab.id, newName)}
                isActive={activeTab === tab.id}
                tabId={tab.id}
              />
            ) : <p>No query provided</p>}
          </div>
        ))}

        {/* Customer Data - render all but only show active */}
        {tabs.filter(tab => tab.type === 'customer-data').map(tab => (
          <div key={tab.id} style={{ display: activeTab === tab.id ? 'block' : 'none' }}>
            {tab.customerId ? (
              <CustomerData
                customerId={tab.customerId}
                onClose={() => closeTab(tab.id)}
              />
            ) : <p>No customer ID provided</p>}
          </div>
        ))}

        {/* Other components */}
        {activeTabData.type === 'masterdata' && <MasterData />}
        {activeTabData.type === 'usermanagement' && <UserManagement />}
        {activeTabData.type === 'reports' && <Reports />}

        {/* Default content for other types */}
        {!['new-record', 'customer-data', 'masterdata', 'usermanagement', 'reports'].includes(activeTabData.type) && (
          <div className={navStyles.defaultContent}>
            <div className={navStyles.defaultContentInner}>
              <h1 className={navStyles.defaultTitle}>{activeTabData.name}</h1>
              <p className={navStyles.defaultSubtitle}>Content for {activeTabData.name} goes here.</p>
            </div>
          </div>
        )}
      </div>
    );
  };

  return (
    <div className={navStyles.navigationContainer}>
      {/* Main App Drawer */}
      <div className={navStyles.mainDrawer}>
        <div className={navStyles.appGrid}>
          {[...Array(9)].map((_, i) => (
            <div key={i} className={navStyles.gridDot}></div>
          ))}
        </div>

        {apps.map((app) => (
          <div
            key={app.id}
            className={`${navStyles.navItem} ${activeApp === app.id ? navStyles.active : ''}`}
            onClick={() => handleAppClick(app)}
          >
            <div 
              className={navStyles.navIcon} 
              style={{ background: app.gradient }}
            >
              {app.icon}
            </div>
            <div className={navStyles.navLabel}>{app.name}</div>
          </div>
        ))}
      </div>

      {/* Header with Tabs */}
      <div className={navStyles.stickyTabs}>
        <div className={navStyles.headerLeft}>
          {tabs.map((tab) => (
            <div
              key={tab.id}
              className={`${navStyles.tabItem} ${activeTab === tab.id ? navStyles.active : ''} ${tab.id === 'home' ? navStyles.homeTab : ''}`}
              onClick={() => handleTabClick(tab.id)}
            >
              <div className={`${navStyles.tabIcon} ${tab.id === 'home' ? navStyles.homeIcon : ''}`}>
                {tab.icon}
              </div>
              <span className={navStyles.tabTitle}>{tab.name}</span>
              {tab.id !== 'home' && (
                <span 
                  className={navStyles.tabClose} 
                  onClick={(e) => {
                    e.stopPropagation();
                    closeTab(tab.id);
                  }}
                >
                  ×
                </span>
              )}
            </div>
          ))}
        </div>
        
        <div className={navStyles.headerRight}>
          <SearchBar 
            placeholder="Search customers by name or phone..."
            onSearch={handleSearch}
            onAddNew={handleAddNew}
            onCustomerClick={handleCustomerClick}
            showAddNewButton={true}
          />
          <div className={navStyles.userProfile}>
            <div className={navStyles.userDropdown}>
              <div className={navStyles.userInfo}>
                <p>{getCurrentUserName() || 'User'}</p>
                <p className={navStyles.userEmail}>{getCurrentUserCompanyName() || 'Company'}</p>
              </div>
              <button onClick={logout} className={navStyles.logoutBtn}>Logout</button>
            </div>
            <span className={navStyles.dropdownArrow}>▼</span>
          </div>
        </div>
      </div>

      {/* Content Area */}
      <div className={navStyles.contentArea}>
        {renderContent()}
      </div>
    </div>
  );
}
