import 'package:test/test.dart';
import 'package:yob_core/yob_core.dart';

void main() {
  group('Producer model', () {
    final json = {
      'id': 'p1',
      'full_name': 'Kouassi Yao',
      'phone': '+225 0101020304',
      'locality': 'Bouaké',
      'cultivated_area': 12.5,
      'status': 'actif',
      'crop_history': ['cacao', 'café'],
      'production_level': 8.5,
      'total_contributions': 150000.0,
      'created_at': '2025-01-15T10:00:00.000',
      'updated_at': '2025-06-01T12:00:00.000',
    };

    test('fromJson creates a valid Producer', () {
      final p = Producer.fromJson(json);
      expect(p.id, 'p1');
      expect(p.fullName, 'Kouassi Yao');
      expect(p.locality, 'Bouaké');
      expect(p.cultivatedArea, 12.5);
      expect(p.status, ProducerStatus.actif);
      expect(p.cropHistory, hasLength(2));
      expect(p.totalContributions, 150000.0);
    });

    test('toJson round-trips correctly', () {
      final p = Producer.fromJson(json);
      final output = p.toJson();
      expect(output['full_name'], 'Kouassi Yao');
      expect(output['cultivated_area'], 12.5);
    });

    test('handles null optional fields', () {
      final minimal = {
        'id': 'p2',
        'full_name': 'Test',
        'locality': 'Abidjan',
        'cultivated_area': 0.0,
        'crop_history': <String>[],
        'total_contributions': 0.0,
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-01T00:00:00.000',
      };
      final p = Producer.fromJson(minimal);
      expect(p.phone, isNull);
      expect(p.photoUrl, isNull);
      expect(p.productionLevel, isNull);
    });
  });

  group('Transaction model', () {
    final json = {
      'id': 't1',
      'type': 'income',
      'amount': 250000.0,
      'description': 'Cotisation mensuelle',
      'category': 'cotisation',
      'date': '2025-03-15T00:00:00.000',
      'created_at': '2025-03-15T10:30:00.000',
    };

    test('fromJson creates a valid Transaction', () {
      final t = Transaction.fromJson(json);
      expect(t.id, 't1');
      expect(t.type, TransactionType.income);
      expect(t.amount, 250000.0);
      expect(t.description, 'Cotisation mensuelle');
      expect(t.category, 'cotisation');
    });

    test('toJson preserves enum as string', () {
      final t = Transaction.fromJson(json);
      final output = t.toJson();
      expect(output['type'], 'income');
    });
  });

  group('Investor model', () {
    final json = {
      'id': 'inv1',
      'full_name': 'Jean Dupont',
      'email': 'jean@example.com',
      'company': 'AgriInvest CI',
      'total_invested': 5000000.0,
      'expected_return': 12.5,
      'created_at': '2025-02-01T00:00:00.000',
      'updated_at': '2025-02-01T00:00:00.000',
    };

    test('fromJson creates a valid Investor', () {
      final inv = Investor.fromJson(json);
      expect(inv.fullName, 'Jean Dupont');
      expect(inv.totalInvested, 5000000.0);
      expect(inv.expectedReturn, 12.5);
    });

    test('defaults totalInvested to 0', () {
      final minimal = {
        'id': 'inv2',
        'full_name': 'Test',
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-01T00:00:00.000',
      };
      final inv = Investor.fromJson(minimal);
      expect(inv.totalInvested, 0);
    });
  });

  group('DashboardStats model', () {
    final json = {
      'total_producers': 45,
      'active_producers': 38,
      'total_hectares': 1230.5,
      'estimated_production': 856.2,
      'available_cash': 2500000.0,
      'active_projects': 3,
      'urgent_alerts': <dynamic>[],
    };

    test('fromJson creates valid DashboardStats', () {
      final stats = DashboardStats.fromJson(json);
      expect(stats.totalProducers, 45);
      expect(stats.activeProducers, 38);
      expect(stats.totalHectares, 1230.5);
      expect(stats.availableCash, 2500000.0);
    });

    test('toJson round-trips', () {
      final stats = DashboardStats.fromJson(json);
      final output = stats.toJson();
      expect(output['total_producers'], 45);
      expect(output['estimated_production'], 856.2);
    });
  });

  group('AlertItem model', () {
    final json = {
      'id': 'alert1',
      'title': 'Trésorerie basse',
      'message': 'Solde inférieur au seuil critique',
      'severity': 'critical',
      'created_at': '2025-03-01T00:00:00.000',
    };

    test('fromJson creates valid AlertItem', () {
      final alert = AlertItem.fromJson(json);
      expect(alert.title, 'Trésorerie basse');
      expect(alert.severity, 'critical');
    });
  });
}
