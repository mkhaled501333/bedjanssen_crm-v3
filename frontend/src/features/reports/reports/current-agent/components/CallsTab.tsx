'use client';

import React, { useState } from 'react';
import { format } from 'date-fns';
import { Phone, Clock, User, FileText, Search, Filter } from 'lucide-react';
import type { CurrentAgentTabProps } from '../types';
import styles from './CallsTab.module.css';

const CallsTab: React.FC<CurrentAgentTabProps> = ({ data, loading }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'customer_call' | 'ticket_call'>('all');
  const [filterCallType, setFilterCallType] = useState<'all' | 'incoming' | 'outgoing'>('all');

  if (loading) {
    return (
      <div className={styles.loading}>
        <p>Loading calls data...</p>
      </div>
    );
  }

  const formatDuration = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  const formatDate = (dateString: string): string => {
    return format(new Date(dateString), 'MMM dd, yyyy HH:mm');
  };

  // Filter calls based on search and filters
  const filteredCalls = data.calls.filter(call => {
    const matchesSearch = 
      call.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      call.customerPhone.includes(searchTerm) ||
      call.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
      call.category.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesType = filterType === 'all' || call.type === filterType;
    const matchesCallType = filterCallType === 'all' || call.callType === filterCallType;
    
    return matchesSearch && matchesType && matchesCallType;
  });

  const getCallTypeIcon = (type: string) => {
    return type === 'customer_call' ? User : FileText;
  };

  const getCallTypeColor = (type: string) => {
    return type === 'customer_call' ? '#10b981' : '#f59e0b';
  };

  const getCallDirectionColor = (direction: string) => {
    return direction === 'incoming' ? '#3b82f6' : '#8b5cf6';
  };

  return (
    <div className={styles.container}>
      {/* Filters */}
      <div className={styles.filters}>
        <div className={styles.searchContainer}>
          <Search className={styles.searchIcon} />
          <input
            type="text"
            placeholder="Search calls..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className={styles.searchInput}
          />
        </div>

        <div className={styles.filterGroup}>
          <Filter className={styles.filterIcon} />
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value as 'all' | 'customer_call' | 'ticket_call')}
            className={styles.filterSelect}
          >
            <option value="all">All Types</option>
            <option value="customer_call">Customer Calls</option>
            <option value="ticket_call">Ticket Calls</option>
          </select>

          <select
            value={filterCallType}
            onChange={(e) => setFilterCallType(e.target.value as 'all' | 'incoming' | 'outgoing')}
            className={styles.filterSelect}
          >
            <option value="all">All Directions</option>
            <option value="incoming">Incoming</option>
            <option value="outgoing">Outgoing</option>
          </select>
        </div>
      </div>

      {/* Results Count */}
      <div className={styles.resultsCount}>
        Showing {filteredCalls.length} of {data.calls.length} calls
      </div>

      {/* Calls List */}
      <div className={styles.callsList}>
        {filteredCalls.length === 0 ? (
          <div className={styles.noResults}>
            <p>No calls found matching your criteria</p>
          </div>
        ) : (
          filteredCalls.map((call) => {
            const TypeIcon = getCallTypeIcon(call.type);
            const typeColor = getCallTypeColor(call.type);
            const directionColor = getCallDirectionColor(call.callType);
            
            return (
              <div key={`call-${call.id}-${call.createdAt}-${call.customerPhone}`} className={styles.callCard}>
                <div className={styles.callHeader}>
                  <div className={styles.callType}>
                    <div 
                      className={styles.typeIcon}
                      style={{ backgroundColor: `${typeColor}20` }}
                    >
                      <TypeIcon 
                        className={styles.icon} 
                        style={{ color: typeColor }}
                      />
                    </div>
                    <div className={styles.callInfo}>
                      <span className={styles.callTypeLabel}>
                        {call.type === 'customer_call' ? 'Customer Call' : 'Ticket Call'}
                      </span>
                      {call.ticketNumber && (
                        <span className={styles.ticketNumber}>
                          #{call.ticketNumber}
                        </span>
                      )}
                    </div>
                  </div>
                  
                  <div className={styles.callDirection}>
                    <div 
                      className={styles.directionBadge}
                      style={{ 
                        backgroundColor: `${directionColor}20`,
                        color: directionColor
                      }}
                    >
                      <Phone className={styles.directionIcon} />
                      {call.callType}
                    </div>
                  </div>
                </div>

                <div className={styles.callContent}>
                  <div className={styles.customerInfo}>
                    <h3 className={styles.customerName}>{call.customerName}</h3>
                    <p className={styles.customerPhone}>{call.customerPhone}</p>
                  </div>

                  <div className={styles.callDetails}>
                    <div className={styles.detailRow}>
                      <span className={styles.detailLabel}>Category:</span>
                      <span className={styles.detailValue}>{call.category}</span>
                    </div>
                    
                    <div className={styles.detailRow}>
                      <span className={styles.detailLabel}>Duration:</span>
                      <span className={styles.detailValue}>
                        <Clock className={styles.detailIcon} />
                        {formatDuration(call.callDuration)}
                      </span>
                    </div>
                    
                    <div className={styles.detailRow}>
                      <span className={styles.detailLabel}>Date:</span>
                      <span className={styles.detailValue}>
                        {formatDate(call.createdAt)}
                      </span>
                    </div>
                  </div>

                  {call.description && (
                    <div className={styles.description}>
                      <span className={styles.descriptionLabel}>Description:</span>
                      <p className={styles.descriptionText}>{call.description}</p>
                    </div>
                  )}

                  {call.callNotes && (
                    <div className={styles.notes}>
                      <span className={styles.notesLabel}>Notes:</span>
                      <p className={styles.notesText}>{call.callNotes}</p>
                    </div>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};

export default CallsTab;