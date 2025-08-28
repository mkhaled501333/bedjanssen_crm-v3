import React, { useState, useEffect, useRef, useCallback } from 'react';

import styles from './TicketReport.module.css';

// Types based on the ticket-items API response
interface FilterOption {
    id: number | string;
    name: string;
}

interface TicketItem {
    ticket_item_id: number;
    customer_id: number;
    customer_name: string;
    governomate_id: number;
    governorate_name: string;
    city_id: number;
    city_name: string;
    ticket_id: number;
    company_id: number;
    ticket_cat_id: number;
    ticket_category_name: string;
    ticket_status: string;
    product_id: number;
    product_name: string;
    product_size: string;
    request_reason_id: number;
    request_reason_name: string;
    inspected: boolean;
    inspection_date: string | null;
    client_approval: boolean;
    action: string;
    pulled_status: boolean;
    delivered_status: boolean;
}

interface TicketItemsReportResponse {
    success: boolean;
    data: {
        available_filters: {
            governorates: FilterOption[];
            cities: FilterOption[];
            ticket_categories: FilterOption[];
            ticket_statuses: FilterOption[];
            products: FilterOption[];
            request_reasons: FilterOption[];
            actions: FilterOption[];
        };
        applied_filters: Record<string, any>;
        filter_summary: {
            total_applied_filters: number;
            active_filters: string[];
        };
        report_data: {
            ticket_items: TicketItem[];
            pagination: {
                page: number;
                limit: number;
                total: number;
                total_pages: number;
                has_next: boolean;
                has_previous: boolean;
            };
        };
    };
    message?: string;
    error?: string;
}

