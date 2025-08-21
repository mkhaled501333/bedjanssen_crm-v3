import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';

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
    HttpMethod.post => await _handlePost(context),
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

/// POST /api/tickets - Create a new ticket with an associated call
Future<Response> _handlePost(RequestContext context) async {
  try {
    final request = context.request;
    final body = await request.json() as Map<String, dynamic>;
    
    // Validate request body
    final validationError = _validateCreateTicketWithCallRequest(body);
    if (validationError != null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': validationError,
          'error': 'Validation failed'
        },
      );
    }
    
    // Check if customer exists
    final customerExists = await _checkCustomerExists(body['customerId'] as int);
    if (!customerExists) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Customer not found',
          'error': 'No customer found with the provided customer ID'
        },
      );
    }
    
    // Check if ticket category exists
    final ticketCatExists = await _checkTicketCategoryExists(body['ticketCatId'] as int);
    if (!ticketCatExists) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Ticket category not found',
          'error': 'No ticket category found with the provided ID'
        },
      );
    }
    
    // Check if call category exists
    final callCatExists = await _checkCallCategoryExists(body['call']['callCatId'] as int);
    if (!callCatExists) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Call category not found',
          'error': 'No call category found with the provided ID'
        },
      );
    }
    
    // Extract user ID from JWT payload
    int userId = 1; // Default fallback
    try {
      final jwtPayload = context.read<dynamic>();
      if (jwtPayload is Map<String, dynamic>) {
        userId = jwtPayload['id'] as int? ?? 1;
      }
    } catch (e) {
      print('Failed to extract user ID from JWT payload: $e');
    }
    
    // Create ticket, call, and item in a transaction
    final Map<String, dynamic> result = await DatabaseService.transaction<Map<String, dynamic>>(() async {
      // First, create the ticket
      final statusMap = {'open': 0, 'closed': 1};
      final priorityMap = {'low': 0, 'medium': 1, 'high': 2};

      final ticketResult = await DatabaseService.query(
        '''
        INSERT INTO tickets (
          company_id, customer_id, ticket_cat_id, description, status, priority, created_by, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ''',
        parameters: [
          body['companyId'],
          body['customerId'],
          body['ticketCatId'],
          body['description'] ?? '',
          statusMap[body['status']?.toString().toLowerCase() ?? 'open'] ?? 0,
          priorityMap[body['priority']?.toString().toLowerCase() ?? 'medium'] ?? 1,
          userId,
        ],
      );
      
      final ticketId = ticketResult.insertId!;
      
      // Then, create the associated call
      final callData = body['call'] as Map<String, dynamic>;
      final callType = (callData['callType'] as String).toLowerCase() == 'incoming' ? 0 : 1;

      final callResult = await DatabaseService.query(
        '''
        INSERT INTO ticketcall (
          company_id, ticket_id, call_type, call_cat_id, description, call_notes,
          call_duration, created_by, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ''',
        parameters: [
          body['companyId'],
          ticketId,
          callType,
          callData['callCatId'],
          callData['description'] ?? '',
          callData['callNotes'] ?? '',
          callData['callDuration'] ?? 0,
          userId,
        ],
      );
      
      final callId = callResult.insertId!;

      // Finally, create the associated item
      final itemData = body['item'] as Map<String, dynamic>;
      
      final itemResult = await DatabaseService.query(
        '''
        INSERT INTO ticket_items (
          company_id, ticket_id, product_id, quantity, product_size, purchase_date, purchase_location, request_reason_id, request_reason_detail, created_by, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ''',
        parameters: [
            body['companyId'],
            ticketId,
            itemData['productId'],
            itemData['quantity'],
            itemData['productSize']?.toString() ?? '',
            itemData['purchaseDate'],
            itemData['purchaseLocation'],
            itemData['requestReasonId'],
            itemData['requestReasonDetail'],
            userId,
        ],
      );
      
      return {
        'ticketId': ticketId,
        'callId': callId,
        'itemId': itemResult.insertId!,
      };
    });
    
    // Log activity for ticket creation (Activity ID: 500)
    try {
      await ActivityLogService.log(
        entityId: 3, // tickets entity
        recordId: result['ticketId'] as int,
        activityId: 500, // Create ticket with call and item
        userId: userId,
      );
    } catch (e) {
      print('Failed to log ticket creation activity: $e');
    }
    
    // Get the complete ticket details with the call and item
    final ticketData = await _getTicketDetailsWithCallAndItem(result['ticketId'] as int);
    
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'data': ticketData,
        'message': 'Ticket with call and item created successfully'
      },
    );
    
  } catch (e) {
    print('Create ticket with call and item error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while creating ticket with call and item',
        'error': e.toString()
      },
    );
  }
}

