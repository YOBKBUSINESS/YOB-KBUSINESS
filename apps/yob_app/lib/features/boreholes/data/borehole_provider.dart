import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/providers.dart';

final boreholeApiProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider), '/boreholes');
});

class BoreholeListState {
  final List<Borehole> boreholes;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? statusFilter;

  const BoreholeListState({
    this.boreholes = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.statusFilter,
  });

  BoreholeListState copyWith({
    List<Borehole>? boreholes,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
  }) {
    return BoreholeListState(
      boreholes: boreholes ?? this.boreholes,
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

class BoreholeListNotifier extends StateNotifier<BoreholeListState> {
  final ApiService _api;

  BoreholeListNotifier(this._api) : super(const BoreholeListState()) {
    loadBoreholes();
  }

  Future<void> loadBoreholes({int page = 1}) async {
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
          .map((e) => Borehole.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        boreholes: items,
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
    loadBoreholes();
  }

  void filterByStatus(String? status) {
    state = state.copyWith(statusFilter: status);
    loadBoreholes();
  }

  Future<void> deleteBorehole(String id) async {
    try {
      await _api.delete(id);
      loadBoreholes(page: state.page);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void nextPage() {
    if (state.page < state.totalPages) loadBoreholes(page: state.page + 1);
  }

  void previousPage() {
    if (state.page > 1) loadBoreholes(page: state.page - 1);
  }
}

final boreholeListProvider =
    StateNotifierProvider<BoreholeListNotifier, BoreholeListState>((ref) {
  return BoreholeListNotifier(ref.watch(boreholeApiProvider));
});

final boreholeDetailProvider =
    FutureProvider.family<Borehole?, String>((ref, id) async {
  final api = ref.watch(boreholeApiProvider);
  try {
    final data = await api.getById(id);
    return Borehole.fromJson(data);
  } catch (_) {
    return null;
  }
});
