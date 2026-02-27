import 'package:json_annotation/json_annotation.dart';
import '../enums/enums.dart';

part 'producer.g.dart';

@JsonSerializable()
class Producer {
  final String id;
  final String fullName;
  final String? phone;
  final String locality;
  final String? photoUrl;
  final String? idDocumentUrl;
  final double cultivatedArea; // in hectares
  final ProducerStatus status;
  final List<String> cropHistory;
  final double? productionLevel;
  final double totalContributions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Producer({
    required this.id,
    required this.fullName,
    this.phone,
    required this.locality,
    this.photoUrl,
    this.idDocumentUrl,
    required this.cultivatedArea,
    this.status = ProducerStatus.actif,
    this.cropHistory = const [],
    this.productionLevel,
    this.totalContributions = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Producer.fromJson(Map<String, dynamic> json) =>
      _$ProducerFromJson(json);
  Map<String, dynamic> toJson() => _$ProducerToJson(this);
}
