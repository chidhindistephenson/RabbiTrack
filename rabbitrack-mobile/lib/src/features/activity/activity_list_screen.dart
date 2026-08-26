import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/app_state.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import 'activity_controller.dart';
import 'activity_models.dart';
import 'activity_options.dart';

class ActivityListScreen extends ConsumerWidget {
  const ActivityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent activity'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: activity.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppState(
              icon: Icons.history,
              title: 'No activity yet',
              message:
                  'Sales, expenses, team updates, and farm changes will appear here as the farm gets used.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(activityListProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              itemBuilder: (context, index) => _ActivityTile(log: items[index]),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemCount: items.length,
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load activity',
          message: 'Try again. Offline demo data should remain available.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(activityListProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.log});

  final ActivityLogSummary log;

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      icon: _iconFor(log.action),
      title: log.description,
      subtitle: [log.actorName, log.createdAt].whereType<String>().join(' | '),
      trailing: Text(activityActionLabel(log.action)),
    );
  }

  IconData _iconFor(String action) {
    if (action.startsWith('sale.')) {
      return Icons.sell_outlined;
    }
    if (action.startsWith('expense.')) {
      return Icons.payments_outlined;
    }
    if (action.startsWith('team.')) {
      return Icons.groups_outlined;
    }

    return Icons.history;
  }
}
