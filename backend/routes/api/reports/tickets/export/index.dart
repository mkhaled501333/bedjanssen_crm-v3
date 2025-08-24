import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/services/reports/tickets_report_service.dart';
import 'package:janssencrm_backend/services/reports/tickets_utils/validation_utils.dart';
import 'package:janssencrm_backend/services/reports/tickets_utils/response_utils.dart';
import 'dart:convert';
import 'package:excel/excel.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _handleExport(context),
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

/// GET /api/reports/tickets/export - Export tickets report in various formats
Future<Response> _handleExport(RequestContext context) async {
  try {
    final request = context.request;
    final uri = request.uri;
    final queryParams = uri.queryParameters;
    
    // Validate format parameter
    final format = queryParams['format'];
    if (format == null || !['csv', 'excel', 'pdf'].contains(format)) {
      return createErrorResponse(
        statusCode: 400,
        message: 'Invalid or missing format parameter. Supported formats: csv, excel, pdf',
        error: 'Validation failed'
      );
    }
    
    // Extract and validate query parameters (reuse existing validation)
    final validationResult = validateTicketsReportParams(queryParams);
    if (!validationResult.isValid) {
      return createErrorResponse(
        statusCode: 400,
        message: validationResult.errorMessage!,
        error: 'Validation failed'
      );
    }
    
    final params = validationResult.params!;
    
    // Extract additional filter parameters
    final governorate = queryParams['governorate'];
    final city = queryParams['city'];
    
    // Get all tickets (no pagination for export)
    final reportResult = await getTicketsReport(
      companyId: params.companyId,
      page: 1,
      limit: 10000, // Large limit to get all tickets
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
        error: 'Failed to retrieve tickets for export'
      );
    }
    
    final data = reportResult.data!;
    final tickets = data['tickets'] as List<dynamic>;
    
    // Generate export based on format
    switch (format) {
      case 'csv':
        return _generateCsvExport(tickets);
      case 'excel':
        return _generateExcelExport(tickets);
      case 'pdf':
        return _generatePdfExport(tickets);
      default:
        return createErrorResponse(
          statusCode: 400,
          message: 'Unsupported export format',
          error: 'Invalid format'
        );
    }
    
  } catch (e) {
    print('Export tickets report error: $e');
    return createErrorResponse(
      statusCode: 500,
      message: 'Internal server error occurred while exporting tickets report',
      error: e.toString()
    );
  }
}

/// Generate CSV export
Response _generateCsvExport(List<dynamic> tickets) {
  final csvLines = <String>[];
  
  // CSV Header
  csvLines.add('ID,Customer Name,Governorate,City,Category,Description,Status,Created By,Created At,Updated At,Calls Count,Items Count');
  
  // CSV Data
  for (final ticket in tickets) {
    final row = [
      ticket['id']?.toString() ?? '',
      _escapeCsvField(ticket['customerName']?.toString() ?? ''),
      _escapeCsvField(ticket['governorateName']?.toString() ?? ''),
      _escapeCsvField(ticket['cityName']?.toString() ?? ''),
      _escapeCsvField(ticket['categoryName']?.toString() ?? ''),
      _escapeCsvField(ticket['description']?.toString() ?? ''),
      ticket['status']?.toString() ?? '',
      _escapeCsvField(ticket['createdByName']?.toString() ?? ''),
      ticket['createdAt']?.toString() ?? '',
      ticket['updatedAt']?.toString() ?? '',
      ticket['callsCount']?.toString() ?? '0',
      ticket['itemsCount']?.toString() ?? '0',
    ];
    csvLines.add(row.join(','));
  }
  
  final csvContent = csvLines.join('\n');
  final bytes = utf8.encode(csvContent);
  
  return addCorsHeaders(Response.bytes(
    body: bytes,
    statusCode: 200,
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': 'attachment; filename="tickets-report.csv"',
      'Content-Length': bytes.length.toString(),
    },
  ));
}

/// Generate Excel export (proper Excel format using excel package)
Response _generateExcelExport(List<dynamic> tickets) {
  // Create a new Excel workbook
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];
  
  // Add headers
  final headers = [
    'ID', 'Customer Name', 'Governorate', 'City', 'Category', 'Description', 'Status', 
    'Created By', 'Created At', 'Updated At', 'Calls Count', 'Items Count'
  ];
  
  for (int i = 0; i < headers.length; i++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
    cell.value = TextCellValue(headers[i]);
  }
  
  // Add data rows
  for (int rowIndex = 0; rowIndex < tickets.length; rowIndex++) {
    final ticket = tickets[rowIndex];
    final rowData = [
      ticket['id']?.toString() ?? '',
      ticket['customerName']?.toString() ?? '',
      ticket['governorateName']?.toString() ?? '',
      ticket['cityName']?.toString() ?? '',
      ticket['categoryName']?.toString() ?? '',
      ticket['description']?.toString() ?? '',
      ticket['status']?.toString() ?? '',
      ticket['createdByName']?.toString() ?? '',
      ticket['createdAt']?.toString() ?? '',
      ticket['updatedAt']?.toString() ?? '',
      ticket['callsCount']?.toString() ?? '0',
      ticket['itemsCount']?.toString() ?? '0',
    ];
    
    for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1));
      cell.value = TextCellValue(rowData[colIndex]);
    }
  }
  
  // Generate Excel file bytes
  final fileBytes = excel.save();
  
  return addCorsHeaders(Response.bytes(
    body: fileBytes!,
    statusCode: 200,
    headers: {
      'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'Content-Disposition': 'attachment; filename="tickets-report.xlsx"',
      'Content-Length': fileBytes.length.toString(),
    },
  ));
}

/// Generate PDF export (simplified as text for now)
Response _generatePdfExport(List<dynamic> tickets) {
  // For now, return a simple text format
  // In a full implementation, you would use a PDF generation library
  final lines = <String>[];
  
  lines.add('TICKETS REPORT');
  lines.add('=' * 50);
  lines.add('');
  
  for (final ticket in tickets) {
    lines.add('Ticket ID: ${ticket['id']}');
    lines.add('Customer: ${ticket['customerName']}');
    lines.add('Governorate: ${ticket['governorateName']}');
    lines.add('City: ${ticket['cityName']}');
    lines.add('Category: ${ticket['categoryName']}');
    lines.add('Description: ${ticket['description']}');
    lines.add('Status: ${ticket['status']}');
    lines.add('Created By: ${ticket['createdByName']}');
    lines.add('Created At: ${ticket['createdAt']}');
    lines.add('Calls Count: ${ticket['callsCount']}');
    lines.add('Items Count: ${ticket['itemsCount']}');
    lines.add('-' * 30);
  }
  
  final content = lines.join('\n');
  final bytes = utf8.encode(content);
  
  return addCorsHeaders(Response.bytes(
    body: bytes,
    statusCode: 200,
    headers: {
      'Content-Type': 'application/pdf',
      'Content-Disposition': 'attachment; filename="tickets-report.pdf"',
      'Content-Length': bytes.length.toString(),
    },
  ));
}

/// Escape CSV field to handle commas and quotes
String _escapeCsvField(String field) {
  if (field.contains(',') || field.contains('"') || field.contains('\n')) {
    return '"${field.replaceAll('"', '""')}"';
  }
  return field;
}

