// Current Agent Report API functions

import type { CurrentAgentData, CallFilters, AgentCall } from './types';
import { authFetch, getApiBaseUrl } from '@/shared/utils';

export async function getCurrentAgentCalls(filters: CallFilters): Promise<CurrentAgentData> {
  try {
    const queryParams = new URLSearchParams({
      userId: filters.userId.toString(),
      startDate: filters.startDate,
      endDate: filters.endDate,
    });

    const response = await authFetch(`${getApiBaseUrl()}/api/reports/current-agent/calls?${queryParams}`, {
      method: 'GET',
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch agent calls: ${response.statusText}`);
    }

    const result = await response.json();
    
    if (!result.success) {
      throw new Error(result.message || 'Failed to fetch agent calls');
    }

    // Process the raw data to add summary statistics
    const processedData = processAgentData(result.data);
    
    return processedData;
  } catch (error) {
    console.error('Error fetching current agent calls:', error);
    throw error;
  }
}

function processAgentData(rawData: { calls?: unknown[]; userId: number; startDate: string; endDate: string; totalCalls: number; customerCalls: number; ticketCalls: number }): CurrentAgentData {
  const calls: unknown[] = rawData.calls || [];
  
  // Calculate summary statistics
  const totalDuration = calls.reduce((sum: number, call: unknown) => {
    const callDuration = (call as { callDuration?: number }).callDuration || 0;
    return sum + callDuration;
  }, 0) as number;
  const averageDuration = calls.length > 0 ? Math.round(totalDuration / calls.length) : 0;
  
  const incomingCalls = calls.filter((call: unknown) => (call as { callType?: string }).callType === 'incoming').length;
  const outgoingCalls = calls.filter((call: unknown) => (call as { callType?: string }).callType === 'outgoing').length;
  
  // Calculate top categories
  const categoryCounts: Record<string, number> = {};
  calls.forEach((call: unknown) => {
    const category = (call as { category?: string }).category || 'Unknown';
    categoryCounts[category] = (categoryCounts[category] || 0) + 1;
  });
  
  const topCategories = Object.entries(categoryCounts)
    .map(([category, count]) => ({
      category,
      count,
      percentage: Math.round((count / calls.length) * 100)
    }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 5);
  
  // Calculate daily activity
  const dailyActivity: Record<string, { calls: number; duration: number }> = {};
  calls.forEach((call: unknown) => {
    const callData = call as { createdAt: string; callDuration?: number };
    const date = callData.createdAt.split('T')[0];
    if (!dailyActivity[date]) {
      dailyActivity[date] = { calls: 0, duration: 0 };
    }
    dailyActivity[date].calls += 1;
    dailyActivity[date].duration += callData.callDuration || 0;
  });
  
  const dailyActivityArray = Object.entries(dailyActivity)
    .map(([date, data]) => ({
      date,
      calls: data.calls,
      duration: data.duration
    }))
    .sort((a, b) => a.date.localeCompare(b.date));
  
  return {
    userId: rawData.userId,
    startDate: rawData.startDate,
    endDate: rawData.endDate,
    totalCalls: rawData.totalCalls,
    customerCalls: rawData.customerCalls,
    ticketCalls: rawData.ticketCalls,
    calls: calls as AgentCall[],
    summary: {
      totalDuration,
      averageDuration,
      incomingCalls,
      outgoingCalls,
      topCategories,
      dailyActivity: dailyActivityArray
    }
  };
}

export async function exportCurrentAgentReport(
  filters: CallFilters, 
  format: 'pdf' | 'excel' | 'csv'
): Promise<Blob> {
  try {
    const queryParams = new URLSearchParams({
      userId: filters.userId.toString(),
      startDate: filters.startDate,
      endDate: filters.endDate,
      format: format
    });

    const response = await fetch(`${API_BASE_URL}/api/reports/current-agent/export?${queryParams}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${getAuthToken()}`
      },
    });

    if (!response.ok) {
      throw new Error(`Failed to export report: ${response.statusText}`);
    }

    return await response.blob();
  } catch (error) {
    console.error('Error exporting current agent report:', error);
    throw error;
  }
}