import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/transaction_repository.dart';

/// GET /api/v1/finances/treasury — real-time treasury balance
/// Query params: ?threshold=500000
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  try {
    final repo = context.read<TransactionRepository>();
    final params = context.request.uri.queryParameters;
    final threshold =
        double.tryParse(params['threshold'] ?? '500000') ?? 500000;

    final alert = await repo.checkAlert(threshold: threshold);
    return Response.json(body: {'success': true, 'data': alert});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}
