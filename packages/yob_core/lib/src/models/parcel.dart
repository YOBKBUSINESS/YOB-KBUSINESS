import 'package:json_annotation/json_annotation.dart';
import '../enums/enums.dart';

part 'parcel.g.dart';

@JsonSerializable()
class Parcel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double surfaceArea; // hectares
  final String cropType;
  final LandTenureStatus tenureStatus;
  final bool commodeSurveyDone;
  final List<String> documentUrls;
  final String? producerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Parcel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.surfaceArea,
    required this.cropType,
    this.tenureStatus = LandTenureStatus.unknown,
    this.commodeSurveyDone = false,
    this.documentUrls = const [],
    this.producerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Parcel.fromJson(Map<String, dynamic> json) => _$ParcelFromJson(json);
  Map<String, dynamic> toJson() => _$ParcelToJson(this);
}
