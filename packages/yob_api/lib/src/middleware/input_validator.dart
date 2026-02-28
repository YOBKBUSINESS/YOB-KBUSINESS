import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';

/// Middleware that limits the maximum request body size.
///
/// Rejects payloads larger than [maxBytes] with a 413 status.
/// Default: 1 MB.
Middleware requestSizeLimiter({int maxBytes = 1024 * 1024}) {
  return (handler) {
    return (context) async {
      final contentLength =
          int.tryParse(context.request.headers['content-length'] ?? '');

      if (contentLength != null && contentLength > maxBytes) {
        return Response.json(
          statusCode: 413,
          body: {
            'success': false,
            'message':
                'Corps de requête trop volumineux (max: ${maxBytes ~/ 1024} KB)',
          },
        );
      }

      return handler(context);
    };
  };
}

/// Utility class for input sanitisation and validation.
class InputValidator {
  InputValidator._();

  /// Maximum allowed string length for general text fields.
  static const int maxStringLength = 1000;
  static const int maxNameLength = 200;
  static const int maxEmailLength = 254;

  /// Sanitises a string by trimming whitespace and removing control characters.
  static String sanitize(String input) {
    // Remove control chars except newline and tab
    return input
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .trim();
  }

  /// Deep-sanitises a JSON map (recursive).
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> input) {
    return input.map((key, value) {
      if (value is String) {
        return MapEntry(key, sanitize(value));
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, sanitizeMap(value));
      } else if (value is List) {
        return MapEntry(
          key,
          value.map((e) {
            if (e is String) return sanitize(e);
            if (e is Map<String, dynamic>) return sanitizeMap(e);
            return e;
          }).toList(),
        );
      }
      return MapEntry(key, value);
    });
  }

  /// Validates an email format.
  static bool isValidEmail(String email) {
    if (email.length > maxEmailLength) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// Validates a phone number format (Côte d'Ivoire).
  static bool isValidPhone(String phone) {
    // Accepts +225 XXXXXXXXXX or local formats
    return RegExp(r'^(\+225\s?)?[0-9\s-]{8,14}$').hasMatch(phone);
  }

  /// Validates that a monetary amount is positive and reasonable.
  static bool isValidAmount(num amount) {
    return amount > 0 && amount <= 999999999999;
  }

  /// Validates name field (no special chars except hyphens and accents).
  static bool isValidName(String name) {
    if (name.isEmpty || name.length > maxNameLength) return false;
    // Allow letters, accents, spaces, hyphens, apostrophes
    return RegExp(r"^[\p{L}\s'\-]+$", unicode: true).hasMatch(name);
  }

  /// Validates a UUID format.
  static bool isValidUuid(String id) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id);
  }

  /// Validates pagination parameters.
  static ({int page, int limit}) validatePagination({
    String? pageStr,
    String? limitStr,
  }) {
    final page = (int.tryParse(pageStr ?? '1') ?? 1).clamp(1, 10000);
    final limit = (int.tryParse(limitStr ?? '20') ?? 20).clamp(1, 100);
    return (page: page, limit: limit);
  }
}

/// Middleware that validates JSON request bodies are parseable
/// and rejects malformed payloads.
///
/// For field-level sanitisation, use [InputValidator] methods
/// directly in route handlers.
Middleware inputSanitizationMiddleware() {
  return (handler) {
    return (context) async {
      final method = context.request.method;
      // Only validate POST / PUT / PATCH requests with JSON bodies
      if (method == HttpMethod.post ||
          method == HttpMethod.put ||
          method == HttpMethod.patch) {
        final contentType = context.request.headers['content-type'] ?? '';
        if (contentType.contains('application/json')) {
          try {
            final rawBody = await context.request.body();
            if (rawBody.isNotEmpty) {
              // Validate JSON is parseable — will throw on malformed input
              jsonDecode(rawBody);
            }
          } catch (_) {
            return Response.json(
              statusCode: 400,
              body: {
                'success': false,
                'message': 'Corps JSON invalide',
              },
            );
          }
        }
      }

      return handler(context);
    };
  };
}
