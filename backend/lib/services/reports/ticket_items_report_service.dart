// ignore_for_file: inference_failure_on_collection_literal

import 'package:janssencrm_backend/database/database_service.dart';

class TicketItemsReportService {
  /// Get available filter options, applied filters, AND report data in one response
  static Future<Map<String, dynamic>> getTicketItemsReport({
    required int companyId,
    List<int>? customerIds,
    List<int>? governomateIds,
    List<int>? cityIds,
    List<int>? ticketIds,
    List<int>? companyIds,
    List<int>? ticketCatIds,
    String? ticketStatus,
    List<int>? productIds,
    List<int>? requestReasonIds,
    bool? inspected,
    DateTime? inspectionDateFrom,
    DateTime? inspectionDateTo,
    DateTime? ticketCreatedDateFrom,
    DateTime? ticketCreatedDateTo,
    String? action,
    bool? pulledStatus,
    bool? deliveredStatus,
    bool? clientApproval,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // First, check if the view exists and has data
      try {
        // Diagnostic: Check each table individually to identify the issue
        print('🔍 Diagnosing view data issue...');
        
        final tables = [
          'ticket_items',
          'tickets', 
          'customers',
          'governorates',
          'cities',
          'product_info',
          'request_reasons',
          'ticket_item_change_another',
          'ticket_item_change_same',
          'ticket_item_maintenance'
        ];
        
        for (final table in tables) {
          try {
            final countQuery = 'SELECT COUNT(*) as count FROM $table';
            final countResult = await DatabaseService.query(countQuery);
            final count = countResult.first['count'] as int;
            print('  📊 $table: $count records');
          } catch (e) {
            print('  ❌ $table: Error - $e');
          }
        }
        
        final testQuery = 'SELECT COUNT(*) as count FROM ticket_items_report LIMIT 1';
        final testResult = await DatabaseService.query(testQuery);
        print('✓ View ticket_items_report exists and is accessible');
        
        // Handle case where view might be empty
        if (testResult.isNotEmpty) {
          final count = testResult.first['count'] as int;
          print('✓ View has $count total records');
          
          // If view is completely empty, return empty result instead of error
          if (count == 0) {
            print('⚠ View is empty - returning empty result structure');
            return {
              'success': true,
              'data': {
                'available_filters': {
                  'governorates': [],
                  'cities': [],
                  'customers': [],
                  'tickets': [],
                  'ticket_categories': [],
                  'products': [],
                  'request_reasons': [],
                  'actions': []
                },
                'applied_filters': {'companyId': companyId},
                'filter_summary': {
                  'total_applied_filters': 1,
                  'active_filters': ['companyId']
                },
                'report_data': {
                  'ticket_items': [],
                  'pagination': {
                    'page': page,
                    'limit': limit,
                    'total': 0,
                    'total_pages': 0,
                    'has_next': false,
                    'has_previous': false
                  }
                }
              }
            };
          }
        } else {
          print('⚠ View exists but returned no results');
        }
      } catch (e) {
        print('✗ Error accessing ticket_items_report view: $e');
        return {
          'success': false,
          'error': 'Database view not accessible: ${e.toString()}',
        };
      }

      // Build base WHERE clause for the current filter state
      final whereConditions = <String>['company_id = ?'];
      final parameters = <dynamic>[companyId];

      // Add currently applied filters to WHERE clause
      if (customerIds != null && customerIds.isNotEmpty) {
        whereConditions.add('customer_id IN (${customerIds.map((_) => '?').join(',')})');
        parameters.addAll(customerIds);
      }
      if (governomateIds != null && governomateIds.isNotEmpty) {
        whereConditions.add('governomate_id IN (${governomateIds.map((_) => '?').join(',')})');
        parameters.addAll(governomateIds);
      }
      if (cityIds != null && cityIds.isNotEmpty) {
        whereConditions.add('city_id IN (${cityIds.map((_) => '?').join(',')})');
        parameters.addAll(cityIds);
      }
      if (ticketIds != null && ticketIds.isNotEmpty) {
        whereConditions.add('ticket_id IN (${ticketIds.map((_) => '?').join(',')})');
        parameters.addAll(ticketIds);
      }
      if (ticketCatIds != null && ticketCatIds.isNotEmpty) {
        whereConditions.add('ticket_cat_id IN (${ticketCatIds.map((_) => '?').join(',')})');
        parameters.addAll(ticketCatIds);
      }
      if (ticketStatus != null) {
        whereConditions.add('ticket_status = ?');
        parameters.add(ticketStatus);
      }
      if (productIds != null && productIds.isNotEmpty) {
        whereConditions.add('product_id IN (${productIds.map((_) => '?').join(',')})');
        parameters.addAll(productIds);
      }
      if (requestReasonIds != null && requestReasonIds.isNotEmpty) {
        whereConditions.add('request_reason_id IN (${requestReasonIds.map((_) => '?').join(',')})');
        parameters.addAll(requestReasonIds);
      }
      if (inspected != null) {
        whereConditions.add('inspected = ?');
        parameters.add(inspected);
      }
      if (inspectionDateFrom != null) {
        whereConditions.add('inspection_date >= ?');
        parameters.add(inspectionDateFrom);
      }
      if (inspectionDateTo != null) {
        whereConditions.add('inspection_date <= ?');
        parameters.add(inspectionDateTo);
      }
      if (ticketCreatedDateFrom != null) {
        whereConditions.add('ticket_created_at >= ?');
        parameters.add(ticketCreatedDateFrom);
      }
      if (ticketCreatedDateTo != null) {
        whereConditions.add('ticket_created_at <= ?');
        parameters.add(ticketCreatedDateTo);
      }
      if (action != null) {
        whereConditions.add('action = ?');
        parameters.add(action);
      }
      if (pulledStatus != null) {
        whereConditions.add('pulled_status = ?');
        parameters.add(pulledStatus);
      }
      if (deliveredStatus != null) {
        whereConditions.add('delivered_status = ?');
        parameters.add(deliveredStatus);
      }
      if (clientApproval != null) {
        whereConditions.add('client_approval = ?');
        parameters.add(clientApproval);
      }

      final whereClause = whereConditions.join(' AND ');

      // Get total count for pagination
      final countQuery = '''
        SELECT COUNT(*) as total
        FROM ticket_items_report
        WHERE $whereClause
      ''';
      
      int total = 0;
      try {
        final countResult = await DatabaseService.query(countQuery, parameters: parameters);
        total = countResult.first['total'] as int;
      } catch (e) {
        print('Error fetching count: $e');
        total = 0;
      }

      // Get paginated report data
      final offset = (page - 1) * limit;
      final dataQuery = '''
        SELECT *
        FROM ticket_items_report
        WHERE $whereClause
        ORDER BY ticket_id DESC, ticket_item_id DESC
        LIMIT ? OFFSET ?
      ''';
      
      final dataParameters = [...parameters, limit, offset];
      List<Map<String, dynamic>> reportData = [];
      
      try {
        final result = await DatabaseService.query(dataQuery, parameters: dataParameters);
        reportData = result.map((row) {
          try {
            final rowMap = Map<String, dynamic>.from(row.fields);
            // Convert all DateTime fields to ISO strings for JSON serialization
            rowMap.forEach((key, value) {
              if (value is DateTime) {
                rowMap[key] = value.toIso8601String();
              }
            });
            return rowMap;
          } catch (e) {
            print('Error processing row: $e');
            print('Row fields: ${row.fields}');
            // Return a safe fallback
            return <String, dynamic>{'error': 'Row processing failed: $e'};
          }
        }).toList();
      } catch (e) {
        print('Error fetching report data: $e');
        // Return empty data instead of failing completely
        reportData = [];
      }

      // Get available filter options from the filtered dataset
      final availableFilters = <String, List<Map<String, dynamic>>>{};

      // Get available governorates
      availableFilters['governorates'] = await _getDistinctValues(
        'governomate_id',
        'governorate_name',
        'governorates',
        whereClause,
        parameters,
      );

      // Get available cities
      availableFilters['cities'] = await _getDistinctValues(
        'city_id',
        'city_name',
        'cities',
        whereClause,
        parameters,
      );

      // Get available ticket categories
      availableFilters['ticket_categories'] = await _getDistinctValues(
        'ticket_cat_id',
        'ticket_category_name',
        'ticket_categories',
        whereClause,
        parameters,
      );

      // Get available ticket statuses
      availableFilters['ticket_statuses'] = await _getDistinctValues(
        'ticket_status',
        'ticket_status',
        'ticket_statuses',
        whereClause,
        parameters,
      );

      // Get available products
      availableFilters['products'] = await _getDistinctValues(
        'product_id',
        'product_name',
        'products',
        whereClause,
        parameters,
      );

      // Get available request reasons
      availableFilters['request_reasons'] = await _getDistinctValues(
        'request_reason_id',
        'request_reason_name',
        'request_reasons',
        whereClause,
        parameters,
      );

      // Get available actions
      availableFilters['actions'] = await _getDistinctValues(
        'action',
        'action',
        'actions',
        whereClause,
        parameters,
      );

      // Build applied filters object with current values
      final appliedFilters = <String, dynamic>{
        'companyId': companyId,
        'customerIds': customerIds,
        'governomateIds': governomateIds,
        'cityIds': cityIds,
        'ticketIds': ticketIds,
        'companyIds': companyIds,
        'ticketCatIds': ticketCatIds,
        'ticketStatus': ticketStatus,
        'productIds': productIds,
        'requestReasonIds': requestReasonIds,
        'inspected': inspected,
        'inspectionDateFrom': inspectionDateFrom?.toIso8601String(),
        'inspectionDateTo': inspectionDateTo?.toIso8601String(),
        'ticketCreatedDateFrom': ticketCreatedDateFrom?.toIso8601String(),
        'ticketCreatedDateTo': ticketCreatedDateTo?.toIso8601String(),
        'action': action,
        'pulledStatus': pulledStatus,
        'deliveredStatus': deliveredStatus,
        'clientApproval': clientApproval,
      };

      // Remove null/empty values for cleaner response
      appliedFilters.removeWhere((key, value) => 
        value == null || 
        (value is List && value.isEmpty) ||
        (value is String && value.isEmpty)
      );

      final responseData = {
        'success': true,
        'data': {
          'available_filters': availableFilters,
          'applied_filters': appliedFilters,
          'filter_summary': {
            'total_applied_filters': appliedFilters.length - 1, // Exclude companyId
            'active_filters': appliedFilters.keys.where((key) => key != 'companyId').toList(),
          },
          'report_data': {
            'ticket_items': reportData,
            'pagination': {
              'page': page,
              'limit': limit,
              'total': total,
              'total_pages': (total / limit).ceil(),
              'has_next': page < (total / limit).ceil(),
              'has_previous': page > 1,
            }
          }
        }
      };

      // Debug: Check for any remaining DateTime objects
      print('Response data keys: ${responseData.keys}');
      print('Report data length: ${reportData.length}');
      if (reportData.isNotEmpty) {
        print('First report item keys: ${reportData.first.keys}');
        print('First report item inspection_date type: ${reportData.first['inspection_date']?.runtimeType}');
      }

      return responseData;
    } catch (e) {
      print('Error getting ticket items report: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Helper method to get distinct values for a specific column
  static Future<List<Map<String, dynamic>>> _getDistinctValues(
    String idColumn,
    String nameColumn,
    String tableAlias,
    String whereClause,
    List<dynamic> parameters,
  ) async {
    try {
      final query = '''
        SELECT DISTINCT $idColumn as id, $nameColumn as name
        FROM ticket_items_report
        WHERE $whereClause
        AND $idColumn IS NOT NULL
        AND $nameColumn IS NOT NULL
        ORDER BY $nameColumn
      ''';

      final result = await DatabaseService.query(query, parameters: parameters);
      
      final mappedResult = result.map((row) => <String, dynamic>{
        'id': row['id'],
        'name': row['name'],
      }).where((item) => 
        item['name'] != null && 
        item['name'].toString().isNotEmpty
      ).toList();
      
      // Debug: Log the structure of the first item
      if (mappedResult.isNotEmpty) {
        print('First ${tableAlias} item: ${mappedResult.first}');
        print('First ${tableAlias} item type: ${mappedResult.first.runtimeType}');
        print('First ${tableAlias} item keys: ${mappedResult.first.keys}');
      }
      
      return mappedResult;
    } catch (e) {
      print('Error getting distinct values for $tableAlias: $e');
      return [];
    }
  }
}
