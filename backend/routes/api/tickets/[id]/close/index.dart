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

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.put => await _handlePut(context, id),
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

/// PUT /api/tickets/{id}/close - Close a ticket
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
    final validationError = _validateCloseTicketRequest(body);
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
    
    // Check if ticket exists and is not already closed
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
    
    // Close the ticket
    await DatabaseService.query(
      '''
      UPDATE tickets 
      SET status = 1, closed_at = NOW(), closing_notes = ?, closed_by = ?, updated_at = NOW()
      WHERE id = ?
      ''',
      parameters: [
        body['closingNotes'],
        userId,
        ticketId,
      ],
      userId: userId,
    );
    
    // Log activity for ticket closure (Activity ID: 501)
    try {
      await ActivityLogService.log(
        entityId: 3, // tickets entity
        recordId: ticketId,
        activityId: 501, // Close ticket
        userId: userId,

      );
    } catch (e) {
      print('Failed to log ticket closure activity: $e');
    }
    
    return Response.json(
      body: {
        'success': true,
        'message': 'Ticket closed successfully'
      },
    );
    
  } catch (e) {
    print('Close ticket error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while closing ticket',
        'error': e.toString()
      },
    );
  }
}

String? _validateCloseTicketRequest(Map<String, dynamic> body) {
  if (body['closingNotes'] == null || body['closingNotes'] is! String || (body['closingNotes'] as String).trim().isEmpty) {
    return 'closingNotes is required and must be a non-empty string';
  }
  if (body['closedBy'] == null || body['closedBy'] is! int) {
    return 'closedBy is required and must be an integer';
  }
  
  return null;
}

Future<bool> _checkTicketExists(int ticketId) async {
  try {
    final result = await DatabaseService.queryOne(
      'SELECT id, status FROM tickets WHERE id = ?',
      parameters: [ticketId],
      userId: 1, // System user for read operations
    );
    return result != null && result['status'] != 1;
  } catch (e) {
    return false;
  }
}