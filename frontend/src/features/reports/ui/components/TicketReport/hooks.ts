import { useState, useEffect, useCallback } from 'react';
import { 
  TicketItem, 
  AppliedFilters, 
  FilterState, 
  FilterDropdownState,
  AvailableFilters 
} from './types';
import TicketItemsReportAPI from './api';

export const useTicketReportData = (companyId: number = 1) => {
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

  useEffect(() => {
    fetchData();
  }, [fetchData]);

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
  const [activeFilters, setActiveFilters] = useState<FilterState>({});
  const [filterSelections, setFilterSelections] = useState<FilterState>({});
  const [filterDropdowns, setFilterDropdowns] = useState<FilterDropdownState>({});

  const toggleFilter = useCallback((column: string) => {
    setFilterDropdowns(prev => ({
      ...prev,
      [column]: !prev[column]
    }));
  }, []);

  const handleFilterSelection = useCallback((column: string, value: string, checked: boolean) => {
    setFilterSelections(prev => {
      const current = prev[column] || [];
      if (checked) {
        return { ...prev, [column]: [...current, value] };
      } else {
        return { ...prev, [column]: current.filter(v => v !== value) };
      }
    });
  }, []);

  const handleSelectAllFilter = useCallback((column: string, checked: boolean, uniqueValues: string[]) => {
    if (checked) {
      setFilterSelections(prev => ({ ...prev, [column]: uniqueValues }));
    } else {
      setFilterSelections(prev => ({ ...prev, [column]: [] }));
    }
  }, []);

  const applyFilter = useCallback((column: string) => {
    const selectedValues = filterSelections[column] || [];
    if (selectedValues.length > 0) {
      setActiveFilters(prev => ({
        ...prev,
        [column]: selectedValues
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
  }, []);

  const clearAllFilters = useCallback(() => {
    setActiveFilters({});
    setFilterSelections({});
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
    handleSelectAllFilter,
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
