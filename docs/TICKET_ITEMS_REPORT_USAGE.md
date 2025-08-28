# Ticket Items Report View - Dynamic Filtering Guide

## Overview

The `ticket_items_report` view provides a comprehensive report of all ticket items with their associated customer, ticket, and product information. This guide focuses on **dynamic filtering** where available filter options automatically update based on currently applied filters, ensuring users only see relevant choices.

**Key Feature**: The API now returns **everything in a single response** - available filters, applied filters, filter summary, AND the actual report data with pagination. This eliminates the need for multiple API calls and provides a more efficient user experience.

## Dynamic Filtering Concept

Dynamic filtering means that when a user applies a filter, the available options for other filters automatically update to show only values that exist in the filtered dataset. This prevents users from selecting filter combinations that would return empty results.

### Example of Dynamic Filtering
1. **Initial State**: All filter options are available
2. **User selects Company A**: Available filters update to show only data related to Company A
3. **User selects Governorate X**: Available cities, customers, products, etc. update to show only those in Governorate X
4. **Result**: Users can only select valid filter combinations

## View Structure

The view combines data from multiple tables:
- `ticket_items` - Core ticket item information
- `tickets` - Ticket details and status
- `customers` - Customer information and location
- `governorates` & `cities` - Geographic data
- `product_info` - Product details
- `request_reasons` - Request reason information
- `ticket_item_change_*` tables - Action tracking (replacement, maintenance)

## Available Fields

| Field | Type | Description |
|-------|------|-------------|
| `customer_id` | INT | Customer identifier |
| `customer_name` | VARCHAR | Customer name |
| `governomate_id` | INT | Governorate identifier |
| `governorate_name` | VARCHAR | Governorate name |
| `city_id` | INT | City identifier |
| `city_name` | VARCHAR | City name |
| `ticket_id` | INT | Ticket identifier |
| `company_id` | INT | Company identifier |
| `ticket_cat_id` | INT | Ticket category identifier |
| `ticket_category_name` | VARCHAR | Ticket category name |
| `ticket_status` | VARCHAR | Ticket status |
| `ticket_item_id` | INT | Ticket item identifier |
| `product_id` | INT | Product identifier |
| `product_name` | VARCHAR | Product name |
| `product_size` | VARCHAR | Product size |
| `request_reason_id` | INT | Request reason identifier |
| `request_reason_name` | VARCHAR | Request reason name |
| `inspected` | BOOLEAN | Whether item was inspected |
| `inspection_date` | DATETIME | Date of inspection |
| `client_approval` | BOOLEAN | Client approval status |
| `action` | VARCHAR | Action type: 'استبدال لنفس النوع', 'استبدال لنوع اخر', 'صيانه' |
| `pulled_status` | BOOLEAN | Whether item was pulled |
| `delivered_status` | BOOLEAN | Whether item was delivered |

## Dynamic Filter Implementation

### 1. Get Available Filters Service

