import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';

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

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _handleGet(context),
    HttpMethod.options => _handleOptions(),
    _ => _addCorsHeaders(Response(statusCode: 405, body: 'Method not allowed')),
  };
}

Response _handleOptions() {
  return _addCorsHeaders(Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  ));
}

Future<Response> _handleGet(RequestContext context) async {
  try {
    final request = context.request;
    final uri = request.uri;
    
    // Get query parameters
    final query = uri.queryParameters['q']?.trim();
    final type = uri.queryParameters['type']?.toLowerCase();
    final limitParam = uri.queryParameters['limit'];
    
    // Validate required parameters
    if (query == null || query.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Query parameter "q" is required',
          'error': 'Missing required parameter'
        },
      );
    }
    
    // Parse limit with default value
    int limit = 10;
    if (limitParam != null) {
      final parsedLimit = int.tryParse(limitParam);
      if (parsedLimit != null && parsedLimit > 0 && parsedLimit <= 50) {
        limit = parsedLimit;
      }
    }
    
    // Determine search type if not specified
    String searchType = type ?? _detectSearchType(query);
    
    List<Map<String, dynamic>> customers;
    
    // Perform search based on type
    if (searchType == 'phone') {
      customers = await _searchCustomersByPhone(query, limit);
    } else {
      customers = await _searchCustomersByName(query, limit);
    }
    
    return Response.json(
      body: {
        'success': true,
        'data': {
          'customers': customers,
          'total': customers.length,
          'query': query,
          'type': searchType,
          'limit': limit,
        },
        'message': 'Search completed successfully'
      },
    );
    
  } catch (e) {
    print('Search customers error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred during search',
        'error': e.toString()
      },
    );
  }
}

/// Detect if query is a phone number or name
String _detectSearchType(String query) {
  // Check if query starts with digits (phone number pattern)
  final phonePattern = RegExp(r'^\d+');
  return phonePattern.hasMatch(query) ? 'phone' : 'name';
}

/// Search customers by name
Future<List<Map<String, dynamic>>> _searchCustomersByName(String name, int limit) async {
  // Sanitize and validate input parameters
  final sanitizedName = _sanitizeSearchInput(name);
  final validLimit = _validateLimit(limit);
  
  const sql = '''
    SELECT
      c.id as customerid,
      c.name,
      (SELECT phone FROM customer_phones WHERE customer_id = c.id LIMIT 1) as phone,
      comp.name as company_name
    FROM
      customers c
    LEFT JOIN
      companies comp ON c.company_id = comp.id
    WHERE
      c.name LIKE ?
    ORDER BY
      c.name
    LIMIT ?
  ''';
  
  final results = await DatabaseService.queryMany(
    sql,
    parameters: ['%$sanitizedName%', validLimit],
  );
  
  return results.map((row) {
    // Get all phone numbers for this customer
    return {
      'id': row['customerid'],
      'name': row['name'],
      'company': row['company_name'],
      'phones': row['phone'] != null ? [row['phone']] : <String>[],
    };
  }).toList();
}

/// Search customers by phone number
Future<List<Map<String, dynamic>>> _searchCustomersByPhone(String phone, int limit) async {
  // Sanitize and validate input parameters
  final sanitizedPhone = _sanitizePhoneInput(phone);
  final validLimit = _validateLimit(limit);
  
  const sql = '''
    SELECT
      c.id as customerid,
      c.name,
      p.phone,
      comp.name as company_name
    FROM
      customers c
    JOIN
      customer_phones p ON c.id = p.customer_id
    LEFT JOIN
      companies comp ON c.company_id = comp.id
    WHERE
      p.phone LIKE ?
    ORDER BY
      c.name
    LIMIT ?
  ''';
  
  final results = await DatabaseService.queryMany(
    sql,
    parameters: ['%$sanitizedPhone%', validLimit],
  );
  
  // Group results by customer to collect all phone numbers
  final Map<int, Map<String, dynamic>> customerMap = <int, Map<String, dynamic>>{};
  
  for (final row in results) {
    final customerId = row['customerid'] as int;
    
    if (customerMap[customerId] == null) {
      customerMap[customerId] = {
        'id': customerId,
        'name': row['name'],
        'company': row['company_name'],
        'phones': <String>[],
      };
    }
    
    // Add phone number if not already present
    final phoneNumber = row['phone'] as String?;
    final customerPhones = customerMap[customerId]!['phones'] as List<String>;
    if (phoneNumber != null && !customerPhones.contains(phoneNumber)) {
      customerPhones.add(phoneNumber);
    }
  }
  
  return customerMap.values.toList();
}


/// Sanitize search input to prevent encoding issues
String _sanitizeSearchInput(String input) {
  if (input.isEmpty) return input;
  
  // Remove potentially problematic characters that could cause buffer issues
  String sanitized = input
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '') // Remove control characters
      .replaceAll(RegExp(r'[\\%_]'), '') // Remove SQL wildcards that could cause issues
      .trim();
  
  // Limit length to prevent buffer overflow
  if (sanitized.length > 100) {
    sanitized = sanitized.substring(0, 100);
  }
  
  return sanitized;
}

/// Sanitize phone input
String _sanitizePhoneInput(String phone) {
  if (phone.isEmpty) return phone;
  
  // Keep only digits and common phone characters
  String sanitized = phone.replaceAll(RegExp(r'[^0-9+\-\s()]'), '');
  
  // Limit length
  if (sanitized.length > 20) {
    sanitized = sanitized.substring(0, 20);
  }
  
  return sanitized;
}

/// Validate and sanitize limit parameter
int _validateLimit(int limit) {
  if (limit < 1) return 1;
  if (limit > 50) return 50;
  return limit;
}