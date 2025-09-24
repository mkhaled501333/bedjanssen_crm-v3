import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/services/reports/ticket_items_report_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';
import 'dart:convert';

/// Ticket Items Reports API
/// 
/// Available endpoints:
/// - POST /api/reports/ticket-items - Get ticket items report with dynamic filtering
/// - POST /api/reports/ticket-items/by-ids - Get detailed ticket information by IDs

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

/// POST /api/reports/ticket-items - Get ticket items report with dynamic filtering
Future<Response> _handlePost(RequestContext context) async {
  try {
    final request = context.request;
    final body = await request.json() as Map<String, dynamic>;
    
    final filters = body['filters'] as Map<String, dynamic>? ?? {};
    final page = body['page'] as int? ?? 1;
    final limit = body['limit'] as int? ?? 50;
    
    // Validate required companyId
    if (filters['companyId'] == null) {
      return Response(
        statusCode: 400,
        body: '{"success": false, "error": "companyId is required"}',
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      );
    }
    
    // Get ticket items report with dynamic filtering
    final result = await TicketItemsReportService.getTicketItemsReport(
      companyId: filters['companyId'] as int,
      customerIds: _safeCastToList<int>(filters['customerIds']),
      governomateIds: _safeCastToList<int>(filters['governomateIds']),
      cityIds: _safeCastToList<int>(filters['cityIds']),
      ticketIds: _safeCastToList<int>(filters['ticketIds']),
      companyIds: _safeCastToList<int>(filters['companyIds']),
      ticketCatIds: _safeCastToList<int>(filters['ticketCatIds']),
      ticketStatus: filters['ticketStatus'] as String?,
      productIds: _safeCastToList<int>(filters['productIds']),
      requestReasonIds: _safeCastToList<int>(filters['requestReasonIds']),
      inspected: filters['inspected'] as bool?,
      inspectionDateFrom: filters['inspectionDateFrom'] != null 
        ? DateTime.parse(filters['inspectionDateFrom'] as String) 
        : null,
      inspectionDateTo: filters['inspectionDateTo'] != null 
        ? DateTime.parse(filters['inspectionDateTo'] as String) 
        : null,
      ticketCreatedDateFrom: filters['ticketCreatedDateFrom'] != null 
        ? DateTime.parse(filters['ticketCreatedDateFrom'] as String) 
        : null,
      ticketCreatedDateTo: filters['ticketCreatedDateTo'] != null 
        ? DateTime.parse(filters['ticketCreatedDateTo'] as String) 
        : null,
      actions: _safeCastToStringList(filters['actions']),
      pulledStatus: filters['pulledStatus'] as bool?,
      deliveredStatus: filters['deliveredStatus'] as bool?,
      clientApproval: _safeCastToList<int>(filters['clientApproval']),
      page: page,
      limit: limit,
    );

    // Log activity for getting ticket items report
    try {
      final jwtPayload = context.read<dynamic>();
      int userId = 1; // Default fallback
      if (jwtPayload is Map<String, dynamic>) {
        userId = jwtPayload['id'] as int? ?? 1;
      }
      
      await ActivityLogService.log(
        entityId: 4, // ticket_items entity
        recordId: 0, // General report, no specific record
        activityId: 305, // Get ticket items report
        userId: userId,
      );
    } catch (e) {
      print('Failed to log get ticket items report activity: $e');
    }

    return Response(
      statusCode: result['success'] == true ? 200 : 500,
      body: _convertToJson(result),
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    );
    
  } catch (e) {
    print('Get ticket items report error: $e');
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

/// Helper method to safely cast dynamic values to List<int>
List<int>? _safeCastToList<T>(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    try {
      return value.cast<int>();
    } catch (e) {
      return null;
    }
  }
  return null;
}

/// Helper method to safely cast dynamic values to List<String>
List<String>? _safeCastToStringList(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    try {
      return value.cast<String>();
    } catch (e) {
      return null;
    }
  }
  return null;
}

/// Helper method to convert Map to JSON string
String _convertToJson(Map<String, dynamic> data) {
  try {
    // Use dart:convert for proper JSON serialization
    return jsonEncode(data);
  } catch (e) {
    return '{"success": false, "error": "JSON conversion failed: ${e.toString()}"}';
  }
}
