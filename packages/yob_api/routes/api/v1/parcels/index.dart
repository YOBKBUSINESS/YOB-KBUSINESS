import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/parcel_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _onGet(context),
    HttpMethod.post => _onPost(context),
    _ => Future.value(
        Response.json(
          statusCode: HttpStatus.methodNotAllowed,
          body: {'success': false, 'message': 'Method not allowed'},
        ),
      ),
  };
}

Future<Response> _onGet(RequestContext context) async {
  try {
    final repo = context.read<ParcelRepository>();
    final params = context.request.uri.queryParameters;

    final result = await repo.findAll(
      page: int.tryParse(params['page'] ?? '1') ?? 1,
      limit: int.tryParse(params['limit'] ?? '20') ?? 20,
      search: params['search'],
      cropType: params['crop_type'],
      tenureStatus: params['tenure_status'],
      producerId: params['producer_id'],
    );

    return Response.json(body: {'success': true, 'data': result});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}

Future<Response> _onPost(RequestContext context) async {
  try {
    final repo = context.read<ParcelRepository>();
    final body = await context.request.json() as Map<String, dynamic>;

    if (body['name'] == null || body['crop_type'] == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Nom et type de culture sont requis',
        },
      );
    }

    final parcel = await repo.create(body);
    return Response.json(
      statusCode: 201,
      body: {'success': true, 'data': parcel},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}
