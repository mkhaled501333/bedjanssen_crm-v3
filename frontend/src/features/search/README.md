# Search Feature

A simple search feature with auto-complete functionality, providing search capabilities with suggestions and loading states. **Now integrated with the Janssen CRM Backend for customer search functionality.**

## 🔗 Janssen CRM Integration

This search feature is now connected to the Janssen CRM backend API (`http://localhost:8081`) and provides:

- **Customer Search**: Search customers by name (Arabic/English) or phone number
- **Auto-Detection**: Automatically detects whether you're searching by name or phone
- **Real-time Results**: Live search results from the CRM database
- **Multilingual Support**: Full support for Arabic and English customer names

### Quick Setup

1. **Start the Janssen CRM Backend**:
   ```bash
   cd janssencrm-backend
   dart_frog dev
   ```

2. **Configure Environment** (optional):
   ```bash
   cp .env.local.example .env.local
   # Edit NEXT_PUBLIC_API_BASE_URL if needed
   ```

3. **Use the Search Component**:
   ```tsx
   import { SearchBar } from '@/features/search';
   
   <SearchBar
     placeholder="Search customers by name or phone..."
     onSearch={(query) => console.log('Found customers for:', query)}
   />
   ```

## Simple Structure

The search feature now uses a simplified structure:

```
search/
├── types.ts               # All types and interfaces
├── ui/                    # React components and hooks
│   ├── components/
│   │   ├── SearchBar.tsx
│   │   └── SearchBar.module.css
│   ├── hooks/
│   │   └── useSearch.ts   # Search logic hook
│   └── index.ts
├── index.ts               # Main exports
└── README.md
```

## Features

- **Search Input**: Clean search input with icon and clear button
- **Auto-complete Suggestions**: Dropdown with filtered suggestions
- **Loading States**: Beautiful shimmer loading animation
- **Keyboard Navigation**: Arrow keys, Enter, and Escape support
- **Add New Option**: Option to create new entries when no results found
- **Responsive Design**: Works well on all device sizes

## Usage

### Basic Usage

```tsx
import { SearchBar } from '@/features/search';

function MyComponent() {
  const handleSearch = (query: string) => {
    console.log('Searching for:', query);
  };

  const handleAddNew = (query: string) => {
    console.log('Adding new:', query);
  };

  return (
    <SearchBar
      placeholder="Search customers..."
      onSearch={handleSearch}
      onAddNew={handleAddNew}
      suggestions={[
        { id: '1', text: 'John Doe', type: 'contact' },
        { id: '2', text: 'Jane Smith', type: 'contact' }
      ]}
    />
  );
}
```

### Using the Hook Directly

```tsx
import { useSearch } from '@/features/search';

function CustomSearchComponent() {
  const {
    searchQuery,
    filteredSuggestions,
    showDropdown,
    selectedIndex,
    isSearching,
    handleInputChange,
    handleKeyDown,
    handleFocus,
    handleBlur,
    handleSuggestionClick,
    setSearchQuery
  } = useSearch({
    suggestions: [
      { id: '1', text: 'John Doe', category: 'Customer' },
      { id: '2', text: 'Jane Smith', category: 'Customer' }
    ],
    onSearch: (query) => console.log('Search:', query),
    onAddNew: (query) => console.log('Add new:', query)
  });

  return (
    <div>
      <input
        type="text"
        value={searchQuery}
        onChange={handleInputChange}
        onKeyDown={handleKeyDown}
        onFocus={handleFocus}
        onBlur={handleBlur}
        placeholder="Search..."
      />
      {/* Custom dropdown implementation */}
    </div>
  );
}
```

## Props

### SearchBar Props

```typescript
interface SearchBarProps {
  placeholder?: string;
  onSearch?: (query: string) => void;
  className?: string;
  suggestions?: SearchSuggestion[];
  showSuggestions?: boolean;
  maxSuggestions?: number;
  onAddNew?: (query: string) => void;
  showAddNewButton?: boolean;
}
```

### SearchSuggestion Type

```typescript
interface SearchSuggestion {
  id: string;
  text: string;
  category?: string;
  description?: string;
}
```

### useSearch Hook Props

```typescript
interface UseSearchProps {
  suggestions?: SearchSuggestion[];
  showSuggestions?: boolean;
  maxSuggestions?: number;
  onSearch?: (query: string) => void;
  onAddNew?: (query: string) => void;
}
```

## Styling

The search component uses CSS modules for styling. The main styles are in `SearchBar.module.css` and include:

- **Shimmer Animation**: Beautiful loading animation when searching
- **Dropdown Styles**: Clean dropdown with hover and selection states
- **Responsive Design**: Adapts to different screen sizes
- **Accessibility**: Proper focus states and keyboard navigation

## Customization

You can customize the search component by:

1. **Passing custom className**: Override default styles
2. **Providing custom suggestions**: Control what appears in the dropdown
3. **Implementing custom search logic**: Use the `onSearch` callback
4. **Adding custom styling**: Override CSS module classes

## Testing

The search feature includes comprehensive functionality:

- Input handling and validation
- Suggestion filtering and display
- Keyboard navigation
- Loading states and animations
- Error handling for edge cases

---

This simplified search feature provides all the essential functionality while being easy to understand and maintain.