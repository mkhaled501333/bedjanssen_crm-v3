import React, { useState, useEffect, useRef, useCallback } from 'react';

import styles from './TicketReport.module.css';

// Types based on the API response
interface TicketItem {
    id: number;
    productId: number;
    productName: string;
    productSize: string;
    quantity: number;
    purchaseDate: string;
    purchaseLocation: string;
    requestReasonId: number;
    requestReasonName: string;
    requestReasonDetail: string;
    inspected: boolean;
    inspectionDate: string | null;
    inspectionResult: string;
    clientApproval: boolean;
    createdAt: string;
    updatedAt: string;
}

interface Ticket {
    id: number;
    companyId: number;
    customerId: number;
    customerName: string;
    companyName: string;
    governorateName: string;
    cityName: string;
    ticketCatId: number;
    categoryName: string;
    description: string;
    status: string;
    priority: string;
    createdBy: number;
    createdByName: string;
    createdAt: string;
    updatedAt: string;
    closedAt: string | null;
    closingNotes: string | null;
    callsCount: number;
    itemsCount: number;
    items: TicketItem[];
}

interface TicketsReportResponse {
    success: boolean;
    data: {
        tickets: Ticket[];
        pagination: {
            currentPage: number;
            totalPages: number;
            totalItems: number;
            itemsPerPage: number;
            hasNextPage: boolean;
            hasPreviousPage: boolean;
        };
        summary: {
            statusCounts: Record<string, number>;
        };
        filters: {
            companyId: number;
            status: string | null;
            categoryId: number | null;
            customerId: number | null;
            startDate: string | null;
            endDate: string | null;
            searchTerm: string | null;
            governorate: string | null;
            city: string | null;
            productName: string | null;
            companyName: string | null;
            requestReasonName: string | null;
            inspected: boolean | null;
        };
        available_filters: {
            governorates: string[];
            cities: string[];
            categories: string[];
            statuses: string[];
            productNames: string[];
            companyNames: string[];
            requestReasonNames: string[];
        };
    };
    message: string;
}

