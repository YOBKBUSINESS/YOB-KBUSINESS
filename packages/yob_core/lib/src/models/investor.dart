import 'package:json_annotation/json_annotation.dart';

part 'investor.g.dart';

@JsonSerializable()
class Investor {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? company;
  final double totalInvested;
  final String? projectId;
  final String? projectName;
  final double? expectedReturn;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Investor({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.company,
    this.totalInvested = 0,
    this.projectId,
    this.projectName,
    this.expectedReturn,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Investor.fromJson(Map<String, dynamic> json) =>
      _$InvestorFromJson(json);
  Map<String, dynamic> toJson() => _$InvestorToJson(this);
}
