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
      'SELECT id, name, created_by, created_at, updated_at, company_id FROM request_reasons WHERE id = ?',
      parameters: [id],
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Request reason not found'},
      );
    }

    final reason = {
      'id': result.first['id'],
      'name': result.first['name'],
      'created_by': result.first['created_by'],
      'created_at': result.first['created_at']?.toString(),
      'updated_at': result.first['updated_at']?.toString(),
      'company_id': result.first['company_id'],
    };

    return Response.json(body: reason);
  } catch (e) {
    print('Get request reason by id error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while fetching request reason',
        'error': e.toString(),
      },
    );
  }
}

Future<Response> _handlePut(RequestContext context, String id) async {
  try {
    final body = await context.request.body();
    final data = jsonDecode(body);
    final name = data['name'] as String?;
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    if (name == null || name.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Name is required'},
      );
    }

    await DatabaseService.query(
      'UPDATE request_reasons SET name = ?, updated_at = ? WHERE id = ?',
      parameters: [name, now, id],
    );

    return Response.json(
      body: {'success': true, 'message': 'Request reason updated successfully'},
    );
  } catch (e) {
    print('Put request reason error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while updating request reason',
        'error': e.toString(),
      },
    );
  }
}

Future<Response> _handleDelete(RequestContext context, String id) async {
  try {
    await DatabaseService.query(
      'DELETE FROM request_reasons WHERE id = ?',
      parameters: [id],
    );

    return Response.json(
      statusCode: 200,
      body: {'success': true, 'message': 'Request reason deleted successfully'},
    );
  } catch (e) {
    print('Delete request reason error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while deleting request reason',
        'error': e.toString(),
      },
    );
  }
} 