```dart
class TicketItemsReportService {
  /// Get available filter options, applied filters, AND report data in one response
  static Future<Map<String, dynamic>> getTicketItemsReport({
    required int companyId,
    List<int>? customerIds,
    List<int>? governomateIds,
    List<int>? cityIds,
    List<int>? ticketIds,
    List<int>? companyIds,
    List<int>? ticketCatIds,
    String? ticketStatus,
    List<int>? productIds,
    List<int>? requestReasonIds,
    bool? inspected,
    DateTime? inspectionDateFrom,
    DateTime? inspectionDateTo,
    String? action,
    bool? pulledStatus,
    bool? deliveredStatus,
    bool? clientApproval,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // Build base WHERE clause for the current filter state
      final whereConditions = <String>['company_id = ?'];
      final parameters = <dynamic>[companyId];

      // Add currently applied filters to WHERE clause
      if (customerIds != null && customerIds.isNotEmpty) {
        whereConditions.add('customer_id = ANY(?)');
        parameters.add(customerIds);
      }
      if (governomateIds != null && governomateIds.isNotEmpty) {
        whereConditions.add('governomate_id = ANY(?)');
        parameters.add(governomateIds);
      }
      if (cityIds != null && cityIds.isNotEmpty) {
        whereConditions.add('city_id = ANY(?)');
        parameters.add(cityIds);
      }
      if (ticketIds != null && ticketIds.isNotEmpty) {
        whereConditions.add('ticket_id = ANY(?)');
        parameters.add(ticketIds);
      }
      if (ticketCatIds != null && ticketCatIds.isNotEmpty) {
        whereConditions.add('ticket_cat_id = ANY(?)');
        parameters.add(ticketCatIds);
      }
      if (ticketStatus != null) {
        whereConditions.add('ticket_status = ?');
        parameters.add(ticketStatus);
      }
      if (productIds != null && productIds.isNotEmpty) {
        whereConditions.add('product_id = ANY(?)');
        parameters.add(productIds);
      }
      if (requestReasonIds != null && requestReasonIds.isNotEmpty) {
        whereConditions.add('request_reason_id = ANY(?)');
        parameters.add(requestReasonIds);
      }
      if (inspected != null) {
        whereConditions.add('inspected = ?');
        parameters.add(inspected);
      }
      if (inspectionDateFrom != null) {
        whereConditions.add('inspection_date >= ?');
        parameters.add(inspectionDateFrom);
      }
      if (inspectionDateTo != null) {
        whereConditions.add('inspection_date <= ?');
        parameters.add(inspectionDateTo);
      }
      if (action != null) {
        whereConditions.add('action = ?');
        parameters.add(action);
      }
      if (pulledStatus != null) {
        whereConditions.add('pulled_status = ?');
        parameters.add(pulledStatus);
      }
      if (deliveredStatus != null) {
        whereConditions.add('delivered_status = ?');
        parameters.add(deliveredStatus);
      }
      if (clientApproval != null) {
        whereConditions.add('client_approval = ?');
        parameters.add(clientApproval);
      }

      final whereClause = whereConditions.join(' AND ');

      // Get total count for pagination
      final countQuery = '''
        SELECT COUNT(*) as total
        FROM ticket_items_report
        WHERE $whereClause
      ''';
      
      final countResult = await DatabaseService.query(countQuery, parameters: parameters);
      final total = countResult.first['total'] as int;

      // Get paginated report data
      final offset = (page - 1) * limit;
      final dataQuery = '''
        SELECT *
        FROM ticket_items_report
        WHERE $whereClause
        ORDER BY ticket_id DESC, ticket_item_id DESC
        LIMIT ? OFFSET ?
      ''';
      
      final dataParameters = [...parameters, limit, offset];
      final reportData = await DatabaseService.query(dataQuery, parameters: dataParameters);

      // Get available filter options from the filtered dataset
      final availableFilters = <String, List<Map<String, dynamic>>>{};

      // Get available customers
      availableFilters['customers'] = await _getDistinctValues(
        'customer_id',
        'customer_name',
        'customers',
        whereClause,
        parameters,
      );

      // Get available governorates
      availableFilters['governorates'] = await _getDistinctValues(
        'governomate_id',
        'governorate_name',
        'governorates',
        whereClause,
        parameters,
      );

      // Get available cities
      availableFilters['cities'] = await _getDistinctValues(
        'city_id',
        'city_name',
        'cities',
        whereClause,
        parameters,
      );

      // Get available tickets
      availableFilters['tickets'] = await _getDistinctValues(
        'ticket_id',
        'ticket_id',
        'tickets',
        whereClause,
        parameters,
      );

      // Get available ticket categories
      availableFilters['ticket_categories'] = await _getDistinctValues(
        'ticket_cat_id',
        'ticket_category_name',
        'ticket_categories',
        whereClause,
        parameters,
      );

      // Get available ticket statuses
      availableFilters['ticket_statuses'] = await _getDistinctValues(
        'ticket_status',
        'ticket_status',
        'ticket_statuses',
        whereClause,
        parameters,
      );

      // Get available products
      availableFilters['products'] = await _getDistinctValues(
        'product_id',
        'product_name',
        'products',
        whereClause,
        parameters,
      );

      // Get available request reasons
      availableFilters['request_reasons'] = await _getDistinctValues(
        'request_reason_id',
        'request_reason_name',
        'request_reasons',
        whereClause,
        parameters,
      );

      // Get available actions
      availableFilters['actions'] = await _getDistinctValues(
        'action',
        'action',
        'actions',
        whereClause,
        parameters,
      );

      // Build applied filters object with current values
      final appliedFilters = <String, dynamic>{
        'companyId': companyId,
        'customerIds': customerIds,
        'governomateIds': governomateIds,
        'cityIds': cityIds,
        'ticketIds': ticketIds,
        'companyIds': companyIds,
        'ticketCatIds': ticketCatIds,
        'ticketStatus': ticketStatus,
        'productIds': productIds,
        'requestReasonIds': requestReasonIds,
        'inspected': inspected,
        'inspectionDateFrom': inspectionDateFrom?.toIso8601String(),
        'inspectionDateTo': inspectionDateTo?.toIso8601String(),
        'action': action,
        'pulledStatus': pulledStatus,
        'deliveredStatus': deliveredStatus,
        'clientApproval': clientApproval,
      };

      // Remove null/empty values for cleaner response
      appliedFilters.removeWhere((key, value) => 
        value == null || 
        (value is List && value.isEmpty) ||
        (value is String && value.isEmpty)
      );

      return {
        'success': true,
        'data': {
          'available_filters': availableFilters,
          'applied_filters': appliedFilters,
          'filter_summary': {
            'total_applied_filters': appliedFilters.length - 1, // Exclude companyId
            'active_filters': appliedFilters.keys.where((key) => key != 'companyId').toList(),
          },
          'report_data': {
            'ticket_items': reportData,
            'pagination': {
              'page': page,
              'limit': limit,
              'total': total,
              'total_pages': (total / limit).ceil(),
              'has_next': page < (total / limit).ceil(),
              'has_previous': page > 1,
            }
          }
        }
      };
    } catch (e) {
      print('Error getting ticket items report: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Helper method to get distinct values for a specific column
  static Future<List<Map<String, dynamic>>> _getDistinctValues(
    String idColumn,
    String nameColumn,
    String tableAlias,
    String whereClause,
    List<dynamic> parameters,
  ) async {
    try {
      final query = '''
        SELECT DISTINCT $idColumn as id, $nameColumn as name
        FROM ticket_items_report
        WHERE $whereClause
        AND $idColumn IS NOT NULL
        AND $nameColumn IS NOT NULL
        ORDER BY $nameColumn
      ''';

      final result = await DatabaseService.query(query, parameters: parameters);
      
      return result.map((row) => {
        'id': row['id'],
        'name': row['name'],
      }).where((item) => 
        item['name'] != null && 
        item['name'].toString().isNotEmpty
      ).toList();
    } catch (e) {
      print('Error getting distinct values for $tableAlias: $e');
      return [];
    }
  }
}
```

