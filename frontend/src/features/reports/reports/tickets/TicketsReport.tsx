'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { format } from 'date-fns';
import { 
  Calendar, 
  Search, 
  Filter, 
  Download, 
  RefreshCw, 
  ChevronLeft, 
  ChevronRight,
  AlertCircle,
  Clock,
  CheckCircle,
  Printer,
  Users,
  Database,
} from 'lucide-react';
import type { TicketsReportProps, TicketsFilters, Ticket } from './types';
import { getTicketsReport, exportTicketsReport, getCompanies, type Company } from './api';
import { getCurrentUserCompanyId } from '@/shared/utils/auth';
import { UserManagement } from '@/features/masterdata/ui/components';
import styles from './TicketsReport.module.css';

const TicketsReport: React.FC<TicketsReportProps> = ({
  data,
  loading: externalLoading,
  error: externalError,
  onRefresh,
  onExport,
  onFiltersChange
}) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [reportData, setReportData] = useState(data);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [selectedTicket, setSelectedTicket] = useState<Ticket | null>(null);
  const [showFilters, setShowFilters] = useState(false);
  const [columnFilters, setColumnFilters] = useState<{[key: string]: string | string[]}>({});
  const [openDropdown, setOpenDropdown] = useState<string | null>(null);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loadingCompanies, setLoadingCompanies] = useState(false);
  const [selectedTickets, setSelectedTickets] = useState<Set<number>>(new Set());
  const [selectAll, setSelectAll] = useState(false);
  const [activeSection, setActiveSection] = useState<'tickets' | 'masterdata'>('tickets');
  const [activeMasterDataTab, setActiveMasterDataTab] = useState<'users'>('users');
  
  // Get company ID from storage or default to 1
