import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../rabbits/rabbit_controller.dart';
import '../reports/breeding_calendar_controller.dart';
import '../reports/breeding_calendar_repository.dart';
import '../reports/breeding_calendar_screen.dart';
import '../reports/report_csv_exporter.dart';
import 'breeding_options.dart';
import 'mating_controller.dart';
import 'mating_models.dart';
import 'mating_repository.dart';

class MatingListScreen extends ConsumerStatefulWidget {
  const MatingListScreen({super.key, this.rabbitId});

  final String? rabbitId;

  @override
  ConsumerState<MatingListScreen> createState() => _MatingListScreenState();
}

class _MatingListScreenState extends ConsumerState<MatingListScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  bool get _isRabbitProfileView => widget.rabbitId != null;

  @override
  void initState() {
    super.initState();
    if (!_isRabbitProfileView) {
      _tabController = TabController(length: 2, vsync: this)
        ..addListener(_handleTabChanged);
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabController = _tabController;
    if (!_isRabbitProfileView && tabController != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Breeding'),
          backgroundColor: RabbiTrackColors.forestGreen,
          foregroundColor: RabbiTrackColors.cream,
          actions: [
            if (tabController.index == 1)
              IconButton(
                tooltip: 'Export CSV',
                onPressed: _exportBreedingCalendarCsv,
                icon: const Icon(Icons.download_outlined),
              ),
          ],
          bottom: TabBar(
            controller: tabController,
            labelColor: RabbiTrackColors.cream,
            unselectedLabelColor: RabbiTrackColors.mintGreen,
            indicatorColor: RabbiTrackColors.warmTan,
            tabs: const [
              Tab(text: 'Matings'),
              Tab(text: 'Calendar'),
            ],
          ),
        ),
        floatingActionButton: tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/breeding/new'),
                icon: const Icon(Icons.add),
                label: const Text('Mating'),
              )
            : null,
        body: TabBarView(
          controller: tabController,
          children: const [_MatingListContent(), BreedingCalendarContent()],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rabbit breeding'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/breeding/new?rabbitId=${widget.rabbitId}'),
        icon: const Icon(Icons.add),
        label: const Text('Mating'),
      ),
      body: _MatingListContent(rabbitId: widget.rabbitId),
    );
  }

  Future<void> _exportBreedingCalendarCsv() async {
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

      if (!mounted) {
        return;
      }
      showSuccessSnackBar(context, 'Breeding calendar saved to $path');
    } catch (_) {
      if (!mounted) {
        return;
      }
      showErrorSnackBar(context, 'Could not export breeding calendar.');
    }
  }
}

class _MatingListContent extends ConsumerWidget {
  const _MatingListContent({this.rabbitId});

  final String? rabbitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRabbitProfileView = rabbitId != null;
    final matings = isRabbitProfileView
        ? ref.watch(rabbitMatingListProvider(rabbitId!))
        : ref.watch(matingListProvider);

    return matings.when(
      data: (items) {
        if (items.isEmpty) {
          return AppState(
            icon: Icons.favorite,
            title: isRabbitProfileView
                ? 'No breeding records for this rabbit'
                : 'No breeding records yet',
            message:
                'Create a mating record to calculate pregnancy check and expected kindling dates.',
            actionLabel: 'Add mating',
            actionIcon: Icons.add,
            onAction: () => context.push(
              isRabbitProfileView
                  ? '/breeding/new?rabbitId=$rabbitId'
                  : '/breeding/new',
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => isRabbitProfileView
              ? ref.refresh(rabbitMatingListProvider(rabbitId!).future)
              : ref.refresh(matingListProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) => _MatingTile(
              mating: items[index],
              onTap: () => context.push('/breeding/${items[index].id}'),
              onCheck: () =>
                  context.push('/breeding/${items[index].id}/pregnancy-check'),
              onEdit: canRevisePregnancyDecision(items[index].status)
                  ? () => context.push(
                      '/breeding/${items[index].id}/pregnancy-check?revise=1',
                    )
                  : null,
              onDelete: () => _confirmDelete(context, ref, items[index]),
            ),
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemCount: items.length,
          ),
        );
      },
      error: (error, stackTrace) => AppState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load breeding',
        message: 'Check the API server and try again.',
        actionLabel: 'Retry',
        onAction: () => isRabbitProfileView
            ? ref.invalidate(rabbitMatingListProvider(rabbitId!))
            : ref.invalidate(matingListProvider),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MatingSummary mating,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete mating record?'),
        content: Text(
          '${mating.doeIdentifier} x ${mating.buckIdentifier} will be removed. Records with litters cannot be deleted from here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    try {
      await ref
          .read(matingRepositoryProvider)
          .delete(farmId: farm.id, matingId: mating.id);

      ref.invalidate(matingListProvider);
      ref.invalidate(rabbitListProvider);

      if (context.mounted) {
        showSuccessSnackBar(context, 'Mating record deleted.');
      }
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not delete mating record.'),
        );
      }
    }
  }
}

class _MatingTile extends StatelessWidget {
  const _MatingTile({
    required this.mating,
    required this.onTap,
    required this.onCheck,
    required this.onDelete,
    this.onEdit,
  });

  final MatingSummary mating;
  final VoidCallback onTap;
  final VoidCallback onCheck;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      icon: Icons.favorite,
      title: '${mating.doeIdentifier} x ${mating.buckIdentifier}',
      subtitle:
          '${breedingStatusLabel(mating.status)} | Check ${mating.pregnancyCheckDueOn} | Kindling ${mating.expectedKindlingOn}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPregnancyCheckDue(
            status: mating.status,
            dueOn: mating.pregnancyCheckDueOn,
          ))
            IconButton(
              tooltip: 'Pregnancy check',
              onPressed: onCheck,
              icon: const Icon(Icons.fact_check_outlined),
            ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit pregnancy decision',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            tooltip: 'Delete mating record',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
