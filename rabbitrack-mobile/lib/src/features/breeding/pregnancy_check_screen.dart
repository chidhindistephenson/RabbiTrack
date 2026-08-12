import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';

import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../rabbits/rabbit_controller.dart';
import 'breeding_options.dart';
import 'mating_controller.dart';
import 'mating_repository.dart';

class PregnancyCheckScreen extends ConsumerStatefulWidget {
  const PregnancyCheckScreen({
    super.key,
    required this.matingId,
    this.isRevision = false,
  });

  final String matingId;
  final bool isRevision;

  @override
  ConsumerState<PregnancyCheckScreen> createState() =>
      _PregnancyCheckScreenState();
}

class _PregnancyCheckScreenState extends ConsumerState<PregnancyCheckScreen> {
  final _notesController = TextEditingController();
  String _result = 'pregnant';
  String? _initializedMatingId;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isRevision) {
        await ref
            .read(matingRepositoryProvider)
            .revisePregnancyDecision(
              farmId: farm.id,
              matingId: widget.matingId,
              result: _result,
              notes: _optionalText(_notesController),
            );
      } else {
        await ref
            .read(matingRepositoryProvider)
            .recordPregnancyCheck(
              farmId: farm.id,
              matingId: widget.matingId,
              result: _result,
              notes: _optionalText(_notesController),
            );
      }

      ref.invalidate(matingListProvider);
      ref.invalidate(matingDetailProvider(widget.matingId));
      ref.invalidate(rabbitListProvider);

      if (mounted) {
        showSuccessSnackBar(
          context,
          widget.isRevision
              ? 'Pregnancy decision updated.'
              : 'Pregnancy check saved.',
        );
        popOrGo(context, '/breeding');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save pregnancy check. Try again.'),
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
    final matings = ref.watch(matingListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: '/breeding/${widget.matingId}',
        ),
        title: Text(widget.isRevision ? 'Revise decision' : 'Pregnancy check'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: matings.when(
        data: (items) {
          final mating = items
              .where((item) => item.id == widget.matingId)
              .firstOrNull;

          if (mating == null) {
            return AppState(
              icon: Icons.search_off,
              title: 'Mating record not found',
              message: 'Go back to breeding records and choose a mating again.',
              actionLabel: 'Back to breeding',
              onAction: () => popOrGo(context, '/breeding'),
            );
          }

          if (_initializedMatingId != mating.id) {
            _initializedMatingId = mating.id;
            if (canRevisePregnancyDecision(mating.status)) {
              _result = mating.status;
            }
          }

          if (widget.isRevision && !canRevisePregnancyDecision(mating.status)) {
            return AppState(
              icon: Icons.edit_off_outlined,
              title: 'No decision to revise',
              message:
                  'Record a pregnancy check before editing the pregnancy decision.',
              actionLabel: 'Back to breeding',
              onAction: () => popOrGo(context, '/breeding'),
            );
          }

          if (!widget.isRevision && !canRecordPregnancyCheck(mating.status)) {
            return AppState(
              icon: Icons.fact_check_outlined,
              title: 'Pregnancy check already recorded',
              message:
                  'This mating is ${breedingStatusLabel(mating.status).toLowerCase()}, so another pregnancy check is not needed.',
              actionLabel: 'Back to breeding',
              onAction: () => popOrGo(context, '/breeding'),
            );
          }

          if (!widget.isRevision &&
              !isPregnancyCheckDue(
                status: mating.status,
                dueOn: mating.pregnancyCheckDueOn,
              )) {
            return AppState(
              icon: Icons.event_busy_outlined,
              title: 'Pregnancy check not due yet',
              message:
                  'This mating can be checked on ${mating.pregnancyCheckDueOn}.',
              actionLabel: 'Back to breeding',
              onAction: () => popOrGo(context, '/breeding'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                mating.doeIdentifier,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: RabbiTrackColors.forestGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text('Mated with ${mating.buckIdentifier}'),
              const SizedBox(height: 22),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'pregnant', label: Text('Pregnant')),
                  ButtonSegment(
                    value: 'not_pregnant',
                    label: Text('Not pregnant'),
                  ),
                  ButtonSegment(value: 'uncertain', label: Text('Uncertain')),
                  ButtonSegment(
                    value: 'not_checked',
                    label: Text('Not checked'),
                  ),
                ],
                selected: {_result},
                onSelectionChanged: (value) {
                  setState(() => _result = value.single);
                },
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
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isRevision ? 'Save decision' : 'Save result'),
              ),
            ],
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load mating record',
          message: 'Check that the API server is running, then try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(matingListProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
