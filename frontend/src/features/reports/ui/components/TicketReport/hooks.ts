import { useState, useEffect, useCallback } from 'react';
import { 
  TicketItem, 
  AppliedFilters, 
  FilterState, 
  FilterDropdownState,
  AvailableFilters,
  FilterValue,
  DateRange
} from './types';
import TicketItemsReportAPI from './api';

export const useTicketReportData = (companyId: number) => {
  const [data, setData] = useState<TicketItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [availableFilters, setAvailableFilters] = useState<AvailableFilters | null>(null);
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 50,
    total: 0,
    totalPages: 0,
    hasNext: false,
    hasPrevious: false,
  });

  const fetchData = useCallback(async (
    filters: AppliedFilters = { companyId },
    page: number = 1,
    limit: number = 50
  ) => {
    try {
      setLoading(true);
      setError(null);
      
      const response = await TicketItemsReportAPI.getFilteredReport(filters, page, limit);
      
      if (response.success && response.data) {
        setData(response.data.report_data.ticket_items);
        setAvailableFilters(response.data.available_filters);
        setPagination({
          page: response.data.report_data.pagination.page,
          limit: response.data.report_data.pagination.limit,
          total: response.data.report_data.pagination.total,
          totalPages: response.data.report_data.pagination.total_pages,
          hasNext: response.data.report_data.pagination.has_next,
          hasPrevious: response.data.report_data.pagination.has_previous,
        });
      } else {
        throw new Error(response.error || 'Failed to fetch data');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
      console.error('Error fetching ticket report data:', err);
    } finally {
      setLoading(false);
    }
  }, [companyId]);

  // Remove automatic fetch on mount to prevent loops
  // Data will be fetched when component mounts via the main useEffect

  return {
    data,
    loading,
    error,
    availableFilters,
    pagination,
    fetchData,
    refetch: () => fetchData(),
  };
};

export const useTicketReportFilters = () => {
  // Load initial filter state from localStorage
  const getInitialFilterState = (): FilterState => {
    try {
      const saved = localStorage.getItem('ticketReport_filters');
      return saved ? JSON.parse(saved) : {};
    } catch {
      return {};
    }
  };

  const getInitialFilterSelections = (): FilterState => {
    try {
      const saved = localStorage.getItem('ticketReport_filterSelections');
      return saved ? JSON.parse(saved) : {};
    } catch {
      return {};
    }
  };

  const [activeFilters, setActiveFilters] = useState<FilterState>(getInitialFilterState);
  const [filterSelections, setFilterSelections] = useState<FilterState>(getInitialFilterSelections);
  const [filterDropdowns, setFilterDropdowns] = useState<FilterDropdownState>({});

  // Save filter state to localStorage whenever it changes
  useEffect(() => {
    localStorage.setItem('ticketReport_filters', JSON.stringify(activeFilters));
  }, [activeFilters]);

  useEffect(() => {
    localStorage.setItem('ticketReport_filterSelections', JSON.stringify(filterSelections));
  }, [filterSelections]);

  const toggleFilter = useCallback((column: string) => {
    setFilterDropdowns(prev => ({
      ...prev,
      [column]: !prev[column]
    }));
  }, []);

  const handleFilterSelection = useCallback((column: string, value: FilterValue) => {
    console.log('handleFilterSelection called for column:', column, 'with value:', value, 'type:', typeof value);
    setFilterSelections(prev => {
      const newState = { ...prev, [column]: value };
      console.log('New filterSelections state:', newState);
      return newState;
    });
  }, []);

  const applyFilter = useCallback((column: string) => {
    const selectedValue = filterSelections[column];
    
    // Check if the value is meaningful (not empty array, empty string, etc.)
    let hasValue = false;
    if (Array.isArray(selectedValue)) {
      hasValue = selectedValue.length > 0;
    } else if (typeof selectedValue === 'string') {
      hasValue = selectedValue.trim().length > 0;
    } else if (typeof selectedValue === 'boolean') {
      hasValue = true; // Boolean values are always meaningful
    } else if (selectedValue === null) {
      // For radio filters, null means "All" which should clear the filter
      hasValue = false;
    } else if (selectedValue && typeof selectedValue === 'object' && 'from' in selectedValue) {
      // DateRange type
      const dateRange = selectedValue as DateRange;
      hasValue = !!(dateRange.from || dateRange.to);
    }

    if (hasValue) {
      setActiveFilters(prev => ({
        ...prev,
        [column]: selectedValue
      }));
    } else {
      setActiveFilters(prev => {
        const newFilters = { ...prev };
        delete newFilters[column];
        return newFilters;
      });
    }
    setFilterDropdowns(prev => ({ ...prev, [column]: false }));
  }, [filterSelections]);

  const clearFilter = useCallback((column: string) => {
    setActiveFilters(prev => {
      const newFilters = { ...prev };
      delete newFilters[column];
      return newFilters;
    });
    setFilterSelections(prev => {
      const newSelections = { ...prev };
      delete newSelections[column];
      return newSelections;
    });
    setFilterDropdowns(prev => ({ ...prev, [column]: false }));
    // Note: localStorage will be automatically updated by the useEffect hooks
  }, []);

  const clearAllFilters = useCallback(() => {
    setActiveFilters({});
    setFilterSelections({});
    // Clear localStorage
    localStorage.removeItem('ticketReport_filters');
    localStorage.removeItem('ticketReport_filterSelections');
  }, []);

  const closeAllDropdowns = useCallback(() => {
    setFilterDropdowns({});
  }, []);

  return {
    activeFilters,
    filterSelections,
    filterDropdowns,
    toggleFilter,
    handleFilterSelection,
    applyFilter,
    clearFilter,
    clearAllFilters,
    closeAllDropdowns,
  };
};

