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
    final validationError = _validateCreateCustomerWithTicketRequest(body);
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
    final ticket = body['ticket'] as Map<String, dynamic>;
    
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
        );
      }
      
      // Insert ticket
      final ticketResult = await DatabaseService.query(
        '''
        INSERT INTO tickets (company_id, customer_id, ticket_cat_id, status, priority, description, created_by, created_at, updated_at) 
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
        ''' ,
        parameters: [
          companyId,
          newCustomerId,
          ticket['ticketCatId'],
          _getTicketStatusId(ticket['status'] as String?),
          _getTicketPriorityId(ticket['priority'] as String?),
          ticket['description'] ?? '',
          userId,
        ],
      );
      
      final ticketId = ticketResult.insertId!;
      
      // Insert ticket call if provided
      if (ticket.containsKey('ticketCall') && ticket['ticketCall'] != null) {
        final ticketCall = ticket['ticketCall'] as Map<String, dynamic>;
        final callType = (ticketCall['callType'] as String).toLowerCase() == 'incoming' ? 0 : 1;
        await DatabaseService.query(
          '''
          INSERT INTO ticketcall (
            company_id, ticket_id, call_type, call_cat_id, description, call_notes,
            call_duration, created_by, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
          ''',
          parameters: [
            companyId,
            ticketId,
            callType,
            ticketCall['callCatId'],
            ticketCall['description'],
            ticketCall['callNotes'] ?? '',
            ticketCall['callDuration'] ?? 0,
            userId,
          ],
        );
      }
      
      // Insert ticket items if provided
      if (ticket['ticketItems'] != null) {
        final ticketItems = ticket['ticketItems'] as List<dynamic>;
        for (final itemData in ticketItems) {
          final itemMap = itemData as Map<String, dynamic>;
          await DatabaseService.query(
            '''
            INSERT INTO ticket_items (company_id, ticket_id, product_id, product_size, quantity, purchase_date, purchase_location, request_reason_id, request_reason_detail, inspected, inspection_date, inspection_result, client_approval, created_by, created_at, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
            ''',
            parameters: [
              companyId,
              ticketId,
              itemMap['productId'],
              itemMap['productSize']?.toString() ?? '',
              itemMap['quantity'] ?? 1,
              itemMap['purchaseDate'],
              itemMap['purchaseLocation'],
              itemMap['requestReasonId'],
              itemMap['requestReasonDetail'],
              false, // inspected
              null, // inspection_date
              null, // inspection_result
              0, // client_approval
              userId,
            ],
          );
        }
      }
      
      return newCustomerId;
    });
    
    // Log activity for customer creation with ticket (Activity ID: 111)
    try {
      await ActivityLogService.log(
        entityId: 2, // customers entity
        recordId: customerId,
        activityId: 111, // Create customer with ticket
        userId: userId,

      );
    } catch (e) {
      print('Failed to log customer creation activity: $e');
    }
    
    // Return success response with customer ID
    return Response.json(
      statusCode: 201,
      body: {
        'success': true,
        'data': {
          'customerId': customerId,
          'message': 'Customer created successfully with ticket'
        },
        'message': 'Customer and ticket created successfully'
      },
    );
    
  } catch (e) {
    print('Create customer with ticket error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while creating customer with ticket',
        'error': e.toString()
      },
    );
  }
}

String? _validateCreateCustomerWithTicketRequest(Map<String, dynamic> body) {
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
  
  if (body['ticket'] == null || body['ticket'] is! Map) {
    return 'ticket is required and must be an object';
  }
  
  // Validate phones array
  final phones = body['phones'] as List;
  for (final phone in phones) {
    if (phone is! Map || phone['phone'] == null || phone['phone'] is! String) {
      return 'Each phone must have a valid phone string';
    }
  }
  
  // Validate ticket object
  final ticket = body['ticket'] as Map<String, dynamic>;
  if (ticket['ticketCatId'] == null || ticket['ticketCatId'] is! int) {
    return 'ticket.ticketCatId is required and must be an integer';
  }
  
  // Description is now optional
  if (ticket['description'] != null && (ticket['description'] is! String)) {
    return 'ticket.description must be a string if provided';
  }
  
  // Validate ticket items if provided
  if (ticket['ticketItems'] != null) {
    if (ticket['ticketItems'] is! List) {
      return 'ticket.ticketItems must be an array';
    }
    
    final ticketItems = ticket['ticketItems'] as List;
    for (final item in ticketItems) {
      if (item is! Map) {
        return 'Each ticket item must be an object';
      }
      
      final itemMap = item as Map<String, dynamic>;
      if (itemMap['productId'] == null || itemMap['productId'] is! int) {
        return 'Each ticket item must have a valid productId';
      }
      
      if (itemMap['requestReasonId'] == null || itemMap['requestReasonId'] is! int) {
        return 'Each ticket item must have a valid requestReasonId';
      }
    }
  }
  
  return null;
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

int _getTicketStatusId(String? status) {
  final type = status?.toLowerCase() ?? 'open';
  switch (type) {
    case 'open':
      return 0;
    case 'closed':
      return 1;
    default:
      return 0;
  }
}

int _getTicketPriorityId(String? priority) {
  final p = priority?.toLowerCase() ?? 'medium';
  switch (p) {
    case 'low':
      return 0;
    case 'medium':
      return 1;
    case 'high':
      return 2;
    default:
      return 1;
  }
}