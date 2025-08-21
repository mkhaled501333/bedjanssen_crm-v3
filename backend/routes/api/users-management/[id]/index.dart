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

Future<Response> onRequest(RequestContext context, String id) async {
  final request = context.request;
  print('User Management [id] endpoint called: ${request.method} for ID: $id');

  // Handle CORS preflight
  if (request.method == HttpMethod.options) {
    return _addCorsHeaders(Response());
  }

  // Parse and validate ID
  final userId = int.tryParse(id);
  if (userId == null) {
    return _addCorsHeaders(
      Response.json(
        statusCode: 400,
        body: {'error': 'Invalid user ID'},
      ),
    );
  }

  try {
    switch (request.method) {
      case HttpMethod.get:
        return await _handleGet(context, userId);
      case HttpMethod.put:
        return await _handlePut(context, userId);
      case HttpMethod.delete:
        return await _handleDelete(context, userId);
      default:
        return _addCorsHeaders(
          Response.json(
            statusCode: 405,
            body: {'error': 'Method not allowed'},
          ),
        );
    }
  } catch (e) {
    print('Error in user management [id]: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {'error': 'Internal server error: ${e.toString()}'},
      ),
    );
  }
}

/// Handle GET requests - Get user by ID
Future<Response> _handleGet(RequestContext context, int userId) async {
  try {
    final user = await User.findById(userId);
    
    if (user == null) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 404,
          body: {'error': 'User not found'},
        ),
      );
    }
    
    // Return safe user data (without password)
    final safeUser = {
      'id': user.id,
      'companyId': user.companyId,
      'name': user.name,
      'username': user.username,
      'createdBy': user.createdBy,
      'isActive': user.isActive,
      'permissions': user.permissions,
      'createdAt': user.createdAt?.toIso8601String(),
      'updatedAt': user.updatedAt?.toIso8601String(),
    };
    
    return _addCorsHeaders(
      Response.json(
        statusCode: 200,
        body: {'user': safeUser},
      ),
    );
  } catch (e) {
    print('Error getting user: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {'error': 'Failed to get user: ${e.toString()}'},
      ),
    );
  }
}

/// Handle PUT requests - Update user
Future<Response> _handlePut(RequestContext context, int userId) async {
  try {
    final request = context.request;
    final data = await request.json() as Map<String, dynamic>;
    
    // Find existing user
    final existingUser = await User.findById(userId);
    if (existingUser == null) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 404,
          body: {'error': 'User not found'},
        ),
      );
    }
    
    // Validate required fields (use existing values if not provided)
    final name = data['name']?.toString() ?? existingUser.name;
    final username = data['username']?.toString() ?? existingUser.username;
    final companyId = data['companyId'] as int? ?? existingUser.companyId;
    
    // Check if username already exists (excluding current user)
    if (username != existingUser.username && await User.usernameExists(username, excludeId: userId)) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 409,
          body: {'error': 'Username already exists'},
        ),
      );
    }
    
    // Parse optional fields
    final password = data['password']?.toString() ?? existingUser.password;
    final createdBy = data['createdBy'] as int? ?? existingUser.createdBy;
    final isActive = data['isActive'] as bool? ?? existingUser.isActive;
    final permissions = data['permissions'] != null 
        ? List<int>.from(data['permissions'] as List)
        : existingUser.permissions;
    
    // Create updated user
    final updatedUser = User(
      id: userId,
      companyId: companyId,
      name: name,
      username: username,
      password: password,
      createdBy: createdBy,
      isActive: isActive,
      permissions: permissions,
      createdAt: existingUser.createdAt,
    );
    
    final savedUser = await updatedUser.save();
    
    // Log activity
    await ActivityLogService.logByNames(
      entityName: 'users',
      recordId: userId,
      activityName: 'UPDATE',
      userId: createdBy ?? userId,
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
        statusCode: 200,
        body: {
          'message': 'User updated successfully',
          'user': safeUser,
        },
      ),
    );
  } catch (e) {
    print('Error updating user: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {'error': 'Failed to update user: ${e.toString()}'},
      ),
    );
  }
}

/// Handle DELETE requests - Delete user functionality disabled
Future<Response> _handleDelete(RequestContext context, int userId) async {
  // Delete user functionality has been disabled for security purposes
  return _addCorsHeaders(
    Response.json(
      statusCode: 403,
      body: {'error': 'Delete user functionality has been disabled'},
    ),
  );
}