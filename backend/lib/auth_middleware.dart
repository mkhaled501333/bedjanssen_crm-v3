import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

Middleware jwtAuthentication({required String secretKey}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: jsonEncode({'error': 'Missing or invalid Authorization header'}), headers: {'Content-Type': 'application/json'});
      }
      final token = authHeader.substring(7);
      try {
        final jwt = JWT.verify(token, SecretKey(secretKey));
        // Attach user info from JWT to request context
        final updatedRequest = request.change(context: {'user': jwt.payload});
        return await innerHandler(updatedRequest);
      } catch (e) {
        return Response(401, body: jsonEncode({'error': 'Invalid or expired token'}), headers: {'Content-Type': 'application/json'});
      }
    };
  };
} 