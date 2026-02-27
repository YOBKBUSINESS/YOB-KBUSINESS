import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/dashboard_repository.dart';

/// GET /api/v1/dashboard — full strategic dashboard data.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Méthode non autorisée'},
    );
  }

  final repo = context.read<DashboardRepository>();

  final results = await Future.wait([
    repo.getKpis(),
    repo.getAlerts(),
    repo.getActiveProjects(),
    repo.getModuleSummary(),
    repo.getRecentActivity(),
  ]);

  return Response.json(body: {
    'kpis': results[0],
    'alerts': results[1],
    'activeProjects': results[2],
    'moduleSummary': results[3],
    'recentActivity': results[4],
  });
}
