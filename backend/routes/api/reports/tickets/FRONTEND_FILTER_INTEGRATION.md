# Frontend Filter Integration Guide

This document explains how to integrate the tickets report API filters in your frontend application, utilizing the new filter structure that includes both IDs and names.

## Filter Structure

The `available_filters` object in the API response now provides each filter option with both an `id` and a `name`:

```json
{
  "available_filters": {
    "governorates": [
      {"id": 1, "name": "الجيزة"},
      {"id": 2, "name": "الغربية"},
      {"id": 3, "name": "الشرقيه"}
    ],
    "cities": [
      {"id": 1, "name": "بلبيس"},
      {"id": 2, "name": "الزقازيق"}
    ],
    "categories": [
      {"id": 1, "name": "Category A"},
      {"id": 2, "name": "Category B"}
    ],
    "statuses": [
      {"id": 0, "name": "open"},
      {"id": 1, "name": "in_progress"},
      {"id": 2, "name": "closed"}
    ]
  }
}
```

## Frontend Implementation Examples

### React/TypeScript Example

```typescript
interface FilterOption {
  id: number;
  name: string;
}

interface AvailableFilters {
  governorates: FilterOption[];
  cities: FilterOption[];
  categories: FilterOption[];
  statuses: FilterOption[];
  productNames: FilterOption[];
  companyNames: FilterOption[];
  requestReasonNames: FilterOption[];
}

// State for selected filters
const [selectedFilters, setSelectedFilters] = useState({
  governorateIds: [] as number[],
  cityIds: [] as number[],
  categoryIds: [] as number[],
  statusIds: [] as number[],
  productIds: [] as number[],
  companyIds: [] as number[],
  requestReasonIds: [] as number[],
});

// Function to build API query parameters
const buildQueryParams = () => {
  const params = new URLSearchParams();
  
  if (selectedFilters.governorateIds.length > 0) {
    params.append('governorate', selectedFilters.governorateIds.join(','));
  }
  
  if (selectedFilters.cityIds.length > 0) {
    params.append('city', selectedFilters.cityIds.join(','));
  }
  
  if (selectedFilters.categoryIds.length > 0) {
    params.append('categoryId', selectedFilters.categoryIds.join(','));
  }
  
  // Add other filters...
  
  return params.toString();
};

// Filter component example
const FilterDropdown = ({ 
  options, 
  selectedIds, 
  onChange, 
  placeholder 
}: {
  options: FilterOption[];
  selectedIds: number[];
  onChange: (ids: number[]) => void;
  placeholder: string;
}) => {
  return (
    <select
      multiple
      value={selectedIds}
      onChange={(e) => {
        const selectedOptions = Array.from(e.target.selectedOptions, option => 
          parseInt(option.value)
        );
        onChange(selectedOptions);
      }}
    >
      <option value="">{placeholder}</option>
      {options.map(option => (
        <option key={option.id} value={option.id}>
          {option.name}
        </option>
      ))}
    </select>
  );
};
```

### Vue.js Example

```vue
<template>
  <div class="filters">
    <select 
      v-model="selectedGovernorateIds" 
      multiple 
      @change="updateFilters"
    >
      <option 
        v-for="option in availableFilters.governorates" 
        :key="option.id" 
        :value="option.id"
      >
        {{ option.name }}
      </option>
    </select>
    
    <select 
      v-model="selectedCityIds" 
      multiple 
      @change="updateFilters"
    >
      <option 
        v-for="option in availableFilters.cities" 
        :key="option.id" 
        :value="option.id"
      >
        {{ option.name }}
      </option>
    </select>
  </div>
</template>

<script>
export default {
  data() {
    return {
      availableFilters: {
        governorates: [],
        cities: [],
        categories: [],
        statuses: [],
        productNames: [],
        companyNames: [],
        requestReasonNames: []
      },
      selectedGovernorateIds: [],
      selectedCityIds: [],
      // ... other selected filters
    };
  },
  
  methods: {
    async fetchTickets() {
      const params = new URLSearchParams();
      
      if (this.selectedGovernorateIds.length > 0) {
        params.append('governorate', this.selectedGovernorateIds.join(','));
      }
      
      if (this.selectedCityIds.length > 0) {
        params.append('city', this.selectedCityIds.join(','));
      }
      
      // Add other filters...
      
      const response = await fetch(`/api/reports/tickets?${params.toString()}`);
      const data = await response.json();
      
      // Update available filters for cascading dropdowns
      this.availableFilters = data.available_filters;
    },
    
    updateFilters() {
      this.fetchTickets();
    }
  }
};
</script>
```

