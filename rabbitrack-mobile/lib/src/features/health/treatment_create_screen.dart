import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/snackbars.dart';

import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../rabbits/rabbit_controller.dart';
import 'health_controller.dart';
import 'health_repository.dart';

class TreatmentCreateScreen extends ConsumerStatefulWidget {
  const TreatmentCreateScreen({required this.healthEventId, super.key});

  final String healthEventId;

  @override
  ConsumerState<TreatmentCreateScreen> createState() =>
      _TreatmentCreateScreenState();
}

class _TreatmentCreateScreenState extends ConsumerState<TreatmentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _routeController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _withdrawalController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _medicationController.dispose();
    _dosageController.dispose();
    _routeController.dispose();
    _frequencyController.dispose();
    _withdrawalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    final medication = _medicationController.text.trim();
    final withdrawalDays = int.tryParse(_withdrawalController.text) ?? 0;

    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        medication.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(healthRepositoryProvider)
          .addTreatment(
            farmId: farm.id,
            healthEventId: widget.healthEventId,
            medication: medication,
            dosage: _optionalText(_dosageController),
            route: _optionalText(_routeController),
            frequency: _optionalText(_frequencyController),
            notes: _optionalText(_notesController),
            withdrawalDays: withdrawalDays,
          );

      ref.invalidate(healthEventListProvider);
      ref.invalidate(rabbitListProvider);

      if (mounted) {
        showSuccessSnackBar(context, 'Treatment saved.');
        popOrGo(context, '/health');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save treatment. Try again.'),
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
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/health'),
        title: const Text('Add treatment'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _medicationController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Medication',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter medication'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _dosageController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _routeController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Route',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _frequencyController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _withdrawalController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Withdrawal days',
                border: OutlineInputBorder(),
              ),
              validator: _withdrawalValidator,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
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
                  : const Text('Save treatment'),
            ),
          ],
        ),
      ),
    );
  }

  String? _withdrawalValidator(String? value) {
    final days = int.tryParse(value?.trim() ?? '');
    if (days == null) {
      return 'Enter withdrawal days';
    }
    if (days < 0) {
      return 'Withdrawal days cannot be negative';
    }

    return null;
  }
}
