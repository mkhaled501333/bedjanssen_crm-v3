import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/models/city.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _get(context),
    HttpMethod.post => await _post(context),
    HttpMethod.options => _handleOptions(),
    _ => _addCorsHeaders(Response(statusCode: 405)),
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

Future<Response> _get(RequestContext context) async {
  try {
    final params = context.request.uri.queryParameters;
    final governorateId = int.tryParse(params['governorateId'] ?? '');

    String sql = 'SELECT id, name, governorate_id FROM cities';
    List<Object> parameters = [];

    if (governorateId != null) {
      sql += ' WHERE governorate_id = ?';
      parameters.add(governorateId);
    }

    final results = await DatabaseService.query(
      sql, 
      parameters: parameters,
      userId: 1, // System user for read operations
    );
    final cities = results.map((row) => City.fromJson(row.fields)).toList();
    return _addCorsHeaders(Response.json(body: cities.map((c) => c.toJson()).toList()));
  } catch (e) {
    return _addCorsHeaders(Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    ));
  }
}

Future<Response> _post(RequestContext context) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final name = body['name'] as String?;
    final governorateId = body['governorate_id'] as int?;

    if (name == null || name.isEmpty) {
      return _addCorsHeaders(Response.json(statusCode: 400, body: {'message': 'Name is required'}));
    }
    if (governorateId == null) {
      return _addCorsHeaders(Response.json(statusCode: 400, body: {'message': 'Governorate ID is required'}));
    }

    // Extract user ID from JWT token
    int userId = 1; // Default fallback
    try {
      final jwtPayload = context.read<dynamic>();
      if (jwtPayload is Map<String, dynamic>) {
        userId = jwtPayload['id'] as int? ?? 1;
      }
    } catch (e) {
      print('Failed to extract user ID from JWT payload: $e');
    }

    final result = await DatabaseService.query(
      'INSERT INTO cities (name, governorate_id) VALUES (?, ?)',
      parameters: [name, governorateId],
      userId: userId,
    );

    final lastInsertId = result.insertId;
    return _addCorsHeaders(Response.json(body: {'id': lastInsertId, 'name': name, 'governorate_id': governorateId}));

  } catch (e) {
    return _addCorsHeaders(Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    ));
  }
} 