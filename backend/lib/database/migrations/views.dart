import 'package:mysql1/mysql1.dart';
import '../database_service.dart';

/// Create ticket items report view
Future<void> createTicketItemsReportView(MySqlConnection conn) async {
  print('Creating ticket items report view...');

  try {
    await DatabaseService.query(
      '''
      CREATE OR REPLACE VIEW ticket_items_report AS
      SELECT 
          c.id AS customer_id,
          c.name AS customer_name,
          c.governomate_id,
          g.name AS governorate_name,
          c.city_id,
          city.name AS city_name,
          t.id AS ticket_id,
          t.company_id,
          t.ticket_cat_id,
          tc.name AS ticket_category_name,
          t.status AS ticket_status,
          ti.id AS ticket_item_id,
          ti.product_id,
          pi.product_name,
          ti.product_size,
          ti.request_reason_id,
          rr.name AS request_reason_name,
          ti.inspected,
          ti.inspection_date,
          ti.client_approval,
          t.created_at AS ticket_created_at,
          
          CASE 
              WHEN tica.ticket_item_id IS NOT NULL THEN 'استبدال لنفس النوع'
              WHEN tics.ticket_item_id IS NOT NULL THEN 'استبدال لنوع اخر'
              WHEN tim.ticket_item_id IS NOT NULL THEN 'صيانه'
              ELSE NULL
          END AS action,
          
          CASE 
              WHEN tica.ticket_item_id IS NOT NULL THEN tica.pulled
              WHEN tics.ticket_item_id IS NOT NULL THEN tics.pulled
              WHEN tim.ticket_item_id IS NOT NULL THEN tim.pulled
              ELSE NULL
          END AS pulled_status,
          
          CASE 
              WHEN tica.ticket_item_id IS NOT NULL THEN tica.delivered
              WHEN tics.ticket_item_id IS NOT NULL THEN tics.delivered
              WHEN tim.ticket_item_id IS NOT NULL THEN tim.delivered
              ELSE NULL
          END AS delivered_status

      FROM ticket_items ti

      LEFT JOIN product_info pi ON ti.product_id = pi.id
      LEFT JOIN request_reasons rr ON ti.request_reason_id = rr.id
      LEFT JOIN tickets t ON ti.ticket_id = t.id
      LEFT JOIN ticket_categories tc ON t.ticket_cat_id = tc.id
      LEFT JOIN customers c ON t.customer_id = c.id
      LEFT JOIN governorates g ON c.governomate_id = g.id
      LEFT JOIN cities city ON c.city_id = city.id
      LEFT JOIN ticket_item_change_another tica ON ti.id = tica.ticket_item_id
      LEFT JOIN ticket_item_change_same tics ON ti.id = tics.ticket_item_id
      LEFT JOIN ticket_item_maintenance tim ON ti.id = tim.ticket_item_id

      ORDER BY ti.id
            ''',
      userId: 1, // System user for view creation
    );
    print('✓ Ticket items report view created successfully');
  } catch (e) {
    if (e.toString().contains('DDL operations are not allowed')) {
      print('⚠ DDL operations not allowed - ticket items report view may already exist');
    } else {
      print('✗ Error creating ticket items report view: $e');
      rethrow;
    }
  }
}
