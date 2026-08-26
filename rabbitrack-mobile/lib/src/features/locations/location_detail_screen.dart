import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../shared/detail_section.dart';
import '../../theme/rabbitrack_colors.dart';
import '../rabbits/rabbit_options.dart';
import 'location_controller.dart';
import 'location_models.dart';
import 'location_options.dart';

class LocationDetailScreen extends ConsumerWidget {
  const LocationDetailScreen({required this.locationId, super.key});

  final String locationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationDetailProvider(locationId));

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/locations'),
        title: const Text('Location'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
        actions: [
          IconButton(
            tooltip: 'Edit location',
            onPressed: () => context.push('/locations/$locationId/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: location.when(
        data: (item) => RefreshIndicator(
          onRefresh: () =>
              ref.refresh(locationDetailProvider(locationId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _Header(location: item),
              const SizedBox(height: 12),
              DetailSection(
                title: 'Details',
                children: [
                  DetailInfoRow(
                    'Type',
                    locationTypeLabel(item.type),
                    labelWidth: 100,
                  ),
                  DetailInfoRow('Code', item.code ?? '-', labelWidth: 100),
                  DetailInfoRow(
                    'Occupancy',
                    locationOccupancyLabel(item.occupiedCount, item.capacity),
                    labelWidth: 100,
                  ),
                  DetailInfoRow(
                    'Status',
                    item.isActive ? 'Active' : 'Inactive',
                    labelWidth: 100,
                  ),
                ],
              ),
              if (item.capacity != null) ...[
                const SizedBox(height: 12),
                _CapacitySection(location: item),
              ],
              const SizedBox(height: 12),
              _NotesSection(notes: item.notes),
              const SizedBox(height: 12),
              _RabbitsSection(rabbits: item.rabbits),
            ],
          ),
        ),
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load location',
          message: 'Try again. Offline demo data should remain available.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(locationDetailProvider(locationId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.location});

  final FarmLocationDetail location;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
            location.name,
            style: textTheme.titleLarge?.copyWith(
              color: RabbiTrackColors.cream,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            locationOccupancyLabel(location.occupiedCount, location.capacity),
            style: textTheme.bodyMedium?.copyWith(
              color: RabbiTrackColors.mintGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacitySection extends StatelessWidget {
  const _CapacitySection({required this.location});

  final FarmLocationDetail location;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: 'Capacity',
      children: [
        DetailInfoRow(
          'Status',
          locationCapacityStatusLabel(
            location.occupiedCount,
            location.capacity,
          ),
          labelWidth: 100,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: locationOccupancyRatio(
                location.occupiedCount,
                location.capacity,
              ),
              backgroundColor: RabbiTrackColors.mintGreen.withValues(
                alpha: 0.35,
              ),
              color: location.occupiedCount >= (location.capacity ?? 0)
                  ? RabbiTrackColors.warmTan
                  : RabbiTrackColors.forestGreen,
            ),
          ),
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

class _RabbitsSection extends StatelessWidget {
  const _RabbitsSection({required this.rabbits});

  final List<LocationRabbitSummary> rabbits;

  @override
  Widget build(BuildContext context) {
    if (rabbits.isEmpty) {
      return const DetailSection(
        title: 'Rabbits',
        children: [DetailInfoRow('Current', 'No rabbits assigned')],
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DetailSectionTitle('Rabbits'),
            const SizedBox(height: 10),
            for (final rabbit in rabbits)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: RabbiTrackColors.mintGreen,
                  foregroundColor: RabbiTrackColors.forestGreen,
                  child: Text(rabbitSexInitial(rabbit.sex)),
                ),
                title: Text(
                  '${rabbit.identifier}${rabbit.name == null ? '' : ' - ${rabbit.name}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(rabbitStatusLabel(rabbit.status)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/rabbits/${rabbit.id}'),
              ),
          ],
        ),
      ),
    );
  }
}
