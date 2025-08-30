import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/models/governorate.dart';

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
    HttpMethod.get => await _get(context, id),
    HttpMethod.put => await _put(context, id),
    HttpMethod.delete => await _delete(context, id),
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

Future<Response> _get(RequestContext context, String id) async {
  try {
    final governorateId = int.tryParse(id);
    if (governorateId == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid ID'});
    }

    final result = await DatabaseService.queryOne(
      'SELECT id, name FROM governorates WHERE id = ?',
      parameters: [governorateId],
      userId: 1, // System user for read operations
    );

    if (result == null) {
      return Response.json(statusCode: 404, body: {'message': 'Governorate not found'});
    }

    return Response.json(body: Governorate.fromJson(result.fields).toJson());
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    );
  }
}

Future<Response> _put(RequestContext context, String id) async {
  try {
    final governorateId = int.tryParse(id);
    if (governorateId == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid ID'});
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final name = body['name'] as String?;

    if (name == null || name.isEmpty) {
      return Response.json(statusCode: 400, body: {'message': 'Name is required'});
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

    await DatabaseService.query(
      'UPDATE governorates SET name = ? WHERE id = ?',
      parameters: [name, governorateId],
      userId: userId,
    );

    return Response.json(body: {'id': governorateId, 'name': name});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    );
  }
}

Future<Response> _delete(RequestContext context, String id) async {
  try {
    final governorateId = int.tryParse(id);
    if (governorateId == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid ID'});
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

    await DatabaseService.query(
      'DELETE FROM governorates WHERE id = ?',
      parameters: [governorateId],
      userId: userId,
    );

    return Response(statusCode: 204);
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    );
  }
} 