export const TicketReport: React.FC = () => {
    // State variables
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(25);
    const [allData, setAllData] = useState<TicketItem[]>([]);
    const [activeFilters, setActiveFilters] = useState<Record<string, number[]>>({});
    const [selectedRows, setSelectedRows] = useState<Set<number>>(new Set());
    const [filterDropdowns, setFilterDropdowns] = useState<Record<string, boolean>>({});
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [totalPages, setTotalPages] = useState(1);
    const [totalItems, setTotalItems] = useState(0);
    const [availableFilters, setAvailableFilters] = useState<{
        governorates: FilterOption[];
        cities: FilterOption[];
        ticket_categories: FilterOption[];
        ticket_statuses: FilterOption[];
        products: FilterOption[];
        request_reasons: FilterOption[];
        actions: FilterOption[];
    }>({
        governorates: [],
        cities: [],
        ticket_categories: [],
        ticket_statuses: [],
        products: [],
        request_reasons: [],
        actions: []
    });
    const [currentApiUrl, setCurrentApiUrl] = useState<string>('');

    // Refs
    const tableRef = useRef<HTMLTableElement>(null);
    const selectAllCheckboxRef = useRef<HTMLInputElement>(null);

    // Use API pagination directly
    const currentPageData = allData;

    // Update select all checkbox indeterminate state
    useEffect(() => {
        if (selectAllCheckboxRef.current) {
            selectAllCheckboxRef.current.indeterminate = selectedRows.size > 0 && selectedRows.size < currentPageData.length;
        }
    }, [selectedRows.size, currentPageData.length]);

    // Helper function to get filter option by name - defined before fetchTicketsData
    const getFilterOptionByName = useCallback((filterType: string, id: number): FilterOption | null => {
        switch (filterType) {
            case 'Governorate':
                return availableFilters.governorates.find(option => option.id === id) || null;
            case 'City':
                return availableFilters.cities.find(option => option.id === id) || null;
            case 'Category':
                return availableFilters.ticket_categories.find(option => option.id === id) || null;
            case 'Status':
                return availableFilters.ticket_statuses.find(option => option.id === id) || null;
            case 'Product':
                return availableFilters.products.find(option => option.id === id) || null;
            case 'Company':
                return availableFilters.governorates.find(option => option.id === id) || null; // Using governorates as fallback
            case 'Reason':
                return availableFilters.request_reasons.find(option => option.id === id) || null;
            case 'Action':
                return availableFilters.actions.find(option => option.id === id) || null;
            default:
                return null;
        }
    }, [availableFilters]);

    // Fetch data from API
    const fetchTicketsData = useCallback(async () => {
        setLoading(true);
        setError(null);

        try {
            // Get auth token from localStorage
            const token = localStorage.getItem('token');
            if (!token) {
                throw new Error('No authentication token found');
            }

            // Get company ID from localStorage or use default
            const user = localStorage.getItem('user');
            let companyId = 1; // Default fallback
            
            if (user) {
                try {
                    const userData = JSON.parse(user);
                    if (userData.company_id && typeof userData.company_id === 'number' && userData.company_id > 0) {
                        companyId = userData.company_id;
                    } else if (userData.company_id && !isNaN(Number(userData.company_id)) && Number(userData.company_id) > 0) {
                        companyId = Number(userData.company_id);
                    } else {
                        console.warn('Invalid company_id in user data, using default:', userData.company_id);
                    }
                } catch (parseError) {
                    console.error('Error parsing user data:', parseError);
                    console.warn('Using default companyId: 1');
                }
            }

            console.log('Using companyId:', companyId);

            // Build filters object for the new API
            const filters: Record<string, any> = {
                companyId: companyId
            };

            // Add filters to the filters object using IDs
            Object.entries(activeFilters).forEach(([key, values]) => {
                if (values.length > 0) {
                    // Map frontend filter names to backend parameter names
                    let paramName = key.toLowerCase();
                    switch (key) {
                        case 'Status':
                            paramName = 'ticketStatus';
                            break;
                        case 'Category':
                            paramName = 'ticketCatIds';
                            break;
                        case 'Customer':
                            paramName = 'customerIds';
                            break;
                        case 'Governorate':
                            paramName = 'governomateIds';
                            break;
                        case 'City':
                            paramName = 'cityIds';
                            break;
                        case 'Company':
                            paramName = 'companyIds';
                            break;
                        case 'Product':
                            paramName = 'productIds';
                            break;
                        case 'Reason':
                            paramName = 'requestReasonIds';
                            break;
                        case 'Inspected':
                            paramName = 'inspected';
                            break;
                        case 'Action':
                            paramName = 'action';
                            break;
                        case 'PulledStatus':
                            paramName = 'pulledStatus';
                            break;
                        case 'DeliveredStatus':
                            paramName = 'deliveredStatus';
                            break;
                        case 'CreatedDate':
                            // Handle date range filtering for inspection dates
                            if (values.length === 2 && values[0] && values[1]) {
                                filters['inspectionDateFrom'] = new Date(values[0]).toISOString();
                                filters['inspectionDateTo'] = new Date(values[1]).toISOString();
                            }
                            return; // Skip the default handling for dates
                        default:
                            paramName = key.toLowerCase();
                    }
                    
                    // Handle multiple values for supported filters
                    if (['ticketStatus', 'action'].includes(paramName)) {
                        // For these filters, we need to convert IDs back to names for the API
                        const filterNames: string[] = [];
                        values.forEach(id => {
                            const filterOption = getFilterOptionByName(key, id);
                            if (filterOption) {
                                filters[paramName] = filterOption.name;
                            }
                        });
                    } else if (['ticketCatIds', 'customerIds', 'governomateIds', 'cityIds', 'companyIds', 'productIds', 'requestReasonIds'].includes(paramName)) {
                        // For ID-based filters, use the values directly
                        filters[paramName] = values;
                    } else if (['inspected', 'pulledStatus', 'deliveredStatus'].includes(paramName)) {
                        // For boolean filters, use the first value
                        filters[paramName] = values[0] === 1;
                    }
                }
            });

            // Build request body
            const requestBody = {
                filters: filters,
                page: currentPage,
                limit: pageSize
            };

            // Store the current URL for debugging
            const apiUrl = `http://localhost:8081/api/reports/ticket-items`;
            setCurrentApiUrl(apiUrl);
            console.log('Final API URL:', apiUrl);
            console.log('Request body:', requestBody);
            
            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(requestBody)
            });

            if (!response.ok) {
                let errorMessage = `HTTP error! status: ${response.status}`;
                try {
                    const errorData = await response.json();
                    if (errorData.message) {
                        errorMessage += ` - ${errorData.message}`;
                    }
                    if (errorData.error) {
                        errorMessage += ` - ${errorData.error}`;
                    }
                } catch {
                    // If we can't parse the error response, just use the status
                }
                throw new Error(errorMessage);
            }

            const data: TicketItemsReportResponse = await response.json();

            if (data.success && data.data) {
                setAllData(data.data.report_data.ticket_items);
                setTotalPages(data.data.report_data.pagination.total_pages);
                setTotalItems(data.data.report_data.pagination.total);
                setAvailableFilters(data.data.available_filters || {
                    governorates: [],
                    cities: [],
                    ticket_categories: [],
                    ticket_statuses: [],
                    products: [],
                    request_reasons: [],
                    actions: []
                });
            } else {
                setError(data.message || data.error || 'Failed to fetch ticket items data');
            }
        } catch (err) {
            console.error('Error fetching ticket items:', err);
            if (err instanceof Error) {
                setError(err.message);
            } else {
                setError('An error occurred while fetching data');
            }
        } finally {
            setLoading(false);
        }
    }, [currentPage, pageSize, activeFilters, getFilterOptionByName]);

    // Initialize data on component mount
    useEffect(() => {
        console.log('Component mounted, fetching initial data...');
        fetchTicketsData();
    }, [fetchTicketsData]);

    // Fetch data when pagination changes
    useEffect(() => {
        if (allData.length > 0) { // Only fetch if we already have some data
            fetchTicketsData();
        }
    }, [currentPage, pageSize, allData.length, fetchTicketsData]);

    // Update pagination when data changes
    useEffect(() => {
        if (currentPage > totalPages && totalPages > 0) {
            setCurrentPage(1);
        }
    }, [totalPages, currentPage]);

    // Filter functions
    const toggleFilter = (column: string) => {
        setFilterDropdowns(prev => ({
            ...prev,
            [column]: !prev[column]
        }));
    };

    const closeAllFilters = () => {
        setFilterDropdowns({});
    };

    const applyFilter = (column: string, selectedValues: number[]) => {
        console.log('Applying filter:', { column, selectedValues });
        if (selectedValues.length > 0) {
            setActiveFilters(prev => {
                const newFilters = { ...prev, [column]: selectedValues };
                console.log('Updated active filters:', newFilters);
                return newFilters;
            });
        } else {
            setActiveFilters(prev => {
                const newFilters = { ...prev };
                delete newFilters[column];
                console.log('Updated active filters (removed):', newFilters);
                return newFilters;
            });
        }
        setFilterDropdowns({});
        setCurrentPage(1); // Reset to first page when applying filters
    };

    const clearFilter = (column: string) => {
        setActiveFilters(prev => {
            const newFilters = { ...prev };
            delete newFilters[column];
            return newFilters;
        });
        setCurrentPage(1);
    };

    const clearAllFilters = () => {
        setActiveFilters({});
        setCurrentPage(1);
    };

    // Row selection functions
    const toggleRowSelection = (id: number, checked: boolean) => {
        setSelectedRows(prev => {
            const newSet = new Set(prev);
            if (checked) {
                newSet.add(id);
            } else {
                newSet.delete(id);
            }
            return newSet;
        });
    };

    const toggleSelectAll = (checked: boolean) => {
        if (checked) {
            setSelectedRows(new Set(currentPageData.map(row => row.ticket_item_id)));
        } else {
            setSelectedRows(new Set());
        }
    };

    // Export function
    const exportToCSV = () => {
        if (allData.length === 0) return;

        const headers = [
            'Ticket Item ID',
            'Customer',
            'Governorate',
            'City',
            'Category',
            'Status',
            'Product',
            'Size',
            'Reason',
            'Action',
            'Inspected',
            'Inspection Date',
            'Client Approval',
            'Pulled Status',
            'Delivered Status'
        ];

        const dataToExport = selectedRows.size > 0 
            ? allData.filter(item => selectedRows.has(item.ticket_item_id))
            : allData;

        const csvContent = [
            headers.join(','),
            ...dataToExport.map(item => [
                item.ticket_item_id,
                `"${item.customer_name}"`,
                `"${item.governorate_name}"`,
                `"${item.city_name}"`,
                `"${item.ticket_category_name}"`,
                `"${item.ticket_status}"`,
                `"${item.product_name}"`,
                `"${item.product_size}"`,
                `"${item.request_reason_name}"`,
                `"${item.action}"`,
                item.inspected ? 'Yes' : 'No',
                `"${item.inspection_date || '-'}"`,
                item.client_approval ? 'Yes' : 'No',
                item.pulled_status ? 'Yes' : 'No',
                item.delivered_status ? 'Yes' : 'No'
            ].join(','))
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', 'ticket_items_report.csv');
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    // Helper function to get filter options for a column
    const getFilterOptions = (column: string): FilterOption[] => {
        switch (column) {
            case 'Governorate':
                return availableFilters.governorates;
            case 'City':
                return availableFilters.cities;
            case 'Category':
                return availableFilters.ticket_categories;
            case 'Status':
                return availableFilters.ticket_statuses;
            case 'Product':
                return availableFilters.products;
            case 'Company':
                return availableFilters.governorates; // Using governorates as fallback
            case 'Reason':
                return availableFilters.request_reasons;
            case 'Action':
                return availableFilters.actions;
            default:
                return [];
        }
    };

    // FilterDropdown component
    const FilterDropdown: React.FC<{
        column: string;
        isOpen: boolean;
        onClose: () => void;
    }> = ({ column, isOpen, onClose }) => {
        const [selectedValues, setSelectedValues] = useState<number[]>([]);
        const options = getFilterOptions(column);

        useEffect(() => {
            setSelectedValues(activeFilters[column] || []);
        }, [column, activeFilters]);

        if (!isOpen) return null;

        return (
            <div className={styles.filterDropdown} onClick={(e) => e.stopPropagation()}>
                <div className={styles.filterHeader}>
                    <span>Filter {column}</span>
                    <button onClick={onClose} className={styles.closeButton}>×</button>
                </div>
                <div className={styles.filterOptions}>
                    {options.map(option => (
                        <label key={option.id} className={styles.filterOption}>
                            <input
                                type="checkbox"
                                id={`filter-${column}-${option.id}`}
                                checked={selectedValues.includes(option.id as number)}
                                onChange={(event) => {
                                    if (event.target.checked) {
                                        setSelectedValues(prev => [...prev, option.id as number]);
                                    } else {
                                        setSelectedValues(prev => prev.filter(v => v !== option.id as number));
                                    }
                                }}
                            />
                            {option.name}
                        </label>
                    ))}
                </div>
                <div className={styles.filterActions}>
                    <button 
                        onClick={() => applyFilter(column, selectedValues)}
                        className={styles.applyButton}
                    >
                        Apply
                    </button>
                    <button 
                        onClick={() => clearFilter(column)}
                        className={styles.clearButton}
                    >
                        Clear
                    </button>
                </div>
            </div>
        );
    };

    if (error) {
        return (
            <div className={styles.errorContainer}>
                <h2>Error</h2>
                <p>{error}</p>
                <button onClick={() => fetchTicketsData()} className={styles.retryButton}>
                    Retry
                </button>
            </div>
        );
    }

    return (
        <div className={styles.container}>
            <h1>Ticket Items Report</h1>
            
            {/* Toolbar */}
            <div className={styles.toolbar}>
                <div className={styles.paginationInfo}>
                    Showing {((currentPage - 1) * pageSize) + 1} to {Math.min(currentPage * pageSize, totalItems)} of {totalItems} items
                </div>
                
                <div className={styles.paginationControls}>
                    <button 
                        onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                        disabled={currentPage === 1}
                        className={styles.paginationButton}
                    >
                        Previous
                </button>
                    <span className={styles.pageInfo}>
                        Page {currentPage} of {totalPages}
                    </span>
                    <button 
                        onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))}
                        disabled={currentPage === totalPages}
                        className={styles.paginationButton}
                    >
                        Next
                </button>
                </div>

                <div className={styles.pageSizeControl}>
                    <label>
                        Items per page:
                        <select 
                            value={pageSize} 
                            onChange={(e) => setPageSize(Number(e.target.value))}
                            className={styles.pageSizeSelect}
                        >
                            <option value={10}>10</option>
                            <option value={25}>25</option>
                            <option value={50}>50</option>
                            <option value={100}>100</option>
                        </select>
                    </label>
                </div>

                <button 
                    onClick={exportToCSV}
                    className={styles.exportButton}
                    disabled={allData.length === 0}
                >
                    📊 Export CSV
                </button>

                {Object.keys(activeFilters).length > 0 && (
                    <div style={{ 
                        display: 'flex', 
                        gap: '10px', 
                        alignItems: 'center',
                        padding: '5px 10px',
                        background: '#e3f2fd',
                        borderRadius: '4px',
                        fontSize: '12px'
                    }}>
                        <strong>Active Filters:</strong>
                        {Object.entries(activeFilters).map(([key, values]) => (
                            <span key={key} style={{ 
                                background: '#2196f3', 
                                color: 'white', 
                                padding: '2px 8px', 
                                borderRadius: '12px',
                                fontSize: '11px'
                            }}>
                                {key}: {key === 'CreatedDate' ? 
                                    `${new Date(values[0]).toLocaleDateString()} to ${new Date(values[1]).toLocaleDateString()}` : 
                                    values.map(id => {
                                        const option = getFilterOptionByName(key, id);
                                        return option ? option.name : id;
                                    }).join(', ')
                                }
                            </span>
                        ))}
                        {loading && (
                            <span style={{ 
                                background: '#ff9800', 
                                color: 'white', 
                                padding: '2px 8px', 
                                borderRadius: '12px',
                                fontSize: '11px'
                            }}>
                                🔄 Applying...
                            </span>
                        )}
                    </div>
                )}
                <button 
                    className={styles.toolbarButton} 
                    onClick={() => fetchTicketsData()}
                    style={{ background: '#28a745', color: 'white', borderColor: '#28a745' }}
                >
                    🔄 Refresh
                </button>
                {process.env.NODE_ENV === 'development' && (
                    <button 
                        className={styles.toolbarButton} 
                        onClick={() => {
                            console.log('Current API URL:', currentApiUrl);
                            console.log('Active Filters:', activeFilters);
                            console.log('All Data:', allData);
                        }}
                        style={{ background: '#6c757d', color: 'white', borderColor: '#6c757d', fontSize: '11px' }}
                    >
                        🐛 Debug
                    </button>
                )}
            </div>

            {/* Table */}
            <div className={styles.excelTableWrapper}>
                <table ref={tableRef} className={styles.excelTable}>
                    <thead>
                        <tr>
                            <th>
                                <input
                                    ref={selectAllCheckboxRef}
                                    type="checkbox"
                                    className={styles.selectAll}
                                    onChange={(event) => toggleSelectAll(event.target.checked)}
                                    checked={selectedRows.size === currentPageData.length && currentPageData.length > 0}
                                />
                            </th>
                            <th>
                                Ticket Item ID 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('TicketItemId')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="TicketItemId" 
                                    isOpen={filterDropdowns['TicketItemId'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Customer 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('Customer')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Customer" 
                                    isOpen={filterDropdowns['Customer'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Governorate 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('Governorate')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Governorate" 
                                    isOpen={filterDropdowns['Governorate'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                City 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('City')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="City" 
                                    isOpen={filterDropdowns['City'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Category 
                                <span 
                                    className={`${styles.filterIcon} ${activeFilters['Category'] ? styles.active : ''}`}
                                    onClick={() => toggleFilter('Category')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Category" 
                                    isOpen={filterDropdowns['Category'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Status 
                                <span 
                                    className={`${styles.filterIcon} ${activeFilters['Status'] ? styles.active : ''}`}
                                    onClick={() => toggleFilter('Status')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Status" 
                                    isOpen={filterDropdowns['Status'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Product 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('Product')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Product" 
                                    isOpen={filterDropdowns['Product'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Size 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('Size')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Size" 
                                    isOpen={filterDropdowns['Size'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Reason 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('Reason')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Reason" 
                                    isOpen={filterDropdowns['Reason'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Action 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('Action')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Action" 
                                    isOpen={filterDropdowns['Action'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Inspected 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('Inspected')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Inspected" 
                                    isOpen={filterDropdowns['Inspected'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Inspection Date 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('InspectionDate')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="InspectionDate" 
                                    isOpen={filterDropdowns['InspectionDate'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Client Approval 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('ClientApproval')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="ClientApproval" 
                                    isOpen={filterDropdowns['ClientApproval'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Pulled Status 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('PulledStatus')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="PulledStatus" 
                                    isOpen={filterDropdowns['PulledStatus'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Delivered Status 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('DeliveredStatus')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="DeliveredStatus" 
                                    isOpen={filterDropdowns['DeliveredStatus'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr>
                                <td colSpan={16} className={styles.loadingCell}>
                                    <div className={styles.loadingSpinner}>
                                        🔄 Loading...
                                    </div>
                                </td>
                            </tr>
                        ) : currentPageData.length === 0 ? (
                            <tr>
                                <td colSpan={16} className={styles.noDataCell}>
                                    No data available
                                </td>
                            </tr>
                        ) : (
                            currentPageData.map((item) => (
                                <tr 
                                    key={item.ticket_item_id} 
                                    className={selectedRows.has(item.ticket_item_id) ? styles.selected : ''}
                            >
                                <td>
                                    <input
                                        type="checkbox"
                                        className={styles.rowCheckbox}
                                            checked={selectedRows.has(item.ticket_item_id)}
                                            onChange={(event) => toggleRowSelection(item.ticket_item_id, event.target.checked)}
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                            value={item.ticket_item_id}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                            value={item.customer_name}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                            value={item.governorate_name}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                            value={item.city_name}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                            value={item.ticket_category_name}
                                        readOnly
                                    />
                                </td>
                                <td className={styles.statusCell}>
                                        {item.ticket_status}
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                            value={item.product_name}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                            value={item.product_size}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                            value={item.request_reason_name}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                            value={item.action}
                                        readOnly
                                    />
                                </td>
                                <td className={styles.statusCell}>
                                        {item.inspected ? 'Yes' : 'No'}
                                </td>
                                <td className={styles.date}>
                                        {item.inspection_date || '-'}
                                </td>
                                <td className={styles.statusCell}>
                                        {item.client_approval ? 'Yes' : 'No'}
                                    </td>
                                    <td className={styles.statusCell}>
                                        {item.pulled_status ? 'Yes' : 'No'}
                                    </td>
                                    <td className={styles.statusCell}>
                                        {item.delivered_status ? 'Yes' : 'No'}
                                </td>
                            </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};
