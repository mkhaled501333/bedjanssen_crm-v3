'use client';

import React, { useState, useEffect, ChangeEvent, useMemo } from 'react';
import styles from '@/app/masterdata.module.css';
import * as api from '../../api';

import type { 
  Governorate, 
  Company 
} from '../../types';

type TabType = 'cities' | 'call-categories' | 'ticket-categories' | 'request-reasons' | 'products';

interface TabConfig {
  id: TabType;
  name: string;
  columns: Array<{ key: string; label:string; }>;
  fetchData: () => Promise<Record<string, unknown>[]>;
  createItem: (data: Record<string, unknown>) => Promise<unknown>;
}

interface NewItemData {
  [key: string]: string;
  governorate_id?: string;
  company_id?: string;
  product_name?: string;
  name?: string;
}

export function MasterData() {
  const [activeTab, setActiveTab] = useState<TabType>('cities');

  const [data, setData] = useState<Record<string, unknown>[]>([]); // Use any[] for compatibility with API and rendering
  const [governorates, setGovernorates] = useState<Governorate[]>([]);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [newItemData, setNewItemData] = useState<NewItemData>({});

  const tabs: TabConfig[] = useMemo(() => [
    {
      id: 'cities',
      name: 'Cities',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'name', label: 'Name' },
        { key: 'governorate_name', label: 'Governorate' },
        { key: 'created_at', label: 'Created At' },
        { key: 'updated_at', label: 'Updated At' },
      ],
      fetchData: async () => {
        const [cities, governoratesData] = await Promise.all([api.getCities(), api.getGovernorates()]);
        const governorateMap = new Map(governoratesData.map(g => [g.id, g.name]));
        return cities.map(city => ({
          ...city,
          governorate_name: governorateMap.get(city.governorate_id) || 'Unknown'
        }));
      },
      createItem: (data) => api.createCity((data.name as string), parseInt(data.governorate_id as string)),
    },
    {
      id: 'call-categories',
      name: 'Call Categories',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'name', label: 'Name' },
        { key: 'created_at', label: 'Created At' },
        { key: 'updated_at', label: 'Updated At' },
      ],
      fetchData: async () => {
        const callCategoriesData = await api.getCallCategories();
        const callCategories = Array.isArray(callCategoriesData)
          ? (callCategoriesData as unknown[])
              .filter(obj => typeof obj === 'object' && obj !== null)
              .map(obj => ({ ...(obj as Record<string, unknown>) })) as Record<string, unknown>[]
          : (((callCategoriesData as { data?: unknown[] })?.data ?? [])
              .filter(obj => typeof obj === 'object' && obj !== null)
              .map(obj => ({ ...(obj as Record<string, unknown>) })) as Record<string, unknown>[]);
        return callCategories;
      },
      createItem: (data) => api.createCallCategory(data.name as string),
    },
    {
      id: 'ticket-categories',
      name: 'Ticket Categories',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'name', label: 'Name' },
        { key: 'created_at', label: 'Created At' },
        { key: 'updated_at', label: 'Updated At' },
      ],
      fetchData: async () => {
        const ticketCategoriesData = await api.getTicketCategories();
        const ticketCategories = Array.isArray(ticketCategoriesData)
          ? (ticketCategoriesData as unknown[])
              .filter(obj => typeof obj === 'object' && obj !== null)
              .map(obj => ({ ...(obj as Record<string, unknown>) })) as Record<string, unknown>[]
          : (((ticketCategoriesData as { data?: unknown[] })?.data ?? [])
              .filter(obj => typeof obj === 'object' && obj !== null)
              .map(obj => ({ ...(obj as Record<string, unknown>) })) as Record<string, unknown>[]);
        return ticketCategories;
      },
      createItem: (data) => api.addTicketCategory(data.name as string),
    },
    {
      id: 'request-reasons',
      name: 'Request Reasons',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'name', label: 'Name' },
        { key: 'created_at', label: 'Created At' },
        { key: 'updated_at', label: 'Updated At' },
      ],
      fetchData: async () => {
        const requestReasonsData = await api.getRequestReasons();
        const requestReasons = Array.isArray(requestReasonsData)
          ? (requestReasonsData as unknown[])
              .filter(obj => typeof obj === 'object' && obj !== null)
              .map(obj => ({ ...(obj as Record<string, unknown>) })) as Record<string, unknown>[]
          : (((requestReasonsData as { data?: unknown[] })?.data ?? [])
              .filter(obj => typeof obj === 'object' && obj !== null)
              .map(obj => ({ ...(obj as Record<string, unknown>) })) as Record<string, unknown>[]);
        return requestReasons;
      },
      createItem: (data) => api.createRequestReason(data.name as string),
    },
    {
      id: 'products',
      name: 'Products',
      columns: [
        { key: 'id', label: 'ID' },
        { key: 'product_name', label: 'Product Name' },
        { key: 'company_name', label: 'Company' },
        { key: 'created_at', label: 'Created At' },
        { key: 'updated_at', label: 'Updated At' },
      ],
      fetchData: async () => {
        const [products, companiesData] = await Promise.all([api.getProducts(), api.getCompanies()]);
        const companyMap = new Map(companiesData.map(c => [c.id, c.name]));
        return products.map(product => ({
          ...product,
          company_name: companyMap.get(product.company_id) || 'Unknown'
        }));
      },
      createItem: (data) => api.createProduct(data.product_name as string, parseInt(data.company_id as string)),
    },
  ], []);

  const currentTab = useMemo(() => tabs.find(tab => tab.id === activeTab)!, [tabs, activeTab]);
  const nameKey = activeTab === 'products' ? 'product_name' : 'name';

  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      setError(null);
      try {
        const result = await currentTab.fetchData();
        setData(result);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load data');
      } finally {
        setLoading(false);
      }
    };
    loadData();
    if (activeTab === 'cities') {
      loadGovernorates();
    }
    if (activeTab === 'products') {
      loadCompanies();
    }
  }, [activeTab, currentTab]);

  const loadGovernorates = async () => {
    try {
      const result = await api.getGovernorates();
      setGovernorates(result);
    } catch (err) {
      console.error('Failed to load governorates:', err);
    }
  };

  const loadCompanies = async () => {
    try {
      const result = await api.getCompanies();
      setCompanies(result);
    } catch (err) {
      console.error('Failed to load companies:', err);
    }
  };

  const handleAdd = async () => {
    if (isAddFormInvalid()) {
      let message = 'Name field is required.';
      if (activeTab === 'cities' && !newItemData.governorate_id) {
        message = 'Please select a governorate.';
      } else if (activeTab === 'products' && !newItemData.company_id) {
        message = 'Please select a company.';
      }
      setError(message);
      return;
    }

    try {
      setError(null);
      await currentTab.createItem(newItemData);
      // Duplicate the loadData logic here
      setLoading(true);
      setError(null);
      try {
        const result = await currentTab.fetchData();
        setData(result);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load data');
      } finally {
        setLoading(false);
      }
      setShowAddForm(false);
      setNewItemData({});
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create item');
    }
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '-';
    // Display the raw date string as received from database
    return dateString;
  };
  
  const isAddFormInvalid = () => {
    if (!newItemData[nameKey] || (newItemData[nameKey] as string).trim() === '') {
      return true;
    }
    if (activeTab === 'cities' && !newItemData.governorate_id) {
      return true;
    }
    if (activeTab === 'products' && !newItemData.company_id) {
      return true;
    }
    return false;
  };

  const renderAddForm = () => {
    if (!showAddForm) return null;

    return (
      <tr>
        {currentTab.columns.map((column) => {
          if (column.key === 'id' || column.key === 'created_at' || column.key === 'updated_at') {
            return <td key={column.key}>-</td>;
          }
          if (activeTab === 'cities' && column.key === 'governorate_name') {
            return (
              <td key={column.key}>
                <select
                  value={newItemData.governorate_id || ''}
                  onChange={(e: ChangeEvent<HTMLSelectElement>) => setNewItemData({ ...newItemData, governorate_id: e.target.value })}
                  style={{ width: '100%', padding: '4px' }}
                >
                  <option value="">Select Governorate</option>
                  {governorates.map((gov) => (
                    <option key={gov.id} value={gov.id}>
                      {gov.name}
                    </option>
                  ))}
                </select>
              </td>
            );
          }
          if (activeTab === 'products' && column.key === 'company_name') {
            return (
              <td key={column.key}>
                <select
                  value={newItemData.company_id || ''}
                  onChange={(e: ChangeEvent<HTMLSelectElement>) => setNewItemData({ ...newItemData, company_id: e.target.value })}
                  style={{ width: '100%', padding: '4px' }}
                >
                  <option value="">Select Company</option>
                  {companies.map((co) => (
                    <option key={co.id} value={co.id}>
                      {co.name}
                    </option>
                  ))}
                </select>
              </td>
            );
          }
          if(column.key === nameKey) {
            return (
              <td key={column.key}>
                <input
                  type='text'
                  placeholder={column.label}
                  value={newItemData[column.key] || ''}
                  onChange={(e: ChangeEvent<HTMLInputElement>) => setNewItemData({ ...newItemData, [column.key]: e.target.value })}
                  style={{ width: '100%', padding: '4px' }}
                />
              </td>
            );
          }
           return <td key={column.key}>-</td>;
        })}
        <td colSpan={2}>
          <button 
            className={`${styles.masterBtn} ${styles.masterBtnEdit}`}
            onClick={handleAdd}
            disabled={isAddFormInvalid()}
          >
            Save
          </button>
          <button 
            className={`${styles.masterBtn} ${styles.masterBtnDelete}`}
            onClick={() => {
              setShowAddForm(false);
              setNewItemData({});
              setError(null);
            }}
          >
            Cancel
          </button>
        </td>
      </tr>
    );
  };
  


  return (
    <div className={styles.masterDataContent}>
      <div className={styles.masterDataWrapper}>
        <div className={styles.masterDataInner}>
          
          <div className={styles.masterNavTabs}>
            {tabs.map((tab) => (
              <button
                key={tab.id}
                className={`${styles.masterNavTab} ${activeTab === tab.id ? styles.masterNavTabActive : ''}`}
                onClick={() => {
                  setActiveTab(tab.id);
                  setError(null); 
                  setShowAddForm(false);
                }}
              >
                {tab.name}
              </button>
            ))}
          </div>
          
          <div className={styles.masterContainer} style={{ padding: '20px' }}>
            {error && (
              <div style={{ 
                padding: '10px', 
                marginBottom: '10px', 
                backgroundColor: '#f44336', 
                color: 'white', 
                borderRadius: '4px' 
              }}>
                {error}
              </div>
            )}
            
            <div style={{ marginBottom: '10px' }}>
              <button
                className={`${styles.masterBtn} ${styles.masterBtnEdit}`}
                onClick={() => {
                  setShowAddForm(true);
                  setError(null);
                }}
                disabled={showAddForm}
              >
                Add New {currentTab.name.slice(0, -1)}
              </button>
            </div>

            <div className={styles.masterTableContainer}>
              <table className={styles.masterTable}>
                <thead>
                  <tr>
                    {currentTab.columns.map((column) => (
                      <th key={column.key}>{column.label}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {renderAddForm()}
                  {loading ? (
                    <tr>
                      <td colSpan={currentTab.columns.length} style={{ textAlign: 'center', padding: '20px' }}>
                        Loading...
                      </td>
                    </tr>
                  ) : data.length === 0 ? (
                    <tr>
                      <td colSpan={currentTab.columns.length} style={{ textAlign: 'center', padding: '20px' }}>
                        No data available
                      </td>
                    </tr>
                  ) : (
                    (data as Record<string, unknown>[]).map((item) => (
                      <tr key={String(item.id)}>
                        {currentTab.columns.map((column) => 
                          <td key={column.key}>{column.key.includes('_at') ? formatDate(String(item[column.key])) : String(item[column.key] ?? '-')}</td>
                        )}
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}