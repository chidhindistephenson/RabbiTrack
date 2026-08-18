import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../shared/detail_section.dart';
import '../../shared/rabbit_icon.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import '../reports/buck_performance_report_controller.dart';
import '../reports/buck_performance_report_models.dart';
import '../reports/doe_performance_report_controller.dart';
import '../reports/doe_performance_report_models.dart';
import '../weights/weight_controller.dart';
import '../weights/weight_models.dart';
import 'rabbit_controller.dart';
import 'rabbit_models.dart';
import 'rabbit_options.dart';

class RabbitDetailScreen extends ConsumerWidget {
  const RabbitDetailScreen({required this.rabbitId, super.key});

  final String rabbitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rabbit = ref.watch(rabbitDetailProvider(rabbitId));
    final weights = ref.watch(rabbitWeightListProvider(rabbitId));

    return Scaffold(
      backgroundColor: RabbiTrackColors.cream,
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/rabbits'),
        title: const Text('Rabbit profile'),
        backgroundColor: RabbiTrackColors.cream,
        foregroundColor: RabbiTrackColors.forestGreen,
        elevation: 0,
        actions: [
          rabbit.maybeWhen(
            data: (item) => isTerminalRabbitStatus(item.status)
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Edit profile',
                    onPressed: () => context.push('/rabbits/$rabbitId/edit'),
                    icon: const Icon(Icons.edit_outlined),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: rabbit.when(
        data: (item) => RefreshIndicator(
          onRefresh: () => ref.refresh(rabbitDetailProvider(rabbitId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _ProfileHeader(rabbit: item),
              const SizedBox(height: 14),
              if (isTerminalRabbitStatus(item.status)) ...[
                _ArchivedRabbitNotice(status: item.status),
                const SizedBox(height: 14),
              ] else ...[
                _RabbitActions(rabbitId: rabbitId),
                const SizedBox(height: 14),
              ],
              _BasicInfoSection(rabbit: item),
              const SizedBox(height: 14),
              _RecordLinks(rabbitId: rabbitId, status: item.status),
              const SizedBox(height: 14),
              _BreedingPerformanceSection(rabbit: item),
              const SizedBox(height: 14),
              _ParentsSection(
                mother: _parentLabel(item.mother),
                father: _parentLabel(item.father),
              ),
              const SizedBox(height: 14),
              _NotesSection(notes: item.notes),
              const SizedBox(height: 14),
              _WeightHistorySection(weights: weights),
              const SizedBox(height: 14),
              _MovementsSection(movements: item.movements),
            ],
          ),
        ),
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load rabbit profile',
          message: 'Check that the API server is running, then try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(rabbitDetailProvider(rabbitId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String _parentLabel(RabbitParent? parent) {
    if (parent == null) {
      return '-';
    }

    return '${parent.identifier}${parent.name == null ? '' : ' - ${parent.name}'}';
  }
}

class _BreedingPerformanceSection extends ConsumerWidget {
  const _BreedingPerformanceSection({required this.rabbit});

  final RabbitDetail rabbit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rabbit.sex == 'female') {
      final report = ref.watch(doePerformanceReportProvider);

      return report.when(
        data: (item) {
          DoePerformanceRow? row;
          for (final doe in item.does) {
            if (doe.id == rabbit.id) {
              row = doe;
              break;
            }
          }

          return _DoePerformanceCard(row: row);
        },
        error: (error, stackTrace) => const _PerformanceUnavailable(),
        loading: () => const _PerformanceLoading(),
      );
    }

    if (rabbit.sex == 'male') {
      final report = ref.watch(buckPerformanceReportProvider);

      return report.when(
        data: (item) {
          BuckPerformanceRow? row;
          for (final buck in item.bucks) {
            if (buck.id == rabbit.id) {
              row = buck;
              break;
            }
          }

          return _BuckPerformanceCard(row: row);
        },
        error: (error, stackTrace) => const _PerformanceUnavailable(),
        loading: () => const _PerformanceLoading(),
      );
    }

    return const SizedBox.shrink();
  }
}

class _DoePerformanceCard extends StatelessWidget {
  const _DoePerformanceCard({required this.row});

  final DoePerformanceRow? row;

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'Doe performance',
      actionLabel: 'Report',
      onAction: () => context.push('/reports/does/performance'),
      child: row == null
          ? const Text('No doe breeding performance recorded yet')
          : GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _InfoTile(
                  icon: Icons.favorite,
                  label: 'Pregnancies',
                  value: '${row!.confirmedPregnancies}',
                ),
                _InfoTile(
                  icon: Icons.child_care,
                  label: 'Kindlings',
                  value: '${row!.kindlings}',
                ),
                _InfoTile(
                  icon: Icons.check_circle_outline,
                  label: 'Weaned',
                  value: '${row!.kitsWeaned}',
                ),
                _InfoTile(
                  icon: Icons.trending_up,
                  label: 'Survival',
                  value: '${row!.survivalRate.toStringAsFixed(1)}%',
                ),
              ],
            ),
    );
  }
}

