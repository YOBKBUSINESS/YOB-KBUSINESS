import 'package:json_annotation/json_annotation.dart';
import '../enums/enums.dart';

part 'transaction.g.dart';

@JsonSerializable()
class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final String? category; // IncomeCategory or ExpenseCategory as string
  final String? referenceId; // linked entity (investor, producer, etc.)
  final DateTime date;
  final String? createdBy;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.category,
    this.referenceId,
    required this.date,
    this.createdBy,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}
