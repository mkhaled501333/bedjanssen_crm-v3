import 'package:janssencrm_backend/database/database_service.dart';
import 'package:mysql1/mysql1.dart';
import 'utils.dart';

/// Get customer calls created by a specific user within a date range
Future<List<Map<String, dynamic>>> getCustomerCalls(int userId, String startDate, String endDate) async {
  try {
    final results = await DatabaseService.query(
      '''
      SELECT
        cc.id,
        cc.company_id,
        cc.customer_id,
        cc.call_type,
        cc.category_id,
        cc.description,
        cc.call_notes,
        cc.call_duration,
        cc.created_by,
        cc.created_at,
        cc.updated_at,
        cat.name AS categoryName,
        u.name AS createdByName,
        c.name AS customerName,
        (SELECT phone FROM customer_phones WHERE customer_id = c.id LIMIT 1) AS customerPhone
      FROM customercall cc
      LEFT JOIN users u ON cc.created_by = u.id
      LEFT JOIN call_categories cat ON cc.category_id = cat.id
      LEFT JOIN customers c ON cc.customer_id = c.id
      WHERE cc.created_by = ?
        AND DATE(cc.created_at) >= ?
        AND DATE(cc.created_at) <= ?
      ORDER BY cc.created_at DESC
      ''',
      parameters: [userId, startDate, endDate],
    );
    
    return results.map((row) => _convertCustomerCallRow(row)).toList();
  } catch (e) {
    print('Error getting customer calls: $e');
    return [];
  }
}

Map<String, dynamic> _convertCustomerCallRow(ResultRow row) {
  return {
    'id': row['id'],
    'type': 'customer_call',
    'companyId': row['company_id'],
    'customerId': row['customer_id'],
    'customerName': convertFromBlob(row['customerName']),
    'customerPhone': convertFromBlob(row['customerPhone']),
    'callType': convertCallTypeToString(row['call_type'] as int),
    'categoryId': row['category_id'],
    'category': convertFromBlob(row['categoryName']),
    'description': convertFromBlob(row['description']),
    'callNotes': convertFromBlob(row['call_notes']),
    'callDuration': row['call_duration'],
    'createdBy': convertFromBlob(row['createdByName']),
    'createdAt': row['created_at']?.toString(),
    'updatedAt': row['updated_at']?.toString(),
  };
} 