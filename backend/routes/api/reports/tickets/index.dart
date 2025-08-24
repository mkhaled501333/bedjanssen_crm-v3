import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/services/reports/tickets_report_service.dart';
import 'package:janssencrm_backend/services/reports/tickets_utils/validation_utils.dart';
import 'package:janssencrm_backend/services/reports/tickets_utils/response_utils.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _handleGet(context),
    HttpMethod.options => _handleOptions(),
    _ => addCorsHeaders(Response(statusCode: 405, body: 'Method not allowed')),
  };
}

Response _handleOptions() {
  return addCorsHeaders(Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  ));
}

/// GET /api/reports/tickets - Get tickets report for a company with pagination and filtering
Future<Response> _handleGet(RequestContext context) async {
  try {
    final request = context.request;
    final uri = request.uri;
    
    // Extract and validate query parameters
    final validationResult = validateTicketsReportParams(uri.queryParameters);
    if (!validationResult.isValid) {
      return createErrorResponse(
        statusCode: 400,
        message: validationResult.errorMessage!,
        error: 'Validation failed'
      );
    }
    
    final params = validationResult.params!;
    
    // Extract additional filter parameters
    final governorate = uri.queryParameters['governorate'];
    final city = uri.queryParameters['city'];
    
    // Get tickets report
    final reportResult = await getTicketsReport(
      companyId: params.companyId,
      page: params.page,
      limit: params.limit,
      status: params.status,
      categoryId: params.categoryId,
      customerId: params.customerId,
      startDate: params.startDate,
      endDate: params.endDate,
      searchTerm: params.searchTerm,
      governorate: governorate,
      city: city,
      productName: params.productName,
      companyName: params.companyName,
      requestReasonName: params.requestReasonName,
      inspected: params.inspected,
    );
    
    if (!reportResult.success) {
      return createErrorResponse(
        statusCode: 500,
        message: reportResult.errorMessage!,
        error: 'Failed to retrieve tickets report'
      );
    }
    
    return createSuccessResponse(
      data: reportResult.data!,
      message: 'Tickets report retrieved successfully'
    );
    
  } catch (e) {
    print('Get tickets report error: $e');
    return createErrorResponse(
      statusCode: 500,
      message: 'Internal server error occurred while retrieving tickets report',
      error: e.toString()
    );
  }
}