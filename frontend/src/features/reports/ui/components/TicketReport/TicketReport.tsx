'use client';

import React, { useState, useEffect, useRef } from 'react';
import styles from './TicketReport.module.css';

// Sample Maintenance Request Data
const sampleMaintenanceData = [
    {
        id: "5428",
        company: "janssen",
        customer: "محمد عبد الشافى ابراهيم",
        governorate: "القاهرة",
        city: "عين شمس",
        category: "طلب صيانه",
        status: "in_progress",
        createdBy: "يوسف",
        createdDate: "2025-08-10",
        closedDate: "-",
        product: "الماني",
        size: "0*120*25",
        quantity: "2",
        purchaseDate: "2016-12-31",
        location: "",
        reason: "هبوط",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5429",
        company: "janssen",
        customer: "أحمد محمد علي",
        governorate: "الإسكندرية",
        city: "سموحة",
        category: "طلب صيانه",
        status: "completed",
        createdBy: "علي",
        createdDate: "2025-08-09",
        closedDate: "2025-08-12",
        product: "إيطالي",
        size: "0*100*20",
        quantity: "1",
        purchaseDate: "2015-06-15",
        location: "محل البناء",
        reason: "كسر",
        inspected: "Yes",
        inspectionDate: "2025-08-11",
        clientApproval: "Yes"
    },
    {
        id: "5430",
        company: "janssen",
        customer: "فاطمة أحمد",
        governorate: "الجيزة",
        city: "الدقي",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "محمود",
        createdDate: "2025-08-08",
        closedDate: "-",
        product: "صيني",
        size: "0*80*15",
        quantity: "3",
        purchaseDate: "2017-03-22",
        location: "سوق الخردة",
        reason: "صدأ",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5431",
        company: "janssen",
        customer: "عبد الرحمن حسن",
        governorate: "أسيوط",
        city: "أسيوط",
        category: "طلب صيانه",
        status: "in_progress",
        createdBy: "أحمد",
        createdDate: "2025-08-07",
        closedDate: "-",
        product: "الماني",
        size: "0*150*30",
        quantity: "1",
        purchaseDate: "2014-09-10",
        location: "مصنع الخرسانة",
        reason: "تآكل",
        inspected: "Yes",
        inspectionDate: "2025-08-08",
        clientApproval: "No"
    },
    {
        id: "5432",
        company: "janssen",
        customer: "سارة محمود",
        governorate: "المنوفية",
        city: "شبين الكوم",
        category: "طلب صيانه",
        status: "completed",
        createdBy: "محمد",
        createdDate: "2025-08-06",
        closedDate: "2025-08-10",
        product: "إيطالي",
        size: "0*90*18",
        quantity: "2",
        purchaseDate: "2016-01-20",
        location: "ورشة النجارة",
        reason: "انكسار",
        inspected: "Yes",
        inspectionDate: "2025-08-07",
        clientApproval: "Yes"
    },
    {
        id: "5433",
        company: "janssen",
        customer: "خالد عبد الله",
        governorate: "سوهاج",
        city: "سوهاج",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "علي",
        createdDate: "2025-08-05",
        closedDate: "-",
        product: "صيني",
        size: "0*70*12",
        quantity: "4",
        purchaseDate: "2018-07-15",
        location: "مستودع الأدوات",
        reason: "صدأ",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5434",
        company: "janssen",
        customer: "نور الدين",
        governorate: "قنا",
        city: "قنا",
        category: "طلب صيانه",
        status: "in_progress",
        createdBy: "يوسف",
        createdDate: "2025-08-04",
        closedDate: "-",
        product: "الماني",
        size: "0*110*22",
        quantity: "1",
        purchaseDate: "2015-11-30",
        location: "مشروع السد",
        reason: "هبوط",
        inspected: "Yes",
        inspectionDate: "2025-08-05",
        clientApproval: "No"
    },
    {
        id: "5435",
        company: "janssen",
        customer: "مريم أحمد",
        governorate: "الأقصر",
        city: "الأقصر",
        category: "طلب صيانه",
        status: "completed",
        createdBy: "محمود",
        createdDate: "2025-08-03",
        closedDate: "2025-08-07",
        product: "إيطالي",
        size: "0*95*19",
        quantity: "3",
        purchaseDate: "2016-04-12",
        location: "مشروع السياحة",
        reason: "كسر",
        inspected: "Yes",
        inspectionDate: "2025-08-04",
        clientApproval: "Yes"
    },
    {
        id: "5436",
        company: "janssen",
        customer: "عمر حسن",
        governorate: "أسوان",
        city: "أسوان",
        category: "طلب صيانه",
        status: "pending",
        createdBy: "أحمد",
        createdDate: "2025-08-02",
        closedDate: "-",
        product: "صيني",
        size: "0*85*16",
        quantity: "2",
        purchaseDate: "2017-08-25",
        location: "مشروع الطاقة",
        reason: "تآكل",
        inspected: "No",
        inspectionDate: "-",
        clientApproval: "No"
    },
    {
        id: "5437",
        company: "janssen",
        customer: "فاطمة علي",
        governorate: "بني سويف",
        city: "بني سويف",
        category: "طلب صيانه",
        status: "in_progress",
        createdBy: "محمد",
        createdDate: "2025-08-01",
        closedDate: "-",
        product: "الماني",
        size: "0*130*28",
        quantity: "1",
        purchaseDate: "2014-12-05",
        location: "مصنع الأسمنت",
        reason: "هبوط",
        inspected: "Yes",
        inspectionDate: "2025-08-02",
        clientApproval: "No"
    }
];

