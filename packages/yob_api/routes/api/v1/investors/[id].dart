import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/investor_repository.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final repo = context.read<InvestorRepository>();

  switch (context.request.method) {
    case HttpMethod.get:
      return _getById(repo, id);
    case HttpMethod.put:
      return _update(context, repo, id);
    case HttpMethod.delete:
      return _delete(repo, id);
    default:
      return Response.json(
        statusCode: 405,
        body: {'error': 'Méthode non autorisée'},
      );
  }
}

/// GET /api/v1/investors/:id
Future<Response> _getById(InvestorRepository repo, String id) async {
  final investor = await repo.findById(id);
  if (investor == null) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Investisseur introuvable'},
    );
  }
  return Response.json(body: investor);
}

/// PUT /api/v1/investors/:id
Future<Response> _update(
    RequestContext context, InvestorRepository repo, String id) async {
  final body =
      json.decode(await context.request.body()) as Map<String, dynamic>;

  final investor = await repo.update(id, body);
  if (investor == null) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Investisseur introuvable'},
    );
  }
  return Response.json(body: investor);
}

/// DELETE /api/v1/investors/:id
Future<Response> _delete(InvestorRepository repo, String id) async {
  final deleted = await repo.delete(id);
  if (!deleted) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'Investisseur introuvable'},
    );
  }
  return Response.json(body: {'message': 'Investisseur supprimé'});
}
