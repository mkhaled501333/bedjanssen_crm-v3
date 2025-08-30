import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => await _handleGet(context, id),
    HttpMethod.put => await _handlePut(context, id),
    HttpMethod.options => _handleOptions(),
    _ => Response(statusCode: 405, body: 'Method not allowed'),
  };
}

Response _handleOptions() {
  return Response(
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

Future<Response> _handleGet(RequestContext context, String id) async {
  try {
    // Validate customer ID
    final customerId = int.tryParse(id);
    if (customerId == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Invalid customer ID format',
          'error': 'Customer ID must be a valid integer',
        },
      );
    }
    
    // Get customer details using the same approach as
    // customer_remote_data_source.dart
    final customerData = await _getCustomerById(customerId);
    
    if (customerData == null) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Customer not found',
          'error': 'No customer found with the provided ID',
        },
      );
    }
    
    // Log activity for getting customer details
    try {
      final jwtPayload = context.read<dynamic>();
      int userId = 1; // Default fallback
      if (jwtPayload is Map<String, dynamic>) {
        userId = jwtPayload['id'] as int? ?? 1;
      }
      
      await ActivityLogService.log(
        entityId: 2, // customers entity
        recordId: customerId,
        activityId: 100, // Get customer details
        userId: userId,
      );
    } catch (e) {
      print('Failed to log get customer details activity: $e');
    }
    
    return Response.json(
      body: {
        'success': true,
        'data': customerData,
        'message': 'Customer details retrieved successfully',
      },
    );
    
  } catch (e) {
    // ignore: avoid_print
    print('Get customer details error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while '
            'retrieving customer details',
        'error': e.toString(),
      },
    );
  }
}

Future<Response> _handlePut(RequestContext context, String id) async {
  try {
    // Validate customer ID
    final customerId = int.tryParse(id);
    if (customerId == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Invalid customer ID format',
          'error': 'Customer ID must be a valid integer',
        },
      );
    }
    
    final request = context.request;
    final body = await request.json() as Map<String, dynamic>;
    
    // Validate request body
    final validationError = _validateUpdateCustomerRequest(body);
    if (validationError != null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': validationError,
          'error': 'Validation failed',
        },
      );
    }
    
    // Check if customer exists
    final existingCustomer = await _getCustomerBasicInfo(customerId);
    if (existingCustomer == null) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Customer not found',
          'error': 'No customer found with the provided ID',
        },
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

    // Track which fields are being updated for activity logging
    final Map<String, int> activityMap = {
      'name': 112, // Update customer name
      'address': 113, // Update customer address
      'notes': 114, // Update customer notes
      'governorateId': 115, // Update customer governorate
      'cityId': 116, // Update customer city
    };

    // Update customer information
    await DatabaseService.query(
      '''
      UPDATE customers 
      SET name = ?, address = ?, notes = ?, governomate_id = ?, city_id = ?, updated_at = NOW()
      WHERE id = ?
      ''',
      parameters: [
        body['name'] ?? existingCustomer['name'],
        body['address'] ?? existingCustomer['address'],
        body['notes'] ?? existingCustomer['notes'],
        body['governorateId'] ?? existingCustomer['governomate_id'],
        body['cityId'] ?? existingCustomer['city_id'],
        customerId,
      ],
      userId: userId,
    );

    // Log activities for updated fields
    for (final entry in activityMap.entries) {
      final fieldName = entry.key;
      final activityId = entry.value;
      
      // Check if this field was actually updated
      bool fieldUpdated = false;
      switch (fieldName) {
        case 'name':
          fieldUpdated = body['name'] != null && body['name'] != existingCustomer['name'];
          break;
        case 'address':
          fieldUpdated = body['address'] != null && body['address'] != existingCustomer['address'];
          break;
        case 'notes':
          fieldUpdated = body['notes'] != null && body['notes'] != existingCustomer['notes'];
          break;
        case 'governorateId':
          fieldUpdated = body['governorateId'] != null && body['governorateId'] != existingCustomer['governomate_id'];
          break;
        case 'cityId':
          fieldUpdated = body['cityId'] != null && body['cityId'] != existingCustomer['city_id'];
          break;
      }
      
      if (fieldUpdated) {
        try {
          await ActivityLogService.log(
            entityId: 2, // customers entity
            recordId: customerId,
            activityId: activityId,
            userId: userId,
          );
        } catch (e) {
          print('Failed to log activity for $fieldName update: $e');
        }
      }
    }
    
    // Get updated customer details
    final updatedCustomer = await _getCustomerById(customerId);
    
    return Response.json(
      body: {
        'success': true,
        'data': updatedCustomer,
        'message': 'Customer information updated successfully',
      },
    );
    
  } catch (e) {
    // ignore: avoid_print
    print('Update customer error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error occurred while updating customer',
        'error': e.toString(),
      },
    );
  }
}

