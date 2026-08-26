import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'health_report_controller.dart';
import 'health_report_models.dart';
import 'health_report_repository.dart';
import 'report_csv_exporter.dart';

class HealthReportScreen extends ConsumerWidget {
  const HealthReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/more'),
        title: const Text('Health report'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context, ref),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: const HealthReportContent(),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      showErrorSnackBar(context, 'Select a farm before exporting.');
      return;
    }

    try {
      final csv = await ref
          .read(healthReportRepositoryProvider)
          .exportCsv(farm.id);
      final path = await saveReportCsv(
        fileName: 'health-report.csv',
        contents: csv,
      );

      if (!context.mounted) {
        return;
      }
      showSuccessSnackBar(context, 'Health report saved to $path');
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      showErrorSnackBar(context, 'Could not export health report.');
    }
  }
}

class HealthReportContent extends ConsumerWidget {
  const HealthReportContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(healthReportProvider);

    return report.when(
      data: (item) => RefreshIndicator(
        onRefresh: () => ref.refresh(healthReportProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            _HealthSummaryGrid(report: item),
            const SizedBox(height: 12),
            _ReportGroup(
              title: 'Severity',
              rows: item.eventsBySeverity,
              emptyLabel: 'No active health events',
            ),
            const SizedBox(height: 12),
            _ReportGroup(
              title: 'Body system',
              rows: item.eventsByBodySystem,
              emptyLabel: 'No body-system trends yet',
            ),
            const SizedBox(height: 12),
            _ReportGroup(
              title: 'Diagnosis',
              rows: item.eventsByDiagnosis,
              emptyLabel: 'No diagnoses recorded',
            ),
            const SizedBox(height: 12),
            _ReportGroup(
              title: 'Medicine use',
              rows: item.medicineUse,
              emptyLabel: 'No active medicines',
            ),
            const SizedBox(height: 12),
            _WithdrawalSection(withdrawals: item.withdrawals),
          ],
        ),
      ),
      error: (error, stackTrace) => AppState(
        icon: Icons.cloud_off_outlined,
        title: 'Health report unavailable',
        message: 'Check the API server and try again.',
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(healthReportProvider),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _HealthSummaryGrid extends StatelessWidget {
  const _HealthSummaryGrid({required this.report});

  final HealthReport report;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _SummaryTile(
          label: 'Active events',
          value: report.activeHealthEvents,
          icon: Icons.health_and_safety_outlined,
        ),
        _SummaryTile(
          label: 'Treatments',
          value: report.activeTreatments,
          icon: Icons.medication_outlined,
        ),
        _SummaryTile(
          label: 'Withdrawals',
          value: report.withdrawalRestrictions,
          icon: Icons.block_outlined,
        ),
        _SummaryTile(
          label: 'Mortality',
          value: report.mortalityCount,
          icon: Icons.report_outlined,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: RabbiTrackColors.warmTan),
          const Spacer(),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: RabbiTrackColors.cream,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: RabbiTrackColors.mintGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportGroup extends StatelessWidget {
  const _ReportGroup({
    required this.title,
    required this.rows,
    required this.emptyLabel,
  });

  final String title;
  final List<HealthReportRow> rows;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<int>(0, (sum, row) => sum + row.count);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RabbiTrackColors.mintGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: RabbiTrackColors.forestGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text(emptyLabel, style: const TextStyle(color: Color(0xFF61706A)))
          else
            for (final row in rows) ...[
              _ReportRow(row: row, total: total),
              if (row != rows.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.row, required this.total});

  final HealthReportRow row;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (row.count / total).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _label(row.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${row.count}',
              style: const TextStyle(
                color: RabbiTrackColors.forestGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: ratio,
            backgroundColor: RabbiTrackColors.cream,
            color: RabbiTrackColors.sageGreen,
          ),
        ),
      ],
    );
  }
}

class _WithdrawalSection extends StatelessWidget {
  const _WithdrawalSection({required this.withdrawals});

  final List<WithdrawalSummary> withdrawals;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RabbiTrackColors.mintGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Withdrawal restrictions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: RabbiTrackColors.forestGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (withdrawals.isEmpty)
            const Text(
              'No active withdrawal restrictions',
              style: TextStyle(color: Color(0xFF61706A)),
            )
          else
            for (final item in withdrawals) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.block_outlined,
                  color: RabbiTrackColors.forestGreen,
                ),
                title: Text(
                  item.rabbitIdentifier ?? 'Rabbit',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${item.medication} until ${item.withdrawalEndsOn}',
                ),
              ),
              if (item != withdrawals.last) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

String _label(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
