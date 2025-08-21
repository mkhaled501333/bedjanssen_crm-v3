'use client';

import React from 'react';
import { format } from 'date-fns';
import { Calendar, Clock, TrendingUp } from 'lucide-react';
import type { CurrentAgentTabProps } from '../types';
import styles from './ActivityTab.module.css';

const ActivityTab: React.FC<CurrentAgentTabProps> = ({ data, loading }) => {
  if (loading) {
    return (
      <div className={styles.loading}>
        <p>Loading activity data...</p>
      </div>
    );
  }

  const formatDuration = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${hours}h ${minutes}m`;
  };

  const formatDate = (dateString: string): string => {
    return format(new Date(dateString), 'MMM dd');
  };

  const getMaxCalls = () => {
    return Math.max(...data.summary.dailyActivity.map(day => day.calls));
  };

  const getMaxDuration = () => {
    return Math.max(...data.summary.dailyActivity.map(day => day.duration));
  };

  const maxCalls = getMaxCalls();
  const maxDuration = getMaxDuration();

  return (
    <div className={styles.container}>
      {/* Activity Overview */}
      <div className={styles.overview}>
        <div className={styles.overviewCard}>
          <Calendar className={styles.overviewIcon} />
          <div className={styles.overviewContent}>
            <h3 className={styles.overviewValue}>
              {data.summary.dailyActivity.length} days
            </h3>
            <p className={styles.overviewLabel}>Active Period</p>
          </div>
        </div>

        <div className={styles.overviewCard}>
          <TrendingUp className={styles.overviewIcon} />
          <div className={styles.overviewContent}>
            <h3 className={styles.overviewValue}>
              {Math.round(data.totalCalls / data.summary.dailyActivity.length)} calls/day
            </h3>
            <p className={styles.overviewLabel}>Average Daily Calls</p>
          </div>
        </div>

        <div className={styles.overviewCard}>
          <Clock className={styles.overviewIcon} />
          <div className={styles.overviewContent}>
            <h3 className={styles.overviewValue}>
              {formatDuration(Math.round(data.summary.totalDuration / data.summary.dailyActivity.length))}
            </h3>
            <p className={styles.overviewLabel}>Average Daily Duration</p>
          </div>
        </div>
      </div>

      {/* Daily Activity Chart */}
      <div className={styles.section}>
        <h2 className={styles.sectionTitle}>Daily Call Activity</h2>
        <div className={styles.chartContainer}>
          <div className={styles.chartHeader}>
            <div className={styles.chartLegend}>
              <div className={styles.legendItem}>
                <div className={styles.legendColor} style={{ backgroundColor: '#3b82f6' }} />
                <span>Number of Calls</span>
              </div>
              <div className={styles.legendItem}>
                <div className={styles.legendColor} style={{ backgroundColor: '#10b981' }} />
                <span>Duration (hours)</span>
              </div>
            </div>
          </div>

          <div className={styles.chart}>
            {data.summary.dailyActivity.map((day, index) => {
              const callHeight = maxCalls > 0 ? (day.calls / maxCalls) * 100 : 0;
              const durationHeight = maxDuration > 0 ? (day.duration / maxDuration) * 100 : 0;
              
              return (
                <div key={`chart-${day.date}-${index}`} className={styles.chartBar}>
                  <div className={styles.barGroup}>
                    <div 
                      className={styles.callBar}
                      style={{ height: `${callHeight}%` }}
                      title={`${day.calls} calls`}
                    />
                    <div 
                      className={styles.durationBar}
                      style={{ height: `${durationHeight}%` }}
                      title={`${formatDuration(day.duration)}`}
                    />
                  </div>
                  <div className={styles.barLabel}>
                    <span className={styles.dateLabel}>{formatDate(day.date)}</span>
                    <span className={styles.callCount}>{day.calls}</span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Activity Table */}
      <div className={styles.section}>
        <h2 className={styles.sectionTitle}>Daily Breakdown</h2>
        <div className={styles.tableContainer}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Date</th>
                <th>Calls</th>
                <th>Duration</th>
                <th>Avg Duration</th>
              </tr>
            </thead>
            <tbody>
              {data.summary.dailyActivity.map((day, index) => (
                <tr key={`table-${day.date}-${index}`}>
                  <td>{formatDate(day.date)}</td>
                  <td>{day.calls}</td>
                  <td>{formatDuration(day.duration)}</td>
                  <td>
                    {day.calls > 0 
                      ? formatDuration(Math.round(day.duration / day.calls))
                      : '0m'
                    }
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Activity Insights */}
      <div className={styles.section}>
        <h2 className={styles.sectionTitle}>Activity Insights</h2>
        <div className={styles.insightsGrid}>
          <div className={styles.insightCard}>
            <h4 className={styles.insightTitle}>Busiest Day</h4>
            <p className={styles.insightValue}>
              {(() => {
                const busiestDay = data.summary.dailyActivity.reduce((max, day) => 
                  day.calls > max.calls ? day : max
                );
                return `${formatDate(busiestDay.date)} (${busiestDay.calls} calls)`;
              })()}
            </p>
          </div>

          <div className={styles.insightCard}>
            <h4 className={styles.insightTitle}>Longest Day</h4>
            <p className={styles.insightValue}>
              {(() => {
                const longestDay = data.summary.dailyActivity.reduce((max, day) => 
                  day.duration > max.duration ? day : max
                );
                return `${formatDate(longestDay.date)} (${formatDuration(longestDay.duration)})`;
              })()}
            </p>
          </div>

          <div className={styles.insightCard}>
            <h4 className={styles.insightTitle}>Most Efficient Day</h4>
            <p className={styles.insightValue}>
              {(() => {
                const mostEfficient = data.summary.dailyActivity.reduce((max, day) => {
                  const avgDuration = day.calls > 0 ? day.duration / day.calls : 0;
                  const maxAvgDuration = max.calls > 0 ? max.duration / max.calls : 0;
                  return avgDuration < maxAvgDuration ? day : max;
                });
                return `${formatDate(mostEfficient.date)} (${formatDuration(Math.round(mostEfficient.duration / mostEfficient.calls))} avg)`;
              })()}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ActivityTab;