String? _validateUpdateCustomerRequest(Map<String, dynamic> body) {
  // All fields are optional for update, but if provided, they should be valid
  if (body['name'] != null &&
      (body['name'] is! String ||
          (body['name'] as String).trim().isEmpty)) {
    return 'name must be a non-empty string if provided';
  }
  
  if (body['governorateId'] != null && body['governorateId'] is! int) {
    return 'governorateId must be an integer if provided';
  }
  
  if (body['cityId'] != null && body['cityId'] is! int) {
    return 'cityId must be an integer if provided';
  }
  
  return null;
}

// Main method to get customer by ID - similar to customer_remote_data_source.dart
Future<Map<String, dynamic>?> _getCustomerById(int customerId) async {
  try {
    // Get basic customer data
    final customerData = await _getCustomer(customerId);
    if (customerData == null) {
      return null;
    }
    
    // Get customer phones
    final phones = await _getCustomerPhones(customerId);
    
    // Get customer tickets
    final tickets = await _getCustomerTickets(customerId);
    
    // Get customer calls
    final calls = await _getCustomerCalls(customerId);
    
    // Create the customer entity similar to customer_remote_data_source.dart
    return {
      'id': customerData['id'],
      'companyId': customerData['company_id'],
      'name': _blobToString(customerData['name']),
      'phones': phones,
      'tickets': tickets,
      'calls': calls,
      'address': _blobToString(customerData['address']),
      'notes': _blobToString(customerData['notes']),
      'governorate': _blobToString(customerData['governorate']),
      'city': _blobToString(customerData['city']),
      'createdBy': _blobToString(customerData['createdByName']),
      'createdAt': customerData['created_at']?.toString(),
      'updatedAt': customerData['updated_at']?.toString(),
    };
    
  } catch (e) {
    // ignore: avoid_print
    print('Error in _getCustomerById: $e');
    return null;
  }
}

// Get basic customer data with location names
Future<Map<String, dynamic>?> _getCustomer(int customerId) async {
  try {
    final result = await DatabaseService.queryOne(
      '''
      SELECT
          c.id,
          c.company_id,
          c.name,
          c.address,
          c.notes,
          g.name AS governorate,
          ct.name AS city,
          u.name AS createdByName,
          c.created_at,
          c.updated_at,
          c.governomate_id,
          c.city_id
      FROM customers c
      LEFT JOIN users u ON c.created_by = u.id
      LEFT JOIN governorates g ON c.governomate_id = g.id
      LEFT JOIN cities ct ON c.city_id = ct.id
      WHERE c.id = ?
      ''',
      parameters: [customerId],
    );
    
    if (result == null) {
      return null;
    }
    
    // Convert ResultRow to Map<String, dynamic>
    return {
      'id': result['id'],
      'company_id': result['company_id'],
      'name': result['name'],
      'address': result['address'],
      'notes': result['notes'],
      'governorate': result['governorate'],
      'city': result['city'],
      'createdByName': result['createdByName'],
      'created_at': result['created_at'],
      'updated_at': result['updated_at'],
    };
  } catch (e) {
    // ignore: avoid_print
    print('Error in _getCustomer: $e');
    return null;
  }
}

