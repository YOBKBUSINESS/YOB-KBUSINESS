import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/transaction_repository.dart';

/// GET /api/v1/finances/report
/// Query params: ?year=2026&month=2
/// Returns detailed monthly financial report.
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
    final now = DateTime.now();
    final year = int.tryParse(params['year'] ?? now.year.toString()) ?? now.year;
    final month =
        int.tryParse(params['month'] ?? now.month.toString()) ?? now.month;

    if (month < 1 || month > 12) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Mois invalide (1-12)'},
      );
    }

    final report = await repo.getMonthlyReport(year, month);
    return Response.json(body: {'success': true, 'data': report});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}
