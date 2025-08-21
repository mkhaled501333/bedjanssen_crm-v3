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

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _get(context),
    HttpMethod.post => await _post(context),
    HttpMethod.options => _handleOptions(),
    _ => _addCorsHeaders(Response(statusCode: 405, body: 'Method not allowed')),
  };
}

Response _handleOptions() {
  return _addCorsHeaders(Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  ));
}

Future<Response> _get(RequestContext context) async {
  try {
    final results = await DatabaseService.query('SELECT id, name FROM call_categories');
    final categories = results.map((row) {
      return {
        'id': row['id'],
        'name': row['name'],
      };
    }).toList();
    return _addCorsHeaders(Response.json(
      body: {
        'success': true,
        'data': categories,
      },
    ));
  } catch (e) {
    print('Get call categories error: $e');
    return _addCorsHeaders(Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while fetching call categories',
        'error': e.toString(),
      },
    ));
  }
} 

Future<Response> _post(RequestContext context) async {
  try {
    final body = await context.request.body();
    final data = jsonDecode(body);
    final name = data['name'];

    if (name == null) {
      return _addCorsHeaders(Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Name is required'},
      ));
    }

    await DatabaseService.query(
      'INSERT INTO call_categories (name) VALUES (?)',
      parameters: [name],
    );

    return _addCorsHeaders(Response.json(
      body: {'success': true, 'message': 'Call category created successfully'},
    ));
  } catch (e) {
    print('Post call category error: $e');
    return _addCorsHeaders(Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while creating call category',
        'error': e.toString(),
      },
    ));
  }
} 