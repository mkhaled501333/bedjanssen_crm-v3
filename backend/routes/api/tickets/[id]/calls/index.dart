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

/// POST /api/tickets/{id}/calls - Add a new call log to a ticket
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
    final validationError = _validateAddCallRequest(body);
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
    
    // Insert ticket call
    final int callTypeInt;
    try {
      callTypeInt = _convertCallTypeToInt(body['callType'] as String);
    } on ArgumentError catch (e) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': e.message, 'error': 'Validation failed'},
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
    
    final callId = await DatabaseService.transaction<int>(() async {
      final result = await DatabaseService.query(
        '''
        INSERT INTO ticketcall (
          company_id, ticket_id, call_type, call_cat_id, description, call_notes,
          call_duration, created_by, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ''',
        parameters: [
          body['companyId'],
          ticketId,
          callTypeInt,
          body['callCatId'],
          body['description'],
          body['callNotes'] ?? '',
          body['callDuration'] ?? 0,
          userId,
        ],
        userId: userId,
      );
      
      return result.insertId!;
    }, userId: userId);
    
    // Log activity for adding call log to ticket (Activity ID: 503)
    try {
      await ActivityLogService.log(
        entityId: 3, // tickets entity
        recordId: ticketId,
        activityId: 503, // Add call log to ticket
        userId: userId,
      );
    } catch (e) {
      print('Failed to log call addition activity: $e');
    }
    
    // Get the call details
    final callData = await _getCallDetails(callId);
    
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'data': callData,
        'message': 'Call log added successfully'
      },
    );
    
  } catch (e) {
    print('Add ticket call error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while adding call log',
        'error': e.toString()
      },
    );
  }
}

String? _validateAddCallRequest(Map<String, dynamic> body) {
  if (body['companyId'] == null || body['companyId'] is! int) {
    return 'companyId is required and must be an integer';
  }
  
  if (body['callType'] == null || body['callType'] is! String) {
    return 'callType is required and must be a string';
  }
  
  if (body['callCatId'] == null || body['callCatId'] is! int) {
    return 'callCatId is required and must be an integer';
  }
  
  if (body['description'] == null || body['description'] is! String || (body['description'] as String).trim().isEmpty) {
    return 'description is required and must be a non-empty string';
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

Future<Map<String, dynamic>?> _getCallDetails(int callId) async {
  try {
    final callResult = await DatabaseService.queryOne(
      '''
      SELECT tc.*, cat.name AS categoryName, u.name AS createdByName
      FROM ticketcall tc
      LEFT JOIN users u ON tc.created_by = u.id
      LEFT JOIN call_categories cat ON tc.call_cat_id = cat.id
      WHERE tc.id = ?
      ''',
      parameters: [callId],
      userId: 1, // System user for read operations
    );
    
    if (callResult == null) {
      return null;
    }
    
    return {
      'id': callResult['id'],
      'companyId': callResult['company_id'],
      'ticketId': callResult['ticket_id'],
      'callType': _convertCallTypeToString(callResult['call_type'] as int),
      'callCatId': callResult['call_cat_id'],
      'category': callResult['categoryName'],
      'description': callResult['description']?.toString(),
      'callNotes': callResult['call_notes']?.toString(),
      'callDuration': callResult['call_duration'],
      'createdBy': callResult['createdByName'],
      'createdAt': callResult['created_at']?.toString(),
      'updatedAt': callResult['updated_at']?.toString(),
    };
  } catch (e) {
    print('Error getting call details: $e');
    return null;
  }
}

int _convertCallTypeToInt(String callType) {
  switch (callType.toLowerCase()) {
    case 'incoming':
      return 0;
    case 'outgoing':
      return 1;
    default:
      throw ArgumentError('Invalid call type: $callType');
  }
}

String _convertCallTypeToString(int callType) {
  switch (callType) {
    case 0:
      return 'incoming';
    case 1:
      return 'outgoing';
    default:
      return 'unknown';
  }
}