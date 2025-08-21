import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/models/customer_phone.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';

Future<Response> onRequest(RequestContext context, String customerId) async {
  return switch (context.request.method) {
    HttpMethod.get => await _get(context, customerId),
    HttpMethod.post => await _post(context, customerId),
    HttpMethod.options => _handleOptions(),
    _ => Response(statusCode: 405),
  };
}

Response _handleOptions() {
  return Response(
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

Future<Response> _get(RequestContext context, String customerId) async {
  try {
    final customerIdInt = int.tryParse(customerId);
    if (customerIdInt == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid customer ID'});
    }

    final results = await DatabaseService.query(
      'SELECT * FROM customer_phones WHERE customer_id = ?',
      parameters: [customerIdInt],
    );

    final phones = results.map((row) => CustomerPhone.fromJson(row.fields)).toList();
    return Response.json(body: phones.map((p) => p.toJson()).toList());
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    );
  }
}

Future<Response> _post(RequestContext context, String customerId) async {
  try {
    final customerIdInt = int.tryParse(customerId);
    if (customerIdInt == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid customer ID'});
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final phone = body['phone'] as String?;
    final phoneType = body['phone_type'] as int?;
    final companyId = body['company_id'] as int?;
    final createdBy = body['created_by'] as int?;
 
    if (phone == null || phone.isEmpty) {
      return Response.json(statusCode: 400, body: {'message': 'Phone number is required'});
    }
    if (companyId == null) {
      return Response.json(statusCode: 400, body: {'message': 'Company ID is required'});
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

    print(createdBy);
    final result = await DatabaseService.query(
      'INSERT INTO customer_phones (customer_id, company_id, phone, phone_type, created_by) VALUES (?, ?, ?, ?, ?)',
      parameters: [customerIdInt, companyId, phone, phoneType, userId],
    );

    final lastInsertId = result.insertId;
    
    // Log activity for phone creation (Activity ID: 206)
    try {
      await ActivityLogService.log(
        entityId: 2, // customers entity
        recordId: customerIdInt,
        activityId: 103, // Add customer phone
        userId: userId,
      );
    } catch (e) {
      print('Failed to log phone creation activity: $e');
    }

    return Response.json(statusCode: 201, body: {'id': lastInsertId, 'customer_id': customerIdInt, ...body});

  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    );
  }
}