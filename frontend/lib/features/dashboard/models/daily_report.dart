import 'package:barbearia_frontend/features/appointments/models/appointment.dart';

class DailyReport {
  const DailyReport(
      {required this.completedRevenue,
      required this.completedCount,
      required this.pendingRevenue,
      required this.activeCount,
      required this.serviceCounts,
      this.cached = false});
  final double completedRevenue, pendingRevenue;
  final int completedCount, activeCount;
  final Map<String, int> serviceCounts;
  final bool cached;
  factory DailyReport.fromJson(Map<String, dynamic> json,
          {bool cached = false}) =>
      DailyReport(
          completedRevenue: (json['completedRevenue'] as num).toDouble(),
          completedCount: (json['completedCount'] as num).toInt(),
          pendingRevenue: (json['pendingRevenue'] as num).toDouble(),
          activeCount: (json['activeCount'] as num).toInt(),
          serviceCounts: (json['serviceCounts'] as Map).map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt())),
          cached: cached);
  factory DailyReport.fromAppointments(List<Appointment> appointments) {
    var completedRevenue = 0.0, pendingRevenue = 0.0;
    var completedCount = 0, activeCount = 0;
    final counts = <String, int>{};
    for (final appointment in appointments) {
      if (appointment.status == 'cancelado') continue;
      activeCount++;
      if (appointment.status == 'concluido') {
        completedRevenue += appointment.total;
        completedCount++;
      } else {
        pendingRevenue += appointment.total;
      }
      for (final service in appointment.services.toSet()) {
        counts.update(service, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    return DailyReport(
        completedRevenue: completedRevenue,
        completedCount: completedCount,
        pendingRevenue: pendingRevenue,
        activeCount: activeCount,
        serviceCounts: counts,
        cached: true);
  }
  Map<String, dynamic> toJson() => {
        'completedRevenue': completedRevenue,
        'completedCount': completedCount,
        'pendingRevenue': pendingRevenue,
        'activeCount': activeCount,
        'serviceCounts': serviceCounts
      };
}
