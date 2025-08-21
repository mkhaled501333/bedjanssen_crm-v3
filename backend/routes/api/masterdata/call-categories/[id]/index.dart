import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';

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
    HttpMethod.put => await _handlePut(context, id),
    HttpMethod.delete => await _handleDelete(context, id),
    HttpMethod.options => _handleOptions(),
    _ => _addCorsHeaders(Response(statusCode: 405, body: 'Method not allowed')),
  };
}

Response _handleOptions() {
  return _addCorsHeaders(Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  ));
}

Future<Response> _handleGet(RequestContext context, String id) async {
  try {
    final result = await DatabaseService.query(
      'SELECT id, name FROM call_categories WHERE id = ?',
      parameters: [id],
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Call category not found'},
      );
    }

    final category = {
      'id': result.first['id'],
      'name': result.first['name'],
    };

    return Response.json(body: category);
  } catch (e) {
    print('Get call category by id error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while fetching call category',
        'error': e.toString(),
      },
    );
  }
}

Future<Response> _handlePut(RequestContext context, String id) async {
  try {
    final body = await context.request.body();
    final data = jsonDecode(body);
    final name = data['name'];

    if (name == null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Name is required'},
      );
    }

    await DatabaseService.query(
      'UPDATE call_categories SET name = ? WHERE id = ?',
      parameters: [name, id],
    );

    return Response.json(
      body: {'success': true, 'message': 'Call category updated successfully'},
    );
  } catch (e) {
    print('Put call category error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while updating call category',
        'error': e.toString(),
      },
    );
  }
}

Future<Response> _handleDelete(RequestContext context, String id) async {
  try {
    await DatabaseService.query(
      'DELETE FROM call_categories WHERE id = ?',
      parameters: [id],
    );

    return Response.json(
      statusCode: 200,
      body: {'success': true, 'message': 'Call category deleted successfully'},
    );
  } catch (e) {
    print('Delete call category error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while deleting call category',
        'error': e.toString(),
      },
    );
  }
} 