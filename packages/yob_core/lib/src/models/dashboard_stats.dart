import 'package:json_annotation/json_annotation.dart';

part 'dashboard_stats.g.dart';

@JsonSerializable()
class DashboardStats {
  final int totalProducers;
  final int activeProducers;
  final double totalHectares;
  final double estimatedProduction;
  final double availableCash;
  final int activeProjects;
  final List<AlertItem> urgentAlerts;

  const DashboardStats({
    this.totalProducers = 0,
    this.activeProducers = 0,
    this.totalHectares = 0,
    this.estimatedProduction = 0,
    this.availableCash = 0,
    this.activeProjects = 0,
    this.urgentAlerts = const [],
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardStatsToJson(this);
}

@JsonSerializable()
class AlertItem {
  final String id;
  final String title;
  final String message;
  final String severity; // 'critical', 'warning', 'info'
  final DateTime createdAt;

  const AlertItem({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) =>
      _$AlertItemFromJson(json);
  Map<String, dynamic> toJson() => _$AlertItemToJson(this);
}
