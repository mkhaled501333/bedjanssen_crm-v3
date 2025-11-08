import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';
import 'package:mysql1/mysql1.dart';
import 'dart:convert';

Future<Response> onRequest(RequestContext context, String ticketId, String itemId) async {
  return switch (context.request.method) {
    HttpMethod.put => await _handlePut(context, ticketId, itemId),
    HttpMethod.delete => await _handleDelete(context, ticketId, itemId),
    HttpMethod.options => _handleOptions(),
    _ => Response(statusCode: 405, body: 'Method not allowed'),
  };
}

Response _handleOptions() {
  return Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

// PUT to update a ticket item
Future<Response> _handlePut(RequestContext context, String ticketId, String itemId) async {
  try {
    final tId = int.tryParse(ticketId);
    final itId = int.tryParse(itemId);
    if (tId == null || itId == null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Invalid ticket or item ID format'},
      );
    }
    
    final body = await context.request.json() as Map<String, dynamic>;
    print(  body);
    
    // Extract user ID from JWT payload
    int userId = 1; // Default fallback
    try {
      final jwtPayload = context.read<dynamic>();
      if (jwtPayload is Map<String, dynamic>) {
        userId = jwtPayload['id'] as int? ?? 1;
      }
    } catch (e) {
      print('Failed to extract user ID from JWT payload: $e');
    }
    
    final queryParts = <String>[];
    final params = <dynamic>[];

    if (body.containsKey('companyId')) {
      queryParts.add('company_id = ?');
      params.add(body['companyId']);
    }
    if (body.containsKey('productId')) {
      queryParts.add('product_id = ?');
      params.add(body['productId']);
    }
    if (body.containsKey('quantity')) {
      queryParts.add('quantity = ?');
      params.add(body['quantity']);
    }
    if (body.containsKey('product_size')) {
      queryParts.add('product_size = ?');
      params.add(body['product_size']);
    }
     if (body.containsKey('purchase_date')) {
      queryParts.add('purchase_date = ?');
      params.add(body['purchase_date']);
    }
    if (body.containsKey('purchase_location')) {
      queryParts.add('purchase_location = ?');
      params.add(body['purchase_location']);
    }
    if (body.containsKey('request_reason_id')) {
      queryParts.add('request_reason_id = ?');
      params.add(body['request_reason_id']);
    }
    if (body.containsKey('request_reason_detail')) {
      queryParts.add('request_reason_detail = ?');
      params.add(body['request_reason_detail']);
    }

    if (queryParts.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'No fields to update provided'},
      );
    }

    queryParts.add('updated_at = NOW()');

    params.add(itId);
    params.add(tId);
    
    final result = await DatabaseService.query(
      'UPDATE ticket_items SET ${queryParts.join(', ')} WHERE id = ? AND ticket_id = ?',
      parameters: params,
      userId: userId,
    );

    if (result.affectedRows == 0) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Ticket item not found or no changes made'},
      );
    }

    // Fetch the updated item
    final updatedItem = await DatabaseService.queryOne(
      '''
      SELECT ti.*, p.product_name as product_name, u.name AS createdByName, rr.name AS request_reason_name
      FROM ticket_items ti
      LEFT JOIN product_info p ON ti.product_id = p.id
      LEFT JOIN users u ON ti.created_by = u.id
      LEFT JOIN request_reasons rr ON ti.request_reason_id = rr.id
      WHERE ti.id = ?
      ''',
      parameters: [itId],
      userId: 1, // System user for read operations
    );
    
    if (updatedItem == null) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Updated ticket item not found'},
      );
    }

    // Log activity for item update (Activity ID: 506-513 based on field)
    try {
      // Extract user ID from JWT payload
      int userId = 1; // Default fallback
      try {
        final jwtPayload = context.read<dynamic>();
        if (jwtPayload is Map<String, dynamic>) {
          userId = jwtPayload['id'] as int? ?? 1;
        }
      } catch (e) {
        print('Failed to extract user ID from JWT payload: $e');
      }
      
      int activityId = 508; // Default to general update (quantity)
      if (body.containsKey('companyId')) activityId = 506; // Update item company ID
      else if (body.containsKey('productId')) activityId = 507; // Update item product ID
      else if (body.containsKey('quantity')) activityId = 508; // Update item quantity
      else if (body.containsKey('product_size')) activityId = 509; // Update item product size
      else if (body.containsKey('purchase_date')) activityId = 510; // Update item purchase date
      else if (body.containsKey('purchase_location')) activityId = 511; // Update item purchase location
      else if (body.containsKey('request_reason_id')) activityId = 512; // Update item request reason ID
      else if (body.containsKey('request_reason_detail')) activityId = 513; // Update item request reason detail
      
      await ActivityLogService.log(
        entityId: 4, // ticket_items entity
        recordId: itId,
        activityId: activityId,
        userId: userId,
      );
    } catch (e) {
      print('Failed to log item update activity: $e');
    }

    final requestReasonDetailString =
        _decodeSqlText(updatedItem['request_reason_detail']);
    final requestReasonNameString =
        _decodeSqlText(updatedItem['request_reason_name']);

    return Response.json(
      body: {
        'success': true,
        'data': {
            'id': updatedItem['id'],
            'companyId': updatedItem['company_id'],
            'ticketId': updatedItem['ticket_id'],
            'productId': updatedItem['product_id'],
            'productName': updatedItem['product_name'],
            'quantity': updatedItem['quantity'],
            'createdBy': updatedItem['createdByName'],
            'createdAt': updatedItem['created_at']?.toString(),
            'updatedAt': updatedItem['updated_at']?.toString(),
            'productSize': updatedItem['product_size'],
            'purchaseDate': updatedItem['purchase_date']?.toString(),
            'purchaseLocation': updatedItem['purchase_location'],
            'requestReasonId': updatedItem['request_reason_id'],
            'requestReasonName': requestReasonNameString,
            'requestReasonDetail': requestReasonDetailString,
        }
      },
    );

  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Internal server error', 'error': e.toString()},
    );
  }
}

String? _decodeSqlText(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Blob) {
    return utf8.decode(value.toBytes());
  }
  return value.toString();
}

// DELETE to remove a ticket item
Future<Response> _handleDelete(RequestContext context, String ticketId, String itemId) async {
  try {
    final tId = int.tryParse(ticketId);
    final itId = int.tryParse(itemId);
    if (tId == null || itId == null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Invalid ticket or item ID format'},
      );
    }
    
    // Extract user ID from JWT payload
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
      'DELETE FROM ticket_items WHERE id = ? AND ticket_id = ?',
      parameters: [itId, tId],
      userId: userId,
    );

    if (result.affectedRows == 0) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Ticket item not found'},
      );
    }
    
    // Log activity for item deletion (Activity ID: 514)
    try {
      // Extract user ID from JWT payload
      int userId = 1; // Default fallback
      try {
        final jwtPayload = context.read<dynamic>();
        if (jwtPayload is Map<String, dynamic>) {
          userId = jwtPayload['id'] as int? ?? 1;
        }
      } catch (e) {
        print('Failed to extract user ID from JWT payload: $e');
      }
      
      await ActivityLogService.log(
        entityId: 4, // ticket_items entity
        recordId: itId,
        activityId: 514, // Delete ticket item
        userId: userId,
      );
    } catch (e) {
      print('Failed to log item deletion activity: $e');
    }
    
    return Response.json(body: {'success': true, 'message': 'Ticket item deleted successfully'});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Internal server error', 'error': e.toString()},
    );
  }
}