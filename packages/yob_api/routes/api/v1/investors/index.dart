import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/investor_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  final repo = context.read<InvestorRepository>();

  switch (context.request.method) {
    case HttpMethod.get:
      return _getAll(context, repo);
    case HttpMethod.post:
      return _create(context, repo);
    default:
      return Response.json(
        statusCode: 405,
        body: {'error': 'Méthode non autorisée'},
      );
  }
}

/// GET /api/v1/investors?page=1&limit=20&search=...
Future<Response> _getAll(RequestContext context, InvestorRepository repo) async {
  final params = context.request.uri.queryParameters;
  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
  final search = params['search'];

  final result = await repo.findAll(page: page, limit: limit, search: search);
  return Response.json(body: result);
}

/// POST /api/v1/investors
Future<Response> _create(RequestContext context, InvestorRepository repo) async {
  final body =
      json.decode(await context.request.body()) as Map<String, dynamic>;

  if (body['fullName'] == null || (body['fullName'] as String).isEmpty) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Le nom complet est requis'},
    );
  }

  final investor = await repo.create(body);
  return Response.json(statusCode: 201, body: investor);
}
