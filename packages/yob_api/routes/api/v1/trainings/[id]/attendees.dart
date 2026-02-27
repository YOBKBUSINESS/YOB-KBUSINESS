import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:yob_api/src/repositories/training_repository.dart';

/// POST /api/v1/trainings/:id/attendees — add/remove/mark attendance
Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.post => _onPost(context, id),
    _ => Future.value(
        Response.json(
          statusCode: HttpStatus.methodNotAllowed,
          body: {'success': false, 'message': 'Method not allowed'},
        ),
      ),
  };
}

Future<Response> _onPost(RequestContext context, String id) async {
  try {
    final repo = context.read<TrainingRepository>();
    final body = await context.request.json() as Map<String, dynamic>;
    final action = body['action'] as String?;
    final producerId = body['producer_id'] as String?;

    if (producerId == null || action == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'producer_id et action (add/remove/mark) requis',
        },
      );
    }

    switch (action) {
      case 'add':
        await repo.addAttendee(id, producerId);
        return Response.json(
            body: {'success': true, 'message': 'Participant ajouté'});
      case 'remove':
        await repo.removeAttendee(id, producerId);
        return Response.json(
            body: {'success': true, 'message': 'Participant retiré'});
      case 'mark':
        final attended = body['attended'] as bool? ?? false;
        await repo.markAttendance(id, producerId, attended);
        return Response.json(
            body: {'success': true, 'message': 'Présence mise à jour'});
      default:
        return Response.json(
          statusCode: 400,
          body: {
            'success': false,
            'message': 'Action invalide. Utilisez add, remove ou mark.',
          },
        );
    }
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'message': 'Erreur serveur: $e'},
    );
  }
}
