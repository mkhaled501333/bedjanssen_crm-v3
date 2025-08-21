import 'package:dart_frog/dart_frog.dart';

/// Add CORS headers to response
Response addCorsHeaders(Response response) {
  return response.copyWith(
    headers: {
      ...response.headers,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

/// Create a success response with CORS headers
Response createSuccessResponse({
  required Map<String, dynamic> data,
  required String message,
  int statusCode = 200,
}) {
  return addCorsHeaders(
    Response.json(
      statusCode: statusCode,
      body: {
        'success': true,
        'data': data,
        'message': message,
      },
    ),
  );
}

/// Create an error response with CORS headers
Response createErrorResponse({
  required int statusCode,
  required String message,
  required String error,
}) {
  return addCorsHeaders(
    Response.json(
      statusCode: statusCode,
      body: {
        'success': false,
        'message': message,
        'error': error,
      },
    ),
  );
}