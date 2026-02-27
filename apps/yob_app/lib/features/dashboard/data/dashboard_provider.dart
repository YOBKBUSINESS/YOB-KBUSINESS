import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/providers.dart';

/// Strategic dashboard data from /dashboard endpoint.
final dashboardDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/dashboard');
  return response.data as Map<String, dynamic>;
});

/// Investor email report generation.
final generateReportProvider = FutureProvider.family<Map<String, dynamic>,
    ({int year, int month})>((ref, params) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.post(
    '/investors/reports',
    queryParameters: {
      'year': params.year.toString(),
      'month': params.month.toString(),
    },
  );
  return response.data as Map<String, dynamic>;
});
