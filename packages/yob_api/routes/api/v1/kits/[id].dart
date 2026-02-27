import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/kit_repository.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _onGet(context, id),
    HttpMethod.put => _onPut(context, id),
    HttpMethod.delete => _onDelete(context, id),
    _ => Future.value(
        Response.json(
          statusCode: HttpStatus.methodNotAllowed,
          body: {'success': false, 'message': 'Method not allowed'},
        ),
      ),
  };
}

Future<Response> _onGet(RequestContext context, String id) async {
  try {
    final repo = context.read<KitRepository>();
    final kit = await repo.findById(id);
    if (kit == null) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Kit non trouvé'},
      );
    }
    return Response.json(body: {'success': true, 'data': kit});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}

Future<Response> _onPut(RequestContext context, String id) async {
  try {
    final repo = context.read<KitRepository>();
    final body = await context.request.json() as Map<String, dynamic>;
    final updated = await repo.update(id, body);
    if (updated == null) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Kit non trouvé'},
      );
    }
    return Response.json(body: {'success': true, 'data': updated});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}

Future<Response> _onDelete(RequestContext context, String id) async {
  try {
    final repo = context.read<KitRepository>();
    final deleted = await repo.delete(id);
    if (!deleted) {
      return Response.json(
        statusCode: 404,
        body: {'success': false, 'message': 'Kit non trouvé'},
      );
    }
    return Response.json(body: {'success': true, 'message': 'Supprimé'});
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}
