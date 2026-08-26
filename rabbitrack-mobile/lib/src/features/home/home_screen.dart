import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/rabbitrack_colors.dart';
import '../../shared/money_format.dart';
import '../../shared/rabbit_icon.dart';
import '../auth/auth_models.dart';
import '../tasks/task_controller.dart';
import '../tasks/task_models.dart';
import '../tasks/task_options.dart';
import 'farm_summary_controller.dart';
import 'farm_summary_models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.farm});

  final FarmSummary? farm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmSummary = ref.watch(farmSummaryProvider);
    final taskSummary = ref.watch(taskSummaryProvider);
    final taskList = ref.watch(taskListProvider);

    return Scaffold(
      backgroundColor: RabbiTrackColors.cream,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            try {
              await Future.wait([
                ref.refresh(farmSummaryProvider.future),
                ref.refresh(taskSummaryProvider.future),
                ref.refresh(taskListProvider.future),
              ], eagerError: false);
            } catch (_) {
              // Individual cards render their own error states.
            }
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 112),
            children: [
              _DashboardHeader(
                farmName: farm?.name ?? 'RabbiTrack',
                taskSummary: taskSummary,
              ),
              const SizedBox(height: 14),
              farmSummary.when(
                data: (summary) => _FarmPulseCard(summary: summary),
                error: (error, stackTrace) => const _HeroFallbackCard(),
                loading: () => const _HeroLoadingCard(),
              ),
              const SizedBox(height: 14),
              farmSummary.when(
                data: (summary) => _HerdStatusCard(summary: summary),
                error: (error, stackTrace) => const SizedBox.shrink(),
                loading: () => const _SmallLoadingCard(height: 150),
              ),
              const SizedBox(height: 14),
              farmSummary.when(
                data: (summary) => _FinanceCard(summary: summary),
                error: (error, stackTrace) => const _InfoCard(
                  icon: Icons.cloud_off_outlined,
                  title: 'Finance unavailable',
                  message:
                      'Try again. Offline demo data should remain available.',
                ),
                loading: () => const _SmallLoadingCard(height: 170),
              ),
              const SizedBox(height: 14),
              taskList.when(
                data: (tasks) => _PriorityTasksCard(tasks: tasks),
                error: (error, stackTrace) => const _InfoCard(
                  icon: Icons.cloud_off_outlined,
                  title: 'Priorities unavailable',
                  message: 'Open tasks could not be loaded right now.',
                ),
                loading: () => const _SmallLoadingCard(height: 180),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.farmName, required this.taskSummary});

  final String farmName;
  final AsyncValue<TaskSummaryCounts> taskSummary;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: RabbiTrackColors.warmTan,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.eco,
            color: RabbiTrackColors.forestGreen,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                farmName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: RabbiTrackColors.forestGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_greeting(now)}, farm command center',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF61706A)),
              ),
            ],
          ),
        ),
        _DateChip(date: now),
        const SizedBox(width: 8),
        _NotificationIconButton(taskSummary: taskSummary),
      ],
    );
  }

  String _greeting(DateTime date) {
    if (date.hour < 12) {
      return 'Good morning';
    }
    if (date.hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }
}

class _NotificationIconButton extends StatelessWidget {
  const _NotificationIconButton({required this.taskSummary});

  final AsyncValue<TaskSummaryCounts> taskSummary;

