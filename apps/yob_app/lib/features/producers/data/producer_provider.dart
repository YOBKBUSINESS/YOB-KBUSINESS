import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/providers.dart';

/// API service for producers.
final producerApiProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider), '/producers');
});

/// State for the producers list view.
class ProducerListState {
  final List<Producer> producers;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? statusFilter;

  const ProducerListState({
    this.producers = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.statusFilter,
  });

  ProducerListState copyWith({
    List<Producer>? producers,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
  }) {
    return ProducerListState(
      producers: producers ?? this.producers,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class ProducerListNotifier extends StateNotifier<ProducerListState> {
  final ApiService _api;

  ProducerListNotifier(this._api) : super(const ProducerListState()) {
    loadProducers();
  }

  Future<void> loadProducers({int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': '20',
      };
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        params['search'] = state.searchQuery!;
      }
      if (state.statusFilter != null && state.statusFilter!.isNotEmpty) {
        params['status'] = state.statusFilter!;
      }

      final data = await _api.getAll(queryParams: params);
      final items = (data['items'] as List<dynamic>)
          .map((e) => Producer.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        producers: items,
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
    loadProducers();
  }

  void filterByStatus(String? status) {
    state = state.copyWith(statusFilter: status);
    loadProducers();
  }

  Future<void> deleteProducer(String id) async {
    try {
      await _api.delete(id);
      loadProducers(page: state.page);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void nextPage() {
    if (state.page < state.totalPages) loadProducers(page: state.page + 1);
  }

  void previousPage() {
    if (state.page > 1) loadProducers(page: state.page - 1);
  }
}

final producerListProvider =
    StateNotifierProvider<ProducerListNotifier, ProducerListState>((ref) {
  return ProducerListNotifier(ref.watch(producerApiProvider));
});

/// Provider for a single producer detail.
final producerDetailProvider =
    FutureProvider.family<Producer?, String>((ref, id) async {
  final api = ref.watch(producerApiProvider);
  try {
    final data = await api.getById(id);
    return Producer.fromJson(data);
  } catch (_) {
    return null;
  }
});
