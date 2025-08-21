import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';

Response _addCorsHeaders(Response response) {
  return response.copyWith(
    headers: {
      ...response.headers,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

Future<Response> onRequest(RequestContext context, String entityName, String recordId) async {
  return switch (context.request.method) {
    HttpMethod.get => await _handleGet(context, entityName, recordId),
    HttpMethod.options => _handleOptions(),
    _ => _addCorsHeaders(Response(statusCode: 405, body: 'Method not allowed')),
  };
}

Response _handleOptions() {
  return _addCorsHeaders(
    Response(
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    ),
  );
}

/// GET /api/activity-logs/entity/{entityName}/{recordId} - Get logs for specific entity record
Future<Response> _handleGet(RequestContext context, String entityName, String recordId) async {
  try {
    // Validate recordId
    final recordIdInt = int.tryParse(recordId);
    if (recordIdInt == null) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 400,
          body: {
            'success': false,
            'message': 'Invalid record ID format',
            'error': 'Record ID must be a valid integer'
          },
        ),
      );
    }
    
    final request = context.request;
    final queryParams = request.uri.queryParameters;
    
    // Parse query parameters
    final userId = queryParams['userId'] != null 
        ? int.tryParse(queryParams['userId']!) 
        : null;
    final activityId = queryParams['activityId'] != null 
        ? int.tryParse(queryParams['activityId']!) 
        : null;
    final fromDate = queryParams['fromDate'] != null 
        ? DateTime.tryParse(queryParams['fromDate']!) 
        : null;
    final toDate = queryParams['toDate'] != null 
        ? DateTime.tryParse(queryParams['toDate']!) 
        : null;
    final limit = queryParams['limit'] != null 
        ? int.tryParse(queryParams['limit']!) 
        : 50; // Default limit
    final offset = queryParams['offset'] != null 
        ? int.tryParse(queryParams['offset']!) 
        : 0; // Default offset
    final detailed = queryParams['detailed'] == 'true';
    
    // Validate limit
    if (limit != null && (limit < 1 || limit > 1000)) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 400,
          body: {
            'success': false,
            'message': 'Limit must be between 1 and 1000',
            'error': 'Invalid limit parameter'
          },
        ),
      );
    }
    
    // Validate offset
    if (offset != null && offset < 0) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 400,
          body: {
            'success': false,
            'message': 'Offset must be non-negative',
            'error': 'Invalid offset parameter'
          },
        ),
      );
    }
    
    // Validate date range
    if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 400,
          body: {
            'success': false,
            'message': 'fromDate must be before toDate',
            'error': 'Invalid date range'
          },
        ),
      );
    }
    
    // Get entity ID by name
    final entities = await ActivityLogService.getEntities();
    final entity = entities.where((e) => e.name == entityName).firstOrNull;
    
    if (entity == null) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 404,
          body: {
            'success': false,
            'message': 'Entity not found: $entityName',
            'error': 'Invalid entity name'
          },
        ),
      );
    }
    
    List<dynamic> activityLogs;
    
    if (detailed) {
      // Get detailed activity logs with entity, activity, and user information
      activityLogs = await ActivityLogService.getDetailedActivityLogs(
        entityId: entity.id,
        recordId: recordIdInt,
        userId: userId,
        activityId: activityId,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
        offset: offset,
      );
    } else {
      // Get basic activity logs
      final logs = await ActivityLogService.getActivityLogs(
        entityId: entity.id,
        recordId: recordIdInt,
        userId: userId,
        activityId: activityId,
        fromDate: fromDate,
        toDate: toDate,
        limit: limit,
        offset: offset,
      );
      activityLogs = logs.map((log) => log.toMap()).toList();
    }
    
    return _addCorsHeaders(
      Response.json(
        statusCode: 200,
        body: {
          'success': true,
          'data': {
            'entity': {
              'id': entity.id,
              'name': entity.name,
            },
            'recordId': recordIdInt,
            'activityLogs': activityLogs,
            'pagination': {
              'limit': limit,
              'offset': offset,
              'hasMore': activityLogs.length == limit,
            },
            'filters': {
              'entityName': entityName,
              'recordId': recordIdInt,
              'userId': userId,
              'activityId': activityId,
              'fromDate': fromDate?.toIso8601String(),
              'toDate': toDate?.toIso8601String(),
              'detailed': detailed,
            },
          },
          'message': 'Activity logs for $entityName record $recordIdInt retrieved successfully',
        },
      ),
    );
  } catch (e) {
    print('Error retrieving activity logs for entity: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {
          'success': false,
          'message': 'Internal server error occurred while retrieving activity logs',
          'error': e.toString(),
        },
      ),
    );
  }
}