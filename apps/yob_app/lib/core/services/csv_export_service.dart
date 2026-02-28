import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

/// Service for generating CSV exports from data.
class CsvExportService {
  CsvExportService._();

  static final _currencyFormat = NumberFormat('#,###', 'fr_FR');

  /// Generate a CSV string from headers and rows.
  static String generateCsv({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return const ListToCsvConverter().convert([headers, ...rows]);
  }

  /// Convert CSV string to bytes (UTF-8 with BOM for Excel compatibility).
  static List<int> csvToBytes(String csv) {
    // UTF-8 BOM so Excel opens it correctly with accented chars
    return [...utf8.encode('\uFEFF'), ...utf8.encode(csv)];
  }

  // ── Producers Export ──

  static String exportProducers(List<Map<String, dynamic>> producers) {
    final headers = [
      'Nom complet',
      'Téléphone',
      'Localité',
      'Statut',
      'Surface (ha)',
      'Type culture',
      'Date inscription',
    ];
    final rows = producers.map((p) {
      return [
        p['full_name']?.toString() ?? '',
        p['phone']?.toString() ?? '',
        p['locality']?.toString() ?? '',
        _statusLabel(p['status']?.toString()),
        '${p['cultivated_area'] ?? 0}',
        p['crop_type']?.toString() ?? '',
        _formatDate(p['created_at']?.toString()),
      ];
    }).toList();
    return generateCsv(headers: headers, rows: rows);
  }

  // ── Transactions Export ──

  static String exportTransactions(List<Map<String, dynamic>> transactions) {
    final headers = [
      'Date',
      'Type',
      'Catégorie',
      'Description',
      'Montant (FCFA)',
      'Créé par',
    ];
    final rows = transactions.map((t) {
      return [
        _formatDate(t['date']?.toString()),
        t['type'] == 'income' ? 'Revenu' : 'Dépense',
        t['category']?.toString() ?? '',
        t['description']?.toString() ?? '',
        _currencyFormat.format((t['amount'] as num?)?.toDouble() ?? 0),
        t['created_by_name']?.toString() ?? '',
      ];
    }).toList();
    return generateCsv(headers: headers, rows: rows);
  }

  // ── Investors Export ──

  static String exportInvestors(List<Map<String, dynamic>> investors) {
    final headers = [
      'Nom',
      'Email',
      'Téléphone',
      'Organisation',
      'Montant Investi (FCFA)',
      'Retour Attendu (%)',
      'Projet associé',
      'Date',
    ];
    final rows = investors.map((inv) {
      return [
        inv['name']?.toString() ?? '',
        inv['email']?.toString() ?? '',
        inv['phone']?.toString() ?? '',
        inv['organization']?.toString() ?? '',
        _currencyFormat.format((inv['amount_invested'] as num?)?.toDouble() ?? 0),
        '${inv['expected_return'] ?? 0}',
        inv['project_name']?.toString() ?? '-',
        _formatDate(inv['created_at']?.toString()),
      ];
    }).toList();
    return generateCsv(headers: headers, rows: rows);
  }

  // ── Parcels Export ──

  static String exportParcels(List<Map<String, dynamic>> parcels) {
    final headers = [
      'Nom',
      'Producteur',
      'Localité',
      'Surface (ha)',
      'Type culture',
      'Statut foncier',
      'Latitude',
      'Longitude',
    ];
    final rows = parcels.map((p) {
      return [
        p['name']?.toString() ?? '',
        p['producer_name']?.toString() ?? '',
        p['locality']?.toString() ?? '',
        '${p['surface_area'] ?? 0}',
        p['crop_type']?.toString() ?? '',
        p['land_tenure_status']?.toString() ?? '',
        '${p['latitude'] ?? ''}',
        '${p['longitude'] ?? ''}',
      ];
    }).toList();
    return generateCsv(headers: headers, rows: rows);
  }

  // ── Helpers ──

  static String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'in_training':
        return 'En formation';
      case 'suspended':
        return 'Suspendu';
      default:
        return status ?? '';
    }
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy', 'fr_FR').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
