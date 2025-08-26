# Tickets Report API Changes

The Tickets Report API has been updated to support multiple comma-separated values for the following filter parameters:

- `governorate`
- `city`
- `status`
- `productName`
- `companyName`
- `requestReasonName`

## Example

To filter by multiple governorates, you can pass a comma-separated list of governorate names to the `governorate` parameter:

```
GET http://localhost:8081/api/reports/tickets?companyId=1&governorate=الجيزة,الغربية&page=1&limit=15
```

This will return all tickets that belong to either of the specified governorates.

## Updated `tickets-api.http`

The `tickets-api.http` file has been updated to include examples of how to use the new multiple value filters.
