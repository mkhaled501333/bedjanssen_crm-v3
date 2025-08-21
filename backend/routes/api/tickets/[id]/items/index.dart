import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';
import 'package:mysql1/mysql1.dart';

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

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => await _handleGet(context, id),
    HttpMethod.post => await _handlePost(context, id),
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

/// GET /api/tickets/{id}/items - Get all items for a ticket
Future<Response> _handleGet(RequestContext context, String id) async {
  try {
    final ticketId = int.tryParse(id);
    if (ticketId == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Invalid ticket ID format',
          'error': 'Ticket ID must be a valid integer'
        },
      );
    }

    final ticketExists = await _checkTicketExists(ticketId);
    if (!ticketExists) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Ticket not found',
          'error': 'No ticket found with the provided ID'
        },
      );
    }

    final results = await DatabaseService.query(
      '''
      SELECT ti.*, p.product_name as product_name, u.name AS createdByName
      FROM ticket_items ti
      LEFT JOIN product_info p ON ti.product_id = p.id
      LEFT JOIN users u ON ti.created_by = u.id
      WHERE ti.ticket_id = ?
      ORDER BY ti.created_at DESC
      ''',
      parameters: [ticketId],
    );

    final items = results.map((item) {
      final detail = item['request_reason_detail'];
      String? requestReasonDetailString;
      if (detail != null) {
        if (detail is Blob) {
          requestReasonDetailString = utf8.decode(detail.toBytes());
        } else {
          requestReasonDetailString = detail.toString();
        }
      } else {
        requestReasonDetailString = null;
      }

      return {
        'id': item['id'],
        'companyId': item['company_id'],
        'ticketId': item['ticket_id'],
        'productId': item['product_id'],
        'productName': item['product_name'],
        'quantity': item['quantity'],
        'createdBy': item['createdByName'],
        'createdAt': item['created_at']?.toString(),
        'updatedAt': item['updated_at']?.toString(),
        'productSize': item['product_size'],
        'purchaseDate': item['purchase_date']?.toString(),
        'purchaseLocation': item['purchase_location'],
        'requestReasonId': item['request_reason_id'],
        'requestReasonDetail': requestReasonDetailString,
      };
    }).toList();

    return Response.json(
      body: {
        'success': true,
        'data': items,
      },
    );
  } catch (e) {
    print('Get ticket items error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while fetching ticket items',
        'error': e.toString()
      },
    );
  }
}

/// POST /api/tickets/{id}/items - Add a new item to a ticket
Future<Response> _handlePost(RequestContext context, String id) async {
  try {
    // Validate ticket ID
    final ticketId = int.tryParse(id);
    if (ticketId == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Invalid ticket ID format',
          'error': 'Ticket ID must be a valid integer'
        },
      );
    }
    
    final request = context.request;
    final body = await request.json() as Map<String, dynamic>;
    
    // Validate request body
    final validationError = _validateAddItemRequest(body);
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
    
    // Check if ticket exists
    final ticketExists = await _checkTicketExists(ticketId);
    if (!ticketExists) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Ticket not found',
          'error': 'No ticket found with the provided ID'
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
    
    // Insert ticket item and get its details in one transaction
    final itemData = await DatabaseService.transaction<Map<String, dynamic>?>(() async {
      final insertResult = await DatabaseService.query(
        '''
        INSERT INTO ticket_items (
          company_id, ticket_id, product_id, quantity, created_by, created_at, updated_at,
          product_size, purchase_date, purchase_location, request_reason_id, request_reason_detail
        ) VALUES (?, ?, ?, ?, ?, NOW(), NOW(), ?, ?, ?, ?, ?)
        ''',
        parameters: [
          body['companyId'],
          ticketId,
          body['productId'],
          body['quantity'],
          userId,
          body['product_size']?.toString() ?? '',
          body['purchase_date'],
          body['purchase_location'],
          body['request_reason_id'],
          body['request_reason_detail'],
        ],
      );
      final itemId = insertResult.insertId;

      if (itemId == null) {
        return null;
      }

      final itemResult = await DatabaseService.queryOne(
        '''
        SELECT ti.*, p.product_name as product_name, u.name AS createdByName
        FROM ticket_items ti
        LEFT JOIN product_info p ON ti.product_id = p.id
        LEFT JOIN users u ON ti.created_by = u.id
        WHERE ti.id = ?
        ''',
        parameters: [itemId],
      );

      if (itemResult == null) {
        return null;
      }

      final detail = itemResult['request_reason_detail'];
      String? requestReasonDetailString;
      if (detail != null) {
        if (detail is Blob) {
          requestReasonDetailString = utf8.decode(detail.toBytes());
        } else {
          requestReasonDetailString = detail.toString();
        }
      } else {
        requestReasonDetailString = null;
      }

      return {
        'id': itemResult['id'],
        'companyId': itemResult['company_id'],
        'ticketId': itemResult['ticket_id'],
        'productId': itemResult['product_id'],
        'productName': itemResult['product_name'],
        'quantity': itemResult['quantity'],
        'createdBy': itemResult['createdByName'],
        'createdAt': itemResult['created_at']?.toString(),
        'updatedAt': itemResult['updated_at']?.toString(),
        'productSize': itemResult['product_size'],
        'purchaseDate': itemResult['purchase_date']?.toString(),
        'purchaseLocation': itemResult['purchase_location'],
        'requestReasonId': itemResult['request_reason_id'],
        'requestReasonDetail': requestReasonDetailString,
      };
    });

    if (itemData == null) {
      return Response.json(
        statusCode: 500,
        body: {
          'success': false,
          'message': 'Failed to retrieve ticket item details after creation',
          'error': 'The item was created but its details could not be fetched.'
        },
      );
    }
    
    // Log activity for adding item to ticket (Activity ID: 505)
    try {
      // Log to ticket_items entity
      await ActivityLogService.log(
        entityId: 4, // ticket_items entity
        recordId: itemData['id'] as int,
        activityId: 505, // Add item to ticket
        userId: userId,
      );
      
      // Also log to tickets entity for complete audit trail
      await ActivityLogService.log(
        entityId: 3, // tickets entity
        recordId: ticketId,
        activityId: 505, // Add item to ticket
        userId: userId,

      );
    } catch (e) {
      print('Failed to log item addition activity: $e');
    }
    
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'data': itemData,
        'message': 'Ticket item added successfully'
      },
    );
    
  } catch (e) {
    print('Add ticket item error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while adding ticket item',
        'error': e.toString()
      },
    );
  }
}

String? _validateAddItemRequest(Map<String, dynamic> body) {
  if (body['companyId'] == null || body['companyId'] is! int) {
    return 'companyId is required and must be an integer';
  }
  
  if (body['productId'] == null || body['productId'] is! int) {
    return 'productId is required and must be an integer';
  }
  
  if (body['quantity'] == null || (body['quantity'] is! int && body['quantity'] is! double)) {
    return 'quantity is required and must be a number';
  }
  
  return null;
}

Future<bool> _checkTicketExists(int ticketId) async {
  try {
    final result = await DatabaseService.queryOne(
      'SELECT id FROM tickets WHERE id = ?',
      parameters: [ticketId],
    );
    return result != null;
  } catch (e) {
    return false;
  }
}