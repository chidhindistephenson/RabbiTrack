class PerformanceReportPeriod {
  const PerformanceReportPeriod({this.start, this.end});

  final String? start;
  final String? end;

  bool get isAllTime => start == null && end == null;

  @override
  bool operator ==(Object other) {
    return other is PerformanceReportPeriod &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

String performancePeriodDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}-$month-$day';
}

PerformanceReportPeriod recentPerformancePeriod(int days) {
  final today = DateTime.now();
  final start = today.subtract(Duration(days: days - 1));

  return PerformanceReportPeriod(
    start: performancePeriodDate(start),
    end: performancePeriodDate(today),
  );
}
