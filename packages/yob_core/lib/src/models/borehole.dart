import 'package:json_annotation/json_annotation.dart';
import '../enums/enums.dart';

part 'borehole.g.dart';

@JsonSerializable()
class Borehole {
  final String id;
  final String name;
  final String location;
  final double cost;
  final String contractor;
  final DateTime startDate;
  final DateTime? endDate;
  final int progressPercent; // 0-100
  final ProjectStatus status;
  final List<String> photoUrls;
  final String? maintenanceNotes;
  final DateTime? lastMaintenanceDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Borehole({
    required this.id,
    required this.name,
    required this.location,
    required this.cost,
    required this.contractor,
    required this.startDate,
    this.endDate,
    this.progressPercent = 0,
    this.status = ProjectStatus.planned,
    this.photoUrls = const [],
    this.maintenanceNotes,
    this.lastMaintenanceDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Borehole.fromJson(Map<String, dynamic> json) =>
      _$BoreholeFromJson(json);
  Map<String, dynamic> toJson() => _$BoreholeToJson(this);
}
