'use client';

import React, { useEffect, useRef, useState } from 'react';
import styles from './TicketReport.module.css';
import { useTicketReportData, useTicketReportFilters, useTicketReportPagination, useTicketReportSelection } from './hooks';
import FilterHeader from './components/FilterHeader';
import { getColumnKey, getUniqueValues, exportToCSV, getDisplayValue } from './utils';
import { TicketItem, FilterValue, DateRange, COLUMN_FILTER_CONFIG, AvailableFilters } from './types';
import LoadingSpinner from './components/LoadingSpinner';
import TableLoadingOverlay from './components/TableLoadingOverlay';
import LoadingRow from './components/LoadingRow';
import { PrintService } from './services/printService';

// Custom hook for responsive width calculation
const useResponsiveWidth = () => {
  const [tableWidth, setTableWidth] = useState<number>(0);

  useEffect(() => {
    const updateWidth = () => {
      const screenWidth = window.innerWidth;
      setTableWidth(screenWidth - 30);
    };

    // Set initial width
    updateWidth();

    // Add event listener for window resize
    window.addEventListener('resize', updateWidth);

    // Cleanup
    return () => window.removeEventListener('resize', updateWidth);
  }, []);

  return tableWidth;
};

const TicketReport: React.FC = () => {
  const companyId = 1; // Default company ID, should come from auth context
  const tableWidth = useResponsiveWidth();
  
  // Custom hooks for state management
  const {
    data,
    loading,
    error,
    availableFilters,
    pagination,
    fetchData,
  } = useTicketReportData(companyId);

  const {
    activeFilters,
    filterSelections,
    filterDropdowns,
    toggleFilter,
    handleFilterSelection,
    applyFilter,
    clearFilter,
    clearAllFilters,
    closeAllDropdowns,
  } = useTicketReportFilters();

  const {
    currentPage,
    itemsPerPage,
    totalPages,
    startIndex,
    endIndex,
    goToFirstPage,
    goToPreviousPage,
    goToNextPage,
    goToLastPage,
    changePageSize,
    resetPagination,
  } = useTicketReportPagination(pagination.total, pagination.limit);

  const {
    selectedRows,
    toggleSelectAll,
    toggleRowSelection,
    clearSelection,
    isAllSelected,
    isIndeterminate,
  } = useTicketReportSelection(data);

  // Click outside handler to close dropdowns
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as Element;
      if (!target.closest(`.${styles.filterIcon}`) && !target.closest(`.${styles.filterDropdown}`)) {
        closeAllDropdowns();
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [closeAllDropdowns]);

  // Function to convert filter names to IDs
  const convertFilterNamesToIds = (column: string, selectedNames: string[]): number[] => {
    if (!availableFilters || selectedNames.length === 0) return [];

    const columnToFilterMap: Record<string, keyof AvailableFilters> = {
      'Governorate': 'governorates',
      'City': 'cities',
      'Category': 'ticket_categories',
      'Status': 'ticket_statuses',
      'Product': 'products',
      'Size': 'products',
      'Request Reason': 'request_reasons',
      'Action': 'actions',
    };

    const filterKey = columnToFilterMap[column];
    if (!filterKey) return [];

    const filterData = availableFilters[filterKey];
    if (!filterData || !Array.isArray(filterData)) return [];

    // Find the IDs for the selected names
    const ids: number[] = [];
    selectedNames.forEach(selectedName => {
      const option = filterData.find(opt => opt.name === selectedName);
      if (option && typeof option.id === 'number') {
        ids.push(option.id);
      }
    });

    return ids;
  };

  // Function to get available filter values for a specific column
  const getAvailableFilterValues = (column: string): string[] => {
    if (!availableFilters) return [];

    const columnToFilterMap: Record<string, keyof AvailableFilters> = {
      'Governorate': 'governorates',
      'City': 'cities',
      'Category': 'ticket_categories',
      'Status': 'ticket_statuses',
      'Product': 'products',
      'Size': 'products',
      'Request Reason': 'request_reasons',
      'Action': 'actions',
    };

    const filterKey = columnToFilterMap[column];
    if (!filterKey) return [];

    const filterData = availableFilters[filterKey];
    if (!filterData || !Array.isArray(filterData)) return [];

    // Extract the name values from FilterOption objects
    return filterData.map(option => option.name);
  };

  // Function to handle printing selected tickets
  const handlePrintSelectedTickets = async () => {
    if (selectedRows.size === 0) {
      alert('يرجى تحديد التذاكر للطباعة');
      return;
    }

    // Convert ticket item IDs to ticket IDs
    const ticketIds = Array.from(selectedRows).map(ticketItemId => {
      const ticketItem = data.find(item => item.ticket_item_id === ticketItemId);
      return ticketItem?.ticket_id;
    }).filter((id): id is number => id !== undefined);

    if (ticketIds.length === 0) {
      alert('لم يتم العثور على بيانات التذاكر المحددة');
      return;
    }

    try {
      await PrintService.printSelectedTickets(ticketIds);
    } catch (error) {
      console.error('Error printing tickets:', error);
      alert('حدث خطأ أثناء الطباعة. يرجى المحاولة مرة أخرى.');
    }
  };

  // Function to handle printing Englander format
  const handlePrintEnglanderFormat = async () => {
    if (selectedRows.size === 0) {
      alert('يرجى تحديد التذاكر للطباعة');
      return;
    }

    // Convert ticket item IDs to ticket IDs
    const ticketIds = Array.from(selectedRows).map(ticketItemId => {
      const ticketItem = data.find(item => item.ticket_item_id === ticketItemId);
      return ticketItem?.ticket_id;
    }).filter((id): id is number => id !== undefined);

    if (ticketIds.length === 0) {
      alert('لم يتم العثور على بيانات التذاكر المحددة');
      return;
    }

    try {
      await PrintService.printEnglanderFormat(ticketIds);
    } catch (error) {
      console.error('Error printing Englander format:', error);
      alert('حدث خطأ أثناء الطباعة. يرجى المحاولة مرة أخرى.');
    }
  };

  // Apply filters when they change
  useEffect(() => {
    // Convert frontend filter format to API format
    const apiFilters = {
      companyId,
      ...Object.entries(activeFilters).reduce((acc, [column, value]) => {
        const filterConfig = COLUMN_FILTER_CONFIG.find(config => config.column === column);
        if (!filterConfig) return acc;

        switch (filterConfig.filterType) {
          case 'multiSelect':
            if (Array.isArray(value) && value.length > 0) {
              // For multiSelect filters, we need to convert string names to IDs
              if (filterConfig.dataType === 'number') {
                // Convert string names to IDs by looking up in availableFilters
                const ids = convertFilterNamesToIds(column, value as string[]);
                if (ids.length > 0) {
                  acc[filterConfig.backendKey] = ids;
                }
              } else {
                // For non-ID filters, send the values as-is
                acc[filterConfig.backendKey] = value;
              }
            }
            break;
          case 'radio':
            if (value !== null && value !== undefined) {
              acc[filterConfig.backendKey] = value;
            }
            break;
          case 'text':
            if (typeof value === 'string' && value.trim().length > 0) {
              acc[filterConfig.backendKey] = value.trim();
            }
            break;
          case 'boolean':
            if (typeof value === 'boolean') {
              acc[filterConfig.backendKey] = value;
            }
            break;
          case 'dateRange':
            if (value && typeof value === 'object' && 'from' in value) {
              const dateRange = value as DateRange;
              try {
                if (dateRange.from) {
                  // Ensure from is a Date object before calling toISOString
                  const fromDate = dateRange.from instanceof Date ? dateRange.from : new Date(dateRange.from);
                  if (!isNaN(fromDate.getTime())) {
                    // Determine which date filter this is based on the column
                    if (column === 'Ticket Creation Date') {
                      acc.ticketCreatedDateFrom = fromDate.toISOString();
                    } else {
                      acc.inspectionDateFrom = fromDate.toISOString();
                    }
                  }
                }
                if (dateRange.to) {
                  // Ensure to is a Date object before calling toISOString
                  const toDate = dateRange.to instanceof Date ? dateRange.to : new Date(dateRange.to);
                  if (!isNaN(toDate.getTime())) {
                    // Determine which date filter this is based on the column
                    if (column === 'Ticket Creation Date') {
                      acc.ticketCreatedDateTo = toDate.toISOString();
                    } else {
                      acc.inspectionDateTo = toDate.toISOString();
                    }
                  }
                }
              } catch (error) {
                console.warn('Error processing date range filter:', error);
                // Skip this filter if there's an error with date processing
              }
            }
            break;
          default:
            break;
        }
        return acc;
      }, {} as any),
    };

    fetchData(apiFilters, currentPage, itemsPerPage);
    resetPagination();
  }, [activeFilters, currentPage, itemsPerPage, fetchData, resetPagination, companyId]);

  const handleExportToCSV = () => {
    exportToCSV(data, 'ticket-report-export.csv');
  };

  const handlePageSizeChange = (newSize: number) => {
    changePageSize(newSize);
    fetchData({ companyId }, 1, newSize);
  };

  // Show initial loading state only when there's no data yet
  if (loading && (!data || data.length === 0)) {
    return (
      <div className={styles.excelContainer}>
        <LoadingSpinner 
          size="large" 
          color="#217346" 
          text="Loading ticket report data..."
        />
      </div>
    );
  }

  if (error) {
    return (
      <div className={styles.excelContainer}>
        <div className={styles.errorMessage}>
          Error loading data: {error}
          <button onClick={() => fetchData({ companyId })}>Retry</button>
        </div>
      </div>
    );
  }

  const currentPageData = data.slice(startIndex, endIndex);

  // Ensure data is available before rendering
  if (!data || data.length === 0) {
    return (
      <div className={styles.excelContainer}>
        <div className={styles.excelToolbar}>
          <button className={styles.toolbarButton} onClick={() => alert('Find functionality')}>🔍 Find</button>
          <button 
            className={styles.toolbarButton} 
            onClick={clearAllFilters} 
            style={{ background: '#dc3545', color: 'white', borderColor: '#dc3545' }}
          >
            🗑️ Clear Filters
          </button>
          <button 
            className={styles.toolbarButton} 
            onClick={handleExportToCSV}
            disabled={loading}
          >
            📊 Export CSV
          </button>
        </div>
        <div className={styles.noDataMessage}>
          No data available to display. Please check your filters or try refreshing the page.
        </div>
      </div>
    );
  }

  const tableColumns = [
    { key: 'Ticket ID', displayName: 'Ticket ID' },
    { key: 'Status', displayName: 'Status' },
    { key: 'Ticket Creation Date', displayName: 'Ticket Creation Date' },
    { key: 'Customer', displayName: 'Customer' },
    { key: 'Governorate', displayName: 'Governorate' },
    { key: 'City', displayName: 'City' },
    { key: 'Category', displayName: 'Category' },
    { key: 'Product', displayName: 'Product' },
    { key: 'Size', displayName: 'Size' },
    { key: 'Request Reason', displayName: 'Request Reason' },
    { key: 'Inspected', displayName: 'Inspected' },
    { key: 'Inspection Date', displayName: 'Inspection Date' },
    { key: 'Client Approval', displayName: 'Client Approval' },
    { key: 'Action', displayName: 'Action' },
    { key: 'Pulled Status', displayName: 'Pulled Status' },
    { key: 'Delivered Status', displayName: 'Delivered Status' },
  ];

  // Helper function to get status cell CSS class
  const getStatusCellClass = (status: string | number | boolean): string => {
    const statusValue = String(status).trim();
    if (statusValue === '0' || statusValue.toLowerCase() === 'open' || statusValue === 'false') {
      return `${styles.statusCell} ${styles.statusOpen}`;
    }
    if (statusValue === '1' || statusValue.toLowerCase() === 'closed' || statusValue === 'true') {
      return `${styles.statusCell} ${styles.statusClosed}`;
    }
    return styles.statusCell;
  };

  return (
    <div className={styles.excelContainer} style={{ width: `${tableWidth}px`, maxWidth: `${tableWidth}px` }}>
      <div className={styles.excelToolbar}>
        <button className={styles.toolbarButton} onClick={() => alert('Find functionality')}>🔍 Find</button>
        <button 
          className={styles.toolbarButton} 
          onClick={clearAllFilters} 
          style={{ background: '#dc3545', color: 'white', borderColor: '#dc3545' }}
        >
          🗑️ Clear Filters
        </button>
        <button className={styles.toolbarButton} onClick={handleExportToCSV}>📊 Export CSV</button>
        <button 
          className={`${styles.toolbarButton} ${styles.printToolbarButton}`}
          onClick={handlePrintSelectedTickets}
          disabled={selectedRows.size === 0}
          title="طباعة نموذج يانسن"
        >
          🖨️ نموذج يانسن
        </button>
        <button 
          className={`${styles.toolbarButton} ${styles.printToolbarButton}`}
          onClick={handlePrintEnglanderFormat}
          disabled={selectedRows.size === 0}
          title="طباعة نموذج انجلندر"
        >
          🖨️ نموذج انجلندر
        </button>
        {loading && data && data.length > 0 && (
          <div className={styles.toolbarLoading}>
            <LoadingSpinner size="small" color="#217346" text="Updating..." />
          </div>
        )}
      </div>

      <div className={styles.excelTableWrapper} style={{ width: `${tableWidth}px`, position: 'relative' }}>
        <TableLoadingOverlay 
          isLoading={loading && data && data.length > 0} 
          loadingText="Updating data..."
        />
        <table className={`${styles.excelTable} ${loading && data && data.length > 0 ? styles.loading : ''}`}>
          <thead>
            <tr>
              <th>
                <input 
                  type="checkbox" 
                  id="selectAll" 
                  onChange={(e) => toggleSelectAll(e.target.checked)}
                  checked={isAllSelected}
                  ref={(input) => {
                    if (input) {
                      input.indeterminate = isIndeterminate;
                    }
                  }}
                />
              </th>
              {tableColumns.map(({ key, displayName }) => {
                // Columns that should not show filter icons
                const columnsWithoutFilters = ['Customer', 'Ticket ID', 'Size'];
                const shouldShowFilters = !columnsWithoutFilters.includes(key);
                
                const isFiltered = shouldShowFilters ? !!(activeFilters[key] !== undefined && activeFilters[key] !== null) : false;
                if (key === 'Pulled Status' || key === 'Delivered Status') {
                  console.log(`${key} - isFiltered:`, isFiltered, 'activeFilters[key]:', activeFilters[key], 'filterSelections[key]:', filterSelections[key]);
                }
                
                // Add custom styling for specific columns
                const customClassName = key === 'Request Reason' ? styles.requestReasonColumn : undefined;
                
                return (
                  <FilterHeader
                    key={key}
                    column={key}
                    displayName={displayName}
                    isFiltered={isFiltered}
                    filterCount={shouldShowFilters ? (() => {
                      const selectedValues = filterSelections[key] !== undefined ? filterSelections[key] : null;
                      if (!selectedValues) return 0;
                      if (Array.isArray(selectedValues)) return selectedValues.length;
                      if (typeof selectedValues === 'string') return selectedValues.trim().length > 0 ? 1 : 0;
                      if (typeof selectedValues === 'boolean') return 1;
                      if (selectedValues === null) return 0;
                      if (typeof selectedValues === 'object' && 'from' in selectedValues) {
                        const dateRange = selectedValues as { from: Date | null; to: Date | null };
                        return (dateRange.from || dateRange.to) ? 1 : 0;
                      }
                      return 0;
                    })() : 0}
                    isDropdownOpen={shouldShowFilters ? (filterDropdowns[key] || false) : false}
                    uniqueValues={shouldShowFilters ? getAvailableFilterValues(key) : []}
                    selectedValues={shouldShowFilters ? (filterSelections[key] !== undefined ? filterSelections[key] : null) : null}
                    onToggleFilter={shouldShowFilters ? toggleFilter : () => {}}
                    onFilterSelection={shouldShowFilters ? handleFilterSelection : () => {}}
                    onApplyFilter={shouldShowFilters ? applyFilter : () => {}}
                    onClearFilter={shouldShowFilters ? clearFilter : () => {}}
                    customClassName={customClassName}
                    isLoading={loading && data && data.length > 0}
                  />
                );
              })}
            </tr>

          </thead>
          <tbody>
            {loading && data && data.length > 0 ? (
              // Show loading rows when refreshing data
              Array.from({ length: Math.min(itemsPerPage, 5) }).map((_, index) => (
                <LoadingRow key={`loading-${index}`} columnCount={tableColumns.length + 1} />
              ))
            ) : (
              currentPageData.map((row) => (
                <tr key={row.ticket_item_id} className={selectedRows.has(row.ticket_item_id) ? styles.selected : ''}>
                <td>
                  <input 
                    type="checkbox" 
                    className={styles.rowCheckbox}
                    value={row.ticket_item_id}
                    checked={selectedRows.has(row.ticket_item_id)}
                    onChange={(e) => toggleRowSelection(row.ticket_item_id, e.target.checked)}
                  />
                </td>
                <td><input type="text" className={styles.cellInput} value={row.ticket_id} readOnly /></td>
                <td className={getStatusCellClass(row.ticket_status)}>{getDisplayValue(row, 'ticket_status')}</td>
                <td className={styles.date}>{getDisplayValue(row, 'ticket_created_at')}</td>
                <td><input type="text" className={styles.cellInput} value={row.customer_name} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.governorate_name} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.city_name} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.ticket_category_name} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.product_name} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.product_size} readOnly /></td>
                <td className={styles.requestReasonColumn}><input type="text" className={styles.cellInput} value={row.request_reason_name} readOnly /></td>
                <td className={getStatusCellClass(row.inspected)}>{getDisplayValue(row, 'inspected')}</td>
                <td className={styles.date}>{getDisplayValue(row, 'inspection_date')}</td>
                <td className={getStatusCellClass(row.client_approval)}>{getDisplayValue(row, 'client_approval')}</td>
                <td><input type="text" className={styles.cellInput} value={row.action} readOnly /></td>
                <td className={getStatusCellClass(row.pulled_status)}>{getDisplayValue(row, 'pulled_status')}</td>
                <td className={getStatusCellClass(row.delivered_status)}>{getDisplayValue(row, 'delivered_status')}</td>
              </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className={styles.excelFooter}>
        <div className={styles.paginationControls}>
          <button 
            className={styles.paginationBtn} 
            onClick={goToFirstPage} 
            disabled={currentPage === 1 || loading} 
            title="First Page"
          >
            ⏮️
          </button>
          <button 
            className={styles.paginationBtn} 
            onClick={goToPreviousPage} 
            disabled={currentPage === 1 || loading} 
            title="Previous Page"
          >
            ◀️
          </button>
          <span className={styles.pageInfo}>
            Page {currentPage} of {totalPages}
            {loading && data && data.length > 0 && (
              <span className={styles.loadingIndicator}> • Updating...</span>
            )}
          </span>
          <button 
            className={styles.paginationBtn} 
            onClick={goToNextPage} 
            disabled={currentPage === totalPages || loading} 
            title="Next Page"
          >
            ▶️
          </button>
          <button 
            className={styles.paginationBtn} 
            onClick={goToLastPage} 
            disabled={currentPage === totalPages || loading} 
            title="Last Page"
          >
            ⏭️
          </button>
        </div>
        <div className={styles.paginationSettings}>
          <label htmlFor="pageSize">Show:</label>
          <select 
            id="pageSize" 
            value={itemsPerPage}
            onChange={(e) => handlePageSizeChange(parseInt(e.target.value))}
            disabled={loading}
          >
            <option value={10}>10</option>
            <option value={25}>25</option>
            <option value={50}>50</option>
            <option value={100}>100</option>
          </select>
          <span className={styles.recordsInfo}>records per page</span>
        </div>
        <div className={styles.statusInfo}>
          <span>
            {loading && data && data.length > 0 ? 'Updating...' : 'Ready'} | {pagination.total} records | Ticket Items Report System
          </span>
        </div>
      </div>
    </div>
  );
};

export default TicketReport;
