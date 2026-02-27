import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/providers.dart';

/// Base API service for transaction CRUD (sub-path under /finances/transactions).
final transactionApiProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider), '/finances/transactions');
});

// ── Treasury ──

final treasuryProvider =
    FutureProvider.family<Map<String, dynamic>, double>((ref, threshold) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(
    '/finances/treasury',
    queryParameters: {'threshold': threshold.toString()},
  );
  final body = response.data as Map<String, dynamic>;
  if (body['success'] == true) {
    return body['data'] as Map<String, dynamic>;
  }
  throw Exception(body['message'] ?? 'Erreur');
});

/// Default treasury with 500k FCFA threshold.
final defaultTreasuryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/finances/treasury');
  final body = response.data as Map<String, dynamic>;
  if (body['success'] == true) {
    return body['data'] as Map<String, dynamic>;
  }
  throw Exception(body['message'] ?? 'Erreur');
});

// ── Annual Summary ──

final financeSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, year) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(
    '/finances/summary',
    queryParameters: {'year': year.toString()},
  );
  final body = response.data as Map<String, dynamic>;
  if (body['success'] == true) {
    return body['data'] as Map<String, dynamic>;
  }
  throw Exception(body['message'] ?? 'Erreur');
});

// ── Monthly Report ──

final monthlyReportProvider = FutureProvider.family<Map<String, dynamic>,
    ({int year, int month})>((ref, params) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(
    '/finances/report',
    queryParameters: {
      'year': params.year.toString(),
      'month': params.month.toString(),
    },
  );
  final body = response.data as Map<String, dynamic>;
  if (body['success'] == true) {
    return body['data'] as Map<String, dynamic>;
  }
  throw Exception(body['message'] ?? 'Erreur');
});

// ── Transaction List ──

class TransactionListState {
  final List<Transaction> transactions;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? typeFilter;
  final String? categoryFilter;

  const TransactionListState({
    this.transactions = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.typeFilter,
    this.categoryFilter,
  });

  TransactionListState copyWith({
    List<Transaction>? transactions,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? typeFilter,
    String? categoryFilter,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter ?? this.typeFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }
}

class TransactionListNotifier extends StateNotifier<TransactionListState> {
  final ApiService _api;

  TransactionListNotifier(this._api) : super(const TransactionListState()) {
    loadTransactions();
  }

  Future<void> loadTransactions({int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': '20',
      };
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        params['search'] = state.searchQuery!;
      }
      if (state.typeFilter != null && state.typeFilter!.isNotEmpty) {
        params['type'] = state.typeFilter!;
      }
      if (state.categoryFilter != null && state.categoryFilter!.isNotEmpty) {
        params['category'] = state.categoryFilter!;
      }

      final data = await _api.getAll(queryParams: params);
      final items = (data['items'] as List<dynamic>)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        transactions: items,
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
    loadTransactions();
  }

  void filterByType(String? type) {
    state = state.copyWith(typeFilter: type ?? '');
    loadTransactions();
  }

  void filterByCategory(String? category) {
    state = state.copyWith(categoryFilter: category ?? '');
    loadTransactions();
  }

  Future<void> createTransaction(Map<String, dynamic> data) async {
    await _api.create(data);
    loadTransactions();
  }

  Future<void> updateTransaction(
      String id, Map<String, dynamic> data) async {
    await _api.update(id, data);
    loadTransactions(page: state.page);
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _api.delete(id);
      loadTransactions(page: state.page);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() async => loadTransactions();

  void nextPage() {
    if (state.page < state.totalPages) {
      loadTransactions(page: state.page + 1);
    }
  }

  void previousPage() {
    if (state.page > 1) loadTransactions(page: state.page - 1);
  }
}

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, TransactionListState>((ref) {
  return TransactionListNotifier(ref.watch(transactionApiProvider));
});

final transactionDetailProvider =
    FutureProvider.family<Transaction?, String>((ref, id) async {
  final api = ref.watch(transactionApiProvider);
  try {
    final data = await api.getById(id);
    return Transaction.fromJson(data);
  } catch (_) {
    return null;
  }
});
