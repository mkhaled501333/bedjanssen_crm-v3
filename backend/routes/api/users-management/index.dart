import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/models/user.dart';
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
  print('Users Management endpoint called: ${request.method}');

  // Handle CORS preflight
  if (request.method == HttpMethod.options) {
    return _addCorsHeaders(Response());
  }

  try {
    switch (request.method) {
      case HttpMethod.get:
        return await _handleGet(context);
      case HttpMethod.post:
        return await _handlePost(context);
      default:
        return _addCorsHeaders(
          Response.json(
            statusCode: 405,
            body: {'error': 'Method not allowed'},
          ),
        );
    }
  } catch (e) {
    print('Error in users management: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {'error': 'Internal server error: ${e.toString()}'},
      ),
    );
  }
}

/// Handle GET requests - Get all users with pagination
Future<Response> _handleGet(RequestContext context) async {
  try {
    final request = context.request;
    final uri = request.uri;
    
    // Parse query parameters
    final limitParam = uri.queryParameters['limit'];
    final offsetParam = uri.queryParameters['offset'];
    final searchParam = uri.queryParameters['search'];
    
    final limit = limitParam != null ? int.tryParse(limitParam) ?? 10 : 10;
    final offset = offsetParam != null ? int.tryParse(offsetParam) ?? 0 : 0;
    
    List<User> users;
    int totalCount;
    
    if (searchParam != null && searchParam.isNotEmpty) {
      // Search users
      users = await User.search(searchParam);
      totalCount = users.length;
    } else {
      // Get users with pagination
      users = await User.findWithPagination(limit: limit, offset: offset);
      totalCount = await User.count();
    }
    
    // Convert users to safe format (without passwords)
    final safeUsers = users.map((user) => {
      'id': user.id,
      'companyId': user.companyId,
      'name': user.name,
      'username': user.username,
      'createdBy': user.createdBy,
      'isActive': user.isActive,
      'permissions': user.permissions,
      'createdAt': user.createdAt?.toIso8601String(),
      'updatedAt': user.updatedAt?.toIso8601String(),
    }).toList();
    
    return _addCorsHeaders(
      Response.json(
        statusCode: 200,
        body: {
          'users': safeUsers,
          'pagination': {
            'total': totalCount,
            'limit': limit,
            'offset': offset,
            'hasMore': offset + limit < totalCount,
          },
        },
      ),
    );
  } catch (e) {
    print('Error getting users: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {'error': 'Failed to get users: ${e.toString()}'},
      ),
    );
  }
}

/// Handle POST requests - Create new user
Future<Response> _handlePost(RequestContext context) async {
  try {
    final request = context.request;
    final data = await request.json() as Map<String, dynamic>;
    
    // Validate required fields
    final name = data['name']?.toString();
    final username = data['username']?.toString();
    final password = data['password']?.toString();
    final companyId = data['companyId'] as int?;
    
    if (name == null || username == null || password == null || companyId == null) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 400,
          body: {'error': 'Name, username, password, and companyId are required'},
        ),
      );
    }
    
    // Check if username already exists
    if (await User.usernameExists(username)) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 409,
          body: {'error': 'Username already exists'},
        ),
      );
    }
    
    // Parse optional fields
    final createdBy = data['createdBy'] as int?;
    final isActive = data['isActive'] as bool? ?? true;
    final permissions = data['permissions'] != null 
        ? List<int>.from(data['permissions'] as List)
        : <int>[];
    
    // Create new user
    final user = User(
      companyId: companyId,
      name: name,
      username: username,
      password: password,
      createdBy: createdBy,
      isActive: isActive,
      permissions: permissions,
    );
    
    final savedUser = await user.save();
    
    // Log activity
    await ActivityLogService.logByNames(
      entityName: 'users',
      recordId: savedUser.id!,
      activityName: 'CREATE',
      userId: createdBy ?? savedUser.id!,
      details: {
        'username': savedUser.username,
        'name': savedUser.name,
        'companyId': savedUser.companyId,
      },
    );
    
    // Return safe user data (without password)
    final safeUser = {
      'id': savedUser.id,
      'companyId': savedUser.companyId,
      'name': savedUser.name,
      'username': savedUser.username,
      'createdBy': savedUser.createdBy,
      'isActive': savedUser.isActive,
      'permissions': savedUser.permissions,
      'createdAt': savedUser.createdAt?.toIso8601String(),
      'updatedAt': savedUser.updatedAt?.toIso8601String(),
    };
    
    return _addCorsHeaders(
      Response.json(
        statusCode: 201,
        body: {
          'message': 'User created successfully',
          'user': safeUser,
        },
      ),
    );
  } catch (e) {
    print('Error creating user: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {'error': 'Failed to create user: ${e.toString()}'},
      ),
    );
  }
}