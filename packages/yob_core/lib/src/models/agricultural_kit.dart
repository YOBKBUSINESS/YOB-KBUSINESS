import 'package:json_annotation/json_annotation.dart';
import '../enums/enums.dart';

part 'agricultural_kit.g.dart';

@JsonSerializable()
class AgriculturalKit {
  final String id;
  final String kitType;
  final DateTime distributionDate;
  final String beneficiaryId; // producer ID
  final String? beneficiaryName;
  final double value;
  final KitStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgriculturalKit({
    required this.id,
    required this.kitType,
    required this.distributionDate,
    required this.beneficiaryId,
    this.beneficiaryName,
    required this.value,
    this.status = KitStatus.subventionne,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AgriculturalKit.fromJson(Map<String, dynamic> json) =>
      _$AgriculturalKitFromJson(json);
  Map<String, dynamic> toJson() => _$AgriculturalKitToJson(this);
}
