import { useState, useEffect, useCallback } from 'react';
import { getCurrentAgentCalls } from '../api';
import type { CurrentAgentData, CallFilters } from '../types';

interface UseCurrentAgentReportProps {
  initialFilters?: Partial<CallFilters>;
}

interface UseCurrentAgentReportReturn {
  data: CurrentAgentData | null;
  loading: boolean;
  error: string | null;
  filters: CallFilters;
  refresh: () => Promise<void>;
  updateFilters: (newFilters: Partial<CallFilters>) => void;
}

export function useCurrentAgentReport({
  initialFilters = {}
}: UseCurrentAgentReportProps = {}): UseCurrentAgentReportReturn {
  const [data, setData] = useState<CurrentAgentData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  // Default filters - in a real app, userId would come from auth context
  const [filters, setFilters] = useState<CallFilters>({
    userId: 1, // This should come from auth context
    startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 30 days ago
    endDate: new Date().toISOString().split('T')[0], // Today
    ...initialFilters
  });

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    try {
      const reportData = await getCurrentAgentCalls(filters);
      setData(reportData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch report data');
    } finally {
      setLoading(false);
    }
  }, [filters]);

  const refresh = useCallback(async () => {
    await fetchData();
  }, [fetchData]);

  const updateFilters = useCallback((newFilters: Partial<CallFilters>) => {
    setFilters(prev => ({ ...prev, ...newFilters }));
  }, []);

  // Fetch data when filters change
  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return {
    data,
    loading,
    error,
    filters,
    refresh,
    updateFilters
  };
} 