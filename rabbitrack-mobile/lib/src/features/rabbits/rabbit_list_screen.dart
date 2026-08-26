import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/rabbit_icon.dart';
import '../../theme/rabbitrack_colors.dart';
import '../litters/litter_list_screen.dart';
import 'rabbit_controller.dart';
import 'rabbit_list_options.dart';
import 'rabbit_models.dart';
import 'rabbit_options.dart';

class RabbitListScreen extends ConsumerStatefulWidget {
  const RabbitListScreen({super.key});

  @override
  ConsumerState<RabbitListScreen> createState() => _RabbitListScreenState();
}

class _RabbitListScreenState extends ConsumerState<RabbitListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rabbits'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
        bottom: TabBar(
          controller: _tabController,
          labelColor: RabbiTrackColors.cream,
          unselectedLabelColor: RabbiTrackColors.mintGreen,
          indicatorColor: RabbiTrackColors.warmTan,
          tabs: const [
            Tab(text: 'Rabbits'),
            Tab(text: 'Litters'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: switch (_tabController.index) {
          1 => () => context.push('/litters/new'),
          _ => () => context.push('/rabbits/new'),
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 1 ? 'Kindling' : 'Rabbit'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_RabbitListContent(), LitterListContent()],
      ),
    );
  }
}

class _RabbitListContent extends ConsumerStatefulWidget {
  const _RabbitListContent();

  @override
  ConsumerState<_RabbitListContent> createState() => _RabbitListContentState();
}

class _RabbitListContentState extends ConsumerState<_RabbitListContent> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateSearch);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_updateSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch() {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }

      final value = _searchController.text.trim();
      final filters = ref.read(rabbitListFiltersProvider);

      if (filters.search == value ||
          (filters.search == null && value.isEmpty)) {
        return;
      }

      ref.read(rabbitListFiltersProvider.notifier).state = filters.copyWith(
        search: value.isEmpty ? null : value,
        clearSearch: value.isEmpty,
      );
    });
  }

  void _resetFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    ref.read(rabbitListFiltersProvider.notifier).state =
        const RabbitListFilters();
  }

  @override
  Widget build(BuildContext context) {
    final rabbits = ref.watch(rabbitListProvider);
    final filters = ref.watch(rabbitListFiltersProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(rabbitListProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _RabbitFilters(
            searchController: _searchController,
            filters: filters,
            onReset: _resetFilters,
          ),
          const SizedBox(height: 14),
          rabbits.when(
            data: (items) => _RabbitResults(
              items: items,
              filters: filters,
              onReset: _resetFilters,
            ),
            error: (error, stackTrace) => AppState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load rabbits',
              message: 'Check that the API server is running, then try again.',
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(rabbitListProvider),
              minHeight: 320,
            ),
            loading: () => const _RabbitResultsLoading(),
          ),
        ],
      ),
    );
  }
}

class _RabbitResults extends StatelessWidget {
  const _RabbitResults({
    required this.items,
    required this.filters,
    required this.onReset,
  });

  final List<RabbitSummary> items;
  final RabbitListFilters filters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final hasNoFilters =
        filters.search == null &&
        filters.sex == null &&
        filters.status == null &&
        filters.breed == null;

