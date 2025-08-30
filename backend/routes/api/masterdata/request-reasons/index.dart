import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:intl/intl.dart';

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
    HttpMethod.post => await _handlePost(context),
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

Future<Response> _handleGet(RequestContext context) async {
  try {
    final results = await DatabaseService.query(
        'SELECT id, name, created_by, created_at, updated_at, company_id FROM request_reasons',
        userId: 1, // System user for read operations
    );

    final reasons = results.map((row) {
      return {
        'id': row['id'],
        'name': row['name'],
        'created_by': row['created_by'],
        'created_at': row['created_at']?.toString(),
        'updated_at': row['updated_at']?.toString(),
        'company_id': row['company_id'],
      };
    }).toList();

    return _addCorsHeaders(Response.json(
      body: {
        'success': true,
        'data': reasons,
      },
    ));
  } catch (e) {
    print('Get request reasons error: $e');
    return _addCorsHeaders(Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while fetching request reasons',
        'error': e.toString(),
      },
    ));
  }
} 

Future<Response> _handlePost(RequestContext context) async {
  try {
    final body = await context.request.body();
    final data = jsonDecode(body);
    final name = data['name'] as String?;
    final createdBy = data['created_by'] as int?;
    final companyId = data['company_id'] as int?;
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    if (name == null || name.isEmpty) {
      return _addCorsHeaders(Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Name is required'},
      ));
    }
    if (createdBy == null) {
      return _addCorsHeaders(Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'created_by is required'},
      ));
    }
    if (companyId == null) {
      return _addCorsHeaders(Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'company_id is required'},
      ));
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
      'INSERT INTO request_reasons (name, created_by, created_at, updated_at, company_id) VALUES (?, ?, ?, ?, ?)',
      parameters: [name, createdBy, now, now, companyId],
      userId: userId,
    );

    return _addCorsHeaders(Response.json(
      body: {'success': true, 'message': 'Request reason created successfully'},
    ));
  } catch (e) {
    print('Post request reason error: $e');
    return _addCorsHeaders(Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while creating request reason',
        'error': e.toString(),
      },
    ));
  }
} 