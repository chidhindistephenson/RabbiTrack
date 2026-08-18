import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'litter_performance_report_controller.dart';
import 'litter_performance_report_models.dart';
import 'litter_performance_report_repository.dart';
import 'report_csv_exporter.dart';

class LitterPerformanceReportScreen extends ConsumerWidget {
  const LitterPerformanceReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(litterPerformanceReportProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/more'),
        title: const Text('Litter performance'),
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
      body: report.when(
        data: (item) {
          if (item.litterCount == 0) {
            return const AppState(
              icon: Icons.child_care_outlined,
              title: 'No litter history yet',
              message:
                  'Kindling and weaning records will build this report automatically.',
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(litterPerformanceReportProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: [
                _SummaryCard(report: item),
                const SizedBox(height: 12),
                for (final litter in item.litters) ...[
                  _LitterTile(litter: litter),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Litter report unavailable',
          message: 'Check the API server and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(litterPerformanceReportProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a farm before exporting.')),
      );
      return;
    }

    try {
      final csv = await ref
          .read(litterPerformanceReportRepositoryProvider)
          .exportCsv(farm.id);
      final path = await saveReportCsv(
        fileName: 'litter-performance-report.csv',
        contents: csv,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Litter performance saved to $path')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export litter performance.')),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final LitterPerformanceReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${report.survivalRate.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: RabbiTrackColors.cream,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'overall live-kit survival',
            style: TextStyle(
              color: RabbiTrackColors.mintGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(label: 'Litters', value: report.litterCount),
              _Metric(label: 'Born', value: report.bornAlive),
              _Metric(label: 'Weaned', value: report.weaned),
              _Metric(label: 'Lost', value: report.mortality),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: RabbiTrackColors.cream,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: RabbiTrackColors.mintGreen,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LitterTile extends StatelessWidget {
  const _LitterTile({required this.litter});

  final LitterPerformanceRow litter;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/litters/${litter.id}'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: RabbiTrackColors.mintGreen),
      ),
      tileColor: Colors.white,
      title: Text(
        litter.identifier,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        '${litter.kindledOn ?? 'Kindled'} | ${litter.bornAlive} alive, ${litter.stillborn} stillborn, ${litter.weaned} weaned\n'
        'Survival ${litter.survivalRate.toStringAsFixed(1)}% | birth avg ${litter.birthAverageWeight ?? '-'} ${litter.weightUnit} | weaning avg ${litter.weaningAverageWeight ?? '-'} ${litter.weightUnit}',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
