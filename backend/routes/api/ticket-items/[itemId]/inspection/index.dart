import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';

Future<Response> onRequest(RequestContext context, String itemId) async {
  return switch (context.request.method) {
    HttpMethod.put => await _handlePut(context, itemId),
    HttpMethod.options => _handleOptions(),
    _ => Response(statusCode: 405, body: 'Method not allowed'),
  };
}

Response _handleOptions() {
  return Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'PUT, OPTIONS',
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
    
    final activityMap = <String, int?>{
      'inspected': null, // Will be determined based on value (622 for true, 623 for false)
      'inspectionDate': 624,
      'inspectionResult': 625,
    };
    
    var inspectionDate = body['inspectionDate'];
    if (inspectionDate is String && inspectionDate.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(inspectionDate);
        inspectionDate = '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}:${parsedDate.second.toString().padLeft(2, '0')}';
      } catch (e) {
        return Response.json(
          statusCode: 400,
          body: {'success': false, 'message': 'Invalid date format for inspectionDate. Expected ISO 8601 format.'},
        );
      }
    } else if (inspectionDate == null || inspectionDate == '') {
      inspectionDate = null;
    }


    await DatabaseService.query(
      '''
      UPDATE ticket_items 
      SET inspected = ?, inspection_date = ?, inspection_result = ?, updated_at = NOW() 
      WHERE id = ?
      ''',
      parameters: [
        body['inspected'] == true ? 1 : 0,
        inspectionDate,
        body['inspectionResult'],
        itId,
      ],
      userId: userId,
    );

    // Log activities for each updated field
      for (final key in body.keys) {
        int? activityId;
        
        if (key == 'inspected') {
          // Determine activity based on inspection status
          final isInspected = body[key] as bool?;
          if (isInspected == true) {
            activityId = 622; // Mark item as inspected
          } else if (isInspected == false) {
            activityId = 623; // Mark item as uninspected
          }
        } else if (key == 'inspectionResult') {
          // Only log inspection result if item is not being marked as uninspected
          final isInspected = body['inspected'] as bool?;
          if (isInspected == false) {
            continue; // Skip inspection result activity when uninspecting
          }
          activityId = activityMap[key];
        } else {
          activityId = activityMap[key];
        }
        
        if (activityId != null) {
          await ActivityLogService.log(
            entityId: 4, // ticket_items
            recordId: itId,
            activityId: activityId,
            userId: userId,
          );
        }
      }

    return Response.json(
      body: {'success': true, 'message': 'Inspection details updated successfully'},
    );

  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Internal server error', 'error': e.toString()},
    );
  }
}