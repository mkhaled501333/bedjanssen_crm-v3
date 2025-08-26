import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/reports/tickets_utils/data_transformer.dart';

Future<Map<String, List<dynamic>>> getAvailableFilters({
  required int companyId,
  String? status,
  int? categoryId,
  int? customerId,
  String? startDate,
  String? endDate,
  String? searchTerm,
  String? governorate,
  String? city,
  String? productName,
  String? companyName,
  String? requestReasonName,
  bool? inspected,
}) async {
  try {
    // Build the base WHERE clause and parameters, similar to getTicketsReport
    final whereConditions = <String>['t.company_id = ?'];
    final parameters = <dynamic>[companyId];

    // Add filters to the WHERE clause and parameters
    if (status != null && status.isNotEmpty) {
      final statusList = status.split(',').map((e) => e.trim()).toList();
      if (statusList.isNotEmpty) {
        final statusValues = statusList.map((s) => DataTransformer.convertStatusToInt(s)).toList();
        final placeholders = List.filled(statusValues.length, '?').join(', ');
        whereConditions.add('t.status IN ($placeholders)');
        parameters.addAll(statusValues);
      }
    }
    if (categoryId != null) {
      whereConditions.add('t.ticket_cat_id = ?');
      parameters.add(categoryId);
    }
    if (customerId != null) {
      whereConditions.add('t.customer_id = ?');
      parameters.add(customerId);
    }
    if (startDate != null && endDate != null) {
      whereConditions.add('DATE(t.created_at) BETWEEN ? AND ?');
      parameters.addAll([startDate, endDate]);
    }
    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(t.description LIKE ? OR c.name LIKE ? OR tc.name LIKE ?)');
      final searchPattern = '%$searchTerm%';
      parameters.addAll([searchPattern, searchPattern, searchPattern]);
    }
    if (governorate != null && governorate.isNotEmpty) {
      final governorateList = governorate.split(',').map((e) => e.trim()).toList();
      if (governorateList.isNotEmpty) {
        final placeholders = List.filled(governorateList.length, '?').join(', ');
        whereConditions.add('g.name IN ($placeholders)');
        parameters.addAll(governorateList);
      }
    }
    if (city != null && city.isNotEmpty) {
      final cityList = city.split(',').map((e) => e.trim()).toList();
      if (cityList.isNotEmpty) {
        final placeholders = List.filled(cityList.length, '?').join(', ');
        whereConditions.add('ct.name IN ($placeholders)');
        parameters.addAll(cityList);
      }
    }
    if (productName != null && productName.isNotEmpty) {
      final productNameList = productName.split(',').map((e) => e.trim()).toList();
      if (productNameList.isNotEmpty) {
        final placeholders = List.filled(productNameList.length, '?').join(', ');
        whereConditions.add('EXISTS (SELECT 1 FROM ticket_items ti2 INNER JOIN product_info pi2 ON ti2.product_id = pi2.id WHERE ti2.ticket_id = t.id AND pi2.product_name IN ($placeholders))');
        parameters.addAll(productNameList);
      }
    }
    if (companyName != null && companyName.isNotEmpty) {
      final companyNameList = companyName.split(',').map((e) => e.trim()).toList();
      if (companyNameList.isNotEmpty) {
        final placeholders = List.filled(companyNameList.length, '?').join(', ');
        whereConditions.add('comp.name IN ($placeholders)');
        parameters.addAll(companyNameList);
      }
    }
    if (requestReasonName != null && requestReasonName.isNotEmpty) {
      final requestReasonNameList = requestReasonName.split(',').map((e) => e.trim()).toList();
      if (requestReasonNameList.isNotEmpty) {
        final placeholders = List.filled(requestReasonNameList.length, '?').join(', ');
        whereConditions.add('EXISTS (SELECT 1 FROM ticket_items ti3 INNER JOIN request_reasons rr ON ti3.request_reason_id = rr.id WHERE ti3.ticket_id = t.id AND rr.name IN ($placeholders))');
        parameters.addAll(requestReasonNameList);
      }
    }
    if (inspected != null) {
      whereConditions.add('EXISTS (SELECT 1 FROM ticket_items ti4 WHERE ti4.ticket_id = t.id AND ti4.inspected = ?)');
      parameters.add(inspected ? 1 : 0);
    }

    whereConditions.join(' AND ');

    // Helper function to get all available options for a specific company (unfiltered)
    
    // Helper function to get all available options from a simple table
    Future<List<Map<String, dynamic>>> _fetchSimpleTable(String selectId, String selectName, String tableName) async {
      try {
        final query = 'SELECT DISTINCT $selectId, $selectName FROM $tableName WHERE $selectName IS NOT NULL';
        print('Executing query: $query');
        final result = await DatabaseService.queryMany(query);
        print('Query result for $tableName: ${result.length} rows');
        final mappedResult = result.map((row) => {
          'id': row[selectId],
          'name': row[selectName],
        }).where((item) => item['name'] != null && item['name'].toString().isNotEmpty).toList();
        print('Mapped result for $tableName: ${mappedResult.length} items');
        return mappedResult;
      } catch (e) {
        print('Error fetching from $tableName: $e');
        return [];
      }
    }

    // For basic filters, get all available options from master data tables
    final availableGovernorates = await _fetchSimpleTable(
      'id',
      'name',
      'governorates',
    );

    final availableCities = await _fetchSimpleTable(
      'id',
      'name',
      'cities',
    );

    final availableCategories = await _fetchSimpleTable(
      'id',
      'name',
      'ticket_categories',
    );

    final statusResult = await DatabaseService.queryMany(
      'SELECT DISTINCT t.status FROM tickets t WHERE t.company_id = ? AND t.status IS NOT NULL',
      parameters: [companyId],
    );
    final availableStatuses = statusResult.map((row) => {
      'id': row['status'],
      'name': DataTransformer.convertStatusToString(row['status'] as int),
    }).toList();

    final availableProductNames = await _fetchSimpleTable(
      'id',
      'product_name',
      'product_info',
    );

    final availableCompanyNames = await _fetchSimpleTable(
      'id',
      'name',
      'companies',
    );

    final availableRequestReasonNames = await _fetchSimpleTable(
      'id',
      'name',
      'request_reasons',
    );

    return {
      'governorates': availableGovernorates,
      'cities': availableCities,
      'categories': availableCategories,
      'statuses': availableStatuses,
      'productNames': availableProductNames,
      'companyNames': availableCompanyNames,
      'requestReasonNames': availableRequestReasonNames,
    };
  } catch (e) {
    print('Error getting available filters: $e');
    return {
      'governorates': [],
      'cities': [],
      'categories': [],
      'statuses': [],
      'productNames': [],
      'companyNames': [],
      'requestReasonNames': [],
    };
  }
}

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
  int? categoryId,
  int? customerId,
  String? startDate,
  String? endDate,
  String? searchTerm,
  String? governorate,
  String? city,
  String? productName,
  String? companyName,
  String? requestReasonName,
  bool? inspected,
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
    
    // Add governorate filter
    if (governorate != null && governorate.isNotEmpty) {
      final governorateList = governorate.split(',').map((e) => e.trim()).toList();
      if (governorateList.isNotEmpty) {
        final placeholders = List.filled(governorateList.length, '?').join(', ');
        whereConditions.add('g.name IN ($placeholders)');
        parameters.addAll(governorateList);
      }
    }
    
    // Add city filter
    if (city != null && city.isNotEmpty) {
      final cityList = city.split(',').map((e) => e.trim()).toList();
      if (cityList.isNotEmpty) {
        final placeholders = List.filled(cityList.length, '?').join(', ');
        whereConditions.add('ct.name IN ($placeholders)');
        parameters.addAll(cityList);
      }
    }
    
    // Add product name filter
    if (productName != null && productName.isNotEmpty) {
      final productNameList = productName.split(',').map((e) => e.trim()).toList();
      if (productNameList.isNotEmpty) {
        final placeholders = List.filled(productNameList.length, '?').join(', ');
        whereConditions.add('EXISTS (SELECT 1 FROM ticket_items ti2 INNER JOIN product_info pi2 ON ti2.product_id = pi2.id WHERE ti2.ticket_id = t.id AND pi2.product_name IN ($placeholders))');
        parameters.addAll(productNameList);
      }
    }
    
    // Add company name filter
    if (companyName != null && companyName.isNotEmpty) {
      final companyNameList = companyName.split(',').map((e) => e.trim()).toList();
      if (companyNameList.isNotEmpty) {
        final placeholders = List.filled(companyNameList.length, '?').join(', ');
        whereConditions.add('comp.name IN ($placeholders)');
        parameters.addAll(companyNameList);
      }
    }
    
    // Add request reason name filter
    if (requestReasonName != null && requestReasonName.isNotEmpty) {
      final requestReasonNameList = requestReasonName.split(',').map((e) => e.trim()).toList();
      if (requestReasonNameList.isNotEmpty) {
        final placeholders = List.filled(requestReasonNameList.length, '?').join(', ');
        whereConditions.add('EXISTS (SELECT 1 FROM ticket_items ti3 INNER JOIN request_reasons rr ON ti3.request_reason_id = rr.id WHERE ti3.ticket_id = t.id AND rr.name IN ($placeholders))');
        parameters.addAll(requestReasonNameList);
      }
    }
    
    // Add inspected filter
    if (inspected != null) {
      final inspectedValue = inspected ? 1 : 0;
      whereConditions.add('EXISTS (SELECT 1 FROM ticket_items ti4 WHERE ti4.ticket_id = t.id AND ti4.inspected = ?)');
      parameters.add(inspectedValue);
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

    // Get available filter options
    final availableFilters = await getAvailableFilters(
      companyId: companyId,
      status: status,
      categoryId: categoryId,
      customerId: customerId,
      startDate: startDate,
      endDate: endDate,
      searchTerm: searchTerm,
      governorate: governorate,
      city: city,
      productName: productName,
      companyName: companyName,
      requestReasonName: requestReasonName,
      inspected: inspected,
    );

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
        'categoryId': categoryId,
        'customerId': customerId,
        'startDate': startDate,
        'endDate': endDate,
        'searchTerm': searchTerm,
        'governorate': governorate,
        'city': city,
        'productName': productName,
        'companyName': companyName,
        'requestReasonName': requestReasonName,
        'inspected': inspected,
      },
      'available_filters': availableFilters,
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
      SELECT COUNT(DISTINCT t.id) as total
      FROM tickets t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      LEFT JOIN companies comp ON t.company_id = comp.id
      LEFT JOIN governorates g ON c.governomate_id = g.id
      LEFT JOIN cities ct ON c.city_id = ct.id
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

