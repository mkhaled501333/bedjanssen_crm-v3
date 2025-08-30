import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => await _handleGet(context, id),
    HttpMethod.post => await _handlePost(context, id),
    HttpMethod.options => _handleOptions(),
    _ => Response(statusCode: 405, body: 'Method not allowed'),
  };
}

Response _handleOptions() {
  return Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

/// GET /api/customers/id/{id}/tickets - Get all tickets for a customer
Future<Response> _handleGet(RequestContext context, String id) async {
  try {
    // Validate customer ID
    final customerId = int.tryParse(id);
    if (customerId == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Invalid customer ID format',
          'error': 'Customer ID must be a valid integer'
        },
      );
    }
    
    // Get customer tickets
    final tickets = await _getCustomerTickets(customerId);
    
    return Response.json(
      body: {
        'success': true,
        'data': tickets,
        'message': 'Customer tickets retrieved successfully'
      },
    );
    
  } catch (e) {
    print('Get customer tickets error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while retrieving tickets',
        'error': e.toString()
      },
    );
  }
}

/// POST /api/customers/id/{id}/tickets - Create a new ticket for customer
Future<Response> _handlePost(RequestContext context, String id) async {
  try {
    // Validate customer ID
    final customerId = int.tryParse(id);
    if (customerId == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Invalid customer ID format',
          'error': 'Customer ID must be a valid integer'
        },
      );
    }
    
    final request = context.request;
    final body = await request.json() as Map<String, dynamic>;
    
    // Validate request body
    final validationError = _validateCreateTicketRequest(body);
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
    final customerExists = await _checkCustomerExists(customerId);
    if (!customerExists) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Customer not found',
          'error': 'No customer found with the provided ID'
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

    // Create ticket
    final ticketId = await DatabaseService.transaction<int>(() async {
      final result = await DatabaseService.query(
        '''
        INSERT INTO tickets (
          company_id, customer_id, ticket_cat_id, description, status, priority, created_by, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ''',
        parameters: [
          body['companyId'],
          customerId,
          body['ticketCatId'],
          body['description'] ?? '',
          body['status'] ?? 'open',
          body['priority'] ?? 'medium',
          userId,
        ],
        userId: userId,
      );
      
      return result.insertId!;
    });
    
    // Log activity for ticket creation (Activity ID: 210)
    try {
      await ActivityLogService.log(
        entityId: 2, // customers entity
        recordId: customerId,
        activityId: 109, // Create customer ticket
        userId: userId,
      );
    } catch (e) {
      print('Failed to log ticket creation activity: $e');
    }
    
    // Get the created ticket details
    final ticketData = await _getTicketDetails(ticketId);
    
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'data': ticketData,
        'message': 'Ticket created successfully'
      },
    );
    
  } catch (e) {
    print('Create ticket error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while creating ticket',
        'error': e.toString()
      },
    );
  }
}

String? _validateCreateTicketRequest(Map<String, dynamic> body) {
  if (body['companyId'] == null || body['companyId'] is! int) {
    return 'companyId is required and must be an integer';
  }
  
  if (body['ticketCatId'] == null || body['ticketCatId'] is! int) {
    return 'ticketCatId is required and must be an integer';
  }
  
  // Description is now optional
  if (body['description'] != null && (body['description'] is! String)) {
    return 'description must be a string if provided';
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

Future<List<Map<String, dynamic>>> _getCustomerTickets(int customerId) async {
  try {
    final ticketsResult = await DatabaseService.queryMany(
      '''
      SELECT t.*, tc.name AS ticket_cat_name
      FROM tickets t
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      WHERE t.customer_id = ?
      ORDER BY t.created_at DESC
      ''',
      parameters: [customerId],
    );
    
    final List<Map<String, dynamic>> ticketsWithItems = [];
    for (final ticket in ticketsResult) {
      final ticketId = ticket['id'];
      
      // Get ticket items
      final itemsResult = await DatabaseService.queryMany(
        '''
        SELECT ti.*, p.name AS product_brand, rr.name AS request_reason_name
        FROM ticket_items ti
        LEFT JOIN product_info p ON ti.product_id = p.id
        LEFT JOIN request_reasons rr ON ti.request_reason_id = rr.id
        WHERE ti.ticket_id = ?
        ORDER BY ti.created_at ASC
        ''',
        parameters: [ticketId],
      );
      
      // Get ticket calls
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
      
      ticketsWithItems.add({
        'ticketID': ticket['id'],
        'ticketCat': ticket['ticket_cat_name'],
        'description': ticket['description'],
        'status': ticket['status'],
        'priority': ticket['priority'],
        'closedAt': ticket['closed_at']?.toString(),
        'closingNotes': ticket['closing_notes'],
        'ticketItems': itemsResult.map((item) => {
          'id': item['id'],
          'productId': item['product_id'],
          'productBrand': item['product_brand'] ?? 'Unknown Product',
          'productName': item['product_name'] ?? 'Product ID: ${item['product_id']}',
          'productSize': item['product_size'],
          'quantity': item['quantity'],
          'purchaseDate': item['purchase_date']?.toString(),
          'purchaseLocation': item['purchase_location'],
          'requestReasonId': item['request_reason_id'],
          'requestReason': item['request_reason_name'] ?? 'Reason ID: ${item['request_reason_id']}',
          'requestReasonDetail': item['request_reason_detail'],
          'inspected': item['inspected'] == 1,
          'inspectionDate': item['inspection_date']?.toString(),
          'inspectionResult': item['inspection_result'],
          'clientApproval': item['client_approval'],
        }).toList(),
        'calls': callsResult.map((call) => {
          'id': call['id'],
          'callType': call['call_type'],
          'category': call['categoryName'],
          'description': call['description'],
          'notes': call['call_notes'],
          'callDuration': call['call_duration'],
          'createdBy': call['createdByName'],
          'createdAt': call['created_at']?.toString(),
        }).toList(),
        'createdAt': ticket['created_at']?.toString(),
        'updatedAt': ticket['updated_at']?.toString(),
      });
    }
    
    return ticketsWithItems;
  } catch (e) {
    print('Error getting customer tickets: $e');
    return [];
  }
}

Future<Map<String, dynamic>?> _getTicketDetails(int ticketId) async {
  try {
    final ticketResult = await DatabaseService.queryOne(
      '''
      SELECT t.*, tc.name AS ticket_cat_name
      FROM tickets t
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      WHERE t.id = ?
      ''',
      parameters: [ticketId],
    );
    
    if (ticketResult == null) {
      return null;
    }
    
    return {
      'ticketID': ticketResult['id'],
      'ticketCat': ticketResult['ticket_cat_name'],
      'description': ticketResult['description'],
      'status': ticketResult['status'],
      'priority': ticketResult['priority'],
      'closedAt': ticketResult['closed_at']?.toString(),
      'closingNotes': ticketResult['closing_notes'],
      'createdAt': ticketResult['created_at']?.toString(),
      'updatedAt': ticketResult['updated_at']?.toString(),
    };
  } catch (e) {
    print('Error getting ticket details: $e');
    return null;
  }
}