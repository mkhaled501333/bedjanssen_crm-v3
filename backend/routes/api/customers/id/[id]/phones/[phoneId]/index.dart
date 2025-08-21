import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/models/customer_phone.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';

Future<Response> onRequest(RequestContext context, String customerId, String phoneId) async {
  return switch (context.request.method) {
    HttpMethod.get => await _get(context, customerId, phoneId),
    HttpMethod.put => await _put(context, customerId, phoneId),
    HttpMethod.delete => await _delete(context, customerId, phoneId),
    HttpMethod.options => _handleOptions(),
    _ => Response(statusCode: 405),
  };
}

Response _handleOptions() {
  return Response(
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

Future<Response> _get(RequestContext context, String customerId, String phoneId) async {
  try {
    final phoneIdInt = int.tryParse(phoneId);
    if (phoneIdInt == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid phone ID'});
    }

    final result = await DatabaseService.queryOne(
      'SELECT * FROM customer_phones WHERE id = ?',
      parameters: [phoneIdInt],
    );

    if (result == null) {
      return Response.json(statusCode: 404, body: {'message': 'Phone not found'});
    }

    return Response.json(body: CustomerPhone.fromJson(result.fields).toJson());
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    );
  }
}

Future<Response> _put(RequestContext context, String customerId, String phoneId) async {
  try {
    final customerIdInt = int.tryParse(customerId);
    final phoneIdInt = int.tryParse(phoneId);

    if (customerIdInt == null || phoneIdInt == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid customer or phone ID'});
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final phone = body['phone'] as String?;

    if (phone == null || phone.isEmpty) {
      return Response.json(statusCode: 400, body: {'message': 'Phone number is required'});
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

    await DatabaseService.query(
      'UPDATE customer_phones SET phone = ? WHERE id = ? AND customer_id = ?',
      parameters: [phone, phoneIdInt, customerIdInt],
    );

    // Log activity for phone update (Activity ID: 104)
    try {
      await ActivityLogService.log(
        entityId: 2, // customers entity
        recordId: customerIdInt,
        activityId: 104, // Update customer phone
        userId: userId,
      );
    } catch (e) {
      print('Failed to log phone update activity: $e');
    }

    return Response.json(body: {'message': 'Phone updated successfully'});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    );
  }
}

Future<Response> _delete(RequestContext context, String customerId, String phoneId) async {
  try {
    final customerIdInt = int.tryParse(customerId);
    final phoneIdInt = int.tryParse(phoneId);

    if (customerIdInt == null || phoneIdInt == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid customer or phone ID'});
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

    await DatabaseService.query(
      'DELETE FROM customer_phones WHERE id = ? AND customer_id = ?',
      parameters: [phoneIdInt, customerIdInt],
    );

    // Log activity for phone deletion (Activity ID: 105)
    try {
      await ActivityLogService.log(
        entityId: 2, // customers entity
        recordId: customerIdInt,
        activityId: 105, // Delete customer phone
        userId: userId,
      );
    } catch (e) {
      print('Failed to log phone deletion activity: $e');
    }

    return Response(statusCode: 204);
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    );
  }
}