### 2. API Endpoint for Complete Ticket Items Report

```dart
@Post('/ticket-items-report')
Future<Map<String, dynamic>> getTicketItemsReport(
  @Body() Map<String, dynamic> request,
) async {
  try {
    final filters = request['filters'] as Map<String, dynamic>;
    final page = request['page'] ?? 1;
    final limit = request['limit'] ?? 50;
    
    final result = await TicketItemsReportService.getTicketItemsReport(
      companyId: filters['companyId'],
      customerIds: filters['customerIds']?.cast<int>(),
      governomateIds: filters['governomateIds']?.cast<int>(),
      cityIds: filters['cityIds']?.cast<int>(),
      ticketIds: filters['ticketIds']?.cast<int>(),
      companyIds: filters['companyIds']?.cast<int>(),
      ticketCatIds: filters['ticketCatIds']?.cast<int>(),
      ticketStatus: filters['ticketStatus'],
      productIds: filters['productIds']?.cast<int>(),
      requestReasonIds: filters['requestReasonIds']?.cast<int>(),
      inspected: filters['inspected'],
      inspectionDateFrom: filters['inspectionDateFrom'] != null 
        ? DateTime.parse(filters['inspectionDateFrom']) 
        : null,
      inspectionDateTo: filters['inspectionDateTo'] != null 
        ? DateTime.parse(filters['inspectionDateTo']) 
        : null,
      action: filters['action'],
      pulledStatus: filters['pulledStatus'],
      deliveredStatus: filters['deliveredStatus'],
      clientApproval: filters['clientApproval'],
      page: page,
      limit: limit,
    );

    return result;
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
```

