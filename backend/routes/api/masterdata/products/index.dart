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
        'SELECT id, company_id, product_name, created_by, created_at, updated_at FROM product_info',
        userId: 1, // System user for read operations
    );

    final products = results.map((row) {
      return {
        'id': row['id'],
        'company_id': row['company_id'],
        'product_name': row['product_name'],
        'created_by': row['created_by'],
        'created_at': row['created_at']?.toString(),
        'updated_at': row['updated_at']?.toString(),
      };
    }).toList();

    return _addCorsHeaders(Response.json(
      body: {
        'success': true,
        'data': products,
      },
    ));
  } catch (e) {
    print('Get products error: $e');
    return _addCorsHeaders(Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while fetching products',
        'error': e.toString(),
      },
    ));
  }
} 

Future<Response> _handlePost(RequestContext context) async {
  try {
    final body = await context.request.body();
    final data = jsonDecode(body);
    final productName = data['product_name'] as String?;
    final companyId = data['company_id'] as int?;
    final createdBy = data['created_by'] as int?;

    if (productName == null || productName.isEmpty) {
      return _addCorsHeaders(Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Product name is required'},
      ));
    }
     if (companyId == null) {
      return _addCorsHeaders(Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'company_id is required'},
      ));
    }
    if (createdBy == null) {
      return _addCorsHeaders(Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'created_by is required'},
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
      'INSERT INTO product_info (product_name, company_id, created_by) VALUES (?, ?, ?)',
      parameters: [productName, companyId, createdBy],
      userId: userId,
    );

    return _addCorsHeaders(Response.json(
      body: {'success': true, 'message': 'Product created successfully'},
    ));
  } catch (e) {
    print('Post product error: $e');
    return _addCorsHeaders(Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while creating product',
        'error': e.toString(),
      },
    ));
  }
} 