'use client';

import React, { useEffect, useRef } from 'react';
import styles from './TicketReport.module.css';
import { useTicketReportData, useTicketReportFilters, useTicketReportPagination, useTicketReportSelection } from './hooks';
import FilterHeader from './components/FilterHeader';
import { getColumnKey, getUniqueValues, exportToCSV, getDisplayValue } from './utils';
import { TicketItem } from './types';

const TicketReport: React.FC = () => {
  const companyId = 1; // Default company ID, should come from auth context
  
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
    handleSelectAllFilter,
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

  // Apply filters when they change
  useEffect(() => {
    if (Object.keys(activeFilters).length > 0) {
      // Convert frontend filter format to API format
      const apiFilters = {
        companyId,
        // Add other filter conversions as needed
      };
      
      fetchData(apiFilters, currentPage, itemsPerPage);
      resetPagination();
    } else {
      fetchData({ companyId }, currentPage, itemsPerPage);
    }
  }, [activeFilters, currentPage, itemsPerPage, fetchData, resetPagination]);

  const handleExportToCSV = () => {
    exportToCSV(data, 'ticket-report-export.csv');
  };

  const handlePageSizeChange = (newSize: number) => {
    changePageSize(newSize);
    fetchData({ companyId }, 1, newSize);
  };

  if (loading) {
    return (
      <div className={styles.excelContainer}>
        <div className={styles.loadingMessage}>Loading ticket report data...</div>
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

  const tableColumns = [
    { key: 'ID', displayName: 'ID' },
    { key: 'Customer', displayName: 'Customer' },
    { key: 'Governorate', displayName: 'Governorate' },
    { key: 'City', displayName: 'City' },
    { key: 'Ticket ID', displayName: 'Ticket ID' },
    { key: 'Category', displayName: 'Category' },
    { key: 'Status', displayName: 'Status' },
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
        <button className={styles.toolbarButton} onClick={handleExportToCSV}>📊 Export CSV</button>
      </div>

      <div className={styles.excelTableWrapper}>
        <table className={styles.excelTable}>
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
              {tableColumns.map(({ key, displayName }) => (
                <FilterHeader
                  key={key}
                  column={key}
                  displayName={displayName}
                  isFiltered={!!(activeFilters[key] && activeFilters[key].length > 0)}
                  filterCount={activeFilters[key] ? activeFilters[key].length : 0}
                  isDropdownOpen={filterDropdowns[key] || false}
                  uniqueValues={getUniqueValues(data, getColumnKey(key))}
                  selectedValues={filterSelections[key] || []}
                  onToggleFilter={toggleFilter}
                  onFilterSelection={handleFilterSelection}
                  onSelectAllFilter={handleSelectAllFilter}
                  onApplyFilter={applyFilter}
                  onClearFilter={clearFilter}
                />
              ))}
            </tr>
          </thead>
          <tbody>
            {currentPageData.map((row) => (
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
                <td><input type="text" className={styles.cellInput} value={row.ticket_item_id} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.customer_name} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.governorate_name} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.city_name} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.ticket_id} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.ticket_category_name} readOnly /></td>
                <td className={styles.statusCell}>{row.ticket_status}</td>
                <td><input type="text" className={styles.cellInput} value={row.product_name} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.product_size} readOnly /></td>
                <td><input type="text" className={styles.cellInput} value={row.request_reason_name} readOnly /></td>
                <td className={styles.statusCell}>{getDisplayValue(row, 'inspected')}</td>
                <td className={styles.date}>{getDisplayValue(row, 'inspection_date')}</td>
                <td className={styles.statusCell}>{getDisplayValue(row, 'client_approval')}</td>
                <td><input type="text" className={styles.cellInput} value={row.action} readOnly /></td>
                <td className={styles.statusCell}>{getDisplayValue(row, 'pulled_status')}</td>
                <td className={styles.statusCell}>{getDisplayValue(row, 'delivered_status')}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className={styles.excelFooter}>
        <div className={styles.paginationControls}>
          <button className={styles.paginationBtn} onClick={goToFirstPage} disabled={currentPage === 1} title="First Page">⏮️</button>
          <button className={styles.paginationBtn} onClick={goToPreviousPage} disabled={currentPage === 1} title="Previous Page">◀️</button>
          <span className={styles.pageInfo}>Page {currentPage} of {totalPages}</span>
          <button className={styles.paginationBtn} onClick={goToNextPage} disabled={currentPage === totalPages} title="Next Page">▶️</button>
          <button className={styles.paginationBtn} onClick={goToLastPage} disabled={currentPage === totalPages} title="Last Page">⏭️</button>
        </div>
        <div className={styles.paginationSettings}>
          <label htmlFor="pageSize">Show:</label>
          <select 
            id="pageSize" 
            value={itemsPerPage}
            onChange={(e) => handlePageSizeChange(parseInt(e.target.value))}
          >
            <option value={10}>10</option>
            <option value={25}>25</option>
            <option value={50}>50</option>
            <option value={100}>100</option>
          </select>
          <span className={styles.recordsInfo}>records per page</span>
        </div>
        <div className={styles.statusInfo}>
          <span>Ready | {pagination.total} records | Ticket Items Report System</span>
        </div>
      </div>
    </div>
  );
};

export default TicketReport;
