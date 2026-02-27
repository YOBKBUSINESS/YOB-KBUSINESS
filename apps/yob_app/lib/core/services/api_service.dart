import 'package:dio/dio.dart';

/// Generic API service for CRUD operations.
class ApiService {
  final Dio _dio;
  final String _basePath;

  ApiService(this._dio, this._basePath);

  /// GET list with pagination & filters.
  Future<Map<String, dynamic>> getAll({
    Map<String, String>? queryParams,
  }) async {
    final response = await _dio.get(
      _basePath,
      queryParameters: queryParams,
    );
    final body = response.data as Map<String, dynamic>;
    if (body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Erreur inconnue');
  }

  /// GET single by ID.
  Future<Map<String, dynamic>> getById(String id) async {
    final response = await _dio.get('$_basePath/$id');
    final body = response.data as Map<String, dynamic>;
    if (body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Erreur inconnue');
  }

  /// POST create.
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _dio.post(_basePath, data: data);
    final body = response.data as Map<String, dynamic>;
    if (body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Erreur de création');
  }

  /// PUT update.
  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> data) async {
    final response = await _dio.put('$_basePath/$id', data: data);
    final body = response.data as Map<String, dynamic>;
    if (body['success'] == true) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] ?? 'Erreur de mise à jour');
  }

  /// DELETE.
  Future<void> delete(String id) async {
    final response = await _dio.delete('$_basePath/$id');
    final body = response.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Erreur de suppression');
    }
  }

  /// POST custom sub-action (e.g. attendees).
  Future<Map<String, dynamic>> postAction(
      String id, String action, Map<String, dynamic> data) async {
    final response = await _dio.post('$_basePath/$id/$action', data: data);
    final body = response.data as Map<String, dynamic>;
    if (body['success'] == true) {
      return body;
    }
    throw Exception(body['message'] ?? 'Erreur');
  }
}