// Get customer phones
Future<List<Map<String, dynamic>>> _getCustomerPhones(int customerId) async {
  try {
    final phonesResult = await DatabaseService.queryMany(
      '''
      SELECT
          cp.id,
          cp.company_id,
          cp.customer_id,
          cp.phone,
          cp.phone_type AS phoneType,
          u.name as createdByName,
          cp.created_at,
          cp.updated_at
      FROM customer_phones cp
      LEFT JOIN users u ON cp.created_by = u.id
      WHERE cp.customer_id = ?
      ORDER BY cp.created_at ASC
      ''',
      parameters: [customerId],
    );
    
    return phonesResult.map((phone) => {
      'id': phone['id'],
      'companyId': phone['company_id'],
      'customerId': phone['customer_id'],
      'phone': _blobToString(phone['phone']),
      'phoneType': _blobToString(phone['phoneType']),
      'createdBy': _blobToString(phone['createdByName']),
      'createdAt': phone['created_at']?.toString(),
      'updatedAt': phone['updated_at']?.toString(),
    }).toList();
  } catch (e) {
    // ignore: avoid_print
    print('Error in _getCustomerPhones: $e');
    return [];
  }
}

// Get customer tickets with items and calls
Future<List<Map<String, dynamic>>> _getCustomerTickets(int customerId) async {
  try {
    final ticketsResult = await DatabaseService.queryMany(
      '''
      SELECT
          t.id,
          t.company_id,
          t.customer_id,
          t.description,
          t.status,
          t.priority,
          t.ticket_cat_id,
          u.name as createdByName,
          cat.name AS categoryName,
          t.created_at,
          t.updated_at,
          t.closed_at
      FROM tickets t
      LEFT JOIN users u ON t.created_by = u.id
      LEFT JOIN ticket_categories cat ON t.ticket_cat_id = cat.id
      WHERE t.customer_id = ?
      ORDER BY t.created_at DESC
      ''',
      parameters: [customerId],
    );
    
    final ticketsWithItems = <Map<String, dynamic>>[];
    for (final ticket in ticketsResult) {
      final ticketId = ticket['id'] as int;
      final items = await _getTicketItems(ticketId);
      final calls = await _getTicketCalls(ticketId);
      
      ticketsWithItems.add({
        'ticketID': ticket['id'],
        'companyId': ticket['company_id'],
        'customerId': ticket['customer_id'],
        'ticketCat': _blobToString(ticket['categoryName']),
        'ticketCatId': ticket['ticket_cat_id'],
        'description': _blobToString(ticket['description']),
        'status': ticket['status'],
        'priority': ticket['priority'],
        'createdBy': _blobToString(ticket['createdByName']),
        'closedAt': ticket['closed_at']?.toString(),
        'ticketItems': items,
        'calls': calls,
        'createdAt': ticket['created_at']?.toString(),
        'updatedAt': ticket['updated_at']?.toString(),
      });
    }
    
    return ticketsWithItems;
  } catch (e) {
    // ignore: avoid_print
    print('Error in _getCustomerTickets: $e');
    return [];
  }
}

