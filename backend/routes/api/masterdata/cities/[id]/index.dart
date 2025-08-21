import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/models/city.dart';

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

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => await _get(context, id),
    HttpMethod.put => await _put(context, id),
    HttpMethod.delete => await _delete(context, id),
    HttpMethod.options => _handleOptions(),
    _ => _addCorsHeaders(Response(statusCode: 405)),
  };
}

Response _handleOptions() {
  return _addCorsHeaders(Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  ));
}

Future<Response> _get(RequestContext context, String id) async {
  try {
    final cityId = int.tryParse(id);
    if (cityId == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid ID'});
    }

    final result = await DatabaseService.queryOne(
      'SELECT id, name, governorate_id FROM cities WHERE id = ?',
      parameters: [cityId],
    );

    if (result == null) {
      return Response.json(statusCode: 404, body: {'message': 'City not found'});
    }

    return Response.json(body: City.fromJson(result.fields).toJson());
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    );
  }
}

Future<Response> _put(RequestContext context, String id) async {
  try {
    final cityId = int.tryParse(id);
    if (cityId == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid ID'});
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final name = body['name'] as String?;
    final governorateId = body['governorate_id'] as int?;

    if ((name == null || name.isEmpty) && governorateId == null) {
      return Response.json(statusCode: 400, body: {'message': 'Name or governorate_id is required'});
    }

    final existingCityResult = await DatabaseService.queryOne('SELECT name, governorate_id FROM cities WHERE id = ?', parameters: [cityId]);
    if (existingCityResult == null) {
        return Response.json(statusCode: 404, body: {'message': 'City not found'});
    }
    final existingCity = City.fromJson(existingCityResult.fields);


    final newName = name ?? existingCity.name;
    final newGovernorateId = governorateId ?? existingCity.governorateId;

    await DatabaseService.query(
      'UPDATE cities SET name = ?, governorate_id = ? WHERE id = ?',
      parameters: [newName, newGovernorateId, cityId],
    );

    return Response.json(body: {'id': cityId, 'name': newName, 'governorate_id': newGovernorateId});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    );
  }
}

Future<Response> _delete(RequestContext context, String id) async {
  try {
    final cityId = int.tryParse(id);
    if (cityId == null) {
      return Response.json(statusCode: 400, body: {'message': 'Invalid ID'});
    }

    await DatabaseService.query(
      'DELETE FROM cities WHERE id = ?',
      parameters: [cityId],
    );

    return Response(statusCode: 204);
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    );
  }
} 