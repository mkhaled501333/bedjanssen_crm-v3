import 'package:dart_frog/dart_frog.dart';
import 'package:janssencrm_backend/database/database_service.dart';
import 'package:janssencrm_backend/models/city.dart';
import 'package:janssencrm_backend/models/governorate.dart';

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

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => await _get(context),
    HttpMethod.options => _handleOptions(),
    _ => _addCorsHeaders(Response(statusCode: 405)),
  };
}

Response _handleOptions() {
  return _addCorsHeaders(Response(
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  ));
}

Future<Response> _get(RequestContext context) async {
  try {
    final governoratesResults = await DatabaseService.query(
      'SELECT id, name FROM governorates ORDER BY name',
      userId: 1, // System user for read operations
    );
    final governorates = governoratesResults.map((row) => Governorate.fromJson(row.fields)).toList();

    final citiesResults = await DatabaseService.query(
      'SELECT id, name, governorate_id FROM cities ORDER BY name',
      userId: 1, // System user for read operations
    );
    final cities = citiesResults.map((row) => City.fromJson(row.fields)).toList();

    final citiesByGovId = <int, List<City>>{};
    for (final city in cities) {
      citiesByGovId.putIfAbsent(city.governorateId, () => []).add(city);
    }

    final responseData = governorates.map((gov) {
      final govJson = gov.toJson();
      govJson['cities'] = (citiesByGovId[gov.id] ?? []).map((c) => c.toJson()).toList();
      return govJson;
    }).toList();

    return _addCorsHeaders(Response.json(body: responseData));
  } catch (e) {
    return _addCorsHeaders(Response.json(
      statusCode: 500,
      body: {'message': 'Internal server error', 'error': e.toString()},
    ));
  }
} 