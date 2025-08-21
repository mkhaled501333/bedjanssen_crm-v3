'use client';

import React from 'react';
import { Phone, Clock, TrendingUp, Users, Calendar } from 'lucide-react';
import type { CurrentAgentTabProps } from '../types';
import styles from './SummaryTab.module.css';

const SummaryTab: React.FC<CurrentAgentTabProps> = ({ data, loading }) => {
  if (loading) {
    return (
      <div className={styles.loading}>
        <p>Loading summary data...</p>
      </div>
    );
  }

  const formatDuration = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}m`;
  };

  const stats = [
    {
      title: 'Total Calls',
      value: data.totalCalls,
      icon: Phone,
      color: '#3b82f6',
      change: '+12%'
    },
    {
      title: 'Customer Calls',
      value: data.customerCalls,
      icon: Users,
      color: '#10b981',
      change: '+8%'
    },
    {
      title: 'Ticket Calls',
      value: data.ticketCalls,
      icon: TrendingUp,
      color: '#f59e0b',
      change: '+15%'
    },
    {
      title: 'Total Duration',
      value: formatDuration(data.summary.totalDuration),
      icon: Clock,
      color: '#8b5cf6',
      change: '+5%'
    },
    {
      title: 'Avg Duration',
      value: formatDuration(data.summary.averageDuration),
      icon: Calendar,
      color: '#ef4444',
      change: '-2%'
    },
    {
      title: 'Incoming Calls',
      value: data.summary.incomingCalls,
      icon: Phone,
      color: '#06b6d4',
      change: '+10%'
    }
  ];

  return (
    <div className={styles.container}>
      {/* Summary Stats */}
      <div className={styles.statsGrid}>
        {stats.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <div key={`stat-${stat.title}-${index}`} className={styles.statCard}>
              <div className={styles.statHeader}>
                <div 
                  className={styles.iconContainer}
                  style={{ backgroundColor: `${stat.color}20` }}
                >
                  <Icon 
                    className={styles.icon} 
                    style={{ color: stat.color }}
                  />
                </div>
                <div className={styles.change}>
                  <span className={styles.changeValue}>{stat.change}</span>
                </div>
              </div>
              <div className={styles.statContent}>
                <h3 className={styles.statValue}>{stat.value}</h3>
                <p className={styles.statTitle}>{stat.title}</p>
              </div>
            </div>
          );
        })}
      </div>

      {/* Top Categories */}
      <div className={styles.section}>
        <h2 className={styles.sectionTitle}>Top Call Categories</h2>
        <div className={styles.categoriesList}>
          {data.summary.topCategories.map((category, index) => (
            <div key={`category-${category.category}-${index}`} className={styles.categoryItem}>
              <div className={styles.categoryInfo}>
                <span className={styles.categoryName}>{category.category}</span>
                <span className={styles.categoryCount}>{category.count} calls</span>
              </div>
              <div className={styles.categoryBar}>
                <div 
                  className={styles.categoryProgress}
                  style={{ width: `${category.percentage}%` }}
                />
              </div>
              <span className={styles.categoryPercentage}>{category.percentage}%</span>
            </div>
          ))}
        </div>
      </div>

      {/* Call Type Distribution */}
      <div className={styles.section}>
        <h2 className={styles.sectionTitle}>Call Type Distribution</h2>
        <div className={styles.distributionGrid}>
          <div className={styles.distributionCard}>
            <div className={styles.distributionHeader}>
              <Phone className={styles.distributionIcon} />
              <span>Incoming Calls</span>
            </div>
            <div className={styles.distributionValue}>
              {data.summary.incomingCalls}
            </div>
            <div className={styles.distributionPercentage}>
              {Math.round((data.summary.incomingCalls / data.totalCalls) * 100)}%
            </div>
          </div>
          
          <div className={styles.distributionCard}>
            <div className={styles.distributionHeader}>
              <Phone className={styles.distributionIcon} />
              <span>Outgoing Calls</span>
            </div>
            <div className={styles.distributionValue}>
              {data.summary.outgoingCalls}
            </div>
            <div className={styles.distributionPercentage}>
              {Math.round((data.summary.outgoingCalls / data.totalCalls) * 100)}%
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SummaryTab;