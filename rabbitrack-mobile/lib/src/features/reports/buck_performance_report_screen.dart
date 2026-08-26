import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'buck_performance_report_controller.dart';
import 'buck_performance_report_models.dart';
import 'buck_performance_report_repository.dart';
import 'performance_report_period.dart';
import 'report_csv_exporter.dart';

class BuckPerformanceReportScreen extends ConsumerStatefulWidget {
  const BuckPerformanceReportScreen({super.key});

  @override
  ConsumerState<BuckPerformanceReportScreen> createState() =>
      _BuckPerformanceReportScreenState();
}

class _BuckPerformanceReportScreenState
    extends ConsumerState<BuckPerformanceReportScreen> {
  PerformanceReportPeriod _period = const PerformanceReportPeriod();

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(buckPerformanceReportForPeriodProvider(_period));

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/more'),
        title: const Text('Buck performance'),
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
          if (item.buckCount == 0) {
            return const AppState(
              icon: Icons.male_outlined,
              title: 'No bucks recorded yet',
              message:
                  'Male rabbits, matings, pregnancies, and litters will build this report automatically.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(
              buckPerformanceReportForPeriodProvider(_period).future,
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
                for (final buck in item.bucks) ...[
                  _BuckTile(buck: buck),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Buck report unavailable',
          message: 'Try again. Offline demo data should remain available.',
          actionLabel: 'Retry',
          onAction: () =>
              ref.invalidate(buckPerformanceReportForPeriodProvider(_period)),
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
          .read(buckPerformanceReportRepositoryProvider)
          .exportCsv(farm.id, start: _period.start, end: _period.end);
      final path = await saveReportCsv(
        fileName: 'buck-performance-report.csv',
        contents: csv,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Buck performance saved to $path')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export buck performance.')),
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

  final BuckPerformanceReport report;

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
            '${report.conceptionRate.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: RabbiTrackColors.cream,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'confirmed pregnancies from matings',
            style: TextStyle(
              color: RabbiTrackColors.mintGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(label: 'Bucks', value: report.buckCount),
              _Metric(label: 'Matings', value: report.totalMatings),
              _Metric(label: 'Litters', value: report.litters),
              _Metric(label: 'Weaned', value: report.kitsWeaned),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Average litter size ${report.averageLitterSize.toStringAsFixed(1)} | weaning rate ${report.weaningRate.toStringAsFixed(1)}%',
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

class _BuckTile extends StatelessWidget {
  const _BuckTile({required this.buck});

  final BuckPerformanceRow buck;

  @override
  Widget build(BuildContext context) {
    final name = buck.name == null || buck.name!.isEmpty
        ? buck.identifier
        : '${buck.identifier} - ${buck.name}';

    return ListTile(
      onTap: () => context.push('/rabbits/${buck.id}'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: RabbiTrackColors.mintGreen),
      ),
      tileColor: Colors.white,
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(
        '${buck.breed ?? 'Breed not set'} | ${buck.status}\n'
        '${buck.matings} matings, ${buck.confirmedPregnancies} pregnant, ${buck.litters} litters\n'
        '${buck.kitsBornAlive} born, ${buck.kitsWeaned} weaned | conception ${buck.conceptionRate.toStringAsFixed(1)}% | weaning ${buck.weaningRate.toStringAsFixed(1)}%',
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
