import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_config.dart';
import 'package:janssencrm_backend/database/database_service.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _handleGet(context),
    _ => Response(statusCode: 405, body: 'Method not allowed'),
  };
}

Future<Response> _handleGet(RequestContext context) async {
  try {
    // Basic health check without database dependency
    final Map<String, Object?> healthStatus = {
      'status': 'healthy',
      'message': 'Janssen CRM Backend is running',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };

    // Try to check database status if initialized
    try {
      if (DatabaseConfig.isInitialized) {
        // Test database connection with a simple query first
        await DatabaseService.query(
          'SELECT 1',
          userId: 1, // System user for health check
        );
        
        final dbName = await DatabaseService.getCurrentDatabase();
        final usersTableExists = await DatabaseService.tableExists('users');
        
        healthStatus['database'] = {
          'connected': true,
          'name': dbName,
          'usersTableExists': usersTableExists,
        };
      } else {
        healthStatus['database'] = {
          'connected': false,
          'message': 'Database not initialized',
        };
      }
    } catch (dbError) {
      print('Database health check error: $dbError');
      healthStatus['database'] = {
        'connected': false,
        'error': dbError.toString(),
      };
    }
    
    return Response.json(body: healthStatus);
  } catch (e) {
    print('Health endpoint error: $e');
    return Response.json(
      statusCode: 500,
      body: {
        'status': 'error',
        'message': 'Health check failed',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}