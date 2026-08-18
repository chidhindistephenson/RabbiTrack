import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'litter_controller.dart';
import 'litter_repository.dart';

class LitterCheckScreen extends ConsumerStatefulWidget {
  const LitterCheckScreen({required this.litterId, super.key});

  final String litterId;

  @override
  ConsumerState<LitterCheckScreen> createState() => _LitterCheckScreenState();
}

class _LitterCheckScreenState extends ConsumerState<LitterCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _liveController = TextEditingController();
  final _deadController = TextEditingController(text: '0');
  final _weakController = TextEditingController(text: '0');
  final _causeController = TextEditingController();
  final _nestController = TextEditingController();
  final _actionController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _liveController.dispose();
    _deadController.dispose();
    _weakController.dispose();
    _causeController.dispose();
    _nestController.dispose();
    _actionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save(int currentLiveCount) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (_formKey.currentState?.validate() != true || farm == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(litterRepositoryProvider)
          .recordCheck(
            farmId: farm.id,
            litterId: widget.litterId,
            liveCount: int.tryParse(_liveController.text) ?? 0,
            deadCount: int.tryParse(_deadController.text) ?? 0,
            weakCount: int.tryParse(_weakController.text) ?? 0,
            suspectedCause: _emptyToNull(_causeController.text),
            nestObservation: _emptyToNull(_nestController.text),
            correctiveAction: _emptyToNull(_actionController.text),
            notes: _emptyToNull(_notesController.text),
          );

      ref.invalidate(litterListProvider);
      ref.invalidate(litterDetailProvider(widget.litterId));

      if (mounted) {
        showSuccessSnackBar(context, 'Litter check recorded.');
        popOrGo(context, '/litters/${widget.litterId}');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save litter check. Try again.'),
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
    final litter = ref.watch(litterDetailProvider(widget.litterId));

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: '/litters/${widget.litterId}',
        ),
        title: const Text('Record litter check'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: litter.when(
        data: (item) {
          if (_liveController.text.isEmpty) {
            _liveController.text = item.currentLiveCount.toString();
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  item.identifier,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: RabbiTrackColors.forestGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text('${item.doeIdentifier} | ${item.currentLiveCount} live'),
                const SizedBox(height: 22),
                _NumberField(
                  controller: _liveController,
                  label: 'Live kits now',
                  validator: (value) =>
                      _countValidator(value, item.currentLiveCount),
                ),
                const SizedBox(height: 14),
                _NumberField(
                  controller: _deadController,
                  label: 'Deaths since last check',
                  validator: (value) =>
                      _countValidator(value, item.currentLiveCount),
                ),
                const SizedBox(height: 14),
                _NumberField(
                  controller: _weakController,
                  label: 'Weak kits',
                  validator: (value) {
                    final weak = int.tryParse(value?.trim() ?? '');
                    final live = int.tryParse(_liveController.text) ?? 0;
                    if (weak == null) {
                      return 'Enter a count';
                    }
                    if (weak < 0) {
                      return 'Count cannot be negative';
                    }
                    if (weak > live) {
                      return 'Cannot exceed live kits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _causeController,
                  decoration: const InputDecoration(
                    labelText: 'Suspected cause',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nestController,
                  decoration: const InputDecoration(
                    labelText: 'Nest observation',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _actionController,
                  decoration: const InputDecoration(
                    labelText: 'Corrective action',
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
                  onPressed: _isSaving
                      ? null
                      : () => _save(item.currentLiveCount),
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save check'),
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
          onAction: () => ref.invalidate(litterDetailProvider(widget.litterId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String? _countValidator(String? value, int currentLiveCount) {
    final count = int.tryParse(value?.trim() ?? '');
    if (count == null) {
      return 'Enter a count';
    }
    if (count < 0) {
      return 'Count cannot be negative';
    }
    if (count > currentLiveCount) {
      return 'Cannot exceed current live count';
    }

    return null;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

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