const TicketReport: React.FC = () => {
    const [activeFilters, setActiveFilters] = useState<Record<string, string[]>>({});
    const [filteredData, setFilteredData] = useState<any[]>([]);
    const [originalData, setOriginalData] = useState<any[]>([]);
    const [selectedRows, setSelectedRows] = useState<Set<string>>(new Set());
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(25);
    const [allData, setAllData] = useState<any[]>([]);
    const [filterDropdowns, setFilterDropdowns] = useState<Record<string, boolean>>({});
    const [filterSelections, setFilterSelections] = useState<Record<string, string[]>>({});

    useEffect(() => {
        setAllData(sampleMaintenanceData);
        setOriginalData(sampleMaintenanceData);
        setFilteredData(sampleMaintenanceData);
    }, []);

    useEffect(() => {
        applyFilters();
    }, [activeFilters]);

    // Click outside handler to close dropdowns
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            const target = event.target as Element;
            if (!target.closest(`.${styles.filterIcon}`) && !target.closest(`.${styles.filterDropdown}`)) {
                setFilterDropdowns({});
            }
        };

        document.addEventListener('mousedown', handleClickOutside);
        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, []);

    const toggleSelectAll = (checked: boolean) => {
        if (checked) {
            const allIds = new Set(allData.map(item => item.id));
            setSelectedRows(allIds);
        } else {
            setSelectedRows(new Set());
        }
    };

    const toggleRowSelection = (id: string, checked: boolean) => {
        const newSelectedRows = new Set(selectedRows);
        if (checked) {
            newSelectedRows.add(id);
        } else {
            newSelectedRows.delete(id);
        }
        setSelectedRows(newSelectedRows);
    };

    const toggleFilter = (column: string) => {
        setFilterDropdowns(prev => ({
            ...prev,
            [column]: !prev[column]
        }));
    };

    const getColumnKey = (columnName: string) => {
        const columnMap: Record<string, string> = {
            'ID': 'id',
            'Company': 'company',
            'Customer': 'customer',
            'Governorate': 'governorate',
            'City': 'city',
            'Category': 'category',
            'Status': 'status',
            'CreatedBy': 'createdBy',
            'CreatedDate': 'createdDate',
            'ClosedDate': 'closedDate',
            'Product': 'product',
            'Size': 'size',
            'Quantity': 'quantity',
            'PurchaseDate': 'purchaseDate',
            'Location': 'location',
            'Reason': 'reason',
            'Inspected': 'inspected',
            'InspectionDate': 'inspectionDate',
            'ClientApproval': 'clientApproval'
        };
        return columnMap[columnName] || columnName.toLowerCase();
    };

    const getUniqueValues = (columnKey: string) => {
        const values = new Set<string>();
        originalData.forEach(row => {
            if (row[columnKey] && row[columnKey] !== '-') {
                values.add(row[columnKey]);
            }
        });
        return Array.from(values).sort();
    };

    const handleFilterSelection = (column: string, value: string, checked: boolean) => {
        setFilterSelections(prev => {
            const current = prev[column] || [];
            if (checked) {
                return { ...prev, [column]: [...current, value] };
            } else {
                return { ...prev, [column]: current.filter(v => v !== value) };
            }
        });
    };

    const handleSelectAllFilter = (column: string, checked: boolean) => {
        const columnKey = getColumnKey(column);
        const uniqueValues = getUniqueValues(columnKey);
        if (checked) {
            setFilterSelections(prev => ({ ...prev, [column]: uniqueValues }));
        } else {
            setFilterSelections(prev => ({ ...prev, [column]: [] }));
        }
    };

    const applyFilter = (column: string) => {
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
    };

    const clearFilter = (column: string) => {
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
    };

    const applyFilters = () => {
        if (Object.keys(activeFilters).length === 0) {
            setFilteredData(originalData);
            return;
        }

        const filtered = originalData.filter(row => {
            return Object.entries(activeFilters).every(([column, allowedValues]) => {
                const columnKey = getColumnKey(column);
                const cellValue = row[columnKey];
                return allowedValues.includes(cellValue);
            });
        });

        setFilteredData(filtered);
        setCurrentPage(1);
    };

    const clearAllFilters = () => {
        setActiveFilters({});
        setFilterSelections({});
        setFilteredData(originalData);
        setCurrentPage(1);
    };

    const exportToCSV = () => {
        const headers = [
            'ID', 'Company', 'Customer', 'Governorate', 'City', 'Category', 'Status',
            'Created By', 'Created Date', 'Closed Date', 'Product', 'Size', 'Quantity',
            'Purchase Date', 'Location', 'Reason', 'Inspected', 'Inspection Date', 'Client Approval'
        ];

        const csvContent = [
            headers.join(','),
            ...filteredData.map(row => [
                row.id, row.company, row.customer, row.governorate, row.city, row.category,
                row.status, row.createdBy, row.createdDate, row.closedDate, row.product,
                row.size, row.quantity, row.purchaseDate, row.location, row.reason,
                row.inspected, row.inspectionDate, row.clientApproval
            ].join(','))
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

    const addNewRow = () => {
        const newRow = {
            id: `new-${Date.now()}`,
            company: "",
            customer: "",
            governorate: "",
            city: "",
            category: "",
            status: "",
            createdBy: "",
            createdDate: "",
            closedDate: "",
            product: "",
            size: "",
            quantity: "",
            purchaseDate: "",
            location: "",
            reason: "",
            inspected: "",
            inspectionDate: "",
            clientApproval: ""
        };
        setAllData(prev => [...prev, newRow]);
        setOriginalData(prev => [...prev, newRow]);
        setFilteredData(prev => [...prev, newRow]);
    };

    const goToFirstPage = () => setCurrentPage(1);
    const goToPreviousPage = () => setCurrentPage(prev => Math.max(1, prev - 1));
    const goToNextPage = () => setCurrentPage(prev => Math.min(Math.ceil(filteredData.length / pageSize), prev + 1));
    const goToLastPage = () => setCurrentPage(Math.ceil(filteredData.length / pageSize));

    const changePageSize = (newSize: number) => {
        setPageSize(newSize);
        setCurrentPage(1);
    };

    const totalPages = Math.ceil(filteredData.length / pageSize);
    const startIndex = (currentPage - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    const currentPageData = filteredData.slice(startIndex, endIndex);

    const FilterDropdown: React.FC<{ column: string; isOpen: boolean }> = ({ column, isOpen }) => {
        if (!isOpen) return null;

        const columnKey = getColumnKey(column);
        const uniqueValues = getUniqueValues(columnKey);
        const selectedValues = filterSelections[column] || [];
        const allSelected = uniqueValues.length > 0 && selectedValues.length === uniqueValues.length;

        return (
            <div className={styles.filterDropdown}>
                <div className={styles.filterHeader}>
                    Filter {column}
                </div>
                <div className={styles.filterOptions}>
                    <div className={styles.filterOption}>
                        <input
                            type="checkbox"
                            checked={allSelected}
                            onChange={(e) => handleSelectAllFilter(column, e.target.checked)}
                        />
                        <label>Select All</label>
                    </div>
                    {uniqueValues.map((value) => (
                        <div key={value} className={styles.filterOption}>
                            <input
                                type="checkbox"
                                checked={selectedValues.includes(value)}
                                onChange={(e) => handleFilterSelection(column, value, e.target.checked)}
                            />
                            <label>{value}</label>
                        </div>
                    ))}
                </div>
                <div className={styles.filterActions}>
                    <button 
                        className={styles.clear} 
                        onClick={() => clearFilter(column)}
                    >
                        Clear
                    </button>
                    <button 
                        className={styles.apply} 
                        onClick={() => applyFilter(column)}
                    >
                        Apply
                    </button>
                </div>
            </div>
        );
    };

    const FilterHeader: React.FC<{ column: string; displayName: string }> = ({ column, displayName }) => {
        const isFiltered = activeFilters[column] && activeFilters[column].length > 0;
        const filterCount = activeFilters[column] ? activeFilters[column].length : 0;

        return (
            <th className={isFiltered ? styles.columnFiltered : ''}>
                {displayName} 
                <span className={styles.filterIcon} onClick={() => toggleFilter(column)}>
                    {isFiltered ? '🔽' : '🔽'}
                </span>
                {isFiltered && (
                    <span className={styles.filterCount}>{filterCount}</span>
                )}
                <FilterDropdown column={column} isOpen={filterDropdowns[column] || false} />
            </th>
        );
    };

    return (
        <div className={styles.excelContainer}>
            <div className={styles.excelToolbar}>
                <button className={styles.toolbarButton} onClick={() => alert('Find functionality')}>🔍 Find</button>
                <button className={styles.toolbarButton} onClick={clearAllFilters} style={{ background: '#dc3545', color: 'white', borderColor: '#dc3545' }}>🗑️ Clear Filters</button>
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
                                    checked={selectedRows.size === allData.length && allData.length > 0}
                                    ref={(input) => {
                                        if (input) {
                                            input.indeterminate = selectedRows.size > 0 && selectedRows.size < allData.length;
                                        }
                                    }}
                                />
                            </th>
                            <FilterHeader column="ID" displayName="ID" />
                            <FilterHeader column="Company" displayName="Company" />
                            <FilterHeader column="Customer" displayName="Customer" />
                            <FilterHeader column="Governorate" displayName="Governorate" />
                            <FilterHeader column="City" displayName="City" />
                            <FilterHeader column="Category" displayName="Category" />
                            <FilterHeader column="Status" displayName="Status" />
                            <FilterHeader column="CreatedBy" displayName="Created By" />
                            <FilterHeader column="CreatedDate" displayName="Created Date" />
                            <FilterHeader column="ClosedDate" displayName="Closed Date" />
                            <FilterHeader column="Product" displayName="Product" />
                            <FilterHeader column="Size" displayName="Size" />
                            <FilterHeader column="Quantity" displayName="Quantity" />
                            <FilterHeader column="PurchaseDate" displayName="Purchase Date" />
                            <FilterHeader column="Location" displayName="Location" />
                            <FilterHeader column="Reason" displayName="Reason" />
                            <FilterHeader column="Inspected" displayName="Inspected" />
                            <FilterHeader column="InspectionDate" displayName="Inspection Date" />
                            <FilterHeader column="ClientApproval" displayName="Client Approval" />
                        </tr>
                    </thead>
                    <tbody>
                        {currentPageData.map((row, index) => (
                            <tr key={row.id} className={selectedRows.has(row.id) ? styles.selected : ''}>
                                <td>
                                    <input 
                                        type="checkbox" 
                                        className={styles.rowCheckbox}
                                        value={row.id}
                                        checked={selectedRows.has(row.id)}
                                        onChange={(e) => toggleRowSelection(row.id, e.target.checked)}
                                    />
                                </td>
                                <td><input type="text" className={styles.cellInput} value={row.id} readOnly /></td>
                                <td><input type="text" className={styles.cellInput} value={row.company} readOnly /></td>
                                <td><input type="text" className={styles.cellInput} value={row.customer} readOnly /></td>
                                <td><input type="text" className={styles.cellInput} value={row.governorate} readOnly /></td>
                                <td><input type="text" className={styles.cellInput} value={row.city} readOnly /></td>
                                <td><input type="text" className={styles.cellInput} value={row.category} readOnly /></td>
                                <td className={styles.statusCell}>{row.status}</td>
                                <td><input type="text" className={styles.cellInput} value={row.createdBy} readOnly /></td>
                                <td className={styles.date}>{row.createdDate}</td>
                                <td className={styles.date}>{row.closedDate}</td>
                                <td><input type="text" className={styles.cellInput} value={row.product} readOnly /></td>
                                <td><input type="text" className={styles.cellInput} value={row.size} readOnly /></td>
                                <td className={styles.currency}>{row.quantity}</td>
                                <td className={styles.date}>{row.purchaseDate}</td>
                                <td><input type="text" className={styles.cellInput} value={row.location} readOnly /></td>
                                <td><input type="text" className={styles.cellInput} value={row.reason} readOnly /></td>
                                <td className={styles.statusCell}>{row.inspected}</td>
                                <td className={styles.date}>{row.inspectionDate}</td>
                                <td className={styles.statusCell}>{row.clientApproval}</td>
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
                        value={pageSize}
                        onChange={(e) => changePageSize(parseInt(e.target.value))}
                    >
                        <option value={10}>10</option>
                        <option value={25}>25</option>
                        <option value={50}>50</option>
                        <option value={100}>100</option>
                    </select>
                    <span className={styles.recordsInfo}>records per page</span>
                </div>
                <div className={styles.statusInfo}>
                    <span>Ready | {filteredData.length} records | Maintenance System</span>
                </div>
            </div>
        </div>
    );
};

export default TicketReport;
