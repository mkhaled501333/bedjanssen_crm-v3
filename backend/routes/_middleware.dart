import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:janssencrm_backend/database/database_config.dart';
import 'package:janssencrm_backend/database/migrations/migrations.dart';

bool _isServerInitialized = false;

Handler middleware(Handler handler) {
  print('Middleware called');
  return (context) async {
    // Initialize database and run migrations on first request if not already initialized
    if (!_isServerInitialized) {
      try {
          // Initialize database connection
      await DatabaseConfig.initialize().then((value) {
        print('✓ Database connection initialized');
              // Run database migrations
       runMigrations(DatabaseConfig.connection);
      print('✓ Database migrations completed');
      
      });

        _isServerInitialized = true;
      } catch (e) {
        print('✗ Failed to initialize database connection or run migrations: $e');
      }
    }

    final path = context.request.uri.path;
    // Allow all OPTIONS requests without authentication
    if (context.request.method == HttpMethod.options) {
      final response = await handler(context);
      return _addCorsHeaders(response);
    }
    // Allow unauthenticated access to login and logout endpoints
    if (path == '/api/auth/login' || path == '/api/auth/logout') {
      final response = await handler(context);
      return _addCorsHeaders(response);
    }

    // JWT secret key (replace with env/config in production)
    final secretKey = 'your-secret-key';
    final authHeader = context.request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return _addCorsHeaders(Response.json(statusCode: 401, body: {'error': 'Missing or invalid Authorization header'}));
    }
    final token = authHeader.substring(7);
    try {
      final jwt = JWT.verify(token, SecretKey(secretKey));
      // Attach user info from JWT to context
      final updatedContext = context.provide(() => jwt.payload);
      final response = await handler(updatedContext);
      return _addCorsHeaders(response);
    } catch (e) {
      return _addCorsHeaders(Response.json(statusCode: 401, body: {'error': 'Invalid or expired token'}));
    }
  };
}

Response _addCorsHeaders(Response response) {
  return response.copyWith(
    headers: {
      ...response.headers,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  );
}

