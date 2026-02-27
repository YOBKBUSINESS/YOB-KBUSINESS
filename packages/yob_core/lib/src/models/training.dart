import 'package:json_annotation/json_annotation.dart';

part 'training.g.dart';

@JsonSerializable()
class Training {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final String location;
  final List<String> attendeeIds;
  final int attendeeCount;
  final String? evaluationNotes;
  final bool certificationIssued;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Training({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.location,
    this.attendeeIds = const [],
    this.attendeeCount = 0,
    this.evaluationNotes,
    this.certificationIssued = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Training.fromJson(Map<String, dynamic> json) =>
      _$TrainingFromJson(json);
  Map<String, dynamic> toJson() => _$TrainingToJson(this);
}
