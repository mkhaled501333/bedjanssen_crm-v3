# Search API Activities

This document lists all the activities available in the search API routes with their corresponding activity names.

## Customer Search Routes (`/api/search/customers`)

### Search Customers by Name
- **Route**: `GET /api/search/customers?q={query}&type=name`
- **Activity Name**: Search customers by name
- **Description**: Searches for customers by their name using partial matching
- **Parameters**:
  - `q` (required): Search query string
  - `type` (optional): Search type, defaults to auto-detection
  - `limit` (optional): Maximum number of results (1-50, default: 10)

### Search Customers by Phone
- **Route**: `GET /api/search/customers?q={query}&type=phone`
- **Activity Name**: Search customers by phone
- **Description**: Searches for customers by their phone number using partial matching
- **Parameters**:
  - `q` (required): Phone number search query
  - `type` (optional): Search type, defaults to auto-detection
  - `limit` (optional): Maximum number of results (1-50, default: 10)

### Auto-detect Search Type
- **Route**: `GET /api/search/customers?q={query}`
- **Activity Name**: Auto-detect customer search
- **Description**: Automatically detects whether the query is a phone number or name and performs the appropriate search
- **Parameters**:
  - `q` (required): Search query string
  - `limit` (optional): Maximum number of results (1-50, default: 10)

## Summary of All Activities

1. Search customers by name
2. Search customers by phone
3. Auto-detect customer search

---

**Note**: All search endpoints support CORS and return results with customer details including ID, name, company, and associated phone numbers.