import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yob_core/yob_core.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/providers.dart';

final parcelApiProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider), '/parcels');
});

class ParcelListState {
  final List<Parcel> parcels;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final String? cropFilter;
  final String? producerFilter;

  const ParcelListState({
    this.parcels = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.cropFilter,
    this.producerFilter,
  });

  ParcelListState copyWith({
    List<Parcel>? parcels,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? cropFilter,
    String? producerFilter,
  }) {
    return ParcelListState(
      parcels: parcels ?? this.parcels,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      cropFilter: cropFilter ?? this.cropFilter,
      producerFilter: producerFilter ?? this.producerFilter,
    );
  }
}

class ParcelListNotifier extends StateNotifier<ParcelListState> {
  final ApiService _api;

  ParcelListNotifier(this._api) : super(const ParcelListState()) {
    loadParcels();
  }

  Future<void> loadParcels({int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': '20',
      };
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        params['search'] = state.searchQuery!;
      }
      if (state.cropFilter != null && state.cropFilter!.isNotEmpty) {
        params['crop_type'] = state.cropFilter!;
      }
      if (state.producerFilter != null && state.producerFilter!.isNotEmpty) {
        params['producer_id'] = state.producerFilter!;
      }

      final data = await _api.getAll(queryParams: params);
      final items = (data['items'] as List<dynamic>)
          .map((e) => Parcel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        parcels: items,
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
    loadParcels();
  }

  void filterByCrop(String? crop) {
    state = state.copyWith(cropFilter: crop);
    loadParcels();
  }

  Future<void> deleteParcel(String id) async {
    try {
      await _api.delete(id);
      loadParcels(page: state.page);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void nextPage() {
    if (state.page < state.totalPages) loadParcels(page: state.page + 1);
  }

  void previousPage() {
    if (state.page > 1) loadParcels(page: state.page - 1);
  }
}

final parcelListProvider =
    StateNotifierProvider<ParcelListNotifier, ParcelListState>((ref) {
  return ParcelListNotifier(ref.watch(parcelApiProvider));
});

final parcelDetailProvider =
    FutureProvider.family<Parcel?, String>((ref, id) async {
  final api = ref.watch(parcelApiProvider);
  try {
    final data = await api.getById(id);
    return Parcel.fromJson(data);
  } catch (_) {
    return null;
  }
});