String? _validateCreateTicketWithCallRequest(Map<String, dynamic> body) {
  // Validate ticket fields
  if (body['companyId'] == null || body['companyId'] is! int) {
    return 'companyId is required and must be an integer';
  }
  
  if (body['customerId'] == null || body['customerId'] is! int) {
    return 'customerId is required and must be an integer';
  }
  
  if (body['ticketCatId'] == null || body['ticketCatId'] is! int) {
    return 'ticketCatId is required and must be an integer';
  }
  
  // Description is now optional
  if (body['description'] != null && (body['description'] is! String)) {
    return 'description must be a string if provided';
  }
  
  // Validate call fields
  if (body['call'] == null || body['call'] is! Map<String, dynamic>) {
    return 'call is required and must be an object';
  }
  
  final call = body['call'] as Map<String, dynamic>;
  
  if (call['callType'] == null || call['callType'] is! String || !['incoming', 'outgoing'].contains((call['callType'] as String).toLowerCase())) {
    return 'call.callType is required and must be "incoming" or "outgoing"';
  }
  
  if (call['callCatId'] == null || call['callCatId'] is! int) {
    return 'call.callCatId is required and must be an integer';
  }
  
  if (call['description'] != null && call['description'] is! String) {
    return 'call.description must be a string if provided';
  }
  
  // Validate item fields
  if (body['item'] == null || body['item'] is! Map<String, dynamic>) {
    return 'item is required and must be an object';
  }

  final item = body['item'] as Map<String, dynamic>;

  if (item['quantity'] == null || (item['quantity'] is! int && item['quantity'] is! double)) {
    return 'item.quantity is required and must be a number';
  }

  if (item['productId'] == null || item['productId'] is! int) {
    return 'item.productId is required and must be an integer';
  }

  // Product size is now optional and can be string or number
  if (item['productSize'] != null && (item['productSize'] is! String && item['productSize'] is! int && item['productSize'] is! double)) {
    return 'item.productSize must be a string or number if provided';
  }

  if (item['purchaseDate'] == null || item['purchaseDate'] is! String) {
    return 'item.purchaseDate is required and must be a string (YYYY-MM-DD)';
  }

  if (item['purchaseLocation'] == null || item['purchaseLocation'] is! String) {
    return 'item.purchaseLocation is required and must be a string';
  }

  if (item['requestReasonId'] == null || item['requestReasonId'] is! int) {
    return 'item.requestReasonId is required and must be an integer';
  }

  if (item['requestReasonDetail'] == null || item['requestReasonDetail'] is! String) {
    return 'item.requestReasonDetail is required and must be a string';
  }

  return null;
}

Future<bool> _checkCustomerExists(int customerId) async {
  try {
    final result = await DatabaseService.queryOne(
      'SELECT id FROM customers WHERE id = ?',
      parameters: [customerId],
    );
    return result != null;
  } catch (e) {
    return false;
  }
}

Future<bool> _checkTicketCategoryExists(int ticketCatId) async {
  try {
    final result = await DatabaseService.queryOne(
      'SELECT id FROM ticket_categories WHERE id = ?',
      parameters: [ticketCatId],
    );
    return result != null;
  } catch (e) {
    return false;
  }
}

Future<bool> _checkCallCategoryExists(int callCatId) async {
  try {
    final result = await DatabaseService.queryOne(
      'SELECT id FROM call_categories WHERE id = ?',
      parameters: [callCatId],
    );
    return result != null;
  } catch (e) {
    return false;
  }
}


