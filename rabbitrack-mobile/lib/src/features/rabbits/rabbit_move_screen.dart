import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';

import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../locations/location_controller.dart';
import '../locations/location_models.dart';
import 'rabbit_controller.dart';
import 'rabbit_models.dart';
import 'rabbit_move_options.dart';
import 'rabbit_options.dart';
import 'rabbit_repository.dart';

class RabbitMoveScreen extends ConsumerStatefulWidget {
  const RabbitMoveScreen({required this.rabbitId, super.key});

  final String rabbitId;

  @override
  ConsumerState<RabbitMoveScreen> createState() => _RabbitMoveScreenState();
}

class _RabbitMoveScreenState extends ConsumerState<RabbitMoveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController(text: 'Location change');
  final _notesController = TextEditingController();
  String? _locationId;
  bool _isSaving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        _locationId == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(rabbitRepositoryProvider)
          .move(
            farmId: farm.id,
            rabbitId: widget.rabbitId,
            toLocationId: _locationId!,
            reason: _optionalText(_reasonController),
            notes: _optionalText(_notesController),
          );

      ref.invalidate(rabbitListProvider);
      ref.invalidate(rabbitDetailProvider(widget.rabbitId));

      if (mounted) {
        showSuccessSnackBar(context, 'Rabbit moved.');
        popOrGo(context, '/rabbits/${widget.rabbitId}');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not move rabbit. Try again.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();

    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(locationListProvider);
    final rabbit = ref.watch(rabbitDetailProvider(widget.rabbitId));

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: '/rabbits/${widget.rabbitId}',
        ),
        title: const Text('Move rabbit'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: SafeArea(
        child: rabbit.when(
          data: (item) => locations.when(
            data: (items) {
              if (isTerminalRabbitStatus(item.status)) {
                return AppState(
                  icon: Icons.lock_outline,
                  title: 'Movement locked',
                  message:
                      'This rabbit is ${rabbitStatusLabel(item.status).toLowerCase()}, so its movement history is read-only.',
                  actionLabel: 'View profile',
                  actionIcon: Icons.arrow_back,
                  onAction: () => popOrGo(context, '/rabbits/${item.id}'),
                );
              }

              final destinations = rabbitMoveDestinations(
                locations: items,
                rabbit: item,
              );

              if (items.isEmpty) {
                return AppState(
                  icon: Icons.location_off_outlined,
                  title: 'No locations yet',
                  message:
                      'Create a cage, pen, or area before moving this rabbit.',
                  actionLabel: 'Add location',
                  actionIcon: Icons.add,
                  onAction: () => context.push('/locations/new'),
                );
              }

              if (destinations.isEmpty) {
                return AppState(
                  icon: Icons.location_searching_outlined,
                  title: 'No destination available',
                  message:
                      'Create or activate another location before moving this rabbit.',
                  actionLabel: 'Add location',
                  actionIcon: Icons.add,
                  onAction: () => context.push('/locations/new'),
                );
              }

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _MoveContextCard(rabbit: item),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _locationId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'New location',
                        border: OutlineInputBorder(),
                      ),
                      items: destinations.map(_locationItem).toList(),
                      onChanged: (value) => setState(() => _locationId = value),
                      validator: (value) =>
                          value == null ? 'Select a destination' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _reasonController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _notesController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _isSaving || _locationId == null
                          ? null
                          : _save,
                      child: _isSaving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save movement'),
                    ),
                  ],
                ),
              );
            },
            error: (error, stackTrace) => AppState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load locations',
              message: 'Check that the API server is running, then try again.',
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(locationListProvider),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => AppState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load rabbit',
            message: 'Check that the API server is running, then try again.',
            actionLabel: 'Retry',
            onAction: () =>
                ref.invalidate(rabbitDetailProvider(widget.rabbitId)),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  DropdownMenuItem<String> _locationItem(FarmLocationSummary location) {
    return DropdownMenuItem(
      value: location.id,
      child: Text(
        '${location.name}${location.code == null ? '' : ' - ${location.code}'}',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MoveContextCard extends StatelessWidget {
  const _MoveContextCard({required this.rabbit});

  final RabbitDetail rabbit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RabbiTrackColors.mintGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.swap_horiz, color: RabbiTrackColors.forestGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rabbitMoveTitle(rabbit),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rabbitCurrentLocationText(rabbit),
                  style: const TextStyle(
                    color: RabbiTrackColors.forestGreen,
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
