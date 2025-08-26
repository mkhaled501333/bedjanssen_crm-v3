'use client';

import React, { useState, useEffect, ChangeEvent, useCallback } from 'react';
import styles from '@/app/masterdata.module.css';
import * as api from '../../api';
import type { User, UserCreateRequest, UserUpdateRequest, Company } from '../../types';

interface UserManagementProps {
  onClose?: () => void;
}

const PERMISSIONS = {
  1: 'show user managment',
  2: 'show master data',
};

export function UserManagement({ onClose }: UserManagementProps) {
  const [users, setUsers] = useState<User[]>([]);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [showPermissions, setShowPermissions] = useState<number | null>(null);
  const [userPermissions, setUserPermissions] = useState<number[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [newUserData, setNewUserData] = useState<UserCreateRequest>({
    name: '',
    username: '',
    password: '',
    companyId: 0,
    isActive: true,
    permissions: []
  });

  const loadUsers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await api.getUsers(currentPage, 10, searchTerm);
      setUsers(result.users);
      setTotalPages(Math.ceil(result.total / result.limit));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load users');
    } finally {
      setLoading(false);
    }
  }, [currentPage, searchTerm]);

  useEffect(() => {
    loadUsers();
    loadCompanies();
  }, [currentPage, searchTerm, loadUsers]);

  const loadCompanies = async () => {
    try {
      const result = await api.getCompanies();
      setCompanies(result);
    } catch (err) {
      console.error('Failed to load companies:', err);
    }
  };

  const handleCreateUser = async () => {
    if (!newUserData.name || !newUserData.username || !newUserData.password || !newUserData.companyId) {
      setError('Please fill in all required fields');
      return;
    }

    try {
      setError(null);
      await api.createUser(newUserData);
      await loadUsers();
      setShowAddForm(false);
      setNewUserData({
        name: '',
        username: '',
        password: '',
        companyId: 0,
        isActive: true,
        permissions: []
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create user');
    }
  };

  const handleUpdateUser = async (user: User) => {
    if (!user.name || !user.username || !user.company_id) {
      setError('Please fill in all required fields');
      return;
    }

    try {
      setError(null);
      const updateData: UserUpdateRequest = {
        name: user.name,
        username: user.username,
        companyId: user.company_id,
        isActive: user.is_active,
        permissions: user.permissions
      };
      await api.updateUser(user.id, updateData);
      await loadUsers();
      setEditingUser(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update user');
    }
  };

  // Delete user functionality has been removed for security purposes

  const handleShowPermissions = async (userId: number) => {
    try {
      const result = await api.getUserPermissions(userId);
      setUserPermissions(result.permissions);
      setShowPermissions(userId);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load permissions');
    }
  };

  const handleUpdatePermissions = async (userId: number, permissions: number[]) => {
    try {
      setError(null);
      await api.updateUserPermissions(userId, permissions);
      setUserPermissions(permissions);
      await loadUsers();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update permissions');
    }
  };

  const togglePermission = (permissionId: number) => {
    const newPermissions = userPermissions.includes(permissionId)
      ? userPermissions.filter(p => p !== permissionId)
      : [...userPermissions, permissionId];
    setUserPermissions(newPermissions);
  };

  const formatDate = (dateString?: string) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString();
  };

  const getCompanyName = (companyId?: number) => {
    const company = companies.find(c => c.id === companyId);
    return company?.name || 'Unknown';
  };

  const renderPermissionsModal = () => {
    if (!showPermissions) return null;

    return (
      <div style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(0,0,0,0.5)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000
      }}>
        <div style={{
          backgroundColor: 'white',
          padding: '20px',
          borderRadius: '8px',
          maxWidth: '600px',
          maxHeight: '80vh',
          overflow: 'auto',
          width: '90%'
        }}>
          <h3>Manage User Permissions</h3>
          <div style={{ marginBottom: '20px' }}>
            {Object.entries(PERMISSIONS).map(([id, name]) => (
              <label key={id} style={{ display: 'block', marginBottom: '8px' }}>
                <input
                  type="checkbox"
                  checked={userPermissions.includes(parseInt(id))}
                  onChange={() => togglePermission(parseInt(id))}
                  style={{ marginRight: '8px' }}
                />
                {name}
              </label>
            ))}
          </div>
          <div>
            <button
              className={`${styles.masterBtn} ${styles.masterBtnEdit}`}
              onClick={() => {
                handleUpdatePermissions(showPermissions, userPermissions);
                setShowPermissions(null);
              }}
              style={{ marginRight: '10px' }}
            >
              Save Permissions
            </button>
            <button
              className={`${styles.masterBtn} ${styles.masterBtnDelete}`}
              onClick={() => setShowPermissions(null)}
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    );
  };

  const renderAddForm = () => {
    if (!showAddForm) return null;

    return (
      <tr>
        <td>-</td>
        <td>
          <input
            type="text"
            placeholder="Name"
            value={newUserData.name}
            onChange={(e: ChangeEvent<HTMLInputElement>) => 
              setNewUserData({ ...newUserData, name: e.target.value })
            }
            style={{ width: '100%', padding: '4px' }}
          />
        </td>
        <td>
          <input
            type="text"
            placeholder="Username"
            value={newUserData.username}
            onChange={(e: ChangeEvent<HTMLInputElement>) => 
              setNewUserData({ ...newUserData, username: e.target.value })
            }
            style={{ width: '100%', padding: '4px' }}
          />
        </td>
        <td>
          <input
            type="password"
            placeholder="Password"
            value={newUserData.password}
            onChange={(e: ChangeEvent<HTMLInputElement>) => 
              setNewUserData({ ...newUserData, password: e.target.value })
            }
            style={{ width: '100%', padding: '4px' }}
          />
        </td>
        <td>
          <select
            value={newUserData.companyId}
            onChange={(e: ChangeEvent<HTMLSelectElement>) => 
              setNewUserData({ ...newUserData, companyId: parseInt(e.target.value) })
            }
            style={{ width: '100%', padding: '4px' }}
          >
            <option value={0}>Select Company</option>
            {companies.map((company) => (
              <option key={company.id} value={company.id}>
                {company.name}
              </option>
            ))}
          </select>
        </td>
        <td>
          <select
            value={newUserData.isActive ? 'true' : 'false'}
            onChange={(e: ChangeEvent<HTMLSelectElement>) => 
              setNewUserData({ ...newUserData, isActive: e.target.value === 'true' })
            }
            style={{ width: '100%', padding: '4px' }}
          >
            <option value="true">Active</option>
            <option value="false">Inactive</option>
          </select>
        </td>
        <td>-</td>
        <td>-</td>
        <td>
          <button 
            className={`${styles.masterBtn} ${styles.masterBtnEdit}`}
            onClick={handleCreateUser}
            style={{ marginRight: '5px' }}
          >
            Save
          </button>
          <button 
            className={`${styles.masterBtn} ${styles.masterBtnDelete}`}
            onClick={() => {
              setShowAddForm(false);
              setNewUserData({
                name: '',
                username: '',
                password: '',
                companyId: 0,
                isActive: true,
                permissions: []
              });
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
          <div className={styles.masterContainer} style={{ padding: '20px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2>User Management</h2>
              {onClose && (
                <button
                  className={`${styles.masterBtn} ${styles.masterBtnDelete}`}
                  onClick={onClose}
                >
                  Back to Master Data
                </button>
              )}
            </div>

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

            <div style={{ marginBottom: '20px', display: 'flex', gap: '10px', alignItems: 'center' }}>
              <input
                type="text"
                placeholder="Search users..."
                value={searchTerm}
                onChange={(e) => {
                  setSearchTerm(e.target.value);
                  setCurrentPage(1);
                }}
                style={{ padding: '8px', borderRadius: '4px', border: '1px solid #ccc' }}
              />
              <button
                className={`${styles.masterBtn} ${styles.masterBtnEdit}`}
                onClick={() => {
                  setShowAddForm(true);
                  setError(null);
                }}
                disabled={showAddForm}
              >
                Add New User
              </button>
            </div>

            <div className={styles.masterTableContainer}>
              <table className={styles.masterTable}>
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Name</th>
                    <th>Username</th>
                    <th>Password</th>
                    <th>Company</th>
                    <th>Status</th>
                    <th>Created At</th>
                    <th>Updated At</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {renderAddForm()}
                  {loading ? (
                    <tr>
                      <td colSpan={9} style={{ textAlign: 'center', padding: '20px' }}>
                        Loading...
                      </td>
                    </tr>
                  ) : users.length === 0 ? (
                    <tr>
                      <td colSpan={9} style={{ textAlign: 'center', padding: '20px' }}>
                        No users found
                      </td>
                    </tr>
                  ) : (
                    users.map((user) => (
                      <tr key={user.id}>
                        <td>{user.id}</td>
                        <td>
                          {editingUser?.id === user.id ? (
                            <input
                              type="text"
                              value={editingUser.name}
                              onChange={(e) => setEditingUser({ ...editingUser, name: e.target.value })}
                              style={{ width: '100%', padding: '4px' }}
                            />
                          ) : (
                            user.name
                          )}
                        </td>
                        <td>
                          {editingUser?.id === user.id ? (
                            <input
                              type="text"
                              value={editingUser.username}
                              onChange={(e) => setEditingUser({ ...editingUser, username: e.target.value })}
                              style={{ width: '100%', padding: '4px' }}
                            />
                          ) : (
                            user.username
                          )}
                        </td>
                        <td>••••••••</td>
                        <td>
                          {editingUser?.id === user.id ? (
                            <select
                              value={editingUser.company_id}
                              onChange={(e) => setEditingUser({ ...editingUser, company_id: parseInt(e.target.value) })}
                              style={{ width: '100%', padding: '4px' }}
                            >
                              {companies.map((company) => (
                                <option key={company.id} value={company.id}>
                                  {company.name}
                                </option>
                              ))}
                            </select>
                          ) : (
                            getCompanyName(user.company_id)
                          )}
                        </td>
                        <td>
                          {editingUser?.id === user.id ? (
                            <select
                              value={editingUser.is_active ? 'true' : 'false'}
                              onChange={(e) => setEditingUser({ ...editingUser, is_active: e.target.value === 'true' })}
                              style={{ width: '100%', padding: '4px' }}
                            >
                              <option value="true">Active</option>
                              <option value="false">Inactive</option>
                            </select>
                          ) : (
                            user.is_active ? 'Active' : 'Inactive'
                          )}
                        </td>
                        <td>{formatDate(user.created_at)}</td>
                        <td>{formatDate(user.updated_at)}</td>
                        <td>
                          {editingUser?.id === user.id ? (
                            <>
                              <button
                                className={`${styles.masterBtn} ${styles.masterBtnEdit}`}
                                onClick={() => handleUpdateUser(editingUser)}
                                style={{ marginRight: '5px', fontSize: '12px', padding: '4px 8px' }}
                              >
                                Save
                              </button>
                              <button
                                className={`${styles.masterBtn} ${styles.masterBtnDelete}`}
                                onClick={() => setEditingUser(null)}
                                style={{ fontSize: '12px', padding: '4px 8px' }}
                              >
                                Cancel
                              </button>
                            </>
                          ) : (
                            <>
                              <button
                                className={`${styles.masterBtn} ${styles.masterBtnEdit}`}
                                onClick={() => setEditingUser(user)}
                                style={{ marginRight: '5px', fontSize: '12px', padding: '4px 8px' }}
                              >
                                Edit
                              </button>
                              <button
                                className={`${styles.masterBtn} ${styles.masterBtnEdit}`}
                                onClick={() => handleShowPermissions(user.id)}
                                style={{ marginRight: '5px', fontSize: '12px', padding: '4px 8px' }}
                              >
                                Permissions
                              </button>
                              {/* Delete button removed for security purposes */}
                            </>
                          )}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div style={{ marginTop: '20px', textAlign: 'center' }}>
                <button
                  className={`${styles.masterBtn} ${styles.masterBtnEdit}`}
                  onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                  disabled={currentPage === 1}
                  style={{ marginRight: '10px' }}
                >
                  Previous
                </button>
                <span style={{ margin: '0 10px' }}>
                  Page {currentPage} of {totalPages}
                </span>
                <button
                  className={`${styles.masterBtn} ${styles.masterBtnEdit}`}
                  onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
                  disabled={currentPage === totalPages}
                  style={{ marginLeft: '10px' }}
                >
                  Next
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
      {renderPermissionsModal()}
    </div>
  );
}