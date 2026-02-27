import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/services/email_report_service.dart';

/// POST /api/v1/investors/reports — generate & send investor reports.
/// GET  /api/v1/investors/reports?investorId=...&year=...&month=... — preview.
Future<Response> onRequest(RequestContext context) async {
  final service = context.read<EmailReportService>();

  switch (context.request.method) {
    case HttpMethod.get:
      return _preview(context, service);
    case HttpMethod.post:
      return _generate(context, service);
    default:
      return Response.json(
        statusCode: 405,
        body: {'error': 'Méthode non autorisée'},
      );
  }
}

/// GET — Preview report for a single investor.
Future<Response> _preview(
  RequestContext context,
  EmailReportService service,
) async {
  final params = context.request.uri.queryParameters;
  final investorId = params['investorId'];
  final year = int.tryParse(params['year'] ?? '');
  final month = int.tryParse(params['month'] ?? '');

  if (investorId == null || year == null || month == null) {
    return Response.json(
      statusCode: 400,
      body: {
        'error': 'Paramètres requis: investorId, year, month',
      },
    );
  }

  try {
    final report = await service.previewReport(
      investorId: investorId,
      year: year,
      month: month,
    );
    return Response.json(body: report);
  } catch (e) {
    return Response.json(
      statusCode: 404,
      body: {'error': e.toString()},
    );
  }
}

/// POST — Generate reports for all investors for a period.
Future<Response> _generate(
  RequestContext context,
  EmailReportService service,
) async {
  final params = context.request.uri.queryParameters;
  final now = DateTime.now();
  final year = int.tryParse(params['year'] ?? '') ?? now.year;
  final month = int.tryParse(params['month'] ?? '') ?? now.month;

  final result = await service.generateInvestorReport(
    year: year,
    month: month,
  );

  return Response.json(body: result);
}
