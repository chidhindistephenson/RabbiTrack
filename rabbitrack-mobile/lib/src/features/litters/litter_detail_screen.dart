import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../theme/rabbitrack_colors.dart';
import 'litter_controller.dart';
import 'litter_models.dart';
import 'litter_options.dart';

class LitterDetailScreen extends ConsumerWidget {
  const LitterDetailScreen({required this.litterId, super.key});

  final String litterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final litter = ref.watch(litterDetailProvider(litterId));

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/litters'),
        title: const Text('Litter profile'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: litter.when(
        data: (item) => RefreshIndicator(
          onRefresh: () => ref.refresh(litterDetailProvider(litterId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _HeroCard(litter: item),
              const SizedBox(height: 14),
              if (!['closed', 'archived'].contains(item.status)) ...[
                _CheckStrip(litterId: litterId),
                const SizedBox(height: 14),
              ],
              if (item.currentLiveCount > 0 &&
                  [
                    'newborn',
                    'nursing',
                    'partially_weaned',
                  ].contains(item.status)) ...[
                _FosterStrip(litterId: litterId),
                const SizedBox(height: 14),
              ],
              if (item.status != 'weaned') ...[
                _ActionStrip(litterId: litterId),
                const SizedBox(height: 14),
              ],
              if (item.status == 'weaned' && item.unconvertedKitsCount > 0) ...[
                _IdentifyStrip(litterId: litterId),
                const SizedBox(height: 14),
              ],
              _KindlingSection(litter: item),
              const SizedBox(height: 14),
              _ChecksSection(checks: item.checks),
              const SizedBox(height: 14),
              _FostersSection(
                fostersOut: item.fostersOut,
                fostersIn: item.fostersIn,
              ),
              const SizedBox(height: 14),
              _WeaningsSection(weanings: item.weanings),
              const SizedBox(height: 14),
              _WeightsSection(weights: item.weights),
            ],
          ),
        ),
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load litter profile',
          message: 'Check that the API server is running, then try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(litterDetailProvider(litterId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.litter});

  final LitterDetail litter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = litterStatusLabel(litter.status);
    final parentLine =
        '${litter.doeIdentifier}${litter.buckIdentifier == null ? '' : ' x ${litter.buckIdentifier}'} | $status';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: RabbiTrackColors.warmTan,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.child_care,
                  color: RabbiTrackColors.forestGreen,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      litter.identifier,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: RabbiTrackColors.cream,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      parentLine,
                      style: textTheme.bodyMedium?.copyWith(
                        color: RabbiTrackColors.mintGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(label: status),
            ],
          ),
          const SizedBox(height: 18),
          _StatsGrid(
            stats: [
              _StatData(
                icon: Icons.favorite,
                label: 'Current live',
                value: '${litter.currentLiveCount}',
              ),
              _StatData(
                icon: Icons.cake_outlined,
                label: 'Born alive',
                value: '${litter.kitsBornAlive}',
              ),
              _StatData(
                icon: Icons.event_available,
                label: 'Weaning',
                value: litter.plannedWeaningOn,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: RabbiTrackColors.mintGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: RabbiTrackColors.forestGreen,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CheckStrip extends StatelessWidget {
  const _CheckStrip({required this.litterId});

  final String litterId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.push('/litters/$litterId/checks/new'),
      icon: const Icon(Icons.fact_check_outlined),
      label: const Text('Record check'),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.litterId});

  final String litterId;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => context.push('/litters/$litterId/weaning'),
      icon: const Icon(Icons.check_circle_outline),
      label: const Text('Record weaning'),
    );
  }
}

class _FosterStrip extends StatelessWidget {
  const _FosterStrip({required this.litterId});

  final String litterId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.push('/litters/$litterId/fosters/new'),
      icon: const Icon(Icons.swap_horiz),
      label: const Text('Record foster'),
    );
  }
}

class _IdentifyStrip extends StatelessWidget {
  const _IdentifyStrip({required this.litterId});

  final String litterId;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => context.push('/litters/$litterId/convert'),
      icon: const Icon(Icons.sell_outlined),
      label: const Text('Identify kits'),
    );
  }
}

class _KindlingSection extends StatelessWidget {
  const _KindlingSection({required this.litter});

