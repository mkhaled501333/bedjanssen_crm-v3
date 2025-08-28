# Troubleshooting Guide for TicketReport 404 Error

## Common Causes and Solutions

### 1. Backend Server Not Running

**Problem**: Getting "HTTP error! status: 404" when trying to access the API.

**Solution**: Make sure your backend server is running.

```bash
# Navigate to backend directory
cd backend

# Start the Dart Frog server
dart_frog dev
```

**Expected Output**:
```
✓ Running on http://localhost:8081
```

### 2. Wrong API Endpoint

**Problem**: The API endpoint `/api/reports/ticket-items` doesn't exist.

**Solution**: Verify the correct endpoint in your backend:

```bash
# Check if the endpoint exists
curl -X POST http://localhost:8081/api/reports/ticket-items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"filters": {"companyId": 1}, "page": 1, "limit": 10}'
```

### 3. Authentication Token Missing

**Problem**: No authentication token or invalid token.

**Solution**: Make sure you're logged in and have a valid token:

```javascript
// Check if token exists
console.log('Token:', localStorage.getItem('token'));

// If no token, redirect to login
if (!localStorage.getItem('token')) {
  window.location.href = '/auth/login';
}
```

### 4. CORS Configuration

**Problem**: CORS errors preventing API calls.

**Solution**: Check your backend CORS configuration in `backend/routes/_middleware.dart`:

```dart
Response _addCorsHeaders(Response response) {
  return response.copyWith(
    headers: {
      ...response.headers,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}
```

### 5. Port Configuration Mismatch

**Problem**: Frontend trying to connect to wrong port.

**Solution**: Verify the API base URL configuration:

```typescript
// In shared/utils/index.ts
export function getApiBaseUrl(): string {
  if (typeof window !== 'undefined' && window.location.hostname !== 'localhost') {
    return `http://${window.location.hostname}:8081`;
  }
  return 'http://localhost:8081';
}
```

## Debugging Steps

### Step 1: Check Backend Status

1. Open terminal and navigate to backend directory
2. Run `dart_frog dev`
3. Verify server starts on port 8081

### Step 2: Test API Endpoint

1. Open browser console
2. Click the "🔧 Test API" button in the TicketReport component
3. Check console for detailed error information

### Step 3: Verify Authentication

1. Check if you're logged in
2. Verify token exists in localStorage
3. Check token validity

### Step 4: Check Network Tab

1. Open browser DevTools
2. Go to Network tab
3. Try to load the TicketReport component
4. Look for failed requests and error details

## Quick Fixes

### Fix 1: Restart Backend Server

```bash
# Stop current server (Ctrl+C)
# Then restart
cd backend
dart_frog dev
```

### Fix 2: Clear Browser Cache

```javascript
// In browser console
localStorage.clear();
sessionStorage.clear();
// Then refresh page and login again
```

### Fix 3: Check Docker Services

If using Docker:

```bash
# Check if backend container is running
docker ps | grep janssencrm-backend

# Restart backend container
docker restart janssencrm-backend
```

## Expected API Response

When the API is working correctly, you should see:

```json
{
  "success": true,
  "data": {
    "available_filters": { ... },
    "applied_filters": { ... },
    "filter_summary": { ... },
    "report_data": {
      "ticket_items": [ ... ],
      "pagination": { ... }
    }
  }
}
```

## Still Having Issues?

1. **Check backend logs** for any error messages
2. **Verify database connection** is working
3. **Check if migrations** have been run
4. **Verify the API route** exists in your backend code
5. **Test with a simple endpoint** like `/api/auth/login` first

## Contact Support

If none of the above solutions work:
1. Check the backend console for error messages
2. Verify the exact error response from the API
3. Check if other API endpoints in your project are working