    return Column(
      children: [
        _RabbitListSummary(count: items.length, filters: filters),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 36),
            child: AppState(
              icon: Icons.manage_search,
              iconWidget: const Center(
                child: RabbitIcon(
                  color: RabbiTrackColors.forestGreen,
                  size: 36,
                ),
              ),
              title: hasNoFilters ? 'No rabbits yet' : 'No rabbits found',
              message: hasNoFilters
                  ? 'Add your first rabbit to start tracking locations, status, breeding, health, and weights.'
                  : 'Try clearing the search or changing the filters.',
              actionLabel: hasNoFilters ? 'Add rabbit' : 'Reset filters',
              actionIcon: hasNoFilters ? Icons.add : Icons.refresh,
              onAction: hasNoFilters
                  ? () => context.push('/rabbits/new')
                  : onReset,
              minHeight: 300,
            ),
          )
        else
          for (final rabbit in items) ...[
            _RabbitTile(
              rabbit: rabbit,
              onTap: () => context.push('/rabbits/${rabbit.id}'),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _RabbitResultsLoading extends StatelessWidget {
  const _RabbitResultsLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RabbitFilters extends ConsumerWidget {
  const _RabbitFilters({
    required this.searchController,
    required this.filters,
    required this.onReset,
  });

  final TextEditingController searchController;
  final RabbitListFilters filters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search ID, name, breed, or tag',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: searchController.clear,
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final filtersFitInRow = constraints.maxWidth >= 390;
            final sexField = DropdownButtonFormField<String?>(
              initialValue: filters.sex,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sex',
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
              ],
              onChanged: (value) {
                ref.read(rabbitListFiltersProvider.notifier).state = filters
                    .copyWith(sex: value, clearSex: value == null);
              },
            );
            final statusField = DropdownButtonFormField<String?>(
              initialValue: filters.status,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Status',
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                for (final status in rabbitStatuses)
                  DropdownMenuItem(
                    value: status,
                    child: Text(
                      rabbitStatusLabel(status),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              selectedItemBuilder: (context) => [
                const Text('All', overflow: TextOverflow.ellipsis),
                for (final status in rabbitStatuses)
                  Text(
                    rabbitStatusLabel(status),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
              onChanged: (value) {
                ref.read(rabbitListFiltersProvider.notifier).state = filters
                    .copyWith(status: value, clearStatus: value == null);
              },
            );

            if (!filtersFitInRow) {
              return Column(
                children: [sexField, const SizedBox(height: 10), statusField],
              );
            }

            return Row(
              children: [
                Expanded(child: sexField),
                const SizedBox(width: 10),
                Expanded(child: statusField),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          initialValue: filters.breed,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Breed',
            filled: true,
            fillColor: Colors.white,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('All breeds')),
            for (final breed in southernAfricaRabbitBreeds)
              DropdownMenuItem(
                value: breed,
                child: Text(breed, overflow: TextOverflow.ellipsis),
              ),
          ],
          selectedItemBuilder: (context) => [
            const Text('All breeds', overflow: TextOverflow.ellipsis),
            for (final breed in southernAfricaRabbitBreeds)
              Text(breed, overflow: TextOverflow.ellipsis),
          ],
          onChanged: (value) {
            ref.read(rabbitListFiltersProvider.notifier).state = filters
                .copyWith(breed: value, clearBreed: value == null);
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: hasActiveRabbitFilters(filters) ? onReset : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
          ),
        ),
      ],
    );
  }
}

class _RabbitListSummary extends StatelessWidget {
  const _RabbitListSummary({required this.count, required this.filters});

  final int count;
  final RabbitListFilters filters;

  @override
  Widget build(BuildContext context) {
    final hasFilters = hasActiveRabbitFilters(filters);

    return Row(
      children: [
        Expanded(
          child: Text(
            rabbitListSummaryText(count: count, filters: filters),
            style: const TextStyle(
              color: RabbiTrackColors.forestGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (hasFilters)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: RabbiTrackColors.mintGreen,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Filtered',
              style: TextStyle(
                color: RabbiTrackColors.forestGreen,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _RabbitTile extends StatelessWidget {
  const _RabbitTile({required this.rabbit, required this.onTap});

  final RabbitSummary rabbit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title =
        '${rabbit.identifier}${rabbit.name == null ? '' : ' - ${rabbit.name}'}';
    final subtitle = [
      if (rabbit.breed != null) rabbit.breed,
      rabbit.currentLocationName ?? 'No location',
    ].join(' | ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: RabbiTrackColors.mintGreen,
                  foregroundColor: RabbiTrackColors.forestGreen,
                  child: Text(rabbitSexInitial(rabbit.sex)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF4F5A55)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusPill(status: rabbit.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final terminal = isTerminalRabbitStatus(status);

    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: terminal ? RabbiTrackColors.cream : null,
        border: Border.all(
          color: terminal
              ? RabbiTrackColors.warmTan
              : RabbiTrackColors.mintGreen,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        compactRabbitStatusLabel(status),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF4F5A55),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}
