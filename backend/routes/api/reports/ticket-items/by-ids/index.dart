import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';
import 'dart:convert';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.post => await _handlePost(context),
    HttpMethod.options => _handleOptions(),
    _ => _handleMethodNotAllowed(),
  };
}

Response _handleOptions() {
  return Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

Response _handleMethodNotAllowed() {
  return Response(
    statusCode: 405,
    body: 'Method not allowed',
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

Future<Response> _handlePost(RequestContext context) async {
  try {
    final request = context.request;
    final body = await request.json() as Map<String, dynamic>;
    
    final ticketIds = body['ticketIds'] as List<dynamic>?;
    
    if (ticketIds == null || ticketIds.isEmpty) {
      return Response(
        statusCode: 400,
        body: '{"success": false, "error": "ticketIds is required and must not be empty"}',
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      );
    }
    
    final List<int> ids = ticketIds.map((id) => id as int).toList();
    final tickets = await _getTicketsByIds(ids);
    
    // Log activity for getting ticket items by IDs
    try {
      final jwtPayload = context.read<dynamic>();
      int userId = 1; // Default fallback
      if (jwtPayload is Map<String, dynamic>) {
        userId = jwtPayload['id'] as int? ?? 1;
      }
      
      await ActivityLogService.log(
        entityId: 4, // ticket_items entity
        recordId: 0, // General report, no specific record
        activityId: 306, // Get ticket items by IDs
        userId: userId,
      );
    } catch (e) {
      print('Failed to log get ticket items by IDs activity: $e');
    }
    
    return Response(
      statusCode: 200,
      body: jsonEncode({
        'success': true,
        'tickets': tickets,
      }),
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    );
    
  } catch (e) {
    print('Get tickets by IDs error: $e');
    return Response(
      statusCode: 500,
      body: '{"success": false, "error": "Internal server error: ${e.toString()}"}',
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    );
  }
}

Future<List<Map<String, dynamic>>> _getTicketsByIds(List<int> ticketIds) async {
  if (ticketIds.isEmpty) return [];
  
  final placeholders = ticketIds.map((_) => '?').join(',');
  
  final query = '''
    SELECT DISTINCT
      t.id,
      c.name as customerName,
      comp.name as companyName,
      g.name as governorateName,
      city.name as cityName,
      c.address,
      t.description,
      t.printing_notes as printingNotes,
      u.name as createdByName,
      c.id as customerId
    FROM tickets t
    LEFT JOIN customers c ON t.customer_id = c.id
    LEFT JOIN companies comp ON c.company_id = comp.id
    LEFT JOIN governorates g ON c.governomate_id = g.id
    LEFT JOIN cities city ON c.city_id = city.id
    LEFT JOIN users u ON t.created_by = u.id
    WHERE t.id IN ($placeholders)
    ORDER BY t.id
  ''';
  
  print('Executing query for ticket IDs: $ticketIds');
  final results = await DatabaseService.query(query, parameters: ticketIds, userId: 1);
  print('Query returned ${results.length} results');
  
     // Debug: Print first row to see what we're getting
   if (results.isNotEmpty) {
     print('First row data:');
     final firstRow = results.first;
     print('  id: ${firstRow['id']} (${firstRow['id']?.runtimeType})');
     print('  customerName: ${firstRow['customerName']} (${firstRow['customerName']?.runtimeType})');
     print('  governorateName: ${firstRow['governorateName']} (${firstRow['governorateName']?.runtimeType})');
     print('  cityName: ${firstRow['cityName']} (${firstRow['cityName']?.runtimeType})');
     print('  address: ${firstRow['address']} (${firstRow['address']?.runtimeType})');
     print('  createdByName: ${firstRow['createdByName']} (${firstRow['createdByName']?.runtimeType})');
     print('  customerId: ${firstRow['customerId']} (${firstRow['customerId']?.runtimeType})');
   }
  
  final List<Map<String, dynamic>> tickets = [];
  
  for (final row in results) {
    try {
      final ticketId = row['id'] as int;
      print('Processing ticket ID: $ticketId');
      
             final phones = await _getCustomerPhones(row['customerId'] as int?);
      final items = await _getTicketItems(ticketId);
      
             final ticketData = {
        'id': ticketId,
        'customerName': row['customerName']?.toString() ?? '',
        'governorateName': row['governorateName']?.toString() ?? '',
        'cityName': row['cityName']?.toString() ?? '',
        'adress': row['address']?.toString() ?? '',
        'phones': phones,
        'createdByName': row['createdByName']?.toString() ?? '',
        'printingNotes': row['printingNotes']?.toString() ?? '',
        'items': items,
      };
       
               print('Ticket data for ID $ticketId:');
        print('  Customer: ${ticketData['customerName']}');
        print('  Phones count: ${phones.length}');
       
       tickets.add(ticketData);
      
      print('Successfully processed ticket $ticketId');
    } catch (e) {
      print('Error processing ticket row: $e');
      print('Row data: $row');
      // Continue with other tickets instead of failing completely
      continue;
    }
  }
  
  print('Successfully processed ${tickets.length} tickets');
  return tickets;
}

Future<List<String>> _getCustomerPhones(int? customerId) async {
  if (customerId == null) return [];
  
  final query = '''
    SELECT DISTINCT cp.phone
    FROM customer_phones cp
    WHERE cp.customer_id = ?
    AND cp.phone IS NOT NULL
    AND cp.phone != ''
  ''';
  
  final results = await DatabaseService.query(query, parameters: [customerId], userId: 1);
  return results.map((row) => row['phone']?.toString() ?? '').where((phone) => phone.isNotEmpty).toList();
}

Future<List<Map<String, dynamic>>> _getTicketItems(int ticketId) async {
  final query = '''
    SELECT 
      pi.product_name as productName,
      ti.product_size as productSize,
      ti.quantity,
      ti.purchase_date as purchaseDate,
      ti.purchase_location as purchaseLocation,
      rr.name as requestReasonName,
      ti.request_reason_detail as requestReasonDetail
    FROM ticket_items ti
    LEFT JOIN product_info pi ON ti.product_id = pi.id
    LEFT JOIN request_reasons rr ON ti.request_reason_id = rr.id
    WHERE ti.ticket_id = ?
    ORDER BY ti.id
  ''';
  
  print('Getting ticket items for ticket ID: $ticketId');
  final results = await DatabaseService.query(query, parameters: [ticketId], userId: 1);
  print('Found ${results.length} ticket items for ticket $ticketId');
  
  final List<Map<String, dynamic>> items = [];
  
  for (final row in results) {
    try {
      // Handle purchase date safely - it might be a Blob or DateTime
      String purchaseDate = '';
      try {
        if (row['purchaseDate'] != null) {
          print('Purchase date type: ${row['purchaseDate'].runtimeType}');
          if (row['purchaseDate'] is DateTime) {
            purchaseDate = (row['purchaseDate'] as DateTime).toIso8601String().split('T')[0];
          } else if (row['purchaseDate'] is String) {
            purchaseDate = row['purchaseDate'] as String;
          } else {
            // Try to convert Blob or other types to string
            purchaseDate = row['purchaseDate'].toString();
          }
        }
      } catch (e) {
        print('Error processing purchase date: $e');
        purchaseDate = '';
      }

      final item = {
        'productName': row['productName']?.toString() ?? '',
        'productSize': row['productSize']?.toString() ?? '',
        'quantity': row['quantity'] is int ? row['quantity'] as int : 0,
        'purchaseDate': purchaseDate,
        'purchaseLocation': row['purchaseLocation']?.toString() ?? '',
        'requestReasonName': row['requestReasonName']?.toString() ?? '',
        'requestReasonDetail': row['requestReasonDetail']?.toString() ?? '',
      };
      
      items.add(item);
      print('Successfully processed ticket item');
    } catch (e) {
      print('Error processing ticket item row: $e');
      print('Row data: $row');
      // Continue with other items instead of failing completely
      continue;
    }
  }
  
  print('Successfully processed ${items.length} ticket items');
  return items;
}