### Angular Example

```typescript
// filter.model.ts
export interface FilterOption {
  id: number;
  name: string;
}

export interface AvailableFilters {
  governorates: FilterOption[];
  cities: FilterOption[];
  categories: FilterOption[];
  statuses: FilterOption[];
  productNames: FilterOption[];
  companyNames: FilterOption[];
  requestReasonNames: FilterOption[];
}

// tickets.service.ts
@Injectable({
  providedIn: 'root'
})
export class TicketsService {
  private apiUrl = '/api/reports/tickets';
  
  getTickets(filters: any): Observable<any> {
    const params = new HttpParams()
      .set('companyId', filters.companyId)
      .set('page', filters.page)
      .set('limit', filters.limit);
    
    if (filters.governorateIds?.length) {
      params.set('governorate', filters.governorateIds.join(','));
    }
    
    if (filters.cityIds?.length) {
      params.set('city', filters.cityIds.join(','));
    }
    
    // Add other filters...
    
    return this.http.get<any>(this.apiUrl, { params });
  }
}

// tickets.component.ts
@Component({
  selector: 'app-tickets',
  template: `
    <div class="filters">
      <mat-select 
        [(ngModel)]="selectedGovernorateIds" 
        multiple 
        (selectionChange)="onFilterChange()"
        placeholder="Select Governorates"
      >
        <mat-option 
          *ngFor="let option of availableFilters.governorates" 
          [value]="option.id"
        >
          {{ option.name }}
        </mat-option>
      </mat-select>
    </div>
  `
})
export class TicketsComponent {
  availableFilters: AvailableFilters = {
    governorates: [],
    cities: [],
    categories: [],
    statuses: [],
    productNames: [],
    companyNames: [],
    requestReasonNames: []
  };
  
  selectedGovernorateIds: number[] = [];
  selectedCityIds: number[] = [];
  
  constructor(private ticketsService: TicketsService) {}
  
  onFilterChange() {
    this.loadTickets();
  }
  
  loadTickets() {
    const filters = {
      companyId: 1,
      page: 1,
      limit: 10,
      governorateIds: this.selectedGovernorateIds,
      cityIds: this.selectedCityIds
    };
    
    this.ticketsService.getTickets(filters).subscribe(data => {
      this.availableFilters = data.available_filters;
      // Update tickets list...
    });
  }
}
```

## Benefits of the New Structure

1. **Efficient Filtering**: Use IDs for database queries and API calls
2. **User-Friendly Display**: Show names in the UI for better user experience
3. **Cascading Dropdowns**: Implement dependent filters (e.g., cities based on selected governorate)
4. **Performance**: Avoid string comparisons in favor of integer ID comparisons
5. **Consistency**: Maintain referential integrity between frontend and backend

## Best Practices

1. **Store IDs in State**: Keep selected filter IDs in your component state
2. **Display Names in UI**: Use the name field for display purposes
3. **Send IDs to API**: Always send the ID values when making API calls
4. **Handle Empty States**: Check for empty arrays before rendering filter options
5. **Update Available Filters**: Refresh available filter options after applying filters to enable cascading behavior

## Migration from Old Structure

If you were previously using the old filter structure (arrays of strings), update your code to:

1. Change filter state from string arrays to number arrays
2. Update filter change handlers to work with IDs
3. Modify API parameter building to use IDs instead of names
4. Update filter option rendering to use the new object structure
