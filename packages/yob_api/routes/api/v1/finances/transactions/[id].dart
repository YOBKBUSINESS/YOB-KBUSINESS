import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/transaction_repository.dart';

/// GET    /api/v1/finances/transactions/:id
/// PUT    /api/v1/finances/transactions/:id
/// DELETE /api/v1/finances/transactions/:id
Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _onGet(context, id),
    HttpMethod.put => _onPut(context, id),
    HttpMethod.delete => _onDelete(context, id),
    _ => Future.value(
        Response.json(
          statusCode: HttpStatus.methodNotAllowed,
          body: {'success': false, 'message': 'Method not allowed'},
        ),
      ),
  };
}

Future<Response> _onGet(RequestContext context, String id) async {
  try {
    final repo = context.read<TransactionRepository>();
    final tx = await repo.findById(id);
    if (tx == null) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Transaction non trouvée'},
      );
    }
    return Response.json(body: {'success': true, 'data': tx});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}

Future<Response> _onPut(RequestContext context, String id) async {
  try {
    final repo = context.read<TransactionRepository>();
    final body = await context.request.json() as Map<String, dynamic>;
    final tx = await repo.update(id, body);
    if (tx == null) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Transaction non trouvée'},
      );
    }
    return Response.json(body: {'success': true, 'data': tx});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}

Future<Response> _onDelete(RequestContext context, String id) async {
  try {
    final repo = context.read<TransactionRepository>();
    final deleted = await repo.delete(id);
    if (!deleted) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Transaction non trouvée'},
      );
    }
    return Response.json(
      body: {'success': true, 'message': 'Transaction supprimée'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}
