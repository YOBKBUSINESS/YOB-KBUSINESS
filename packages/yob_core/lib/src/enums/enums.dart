/// User roles for RBAC
enum UserRole {
  direction,
  superviseur,
  comptable,
  partenaire;

  String get label {
    switch (this) {
      case UserRole.direction:
        return 'Direction';
      case UserRole.superviseur:
        return 'Superviseur Terrain';
      case UserRole.comptable:
        return 'Comptable';
      case UserRole.partenaire:
        return 'Partenaire / Investisseur';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.partenaire,
    );
  }
}

/// Producer status
enum ProducerStatus {
  actif,
  enFormation,
  suspendu;

  String get label {
    switch (this) {
      case ProducerStatus.actif:
        return 'Actif';
      case ProducerStatus.enFormation:
        return 'En Formation';
      case ProducerStatus.suspendu:
        return 'Suspendu';
    }
  }

  static ProducerStatus fromString(String value) {
    return ProducerStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProducerStatus.actif,
    );
  }
}

/// Kit reimbursement status
enum KitStatus {
  rembourse,
  subventionne;

  String get label {
    switch (this) {
      case KitStatus.rembourse:
        return 'Remboursé';
      case KitStatus.subventionne:
        return 'Subventionné';
    }
  }
}

/// Land tenure status
enum LandTenureStatus {
  secured,
  pending,
  disputed,
  unknown;

  String get label {
    switch (this) {
      case LandTenureStatus.secured:
        return 'Sécurisé';
      case LandTenureStatus.pending:
        return 'En cours';
      case LandTenureStatus.disputed:
        return 'En litige';
      case LandTenureStatus.unknown:
        return 'Inconnu';
    }
  }
}

/// Finance transaction type
enum TransactionType {
  income,
  expense;

  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Entrée';
      case TransactionType.expense:
        return 'Sortie';
    }
  }
}

/// Income categories
enum IncomeCategory {
  investissement,
  cotisation,
  vente,
  subvention,
  autre;

  String get label {
    switch (this) {
      case IncomeCategory.investissement:
        return 'Investissement';
      case IncomeCategory.cotisation:
        return 'Cotisation';
      case IncomeCategory.vente:
        return 'Vente';
      case IncomeCategory.subvention:
        return 'Subvention';
      case IncomeCategory.autre:
        return 'Autre';
    }
  }
}

/// Expense categories
enum ExpenseCategory {
  forage,
  salaire,
  equipement,
  transport,
  formation,
  autre;

  String get label {
    switch (this) {
      case ExpenseCategory.forage:
        return 'Forage';
      case ExpenseCategory.salaire:
        return 'Salaire';
      case ExpenseCategory.equipement:
        return 'Équipement';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.formation:
        return 'Formation';
      case ExpenseCategory.autre:
        return 'Autre';
    }
  }
}

/// Borehole/project status
enum ProjectStatus {
  planned,
  inProgress,
  completed,
  onHold;

  String get label {
    switch (this) {
      case ProjectStatus.planned:
        return 'Planifié';
      case ProjectStatus.inProgress:
        return 'En cours';
      case ProjectStatus.completed:
        return 'Terminé';
      case ProjectStatus.onHold:
        return 'En attente';
    }
  }
}
