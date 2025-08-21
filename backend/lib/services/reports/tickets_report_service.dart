import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/reports/tickets_utils/data_transformer.dart';

class TicketsReportResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  TicketsReportResult.success(this.data) : success = true, errorMessage = null;
  TicketsReportResult.error(this.errorMessage) : success = false, data = null;
}

/// Get tickets report with pagination and filtering
Future<TicketsReportResult> getTicketsReport({
  required int companyId,
  required int page,
  required int limit,
  String? status,
  String? priority,
  int? categoryId,
  int? customerId,
  String? startDate,
  String? endDate,
  String? searchTerm,
}) async {
  try {
    // Build WHERE clause and parameters
    final whereConditions = <String>['t.company_id = ?'];
    final parameters = <dynamic>[companyId];
    
    // Add status filter
    if (status != null) {
      final statusValue = DataTransformer.convertStatusToInt(status);
      whereConditions.add('t.status = ?');
      parameters.add(statusValue);
    }
    
    // Add priority filter
    if (priority != null) {
      final priorityValue = DataTransformer.convertPriorityToInt(priority);
      whereConditions.add('t.priority = ?');
      parameters.add(priorityValue);
    }
    
    // Add category filter
    if (categoryId != null) {
      whereConditions.add('t.ticket_cat_id = ?');
      parameters.add(categoryId);
    }
    
    // Add customer filter
    if (customerId != null) {
      whereConditions.add('t.customer_id = ?');
      parameters.add(customerId);
    }
    
    // Add date range filter
    if (startDate != null && endDate != null) {
      whereConditions.add('DATE(t.created_at) >= ? AND DATE(t.created_at) <= ?');
      parameters.addAll([startDate, endDate]);
    }
    
    // Add search term filter
    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(t.description LIKE ? OR c.name LIKE ? OR tc.name LIKE ?)');
      final searchPattern = '%$searchTerm%';
      parameters.addAll([searchPattern, searchPattern, searchPattern]);
    }
    
    final whereClause = whereConditions.join(' AND ');
    
    // Get total count for pagination
    final totalCount = await _getTotalTicketsCount(whereClause, parameters);
    
    // Calculate pagination info
    final offset = (page - 1) * limit;
    final totalPages = (totalCount / limit).ceil();
    
    // Get tickets data
    final tickets = await _getTicketsData(
      whereClause: whereClause,
      parameters: parameters,
      limit: limit,
      offset: offset,
    );
    
    // Get summary statistics
    final summary = await _getTicketsSummary(companyId, whereClause, parameters);
    
    // Get detailed ticket items for each ticket
    final ticketsWithItems = await _addTicketItemsDetails(tickets);

    return TicketsReportResult.success({
      'tickets': ticketsWithItems,
      'pagination': {
        'currentPage': page,
        'totalPages': totalPages,
        'totalItems': totalCount,
        'itemsPerPage': limit,
        'hasNextPage': page < totalPages,
        'hasPreviousPage': page > 1,
      },
      'summary': summary,
      'filters': {
        'companyId': companyId,
        'status': status,
        'priority': priority,
        'categoryId': categoryId,
        'customerId': customerId,
        'startDate': startDate,
        'endDate': endDate,
        'searchTerm': searchTerm,
      },
    });
    
  } catch (e) {
    print('Error getting tickets report: $e');
    return TicketsReportResult.error('Failed to retrieve tickets report: ${e.toString()}');
  }
}

/// Get total count of tickets matching the criteria
Future<int> _getTotalTicketsCount(String whereClause, List<dynamic> parameters) async {
  try {
    final result = await DatabaseService.queryOne(
      '''
      SELECT COUNT(*) as total
      FROM tickets t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      WHERE $whereClause
      ''',
      parameters: parameters,
    );
    
    return result?['total'] as int? ?? 0;
  } catch (e) {
    print('Error getting total tickets count: $e');
    return 0;
  }
}

