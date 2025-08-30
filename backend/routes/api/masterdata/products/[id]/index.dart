import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final intId = int.tryParse(id);
  if (intId == null) {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Invalid product ID format'},
    );
  }

  return switch (context.request.method) {
    HttpMethod.get => await _handleGet(context, intId),
    HttpMethod.put => await _handlePut(context, intId),
    HttpMethod.delete => await _handleDelete(context, intId),
    HttpMethod.options => _handleOptions(),
    _ => Response(statusCode: 405, body: 'Method not allowed'),
  };
}

Response _handleOptions() {
  return Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

Future<Response> _handleGet(RequestContext context, int id) async {
  try {
    final result = await DatabaseService.query(
      'SELECT id, company_id, product_name, created_by, created_at, updated_at FROM product_info WHERE id = ?',
      parameters: [id],
      userId: 1, // System user for read operations
    );

    if (result.isEmpty) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Product not found'},
      );
    }

    final product = {
      'id': result.first['id'],
      'company_id': result.first['company_id'],
      'product_name': result.first['product_name'],
      'created_by': result.first['created_by'],
      'created_at': result.first['created_at']?.toString(),
      'updated_at': result.first['updated_at']?.toString(),
    };

    return Response.json(body: product);
  } catch (e) {
    print('Get product by id error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while fetching product',
        'error': e.toString(),
      },
    );
  }
}

Future<Response> _handlePut(RequestContext context, int id) async {
  try {
    final body = await context.request.body();
    final data = jsonDecode(body);
    final productName = data['product_name'] as String?;

    if (productName == null || productName.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Product name is required'},
      );
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
      'UPDATE product_info SET product_name = ? WHERE id = ?',
      parameters: [productName, id],
      userId: userId,
    );

    return Response.json(
      body: {'success': true, 'message': 'Product updated successfully'},
    );
  } catch (e) {
    print('Put product error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while updating product',
        'error': e.toString(),
      },
    );
  }
}

Future<Response> _handleDelete(RequestContext context, int id) async {
  try {
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
      'DELETE FROM product_info WHERE id = ?',
      parameters: [id],
      userId: userId,
    );

    return Response.json(
      statusCode: 200,
      body: {'success': true, 'message': 'Product deleted successfully'},
    );
  } catch (e) {
    print('Delete product error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while deleting product',
        'error': e.toString(),
      },
    );
  }
} 