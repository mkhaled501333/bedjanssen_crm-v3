// ignore_for_file: inference_failure_on_collection_literal

import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => await _handlePost(context),
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

Future<Response> _handlePost(RequestContext context) async {
  try {
    final request = context.request;
    final body = await request.json() as Map<String, dynamic>;
    
    // Validate required fields
    final validationError = _validateCreateCustomerWithCallRequest(body);
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
    
    // Extract data from request body
    final companyId = body['companyId'] as int;
    final name = body['name'] as String;
    final address = body['address'] as String?;
    final notes = body['notes'] as String?;
    final governorateId = body['governorateId'] as int?;
    final cityId = body['cityId'] as int?;
    final phones = body['phones'] as List<dynamic>;
    final call = body['call'] as Map<String, dynamic>;
    
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
    
    // Start transaction
    final customerId = await DatabaseService.transaction<int>(() async {
      // Insert customer
      final customerResult = await DatabaseService.query(
        '''
        INSERT INTO customers (company_id, name, address, notes, governomate_id, city_id, created_by, created_at, updated_at) 
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ''',
        parameters: [companyId, name, address, notes, governorateId, cityId, userId],
        userId: userId,
      );
      
      final newCustomerId = customerResult.insertId!;
      
      // Insert customer phones
      for (final phoneData in phones) {
        final phoneMap = phoneData as Map<String, dynamic>;
        await DatabaseService.query(
          '''
          INSERT INTO customer_phones (company_id, customer_id, phone, phone_type, created_by, created_at, updated_at) 
          VALUES (?, ?, ?, ?, ?, NOW(), NOW())
        ''',
          parameters: [
            companyId,
            newCustomerId,
            phoneMap['phone'],
            _getPhoneTypeId(phoneMap['phoneType'] as String?),
            userId,
          ],
          userId: userId,
        );
      }
      
      // Insert customer call
      await DatabaseService.query(
        '''
        INSERT INTO customercall (company_id, customer_id, call_type, category_id, description, call_notes, call_duration, created_by, created_at, updated_at) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ''',
        parameters: [
          companyId,
          newCustomerId,
          _getCallTypeId(call['callType'] as String?),
          call['categoryId'],
          call['description'],
          call['callNotes'],
          call['callDuration'] ?? 0,
          userId,
        ],
        userId: userId,
      );
      
      return newCustomerId;
    }, userId: userId);
    
    // Log activity for customer creation with call (Activity ID: 110)
    try {
      await ActivityLogService.log(
        entityId: 2, // customers entity
        recordId: customerId,
        activityId: 110, // Create customer with call
        userId: userId,
      );
    } catch (e) {
      print('Failed to log customer creation activity: $e');
    }
    
    // Fetch the complete customer data to return
    final customerData = await _getCustomerDetails(customerId);
    
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'data': customerData,
        'message': 'Customer created successfully with call log'
      },
    );
    
  } catch (e) {
    print('Create customer with call error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while creating customer',
        'error': e.toString()
      },
    );
  }
}

String? _validateCreateCustomerWithCallRequest(Map<String, dynamic> body) {
  // Check required fields
  if (body['companyId'] == null || body['companyId'] is! int) {
    return 'companyId is required and must be an integer';
  }
  
  if (body['name'] == null || body['name'] is! String || (body['name'] as String).trim().isEmpty) {
    return 'name is required and must be a non-empty string';
  }
  
  if (body['phones'] == null || body['phones'] is! List || (body['phones'] as List).isEmpty) {
    return 'phones is required and must be a non-empty array';
  }
  
  if (body['call'] == null || body['call'] is! Map) {
    return 'call is required and must be an object';
  }
  
  // Validate phones array
  final phones = body['phones'] as List;
  for (final phone in phones) {
    if (phone is! Map || phone['phone'] == null || phone['phone'] is! String) {
      return 'Each phone must have a valid phone string';
    }
  }
  
  // Validate call object
  final call = body['call'] as Map<String, dynamic>;
  if (call['callType'] == null || call['callType'] is! String) {
    return 'call.callType is required and must be a string';
  }
  
  if (call['categoryId'] == null || call['categoryId'] is! int) {
    return 'call.categoryId is required and must be an integer';
  }
  
  if (call['description'] == null || call['description'] is! String || (call['description'] as String).trim().isEmpty) {
    return 'call.description is required and must be a non-empty string';
  }
  
  return null;
}

Future<Map<String, dynamic>> _getCustomerDetails(int customerId) async {
  // Get customer basic info with location names
  final customerResult = await DatabaseService.queryOne(
    '''
    SELECT c.*, g.name AS governorate, ct.name AS city
    FROM customers c
    LEFT JOIN governorates g ON c.governomate_id = g.id
    LEFT JOIN cities ct ON c.city_id = ct.id
    WHERE c.id = ?
    ''',
    parameters: [customerId],
  );
  
  if (customerResult == null) {
    throw Exception('Customer not found with id: $customerId');
  }
  
  // Get customer phones
  final phonesResult = await DatabaseService.queryMany(
    'SELECT * FROM customer_phones WHERE customer_id = ? ORDER BY created_at ASC',
    parameters: [customerId],
  );
  
  // Get customer calls
  final callsResult = await DatabaseService.queryMany(
    '''
    SELECT cc.*, cat.name AS categoryName, u.name AS createdByName
    FROM customercall cc
    LEFT JOIN users u ON cc.created_by = u.id
    LEFT JOIN call_categories cat ON cc.category_id = cat.id
    WHERE cc.customer_id = ?
    ORDER BY cc.created_at DESC
    ''',
    parameters: [customerId],
  );
  
  return {
    'id': customerResult['id'],
    'companyId': customerResult['company_id'],
    'name': customerResult['name'],
    'address': customerResult['address'],
    'notes': customerResult['notes']?.toString(),
    'governorate': customerResult['governorate'],
    'city': customerResult['city'],
    'phones': phonesResult.map((phone) => {
      'id': phone['id'],
      'phone': phone['phone'],
      'phoneType': phone['phone_type'],
      'createdAt': phone['created_at']?.toString(),
    }).toList(),
    'calls': callsResult.map((call) => {
      'id': call['id'],
      'callType': call['call_type'],
      'category': call['categoryName'],
      'description': call['description']?.toString(),
      'notes': call['call_notes']?.toString(),
      'callDuration': call['call_duration'],
      'createdBy': call['createdByName'],
      'createdAt': call['created_at']?.toString(),
    }).toList(),
    'tickets': [], // Empty for new customer
    'createdAt': customerResult['created_at']?.toString(),
    'updatedAt': customerResult['updated_at']?.toString(),
  };
}

int _getPhoneTypeId(String? phoneType) {
  final type = phoneType?.toLowerCase() ?? 'mobile';
  switch (type) {
    case 'mobile':
      return 1;
    case 'work':
      return 2;
    case 'home':
      return 3;
    default:
      return 1;
  }
}

int _getCallTypeId(String? callType) {
  final type = callType?.toLowerCase() ?? 'incoming';
  switch (type) {
    case 'incoming':
      return 0;
    case 'outgoing':
      return 1;
    default:
      return 0;
  }
}