  @override
  Widget build(BuildContext context) {
    final openTasks = taskSummary.valueOrNull?.open ?? 0;
    final hasError = taskSummary.hasError;
    final showBadge = hasError || openTasks > 0;
    final label = openTasks > 99 ? '99+' : '$openTasks';

    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IconButton.filledTonal(
              tooltip: 'Notifications',
              onPressed: () => context.push('/tasks'),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ),
          if (showBadge)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: hasError
                      ? const Color(0xFFB86955)
                      : RabbiTrackColors.warmTan,
                  shape: !hasError && openTasks < 10
                      ? BoxShape.circle
                      : BoxShape.rectangle,
                  borderRadius: !hasError && openTasks < 10
                      ? null
                      : BorderRadius.circular(999),
                  border: Border.all(color: RabbiTrackColors.cream, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  hasError ? '!' : label,
                  style: const TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E2D9)),
      ),
      child: Column(
        children: [
          Text(
            _weekday(date),
            style: const TextStyle(
              color: Color(0xFF61706A),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${date.day}',
            style: const TextStyle(
              color: RabbiTrackColors.forestGreen,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _weekday(DateTime date) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return days[date.weekday - 1];
  }
}

class _FarmPulseCard extends StatelessWidget {
  const _FarmPulseCard({required this.summary});

  final FarmSummaryCounts summary;

  @override
  Widget build(BuildContext context) {
    final risk = summary.healthAlerts + summary.quarantined;
    final careLoad = summary.openTasks + risk;
    final readyShare = summary.activeRabbits <= 0
        ? 0.0
        : summary.readyForSale / summary.activeRabbits;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RabbiTrackColors.forestGreen,
            Color(0xFF285246),
            Color(0xFF355F4D),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: RabbiTrackColors.forestGreen.withValues(alpha: 0.2),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -18,
            child: RabbitIcon(
              color: Colors.white.withValues(alpha: 0.07),
              size: 210,
              filled: true,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroBadge(
                          icon: _insightIcon(summary),
                          label: _statusLabel(summary),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Today on the farm',
                          style: TextStyle(
                            color: RabbiTrackColors.mintGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${summary.activeRabbits}',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: RabbiTrackColors.cream,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const Text(
                          'active rabbits',
                          style: TextStyle(
                            color: RabbiTrackColors.mintGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 126,
                    height: 126,
                    child: CustomPaint(
                      painter: _FarmPulsePainter(
                        readyProgress: _safeProgress(readyShare, 0.04, 1.0),
                        careProgress: _safeProgress(careLoad / 12, 0.08, 1.0),
                        alertProgress: _safeProgress(risk / 8, 0.06, 1.0),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${summary.readyForSale}',
                              style: const TextStyle(
                                color: RabbiTrackColors.cream,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'ready',
                              style: TextStyle(
                                color: RabbiTrackColors.mintGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _FarmInsightLine(
                icon: _insightIcon(summary),
                message: _insightMessage(summary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      label: 'Open tasks',
                      value: '${summary.openTasks}',
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Alerts',
                      value: '$risk',
                      icon: Icons.health_and_safety_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Breeding',
                      value: '${summary.pregnantDoes + summary.nursingDoes}',
                      icon: Icons.favorite_border,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(FarmSummaryCounts summary) {
    if (summary.healthAlerts > 0 || summary.quarantined > 0) {
      return 'Needs care';
    }
    if (summary.openTasks > 0) {
      return 'Work queued';
    }
    if (summary.readyForSale > 0) {
      return 'Sales ready';
    }

    return 'All calm';
  }

  IconData _insightIcon(FarmSummaryCounts summary) {
    if (summary.healthAlerts > 0 || summary.quarantined > 0) {
      return Icons.health_and_safety_outlined;
    }
    if (summary.openTasks > 0) {
      return Icons.assignment_outlined;
    }
    if (summary.readyForSale > 0) {
      return Icons.sell_outlined;
    }

    return Icons.check_circle_outline;
  }

  String _insightMessage(FarmSummaryCounts summary) {
    if (summary.healthAlerts > 0 || summary.quarantined > 0) {
      return '${summary.healthAlerts} health alert${summary.healthAlerts == 1 ? '' : 's'} and ${summary.quarantined} quarantined need attention.';
    }
    if (summary.overdueTasks > 0) {
      return '${summary.overdueTasks} overdue task${summary.overdueTasks == 1 ? '' : 's'} need follow-up today.';
    }
    if (summary.openTasks > 0) {
      return '${summary.openTasks} open task${summary.openTasks == 1 ? '' : 's'} keeping today active.';
    }
    if (summary.expectedKindlings > 0) {
      return '${summary.expectedKindlings} expected kindling${summary.expectedKindlings == 1 ? '' : 's'} on the calendar.';
    }
    if (summary.readyForSale > 0) {
      return '${summary.readyForSale} rabbit${summary.readyForSale == 1 ? '' : 's'} ready for sale.';
    }

    return 'No urgent pressure showing on the farm right now.';
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: RabbiTrackColors.warmTan, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: RabbiTrackColors.cream,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmInsightLine extends StatelessWidget {
  const _FarmInsightLine({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: RabbiTrackColors.warmTan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: RabbiTrackColors.cream,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HerdStatusCard extends StatelessWidget {
  const _HerdStatusCard({required this.summary});

  final FarmSummaryCounts summary;

  @override
  Widget build(BuildContext context) {
    final attention = summary.healthAlerts + summary.quarantined;
    final routine = (summary.activeRabbits - summary.readyForSale - attention)
        .clamp(0, summary.activeRabbits);
    final total = summary.activeRabbits == 0 ? 1 : summary.activeRabbits;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Herd status',
            subtitle: 'A quick read on where the herd stands',
          ),
          const SizedBox(height: 14),
          _SegmentedStatusBar(
            segments: [
              _StatusSegment(
                value: routine,
                share: routine / total,
                color: RabbiTrackColors.sageGreen,
              ),
              _StatusSegment(
                value: summary.readyForSale,
                share: summary.readyForSale / total,
                color: RabbiTrackColors.warmTan,
              ),
              _StatusSegment(
                value: attention,
                share: attention / total,
                color: const Color(0xFFB86955),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatusLegend(
                  label: 'Routine',
                  value: routine,
                  color: RabbiTrackColors.sageGreen,
                ),
              ),
              Expanded(
                child: _StatusLegend(
                  label: 'Ready',
                  value: summary.readyForSale,
                  color: RabbiTrackColors.warmTan,
                ),
              ),
              Expanded(
                child: _StatusLegend(
                  label: 'Attention',
                  value: attention,
                  color: const Color(0xFFB86955),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _HerdMiniStat(
                icon: Icons.female,
                label: 'Does',
                value: summary.does,
              ),
              _HerdMiniStat(
                icon: Icons.male,
                label: 'Bucks',
                value: summary.bucks,
              ),
              _HerdMiniStat(
                icon: Icons.child_care_outlined,
                label: 'Live kits',
                value: summary.liveKits,
              ),
              _HerdMiniStat(
                icon: Icons.event_available_outlined,
                label: 'Expected kindlings',
                value: summary.expectedKindlings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HerdMiniStat extends StatelessWidget {
  const _HerdMiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: RabbiTrackColors.cream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RabbiTrackColors.mintGreen),
      ),
      child: Row(
        children: [
          Icon(icon, color: RabbiTrackColors.sageGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF61706A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedStatusBar extends StatelessWidget {
  const _SegmentedStatusBar({required this.segments});

  final List<_StatusSegment> segments;

  @override
  Widget build(BuildContext context) {
    final hasVisibleData = segments.any((segment) => segment.value > 0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            if (!hasVisibleData)
              const Expanded(
                child: ColoredBox(color: RabbiTrackColors.mintGreen),
              )
            else
              for (final segment in segments)
                if (segment.value > 0)
                  Expanded(
                    flex: (segment.share * 1000).round().clamp(1, 1000),
                    child: ColoredBox(color: segment.color),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: RabbiTrackColors.forestGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF61706A), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusSegment {
  const _StatusSegment({
    required this.value,
    required this.share,
    required this.color,
  });

  final int value;
  final double share;
  final Color color;
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({required this.summary});

  final FarmSummaryCounts summary;

  @override
  Widget build(BuildContext context) {
    final revenue = _safeAmount(summary.salesRevenue);
    final expenses = _safeAmount(summary.totalExpenses);
    final net = _safeAmount(summary.netIncome, fallback: revenue - expenses);
    final total = revenue + expenses;
    final revenueShare = total <= 0 ? 0.5 : revenue / total;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  title: 'Farm money',
                  subtitle: 'Revenue, costs, and net position',
                ),
              ),
              IconButton(
                tooltip: 'Finance report',
                onPressed: () => context.push('/reports/finance'),
                icon: const Icon(Icons.bar_chart),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CustomPaint(
                  painter: _FinanceRingPainter(
                    revenueShare: _safeProgress(revenueShare, 0.0, 1.0),
                  ),
                  child: Center(
                    child: Text(
                      net >= 0 ? '+' : '-',
                      style: const TextStyle(
                        color: RabbiTrackColors.forestGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatMoney(summary.currency, net.toStringAsFixed(2)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: RabbiTrackColors.forestGreen,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _MoneyLine(
                      label: 'Revenue',
                      value: formatMoney(
                        summary.currency,
                        summary.salesRevenue,
                      ),
                      color: RabbiTrackColors.sageGreen,
                    ),
                    const SizedBox(height: 6),
                    _MoneyLine(
                      label: 'Expenses',
                      value: formatMoney(
                        summary.currency,
                        summary.totalExpenses,
                      ),
                      color: RabbiTrackColors.warmTan,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityTasksCard extends StatelessWidget {
  const _PriorityTasksCard({required this.tasks});

  final List<TaskSummary> tasks;

  @override
  Widget build(BuildContext context) {
    final topTasks = tasks.take(3).toList();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  title: 'Next priorities',
                  subtitle: 'The first jobs to handle',
                ),
              ),
              TextButton(
                onPressed: () => context.push('/tasks'),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (topTasks.isEmpty)
            const _CompactEmptyLine(
              icon: Icons.check_circle_outline,
              text: 'No open task pressure right now.',
            )
          else
            for (final task in topTasks) _TaskPreview(task: task),
        ],
      ),
    );
  }
}

class _TaskPreview extends StatelessWidget {
  const _TaskPreview({required this.task});

  final TaskSummary task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: RabbiTrackColors.cream,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/tasks'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _priorityColor(task.priority).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _taskIcon(task.type),
                    color: RabbiTrackColors.forestGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RabbiTrackColors.forestGreen,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          _dueLabel(task.dueOn),
                          task.rabbitIdentifier,
                          task.locationName,
                        ].whereType<String>().join(' | '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF61706A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _TinyBadge(label: taskPriorityLabel(task.priority)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _taskIcon(String type) {
    return switch (type) {
      'breeding' => Icons.favorite,
      'health' => Icons.medical_services_outlined,
      'cleaning' => Icons.cleaning_services_outlined,
      'feeding' => Icons.restaurant_outlined,
      _ => Icons.task_alt,
    };
  }

  Color _priorityColor(String priority) {
    return switch (priority) {
      'urgent' => const Color(0xFFB86955),
      'critical' => const Color(0xFFB86955),
      'high' => RabbiTrackColors.warmTan,
      _ => RabbiTrackColors.sageGreen,
    };
  }

  String _dueLabel(String dueOn) {
    final due = DateTime.tryParse(dueOn);
    if (due == null) {
      return dueOn;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    final difference = day.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    }
    if (difference == 1) {
      return 'Tomorrow';
    }
    if (difference < 0) {
      return '${difference.abs()}d overdue';
    }

    return dueOn;
  }
}

class _CompactEmptyLine extends StatelessWidget {
  const _CompactEmptyLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RabbiTrackColors.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: RabbiTrackColors.sageGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: RabbiTrackColors.forestGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: RabbiTrackColors.cream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RabbiTrackColors.mintGreen),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: RabbiTrackColors.forestGreen,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E2D9)),
        boxShadow: [
          BoxShadow(
            color: RabbiTrackColors.forestGreen.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: RabbiTrackColors.warmTan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: RabbiTrackColors.cream,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RabbiTrackColors.mintGreen,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: RabbiTrackColors.forestGreen,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Color(0xFF61706A))),
      ],
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(
            color: RabbiTrackColors.forestGreen,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Icon(icon, color: RabbiTrackColors.forestGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: Color(0xFF61706A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFallbackCard extends StatelessWidget {
  const _HeroFallbackCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.cloud_off_outlined,
      title: 'Dashboard unavailable',
      message: 'Try again. Offline demo data should remain available.',
    );
  }
}

class _HeroLoadingCard extends StatelessWidget {
  const _HeroLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _SmallLoadingCard(height: 240);
  }
}

double _safeProgress(double value, double min, double max) {
  if (!value.isFinite) {
    return min;
  }

  return value.clamp(min, max);
}

double _safeAmount(String value, {double fallback = 0}) {
  final parsed = double.tryParse(value);
  if (parsed == null || !parsed.isFinite) {
    return fallback;
  }

  return parsed;
}

class _SmallLoadingCard extends StatelessWidget {
  const _SmallLoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: SizedBox(
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _FarmPulsePainter extends CustomPainter {
  const _FarmPulsePainter({
    required this.readyProgress,
    required this.careProgress,
    required this.alertProgress,
  });

  final double readyProgress;
  final double careProgress;
  final double alertProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 16) {
      return;
    }

    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    _arc(
      canvas,
      center,
      radius,
      -1.55,
      readyProgress,
      RabbiTrackColors.warmTan,
    );
    _arc(
      canvas,
      center,
      radius - 18,
      0.35,
      careProgress,
      RabbiTrackColors.sageGreen,
    );
    _arc(
      canvas,
      center,
      radius - 36,
      2.2,
      alertProgress,
      const Color(0xFFBFD8C6),
    );
  }

  void _arc(
    Canvas canvas,
    Offset center,
    double radius,
    double start,
    double progress,
    Color color,
  ) {
    if (radius <= 0 || !progress.isFinite || progress <= 0) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, start, progress * 4.9, false, paint);
  }

  @override
  bool shouldRepaint(covariant _FarmPulsePainter oldDelegate) {
    return readyProgress != oldDelegate.readyProgress ||
        careProgress != oldDelegate.careProgress ||
        alertProgress != oldDelegate.alertProgress;
  }
}

class _FinanceRingPainter extends CustomPainter {
  const _FinanceRingPainter({required this.revenueShare});

  final double revenueShare;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 16) {
      return;
    }

    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final share = _safeProgress(revenueShare, 0.0, 1.0);
    final track = Paint()
      ..color = RabbiTrackColors.mintGreen.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final revenue = Paint()
      ..color = RabbiTrackColors.sageGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final expense = Paint()
      ..color = RabbiTrackColors.warmTan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius, track);
    if (share > 0) {
      canvas.drawArc(rect, -1.57, share * 6.28, false, revenue);
    }
    if (share < 1) {
      canvas.drawArc(
        rect,
        -1.57 + share * 6.28 + 0.08,
        ((1 - share) * 6.28 - 0.08).clamp(0.0, 6.28),
        false,
        expense,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FinanceRingPainter oldDelegate) {
    return revenueShare != oldDelegate.revenueShare;
  }
}
