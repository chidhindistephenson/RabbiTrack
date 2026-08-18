import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'breeding_calendar_controller.dart';
import 'breeding_calendar_models.dart';
import 'breeding_calendar_repository.dart';
import 'report_csv_exporter.dart';

class BreedingCalendarScreen extends ConsumerWidget {
  const BreedingCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(breedingCalendarProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/more'),
        title: const Text('Breeding calendar'),
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
      body: events.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppState(
              icon: Icons.event_available_outlined,
              title: 'No breeding dates yet',
              message:
                  'Mating, kindling, and weaning records will appear here automatically.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(breedingCalendarProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              children: [
                const _CalendarHeader(),
                const SizedBox(height: 12),
                for (final group in _groupedEvents(items)) ...[
                  _DateHeading(date: group.date),
                  const SizedBox(height: 8),
                  for (final event in group.events) ...[
                    _CalendarEventTile(event: event),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                ],
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Calendar unavailable',
          message: 'Check the API server and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(breedingCalendarProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      showErrorSnackBar(context, 'Select a farm before exporting.');
      return;
    }

    final today = DateTime.now();
    final start = dateValue(today.subtract(const Duration(days: 30)));
    final end = dateValue(today.add(const Duration(days: 90)));

    try {
      final csv = await ref
          .read(breedingCalendarRepositoryProvider)
          .exportCsv(farmId: farm.id, start: start, end: end);
      final path = await saveReportCsv(
        fileName: 'breeding-calendar.csv',
        contents: csv,
      );

      if (!context.mounted) {
        return;
      }
      showSuccessSnackBar(context, 'Breeding calendar saved to $path');
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      showErrorSnackBar(context, 'Could not export breeding calendar.');
    }
  }

  List<_EventGroup> _groupedEvents(List<BreedingCalendarEvent> events) {
    final groups = <String, List<BreedingCalendarEvent>>{};

    for (final event in events) {
      groups.putIfAbsent(event.date, () => []).add(event);
    }

    return groups.entries
        .map((entry) => _EventGroup(date: entry.key, events: entry.value))
        .toList();
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_available_outlined, color: RabbiTrackColors.warmTan),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Upcoming and recent breeding milestones',
              style: TextStyle(
                color: RabbiTrackColors.cream,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateHeading extends StatelessWidget {
  const _DateHeading({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Text(
      _friendlyDate(date),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: RabbiTrackColors.forestGreen,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _CalendarEventTile extends StatelessWidget {
  const _CalendarEventTile({required this.event});

  final BreedingCalendarEvent event;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => _openEvent(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: RabbiTrackColors.mintGreen),
      ),
      tileColor: Colors.white,
      leading: CircleAvatar(
        backgroundColor: RabbiTrackColors.mintGreen,
        foregroundColor: RabbiTrackColors.forestGreen,
        child: Icon(_eventIcon(event.type), size: 20),
      ),
      title: Text(
        event.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        event.subtitle ?? _eventTypeLabel(event.type),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  void _openEvent(BuildContext context) {
    if (event.relatedType == 'litter') {
      context.push('/litters/${event.relatedId}');
      return;
    }

    context.push('/breeding/${event.relatedId}');
  }
}

class _EventGroup {
  const _EventGroup({required this.date, required this.events});

  final String date;
  final List<BreedingCalendarEvent> events;
}

IconData _eventIcon(String type) {
  return switch (type) {
    'mating' => Icons.favorite_border,
    'pregnancy_check' => Icons.fact_check_outlined,
    'nest_box' => Icons.inventory_2_outlined,
    'expected_kindling' => Icons.child_care_outlined,
    'kindling' => Icons.child_friendly_outlined,
    'weaning' => Icons.event_available_outlined,
    _ => Icons.event_note_outlined,
  };
}

String _eventTypeLabel(String type) {
  return switch (type) {
    'mating' => 'Mating',
    'pregnancy_check' => 'Pregnancy check',
    'nest_box' => 'Nest box',
    'expected_kindling' => 'Expected kindling',
    'kindling' => 'Kindling',
    'weaning' => 'Weaning',
    _ => type,
  };
}

String _friendlyDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) {
    return value;
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
