import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';

Future<Response> onRequest(RequestContext context, String itemId) async {
  print('maintenance route ');
  return switch (context.request.method) {
    HttpMethod.post => await _handlePost(context, itemId),
    HttpMethod.put => await _handlePut(context, itemId),
    HttpMethod.delete => await _handleDelete(context, itemId),
    HttpMethod.options => _handleOptions(),
    _ => Response(statusCode: 405, body: 'Method not allowed'),
  };
}

Response _handleOptions() {
  return Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

Future<Response> _handlePut(RequestContext context, String itemId) async {
  try {
    final itId = int.tryParse(itemId);
    if (itId == null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Invalid item ID format'},
      );
    }
    
    final body = await context.request.json() as Map<String, dynamic>;
    print(body);
    final userId = body['userId'] as int? ?? 1; // Default to 1 if not provided

    final queryParts = <String>[];
    final params = <dynamic>[];
    final activityMap = <String, int>{
      'maintenanceSteps': 627,
      'maintenanceCost': 628,
      'clientApproval': 629,
      'refusalReason': 630,
      'pullDate': 632,
      'deliveryDate': 634,
    };

    if (body.containsKey('maintenanceSteps')) {
      queryParts.add('maintenance_steps = ?');
      params.add(body['maintenanceSteps']);
    }
    if (body.containsKey('maintenanceCost')) {
      queryParts.add('maintenance_cost = ?');
      params.add(body['maintenanceCost']);
    }
    if (body.containsKey('clientApproval')) {
        final rawClientApproval = body['clientApproval'];
        int? clientApproval;

        if (rawClientApproval is String) {
          if (rawClientApproval.toLowerCase() == 'approved') {
            clientApproval = 1;
          } else if (rawClientApproval.toLowerCase() == 'rejected' || rawClientApproval.toLowerCase() == 'refused') {
            clientApproval = 0;
          }
        } else if (rawClientApproval is bool) {
          clientApproval = rawClientApproval ? 1 : 0;
        } else if (rawClientApproval is int) {
          clientApproval = rawClientApproval;
        }
        queryParts.add('client_approval = ?');
        params.add(clientApproval);
    }
    if (body.containsKey('refusalReason')) {
      queryParts.add('refusal_reason = ?');
      params.add(body['refusalReason']);
    }
    // Track special activity IDs for pulled/delivered status changes
    final specialActivities = <int>[];
    
    if (body.containsKey('pulled')) {
      queryParts.add('pulled = ?');
      final pulledValue = body['pulled'] == true ? 1 : 0;
      params.add(pulledValue);
      // Add appropriate activity ID based on pulled status
      specialActivities.add(pulledValue == 1 ? 631 : 636); // 631: Mark maintenance as pulled, 636: Mark maintenance as unpulled
    }
    if (body.containsKey('pullDate')) {
      queryParts.add('pull_date = ?');
      params.add(body['pullDate']);
    }
    if (body.containsKey('delivered')) {
      queryParts.add('delivered = ?');
      final deliveredValue = body['delivered'] == true ? 1 : 0;
      params.add(deliveredValue);
      // Add appropriate activity ID based on delivered status
      specialActivities.add(deliveredValue == 1 ? 633 : 637); // 633: Mark maintenance as delivered, 637: Mark maintenance as undelivered
    }
    if (body.containsKey('deliveryDate')) {
      queryParts.add('delivery_date = ?');
      params.add(body['deliveryDate']);
    }

    if (queryParts.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'No fields to update provided'},
      );
    }

    queryParts.add('updated_at = NOW()');
    params.add(itId);
    
    final result = await DatabaseService.query(
      'UPDATE ticket_item_maintenance SET ${queryParts.join(', ')} WHERE ticket_item_id = ?',
      parameters: params,
      userId: userId,
    );

    if (result.affectedRows == 0) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Maintenance record not found or no changes made'},
      );
    }

    // Log activities for each updated field
    for (final key in body.keys) {
      if (activityMap.containsKey(key)) {
        await ActivityLogService.log(
          entityId: 4, // ticket_items
          recordId: itId,
          activityId: activityMap[key]!,
          userId: userId,
        );
      }
    }
    
    // Log special activities for pulled/delivered status changes
    for (final activityId in specialActivities) {
      await ActivityLogService.log(
        entityId: 4, // ticket_items
        recordId: itId,
        activityId: activityId,
        userId: userId,
      );
    }

    return Response.json(
      body: {'success': true, 'message': 'Maintenance details updated successfully'},
    );

  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Internal server error', 'error': e.toString()},
    );
  }
}

Future<Response> _handlePost(RequestContext context, String itemId) async {
  try {
    final itId = int.tryParse(itemId);
    if (itId == null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Invalid item ID format'},
      );
    }
    
    final body = await context.request.json() as Map<String, dynamic>;
    
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

    final rawClientApproval = body['clientApproval'];
    int? clientApproval;

    if (rawClientApproval is String) {
      if (rawClientApproval.toLowerCase() == 'approved') {
        clientApproval = 1;
      } else if (rawClientApproval.toLowerCase() == 'rejected' || rawClientApproval.toLowerCase() == 'refused') {
        clientApproval = 0;
      }
    } else if (rawClientApproval is bool) {
      clientApproval = rawClientApproval ? 1 : 0;
    } else if (rawClientApproval is int) {
      clientApproval = rawClientApproval;
    }
   
    await DatabaseService.query(
      '''
      INSERT INTO ticket_item_maintenance (ticket_item_id, company_id, maintenance_steps, maintenance_cost, client_approval, refusal_reason, pulled, pull_date, delivered, delivery_date, created_by, created_at, updated_at) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
      ''',
      parameters: [
        itId,
        body['companyId'],
        body['maintenanceSteps'],
        body['maintenanceCost'],
        clientApproval,
        body['refusalReason'],
        body['pulled'],
        body['pullDate'],
        body['delivered'],
        body['deliveryDate'],
        userId,
      ],
      userId: userId,
    );

    // Log activity
    await ActivityLogService.log(
      entityId: 4, // ticket_items
      recordId: itId,
      activityId: 626, // Create maintenance option
      userId: userId,
    );

    return Response.json(
      statusCode: 201,
      body: {'success': true, 'message': 'Maintenance option selected successfully'},
    );

  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Internal server error', 'error': e.toString()},
    );
  }
}

Future<Response> _handleDelete(RequestContext context, String itemId) async {
  try {
    final itId = int.tryParse(itemId);
    if (itId == null) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Invalid item ID format'},
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
    
    await DatabaseService.query(
      'DELETE FROM ticket_item_maintenance WHERE ticket_item_id = ?',
      parameters: [itId],
      userId: userId,
    );

    // Log activity
    await ActivityLogService.log(
      entityId: 4, // ticket_items
      recordId: itId,
      activityId: 635, // Delete maintenance option
      userId: userId,
    );

    return Response.json(
      body: {'success': true, 'message': 'Maintenance selection deleted successfully'},
    );

  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Internal server error', 'error': e.toString()},
    );
  }
}