class _BuckPerformanceCard extends StatelessWidget {
  const _BuckPerformanceCard({required this.row});

  final BuckPerformanceRow? row;

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'Buck performance',
      actionLabel: 'Report',
      onAction: () => context.push('/reports/bucks/performance'),
      child: row == null
          ? const Text('No buck breeding performance recorded yet')
          : GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _InfoTile(
                  icon: Icons.percent,
                  label: 'Conception',
                  value: '${row!.conceptionRate.toStringAsFixed(1)}%',
                ),
                _InfoTile(
                  icon: Icons.favorite,
                  label: 'Matings',
                  value: '${row!.matings}',
                ),
                _InfoTile(
                  icon: Icons.child_care,
                  label: 'Litters',
                  value: '${row!.litters}',
                ),
                _InfoTile(
                  icon: Icons.check_circle_outline,
                  label: 'Weaned',
                  value: '${row!.kitsWeaned}',
                ),
              ],
            ),
    );
  }
}

class _PerformanceLoading extends StatelessWidget {
  const _PerformanceLoading();

  @override
  Widget build(BuildContext context) {
    return const _ProfileSection(
      title: 'Breeding performance',
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PerformanceUnavailable extends StatelessWidget {
  const _PerformanceUnavailable();

  @override
  Widget build(BuildContext context) {
    return const _ProfileSection(
      title: 'Breeding performance',
      child: Text('Could not load breeding performance.'),
    );
  }
}

class _RabbitActions extends StatelessWidget {
  const _RabbitActions({required this.rabbitId});

  final String rabbitId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.edit_note,
            label: 'Status',
            onPressed: () => context.push('/rabbits/$rabbitId/status'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.swap_horiz,
            label: 'Move',
            onPressed: () => context.push('/rabbits/$rabbitId/move'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.monitor_weight_outlined,
            label: 'Weight',
            onPressed: () => context.push('/rabbits/$rabbitId/weight'),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: RabbiTrackColors.forestGreen),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: RabbiTrackColors.forestGreen,
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

class _BasicInfoSection extends StatelessWidget {
  const _BasicInfoSection({required this.rabbit});

  final RabbitDetail rabbit;

  @override
  Widget build(BuildContext context) {
    final weight = rabbit.weightValue == null
        ? '-'
        : '${rabbit.weightValue} ${rabbit.weightUnit ?? 'kg'}';

    return _ProfileSection(
      title: 'Basic info',
      actionLabel: isTerminalRabbitStatus(rabbit.status) ? null : 'Edit',
      onAction: isTerminalRabbitStatus(rabbit.status)
          ? null
          : () => context.push('/rabbits/${rabbit.id}/edit'),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 2.9,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _InfoTile(
            icon: Icons.badge_outlined,
            label: 'ID',
            value: rabbit.identifier,
          ),
          _InfoTile(
            icon: Icons.transgender,
            label: 'Sex',
            value: rabbitSexLabel(rabbit.sex),
          ),
          _InfoTile(
            icon: Icons.auto_awesome,
            label: 'Breed',
            value: rabbit.breed ?? '-',
          ),
          _InfoTile(
            icon: Icons.flag_outlined,
            label: 'Status',
            value: rabbitStatusLabel(rabbit.status),
          ),
          _InfoTile(icon: Icons.scale_outlined, label: 'Weight', value: weight),
          _InfoTile(
            icon: Icons.home_work_outlined,
            label: 'Location',
            value: rabbit.currentLocationName ?? 'No location',
          ),
          _InfoTile(
            icon: Icons.palette_outlined,
            label: 'Colour',
            value: rabbit.colour ?? '-',
          ),
          _InfoTile(
            icon: Icons.cake_outlined,
            label: 'Birth date',
            value: rabbit.dateOfBirth ?? '-',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: RabbiTrackColors.mintGreen.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: RabbiTrackColors.forestGreen, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RabbiTrackColors.sageGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordLinks extends StatelessWidget {
  const _RecordLinks({required this.rabbitId, required this.status});

  final String rabbitId;
  final String status;

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'Records',
      child: Column(
        children: [
          SoftListTile(
            icon: Icons.favorite_border,
            title: 'Health records',
            subtitle: 'Illness, treatments, and vet care',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/health?rabbitId=$rabbitId'),
          ),
          const SizedBox(height: 10),
          SoftListTile(
            icon: Icons.favorite,
            title: 'Breeding records',
            subtitle: 'Mating, pregnancy checks, and kindling',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/breeding?rabbitId=$rabbitId'),
          ),
          const SizedBox(height: 10),
          SoftListTile(
            icon: Icons.sell_outlined,
            title: 'Sale record',
            subtitle: isTerminalRabbitStatus(status)
                ? 'View sale history for this rabbit'
                : 'Mark this rabbit for sale or record a sale',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/sales?rabbitId=$rabbitId'),
          ),
        ],
      ),
    );
  }
}

class _ArchivedRabbitNotice extends StatelessWidget {
  const _ArchivedRabbitNotice({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RabbiTrackColors.warmTan.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RabbiTrackColors.warmTan),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: RabbiTrackColors.forestGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This rabbit is ${rabbitStatusLabel(status).toLowerCase()}. Its profile is now historical, so active farm actions are disabled.',
              style: const TextStyle(
                color: RabbiTrackColors.forestGreen,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentsSection extends StatelessWidget {
  const _ParentsSection({required this.mother, required this.father});

  final String mother;
  final String father;

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'Lineage',
      child: Row(
        children: [
          Expanded(
            child: _InfoTile(
              icon: Icons.female,
              label: 'Mother',
              value: mother,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InfoTile(icon: Icons.male, label: 'Father', value: father),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: DetailSectionTitle(title)),
                if (actionLabel != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _WeightHistorySection extends StatelessWidget {
  const _WeightHistorySection({required this.weights});

  final AsyncValue<List<WeightSummary>> weights;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Weight history',
      children: [
        weights.when(
          data: (items) {
            if (items.isEmpty) {
              return const Text('No weights recorded');
            }

            return Column(
              children: [
                for (final weight in items.take(5))
                  DetailInfoRow(
                    weight.weighedOn,
                    '${weight.weightValue} ${weight.weightUnit}',
                    labelWidth: 110,
                  ),
              ],
            );
          },
          error: (error, stackTrace) =>
              const Text('Could not load weight history.'),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.notes});

  final String? notes;

  @override
  Widget build(BuildContext context) {
    final trimmed = notes?.trim();

    return DetailSection(
      title: 'Notes',
      children: [
        Text(
          trimmed == null || trimmed.isEmpty ? 'No notes recorded' : trimmed,
          style: TextStyle(
            color: trimmed == null || trimmed.isEmpty
                ? RabbiTrackColors.sageGreen
                : null,
            fontWeight: trimmed == null || trimmed.isEmpty
                ? FontWeight.w500
                : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.rabbit});

  final RabbitDetail rabbit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final displayName = rabbit.name ?? 'Unnamed rabbit';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 176,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [RabbiTrackColors.mintGreen, RabbiTrackColors.warmTan],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  bottom: -12,
                  child: RabbitIcon(
                    color: RabbiTrackColors.cream.withValues(alpha: 0.55),
                    size: 170,
                    filled: true,
                  ),
                ),
                Center(
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: RabbiTrackColors.cream,
                        width: 5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        rabbitSexInitial(rabbit.sex),
                        style: textTheme.displaySmall?.copyWith(
                          color: RabbiTrackColors.forestGreen,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isTerminalRabbitStatus(rabbit.status))
                  Positioned(
                    right: 14,
                    top: 14,
                    child: IconButton.filled(
                      tooltip: 'Edit profile',
                      onPressed: () =>
                          context.push('/rabbits/${rabbit.id}/edit'),
                      icon: const Icon(Icons.camera_alt_outlined),
                      style: IconButton.styleFrom(
                        backgroundColor: RabbiTrackColors.forestGreen,
                        foregroundColor: RabbiTrackColors.cream,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: RabbiTrackColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rabbit.identifier,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: RabbiTrackColors.sageGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _ProfileChip(
                      icon: Icons.flag_outlined,
                      label: rabbitStatusLabel(rabbit.status),
                    ),
                    _ProfileChip(
                      icon: Icons.home_work_outlined,
                      label: rabbit.currentLocationName ?? 'No location',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RabbiTrackColors.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: RabbiTrackColors.forestGreen),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: RabbiTrackColors.forestGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementsSection extends StatelessWidget {
  const _MovementsSection({required this.movements});

  final List<RabbitMovementSummary> movements;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return const DetailSection(
        title: 'Movement history',
        children: [DetailInfoRow('Latest', 'No movements recorded')],
      );
    }

    return DetailSection(
      title: 'Movement history',
      children: [
        for (final movement in movements)
          DetailInfoRow(
            '${movement.fromLocation ?? 'Start'} to ${movement.toLocation ?? 'Unknown'}',
            [movement.reason, movement.movedAt].whereType<String>().join(' | '),
            labelWidth: 150,
          ),
      ],
    );
  }
}
