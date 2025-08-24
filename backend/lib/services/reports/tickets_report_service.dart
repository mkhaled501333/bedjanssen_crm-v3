import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/reports/tickets_utils/data_transformer.dart';

/// Get available filter options for cities and governorates
Future<Map<String, List<String>>> getAvailableFilters({int? companyId}) async {
  try {
    final filters = <String, List<String>>{};

    // Get distinct governorate names - company-specific when possible
    if (companyId != null) {
      final governorateResult = await DatabaseService.queryMany('''
        SELECT DISTINCT g.name 
        FROM governorates g
        INNER JOIN customers c ON c.governomate_id = g.id
        INNER JOIN tickets t ON t.customer_id = c.id
        WHERE t.company_id = ? AND g.name IS NOT NULL AND g.name != ''
        ORDER BY g.name
      ''', parameters: [companyId]);
      filters['governorates'] = governorateResult.map((row) => row.fields['name'] as String).toList();
      
      // If no governorates found with tickets, get all governorates for the company
      if (filters['governorates']!.isEmpty) {
        final fallbackResult = await DatabaseService.queryMany('''
          SELECT DISTINCT g.name 
          FROM governorates g
          INNER JOIN customers c ON c.governomate_id = g.id
          WHERE c.company_id = ? AND g.name IS NOT NULL AND g.name != ''
          ORDER BY g.name
        ''', parameters: [companyId]);
        filters['governorates'] = fallbackResult.map((row) => row.fields['name'] as String).toList();
      }
      
      // If still empty, get all governorates in the system
      if (filters['governorates']!.isEmpty) {
        final allGovernoratesResult = await DatabaseService.queryMany('''
          SELECT DISTINCT g.name 
          FROM governorates g
          WHERE g.name IS NOT NULL AND g.name != ''
          ORDER BY g.name
        ''');
        filters['governorates'] = allGovernoratesResult.map((row) => row.fields['name'] as String).toList();
      }
    } else {
      final governorateResult = await DatabaseService.queryMany('''
        SELECT DISTINCT g.name 
        FROM governorates g
        WHERE g.name IS NOT NULL AND g.name != ''
        ORDER BY g.name
      ''');
      filters['governorates'] = governorateResult.map((row) => row.fields['name'] as String).toList();
    }

    // Get distinct city names - company-specific when possible
    if (companyId != null) {
      final cityResult = await DatabaseService.queryMany('''
        SELECT DISTINCT ct.name 
        FROM cities ct
        INNER JOIN customers c ON c.city_id = ct.id
        INNER JOIN tickets t ON t.customer_id = c.id
        WHERE t.company_id = ? AND ct.name IS NOT NULL AND ct.name != ''
        ORDER BY ct.name
      ''', parameters: [companyId]);
      filters['cities'] = cityResult.map((row) => row.fields['name'] as String).toList();
      
      // If no cities found with tickets, get all cities for the company
      if (filters['cities']!.isEmpty) {
        final fallbackResult = await DatabaseService.queryMany('''
          SELECT DISTINCT ct.name 
          FROM cities ct
          INNER JOIN customers c ON c.city_id = ct.id
          WHERE c.company_id = ? AND ct.name IS NOT NULL AND ct.name != ''
          ORDER BY ct.name
        ''', parameters: [companyId]);
        filters['cities'] = fallbackResult.map((row) => row.fields['name'] as String).toList();
      }
    } else {
      final cityResult = await DatabaseService.queryMany('''
        SELECT DISTINCT ct.name 
        FROM cities ct
        WHERE ct.name IS NOT NULL AND ct.name != ''
        ORDER BY ct.name
      ''');
      filters['cities'] = cityResult.map((row) => row.fields['name'] as String).toList();
    }

    // Get distinct ticket categories - company-specific when possible
    if (companyId != null) {
      final categoryResult = await DatabaseService.queryMany('''
        SELECT DISTINCT tc.name 
        FROM ticket_categories tc
        INNER JOIN tickets t ON t.ticket_cat_id = tc.id
        WHERE t.company_id = ? AND tc.name IS NOT NULL AND tc.name != ''
        ORDER BY tc.name
      ''', parameters: [companyId]);
      filters['categories'] = categoryResult.map((row) => row.fields['name'] as String).toList();
    } else {
      final categoryResult = await DatabaseService.queryMany('''
        SELECT DISTINCT tc.name 
        FROM ticket_categories tc
        WHERE tc.name IS NOT NULL AND tc.name != ''
        ORDER BY tc.name
      ''');
      filters['categories'] = categoryResult.map((row) => row.fields['name'] as String).toList();
    }

    // Get distinct status values from tickets - company-specific when possible
    if (companyId != null) {
      final statusResult = await DatabaseService.queryMany('''
        SELECT DISTINCT t.status 
        FROM tickets t
        WHERE t.company_id = ? AND t.status IS NOT NULL
        ORDER BY t.status
      ''', parameters: [companyId]);
      filters['statuses'] = statusResult.map((row) {
        final statusInt = row.fields['status'] as int;
        return DataTransformer.convertStatusToString(statusInt);
      }).toList();
    } else {
      final statusResult = await DatabaseService.queryMany('''
        SELECT DISTINCT t.status 
        FROM tickets t
        WHERE t.status IS NOT NULL
        ORDER BY t.status
      ''');
      filters['statuses'] = statusResult.map((row) {
        final statusInt = row.fields['status'] as int;
        return DataTransformer.convertStatusToString(statusInt);
      }).toList();
    }

    // Get distinct product names - company-specific when possible
    if (companyId != null) {
      final productResult = await DatabaseService.queryMany('''
        SELECT DISTINCT pi.product_name 
        FROM product_info pi
        INNER JOIN ticket_items ti ON ti.product_id = pi.id
        INNER JOIN tickets t ON ti.ticket_id = t.id
        WHERE t.company_id = ? AND pi.product_name IS NOT NULL AND pi.product_name != ''
        ORDER BY pi.product_name
      ''', parameters: [companyId]);
      filters['productNames'] = productResult.map((row) => row.fields['product_name'] as String).toList();
    } else {
      final productResult = await DatabaseService.queryMany('''
        SELECT DISTINCT pi.product_name 
        FROM product_info pi
        WHERE pi.product_name IS NOT NULL AND pi.product_name != ''
        ORDER BY pi.product_name
      ''');
      filters['productNames'] = productResult.map((row) => row.fields['product_name'] as String).toList();
    }

    // Get distinct company names - company-specific when possible
    if (companyId != null) {
      final companyResult = await DatabaseService.queryMany('''
        SELECT DISTINCT comp.name 
        FROM companies comp
        INNER JOIN tickets t ON t.company_id = comp.id
        WHERE t.company_id = ? AND comp.name IS NOT NULL AND comp.name != ''
        ORDER BY comp.name
      ''', parameters: [companyId]);
      filters['companyNames'] = companyResult.map((row) => row.fields['name'] as String).toList();
    } else {
      final companyResult = await DatabaseService.queryMany('''
        SELECT DISTINCT comp.name 
        FROM companies comp
        WHERE comp.name IS NOT NULL AND comp.name != ''
        ORDER BY comp.name
      ''');
      filters['companyNames'] = companyResult.map((row) => row.fields['name'] as String).toList();
    }

    // Get distinct request reason names - company-specific when possible
    if (companyId != null) {
      final requestReasonResult = await DatabaseService.queryMany('''
        SELECT DISTINCT rr.name 
        FROM request_reasons rr
        INNER JOIN ticket_items ti ON ti.request_reason_id = rr.id
        INNER JOIN tickets t ON ti.ticket_id = t.id
        WHERE t.company_id = ? AND rr.name IS NOT NULL AND rr.name != ''
        ORDER BY rr.name
      ''', parameters: [companyId]);
      filters['requestReasonNames'] = requestReasonResult.map((row) => row.fields['name'] as String).toList();
    } else {
      final requestReasonResult = await DatabaseService.queryMany('''
        SELECT DISTINCT rr.name 
        FROM request_reasons rr
        WHERE rr.name IS NOT NULL AND rr.name != ''
        ORDER BY rr.name
      ''');
      filters['requestReasonNames'] = requestReasonResult.map((row) => row.fields['name'] as String).toList();
    }

    // Debug logging
    print('Available filters found:');
    print('Governorates: ${filters['governorates']}');
    print('Cities: ${filters['cities']}');
    print('Categories: ${filters['categories']}');
    print('Statuses: ${filters['statuses']}');
    print('Product Names: ${filters['productNames']}');
    print('Company Names: ${filters['companyNames']}');
    print('Request Reason Names: ${filters['requestReasonNames']}');
    
    // Debug: Check data types
    print('Data type debugging:');
    if (filters['statuses']!.isNotEmpty) {
      print('First status value: ${filters['statuses']!.first} (type: ${filters['statuses']!.first.runtimeType})');
    }
    
    // Additional debug: Check if we have any data at all
    if (companyId != null) {
      final ticketCount = await DatabaseService.queryOne('''
        SELECT COUNT(*) as count FROM tickets WHERE company_id = ?
      ''', parameters: [companyId]);
      print('Total tickets for company $companyId: ${ticketCount?.fields['count']}');
      
      final governorateCount = await DatabaseService.queryOne('''
        SELECT COUNT(*) as count FROM governorates
      ''');
      print('Total governorates in system: ${governorateCount?.fields['count']}');
      
      final cityCount = await DatabaseService.queryOne('''
        SELECT COUNT(*) as count FROM cities
      ''');
      print('Total cities in system: ${cityCount?.fields['count']}');
    }

    return filters;
  } catch (e) {
    print('Error getting available filters: $e');
    // Return empty filters on error to avoid breaking the main functionality
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
      whereConditions.add('g.name = ?');
      parameters.add(governorate);
    }
    
    // Add city filter
    if (city != null && city.isNotEmpty) {
      whereConditions.add('ct.name = ?');
      parameters.add(city);
    }
    
    // Add product name filter
    if (productName != null && productName.isNotEmpty) {
      whereConditions.add('EXISTS (SELECT 1 FROM ticket_items ti2 INNER JOIN product_info pi2 ON ti2.product_id = pi2.id WHERE ti2.ticket_id = t.id AND pi2.product_name LIKE ?)');
      parameters.add('%$productName%');
    }
    
    // Add company name filter
    if (companyName != null && companyName.isNotEmpty) {
      whereConditions.add('comp.name LIKE ?');
      parameters.add('%$companyName%');
    }
    
    // Add request reason name filter
    if (requestReasonName != null && requestReasonName.isNotEmpty) {
      whereConditions.add('EXISTS (SELECT 1 FROM ticket_items ti3 INNER JOIN request_reasons rr ON ti3.request_reason_id = rr.id WHERE ti3.ticket_id = t.id AND rr.name LIKE ?)');
      parameters.add('%$requestReasonName%');
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
    final availableFilters = await getAvailableFilters(companyId: companyId);

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
      SELECT t.status as value, COUNT(*) as count
      FROM tickets t
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
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