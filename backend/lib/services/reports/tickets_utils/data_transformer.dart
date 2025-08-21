import 'package:mysql1/mysql1.dart';

/// Utility class for transforming database data to API response format
class DataTransformer {
  /// Convert Blob to string safely
  static dynamic convertFromBlob(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Blob) return value.toString();
    if (value is List<int>) return String.fromCharCodes(value);
    return value.toString();
  }
  
  /// Convert ticket status integer to string
  static String convertStatusToString(int? status) {
    switch (status) {
      case 0:
        return 'open';
      case 1:
        return 'in_progress';
      case 2:
        return 'closed';
      default:
        return 'unknown';
    }
  }
  
  /// Convert ticket status string to integer
  static int convertStatusToInt(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 0;
      case 'in_progress':
        return 1;
      case 'closed':
        return 2;
      default:
        return 0;
    }
  }
  
  /// Convert priority integer to string
  static String convertPriorityToString(int? priority) {
    switch (priority) {
      case 0:
        return 'low';
      case 1:
        return 'medium';
      case 2:
        return 'high';
      default:
        return 'unknown';
    }
  }
  
  /// Convert priority string to integer
  static int convertPriorityToInt(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 0;
      case 'medium':
        return 1;
      case 'high':
        return 2;
      default:
        return 1;
    }
  }
  
  /// Convert call type integer to string
  static String convertCallTypeToString(int? callType) {
    switch (callType) {
      case 0:
        return 'incoming';
      case 1:
        return 'outgoing';
      default:
        return 'unknown';
    }
  }
  
  /// Convert call type string to integer
  static int convertCallTypeToInt(String callType) {
    switch (callType.toLowerCase()) {
      case 'incoming':
        return 0;
      case 'outgoing':
        return 1;
      default:
        return 0;
    }
  }
  
  /// Format datetime for API response
  static String? formatDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    if (dateTime is DateTime) return dateTime.toIso8601String();
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime).toIso8601String();
      } catch (e) {
        return dateTime;
      }
    }
    return dateTime.toString();
  }
  
  /// Format date for API response (date only)
  static String? formatDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date.toIso8601String().split('T')[0];
    if (date is String) {
      try {
        return DateTime.parse(date).toIso8601String().split('T')[0];
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }
  
  /// Safely convert to integer
  static int? safeToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
  
  /// Safely convert to double
  static double? safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  /// Safely convert to string
  static String? safeToString(dynamic value) {
    if (value == null) return null;
    return convertFromBlob(value)?.toString();
  }
  
  /// Transform ticket row from database to API format
  static Map<String, dynamic> transformTicketRow(ResultRow row) {
    return {
      'id': safeToInt(row['id']),
      'companyId': safeToInt(row['company_id']),
      'customerId': safeToInt(row['customer_id']),
      'customerName': safeToString(row['customer_name']),
      'companyName': safeToString(row['company_name']),
      'governorateName': safeToString(row['governorate_name']),
      'cityName': safeToString(row['city_name']),
      'ticketCatId': safeToInt(row['ticket_cat_id']),
      'categoryName': safeToString(row['category_name']),
      'description': safeToString(row['description']),
      'status': convertStatusToString(safeToInt(row['status'])),
      'priority': convertPriorityToString(safeToInt(row['priority'])),
      'createdBy': safeToInt(row['created_by']),
      'createdByName': safeToString(row['created_by_name']),
      'createdAt': formatDateTime(row['created_at']),
      'updatedAt': formatDateTime(row['updated_at']),
      'closedAt': formatDateTime(row['closed_at']),
      'closingNotes': safeToString(row['closing_notes']),
      'callsCount': safeToInt(row['calls_count']) ?? 0,
      'itemsCount': safeToInt(row['items_count']) ?? 0,
    };
  }

  /// Transform ticket item row from database to API format
  static Map<String, dynamic> transformTicketItemRow(ResultRow row) {
    return {
      'id': safeToInt(row['id']),
      'productId': safeToInt(row['product_id']),
      'productName': safeToString(row['product_name']),
      'productSize': safeToString(row['product_size']),
      'quantity': safeToInt(row['quantity']),
      'purchaseDate': formatDate(row['purchase_date']),
      'purchaseLocation': safeToString(row['purchase_location']),
      'requestReasonId': safeToInt(row['request_reason_id']),
      'requestReasonName': safeToString(row['request_reason_name']),
      'requestReasonDetail': safeToString(row['request_reason_detail']),
      'inspected': safeToInt(row['inspected']) == 1,
      'inspectionDate': formatDate(row['inspection_date']),
      'inspectionResult': safeToString(row['inspection_result']),
      'clientApproval': safeToInt(row['client_approval']) == 1,
      'createdAt': formatDateTime(row['created_at']),
      'updatedAt': formatDateTime(row['updated_at']),
    };
  }
  
  /// Transform pagination info
  static Map<String, dynamic> transformPaginationInfo({
    required int currentPage,
    required int totalItems,
    required int itemsPerPage,
  }) {
    final totalPages = (totalItems / itemsPerPage).ceil();
    
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
      'hasNextPage': currentPage < totalPages,
      'hasPreviousPage': currentPage > 1,
    };
  }
  
  /// Transform summary statistics
  static Map<String, dynamic> transformSummaryStats({
    required Map<int, int> statusCounts,
    required Map<int, int> priorityCounts,
  }) {
    final transformedStatusCounts = <String, int>{};
    statusCounts.forEach((key, value) {
      transformedStatusCounts[convertStatusToString(key)] = value;
    });
    
    final transformedPriorityCounts = <String, int>{};
    priorityCounts.forEach((key, value) {
      transformedPriorityCounts[convertPriorityToString(key)] = value;
    });
    
    return {
      'statusCounts': transformedStatusCounts,
      'priorityCounts': transformedPriorityCounts,
    };
  }
}