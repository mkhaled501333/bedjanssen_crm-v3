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

    // Refs
    const tableRef = useRef<HTMLTableElement>(null);
    const selectAllCheckboxRef = useRef<HTMLInputElement>(null);

    // Calculate pagination
    const startIndex = (currentPage - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    const currentPageData = (filteredData || allData).slice(startIndex, endIndex);

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

            const response = await fetch(
                `http://localhost:8081/api/reports/tickets?companyId=${companyId}&page=${currentPage}&limit=${pageSize}`,
                {
                    method: 'GET',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    }
                }
            );

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data: TicketsReportResponse = await response.json();

            if (data.success && data.data) {
                setAllData(data.data.tickets);
                setTotalPages(data.data.pagination.totalPages);
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
    }, [currentPage, pageSize]);

    // Initialize data on component mount
    useEffect(() => {
        fetchTicketsData();
    }, [fetchTicketsData]);

    // Refetch data when pagination changes
    useEffect(() => {
        if (allData.length > 0) {
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
    };

    const clearFilter = (column: string) => {
        setActiveFilters(prev => {
            const newFilters = { ...prev };
            delete newFilters[column];
            return newFilters;
        });
    };

    const clearAllFilters = () => {
        setActiveFilters({});
        setFilteredData(null);
    };

    // Apply filters to data
    useEffect(() => {
        if (Object.keys(activeFilters).length === 0) {
            setFilteredData(null);
            return;
        }

        const filtered = allData.filter(ticket => {
            return Object.entries(activeFilters).every(([column, allowedValues]) => {
                let value: string = '';
                
                switch (column) {
                    case 'Status':
                        value = ticket.status;
                        break;
                    case 'Category':
                        value = ticket.categoryName;
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
                    case 'CreatedBy':
                        value = ticket.createdByName;
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
                    default:
                        value = '';
                }
                
                return allowedValues.includes(value);
            });
        });

        setFilteredData(filtered);
        setCurrentPage(1);
    }, [activeFilters, allData]);

    // Pagination functions
    const goToFirstPage = () => setCurrentPage(1);
    const goToPreviousPage = () => setCurrentPage(prev => Math.max(1, prev - 1));
    const goToNextPage = () => setCurrentPage(prev => Math.min(totalPages, prev + 1));
    const goToLastPage = () => setCurrentPage(totalPages);

    const changePageSize = (newSize: number) => {
        setPageSize(newSize);
        setCurrentPage(1);
    };

    // Row selection functions
    const toggleSelectAll = (checked: boolean) => {
        if (checked) {
            const allIds = currentPageData.map(ticket => ticket.id);
            setSelectedRows(new Set(allIds));
        } else {
            setSelectedRows(new Set());
        }
    };

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

    // Export to CSV
    const exportToCSV = () => {
        const data = filteredData || allData;
        const headers = [
            'ID', 'Company', 'Customer', 'Governorate', 'City', 'Category', 'Status',
            'Created By', 'Created Date', 'Closed Date', 'Product', 'Size', 'Quantity',
            'Purchase Date', 'Location', 'Reason', 'Inspected', 'Inspection Date', 'Client Approval'
        ];

        const csvContent = [
            headers.join(','),
            ...data.map(ticket => [
                ticket.id,
                ticket.companyName,
                ticket.customerName,
                ticket.governorateName,
                ticket.cityName,
                ticket.categoryName,
                ticket.status,
                ticket.createdByName,
                new Date(ticket.createdAt).toLocaleDateString(),
                ticket.closedAt ? new Date(ticket.closedAt).toLocaleDateString() : '-',
                ticket.items?.[0]?.productName || '',
                ticket.items?.[0]?.productSize || '',
                ticket.items?.[0]?.quantity || 0,
                ticket.items?.[0]?.purchaseDate || '',
                ticket.items?.[0]?.purchaseLocation || '',
                ticket.items?.[0]?.requestReasonName || '',
                ticket.items?.[0]?.inspected ? 'Yes' : 'No',
                ticket.items?.[0]?.inspectionDate || '-',
                ticket.items?.[0]?.clientApproval ? 'Yes' : 'No'
            ].map(field => `"${field}"`).join(','))
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.setAttribute('href', url);
        link.setAttribute('download', 'ticket-report-export.csv');
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    // Add new row (placeholder for future functionality)
    const addNewRow = () => {
        alert('Add new row functionality will be implemented here');
    };

    // Get unique values for filter dropdowns
    const getUniqueColumnValues = (column: string): string[] => {
        const values = new Set<string>();
        
        allData.forEach(ticket => {
            let value: string = '';
            
            switch (column) {
                case 'Status':
                    value = ticket.status;
                    break;
                case 'Category':
                    value = ticket.categoryName;
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
                case 'CreatedBy':
                    value = ticket.createdByName;
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
    };

    // Filter dropdown component
    const FilterDropdown: React.FC<{ column: string; isOpen: boolean; onClose: () => void }> = ({ column, isOpen, onClose }) => {
        const [searchTerm, setSearchTerm] = useState('');
        const [selectedValues, setSelectedValues] = useState<string[]>([]);
        const uniqueValues = getUniqueColumnValues(column);

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
            <div className={styles.filterDropdown} style={{ display: 'block' }}>
                <div className={styles.filterHeader}>Filter {column}</div>
                <input
                    type="text"
                    className={styles.filterSearch}
                    placeholder="Search..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                />
                <div className={styles.filterOptions}>
                    {filteredOptions.map(value => (
                        <div key={value} className={styles.filterOption}>
                            <input
                                type="checkbox"
                                id={`filter-${column}-${value}`}
                                checked={selectedValues.includes(value)}
                                onChange={(e) => {
                                    if (e.target.checked) {
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
                                    onChange={(e) => toggleSelectAll(e.target.checked)}
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
                                    className={styles.filterIcon} 
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
                                    className={styles.filterIcon} 
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
                                Closed Date 
                                <span 
                                    className={styles.filterIcon} 
                                    onClick={() => toggleFilter('ClosedDate')}
                                >
                                    🔽
                                </span>
                                <FilterDropdown 
                                    column="ClosedDate" 
                                    isOpen={filterDropdowns['ClosedDate'] || false} 
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
                                        onChange={(e) => toggleRowSelection(ticket.id, e.target.checked)}
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
                                    {new Date(ticket.createdAt).toLocaleDateString()}
                                </td>
                                <td className={styles.date}>
                                    {ticket.closedAt ? new Date(ticket.closedAt).toLocaleDateString() : '-'}
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
                                <td className={styles.currency}>
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

            {/* Footer */}
            <div className={styles.excelFooter}>
                <div className={styles.paginationControls}>
                    <button 
                        className={styles.paginationBtn} 
                        onClick={goToFirstPage}
                        disabled={currentPage === 1}
                        title="First Page"
                    >
                        ⏮️
                    </button>
                    <button 
                        className={styles.paginationBtn} 
                        onClick={goToPreviousPage}
                        disabled={currentPage === 1}
                        title="Previous Page"
                    >
                        ◀️
                    </button>
                    <span className={styles.pageInfo}>
                        Page {currentPage} of {totalPages}
                    </span>
                    <button 
                        className={styles.paginationBtn} 
                        onClick={goToNextPage}
                        disabled={currentPage === totalPages}
                        title="Next Page"
                    >
                        ▶️
                    </button>
                    <button 
                        className={styles.paginationBtn} 
                        onClick={goToLastPage}
                        disabled={currentPage === totalPages}
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
                        onChange={(e) => changePageSize(Number(e.target.value))}
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
                        Ready | {(filteredData || allData).length} records | Tickets System
                        {selectedRows.size > 0 && ` | ${selectedRows.size} selected`}
                    </span>
                </div>
            </div>
    </div>
  );
};