## Complete Response Structure

The API now returns everything in a single response:

```json
{
  "success": true,
  "data": {
    "available_filters": {
      "customers": [...],
      "governorates": [...],
      "cities": [...],
      "tickets": [...],
      "ticket_categories": [...],
      "ticket_statuses": [...],
      "products": [...],
      "request_reasons": [...],
      "actions": [...]
    },
    "applied_filters": {
      "companyId": 1,
      "governomateIds": [1],
      "cityIds": [1]
    },
    "filter_summary": {
      "total_applied_filters": 2,
      "active_filters": ["governomateIds", "cityIds"]
    },
    "report_data": {
      "ticket_items": [
        {
          "ticket_item_id": 1,
          "customer_name": "Customer A",
          "governorate_name": "Governorate X",
          "city_name": "City A",
          "product_name": "Product X",
          "action": "صيانه",
          "ticket_status": "مفتوح",
          "inspected": true,
          "inspection_date": "2024-01-15T10:00:00Z",
          "pulled_status": false,
          "delivered_status": true,
          "client_approval": true
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 50,
        "total": 150,
        "total_pages": 3,
        "has_next": true,
        "has_previous": false
      }
    }
  }
}
```

## Dynamic Filter Examples

### Example 1: Company-Based Filtering

**Initial State (No filters applied):**
```json
{
  "success": true,
  "data": {
    "available_filters": {
      "customers": [
        {"id": 1, "name": "Customer A"},
        {"id": 2, "name": "Customer B"},
        {"id": 3, "name": "Customer C"}
      ],
      "governorates": [
        {"id": 1, "name": "Governorate X"},
        {"id": 2, "name": "Governorate Y"}
      ],
      "cities": [
        {"id": 1, "name": "City A"},
        {"id": 2, "name": "City B"},
        {"id": 3, "name": "City C"}
      ]
    },
    "applied_filters": {
      "companyId": 1
    },
    "filter_summary": {
      "total_applied_filters": 0,
      "active_filters": []
    },
    "report_data": {
      "ticket_items": [
        {
          "ticket_item_id": 1,
          "customer_name": "Customer A",
          "product_name": "Product X",
          "action": "صيانه",
          "ticket_status": "مفتوح"
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 50,
        "total": 150,
        "total_pages": 3,
        "has_next": true,
        "has_previous": false
      }
    }
  }
}
```

**After applying Company filter:**
```json
{
  "available_filters": {
    "customers": [
      {"id": 1, "name": "Customer A"},
      {"id": 2, "name": "Customer B"}
    ],
    "governorates": [
      {"id": 1, "name": "Governorate X"}
    ],
    "cities": [
      {"id": 1, "name": "City A"},
      {"id": 2, "name": "City B"}
    ]
  },
  "applied_filters": {
    "companyId": 1
  },
  "filter_summary": {
    "total_applied_filters": 0,
    "active_filters": []
  }
}
```

### Example 2: Geographic Filtering

**After applying Governorate filter:**
```json
{
  "available_filters": {
    "customers": [
      {"id": 1, "name": "Customer A"},
      {"id": 2, "name": "Customer B"}
    ],
    "cities": [
      {"id": 1, "name": "City A"},
      {"id": 2, "name": "City B"}
    ],
    "products": [
      {"id": 10, "name": "Product X"},
      {"id": 20, "name": "Product Y"}
    ]
  },
  "applied_filters": {
    "companyId": 1,
    "governomateIds": [1]
  },
  "filter_summary": {
    "total_applied_filters": 1,
    "active_filters": ["governomateIds"]
  }
}
```

**After applying City filter:**
```json
{
  "available_filters": {
    "customers": [
      {"id": 1, "name": "Customer A"}
    ],
    "products": [
      {"id": 10, "name": "Product X"}
    ],
    "ticket_categories": [
      {"id": 1, "name": "Category A"}
    ]
  },
  "applied_filters": {
    "companyId": 1,
    "governomateIds": [1],
    "cityIds": [1]
  },
  "filter_summary": {
    "total_applied_filters": 2,
    "active_filters": ["governomateIds", "cityIds"]
  }
}
```

