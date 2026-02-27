import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/transaction_repository.dart';

/// GET /api/v1/finances/summary
/// Query params: ?year=2026
/// Returns monthly income/expense breakdown for the year.
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
    final year =
        int.tryParse(params['year'] ?? DateTime.now().year.toString()) ??
            DateTime.now().year;

    final monthly = await repo.getMonthlySummary(year);

    // Category breakdown for entire year
    final incomeBreakdown = await repo.getCategoryBreakdown(
      type: 'income',
      dateFrom: '$year-01-01',
      dateTo: '$year-12-31',
    );
    final expenseBreakdown = await repo.getCategoryBreakdown(
      type: 'expense',
      dateFrom: '$year-01-01',
      dateTo: '$year-12-31',
    );

    final treasury = await repo.getTreasury();

    return Response.json(body: {
      'success': true,
      'data': {
        'year': year,
        'monthly': monthly,
        'incomeBreakdown': incomeBreakdown,
        'expenseBreakdown': expenseBreakdown,
        'treasury': treasury,
      },
    });
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}
