import 'package:janssencrm_backend/database/database_service.dart';
import 'package:mysql1/mysql1.dart';
import 'utils.dart';

/// Get ticket calls created by a specific user within a date range
Future<List<Map<String, dynamic>>> getTicketCalls(int userId, String startDate, String endDate) async {
  try {
    final results = await DatabaseService.query(
      '''
      SELECT
        tc.id,
        tc.company_id,
        tc.ticket_id,
        tc.call_type,
        tc.call_cat_id,
        tc.description,
        tc.call_notes,
        tc.call_duration,
        tc.created_by,
        tc.created_at,
        tc.updated_at,
        cat.name AS categoryName,
        u.name AS createdByName,
        t.id AS ticketNumber,
        t.description AS ticketTitle,
        c.name AS customerName,
        (SELECT phone FROM customer_phones WHERE customer_id = c.id LIMIT 1) AS customerPhone
      FROM ticketcall tc
      LEFT JOIN users u ON tc.created_by = u.id
      LEFT JOIN call_categories cat ON tc.call_cat_id = cat.id
      LEFT JOIN tickets t ON tc.ticket_id = t.id
      LEFT JOIN customers c ON t.customer_id = c.id
      WHERE tc.created_by = ?
        AND DATE(tc.created_at) >= ?
        AND DATE(tc.created_at) <= ?
      ORDER BY tc.created_at DESC
      ''',
      parameters: [userId, startDate, endDate],
    );
    
    return results.map((row) => _convertTicketCallRow(row)).toList();
  } catch (e) {
    print('Error getting ticket calls: $e');
    return [];
  }
}

Map<String, dynamic> _convertTicketCallRow(ResultRow row) {
  return {
    'id': row['id'],
    'type': 'ticket_call',
    'companyId': row['company_id'],
    'ticketId': row['ticket_id'],
    'ticketNumber': convertFromBlob(row['ticketNumber']),
    'ticketTitle': convertFromBlob(row['ticketTitle']),
    'customerName': convertFromBlob(row['customerName']),
    'customerPhone': convertFromBlob(row['customerPhone']),
    'callType': convertCallTypeToString(row['call_type'] as int),
    'callCatId': row['call_cat_id'],
    'category': convertFromBlob(row['categoryName']),
    'description': convertFromBlob(row['description']),
    'callNotes': convertFromBlob(row['call_notes']),
    'callDuration': row['call_duration'],
    'createdBy': convertFromBlob(row['createdByName']),
    'createdAt': row['created_at']?.toString(),
    'updatedAt': row['updated_at']?.toString(),
  };
} 