Future<Map<String, dynamic>?> _getTicketDetailsWithCallAndItem(int ticketId) async {
  try {
    // Get ticket details
    final ticketResult = await DatabaseService.queryOne(
      '''
      SELECT t.*, tc.name AS ticket_cat_name, c.name AS customer_name
      FROM tickets t
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE t.id = ?
      ''',
      parameters: [ticketId],
    );
    
    if (ticketResult == null) {
      return null;
    }
    
    // Get associated calls
    final callsResult = await DatabaseService.queryMany(
      '''
      SELECT tc.*, cat.name AS categoryName, u.name AS createdByName
      FROM ticketcall tc
      LEFT JOIN users u ON tc.created_by = u.id
      LEFT JOIN call_categories cat ON tc.call_cat_id = cat.id
      WHERE tc.ticket_id = ?
      ORDER BY tc.created_at DESC
      ''',
      parameters: [ticketId],
    );

    // Get associated items
    final itemsResult = await DatabaseService.queryMany(
      '''
      SELECT ti.*, u.name AS createdByName, p.product_name, rr.name as request_reason_name
      FROM ticket_items ti
      LEFT JOIN users u ON ti.created_by = u.id
      LEFT JOIN product_info p ON ti.product_id = p.id
      LEFT JOIN request_reasons rr ON ti.request_reason_id = rr.id
      WHERE ti.ticket_id = ?
      ORDER BY ti.created_at ASC
      ''',
      parameters: [ticketId],
    );

    const statusMap = {0: 'open', 1: 'in progress', 2: 'closed'};
    const priorityMap = {0: 'low', 1: 'medium', 2: 'high'};
    
    return {
      'ticketID': ticketResult['id'],
      'companyId': ticketResult['company_id'],
      'customerId': ticketResult['customer_id'],
      'customerName': _blobToString(ticketResult['customer_name']),
      'ticketCatId': ticketResult['ticket_cat_id'],
      'ticketCat': _blobToString(ticketResult['ticket_cat_name']),
      'description': _blobToString(ticketResult['description']),
      'status': statusMap[ticketResult['status']] ?? 'unknown',
      'priority': priorityMap[ticketResult['priority']] ?? 'unknown',
      'closedAt': ticketResult['closed_at']?.toString(),
      'closingNotes': _blobToString(ticketResult['closing_notes']),
      'createdAt': ticketResult['created_at']?.toString(),
      'updatedAt': ticketResult['updated_at']?.toString(),
      'calls': callsResult.map((call) => {
        'id': call['id'],
        'callType': call['call_type'] == 0 ? 'incoming' : 'outgoing',
        'callCatId': call['call_cat_id'],
        'category': _blobToString(call['categoryName']),
        'description': _blobToString(call['description']),
        'callNotes': _blobToString(call['call_notes']),
        'callDuration': call['call_duration'],
        'createdBy': _blobToString(call['createdByName']),
        'createdAt': call['created_at']?.toString(),
        'updatedAt': call['updated_at']?.toString(),
      }).toList(),
      'items': itemsResult.map((item) => {
        'id': item['id'],
        'productId': item['product_id'],
        'productName': _blobToString(item['product_name']),
        'productSize': _blobToString(item['product_size']),
        'quantity': item['quantity'],
        'purchaseDate': item['purchase_date']?.toString(),
        'purchaseLocation': _blobToString(item['purchase_location']),
        'requestReason': _blobToString(item['request_reason_name']),
        'requestReasonDetail': _blobToString(item['request_reason_detail']),
        'createdBy': _blobToString(item['createdByName']),
        'createdAt': item['created_at']?.toString(),
        'updatedAt': item['updated_at']?.toString(),
      }).toList(),
    };
  } catch (e) {
    print('Error getting ticket details with call and item: $e');
    return null;
  }
}

String _blobToString(dynamic blob) {
  if (blob == null) {
    return '';
  }
  if (blob is String) {
    return blob;
  }
  if (blob is List<int>) {
    return String.fromCharCodes(blob);
  }
  return blob.toString();
}