/// Get tickets data with pagination
Future<List<Map<String, dynamic>>> _getTicketsData({
  required String whereClause,
  required List<dynamic> parameters,
  required int limit,
  required int offset,
}) async {
  try {
    final results = await DatabaseService.query(
      '''
      SELECT 
        t.id,
        t.company_id,
        t.customer_id,
        t.ticket_cat_id,
        t.description,
        t.status,
        t.priority,
        t.created_by,
        t.created_at,
        t.updated_at,
        t.closed_at,
        t.closing_notes,
        c.name AS customer_name,
        comp.name AS company_name,
        g.name AS governorate_name,
        ct.name AS city_name,
        tc.name AS category_name,
        u.name AS created_by_name,
        (
          SELECT COUNT(*) 
          FROM ticketcall tcall 
          WHERE tcall.ticket_id = t.id
        ) AS calls_count,
        (
          SELECT COUNT(*) 
          FROM ticket_items ti 
          WHERE ti.ticket_id = t.id
        ) AS items_count
      FROM tickets t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN companies comp ON t.company_id = comp.id
      LEFT JOIN governorates g ON c.governomate_id = g.id
      LEFT JOIN cities ct ON c.city_id = ct.id
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      LEFT JOIN users u ON t.created_by = u.id
      WHERE $whereClause
      ORDER BY t.created_at DESC
      LIMIT ? OFFSET ?
      ''',
      parameters: [...parameters, limit, offset],
    );
    
    return results.map((row) => DataTransformer.transformTicketRow(row)).toList();
  } catch (e) {
    print('Error getting tickets data: $e');
    return [];
  }
}

/// Get summary statistics for tickets
Future<Map<String, dynamic>> _getTicketsSummary(int companyId, String whereClause, List<dynamic> parameters) async {
  try {
    // Get status counts
    final statusResult = await DatabaseService.query(
      '''
      SELECT 
        t.status,
        COUNT(*) as count
      FROM tickets t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      WHERE $whereClause
      GROUP BY t.status
      ''',
      parameters: parameters,
    );
    
    // Get priority counts
    final priorityResult = await DatabaseService.query(
      '''
      SELECT 
        t.priority,
        COUNT(*) as count
      FROM tickets t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      WHERE $whereClause
      GROUP BY t.priority
      ''',
      parameters: parameters,
    );
    
    // Convert status counts
    final statusCounts = <String, int>{};
    for (final row in statusResult) {
      final status = DataTransformer.convertStatusToString(row['status'] as int);
      statusCounts[status] = row['count'] as int;
    }
    
    // Convert priority counts
    final priorityCounts = <String, int>{};
    for (final row in priorityResult) {
      final priority = DataTransformer.convertPriorityToString(row['priority'] as int);
      priorityCounts[priority] = row['count'] as int;
    }
    
    return {
      'statusCounts': statusCounts,
      'priorityCounts': priorityCounts,
    };
  } catch (e) {
    print('Error getting tickets summary: $e');
    return {
      'statusCounts': <String, int>{},
      'priorityCounts': <String, int>{},
    };
  }
}

/// Add detailed ticket items information to each ticket
Future<List<Map<String, dynamic>>> _addTicketItemsDetails(List<Map<String, dynamic>> tickets) async {
  try {
    final ticketsWithItems = <Map<String, dynamic>>[];
    
    for (final ticket in tickets) {
      final ticketId = ticket['id'] as int?;
      if (ticketId == null) {
        ticketsWithItems.add(ticket);
        continue;
      }
      
      // Get detailed items for this ticket
      final items = await _getTicketItemsDetails(ticketId);
      
      // Add items to ticket data
      final ticketWithItems = Map<String, dynamic>.from(ticket);
      ticketWithItems['items'] = items;
      ticketsWithItems.add(ticketWithItems);
    }
    
    return ticketsWithItems;
  } catch (e) {
    print('Error adding ticket items details: $e');
    return tickets;
  }
}

/// Get detailed ticket items for a specific ticket
Future<List<Map<String, dynamic>>> _getTicketItemsDetails(int ticketId) async {
  try {
    final results = await DatabaseService.query(
      '''
      SELECT 
        ti.id,
        ti.product_id,
        pi.product_name,
        ti.product_size,
        ti.quantity,
        ti.purchase_date,
        ti.purchase_location,
        ti.request_reason_id,
        rr.name AS request_reason_name,
        ti.request_reason_detail,
        ti.inspected,
        ti.inspection_date,
        ti.inspection_result,
        ti.client_approval,
        ti.created_at,
        ti.updated_at
      FROM ticket_items ti
      LEFT JOIN product_info pi ON ti.product_id = pi.id
      LEFT JOIN request_reasons rr ON ti.request_reason_id = rr.id
      WHERE ti.ticket_id = ?
      ORDER BY ti.created_at ASC
      ''',
      parameters: [ticketId],
    );
    
    return results.map((row) => DataTransformer.transformTicketItemRow(row)).toList();
  } catch (e) {
    print('Error getting ticket items details: $e');
    return [];
  }
}