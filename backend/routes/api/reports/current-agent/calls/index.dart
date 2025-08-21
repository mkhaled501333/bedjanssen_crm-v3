import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/reports/customer_calls_service.dart';
import 'package:janssencrm_backend/services/reports/ticket_calls_service.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _handleGet(context),
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

/// GET /api/reports/currentagent - Get all calls created by a specific user
Future<Response> _handleGet(RequestContext context) async {
  try {
    final request = context.request;
    final uri = request.uri;
    
    // Extract query parameters
    final userId = uri.queryParameters['userId'];
    final startDate = uri.queryParameters['startDate'];
    final endDate = uri.queryParameters['endDate'];
    
    // Validate required parameters
    if (userId == null || startDate == null || endDate == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Missing required parameters: userId, startDate, endDate',
          'error': 'All query parameters are required'
        },
      );
    }
    
    // Validate userId
    final userIdInt = int.tryParse(userId);
    if (userIdInt == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Invalid userId format',
          'error': 'userId must be a valid integer'
        },
      );
    }
    
    // Validate date format (YYYY-MM-DD)
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(startDate) || !dateRegex.hasMatch(endDate)) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Invalid date format',
          'error': 'Dates must be in YYYY-MM-DD format'
        },
      );
    }
    
    // Check if user exists
    final userExists = await _checkUserExists(userIdInt);
    if (!userExists) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'User not found',
          'error': 'No user found with the provided ID'
        },
      );
    }
    
    // Get customer calls
    final customerCalls = await getCustomerCalls(userIdInt, startDate, endDate);
    
    // Get ticket calls
    final ticketCalls = await getTicketCalls(userIdInt, startDate, endDate);
    
    // Combine and sort results by creation date
    final allCalls = [...customerCalls, ...ticketCalls];
    allCalls.sort((a, b) {
      final aDate = a['createdAt'] as String?;
      final bDate = b['createdAt'] as String?;
      if (aDate == null || bDate == null) return 0;
      return DateTime.parse(aDate).compareTo(DateTime.parse(bDate));
    });
    
    return Response.json(
      statusCode: 200,
      body: {
        'success': true,
        'data': {
          'userId': userIdInt,
          'startDate': startDate,
          'endDate': endDate,
          'totalCalls': allCalls.length,
          'customerCalls': customerCalls.length,
          'ticketCalls': ticketCalls.length,
          'calls': allCalls,
        },
        'message': 'Agent calls report retrieved successfully'
      },
    );
    
  } catch (e) {
    print('Get agent calls report error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while retrieving report',
        'error': e.toString()
      },
    );
  }
}

Future<bool> _checkUserExists(int userId) async {
  try {
    final result = await DatabaseService.queryOne(
      'SELECT id FROM users WHERE id = ?',
      parameters: [userId],
    );
    return result != null;
  } catch (e) {
    return false;
  }
} 