export const useTicketReportPagination = (totalItems: number, pageSize: number) => {
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(pageSize);

  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;

  const goToPage = useCallback((page: number) => {
    setCurrentPage(Math.max(1, Math.min(page, totalPages)));
  }, [totalPages]);

  const goToFirstPage = useCallback(() => goToPage(1), [goToPage]);
  const goToPreviousPage = useCallback(() => goToPage(currentPage - 1), [goToPage, currentPage]);
  const goToNextPage = useCallback(() => goToPage(currentPage + 1), [goToPage, currentPage]);
  const goToLastPage = useCallback(() => goToPage(totalPages), [goToPage, totalPages]);

  const changePageSize = useCallback((newSize: number) => {
    setItemsPerPage(newSize);
    setCurrentPage(1);
  }, []);

  const resetPagination = useCallback(() => {
    setCurrentPage(1);
  }, []);

  return {
    currentPage,
    itemsPerPage,
    totalPages,
    startIndex,
    endIndex,
    goToPage,
    goToFirstPage,
    goToPreviousPage,
    goToNextPage,
    goToLastPage,
    changePageSize,
    resetPagination,
  };
};

export const useTicketReportSelection = (data: TicketItem[]) => {
  const [selectedRows, setSelectedRows] = useState<Set<number>>(new Set());

  const toggleSelectAll = useCallback((checked: boolean) => {
    if (checked) {
      const allIds = new Set(data.map(item => item.ticket_item_id));
      setSelectedRows(allIds);
    } else {
      setSelectedRows(new Set());
    }
  }, [data]);

  const toggleRowSelection = useCallback((id: number, checked: boolean) => {
    const newSelectedRows = new Set(selectedRows);
    if (checked) {
      newSelectedRows.add(id);
    } else {
      newSelectedRows.delete(id);
    }
    setSelectedRows(newSelectedRows);
  }, [selectedRows]);

  const clearSelection = useCallback(() => {
    setSelectedRows(new Set());
  }, []);

  const getSelectedCount = useCallback(() => selectedRows.size, [selectedRows]);

  const isAllSelected = data.length > 0 && selectedRows.size === data.length;
  const isIndeterminate = selectedRows.size > 0 && selectedRows.size < data.length;

  return {
    selectedRows,
    toggleSelectAll,
    toggleRowSelection,
    clearSelection,
    getSelectedCount,
    isAllSelected,
    isIndeterminate,
  };
};
