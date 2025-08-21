import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';

Response _addCorsHeaders(Response response) => response.copyWith(
  headers: {
    ...response.headers,
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Origin,Content-Type,Authorization',
  },
);

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;


  // Handle CORS preflight
  if (request.method == HttpMethod.options) {
    return _addCorsHeaders(Response());
  }

  // Extract user ID from JWT token for activity logging
  var userId = 1; // Default fallback
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        final jwt = JWT.verify(token, SecretKey('your-secret-key'));
        final payload = jwt.payload as Map<String, dynamic>;
        userId = payload['id'] as int? ?? 1;
      } else {
        print('No valid authorization header found, using default userId: $userId');
      }
    } catch (e) {
      print('Error extracting user ID from token: $e');
    }

  // Log logout activity
  try {

    
    await ActivityLogService.log(
      entityId: 3, // users entity
      recordId: userId,
      activityId: 2, // User logout activity
      userId: userId,
    );
  } catch (e) {
    print('✗ Failed to log logout activity: $e');
    print('Error type: ${e.runtimeType}');
    print('Stack trace: ${StackTrace.current}');
  }

  // For stateless JWT, logout is handled client-side by deleting the token.
  // Optionally, implement token blacklisting here if needed.
  return _addCorsHeaders(
    Response.json(body: {'success': true, 'message': 'Logged out'}),
  );
}
