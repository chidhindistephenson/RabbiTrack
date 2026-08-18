import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'doe_performance_report_controller.dart';
import 'doe_performance_report_models.dart';
import 'doe_performance_report_repository.dart';
import 'performance_report_period.dart';
import 'report_csv_exporter.dart';

class DoePerformanceReportScreen extends ConsumerStatefulWidget {
  const DoePerformanceReportScreen({super.key});

  @override
  ConsumerState<DoePerformanceReportScreen> createState() =>
      _DoePerformanceReportScreenState();
}

class _DoePerformanceReportScreenState
    extends ConsumerState<DoePerformanceReportScreen> {
  PerformanceReportPeriod _period = const PerformanceReportPeriod();

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(doePerformanceReportForPeriodProvider(_period));

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/more'),
        title: const Text('Doe performance'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: report.when(
        data: (item) {
          if (item.doeCount == 0) {
            return const AppState(
              icon: Icons.female_outlined,
              title: 'No does recorded yet',
              message:
                  'Female rabbits, matings, kindlings, and weanings will build this report automatically.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(
              doePerformanceReportForPeriodProvider(_period).future,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: [
                _PeriodPicker(
                  period: _period,
                  onChanged: (period) => setState(() => _period = period),
                ),
                const SizedBox(height: 12),
                _SummaryCard(report: item),
                const SizedBox(height: 12),
                for (final doe in item.does) ...[
                  _DoeTile(doe: doe),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Doe report unavailable',
          message: 'Check the API server and try again.',
          actionLabel: 'Retry',
          onAction: () =>
              ref.invalidate(doePerformanceReportForPeriodProvider(_period)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a farm before exporting.')),
      );
      return;
    }

    try {
      final csv = await ref
          .read(doePerformanceReportRepositoryProvider)
          .exportCsv(farm.id, start: _period.start, end: _period.end);
      final path = await saveReportCsv(
        fileName: 'doe-performance-report.csv',
        contents: csv,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Doe performance saved to $path')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export doe performance.')),
      );
    }
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.period, required this.onChanged});

  final PerformanceReportPeriod period;
  final ValueChanged<PerformanceReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PeriodChip(
          label: 'All time',
          selected: period.isAllTime,
          onTap: () => onChanged(const PerformanceReportPeriod()),
        ),
        _PeriodChip(
          label: 'Last 30d',
          selected: period == recentPerformancePeriod(30),
          onTap: () => onChanged(recentPerformancePeriod(30)),
        ),
        _PeriodChip(
          label: 'Last 90d',
          selected: period == recentPerformancePeriod(90),
          onTap: () => onChanged(recentPerformancePeriod(90)),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: RabbiTrackColors.warmTan,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: RabbiTrackColors.forestGreen,
        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final DoePerformanceReport report;

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
            'kits weaned from live births',
            style: TextStyle(
              color: RabbiTrackColors.mintGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(label: 'Does', value: report.doeCount),
              _Metric(label: 'Matings', value: report.totalMatings),
              _Metric(label: 'Kindlings', value: report.kindlings),
              _Metric(label: 'Weaned', value: report.kitsWeaned),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Average litter size ${report.averageLitterSize.toStringAsFixed(1)} | ${report.completedLitters} completed litters',
            style: const TextStyle(color: RabbiTrackColors.cream),
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

class _DoeTile extends StatelessWidget {
  const _DoeTile({required this.doe});

  final DoePerformanceRow doe;

  @override
  Widget build(BuildContext context) {
    final name = doe.name == null || doe.name!.isEmpty
        ? doe.identifier
        : '${doe.identifier} - ${doe.name}';
    final interval = doe.averageLitterIntervalDays == null
        ? 'interval -'
        : 'interval ${doe.averageLitterIntervalDays!.toStringAsFixed(1)} days';

    return ListTile(
      onTap: () => context.push('/rabbits/${doe.id}'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: RabbiTrackColors.mintGreen),
      ),
      tileColor: Colors.white,
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(
        '${doe.breed ?? 'Breed not set'} | ${doe.status}\n'
        '${doe.matings} matings, ${doe.confirmedPregnancies} pregnant, ${doe.kindlings} kindlings\n'
        '${doe.kitsBornAlive} born, ${doe.kitsWeaned} weaned | survival ${doe.survivalRate.toStringAsFixed(1)}% | $interval',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
