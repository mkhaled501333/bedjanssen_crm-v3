# API Troubleshooting Guide for Print Functionality

## Current Issue: HTTP 500 Error

The print functionality is currently experiencing a 500 Internal Server Error when calling the `/api/reports/ticket-items/by-ids` endpoint.

## Debugging Steps

### 1. Check Backend Server Status
- Ensure the Dart Frog backend server is running on port 8081
- Check if the server is accessible at `http://localhost:8081`

### 2. Verify API Endpoint
- Test the endpoint directly: `POST http://localhost:8081/api/reports/ticket-items/by-ids`
- Use the HTTP test file: `backend/routes/api/reports/ticket-items/by-ids/by-ids-api.http`

### 3. Check Database Connection
- Verify the backend can connect to the database
- Check if the required tables exist and are accessible

### 4. Authentication Issues
- Ensure the user is properly authenticated
- Check if the auth token is valid and not expired
- Verify the token format matches backend expectations

### 5. CORS Configuration
- Check if CORS is properly configured in the backend
- Verify the frontend origin is allowed

## Common Solutions

### Backend Not Running
```bash
# Start the backend server
cd backend
dart run build/bin/server.dart
```

### Database Connection Issues
- Check database credentials in `backend/lib/database/database_config.dart`
- Verify database server is running
- Check if required tables exist

### Authentication Token Issues
- Clear localStorage and re-login
- Check token expiration
- Verify token format

## Testing the API

### Using the HTTP Test File
1. Open `backend/routes/api/reports/ticket-items/by-ids/by-ids-api.http`
2. Update the `@authToken` variable with a valid token
3. Run the test requests

### Manual Testing with curl
```bash
curl -X POST http://localhost:8081/api/reports/ticket-items/by-ids \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"ticketIds": [5427]}'
```

## Expected Response Format

```json
{
  "success": true,
  "tickets": [
    {
      "id": 5427,
      "customerName": "Customer Name",
      "governorateName": "Governorate",
      "cityName": "City",
      "adress": "Address",
      "phones": ["Phone1", "Phone2"],
      "createdByName": "User Name",
      "items": [
        {
          "productName": "Product",
          "productSize": "Size",
          "quantity": 1,
          "purchaseDate": "2024-01-01",
          "purchaseLocation": "Location",
          "requestReasonName": "Reason"
        }
      ]
    }
  ]
}
```

## Error Response Examples

### 500 Internal Server Error
```json
{
  "success": false,
  "error": "Internal server error: [error details]"
}
```

### 400 Bad Request
```json
{
  "success": false,
  "error": "ticketIds is required and must not be empty"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "error": "Unauthorized"
}
```

## Next Steps

1. **Check Backend Logs**: Look for error messages in the backend console
2. **Test Database Queries**: Verify the SQL queries in the backend code
3. **Check Network Tab**: Use browser dev tools to see the actual request/response
4. **Verify Environment**: Ensure all required environment variables are set

## Fallback Solution

If the API continues to fail, the print functionality will show a fallback message with the selected ticket IDs, allowing users to manually process the tickets while the technical issue is resolved.
