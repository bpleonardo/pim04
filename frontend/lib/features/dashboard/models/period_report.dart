import 'package:barbearia_frontend/features/dashboard/models/daily_report.dart';

class PeriodReport {
  const PeriodReport(
      {required this.startDate,
      required this.endDate,
      required this.summary,
      required this.revenueByDay});
  final DateTime startDate, endDate;
  final DailyReport summary;
  final Map<DateTime, double> revenueByDay;
  factory PeriodReport.fromJson(Map<String, dynamic> json,
          {bool cached = false}) =>
      PeriodReport(
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        summary: DailyReport.fromJson(
            Map<String, dynamic>.from(json['summary'] as Map),
            cached: cached),
        revenueByDay: {
          for (final entry in json['revenueByDay'] as List)
            DateTime.parse(entry['date'] as String):
                (entry['revenue'] as num).toDouble()
        },
      );
  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String().split('T').first,
        'endDate': endDate.toIso8601String().split('T').first,
        'summary': summary.toJson(),
        'revenueByDay': [
          for (final entry in revenueByDay.entries)
            {
              'date': entry.key.toIso8601String().split('T').first,
              'revenue': entry.value
            }
        ],
      };
  factory PeriodReport.fromCachedDays(Map<DateTime, DailyReport> days) {
    final counts = <String, int>{};
    var completed = 0.0, pending = 0.0;
    var completedCount = 0, activeCount = 0;
    for (final report in days.values) {
      completed += report.completedRevenue;
      pending += report.pendingRevenue;
      completedCount += report.completedCount;
      activeCount += report.activeCount;
      for (final entry in report.serviceCounts.entries) {
        counts.update(entry.key, (count) => count + entry.value,
            ifAbsent: () => entry.value);
      }
    }
    return PeriodReport(
        startDate: days.keys.first,
        endDate: days.keys.last,
        summary: DailyReport(
            completedRevenue: completed,
            pendingRevenue: pending,
            completedCount: completedCount,
            activeCount: activeCount,
            serviceCounts: counts,
            cached: true),
        revenueByDay:
            days.map((day, report) => MapEntry(day, report.completedRevenue)));
  }
}