### Example 3: Action-Based Filtering

**After applying Action filter:**
```json
{
  "available_filters": {
    "customers": [
      {"id": 1, "name": "Customer A"},
      {"id": 3, "name": "Customer C"}
    ],
    "products": [
      {"id": 15, "name": "Product Z"},
      {"id": 25, "name": "Product W"}
    ],
    "request_reasons": [
      {"id": 5, "name": "Maintenance Required"},
      {"id": 6, "name": "Preventive Maintenance"}
    ]
  },
  "applied_filters": {
    "companyId": 1,
    "action": "صيانه"
  },
  "filter_summary": {
    "total_applied_filters": 1,
    "active_filters": ["action"]
  }
}
```

## Frontend Implementation

### React/TypeScript Hook

```typescript
interface FilterOption {
  id: number;
  name: string;
}

interface AvailableFilters {
  governorates: FilterOption[];
  cities: FilterOption[];
  ticket_categories: FilterOption[];
  ticket_statuses: FilterOption[];
  products: FilterOption[];
  request_reasons: FilterOption[];
  actions: FilterOption[];
}

interface AppliedFilters {
  companyId: number;
  customerIds?: number[];
  governomateIds?: number[];
  cityIds?: number[];
  ticketIds?: number[];
  ticketCatIds?: number[];
  ticketStatus?: string;
  productIds?: number[];
  requestReasonIds?: number[];
  inspected?: boolean;
  inspectionDateFrom?: string;
  inspectionDateTo?: string;
  action?: string;
  pulledStatus?: boolean;
  deliveredStatus?: boolean;
  clientApproval?: boolean;
}

interface FilterSummary {
  total_applied_filters: number;
  active_filters: string[];
}

const useDynamicFilters = () => {
  const [appliedFilters, setAppliedFilters] = useState<AppliedFilters>({
    companyId: 1,
  });
  const [availableFilters, setAvailableFilters] = useState<AvailableFilters>({
    governorates: [],
    cities: [],
    ticket_categories: [],
    ticket_statuses: [],
    products: [],
    request_reasons: [],
    actions: [],
  });
  const [filterSummary, setFilterSummary] = useState<FilterSummary>({
    total_applied_filters: 0,
    active_filters: [],
  });

  // Fetch available filters, applied filters, and report data in one call
  const updateFilters = useCallback(async () => {
    try {
      const response = await fetch('/api/ticket-items-report', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
          filters: appliedFilters,
          page: 1,
          limit: 50
        }),
      });
      
      const data = await response.json();
      if (data.success) {
        setAvailableFilters(data.data.available_filters);
        setAppliedFilters(data.data.applied_filters);
        setFilterSummary(data.data.filter_summary);
        // You can also set report data here if needed
        // setReportData(data.data.report_data);
      }
    } catch (error) {
      console.error('Error updating filters:', error);
    }
  }, [appliedFilters]);

  // Update filters when applied filters change
  useEffect(() => {
    updateFilters();
  }, [updateFilters]);

  // Apply a filter and update available options
  const applyFilter = useCallback((filterKey: keyof AppliedFilters, value: any) => {
    setAppliedFilters(prev => ({
      ...prev,
      [filterKey]: value,
    }));
  }, []);

  // Clear a specific filter
  const clearFilter = useCallback((filterKey: keyof AppliedFilters) => {
    setAppliedFilters(prev => {
      const newFilters = { ...prev };
      delete newFilters[filterKey];
      return newFilters;
    });
  }, []);

  // Clear all filters
  const clearAllFilters = useCallback(() => {
    setAppliedFilters({ companyId: 1 });
  }, []);

  return {
    appliedFilters,
    availableFilters,
    filterSummary,
    applyFilter,
    clearFilter,
    clearAllFilters,
  };
};
```

### Filter Display Component

