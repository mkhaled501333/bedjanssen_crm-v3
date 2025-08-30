import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';
import 'package:mysql1/mysql1.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.put => await _handlePut(context, id),
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

/// PUT /api/tickets/{id}/category - Update ticket category
Future<Response> _handlePut(RequestContext context, String id) async {
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
    final validationError = _validateUpdateCategoryRequest(body);
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
    
    // Check if category exists
    final categoryExists = await _checkCategoryExists(body['ticketCatId'] as int);
    if (!categoryExists) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Invalid category',
          'error': 'The specified ticket category does not exist'
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
    
    // Update ticket category
    await DatabaseService.query(
      '''
      UPDATE tickets 
      SET ticket_cat_id = ?, updated_at = NOW()
      WHERE id = ?
      ''',
      parameters: [
        body['ticketCatId'],
        ticketId,
      ],
      userId: userId,
    );
    
    // Log activity for ticket category update (Activity ID: 502)
    try {
      await ActivityLogService.log(
        entityId: 3, // tickets entity
        recordId: ticketId,
        activityId: 502, // Update ticket category
        userId: userId,
      );
    } catch (e) {
      print('Failed to log ticket category update activity: $e');
    }
    
    // Get updated ticket details
    final ticketData = await _getTicketDetails(ticketId);
    
    return Response.json(
      body: {
        'success': true,
        'data': ticketData,
        'message': 'Ticket category updated successfully'
      },
    );
    
  } catch (e) {
    print('Update ticket category error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while updating ticket category',
        'error': e.toString()
      },
    );
  }
}

String? _validateUpdateCategoryRequest(Map<String, dynamic> body) {
  if (body['ticketCatId'] == null || body['ticketCatId'] is! int) {
    return 'ticketCatId is required and must be an integer';
  }
  
  return null;
}

Future<bool> _checkTicketExists(int ticketId) async {
  try {
    final result = await DatabaseService.queryOne(
      'SELECT id FROM tickets WHERE id = ?',
      parameters: [ticketId],
      userId: 1, // System user for read operations
    );
    return result != null;
  } catch (e) {
    return false;
  }
}

Future<bool> _checkCategoryExists(int categoryId) async {
  try {
    final result = await DatabaseService.queryOne(
      'SELECT id FROM ticket_categories WHERE id = ?',
      parameters: [categoryId],
      userId: 1, // System user for read operations
    );
    return result != null;
  } catch (e) {
    return false;
  }
}

Future<Map<String, dynamic>?> _getTicketDetails(int ticketId) async {
  try {
    final ticketResult = await DatabaseService.queryOne(
      '''
      SELECT 
        t.id, t.ticket_cat_id, t.description, t.status, t.priority,
        t.closed_at, t.closing_notes, t.created_at, t.updated_at,
        tc.name AS ticket_cat_name
      FROM tickets t
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      WHERE t.id = ?
      ''',
      parameters: [ticketId],
      userId: 1, // System user for read operations
    );
    
    if (ticketResult == null) {
      return null;
    }

    final description = ticketResult['description'];
    final closingNotes = ticketResult['closing_notes'];
    
    return {
      'id': ticketResult['id'],
      'ticket_cat_id': ticketResult['ticket_cat_id'],
      'ticket_cat_name': ticketResult['ticket_cat_name'],
      'description': description is Blob ? utf8.decode(description.toBytes()) : description,
      'status': ticketResult['status'],
      'priority': ticketResult['priority'],
      'closed_at': ticketResult['closed_at']?.toString(),
      'closing_notes': closingNotes is Blob ? utf8.decode(closingNotes.toBytes()) : closingNotes,
      'created_at': ticketResult['created_at']?.toString(),
      'updated_at': ticketResult['updated_at']?.toString(),
    };
  } catch (e) {
    print('Error getting ticket details: $e');
    return null;
  }
}