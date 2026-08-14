import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../theme/rabbitrack_colors.dart';
import 'breeding_options.dart';
import 'mating_controller.dart';
import 'mating_models.dart';

class MatingDetailScreen extends ConsumerWidget {
  const MatingDetailScreen({required this.matingId, super.key});

  final String matingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mating = ref.watch(matingDetailProvider(matingId));

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/breeding'),
        title: const Text('Breeding record'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: mating.when(
        data: (item) => RefreshIndicator(
          onRefresh: () => ref.refresh(matingDetailProvider(matingId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _HeroCard(mating: item),
              const SizedBox(height: 14),
              _BreedingActions(mating: item),
              const SizedBox(height: 14),
              _TimelineSection(mating: item),
              const SizedBox(height: 14),
              _PregnancyChecksSection(checks: item.pregnancyChecks),
              const SizedBox(height: 14),
              _LittersSection(litters: item.litters),
            ],
          ),
        ),
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load breeding record',
          message: 'Check that the API server is running, then try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(matingDetailProvider(matingId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.mating});

  final MatingDetail mating;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = breedingStatusLabel(mating.status);

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
                  Icons.favorite,
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
                      '${mating.doeIdentifier} x ${mating.buckIdentifier}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: RabbiTrackColors.cream,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status,
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
                icon: Icons.fact_check_outlined,
                label: 'Check due',
                value: mating.pregnancyCheckDueOn,
              ),
              _StatData(
                icon: Icons.inventory_2_outlined,
                label: 'Nest box',
                value: mating.nestBoxDueOn ?? '-',
              ),
              _StatData(
                icon: Icons.child_care,
                label: 'Kindling',
                value: mating.expectedKindlingOn,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreedingActions extends StatelessWidget {
  const _BreedingActions({required this.mating});

  final MatingDetail mating;

  @override
  Widget build(BuildContext context) {
    final canCheck = isPregnancyCheckDue(
      status: mating.status,
      dueOn: mating.pregnancyCheckDueOn,
    );
    final canRevise = canRevisePregnancyDecision(mating.status);
    final canKindle = canRecordKindling(mating.status);

    if (!canCheck && !canRevise && !canKindle) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (canCheck)
          FilledButton.icon(
            onPressed: () =>
                context.push('/breeding/${mating.id}/pregnancy-check'),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Pregnancy check'),
          ),
        if (canRevise)
          OutlinedButton.icon(
            onPressed: () =>
                context.push('/breeding/${mating.id}/pregnancy-check?revise=1'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit decision'),
          ),
        if (canKindle)
          FilledButton.icon(
            onPressed: () => context.push('/litters/new?matingId=${mating.id}'),
            icon: const Icon(Icons.child_care_outlined),
            label: const Text('Record kindling'),
          ),
      ],
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.mating});

  final MatingDetail mating;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Breeding timeline',
      subtitle: 'Dates and observations for this pairing',
      child: Column(
        children: [
          _TimelineRow(
            icon: Icons.favorite_outline,
            title: 'Mated',
            value: _dateOnly(mating.matedAt),
          ),
          _TimelineRow(
            icon: Icons.fact_check_outlined,
            title: 'Pregnancy check',
            value: mating.pregnancyCheckDueOn,
          ),
          _TimelineRow(
            icon: Icons.inventory_2_outlined,
            title: 'Nest box',
            value: mating.nestBoxDueOn ?? '-',
          ),
          _TimelineRow(
            icon: Icons.child_care_outlined,
            title: 'Expected kindling',
            value: mating.expectedKindlingOn,
          ),
          _TimelineRow(
            icon: Icons.visibility_outlined,
            title: 'Outcome',
            value: matingOutcomeLabel(mating.outcome),
          ),
          _TimelineRow(
            icon: Icons.notes_outlined,
            title: 'Behavior',
            value: mating.behaviorObserved ?? '-',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _PregnancyChecksSection extends StatelessWidget {
  const _PregnancyChecksSection({required this.checks});

  final List<PregnancyCheckSummary> checks;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Pregnancy checks',
      subtitle: checks.isEmpty
          ? 'No pregnancy decision recorded yet'
          : 'Latest checks for this mating',
      child: checks.isEmpty
          ? const _EmptyInline(
              icon: Icons.fact_check_outlined,
              text: 'No checks recorded',
            )
          : Column(
              children: [
                for (final check in checks) ...[
                  _RecordCard(
                    icon: Icons.fact_check_outlined,
                    title: pregnancyCheckResultLabel(check.result),
                    subtitle: check.notes ?? 'Pregnancy check decision',
                    meta: check.checkedOn ?? 'Check',
                  ),
                  if (check != checks.last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _LittersSection extends StatelessWidget {
  const _LittersSection({required this.litters});

  final List<MatingLitterSummary> litters;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Litter outcome',
      subtitle: litters.isEmpty
          ? 'No kindling record yet'
          : 'Kindling results from this breeding',
      child: litters.isEmpty
          ? const _EmptyInline(
              icon: Icons.child_care_outlined,
              text: 'No litter recorded',
            )
          : Column(
              children: [
                for (final litter in litters) ...[
                  _RecordCard(
                    icon: Icons.child_care,
                    title: litter.identifier,
                    subtitle:
                        '${litter.kindledOn ?? '-'} | Born alive ${litter.kitsBornAlive ?? 0} | Stillborn ${litter.kitsStillborn ?? 0} | Current live ${litter.currentLiveCount ?? 0}',
                    meta: breedingStatusLabel(litter.status),
                    onTap: () => context.push('/litters/${litter.id}'),
                  ),
                  if (litter != litters.last) const SizedBox(height: 10),
                ],
              ],
            ),
    );
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RabbiTrackColors.cream,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
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
                child: Icon(
                  icon,
                  color: RabbiTrackColors.forestGreen,
                  size: 22,
                ),
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
        ),
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

String _dateOnly(String? value) {
  if (value == null || value.isEmpty) {
    return '-';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  final year = parsed.year.toString().padLeft(4, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final day = parsed.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}
