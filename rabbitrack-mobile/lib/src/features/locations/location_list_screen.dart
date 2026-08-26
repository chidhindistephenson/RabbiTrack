import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import 'location_controller.dart';
import 'location_models.dart';
import 'location_options.dart';

class LocationListScreen extends ConsumerWidget {
  const LocationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/locations/new'),
        icon: const Icon(Icons.add),
        label: const Text('Location'),
      ),
      body: locations.when(
        data: (items) {
          if (items.isEmpty) {
            return AppState(
              icon: Icons.meeting_room_outlined,
              title: 'No locations yet',
              message:
                  'Create cages, grow-out pens, quarantine areas, or other spaces before assigning rabbits.',
              actionLabel: 'Add location',
              actionIcon: Icons.add,
              onAction: () => context.push('/locations/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(locationListProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _LocationSummaryCard(locations: items),
                const SizedBox(height: 12),
                for (final location in items) ...[
                  _LocationTile(
                    location: location,
                    onTap: () => context.push('/locations/${location.id}'),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load locations',
          message: 'Try again. Offline demo data should remain available.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(locationListProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _LocationSummaryCard extends StatelessWidget {
  const _LocationSummaryCard({required this.locations});

  final List<FarmLocationSummary> locations;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.meeting_room_outlined,
            color: RabbiTrackColors.warmTan,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryMetric(
              label: 'Total',
              value: locationCountLabel(locations.length),
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              label: 'Status',
              value: activeLocationCountLabel(locations),
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              label: 'Capacity',
              value: locationCapacitySummaryLabel(locations),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RabbiTrackColors.mintGreen,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: RabbiTrackColors.cream,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.location, required this.onTap});

  final FarmLocationSummary location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      icon: Icons.meeting_room_outlined,
      title: location.name,
      subtitle: [
        locationTypeLabel(location.type),
        location.code,
        locationOccupancyLabel(location.occupiedCount, location.capacity),
      ].whereType<String>().join(' | '),
      trailing: location.isActive
          ? const Icon(Icons.check_circle_outline)
          : const Icon(Icons.pause_circle_outline),
      onTap: onTap,
    );
  }
}
