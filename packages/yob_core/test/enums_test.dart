import 'package:test/test.dart';
import 'package:yob_core/yob_core.dart';

void main() {
  group('UserRole', () {
    test('labels are correct', () {
      expect(UserRole.direction.label, 'Direction');
      expect(UserRole.superviseur.label, 'Superviseur Terrain');
      expect(UserRole.comptable.label, 'Comptable');
      expect(UserRole.partenaire.label, 'Partenaire / Investisseur');
    });

    test('fromString maps correctly', () {
      expect(UserRole.fromString('direction'), UserRole.direction);
      expect(UserRole.fromString('comptable'), UserRole.comptable);
    });

    test('fromString defaults to partenaire on unknown', () {
      expect(UserRole.fromString('invalid'), UserRole.partenaire);
    });
  });

  group('ProducerStatus', () {
    test('labels are correct', () {
      expect(ProducerStatus.actif.label, 'Actif');
      expect(ProducerStatus.enFormation.label, 'En Formation');
      expect(ProducerStatus.suspendu.label, 'Suspendu');
    });

    test('fromString maps correctly', () {
      expect(ProducerStatus.fromString('actif'), ProducerStatus.actif);
      expect(ProducerStatus.fromString('suspendu'), ProducerStatus.suspendu);
    });

    test('fromString defaults to actif on unknown', () {
      expect(ProducerStatus.fromString('unknown'), ProducerStatus.actif);
    });
  });

  group('TransactionType', () {
    test('labels are correct', () {
      expect(TransactionType.income.label, 'Entrée');
      expect(TransactionType.expense.label, 'Sortie');
    });
  });

  group('KitStatus', () {
    test('labels are correct', () {
      expect(KitStatus.rembourse.label, 'Remboursé');
      expect(KitStatus.subventionne.label, 'Subventionné');
    });
  });

  group('LandTenureStatus', () {
    test('labels are correct', () {
      expect(LandTenureStatus.secured.label, 'Sécurisé');
      expect(LandTenureStatus.pending.label, 'En cours');
      expect(LandTenureStatus.disputed.label, 'En litige');
      expect(LandTenureStatus.unknown.label, 'Inconnu');
    });
  });

  group('IncomeCategory', () {
    test('has all expected values', () {
      expect(IncomeCategory.values, hasLength(5));
      expect(IncomeCategory.investissement.label, 'Investissement');
      expect(IncomeCategory.cotisation.label, 'Cotisation');
      expect(IncomeCategory.vente.label, 'Vente');
      expect(IncomeCategory.subvention.label, 'Subvention');
      expect(IncomeCategory.autre.label, 'Autre');
    });
  });

  group('AppConstants', () {
    test('currency is FCFA', () {
      expect(AppConstants.currency, 'FCFA');
    });

    test('default page size is 20', () {
      expect(AppConstants.defaultPageSize, 20);
    });

    test('low funds threshold is 500000', () {
      expect(AppConstants.lowFundsThreshold, 500000);
    });

    test('critical funds threshold is 100000', () {
      expect(AppConstants.criticalFundsThreshold, 100000);
    });

    test('max file size is 10 MB', () {
      expect(AppConstants.maxFileSize, 10 * 1024 * 1024);
    });
  });
}