export const TicketReport: React.FC = () => {
    // State variables
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(25);
    const [allData, setAllData] = useState<Ticket[]>([]);
    const [activeFilters, setActiveFilters] = useState<Record<string, string[]>>({});
    const [filteredData, setFilteredData] = useState<Ticket[] | null>(null);
    const [selectedRows, setSelectedRows] = useState<Set<number>>(new Set());
    const [filterDropdowns, setFilterDropdowns] = useState<Record<string, boolean>>({});
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [totalPages, setTotalPages] = useState(1);
    const [totalItems, setTotalItems] = useState(0);
    const [availableFilters, setAvailableFilters] = useState<{
        governorates: string[];
        cities: string[];
        categories: string[];
        statuses: string[];
        productNames: string[];
        companyNames: string[];
        requestReasonNames: string[];
    }>({
        governorates: [],
        cities: [],
        categories: [],
        statuses: [],
        productNames: [],
        companyNames: [],
        requestReasonNames: []
    });
    const [currentApiUrl, setCurrentApiUrl] = useState<string>('');

    // Refs
    const tableRef = useRef<HTMLTableElement>(null);
    const selectAllCheckboxRef = useRef<HTMLInputElement>(null);

    // Calculate pagination - only slice if we have filtered data, otherwise use API pagination
    const currentPageData = filteredData ? 
        filteredData.slice((currentPage - 1) * pageSize, currentPage * pageSize) : 
        allData;
    


    // Update select all checkbox indeterminate state
    useEffect(() => {
        if (selectAllCheckboxRef.current) {
            selectAllCheckboxRef.current.indeterminate = selectedRows.size > 0 && selectedRows.size < currentPageData.length;
        }
    }, [selectedRows.size, currentPageData.length]);

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
            const companyId = user ? JSON.parse(user).company_id : 1;

            // Build query parameters
            const queryParams = new URLSearchParams({
                companyId: companyId.toString(),
                page: currentPage.toString(),
                limit: pageSize.toString()
            });

            // Add filters to query parameters
            console.log('Building query params with filters:', activeFilters);
            Object.entries(activeFilters).forEach(([key, values]) => {
                if (values.length > 0) {
                    // Map frontend filter names to backend parameter names
                    let paramName = key.toLowerCase();
                    switch (key) {
                        case 'Status':
                            paramName = 'status';
                            break;
                        case 'Category':
                            paramName = 'category'; // Changed from categoryId to category
                            break;
                        case 'Customer':
                            paramName = 'customer'; // Changed from customerId to customer
                            break;
                        case 'Governorate':
                            paramName = 'governorate';
                            break;
                        case 'City':
                            paramName = 'city';
                            break;
                        case 'CreatedBy':
                            paramName = 'createdBy';
                            break;
                        case 'Company':
                            paramName = 'company'; // Changed from companyName to company
                            break;
                        case 'Product':
                            paramName = 'product'; // Changed from productName to product
                            break;
                        case 'Size':
                            paramName = 'size'; // Changed from productSize to size
                            break;
                        case 'Reason':
                            paramName = 'reason'; // Changed from requestReasonName to reason
                            break;
                        case 'Inspected':
                            paramName = 'inspected';
                            break;
                        case 'ClientApproval':
                            paramName = 'clientApproval';
                            break;
                        default:
                            paramName = key.toLowerCase();
                    }
                    
                    console.log(`Mapping filter ${key} -> ${paramName} with values:`, values);
                    
                    // Only add non-empty values
                    values.forEach(value => {
                        if (value && value.trim() !== '') {
                            queryParams.append(paramName, value.trim());
                        }
                    });
                }
            });

            // Store the current URL for debugging
            const apiUrl = `http://localhost:8081/api/reports/tickets?${queryParams.toString()}`;
            setCurrentApiUrl(apiUrl);
            console.log('Final API URL:', apiUrl);
            console.log('Query parameters:', queryParams.toString());

            
            const response = await fetch(apiUrl, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                }
            });

            if (!response.ok) {
                let errorMessage = `HTTP error! status: ${response.status}`;
                try {
                    const errorData = await response.json();
                    if (errorData.message) {
                        errorMessage += ` - ${errorData.message}`;
                    }
                    if (errorData.details) {
                        errorMessage += ` - ${JSON.stringify(errorData.details)}`;
                    }
                } catch {
                    // If we can't parse the error response, just use the status
                }
                throw new Error(errorMessage);
            }

            const data: TicketsReportResponse = await response.json();

            if (data.success && data.data) {
                
                setAllData(data.data.tickets);
                setTotalPages(data.data.pagination.totalPages);
                setTotalItems(data.data.pagination.totalItems);
                setAvailableFilters(data.data.available_filters || {
                    governorates: [],
                    cities: [],
                    categories: [],
                    statuses: [],
                    productNames: [],
                    companyNames: [],
                    requestReasonNames: []
                });
                setFilteredData(null); // Reset filtered data when new data arrives
            } else {
                setError(data.message || 'Failed to fetch tickets data');
            }
        } catch (err) {
            console.error('Error fetching tickets:', err);
            if (err instanceof Error) {
                setError(err.message);
            } else {
                setError('An error occurred while fetching data');
            }
        } finally {
            setLoading(false);
        }
    }, [currentPage, pageSize, activeFilters]);



    // Initialize data on component mount
    useEffect(() => {
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

    const applyFilter = (column: string, selectedValues: string[]) => {
        console.log('Applying filter:', { column, selectedValues });
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
        setFilterDropdowns({});
        setCurrentPage(1); // Reset to first page when applying filters
    };

    const clearFilter = (column: string) => {
        setActiveFilters(prev => {
            const newFilters = { ...prev };
            delete newFilters[column];
            return newFilters;
        });
        setCurrentPage(1); // Reset to first page when clearing filters
    };



    const clearAllFilters = () => {
        setActiveFilters({});
        setFilteredData(null);
        setCurrentPage(1); // Reset to first page when clearing all filters
    };

    // Apply filters to data
    useEffect(() => {
        if (Object.keys(activeFilters).length === 0) {
            setFilteredData(null);
            return;
        }

        // If we have active filters, we need to fetch filtered data from API
        // Reset to page 1 and trigger API call
        setCurrentPage(1);
    }, [activeFilters]);

    // Trigger API call when filters change
    useEffect(() => {
        console.log('Filters changed:', activeFilters);
        if (Object.keys(activeFilters).length > 0) {
            console.log('Triggering API call with filters');
            fetchTicketsData();
        }
    }, [activeFilters, fetchTicketsData]);

    // Get unique values for a column (for local filtering)
    const getUniqueColumnValues = useCallback((column: string): string[] => {
        const values = new Set<string>();
        
        allData.forEach(ticket => {
            let value: string = '';
            
            switch (column) {
                case 'ID':
                    value = ticket.id.toString();
                    break;
                case 'Company':
                    value = ticket.companyName;
                    break;
                case 'Customer':
                    value = ticket.customerName;
                    break;
                case 'Governorate':
                    value = ticket.governorateName;
                    break;
                case 'City':
                    value = ticket.cityName;
                    break;
                case 'Category':
                    value = ticket.categoryName;
                    break;
                case 'Status':
                    value = ticket.status;
                    break;
                case 'CreatedBy':
                    value = ticket.createdByName;
                    break;
                case 'CreatedDate':
                    value = ticket.createdAt;
                    break;
                case 'Product':
                    value = ticket.items?.[0]?.productName || '';
                    break;
                case 'Size':
                    value = ticket.items?.[0]?.productSize || '';
                    break;
                case 'Quantity':
                    value = ticket.items?.[0]?.quantity?.toString() || '';
                    break;
                case 'PurchaseDate':
                    value = ticket.items?.[0]?.purchaseDate || '';
                    break;
                case 'Location':
                    value = ticket.items?.[0]?.purchaseLocation || '';
                    break;
                case 'Reason':
                    value = ticket.items?.[0]?.requestReasonName || '';
                    break;
                case 'Inspected':
                    value = ticket.items?.[0]?.inspected ? 'Yes' : 'No';
                    break;
                case 'InspectionDate':
                    value = ticket.items?.[0]?.inspectionDate || '-';
                    break;
                case 'ClientApproval':
                    value = ticket.items?.[0]?.clientApproval ? 'Yes' : 'No';
                    break;
            }
            
            if (value && value.trim() !== '') {
                values.add(value);
            }
        });
        
        return Array.from(values).sort();
    }, [allData]);

    // Get available filter values from API response
    const getAvailableFilterValues = useCallback((column: string): string[] => {
        switch (column) {
            case 'Governorate':
                return availableFilters.governorates;
            case 'City':
                return availableFilters.cities;
            case 'Category':
                return availableFilters.categories;
            case 'Status':
                return availableFilters.statuses;
            case 'Product':
                return availableFilters.productNames;
            case 'Company':
                return availableFilters.companyNames;
            case 'Reason':
                return availableFilters.requestReasonNames;
            default:
                return getUniqueColumnValues(column);
        }
    }, [availableFilters, getUniqueColumnValues]);

    // Filter dropdown component
    const FilterDropdown: React.FC<{ column: string; isOpen: boolean; onClose: () => void }> = ({ column, isOpen, onClose }) => {
        const [searchTerm, setSearchTerm] = useState('');
        const [selectedValues, setSelectedValues] = useState<string[]>([]);
        
        // Initialize selectedValues with current active filters for this column
        useEffect(() => {
            if (isOpen) {
                setSelectedValues(activeFilters[column] || []);
            }
        }, [isOpen, column]);
        
        // Use available filters from API when possible, fallback to local unique values
        const availableValues = getAvailableFilterValues(column);
        const uniqueValues = availableValues.length > 0 ? availableValues : getUniqueColumnValues(column);

        const handleApply = () => {
            applyFilter(column, selectedValues);
            onClose();
        };

        const handleClear = () => {
            clearFilter(column);
            onClose();
        };

        const filteredOptions = uniqueValues.filter(value => 
            value.toLowerCase().includes(searchTerm.toLowerCase())
        );

        if (!isOpen) return null;

        return (
            <div className={`${styles.filterDropdown} ${styles.show}`}>
                <div className={styles.filterHeader}>Filter {column}</div>
                <input
                    type="text"
                    className={styles.filterSearch}
                    placeholder="Search..."
                    value={searchTerm}
                    onChange={(event) => setSearchTerm(event.target.value)}
                />
                <div className={styles.filterOptions}>
                    {filteredOptions.map(value => (
                        <div key={value} className={styles.filterOption}>
                            <input
                                type="checkbox"
                                id={`filter-${column}-${value}`}
                                checked={selectedValues.includes(value)}
                                onChange={(event) => {
                                    if (event.target.checked) {
                                        setSelectedValues(prev => [...prev, value]);
                                    } else {
                                        setSelectedValues(prev => prev.filter(v => v !== value));
                                    }
                                }}
                            />
                            <label htmlFor={`filter-${column}-${value}`}>{value}</label>
                        </div>
                    ))}
                </div>
                <div className={styles.filterActions}>
                    <button onClick={handleClear}>Clear</button>
                    <button className={styles.apply} onClick={handleApply}>Apply</button>
                </div>
            </div>
        );
    };

    // Pagination functions
    const goToFirstPage = () => {
        setCurrentPage(1);
    };
    const goToPreviousPage = () => {
        setCurrentPage(prev => Math.max(prev - 1, 1));
    };
    const goToNextPage = () => {
        setCurrentPage(prev => Math.min(prev + 1, totalPages));
    };
    const goToLastPage = () => {
        setCurrentPage(totalPages);
    };
    
    const changePageSize = (newPageSize: number) => {
        setPageSize(newPageSize);
        setCurrentPage(1); // Reset to first page when changing page size
    };

    // Row selection functions
    const toggleRowSelection = (rowId: number, checked: boolean) => {
        setSelectedRows(prev => {
            const newSet = new Set(prev);
            if (checked) {
                newSet.add(rowId);
            } else {
                newSet.delete(rowId);
            }
            return newSet;
        });
    };

    const toggleSelectAll = (checked: boolean) => {
        if (checked) {
            setSelectedRows(new Set(currentPageData.map(row => row.id)));
        } else {
            setSelectedRows(new Set());
        }
    };

    // Export function
    const exportToCSV = () => {
        const dataToExport = filteredData || allData;
        if (dataToExport.length === 0) return;

        const headers = [
            'ID', 'Company', 'Customer', 'Governorate', 'City', 'Category', 'Status', 
            'Created By', 'Created Date', 'Product', 'Size', 'Quantity', 'Purchase Date', 
            'Location', 'Reason', 'Inspected', 'Inspection Date', 'Client Approval'
        ];

        const csvContent = [
            headers.join(','),
            ...dataToExport.map(ticket => [
                ticket.id,
                `"${ticket.companyName}"`,
                `"${ticket.customerName}"`,
                `"${ticket.governorateName}"`,
                `"${ticket.cityName}"`,
                `"${ticket.categoryName}"`,
                `"${ticket.status}"`,
                `"${ticket.createdByName}"`,
                `"${ticket.createdAt}"`,
                `"${ticket.items?.[0]?.productName || ''}"`,
                `"${ticket.items?.[0]?.productSize || ''}"`,
                ticket.items?.[0]?.quantity || 0,
                `"${ticket.items?.[0]?.purchaseDate || ''}"`,
                `"${ticket.items?.[0]?.purchaseLocation || ''}"`,
                `"${ticket.items?.[0]?.requestReasonName || ''}"`,
                ticket.items?.[0]?.inspected ? 'Yes' : 'No',
                `"${ticket.items?.[0]?.inspectionDate || '-'}"`,
                ticket.items?.[0]?.clientApproval ? 'Yes' : 'No'
            ].join(','))
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', 'tickets_report.csv');
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    // Add new row function
    const addNewRow = () => {
        alert('Add new row functionality would go here');
    };

    // Loading state
    if (loading && allData.length === 0) {
        return (
            <div className={styles.excelContainer}>
                <div style={{ padding: '20px', textAlign: 'center' }}>
                    <p>Loading tickets data...</p>
                </div>
            </div>
        );
    }

    // Error state
    if (error && allData.length === 0) {
        return (
            <div className={styles.excelContainer}>
                <div style={{ padding: '20px', textAlign: 'center', color: 'red' }}>
                    <p>Error: {error}</p>
                    <button onClick={fetchTicketsData}>Retry</button>
                </div>
            </div>
        );
    }

    return (
        <div className={styles.excelContainer}>
            {/* Toolbar */}
            <div className={styles.excelToolbar}>
                <button className={styles.toolbarButton} onClick={() => alert('Open functionality')}>
                    📁 Open
                </button>
                <button className={styles.toolbarButton} onClick={() => alert('Save functionality')}>
                    💾 Save
                </button>
                <button className={styles.toolbarButton} onClick={exportToCSV}>
                    📤 Export
                </button>
                <button className={styles.toolbarButton} onClick={() => alert('Find functionality')}>
                    🔍 Find
                </button>
                <button className={styles.toolbarButton} onClick={() => alert('Filter functionality')}>
                    📊 Filter
                </button>
                <button className={styles.toolbarButton} onClick={() => alert('Sort functionality')}>
                    📈 Sort
                </button>
                <button className={styles.toolbarButton} onClick={addNewRow}>
                    ➕ Insert
                </button>
                <button className={styles.toolbarButton} onClick={() => alert('Edit functionality')}>
                    ✏️ Edit
                </button>
                <button 
                    className={styles.toolbarButton} 
                    onClick={clearAllFilters}
                    style={{ background: '#dc3545', color: 'white', borderColor: '#dc3545' }}
                >
                    🗑️ Clear Filters
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
                                {key}: {values.join(', ')}
                            </span>
                        ))}
                    </div>
                )}
                <button 
                    className={styles.toolbarButton} 
                    onClick={() => fetchTicketsData()}
                    style={{ background: '#28a745', color: 'white', borderColor: '#28a745' }}
                >
                    🔄 Refresh
                </button>
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
                                ID 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('ID')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="ID" 
                                    isOpen={filterDropdowns['ID'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Company 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('Company')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Company" 
                                    isOpen={filterDropdowns['Company'] || false} 
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
                                Created By 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('CreatedBy')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="CreatedBy" 
                                    isOpen={filterDropdowns['CreatedBy'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Created Date 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('CreatedDate')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="CreatedDate" 
                                    isOpen={filterDropdowns['CreatedDate'] || false} 
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
                                Quantity 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('Quantity')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Quantity" 
                                    isOpen={filterDropdowns['Quantity'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Purchase Date 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('PurchaseDate')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="PurchaseDate" 
                                    isOpen={filterDropdowns['PurchaseDate'] || false} 
                                    onClose={() => closeAllFilters()}
                                />
                            </th>
                            <th>
                                Location 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('Location')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="Location" 
                                    isOpen={filterDropdowns['Location'] || false} 
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
                        </tr>
                    </thead>
                    <tbody>
                        {currentPageData.map((ticket) => (
                            <tr 
                                key={ticket.id} 
                                className={selectedRows.has(ticket.id) ? styles.selected : ''}
                            >
                                <td>
                                    <input
                                        type="checkbox"
                                        className={styles.rowCheckbox}
                                        checked={selectedRows.has(ticket.id)}
                                        onChange={(event) => toggleRowSelection(ticket.id, event.target.checked)}
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                        value={ticket.id}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                        value={ticket.companyName}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                        value={ticket.customerName}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                        value={ticket.governorateName}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                        value={ticket.cityName}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                        value={ticket.categoryName}
                                        readOnly
                                    />
                                </td>
                                <td className={styles.statusCell}>
                                    {ticket.status}
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                        value={ticket.createdByName}
                                        readOnly
                                    />
                                </td>
                                <td className={styles.date}>
                                    {ticket.createdAt}
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                        value={ticket.items?.[0]?.productName || ''}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                        value={ticket.items?.[0]?.productSize || ''}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    {ticket.items?.[0]?.quantity || 0}
                                </td>
                                <td className={styles.date}>
                                    {ticket.items?.[0]?.purchaseDate || ''}
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                        value={ticket.items?.[0]?.purchaseLocation || ''}
                                        readOnly
                                    />
                                </td>
                                <td>
                                    <input
                                        type="text"
                                        className={styles.cellInput}
                                        value={ticket.items?.[0]?.requestReasonName || ''}
                                        readOnly
                                    />
                                </td>
                                <td className={styles.statusCell}>
                                    {ticket.items?.[0]?.inspected ? 'Yes' : 'No'}
                                </td>
                                <td className={styles.date}>
                                    {ticket.items?.[0]?.inspectionDate || '-'}
                                </td>
                                <td className={styles.statusCell}>
                                    {ticket.items?.[0]?.clientApproval ? 'Yes' : 'No'}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {/* Debug Info */}
            {process.env.NODE_ENV === 'development' && (
                <div style={{ 
                    background: '#f8f9fa', 
                    padding: '10px', 
                    borderTop: '1px solid #dee2e6',
                    fontSize: '12px',
                    fontFamily: 'monospace'
                }}>
                    <strong>Debug Info:</strong> 
                    Page: {currentPage}/{totalPages} | 
                    Page Size: {pageSize} | 
                    Total Items: {totalItems} | 
                    Data Length: {allData.length} | 
                    Filtered: {filteredData ? filteredData.length : 'None'} |
                    Loading: {loading ? 'Yes' : 'No'} |
                    Error: {error || 'None'}
                    <br />
                    <strong>Active Filters:</strong> {Object.keys(activeFilters).length > 0 ? 
                        Object.entries(activeFilters).map(([k, v]) => `${k}:${v.join(',')}`).join(' | ') : 
                        'None'
                    }
                    <br />
                    <strong>Last API Call:</strong> {currentApiUrl || 'None'}
                </div>
            )}

            {/* Footer */}
            <div className={styles.excelFooter}>
                <div className={styles.paginationControls}>
                    {loading && <span style={{ marginRight: '10px', color: '#6c757d' }}>Loading...</span>}
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
                        Page {currentPage} of {totalPages} ({totalItems} total records)
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
                        value={pageSize}
                        onChange={(event) => changePageSize(Number(event.target.value))}
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
                        {loading ? 'Loading...' : 'Ready'} | {(filteredData || allData).length} records | Tickets System
                        {selectedRows.size > 0 && ` | ${selectedRows.size} selected`}
                        {error && ` | Error: ${error}`}
                        {!loading && !error && allData.length > 0 && ` | Page ${currentPage} of ${totalPages}`}
                    </span>
                </div>
            </div>
        </div>
    );
};