```typescript
const FilterDisplay: React.FC<{
  appliedFilters: AppliedFilters;
  filterSummary: FilterSummary;
  onClearFilter: (key: keyof AppliedFilters) => void;
  onClearAll: () => void;
}> = ({ appliedFilters, filterSummary, onClearFilter, onClearAll }) => {
  const getFilterDisplayName = (key: string, value: any): string => {
    switch (key) {
      case 'governomateIds':
        return `Governorate: ${value.join(', ')}`;
      case 'cityIds':
        return `City: ${value.join(', ')}`;
      case 'customerIds':
        return `Customer: ${value.join(', ')}`;
      case 'action':
        return `Action: ${value}`;
      case 'inspected':
        return `Inspected: ${value ? 'Yes' : 'No'}`;
      default:
        return `${key}: ${value}`;
    }
  };

  return (
    <div className="filter-display">
      <div className="filter-header">
        <h4>Applied Filters ({filterSummary.total_applied_filters})</h4>
        {filterSummary.total_applied_filters > 0 && (
          <button onClick={onClearAll} className="clear-all-btn">
            Clear All
          </button>
        )}
      </div>
      
      <div className="active-filters">
        {filterSummary.active_filters.map(filterKey => {
          const value = appliedFilters[filterKey as keyof AppliedFilters];
          if (!value) return null;
          
          return (
            <div key={filterKey} className="filter-tag">
              <span>{getFilterDisplayName(filterKey, value)}</span>
              <button 
                onClick={() => onClearFilter(filterKey as keyof AppliedFilters)}
                className="remove-filter-btn"
              >
                ×
              </button>
            </div>
          );
        })}
      </div>
      
      {filterSummary.total_applied_filters === 0 && (
        <p className="no-filters">No filters applied</p>
      )}
    </div>
  );
};
```

### Filter Component

```typescript
interface FilterDropdownProps {
  label: string;
  options: FilterOption[];
  selectedValues: number[];
  onSelectionChange: (values: number[]) => void;
  multiple?: boolean;
}

const FilterDropdown: React.FC<FilterDropdownProps> = ({
  label,
  options,
  selectedValues,
  onSelectionChange,
  multiple = true,
}) => {
  return (
    <div className="filter-dropdown">
      <label className="filter-label">{label}</label>
      <select
        multiple={multiple}
        value={multiple ? selectedValues.map(String) : [selectedValues[0]?.toString() || '']}
        onChange={(e) => {
          if (multiple) {
            const values = Array.from(e.target.selectedOptions, option => Number(option.value));
            onSelectionChange(values);
          } else {
            const value = Number(e.target.value);
            onSelectionChange(value ? [value] : []);
          }
        }}
      >
        <option value="">Select {label}</option>
        {options.map(option => (
          <option key={option.id} value={option.id}>
            {option.name}
          </option>
        ))}
      </select>
    </div>
  );
};
```

### Main Report Component

```typescript
const TicketItemsReport: React.FC = () => {
  const {
    appliedFilters,
    availableFilters,
    filterSummary,
    applyFilter,
    clearFilter,
    clearAllFilters,
  } = useDynamicFilters();

  return (
    <div className="ticket-items-report">
      <div className="filters-section">
        <h3>Filters</h3>
        
        {/* Company Filter (Always available) */}
        <FilterDropdown
          label="Company"
          options={[{ id: 1, name: "Company A" }]}
          selectedValues={[appliedFilters.companyId]}
          onSelectionChange={(values) => applyFilter('companyId', values[0])}
          multiple={false}
        />

        {/* Governorate Filter */}
        <FilterDropdown
          label="Governorate"
          options={availableFilters.governorates}
          selectedValues={appliedFilters.governomateIds || []}
          onSelectionChange={(values) => applyFilter('governomateIds', values)}
        />

        {/* City Filter (depends on governorate) */}
        <FilterDropdown
          label="City"
          options={availableFilters.cities}
          selectedValues={appliedFilters.cityIds || []}
          onSelectionChange={(values) => applyFilter('cityIds', values)}
        />

        {/* Action Filter */}
        <FilterDropdown
          label="Action"
          options={availableFilters.actions}
          selectedValues={appliedFilters.action ? [appliedFilters.action] : []}
          onSelectionChange={(values) => applyFilter('action', values[0])}
          multiple={false}
        />
      </div>

      {/* Display Applied Filters */}
      <FilterDisplay
        appliedFilters={appliedFilters}
        filterSummary={filterSummary}
        onClearFilter={clearFilter}
        onClearAll={clearAllFilters}
      />

      <div className="report-section">
        <h3>Report Results</h3>
        {/* Report content based on applied filters */}
      </div>
    </div>
  );
};
```