  final LitterDetail litter;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Kindling snapshot',
      subtitle: 'Birth outcome and next milestone',
      child: Column(
        children: [
          _TimelineRow(
            icon: Icons.calendar_today,
            title: 'Kindled',
            value: litter.kindledOn,
          ),
          _TimelineRow(
            icon: Icons.health_and_safety_outlined,
            title: 'Birth outcome',
            value:
                '${litter.kitsBornAlive} alive, ${litter.kitsStillborn} stillborn, ${litter.kitsWeak} weak',
          ),
          _TimelineRow(
            icon: Icons.event_available,
            title: 'Planned weaning',
            value: litter.plannedWeaningOn,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ChecksSection extends StatelessWidget {
  const _ChecksSection({required this.checks});

  final List<LitterCheckSummary> checks;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Litter checks',
      subtitle: checks.isEmpty
          ? 'No checks recorded yet'
          : 'Recent count and nest observations',
      child: checks.isEmpty
          ? const _EmptyInline(
              icon: Icons.fact_check_outlined,
              text: 'No litter checks recorded',
            )
          : Column(
              children: [
                for (final check in checks.take(5)) ...[
                  _RecordCard(
                    icon: Icons.fact_check,
                    title:
                        '${check.liveCount} live, ${check.deadCount} dead, ${check.weakCount} weak',
                    subtitle: [
                      if (check.suspectedCause != null)
                        'Cause: ${check.suspectedCause}',
                      if (check.nestObservation != null)
                        'Nest: ${check.nestObservation}',
                      if (check.correctiveAction != null)
                        'Action: ${check.correctiveAction}',
                    ].join(' | '),
                    meta: check.checkedOn ?? 'Check',
                  ),
                  if (check != checks.take(5).last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _WeaningsSection extends StatelessWidget {
  const _WeaningsSection({required this.weanings});

  final List<LitterWeaningSummary> weanings;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Weaning',
      subtitle: weanings.isEmpty
          ? 'No weaning record yet'
          : 'Recorded transition into grow-out',
      child: weanings.isEmpty
          ? const _EmptyInline(
              icon: Icons.hourglass_empty,
              text: 'Not weaned yet',
            )
          : Column(
              children: [
                for (final weaning in weanings) ...[
                  _RecordCard(
                    icon: Icons.check_circle,
                    title: '${weaning.numberWeaned} kits weaned',
                    subtitle:
                        '${weaning.numberWeaned} weaned | avg ${weaning.averageWeightValue ?? '-'} ${weaning.weightUnit ?? 'kg'}/kit | ${weaning.destination ?? '-'}',
                    meta: weaning.weanedOn ?? 'Weaning',
                  ),
                  if (weaning != weanings.last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _FostersSection extends StatelessWidget {
  const _FostersSection({required this.fostersOut, required this.fostersIn});

  final List<LitterFosterSummary> fostersOut;
  final List<LitterFosterSummary> fostersIn;

  @override
  Widget build(BuildContext context) {
    final records = [
      for (final foster in fostersOut)
        _FosterRecord(foster: foster, isOut: true),
      for (final foster in fostersIn)
        _FosterRecord(foster: foster, isOut: false),
    ];

    return _Panel(
      title: 'Fostering',
      subtitle: records.isEmpty
          ? 'No kits moved between litters'
          : 'Kits fostered in or out of this litter',
      child: records.isEmpty
          ? const _EmptyInline(
              icon: Icons.swap_horiz,
              text: 'No fostering records',
            )
          : Column(
              children: [
                for (final record in records.take(5)) ...[
                  _RecordCard(
                    icon: record.isOut ? Icons.north_east : Icons.south_west,
                    title:
                        '${record.foster.kitCount} kits fostered ${record.isOut ? 'out' : 'in'}',
                    subtitle: record.subtitle,
                    meta: record.foster.fosteredOn ?? 'Foster',
                  ),
                  if (record != records.take(5).last)
                    const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _FosterRecord {
  const _FosterRecord({required this.foster, required this.isOut});

  final LitterFosterSummary foster;
  final bool isOut;

  String get subtitle {
    final counterpart = isOut
        ? foster.toLitterIdentifier ?? 'receiving litter'
        : foster.fromLitterIdentifier ?? 'source litter';
    final direction = isOut ? 'To $counterpart' : 'From $counterpart';
    final reason = foster.reason == null ? null : 'Reason: ${foster.reason}';

    return [direction, ?reason].join(' | ');
  }
}

class _WeightsSection extends StatelessWidget {
  const _WeightsSection({required this.weights});

  final List<LitterWeightSummary> weights;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Growth records',
      subtitle: weights.isEmpty
          ? 'Litter weights will appear here'
          : 'Total litter weight with average per kit',
      child: weights.isEmpty
          ? const _EmptyInline(
              icon: Icons.monitor_weight_outlined,
              text: 'No litter weights recorded',
            )
          : Column(
              children: [
                for (final weight in weights.take(5)) ...[
                  _RecordCard(
                    icon: Icons.monitor_weight,
                    title: _litterWeightText(weight),
                    subtitle:
                        '${_stageLabel(weight.stage)} | ${weight.method ?? 'Litter total weight'}',
                    meta: weight.weighedOn ?? 'Weight',
                  ),
                  if (weight != weights.take(5).last)
                    const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }

  String _litterWeightText(LitterWeightSummary weight) {
    final total = '${weight.weightValue} ${weight.weightUnit} total';
    final average = weight.averageWeightValue == null
        ? null
        : '${weight.averageWeightValue} ${weight.weightUnit}/kit';
    final count = weight.kitCount == null ? null : '${weight.kitCount} kits';

    return [total, if (average != null) 'avg $average', ?count].join(' | ');
  }

  String _stageLabel(String? stage) {
    return switch (stage) {
      'weaning' => 'Weaning weight',
      _ => 'Birth weight',
    };
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E5DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: RabbiTrackColors.forestGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6A746D),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final List<_StatData> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 16) / 3;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final stat in stats) _StatTile(width: width, stat: stat),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.width, required this.stat});

  final double width;
  final _StatData stat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.clamp(92, 180).toDouble(),
      child: Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(stat.icon, color: RabbiTrackColors.warmTan, size: 20),
            const SizedBox(height: 8),
            Text(
              stat.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: RabbiTrackColors.cream,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              stat.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: RabbiTrackColors.mintGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.title,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: RabbiTrackColors.mintGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: RabbiTrackColors.forestGreen, size: 18),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: RabbiTrackColors.mintGreen,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6A746D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF202723),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: RabbiTrackColors.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: RabbiTrackColors.mintGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: RabbiTrackColors.forestGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF202723),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF56615A),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            meta,
            style: const TextStyle(
              color: RabbiTrackColors.sageGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              style: const TextStyle(
                color: Color(0xFF56615A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
