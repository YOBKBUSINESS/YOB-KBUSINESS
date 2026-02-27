import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/providers.dart';

final kitApiProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider), '/kits');
});

class KitListState {
  final List<AgriculturalKit> kits;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? statusFilter;

  const KitListState({
    this.kits = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.statusFilter,
  });

  KitListState copyWith({
    List<AgriculturalKit>? kits,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
  }) {
    return KitListState(
      kits: kits ?? this.kits,
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

class KitListNotifier extends StateNotifier<KitListState> {
  final ApiService _api;

  KitListNotifier(this._api) : super(const KitListState()) {
    loadKits();
  }

  Future<void> loadKits({int page = 1}) async {
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
          .map((e) => AgriculturalKit.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        kits: items,
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
    loadKits();
  }

  void filterByStatus(String? status) {
    state = state.copyWith(statusFilter: status);
    loadKits();
  }

  Future<void> createKit(Map<String, dynamic> data) async {
    await _api.create(data);
    loadKits();
  }

  Future<void> updateKit(String id, Map<String, dynamic> data) async {
    await _api.update(id, data);
    loadKits(page: state.page);
  }

  Future<void> deleteKit(String id) async {
    try {
      await _api.delete(id);
      loadKits(page: state.page);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void nextPage() {
    if (state.page < state.totalPages) loadKits(page: state.page + 1);
  }

  void previousPage() {
    if (state.page > 1) loadKits(page: state.page - 1);
  }
}

final kitListProvider =
    StateNotifierProvider<KitListNotifier, KitListState>((ref) {
  return KitListNotifier(ref.watch(kitApiProvider));
});

final kitDetailProvider =
    FutureProvider.family<AgriculturalKit?, String>((ref, id) async {
  final api = ref.watch(kitApiProvider);
  try {
    final data = await api.getById(id);
    return AgriculturalKit.fromJson(data);
  } catch (_) {
    return null;
  }
});