// Get ticket items
Future<List<Map<String, dynamic>>> _getTicketItems(int ticketId) async {
  try {
    List<dynamic> itemsResult = [];
    
    try {
      // Try detailed query first
      itemsResult = await DatabaseService.queryMany(
        '''
        SELECT 
            ti.*, 
            c.name as product_brand, 
            p.product_name, 
            rr.name AS request_reason_name,
            maint.ticket_item_id AS maintenance_id,
            maint.maintenance_steps,
            maint.maintenance_cost,
            maint.client_approval AS maintenance_client_approval,
            maint.refusal_reason AS maintenance_refusal_reason,
            maint.pulled AS maintenance_pulled,
            maint.pull_date AS maintenance_pull_date,
            maint.delivered AS maintenance_delivered,
            maint.delivery_date AS maintenance_delivery_date,
            cs.ticket_item_id AS changesame_id,
            cs.product_size AS changesame_product_size,
            cs.cost AS changesame_cost,
            cs.client_approval AS changesame_client_approval,
            cs.refusal_reason AS changesame_refusal_reason,
            cs.pulled AS changesame_pulled,
            cs.pull_date AS changesame_pull_date,
            cs.delivered AS changesame_delivered,
            cs.delivery_date AS changesame_delivery_date,
            ca.ticket_item_id AS changeanother_id,
            ca.product_id AS changeanother_product_id,
            new_p_info.company_id AS changeanother_brand_id,
            ca.product_size AS changeanother_product_size,
            ca.cost AS changeanother_cost,
            ca.client_approval AS changeanother_client_approval,
            ca.refusal_reason AS changeanother_refusal_reason,
            ca.pulled AS changeanother_pulled,
            ca.pull_date AS changeanother_pull_date,
            ca.delivered AS changeanother_delivered,
            ca.delivery_date AS changeanother_delivery_date
        FROM ticket_items ti
        LEFT JOIN product_info p ON ti.product_id = p.id
        LEFT JOIN companies c ON p.company_id = c.id
        LEFT JOIN request_reasons rr ON ti.request_reason_id = rr.id
        LEFT JOIN ticket_item_maintenance maint ON ti.id = maint.ticket_item_id
        LEFT JOIN ticket_item_change_same cs ON ti.id = cs.ticket_item_id
        LEFT JOIN ticket_item_change_another ca ON ti.id = ca.ticket_item_id
        LEFT JOIN product_info new_p_info ON ca.product_id = new_p_info.id
        WHERE ti.ticket_id = ?
        ORDER BY ti.created_at ASC
        ''',
        parameters: [ticketId],
      );
    } catch (e) {
      // ignore: avoid_print
      print('Detailed ticket items query failed: $e, '
          'falling back to simple query');
      // Fall back to simple query without JOINs
      try {
        itemsResult = await DatabaseService.queryMany(
          'SELECT * FROM ticket_items WHERE ticket_id = ? '
              'ORDER BY created_at ASC',
          parameters: [ticketId],
        );
      } catch (e2) {
        // ignore: avoid_print
        print('Simple ticket items query also failed: $e2');
        itemsResult = [];
      }
    }
    
    return itemsResult.map((item) {
      Map<String, dynamic>? actionFormData;
      String? actionType;

      if (item['maintenance_id'] != null) {
        actionType = 'maintenance';
        actionFormData = {
          'maintenanceSteps': _blobToString(item['maintenance_steps']),
          'maintenanceCost': item['maintenance_cost'],
          'clientApproval': item['maintenance_client_approval'] == 1 ? 'approved' : (item['maintenance_client_approval'] == 0 ? 'rejected' : null),
          'refusalReason': _blobToString(item['maintenance_refusal_reason']),
          'pulled': item['maintenance_pulled'] == 1,
          'pullDate': item['maintenance_pull_date']?.toString().substring(0,10),
          'delivered': item['maintenance_delivered'] == 1,
          'deliveryDate': item['maintenance_delivery_date']?.toString().substring(0,10),
        };
      } else if (item['changesame_id'] != null) {
          actionType = 'change-same';
          actionFormData = {
            'productSize': _blobToString(item['changesame_product_size']),
            'cost': item['changesame_cost'],
            'clientApproval': item['changesame_client_approval'] == 1 ? 'approved' : (item['changesame_client_approval'] == 0 ? 'rejected' : null),
            'refusalReason': _blobToString(item['changesame_refusal_reason']),
            'pulled': item['changesame_pulled'] == 1,
            'pullDate': item['changesame_pull_date']?.toString().substring(0,10),
            'delivered': item['changesame_delivered'] == 1,
            'deliveryDate': item['changesame_delivery_date']?.toString().substring(0,10),
          };
      } else if (item['changeanother_id'] != null) {
          actionType = 'change-another';
          actionFormData = {
            'brandId': item['changeanother_brand_id'],
            'productId': item['changeanother_product_id'],
            'productSize': _blobToString(item['changeanother_product_size']),
            'cost': item['changeanother_cost'],
            'clientApproval': item['changeanother_client_approval'] == 1 ? 'approved' : (item['changeanother_client_approval'] == 0 ? 'rejected' : null),
            'refusalReason': _blobToString(item['changeanother_refusal_reason']),
            'pulled': item['changeanother_pulled'] == 1,
            'pullDate': item['changeanother_pull_date']?.toString().substring(0,10),
            'delivered': item['changeanother_delivered'] == 1,
            'deliveryDate': item['changeanother_delivery_date']?.toString().substring(0,10),
          };
      }

      return {
      'id': item['id'],
      'ticketItemID': item['id'],
      'companyId': item['company_id'],
      'ticketId': item['ticket_id'],
      'productId': item['product_id'],
      'productBrand': _blobToString(item['product_brand']),
      'productName': _blobToString(item['product_name']) != '' ? _blobToString(item['product_name']) : 'Product ID: ${item['product_id']}',
      'productSize': _blobToString(item['product_size']),
      'quantity': item['quantity'],
      'purchaseDate': item['purchase_date']?.toString(),
      'purchaseLocation': _blobToString(item['purchase_location']),
      'requestReasonId': item['request_reason_id'],
      'requestReason': _blobToString(item['request_reason_name']),
      'requestReasonDetail': _blobToString(item['request_reason_detail']),
      'inspected': item['inspected'] == 1,
      'inspectionDate': item['inspection_date']?.toString(),
      'inspectionResult': _blobToString(item['inspection_result']),
        'actionType': actionType,
        'actionFormData': actionFormData,
      'createdAt': item['created_at']?.toString(),
      'updatedAt': item['updated_at']?.toString(),
      };
    }).toList();
  } catch (e) {
    // ignore: avoid_print
    print('Error in _getTicketItems: $e');
    return [];
  }
}

