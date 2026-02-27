import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/providers.dart';

final trainingApiProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider), '/trainings');
});

class TrainingListState {
  final List<Training> trainings;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  const TrainingListState({
    this.trainings = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });

  TrainingListState copyWith({
    List<Training>? trainings,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return TrainingListState(
      trainings: trainings ?? this.trainings,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TrainingListNotifier extends StateNotifier<TrainingListState> {
  final ApiService _api;

  TrainingListNotifier(this._api) : super(const TrainingListState()) {
    loadTrainings();
  }

  Future<void> loadTrainings({int page = 1}) async {
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
          .map((e) => Training.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        trainings: items,
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
    loadTrainings();
  }

  Future<void> createTraining(Map<String, dynamic> data) async {
    await _api.create(data);
    loadTrainings();
  }

  Future<void> updateTraining(String id, Map<String, dynamic> data) async {
    await _api.update(id, data);
    loadTrainings(page: state.page);
  }

  Future<void> deleteTraining(String id) async {
    try {
      await _api.delete(id);
      loadTrainings(page: state.page);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadTrainings();
  }

  void loadMore() {
    if (state.page < state.totalPages) loadTrainings(page: state.page + 1);
  }

  void nextPage() {
    if (state.page < state.totalPages) loadTrainings(page: state.page + 1);
  }

  void previousPage() {
    if (state.page > 1) loadTrainings(page: state.page - 1);
  }
}

final trainingListProvider =
    StateNotifierProvider<TrainingListNotifier, TrainingListState>((ref) {
  return TrainingListNotifier(ref.watch(trainingApiProvider));
});

final trainingDetailProvider =
    FutureProvider.family<Training?, String>((ref, id) async {
  final api = ref.watch(trainingApiProvider);
  try {
    final data = await api.getById(id);
    return Training.fromJson(data);
  } catch (_) {
    return null;
  }
});
