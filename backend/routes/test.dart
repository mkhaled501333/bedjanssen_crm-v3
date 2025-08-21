import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return switch (context.request.method) {
    HttpMethod.get => _handleGet(context),
    _ => Response(statusCode: 405, body: 'Method not allowed'),
  };
}

Response _handleGet(RequestContext context) {
  return Response.json(
    body: {
      'status': 'ok',
      'message': 'Test endpoint working',
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
}