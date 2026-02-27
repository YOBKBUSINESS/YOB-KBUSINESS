import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/providers.dart';

/// Base API service for investor CRUD.
final investorApiProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider), '/investors');
});

// ── Portfolio Summary ──

final portfolioSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/investors/portfolio');
  final body = response.data as Map<String, dynamic>;
  return body;
});

// ── Investor List ──

class InvestorListState {
  final List<Investor> investors;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  const InvestorListState({
    this.investors = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });

  InvestorListState copyWith({
    List<Investor>? investors,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return InvestorListState(
      investors: investors ?? this.investors,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class InvestorListNotifier extends StateNotifier<InvestorListState> {
  final ApiService _api;

  InvestorListNotifier(this._api) : super(const InvestorListState()) {
    loadInvestors();
  }

  Future<void> loadInvestors({int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': '20',
      };
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        params['search'] = state.searchQuery!;
      }

      final data = await _api.getAll(queryParams: params);
      final items = (data['items'] as List<dynamic>)
          .map((e) => Investor.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        investors: items,
        total: data['total'] as int? ?? 0,
        page: data['page'] as int? ?? 1,
        totalPages: data['totalPages'] as int? ?? 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    loadInvestors();
  }

  Future<void> createInvestor(Map<String, dynamic> data) async {
    await _api.create(data);
    loadInvestors();
  }

  Future<void> updateInvestor(String id, Map<String, dynamic> data) async {
    await _api.update(id, data);
    loadInvestors(page: state.page);
  }

  Future<void> deleteInvestor(String id) async {
    try {
      await _api.delete(id);
      loadInvestors(page: state.page);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() async => loadInvestors();

  void nextPage() {
    if (state.page < state.totalPages) {
      loadInvestors(page: state.page + 1);
    }
  }

  void previousPage() {
    if (state.page > 1) loadInvestors(page: state.page - 1);
  }
}

final investorListProvider =
    StateNotifierProvider<InvestorListNotifier, InvestorListState>((ref) {
  return InvestorListNotifier(ref.watch(investorApiProvider));
});

final investorDetailProvider =
    FutureProvider.family<Investor?, String>((ref, id) async {
  final api = ref.watch(investorApiProvider);
  try {
    final data = await api.getById(id);
    return Investor.fromJson(data);
  } catch (_) {
    return null;
  }
});
