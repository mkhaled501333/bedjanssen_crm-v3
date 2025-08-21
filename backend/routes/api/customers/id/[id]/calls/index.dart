import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';
import 'package:mysql1/mysql1.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.post => await _handlePost(context, id),
    HttpMethod.options => _handleOptions(),
    _ => Response(statusCode: 405, body: 'Method not allowed'),
  };
}

Response _handleOptions() {
  return Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

/// POST /api/customers/id/{id}/calls - Add a new call log to a customer
Future<Response> _handlePost(RequestContext context, String id) async {
  try {
    // Validate customer ID
    final customerId = int.tryParse(id);
    if (customerId == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Invalid customer ID format',
          'error': 'Customer ID must be a valid integer'
        },
      );
    }
    
    final request = context.request;
    final body = await request.json() as Map<String, dynamic>;
    
    // Validate request body
    final validationError = _validateAddCallRequest(body);
    if (validationError != null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': validationError,
          'error': 'Validation failed'
        },
      );
    }
    
    // Check if customer exists
    final customerExists = await _checkCustomerExists(customerId);
    if (!customerExists) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Customer not found',
          'error': 'No customer found with the provided ID'
        },
      );
    }
    
    int callTypeInt;
    final callTypeString = body['callType'] as String;
    if (callTypeString.toLowerCase() == 'incoming') {
      callTypeInt = 0;
    } else if (callTypeString.toLowerCase() == 'outgoing') {
      callTypeInt = 1;
    } else {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Invalid callType value. Must be "incoming" or "outgoing".'},
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

    // Insert customer call
    final callId = await DatabaseService.transaction<int>(() async {
      final result = await DatabaseService.query(
        '''
        INSERT INTO customercall (
          company_id, customer_id, call_type, category_id, description, call_notes,
          call_duration, created_by, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ''',
        parameters: [
          body['companyId'],
          customerId,
          callTypeInt,
          body['categoryId'],
          body['description'],
          body['notes'] ?? '',
          body['callDuration'] ?? 0,
          userId,
        ],
      );
      
      return result.insertId!;
    });
    
    // Log activity for call creation (Activity ID: 107)
    try {
      await ActivityLogService.log(
        entityId: 2, // customers entity
        recordId: customerId,
        activityId: 107, // Create customer call
        userId: userId,
      );
    } catch (e) {
      print('Failed to log call creation activity: $e');
    }
    
    // Get the created call details
    final callData = await _getCallDetails(callId);
    
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'data': callData,
        'message': 'Customer call log added successfully'
      },
    );
    
  } catch (e) {
    print('Add customer call error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while adding call log',
        'error': e.toString()
      },
    );
  }
}

String? _validateAddCallRequest(Map<String, dynamic> body) {
  if (body['companyId'] == null || body['companyId'] is! int) {
    return 'companyId is required and must be an integer';
  }
  
  if (body['callType'] == null || body['callType'] is! String) {
    return 'callType is required and must be a string';
  }
  
  if (body['categoryId'] == null || body['categoryId'] is! int) {
    return 'categoryId is required and must be an integer';
  }
  
  if (body['description'] == null || body['description'] is! String || (body['description'] as String).trim().isEmpty) {
    return 'description is required and must be a non-empty string';
  }
  
  return null;
}

dynamic _convertFromBlob(dynamic value) {
  if (value is Blob) {
    return value.toString();
  }
  return value;
}

Future<bool> _checkCustomerExists(int customerId) async {
  try {
    final result = await DatabaseService.queryOne(
      'SELECT id FROM customers WHERE id = ?',
      parameters: [customerId],
    );
    return result != null;
  } catch (e) {
    return false;
  }
}

Future<Map<String, dynamic>?> _getCallDetails(int callId) async {
  try {
    final callResult = await DatabaseService.queryOne(
      '''
      SELECT
        cc.id,
        cc.company_id,
        cc.customer_id,
        cc.call_type,
        cc.category_id,
        cc.description,
        cc.call_notes,
        cc.call_duration,
        cc.created_by,
        cc.created_at,
        cc.updated_at,
        cat.name AS categoryName,
        u.name AS createdByName
      FROM customercall cc
      LEFT JOIN users u ON cc.created_by = u.id
      LEFT JOIN call_categories cat ON cc.category_id = cat.id
      WHERE cc.id = ?
      ''',
      parameters: [callId],
    );
    
    if (callResult == null) {
      return null;
    }
    
    return {
      'id': callResult['id'],
      'companyId': callResult['company_id'],
      'customerId': callResult['customer_id'],
      'callType': callResult['call_type'],
      'categoryId': callResult['category_id'],
      'category': _convertFromBlob(callResult['categoryName']),
      'description': _convertFromBlob(callResult['description']),
      'callNotes': _convertFromBlob(callResult['call_notes']),
      'callDuration': callResult['call_duration'],
      'createdBy': _convertFromBlob(callResult['createdByName']),
      'createdAt': callResult['created_at']?.toString(),
      'updatedAt': callResult['updated_at']?.toString(),
    };
  } catch (e) {
    print('Error getting call details: $e');
    return null;
  }
}