/// Get tickets data with pagination - optimized version
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
        COALESCE(tcall_counts.calls_count, 0) AS calls_count,
        COALESCE(ti_counts.items_count, 0) AS items_count
      FROM tickets t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN companies comp ON t.company_id = comp.id
      LEFT JOIN governorates g ON c.governomate_id = g.id
      LEFT JOIN cities ct ON c.city_id = ct.id
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      LEFT JOIN users u ON t.created_by = u.id
      LEFT JOIN (
        SELECT ticket_id, COUNT(*) as calls_count
        FROM ticketcall
        GROUP BY ticket_id
      ) tcall_counts ON tcall_counts.ticket_id = t.id
      LEFT JOIN (
        SELECT ticket_id, COUNT(*) as items_count
        FROM ticket_items
        GROUP BY ticket_id
      ) ti_counts ON ti_counts.ticket_id = t.id
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

/// Get summary statistics for tickets using single optimized query
Future<Map<String, dynamic>> _getTicketsSummary(int companyId, String whereClause, List<dynamic> parameters) async {
  try {
    // Get status counts
    final result = await DatabaseService.query(
      '''
      SELECT t.status as value, COUNT(DISTINCT t.id) as count
      FROM tickets t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      LEFT JOIN companies comp ON t.company_id = comp.id
      LEFT JOIN governorates g ON c.governomate_id = g.id
      LEFT JOIN cities ct ON c.city_id = ct.id
      WHERE $whereClause
      GROUP BY t.status
      ''',
      parameters: parameters,
    );

    final statusCounts = <String, int>{};

    for (final row in result) {
      final value = row['value'] as int;
      final count = row['count'] as int;
      final status = DataTransformer.convertStatusToString(value);
      statusCounts[status] = count;
    }

    return {
      'statusCounts': statusCounts,
    };
  } catch (e) {
    print('Error getting tickets summary: $e');
    return {
      'statusCounts': <String, int>{},
    };
  }
}