const userCompanyId = getCurrentUserCompanyId() || 1;
  const [filters, setFilters] = useState<TicketsFilters>({
    companyId: userCompanyId,
    startDate: format(new Date().setDate(new Date().getDate() - 30), 'yyyy-MM-dd'),
    endDate: format(new Date(), 'yyyy-MM-dd'),
  });

  // Fetch companies on component mount
  useEffect(() => {
    const fetchCompanies = async () => {
      setLoadingCompanies(true);
      try {
        const companiesData = await getCompanies();
        setCompanies(companiesData);
      } catch (err) {
        console.error('Failed to fetch companies:', err);
      } finally {
        setLoadingCompanies(false);
      }
    };

    fetchCompanies();
  }, []);

  useEffect(() => {
    if (data) {
      setReportData(data);
    }
  }, [data]);

  useEffect(() => {
    if (externalError) {
      setError(externalError);
    }
  }, [externalError]);

  // Fetch data when filters or pagination change
  useEffect(() => {
    if (!data) {
      handleRefresh();
    }
  }, [filters, currentPage, itemsPerPage, data]);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (openDropdown && !(event.target as Element).closest(`.${styles.columnFilterContainer}`)) {
        setOpenDropdown(null);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [openDropdown]);

  const handleRefresh = async () => {
    if (onRefresh) {
      onRefresh();
      return;
    }

    setLoading(true);
    setError(null);
    
    try {
      const newData = await getTicketsReport(filters, currentPage, itemsPerPage);
      setReportData(newData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch tickets report');
    } finally {
      setLoading(false);
    }
  };

  const handleExport = async (format: 'pdf' | 'excel' | 'csv') => {
    if (onExport) {
      onExport();
      return;
    }

    try {
      const blob = await exportTicketsReport(filters, format);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `tickets-report-${filters.startDate}-${filters.endDate}.${format}`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to export report');
    }
  };

  const handleFiltersChange = (newFilters: TicketsFilters) => {
    setFilters(newFilters);
    setCurrentPage(1); // Reset to first page when filters change
    
    if (onFiltersChange) {
      onFiltersChange(newFilters);
    }
  };

  const handlePageChange = (page: number) => {
    setCurrentPage(page);
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'open':
        return <AlertCircle className={styles.statusIconOpen} />;
      case 'in_progress':
        return <Clock className={styles.statusIconProgress} />;
      case 'closed':
        return <CheckCircle className={styles.statusIconClosed} />;
      default:
        return <AlertCircle className={styles.statusIconOpen} />;
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'open':
        return 'مفتوح';
      case 'in_progress':
        return 'قيد المعالجة';
      case 'closed':
        return 'مغلق';
      default:
        return status;
    }
  };

  const getPriorityText = (priority: string) => {
    switch (priority) {
      case 'low':
        return 'منخفض';
      case 'medium':
        return 'متوسط';
      case 'high':
        return 'عالي';
      default:
        return priority;
    }
  };

  const getPriorityClass = (priority: string) => {
    switch (priority) {
      case 'low':
        return styles.priorityLow;
      case 'medium':
        return styles.priorityMedium;
      case 'high':
        return styles.priorityHigh;
      default:
        return styles.priorityMedium;
    }
  };

  // Extract unique values for each column for dropdown filters
  const columnUniqueValues = useMemo(() => {
    if (!reportData?.tickets) return {};
    
    const uniqueValues: {[key: string]: string[]} = {};
    const tickets = reportData.tickets;
    
    // Extract unique values for each filterable column
    uniqueValues.customerName = [...new Set(tickets.map(t => t.customerName).filter(Boolean))].sort();
    uniqueValues.companyName = [...new Set(tickets.map(t => t.companyName).filter(Boolean))].sort();
    uniqueValues.governorateName = [...new Set(tickets.map(t => t.governorateName).filter(Boolean))].sort();
    uniqueValues.cityName = [...new Set(tickets.map(t => t.cityName).filter(Boolean))].sort();
    uniqueValues.categoryName = [...new Set(tickets.map(t => t.categoryName).filter(Boolean))].sort();
    uniqueValues.status = [...new Set(tickets.map(t => getStatusText(t.status)).filter(Boolean))].sort();
    
    return uniqueValues;
  }, [reportData?.tickets]);

  // Create expanded ticket-item rows
  const expandedTicketRows = useMemo(() => {
    if (!reportData?.tickets) return [];
    
    const expandedRows: Array<{
      ticketId: number;
      itemId: number | null;
      ticket: Ticket;
      item: any | null;
      isFirstItemRow: boolean;
    }> = [];
    
    // Debug: Log the first ticket's items to see data structure
    if (reportData.tickets.length > 0 && reportData.tickets[0].items?.length > 0) {
      console.log('First ticket item data:', reportData.tickets[0].items[0]);
    }
    
    reportData.tickets.forEach(ticket => {
      if (ticket.items && ticket.items.length > 0) {
        // Create a row for each item
        ticket.items.forEach((item, index) => {
          expandedRows.push({
            ticketId: ticket.id,
            itemId: item.id,
            ticket,
            item,
            isFirstItemRow: index === 0
          });
        });
      } else {
        // Create a single row for tickets without items
        expandedRows.push({
          ticketId: ticket.id,
          itemId: null,
          ticket,
          item: null,
          isFirstItemRow: true
        });
      }
    });
    
    return expandedRows;
  }, [reportData?.tickets]);

  // Filter expanded rows based on column filters
  const filteredTicketRows = useMemo(() => {
    if (!expandedTicketRows) return [];
    
    return expandedTicketRows.filter(row => {
      const ticket = row.ticket;
      return Object.entries(columnFilters).every(([column, filterValue]) => {
        if (!filterValue || (Array.isArray(filterValue) && filterValue.length === 0)) return true;
        
        switch (column) {
          case 'customerName':
            return Array.isArray(filterValue) 
              ? filterValue.includes(ticket.customerName)
              : ticket.customerName === filterValue;
          case 'companyName':
            return Array.isArray(filterValue) 
              ? filterValue.includes(ticket.companyName)
              : ticket.companyName === filterValue;
          case 'governorateName':
            return Array.isArray(filterValue) 
              ? filterValue.includes(ticket.governorateName)
              : ticket.governorateName === filterValue;
          case 'cityName':
            return Array.isArray(filterValue)
              ? filterValue.includes(ticket.cityName)
              : ticket.cityName === filterValue;
          case 'categoryName':
            return Array.isArray(filterValue) 
              ? filterValue.includes(ticket.categoryName)
              : ticket.categoryName === filterValue;
          case 'status':
            return Array.isArray(filterValue)
              ? filterValue.includes(getStatusText(ticket.status))
              : getStatusText(ticket.status) === filterValue;
          default:
            return true;
        }
      });
    });
  }, [expandedTicketRows, columnFilters]);

  const handleColumnFilter = (column: string, value: string) => {
    const isMultiSelect = true; // Enable multi-select for all columns
    
    if (isMultiSelect) {
      setColumnFilters(prev => {
        const currentValues = Array.isArray(prev[column]) ? prev[column] as string[] : [];
        const newValues = currentValues.includes(value)
          ? currentValues.filter(v => v !== value)
          : [...currentValues, value];
        
        return {
          ...prev,
          [column]: newValues
        };
      });
    } else {
      setColumnFilters(prev => ({
        ...prev,
        [column]: value === prev[column] ? '' : value
      }));
      setOpenDropdown(null);
    }
  };

  const clearColumnFilter = (column: string) => {
    setColumnFilters(prev => {
      const newFilters = { ...prev };
      delete newFilters[column];
      return newFilters;
    });
    setOpenDropdown(null);
  };

  // Selection handlers
  const handleSelectTicket = (ticketId: number) => {
    setSelectedTickets(prev => {
      const newSelected = new Set(prev);
      if (newSelected.has(ticketId)) {
        newSelected.delete(ticketId);
      } else {
        newSelected.add(ticketId);
      }
      return newSelected;
    });
  };

  const handleSelectAll = () => {
    if (selectAll) {
      setSelectedTickets(new Set());
      setSelectAll(false);
    } else {
      const allTicketIds = new Set(filteredTicketRows?.map(row => row.ticket.id) || []);
      setSelectedTickets(allTicketIds);
      setSelectAll(true);
    }
  };

  // Update selectAll state when individual selections change
  useEffect(() => {
    if (filteredTicketRows) {
      const allTicketIds = [...new Set(filteredTicketRows.map(row => row.ticket.id))];
      const allSelected = allTicketIds.length > 0 && allTicketIds.every(id => selectedTickets.has(id));
      setSelectAll(allSelected);
    }
  }, [selectedTickets, filteredTicketRows]);

  // Print functionality
  const handlePrintSelected = async () => {
    if (selectedTickets.size === 0) {
      alert('يرجى اختيار تذكرة واحدة على الأقل للطباعة');
      return;
    }

    const selectedTicketData = filteredTicketRows 
      ? [...new Set(filteredTicketRows.filter(row => selectedTickets.has(row.ticket.id)).map(row => row.ticket))]
      : [];
    await printTickets(selectedTicketData);
  };

  const printTickets = async (tickets: Ticket[]) => {
    if (tickets.length === 0) return;
    
    const printWindow = window.open('', '_blank');
    if (!printWindow) return;

    const currentDate = format(new Date(), 'dd-MM-yyyy');
    const currentTime = format(new Date(), 'HH:mm');

    // Generate content for each ticket on separate pages
    const ticketPages = await Promise.all(tickets.map(async (ticket, index) => {
      // Get customer details for each ticket
      let customerData = {
        name: ticket.customerName,
        governorate: ticket.governorateName,
        city: ticket.cityName,
        address: '',
        phone: ''
      };
      
      try {
        const { getCustomerDetails } = await import('../../../customerdata/api');
        const customerResponse = await getCustomerDetails(ticket.customerId.toString());
        if (customerResponse.success) {
          customerData = {
            name: customerResponse.data.name,
            governorate: customerResponse.data.governorate,
            city: customerResponse.data.city,
            address: customerResponse.data.address || '',
            phone: customerResponse.data.phones.length > 0 ? customerResponse.data.phones[0].phone : ''
          };
        }
      } catch (error) {
        console.error('Failed to fetch customer details:', error);
        // Continue with basic data from ticket
      }

      return `
        <div class="document" ${index > 0 ? 'style="page-break-before: always;"' : ''}>
          <div class="header-line">الرقم التسلسلي للتذكرة: ${ticket.id}</div>
          
          <div class="company-name">شركة بيد جانسن للتجارة والمقاولات</div>
          
          <div class="form-title">نموذج ابلاغ عن حالة وجود شكاوى العملاء</div>
          
          <div class="separator-line"></div>
          
          <div class="info-section">
            <div class="right-info">
              <div class="info-line">التاريخ: ${currentDate}</div>
              <div class="info-line">اسم العميل: ${customerData.name}</div>
              <div class="info-line">المحافظة: ${customerData.governorate}</div>
              <div class="info-line">المدينة: ${customerData.city}</div>
              <div class="info-line">العنوان: ${customerData.address}</div>
              <div class="info-line">الهاتف: ${customerData.phone}</div>
            </div>
          </div>
          
          <div style="margin-bottom: 30px; page-break-inside: avoid;">
            ${ticket.items && ticket.items.length > 0 ? `
              <table style="width: 100%; border-collapse: collapse; font-size: 11px;">
                <thead>
                  <tr>
                    <th style="border: 1px solid #000; padding: 8px; background-color: #f0f0f0; font-weight: bold;">اسم المنتج</th>
                    <th style="border: 1px solid #000; padding: 8px; background-color: #f0f0f0; font-weight: bold;">الحجم</th>
                    <th style="border: 1px solid #000; padding: 8px; background-color: #f0f0f0; font-weight: bold;">الكمية</th>
                    <th style="border: 1px solid #000; padding: 8px; background-color: #f0f0f0; font-weight: bold;">مكان الشراء</th>
                    <th style="border: 1px solid #000; padding: 8px; background-color: #f0f0f0; font-weight: bold;">تاريخ الشراء</th>
                    <th style="border: 1px solid #000; padding: 8px; background-color: #f0f0f0; font-weight: bold;">سبب الطلب</th>
                  </tr>
                </thead>
                <tbody>
                  ${ticket.items.map(item => `
                    <tr>
                      <td style="border: 1px solid #000; padding: 8px; text-align: center;">${item.productName}</td>
                      <td style="border: 1px solid #000; padding: 8px; text-align: center;">${item.productSize}</td>
                      <td style="border: 1px solid #000; padding: 8px; text-align: center;">${item.quantity}</td>
                      <td style="border: 1px solid #000; padding: 8px; text-align: center;">${item.purchaseLocation}</td>
                      <td style="border: 1px solid #000; padding: 8px; text-align: center;">${format(new Date(item.purchaseDate), 'yyyy-MM-dd')}</td>
                      <td style="border: 1px solid #000; padding: 8px; text-align: center;">${item.requestReasonName}</td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
            ` : '<p style="font-size: 11px; color: #666;">لا توجد عناصر مرتبطة بهذه التذكرة</p>'}
          </div>
          
          <div class="footer-section">
            <div class="footer-line">تم تسليم هذا النموذج لقسم الجودة بتاريخ : _______________</div>
            <div class="footer-line">ملاحظات :</div>
            <div class="footer-line">تقرير الفني :</div>
          </div>
        </div>
      `;
    }));

    const printContent = `
      <!DOCTYPE html>
      <html dir="rtl" lang="ar">
      <head>
        <meta charset="UTF-8">
        <title>نموذج ابلاغ عن حالة وجود شكاوى العملاء</title>
        <style>
          * { box-sizing: border-box; }
          body { 
            font-family: 'Arial', sans-serif; 
            margin: 0; 
            padding: 20px; 
            direction: rtl; 
            background: white;
            font-size: 12px;
            line-height: 1.6;
          }
          .document {
            max-width: 210mm;
            margin: 0 auto;
            background: white;
            padding: 6mm;
            min-height: 240mm;
            border: 2px solid #000;
            margin-bottom: 20px;
          }
          .header-line {
            text-align: center;
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 8px;
          }
          .company-name {
            text-align: center;
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 8px;
          }
          .form-title {
            text-align: center;
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 15px;
            text-decoration: underline;
          }
          .footer-section {
            margin-top: 8px;
            font-size: 9px;
            line-height: 1.3;
          }
          .footer-line {
            margin-bottom: 15px;
            padding-bottom: 5px;
          }
          .separator-line {
            margin: 15px 0;
          }
          .info-section {
            display: flex;
            justify-content: flex-end;
            text-align: right;
            margin: 5px 0;
          }
          .right-info {
            text-align: right;
            flex: 1;
            font-size: 14px;
            line-height: 1.2;
            font-weight: normal;
          }
          .info-line {
            margin-bottom: 8px;
          }
          .tickets-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 8px;
            font-size: 8px;
          }
          .tickets-table th,
          .tickets-table td {
            border: 1px solid #000;
            padding: 4px;
            text-align: center;
            vertical-align: middle;
          }
          .tickets-table th {
            background-color: #f0f0f0;
            font-weight: bold;
            font-size: 9px;
          }
          .tickets-table td {
            font-size: 9px;
            max-width: 80px;
            word-wrap: break-word;
          }
          .status-cell {
            font-weight: bold;
          }
          .status-open { color: #dc3545; }
          .status-in_progress { color: #ffc107; }
          .status-closed { color: #28a745; }
          @media print {
            body { margin: 0; padding: 0; }
            .document { 
              padding: 10mm;
              margin-bottom: 0;
            }
          }
        </style>
      </head>
      <body>
        ${ticketPages.join('')}
      </body>
      </html>
    `;

    printWindow.document.write(printContent);
    printWindow.document.close();
    printWindow.focus();
    printWindow.print();
  };

  // Column Filter Dropdown Component
  const ColumnFilterDropdown = ({ column, title, values }: { column: string; title: string; values: string[] }) => {
    const isOpen = openDropdown === column;
    const isMultiSelect = true; // Enable multi-select for all columns
    const currentFilter = columnFilters[column];
    const hasFilter = isMultiSelect 
      ? Array.isArray(currentFilter) && currentFilter.length > 0
      : !!currentFilter;
    
    const selectedCount = isMultiSelect && Array.isArray(currentFilter) ? currentFilter.length : 0;
    
    // Local state for the dropdown
    const [searchTerm, setSearchTerm] = useState('');
    const [tempSelection, setTempSelection] = useState<string | string[]>(
      isMultiSelect ? (Array.isArray(currentFilter) ? [...currentFilter] : []) : (currentFilter || '')
    );
    
    // Filter values based on search term
    const filteredValues = values.filter(value => 
      value.toLowerCase().includes(searchTerm.toLowerCase())
    );
    
    const handleTempSelection = (value: string) => {
      if (isMultiSelect) {
        const currentArray = Array.isArray(tempSelection) ? tempSelection : [];
        const newSelection = currentArray.includes(value)
          ? currentArray.filter(v => v !== value)
          : [...currentArray, value];
        setTempSelection(newSelection);
      } else {
        setTempSelection(value === tempSelection ? '' : value);
      }
    };
    
    const handleApply = () => {
      if (isMultiSelect) {
        setColumnFilters(prev => ({
          ...prev,
          [column]: Array.isArray(tempSelection) ? tempSelection : []
        }));
      } else {
        if (tempSelection) {
          setColumnFilters(prev => ({
            ...prev,
            [column]: tempSelection
          }));
        } else {
          const newFilters = { ...columnFilters };
          delete newFilters[column];
          setColumnFilters(newFilters);
        }
      }
      setOpenDropdown(null);
      setSearchTerm('');
    };
    
    const handleCancel = () => {
      setTempSelection(
        isMultiSelect ? (Array.isArray(currentFilter) ? [...currentFilter] : []) : (currentFilter || '')
      );
      setOpenDropdown(null);
      setSearchTerm('');
    };
    
    const handleClearAll = () => {
      setTempSelection(isMultiSelect ? [] : '');
    };
    
    return (
      <div className={styles.columnFilterContainer}>
        <div className={styles.columnHeader}>
          <span>{title}</span>
          {isMultiSelect && selectedCount > 0 && (
            <span className={styles.selectedCount}>({selectedCount})</span>
          )}
          <button
            className={`${styles.filterDropdownButton} ${hasFilter ? styles.filtered : ''}`}
            onClick={() => {
              if (isOpen) {
                setOpenDropdown(null);
                setSearchTerm('');
              } else {
                setOpenDropdown(column);
                setTempSelection(
                  isMultiSelect ? (Array.isArray(currentFilter) ? [...currentFilter] : []) : (currentFilter || '')
                );
              }
            }}
          >
            <Filter className={styles.filterIcon} />
          </button>
        </div>
        
        {isOpen && (
          <div className={styles.filterDropdown}>
            {/* Search Input */}
            <div className={styles.filterSearchContainer}>
              <Search className={styles.filterSearchIcon} />
              <input
                type="text"
                placeholder="البحث..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className={styles.filterSearchInput}
                onClick={(e) => e.stopPropagation()}
              />
            </div>
            
            {/* Options */}
            <div className={styles.filterOptions}>
              {!isMultiSelect && (
                <button
                  className={`${styles.filterOption} ${!tempSelection ? styles.selected : ''}`}
                  onClick={() => setTempSelection('')}
                >
                  الكل
                </button>
              )}
              
              {filteredValues.length > 0 ? (
                filteredValues.map((value) => {
                  const isSelected = isMultiSelect 
                    ? Array.isArray(tempSelection) && tempSelection.includes(value)
                    : tempSelection === value;
                  
                  return (
                    <button
                      key={value}
                      className={`${styles.filterOption} ${isSelected ? styles.selected : ''}`}
                      onClick={() => handleTempSelection(value)}
                    >
                      {isMultiSelect && (
                        <input
                          type="checkbox"
                          checked={isSelected}
                          onChange={() => {}}
                          className={styles.checkbox}
                        />
                      )}
                      {value}
                    </button>
                  );
                })
              ) : (
                <div className={styles.noResults}>لا توجد نتائج</div>
              )}
            </div>
            
            {/* Action Buttons */}
            <div className={styles.filterActions}>
              {isMultiSelect && (
                <button
                  onClick={handleClearAll}
                  className={styles.filterClearButton}
                >
                  مسح الكل
                </button>
              )}
              <div className={styles.filterActionButtons}>
                <button
                  onClick={handleCancel}
                  className={styles.filterCancelButton}
                >
                  إلغاء
                </button>
                <button
                  onClick={handleApply}
                  className={styles.filterApplyButton}
                >
                  تطبيق
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  };

  const isLoading = loading || externalLoading;

  return (
    <div className={styles.container}>
      {/* Section Navigation */}
      <div className={styles.sectionTabs}>
        <button
          className={`${styles.sectionTab} ${activeSection === 'tickets' ? styles.activeSectionTab : ''}`}
          onClick={() => setActiveSection('tickets')}
        >
          <Database className={styles.tabIcon} />
          Tickets Report
        </button>
        <button
          className={`${styles.sectionTab} ${activeSection === 'masterdata' ? styles.activeSectionTab : ''}`}
          onClick={() => setActiveSection('masterdata')}
        >
          <Users className={styles.tabIcon} />
          Master Data Management
        </button>
      </div>

      {activeSection === 'tickets' ? (
        <>
          {/* Header */}
          <div className={styles.header}>
        <div className={styles.headerLeft}>
          {reportData?.summary && (
            <div className={styles.summaryCards}>
              <div className={styles.summaryCard}>
                <span className={styles.summaryLabel}>المفتوحة</span>
                <span className={styles.summaryValue}>{reportData.summary.statusCounts.open}</span>
              </div>
              <div className={styles.summaryCard}>
                <span className={styles.summaryLabel}>قيد المعالجة</span>
                <span className={styles.summaryValue}>{reportData.summary.statusCounts.in_progress}</span>
              </div>
              <div className={styles.summaryCard}>
                <span className={styles.summaryLabel}>المغلقة</span>
                <span className={styles.summaryValue}>{reportData.summary.statusCounts.closed}</span>
              </div>
            </div>
          )}
        </div>
        
        <div className={styles.headerActions}>
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`${styles.actionButton} ${showFilters ? styles.active : ''}`}
          >
            <Filter className={styles.icon} />
            فلترة
          </button>
          
          <button
            onClick={handleRefresh}
            disabled={isLoading}
            className={styles.actionButton}
          >
            <RefreshCw className={`${styles.icon} ${isLoading ? styles.spinning : ''}`} />
            تحديث
          </button>
          
          <button
            onClick={() => handleExport('excel')}
            className={styles.actionButton}
          >
            <Download className={styles.icon} />
            تصدير
          </button>
          
          <button
            onClick={handlePrintSelected}
            disabled={selectedTickets.size === 0}
            className={`${styles.actionButton} ${selectedTickets.size === 0 ? styles.disabled : ''}`}
            title={selectedTickets.size === 0 ? 'اختر تذاكر للطباعة' : `طباعة ${selectedTickets.size} تذكرة`}
          >
            <Printer className={styles.icon} />
            طباعة ({selectedTickets.size})
          </button>
        </div>
      </div>

      {/* Filters */}
      {showFilters && (
        <div className={styles.filtersContainer}>
          <div className={styles.filtersGrid}>
            <div className={styles.filterGroup}>
              <label className={styles.filterLabel}>الشركة</label>
              <select
                value={filters.companyId || userCompanyId}
                onChange={(e) => handleFiltersChange({ ...filters, companyId: Number(e.target.value) })}
                className={styles.filterSelect}
                disabled={loadingCompanies}
              >
                {loadingCompanies ? (
                  <option value="">جاري التحميل...</option>
                ) : (
                  companies.map((company) => (
                    <option key={company.id} value={company.id}>
                      {company.name}
                    </option>
                  ))
                )}
              </select>
            </div>
            
            <div className={styles.filterGroup}>
              <label className={styles.filterLabel}>من تاريخ</label>
              <input
                type="date"
                value={filters.startDate || ''}
                onChange={(e) => handleFiltersChange({ ...filters, startDate: e.target.value })}
                className={styles.filterInput}
              />
            </div>
            
            <div className={styles.filterGroup}>
              <label className={styles.filterLabel}>إلى تاريخ</label>
              <input
                type="date"
                value={filters.endDate || ''}
                onChange={(e) => handleFiltersChange({ ...filters, endDate: e.target.value })}
                className={styles.filterInput}
              />
            </div>
            
            <div className={styles.filterGroup}>
              <label className={styles.filterLabel}>الحالة</label>
              <select
                value={filters.status || ''}
                onChange={(e) => handleFiltersChange({ ...filters, status: e.target.value as any })}
                className={styles.filterSelect}
              >
                <option value="">جميع الحالات</option>
                <option value="open">مفتوح</option>
                <option value="in_progress">قيد المعالجة</option>
                <option value="closed">مغلق</option>
              </select>
            </div>
            
            <div className={styles.filterGroup}>
              <label className={styles.filterLabel}>البحث</label>
              <div className={styles.searchContainer}>
                <Search className={styles.searchIcon} />
                <input
                  type="text"
                  placeholder="البحث في الوصف أو اسم العميل..."
                  value={filters.searchTerm || ''}
                  onChange={(e) => handleFiltersChange({ ...filters, searchTerm: e.target.value })}
                  className={styles.searchInput}
                />
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Error Display */}
      {error && (
        <div className={styles.error}>
          <p>{error}</p>
          <button onClick={handleRefresh} className={styles.retryButton}>
            إعادة المحاولة
          </button>
        </div>
      )}

      {/* Table */}
      <div className={styles.tableContainer}>
        {isLoading ? (
          <div className={styles.loading}>
            <RefreshCw className={styles.spinning} />
            <p>جاري تحميل التقرير...</p>
          </div>
        ) : (
          <>
            <table className={styles.table}>
              <thead>
                <tr>
                  <th className={styles.checkboxColumn}>
                    <input
                      type="checkbox"
                      checked={selectAll}
                      onChange={handleSelectAll}
                      className={styles.selectAllCheckbox}
                    />
                  </th>
                  <th>رقم التذكرة</th>
                  <th>
                    <ColumnFilterDropdown 
                      column="status" 
                      title="الحالة" 
                      values={columnUniqueValues.status || []} 
                    />
                  </th>
                  <th>
                    <ColumnFilterDropdown 
                      column="customerName" 
                      title="العميل" 
                      values={columnUniqueValues.customerName || []} 
                    />
                  </th>
                  <th>
                    <ColumnFilterDropdown 
                      column="governorateName" 
                      title="المحافظة" 
                      values={columnUniqueValues.governorateName || []} 
                    />
                  </th>
                  <th>
                    <ColumnFilterDropdown 
                      column="cityName" 
                      title="المدينة" 
                      values={columnUniqueValues.cityName || []} 
                    />
                  </th>
                  <th>
                    <ColumnFilterDropdown 
                      column="categoryName" 
                      title="التصنيف" 
                      values={columnUniqueValues.categoryName || []} 
                    />
                  </th>
                  <th>المكالمات</th>
                  <th>العناصر</th>
                  <th>تاريخ الإنشاء</th>
                  <th>
                    <ColumnFilterDropdown 
                      column="companyName" 
                      title="الشركة" 
                      values={columnUniqueValues.companyName || []} 
                    />
                  </th>
                  <th>اسم المنتج</th>
                  <th>حجم المنتج</th>
                  <th>نوع الإجراء</th>
                  <th>التفتيش</th>
                  <th>المسحوب</th>
                  <th>المسلم</th>
                </tr>
              </thead>
              <tbody>
                {filteredTicketRows && filteredTicketRows.length > 0 ? (
                  filteredTicketRows.map((row, index) => {
                    // Get unique ticket IDs to determine group index for zebra striping
                    const uniqueTicketIds = [...new Set(filteredTicketRows.map(r => r.ticketId))];
                    const ticketGroupIndex = uniqueTicketIds.indexOf(row.ticketId);
                    const isEvenGroup = ticketGroupIndex % 2 === 0;
                    const groupClass = isEvenGroup ? styles.ticketGroupEven : styles.ticketGroupOdd;
                    
                    return (
                    <tr key={`${row.ticketId}-${row.itemId || 'no-item'}`} className={`${styles.tableRow} ${groupClass}`}>
                      <td className={styles.checkboxColumn}>
                        {row.isFirstItemRow && (
                          <input
                            type="checkbox"
                            checked={selectedTickets.has(row.ticket.id)}
                            onChange={() => handleSelectTicket(row.ticket.id)}
                            className={styles.ticketCheckbox}
                          />
                        )}
                      </td>
                      <td className={styles.ticketId}>
                        {row.isFirstItemRow ? `#${row.ticket.id}` : ''}
                      </td>
                      <td>
                        {row.isFirstItemRow && (
                          <div className={styles.statusContainer}>
                            {getStatusIcon(row.ticket.status)}
                            <span>{getStatusText(row.ticket.status)}</span>
                          </div>
                        )}
                      </td>
                      <td>{row.isFirstItemRow ? row.ticket.customerName : ''}</td>
                      <td>{row.isFirstItemRow ? row.ticket.governorateName : ''}</td>
                      <td>{row.isFirstItemRow ? row.ticket.cityName : ''}</td>
                      <td>{row.isFirstItemRow ? row.ticket.categoryName : ''}</td>
                      <td className={styles.count}>
                        {row.isFirstItemRow ? row.ticket.callsCount : ''}
                      </td>
                      <td className={styles.count}>
                        {row.isFirstItemRow ? row.ticket.itemsCount : ''}
                      </td>
                      <td>
                        {row.isFirstItemRow ? format(new Date(row.ticket.createdAt), 'yyyy-MM-dd') : ''}
                      </td>
                      <td>{row.isFirstItemRow ? row.ticket.companyName : ''}</td>
                      <td>{row.item?.productName || '-'}</td>
                      <td>{row.item?.productSize || '-'}</td>
                      <td>{row.item?.requestReasonName || row.item?.requestReasonDetail || 'لا يوجد'}</td>
                      <td style={{textAlign: 'center'}}>
                        {row.item?.inspected ? '✔' : '❌'}
                      </td>
                      <td style={{textAlign: 'center'}}>❌</td>
                      <td style={{textAlign: 'center'}}>❌</td>
                     </tr>
                    );
                   })
                 ) : (
                   <tr>
                     <td colSpan={16} className={styles.noData}>
                       لا توجد تذاكر متاحة
                     </td>
                   </tr>
                 )}
              </tbody>
            </table>

            {/* Pagination */}
            {reportData?.pagination && (
              <div className={styles.pagination}>
                <div className={styles.paginationInfo}>
                  عرض {filteredTicketRows.length > 0 ? 1 : 0} إلى {filteredTicketRows.length} من {filteredTicketRows.length} صف
                </div>
                
                <div className={styles.paginationControls}>
                  <button
                    onClick={() => handlePageChange(reportData.pagination.currentPage - 1)}
                    disabled={!reportData.pagination.hasPreviousPage}
                    className={styles.paginationButton}
                  >
                    <ChevronRight className={styles.paginationIcon} />
                  </button>
                  
                  <span className={styles.pageInfo}>
                    صفحة {reportData.pagination.currentPage} من {reportData.pagination.totalPages}
                  </span>
                  
                  <button
                    onClick={() => handlePageChange(reportData.pagination.currentPage + 1)}
                    disabled={!reportData.pagination.hasNextPage}
                    className={styles.paginationButton}
                  >
                    <ChevronLeft className={styles.paginationIcon} />
                  </button>
                </div>
                
                <div className={styles.itemsPerPageContainer}>
                  <label>عناصر لكل صفحة:</label>
                  <select
                    value={itemsPerPage}
                    onChange={(e) => setItemsPerPage(Number(e.target.value))}
                    className={styles.itemsPerPageSelect}
                  >
                    <option value={10}>10</option>
                    <option value={25}>25</option>
                    <option value={50}>50</option>
                    <option value={100}>100</option>
                  </select>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {/* Ticket Details Modal */}
      {selectedTicket && (
        <div className={styles.modal} onClick={() => setSelectedTicket(null)}>
          <div className={styles.modalContent} onClick={(e) => e.stopPropagation()}>
            <div className={styles.modalHeader}>
              <h2>تفاصيل التذكرة #{selectedTicket.id}</h2>
              <button
                onClick={() => setSelectedTicket(null)}
                className={styles.closeButton}
              >
                ×
              </button>
            </div>
            
            <div className={styles.modalBody}>
              <div className={styles.ticketDetails}>
                <div className={styles.detailRow}>
                  <strong>العميل:</strong> {selectedTicket.customerName}
                </div>
                <div className={styles.detailRow}>
                  <strong>الشركة:</strong> {selectedTicket.companyName}
                </div>
                <div className={styles.detailRow}>
                  <strong>المحافظة:</strong> {selectedTicket.governorateName}
                </div>
                <div className={styles.detailRow}>
                  <strong>المدينة:</strong> {selectedTicket.cityName}
                </div>
                <div className={styles.detailRow}>
                  <strong>الفئة:</strong> {selectedTicket.categoryName}
                </div>
                <div className={styles.detailRow}>
                  <strong>الوصف:</strong> {selectedTicket.description}
                </div>
                <div className={styles.detailRow}>
                  <strong>الحالة:</strong> {getStatusText(selectedTicket.status)}
                </div>
                <div className={styles.detailRow}>
                  <strong>الأولوية:</strong> {getPriorityText(selectedTicket.priority)}
                </div>
                <div className={styles.detailRow}>
                  <strong>أنشئ بواسطة:</strong> {selectedTicket.createdByName}
                </div>
                <div className={styles.detailRow}>
                  <strong>تاريخ الإنشاء:</strong> {format(new Date(selectedTicket.createdAt), 'yyyy-MM-dd HH:mm')}
                </div>
                {selectedTicket.closedAt && (
                  <div className={styles.detailRow}>
                    <strong>تاريخ الإغلاق:</strong> {format(new Date(selectedTicket.closedAt), 'yyyy-MM-dd HH:mm')}
                  </div>
                )}
                {selectedTicket.closingNotes && (
                  <div className={styles.detailRow}>
                    <strong>ملاحظات الإغلاق:</strong> {selectedTicket.closingNotes}
                  </div>
                )}
              </div>
              
              {selectedTicket.items && selectedTicket.items.length > 0 && (
                <div className={styles.itemsSection}>
                  <h3>عناصر التذكرة</h3>
                  <div className={styles.itemsList}>
                    {selectedTicket.items.map((item) => (
                      <div key={item.id} className={styles.itemCard}>
                        <div className={styles.itemHeader}>
                          <strong>{item.productName}</strong>
                          <span className={styles.itemSize}>({item.productSize})</span>
                        </div>
                        <div className={styles.itemDetails}>
                          <div>الكمية: {item.quantity}</div>
                          <div>تاريخ الشراء: {item.purchaseDate}</div>
                          <div>مكان الشراء: {item.purchaseLocation}</div>
                          <div>سبب الطلب: {item.requestReasonName}</div>
                          {item.inspected && (
                            <div className={styles.inspectionInfo}>
                              <div>تم الفحص: {item.inspectionDate}</div>
                              <div>نتيجة الفحص: {item.inspectionResult}</div>
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
        </>
      ) : (
        <div className={styles.masterDataSection}>
          <div className={styles.masterDataTabs}>
            <button
              className={`${styles.masterDataTab} ${activeMasterDataTab === 'users' ? styles.activeMasterDataTab : ''}`}
              onClick={() => setActiveMasterDataTab('users')}
            >
              <Users className={styles.tabIcon} />
              User Management
            </button>
          </div>
          
          <div className={styles.masterDataContent}>
            {activeMasterDataTab === 'users' && (
              <UserManagement />
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default TicketsReport;