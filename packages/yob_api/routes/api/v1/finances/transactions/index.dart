import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/transaction_repository.dart';

/// GET  /api/v1/finances/transactions — list transactions
/// POST /api/v1/finances/transactions — create transaction
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
    final repo = context.read<TransactionRepository>();
    final params = context.request.uri.queryParameters;

    final result = await repo.findAll(
      page: int.tryParse(params['page'] ?? '1') ?? 1,
      limit: int.tryParse(params['limit'] ?? '20') ?? 20,
      search: params['search'],
      type: params['type'],
      category: params['category'],
      dateFrom: params['dateFrom'],
      dateTo: params['dateTo'],
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
    final repo = context.read<TransactionRepository>();
    final body = await context.request.json() as Map<String, dynamic>;

    if (body['type'] == null ||
        body['amount'] == null ||
        body['description'] == null ||
        body['date'] == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'type, amount, description et date sont requis',
        },
      );
    }

    // Inject authenticated user as creator
    final userId = context.read<String?>(); // from auth middleware user_id
    body['createdBy'] = userId;

    final tx = await repo.create(body);
    return Response.json(
      statusCode: 201,
      body: {'success': true, 'data': tx},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}
