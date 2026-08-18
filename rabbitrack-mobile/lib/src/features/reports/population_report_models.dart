class PopulationReport {
  const PopulationReport({
    required this.total,
    required this.bySex,
    required this.byStatus,
    required this.byBreed,
    required this.byLocation,
  });

  factory PopulationReport.fromJson(Map<String, dynamic> json) {
    return PopulationReport(
      total: json['total'] as int? ?? 0,
      bySex: _rows(json['by_sex']),
      byStatus: _rows(json['by_status']),
      byBreed: _rows(json['by_breed']),
      byLocation: _rows(json['by_location']),
    );
  }

  final int total;
  final List<PopulationReportRow> bySex;
  final List<PopulationReportRow> byStatus;
  final List<PopulationReportRow> byBreed;
  final List<PopulationReportRow> byLocation;
}

class PopulationReportRow {
  const PopulationReportRow({required this.label, required this.count});

  factory PopulationReportRow.fromJson(Map<String, dynamic> json) {
    return PopulationReportRow(
      label: json['label'] as String? ?? 'Unknown',
      count: json['count'] as int? ?? 0,
    );
  }

  final String label;
  final int count;
}

List<PopulationReportRow> _rows(Object? value) {
  final items = value as List<dynamic>? ?? [];

  return items
      .map((item) => PopulationReportRow.fromJson(item as Map<String, dynamic>))
      .toList();
}