// Get ticket calls
Future<List<Map<String, dynamic>>> _getTicketCalls(int ticketId) async {
  try {
    final callsResult = await DatabaseService.queryMany(
      '''
      SELECT tc.*, cat.name AS categoryName, u.name AS createdByName
      FROM ticketcall tc
      LEFT JOIN users u ON tc.created_by = u.id
      LEFT JOIN call_categories cat ON tc.call_cat_id = cat.id
      WHERE tc.ticket_id = ?
      ORDER BY tc.created_at DESC
      ''',
      parameters: [ticketId],
    );
    
    return callsResult.map((call) => {
      'id': call['id'],
      'companyId': call['company_id'],
      'ticketId': call['ticket_id'],
      'callType': _blobToString(call['call_type']),
      'categoryId': call['call_cat_id'],
      'category': _blobToString(call['categoryName']),
      'description': _blobToString(call['description']),
      'notes': _blobToString(call['call_notes']),
      'callDuration': _blobToString(call['call_duration']),
      'createdBy': _blobToString(call['createdByName']),
      'createdAt': call['created_at']?.toString(),
      'updatedAt': call['updated_at']?.toString(),
    }).toList();
  } catch (e) {
    // ignore: avoid_print
    print('Error in _getTicketCalls: $e');
    return [];
  }
}

// Get customer calls
Future<List<Map<String, dynamic>>> _getCustomerCalls(int customerId) async {
  try {
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
    
    return callsResult.map((call) => {
      'id': call['id'],
      'companyId': call['company_id'],
      'customerId': call['customer_id'],
      'callType': _blobToString(call['call_type']),
      'categoryId': call['category_id'],
      'category': _blobToString(call['categoryName']),
      'description': _blobToString(call['description']),
      'notes': _blobToString(call['call_notes']),
      'callDuration': _blobToString(call['call_duration']),
      'createdBy': _blobToString(call['createdByName']),
      'createdAt': call['created_at']?.toString(),
      'updatedAt': call['updated_at']?.toString(),
    }).toList();
  } catch (e) {
    // ignore: avoid_print
    print('Error in _getCustomerCalls: $e');
    return [];
  }
}

// Get basic customer data - used for updates to get existing values
Future<Map<String, dynamic>?> _getCustomerBasicInfo(int customerId) async {
  try {
    final result = await DatabaseService.queryOne(
      '''
      SELECT name, address, notes, governomate_id, city_id, created_by 
      FROM customers 
      WHERE id = ?
      ''',
      parameters: [customerId],
    );
    
    if (result != null) {
      // Convert Blob fields to strings for proper comparison
      return {
        'name': _blobToString(result['name']),
        'address': _blobToString(result['address']),
        'notes': _blobToString(result['notes']),
        'governomate_id': result['governomate_id'],
        'city_id': result['city_id'],
        'created_by': result['created_by'],
      };
    }
    return null;
    
  } catch (e) {
    print('Error in _getCustomerBasicInfo: $e');
    return null;
  }
}

String _blobToString(dynamic value) {
  if (value == null) {
    return '';
  }
  
  if (value.runtimeType.toString() == 'Blob') {
    try {
      if (value is List<int>) {
        return utf8.decode(value);
      }
      // The mysql_client's Blob.toString() might return something useful.
      // If not, we have the catch-all below.
      return value.toString();
    } catch (e) {
      return 'Error decoding blob';
    }
  }
  return value.toString();
}
