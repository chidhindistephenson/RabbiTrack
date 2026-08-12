import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';

import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../rabbits/rabbit_controller.dart';
import 'litter_controller.dart';
import 'litter_repository.dart';

class WeaningCreateScreen extends ConsumerStatefulWidget {
  const WeaningCreateScreen({super.key, required this.litterId});

  final String litterId;

  @override
  ConsumerState<WeaningCreateScreen> createState() =>
      _WeaningCreateScreenState();
}

class _WeaningCreateScreenState extends ConsumerState<WeaningCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController(text: '0');
  final _weightController = TextEditingController();
  final _destinationController = TextEditingController(text: 'Grow-out cages');
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _countController.dispose();
    _weightController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (_formKey.currentState?.validate() != true || farm == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(litterRepositoryProvider)
          .recordWeaning(
            farmId: farm.id,
            litterId: widget.litterId,
            numberWeaned: int.tryParse(_countController.text) ?? 0,
            averageWeightValue: double.tryParse(_weightController.text),
            destination: _destinationController.text.trim().isEmpty
                ? null
                : _destinationController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      ref.invalidate(litterListProvider);
      ref.invalidate(litterDetailProvider(widget.litterId));
      ref.invalidate(rabbitListProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Weaning recorded.');
        popOrGo(context, '/litters');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save weaning. Try again.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final litters = ref.watch(litterListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: '/litters/${widget.litterId}',
        ),
        title: const Text('Record weaning'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: litters.when(
        data: (items) {
          final litter = items
              .where((item) => item.id == widget.litterId)
              .firstOrNull;

          if (litter == null) {
            return AppState(
              icon: Icons.search_off_outlined,
              title: 'Litter not found',
              message: 'Return to the litter list and choose a litter again.',
              actionLabel: 'Back to litters',
              onAction: () => popOrGo(context, '/litters'),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  litter.identifier,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: RabbiTrackColors.forestGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${litter.doeIdentifier} | ${litter.currentLiveCount} live',
                ),
                const SizedBox(height: 22),
                _NumberField(
                  controller: _countController,
                  label: 'Number weaned',
                  validator: (value) =>
                      _requiredCountValidator(value, litter.currentLiveCount),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Average weight kg',
                    border: OutlineInputBorder(),
                  ),
                  validator: _optionalWeightValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save weaning'),
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load litter',
          message: 'Check the API server and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(litterListProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String? _requiredCountValidator(String? value, int liveCount) {
    final count = int.tryParse(value?.trim() ?? '');
    if (count == null) {
      return 'Enter a count';
    }
    if (count <= 0) {
      return 'Number weaned must be greater than zero';
    }
    if (count > liveCount) {
      return 'Cannot exceed current live count';
    }

    return null;
  }

  String? _optionalWeightValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final weight = double.tryParse(trimmed);
    if (weight == null || weight <= 0) {
      return 'Average weight must be greater than zero';
    }

    return null;
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