/// Add detailed ticket items information to each ticket using batch query
Future<List<Map<String, dynamic>>> _addTicketItemsDetails(List<Map<String, dynamic>> tickets) async {
  try {
    if (tickets.isEmpty) return tickets;

    // Extract ticket IDs for batch query
    final ticketIds = tickets
        .map((ticket) => ticket['id'] as int?)
        .where((id) => id != null)
        .cast<int>() // Cast to non-nullable int
        .toList();

    if (ticketIds.isEmpty) return tickets;

    // Get all items for all tickets in a single batch query
    final itemsMap = await _getTicketItemsDetailsBatch(ticketIds);

    // Associate items with their tickets
    final ticketsWithItems = <Map<String, dynamic>>[];
    for (final ticket in tickets) {
      final ticketId = ticket['id'] as int?;
      final ticketWithItems = Map<String, dynamic>.from(ticket);

      if (ticketId != null && itemsMap.containsKey(ticketId)) {
        ticketWithItems['items'] = itemsMap[ticketId]!;
      } else {
        ticketWithItems['items'] = <Map<String, dynamic>>[];
      }

      ticketsWithItems.add(ticketWithItems);
    }

    return ticketsWithItems;
  } catch (e) {
    print('Error adding ticket items details: $e');
    return tickets;
  }
}

/// Get detailed ticket items for multiple tickets in a single batch query
Future<Map<int, List<Map<String, dynamic>>>> _getTicketItemsDetailsBatch(List<int> ticketIds) async {
  try {
    if (ticketIds.isEmpty) return {};

    // Create placeholders for IN clause
    final placeholders = List.filled(ticketIds.length, '?').join(', ');

    final results = await DatabaseService.query(
      '''
      SELECT
        ti.id,
        ti.ticket_id,
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
      WHERE ti.ticket_id IN ($placeholders)
      ORDER BY ti.ticket_id ASC, ti.created_at ASC
      ''',
      parameters: ticketIds,
    );

    // Group items by ticket_id
    final itemsMap = <int, List<Map<String, dynamic>>>{};
    for (final row in results) {
      final ticketId = row['ticket_id'] as int;
      final transformedRow = DataTransformer.transformTicketItemRow(row);

      if (!itemsMap.containsKey(ticketId)) {
        itemsMap[ticketId] = [];
      }
      itemsMap[ticketId]!.add(transformedRow);
    }

    return itemsMap;
  } catch (e) {
    print('Error getting ticket items details batch: $e');
    return {};
  }
}