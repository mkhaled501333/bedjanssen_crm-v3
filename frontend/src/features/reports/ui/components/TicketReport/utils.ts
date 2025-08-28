import { TicketItem, ColumnMapping } from './types';

export const columnMapping: ColumnMapping = {
  'ID': 'ticket_item_id',
  'Customer': 'customer_name',
  'Governorate': 'governorate_name',
  'City': 'city_name',
  'Ticket ID': 'ticket_id',
  'Category': 'ticket_category_name',
  'Status': 'ticket_status',
  'Product': 'product_name',
  'Size': 'product_size',
  'Request Reason': 'request_reason_name',
  'Inspected': 'inspected',
  'Inspection Date': 'inspection_date',
  'Client Approval': 'client_approval',
  'Action': 'action',
  'Pulled Status': 'pulled_status',
  'Delivered Status': 'delivered_status',
};

export const getColumnKey = (columnName: string): keyof TicketItem => {
  return columnMapping[columnName] || columnName.toLowerCase() as keyof TicketItem;
};

export const getUniqueValues = (data: TicketItem[], columnKey: keyof TicketItem): string[] => {
  const values = new Set<string>();
  data.forEach(row => {
    const value = row[columnKey];
    if (value !== null && value !== undefined && value !== '') {
      if (typeof value === 'boolean') {
        values.add(value ? 'Yes' : 'No');
      } else {
        values.add(String(value));
      }
    }
  });
  return Array.from(values).sort();
};

export const formatDate = (dateString: string | null): string => {
  if (!dateString) return '-';
  try {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-GB');
  } catch {
    return dateString;
  }
};

export const formatBoolean = (value: boolean | null): string => {
  if (value === null || value === undefined) return '-';
  return value ? 'Yes' : 'No';
};

export const formatStatus = (value: string | number | null): string => {
  if (value === null || value === undefined) return '-';
  
  // Convert to string and trim whitespace
  const stringValue = String(value).trim();
  
  // Handle numeric values
  if (stringValue === '0') return 'Open';
  if (stringValue === '1') return 'Closed';
  
  // Handle string values (case-insensitive)
  if (stringValue.toLowerCase() === 'open') return 'Open';
  if (stringValue.toLowerCase() === 'closed') return 'Closed';
  
  // Return original value if it doesn't match expected patterns
  return stringValue;
};

export const exportToCSV = (data: TicketItem[], filename: string = 'ticket-report-export.csv') => {
  const headers = [
    'Ticket ID', 'Status', 'Customer', 'Governorate', 'City', 'Category', 'Product',
    'Size', 'Request Reason', 'Inspected', 'Inspection Date',
    'Client Approval', 'Action', 'Pulled Status', 'Delivered Status'
  ];

  const csvContent = [
    headers.join(','),
    ...data.map(row => [
      row.ticket_id,
      `"${formatStatus(row.ticket_status)}"`,
      `"${row.customer_name}"`,
      `"${row.governorate_name}"`,
      `"${row.city_name}"`,
      `"${row.ticket_category_name}"`,
      `"${row.product_name}"`,
      `"${row.product_size}"`,
      `"${row.request_reason_name}"`,
      formatBoolean(row.inspected),
      formatDate(row.inspection_date),
      formatBoolean(row.client_approval),
      `"${row.action}"`,
      formatBoolean(row.pulled_status),
      formatBoolean(row.delivered_status)
    ].join(','))
  ].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);
  link.setAttribute('href', url);
  link.setAttribute('download', filename);
  link.style.visibility = 'hidden';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

export const getDisplayValue = (item: TicketItem, columnKey: keyof TicketItem): string => {
  const value = item[columnKey];
  
  if (value === null || value === undefined) return '-';
  
  switch (columnKey) {
    case 'inspection_date':
      return formatDate(value as string);
    case 'ticket_status':
      return formatStatus(value as string);
    case 'inspected':
    case 'client_approval':
    case 'pulled_status':
    case 'delivered_status':
      return formatBoolean(value as boolean);
    default:
      return String(value);
  }
};

export const getColumnDisplayName = (columnKey: keyof TicketItem): string => {
  const displayNames: Partial<Record<keyof TicketItem, string>> = {
    customer_id: 'Customer ID',
    customer_name: 'Customer',
    governomate_id: 'Governorate ID',
    governorate_name: 'Governorate',
    city_id: 'City ID',
    city_name: 'City',
    ticket_id: 'Ticket ID',
    company_id: 'Company ID',
    ticket_cat_id: 'Category ID',
    ticket_category_name: 'Category',
    ticket_status: 'Status',
    product_id: 'Product ID',
    product_name: 'Product',
    product_size: 'Size',
    request_reason_id: 'Request Reason ID',
    request_reason_name: 'Request Reason',
    inspected: 'Inspected',
    inspection_date: 'Inspection Date',
    client_approval: 'Client Approval',
    action: 'Action',
    pulled_status: 'Pulled Status',
    delivered_status: 'Delivered Status',
  };
  
  return displayNames[columnKey] || columnKey;
};
