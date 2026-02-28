import 'package:flutter_test/flutter_test.dart';
import 'package:yob_app/core/services/csv_export_service.dart';

void main() {
  group('CsvExportService', () {
    test('generateCsv produces valid CSV', () {
      final csv = CsvExportService.generateCsv(
        headers: ['Name', 'Age'],
        rows: [
          ['Alice', '30'],
          ['Bob', '25'],
        ],
      );
      expect(csv, contains('Name,Age'));
      expect(csv, contains('Alice,30'));
      expect(csv, contains('Bob,25'));
    });

    test('csvToBytes includes UTF-8 BOM', () {
      final bytes = CsvExportService.csvToBytes('test');
      // UTF-8 BOM is EF BB BF
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);
    });

    test('exportProducers generates CSV with correct headers', () {
      final producers = [
        {
          'full_name': 'Kouassi Yao',
          'phone': '+225 01020304',
          'locality': 'Bouaké',
          'status': 'active',
          'cultivated_area': 12.5,
          'crop_type': 'cacao',
          'created_at': '2025-01-15',
        },
      ];
      final csv = CsvExportService.exportProducers(producers);
      expect(csv, contains('Nom complet'));
      expect(csv, contains('Téléphone'));
      expect(csv, contains('Kouassi Yao'));
      expect(csv, contains('Bouaké'));
    });

    test('exportTransactions generates correct data', () {
      final transactions = [
        {
          'date': '2025-03-15',
          'type': 'income',
          'category': 'cotisation',
          'description': 'Cotisation mensuelle',
          'amount': 50000,
          'created_by_name': 'Admin',
        },
      ];
      final csv = CsvExportService.exportTransactions(transactions);
      expect(csv, contains('Date'));
      expect(csv, contains('Revenu'));
      expect(csv, contains('Cotisation mensuelle'));
    });

    test('exportInvestors generates correct headers', () {
      final investors = [
        {
          'name': 'Jean Dupont',
          'email': 'jean@example.com',
          'phone': '+225 0700000',
          'organization': 'AgriInvest',
          'amount_invested': 5000000,
          'expected_return': 12.5,
          'project_name': 'Forage Nord',
          'created_at': '2025-02-01',
        },
      ];
      final csv = CsvExportService.exportInvestors(investors);
      expect(csv, contains('Nom'));
      expect(csv, contains('Jean Dupont'));
      expect(csv, contains('AgriInvest'));
    });

    test('exportParcels generates correct data', () {
      final parcels = [
        {
          'name': 'Parcelle A1',
          'producer_name': 'Kouassi',
          'locality': 'Bouaké',
          'surface_area': 5.0,
          'crop_type': 'cacao',
          'land_tenure_status': 'secured',
          'latitude': 7.69,
          'longitude': -5.04,
        },
      ];
      final csv = CsvExportService.exportParcels(parcels);
      expect(csv, contains('Parcelle A1'));
      expect(csv, contains('Kouassi'));
    });

    test('handles missing fields gracefully', () {
      final producers = [
        <String, dynamic>{
          'full_name': null,
          'phone': null,
          'locality': null,
        },
      ];
      // Should not throw
      final csv = CsvExportService.exportProducers(producers);
      expect(csv, isNotEmpty);
    });
  });
}
