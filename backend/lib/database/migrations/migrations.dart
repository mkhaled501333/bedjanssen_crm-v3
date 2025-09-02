import 'package:mysql1/mysql1.dart';
import 'index.dart';

/// Main migration orchestrator
Future<void> runMigrations(MySqlConnection conn) async {
  try {
    print('Starting database migrations...');

    // Create basic tables (without activity_logs foreign keys first)
    await createBasicTablesWithoutForeignKeys(conn);

    // Insert activities data (entities and activities must exist before activity_logs)
    await insertActivitiesData(conn);

    // Create activity_logs table with foreign keys (after entities and activities exist)
    await createActivityLogsTable(conn);

    // Create optimized indexes for tickets report service
    await createOptimizedTicketsReportIndexes(conn);

    // Create additional indexes for ticket items report view optimization
    await createTicketItemsReportIndexes(conn);

    // Create ticket items report view
    await createTicketItemsReportView(conn);

    // Create audit triggers
    await createAuditTriggers(conn);

    print('✓ All migrations completed: database schema and indexes ensured.');
  } catch (e) {
    print('✗ Migration failed: $e');
    rethrow;
  }
}
