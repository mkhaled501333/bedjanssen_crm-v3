import 'package:dart_frog/dart_frog.dart';
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
    HttpMethod.get => await _handleGet(context),
    HttpMethod.options => _handleOptions(),
    _ => _addCorsHeaders(Response(statusCode: 405, body: 'Method not allowed')),
  };
}

Response _handleOptions() {
  return _addCorsHeaders(
    Response(
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    ),
  );
}

/// GET /api/activity-logs/activities - Get all activities
Future<Response> _handleGet(RequestContext context) async {
  try {
    final activities = await ActivityLogService.getActivities();
    
    return _addCorsHeaders(
      Response.json(
        statusCode: 200,
        body: {
          'success': true,
          'data': {
            'activities': activities.map((activity) => activity.toMap()).toList(),
          },
          'message': 'Activities retrieved successfully',
        },
      ),
    );
  } catch (e) {
    print('Error retrieving activities: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {
          'success': false,
          'message': 'Internal server error occurred while retrieving activities',
          'error': e.toString(),
        },
      ),
    );
  }
}