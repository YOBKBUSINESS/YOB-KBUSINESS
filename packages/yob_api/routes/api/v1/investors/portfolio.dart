import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/investor_repository.dart';

/// GET /api/v1/investors/portfolio — portfolio summary.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Méthode non autorisée'},
    );
  }

  final repo = context.read<InvestorRepository>();
  final summary = await repo.getPortfolioSummary();
  final byProject = await repo.getByProject();

  return Response.json(body: {
    ...summary,
    'byProject': byProject,
  });
}
