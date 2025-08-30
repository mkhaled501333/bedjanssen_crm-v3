import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:janssencrm_backend/models/user.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';

Response _addCorsHeaders(Response response) => response.copyWith(
  headers: {
    ...response.headers,
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Origin,Content-Type,Authorization',
  },
);

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;
  print('Login endpoint called');

  // Handle CORS preflight
  if (request.method == HttpMethod.options) {
    return _addCorsHeaders(Response());
  }

  try {
    final data = await request.json() as Map<String, dynamic>;
    print(data);
    final username = data['username']?.toString();
    final password = data['password']?.toString();

    if (username == null || password == null) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 400,
          body: {'error': 'Username and password are required'},
        ),
      );
    }

    final user = await User.findByUsername(username);
    if (user == null || !user.isActive) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 401,
          body: {'error': 'Invalid credentials'},
        ),
      );
    }

    // Compare password as plain text (no hashing)
    final valid = password == user.password;
    if (!valid) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 401,
          body: {'error': 'Invalid credentials'},
        ),
      );
    }

    // Fetch company name by companyId
    final companyRow = await DatabaseService.queryOne(
      'SELECT name FROM companies WHERE id = ?',
      parameters: [user.companyId],
    );
    final companyName = companyRow != null ? companyRow['name'] : null;

    // Generate JWT token
    final jwt = JWT({
      'id': user.id,
      'username': user.username,
      'company_id': user.companyId,
      'name': user.name,
    });
    final token = jwt.sign(
      SecretKey('your-secret-key'),
      expiresIn: const Duration(hours: 8),
    );

    // Log login activity
    try {
      await ActivityLogService.log(
        entityId: 1, // users entity (ID 1 according to seed data)
        recordId: user.id!,
        activityId: 1, // User login activity
        userId: user.id!,
      );
    } catch (e) {
      print('Failed to log login activity: $e');
    }

    return _addCorsHeaders(
      Response.json(body: {
        'token': token,
        'user': {
          'id': user.id,
          'username': user.username,
          'name': user.name,
          'company_id': user.companyId,
          'company_name': companyName,
          'permissions': user.permissions,
        },
      }),
    );
  } catch (e) {
    return _addCorsHeaders(
      Response.json(
        statusCode: 400,
        body: {'error': 'Invalid request'},
      ),
    );
  }
}