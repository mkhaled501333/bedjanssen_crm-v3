import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/models/user.dart';
import 'package:janssencrm_backend/services/activity_log_service.dart';
import 'package:janssencrm_backend/services/reports/tickets_utils/data_transformer.dart';

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
      case HttpMethod.post:
        return await _handlePost(context, userId);
      default:
        return _addCorsHeaders(
          Response.json(
            statusCode: 405,
            body: {'error': 'Method not allowed'},
          ),
        );
    }
  } catch (e) {
    print('Error in user permissions: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {'error': 'Internal server error: ${e.toString()}'},
      ),
    );
  }
}

/// Handle GET requests - Get user permissions
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
    
    // Return user permissions with permission details
    final permissionDetails = await _getPermissionDetails(user.permissions);
    
    return _addCorsHeaders(
      Response.json(
        statusCode: 200,
        body: {
          'userId': user.id,
          'username': user.username,
          'name': user.name,
          'permissions': user.permissions,
          'permissionDetails': permissionDetails,
        },
      ),
    );
  } catch (e) {
    print('Error getting user permissions: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {'error': 'Failed to get user permissions: ${e.toString()}'},
      ),
    );
  }
}

/// Handle PUT requests - Update user permissions (replace all)
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
    
    // Parse new permissions
    final newPermissions = data['permissions'] != null 
        ? List<int>.from(data['permissions'] as List)
        : <int>[];
    
    // Validate permissions
    final validationResult = await _validatePermissions(newPermissions);
    if (!(validationResult['valid'] as bool)) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 400,
          body: {'error': validationResult['message']},
        ),
      );
    }
    
    // Update user with new permissions
    final updatedUser = User(
      id: userId,
      companyId: existingUser.companyId,
      name: existingUser.name,
      username: existingUser.username,
      password: existingUser.password,
      createdBy: existingUser.createdBy,
      isActive: existingUser.isActive,
      permissions: newPermissions,
      createdAt: existingUser.createdAt,
    );
    
    final savedUser = await updatedUser.save();
    
    // Log activity
    final updatedBy = data['updatedBy'] as int? ?? userId;
    await ActivityLogService.logByNames(
      entityName: 'users',
      recordId: userId,
      activityName: 'UPDATE',
      userId: updatedBy,
      details: {
        'username': savedUser.username,
        'action': 'update_permissions',
        'newPermissions': newPermissions,
        'permissionCount': newPermissions.length,
      },
    );
    
    final permissionDetails = await _getPermissionDetails(savedUser.permissions);
    
    return _addCorsHeaders(
      Response.json(
        statusCode: 200,
        body: {
          'message': 'User permissions updated successfully',
          'userId': savedUser.id,
          'username': savedUser.username,
          'permissions': savedUser.permissions,
          'permissionDetails': permissionDetails,
        },
      ),
    );
  } catch (e) {
    print('Error updating user permissions: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {'error': 'Failed to update user permissions: ${e.toString()}'},
      ),
    );
  }
}

/// Handle POST requests - Add permissions to user
Future<Response> _handlePost(RequestContext context, int userId) async {
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
    
    // Parse permissions to add
    final permissionsToAdd = data['permissions'] != null 
        ? List<int>.from(data['permissions'] as List)
        : <int>[];
    
    if (permissionsToAdd.isEmpty) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 400,
          body: {'error': 'No permissions provided'},
        ),
      );
    }
    
    // Validate permissions
    final validationResult = await _validatePermissions(permissionsToAdd);
    if (!(validationResult['valid'] as bool)) {
      return _addCorsHeaders(
        Response.json(
          statusCode: 400,
          body: {'error': validationResult['message']},
        ),
      );
    }
    
    // Merge with existing permissions (avoid duplicates)
    final currentPermissions = Set<int>.from(existingUser.permissions);
    currentPermissions.addAll(permissionsToAdd);
    final newPermissions = currentPermissions.toList()..sort();
    
    // Update user with new permissions
    final updatedUser = User(
      id: userId,
      companyId: existingUser.companyId,
      name: existingUser.name,
      username: existingUser.username,
      password: existingUser.password,
      createdBy: existingUser.createdBy,
      isActive: existingUser.isActive,
      permissions: newPermissions,
      createdAt: existingUser.createdAt,
    );
    
    final savedUser = await updatedUser.save();
    
    // Log activity
    final updatedBy = data['updatedBy'] as int? ?? userId;
    await ActivityLogService.logByNames(
      entityName: 'users',
      recordId: userId,
      activityName: 'UPDATE',
      userId: updatedBy,
      details: {
        'username': savedUser.username,
        'action': 'add_permissions',
        'addedPermissions': permissionsToAdd,
        'totalPermissions': newPermissions,
      },
    );
    
    final permissionDetails = await _getPermissionDetails(savedUser.permissions);
    
    return _addCorsHeaders(
      Response.json(
        statusCode: 200,
        body: {
          'message': 'Permissions added successfully',
          'userId': savedUser.id,
          'username': savedUser.username,
          'permissions': savedUser.permissions,
          'permissionDetails': permissionDetails,
          'addedPermissions': permissionsToAdd,
        },
      ),
    );
  } catch (e) {
    print('Error adding user permissions: $e');
    return _addCorsHeaders(
      Response.json(
        statusCode: 500,
        body: {'error': 'Failed to add user permissions: ${e.toString()}'},
      ),
    );
  }
}

/// Validate permissions
Future<Map<String, dynamic>> _validatePermissions(List<int> permissions) async {
  final validPermissions = await _getValidPermissions();
  
  for (final permission in permissions) {
    if (!validPermissions.containsKey(permission)) {
      return {
        'valid': false,
        'message': 'Invalid permission ID: $permission',
      };
    }
  }
  
  return {'valid': true};
}

/// Get valid permissions mapping from database
Future<Map<int, String>> _getValidPermissions() async {
  try {
    final results = await DatabaseService.query('SELECT id, title FROM permissions ORDER BY id');
    final Map<int, String> permissions = {};
    
    for (final row in results) {
      final id = row['id'] as int;
      final title = DataTransformer.convertFromBlob(row['title']) as String?;
      permissions[id] = title ?? 'Unknown Permission';
    }
    
    return permissions;
  } catch (e) {
    print('Error fetching permissions from database: $e');
    // Fallback to hardcoded permissions if database query fails
    return {
      1: 'View Users',
      2: 'Create Users',
      3: 'Edit Users',
      4: 'Delete Users',
      5: 'Manage User Permissions',
      10: 'View Tickets',
      11: 'Create Tickets',
      12: 'Edit Tickets',
      13: 'Delete Tickets',
      14: 'Close Tickets',
      20: 'View Customers',
      21: 'Create Customers',
      22: 'Edit Customers',
      23: 'Delete Customers',
      30: 'View Reports',
      31: 'Export Reports',
      40: 'View Master Data',
      41: 'Edit Master Data',
      50: 'View Activity Logs',
      60: 'System Administration',
    };
  }
}

/// Get permission details
Future<List<Map<String, dynamic>>> _getPermissionDetails(List<int> permissions) async {
  final validPermissions = await _getValidPermissions();
  
  return permissions.map((permissionId) => {
    'id': permissionId,
    'name': validPermissions[permissionId] ?? 'Unknown Permission',
    'valid': validPermissions.containsKey(permissionId),
  }).toList();
}