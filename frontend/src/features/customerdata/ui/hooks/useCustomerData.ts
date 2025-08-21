'use client';

import { useState, useEffect, useCallback } from 'react';
import type { CustomerDataState, UseCustomerDataProps } from '../../types';
import { getCustomerDetails } from '../../api';

export function useCustomerData({ customerId }: UseCustomerDataProps) {
  const [state, setState] = useState<CustomerDataState>({
    customer: null,
    isLoading: false,
    error: null,
  });

  const fetchCustomerData = useCallback(async () => {
    if (!customerId) {
      setState(prev => ({ ...prev, error: 'Customer ID is required' }));
      return;
    }

    setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      const response = await getCustomerDetails(customerId);
      setState({
        customer: response.data,
        isLoading: false,
        error: null,
      });
    } catch (error) {
      setState({
        customer: null,
        isLoading: false,
        error: error instanceof Error ? error.message : 'Failed to fetch customer data',
      });
    }
  }, [customerId]);

  const refreshCustomerData = useCallback(() => {
    fetchCustomerData();
  }, [fetchCustomerData]);

  useEffect(() => {
    fetchCustomerData();
  }, [fetchCustomerData]);

  return {
    ...state,
    refreshCustomerData,
  };
}