## Dynamic Filter Logic Flow

### 1. Filter Dependency Chain

```
Company → Governorate → City → Customer
    ↓
Product ← Request Reason ← Action
    ↓
Ticket Category ← Ticket Status
```

### 2. Filter Update Rules

- **Company**: Always available, affects all other filters
- **Governorate**: Depends on company, affects cities and customers
- **City**: Depends on governorate, affects customers and tickets
- **Customer**: Depends on location filters, affects tickets and products
- **Action**: Depends on company, affects products and request reasons
- **Product**: Depends on company and action, affects tickets
- **Ticket Category**: Depends on company and location, affects tickets

### 3. Boolean Status Filters

The following boolean filters provide status-based filtering:

- **inspected**: Filter by inspection status (true/false)
- **pulledStatus**: Filter by pulled status (true/false)  
- **deliveredStatus**: Filter by delivered status (true/false)
- **clientApproval**: Filter by client approval status (true/false)

These filters can be combined with other filters to create precise status-based queries. For example:
- `inspected: true, clientApproval: true` - Show only inspected and approved items
- `pulledStatus: false, deliveredStatus: false` - Show items that haven't been pulled or delivered

### 4. Performance Optimization

```sql
-- Use composite indexes for common filter combinations
CREATE INDEX idx_ticket_items_company_location ON ticket_items(company_id, governomate_id, city_id);
CREATE INDEX idx_ticket_items_company_action ON ticket_items(company_id, action);
CREATE INDEX idx_ticket_items_company_product ON ticket_items(company_id, product_id);

-- Use covering indexes for filter queries
CREATE INDEX idx_ticket_items_filter_covering ON ticket_items(
  company_id, governomate_id, city_id, action, product_id, 
  customer_id, ticket_id, inspected, pulled_status, delivered_status
);
```

## Best Practices

### 1. Filter Order
- Start with broad filters (company, governorate)
- Progress to specific filters (city, customer)
- End with detailed filters (action, product)

### 2. User Experience
- Show loading states while updating filters
- Provide clear feedback when filters return no results
- Allow users to clear individual filters
- Remember user's last filter combination

### 3. Performance
- Debounce filter changes (300-500ms delay)
- Cache filter results for common combinations
- Use pagination for large result sets
- Implement virtual scrolling for long lists

### 4. Error Handling
- Handle network errors gracefully
- Provide fallback filter options
- Log filter usage for optimization
- Validate filter combinations before API calls

## Troubleshooting

### Common Issues

1. **Empty Filter Options**: Check if base filters are too restrictive
2. **Slow Filter Updates**: Optimize database indexes and queries
3. **Filter State Mismatch**: Ensure frontend and backend filter state synchronization
4. **Memory Issues**: Implement proper cleanup for filter change listeners

### Debug Queries

```sql
-- Check available filters for specific company
SELECT DISTINCT governomate_id, governorate_name 
FROM ticket_items_report 
WHERE company_id = 1;

-- Check filter dependencies
SELECT DISTINCT city_id, city_name 
FROM ticket_items_report 
WHERE company_id = 1 AND governomate_id = 1;

-- Verify filter combinations
SELECT COUNT(*) 
FROM ticket_items_report 
WHERE company_id = 1 
  AND governomate_id = 1 
  AND city_id = 1;
```

## Migration Notes

The dynamic filtering system requires:

1. **Database Indexes**: Automatically created during migrations
2. **View Optimization**: The `ticket_items_report` view with proper joins
3. **Service Layer**: `TicketItemsReportService` with comprehensive filter and data logic
4. **API Endpoints**: Single endpoint `/ticket-items-report` that returns everything
5. **Frontend State Management**: Proper filter state management and updates
6. **Pagination Support**: Built-in pagination for large datasets

## Support

For issues with dynamic filtering:
1. Check database indexes are properly created
2. Verify view structure and joins
3. Test filter combinations return expected results
4. Monitor API performance and response times
5. Review frontend filter state management
