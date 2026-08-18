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

class LitterConversionScreen extends ConsumerStatefulWidget {
  const LitterConversionScreen({required this.litterId, super.key});

  final String litterId;

  @override
  ConsumerState<LitterConversionScreen> createState() =>
      _LitterConversionScreenState();
}

class _LitterConversionScreenState
    extends ConsumerState<LitterConversionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
  final _breedController = TextEditingController();
  final _colourController = TextEditingController();
  final _notesController = TextEditingController();
  String _sex = 'unknown';
  bool _isSaving = false;

  @override
  void dispose() {
    _countController.dispose();
    _breedController.dispose();
    _colourController.dispose();
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
      final result = await ref
          .read(litterRepositoryProvider)
          .convertKits(
            farmId: farm.id,
            litterId: widget.litterId,
            count: int.tryParse(_countController.text) ?? 0,
            sex: _sex,
            breed: _emptyToNull(_breedController.text),
            colour: _emptyToNull(_colourController.text),
            notes: _emptyToNull(_notesController.text),
          );

      ref.invalidate(litterListProvider);
      ref.invalidate(litterDetailProvider(widget.litterId));
      ref.invalidate(rabbitListProvider);

      if (mounted) {
        showSuccessSnackBar(
          context,
          '${result.convertedCount} kit profiles created.',
        );
        popOrGo(context, '/litters/${widget.litterId}');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not identify kits. Try again.'),
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
        title: const Text('Identify kits'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: litter.when(
        data: (item) {
          if (item.unconvertedKitsCount <= 0) {
            return AppState(
              icon: Icons.check_circle_outline,
              title: 'All kits identified',
              message: 'This litter has no remaining kits to convert.',
              actionLabel: 'Back to litter',
              onAction: () => popOrGo(context, '/litters/${widget.litterId}'),
            );
          }

          if (_countController.text.isEmpty) {
            _countController.text = item.unconvertedKitsCount.toString();
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
                Text(
                  '${item.doeIdentifier} | ${item.unconvertedKitsCount} kits remaining',
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Number to identify',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _countValidator(value, item.unconvertedKitsCount),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _sex,
                  decoration: const InputDecoration(
                    labelText: 'Starting sex',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sex = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(
                    labelText: 'Breed',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _colourController,
                  decoration: const InputDecoration(
                    labelText: 'Colour',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
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
                      : const Text('Create rabbit profiles'),
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

  String? _countValidator(String? value, int remainingCount) {
    final count = int.tryParse(value?.trim() ?? '');
    if (count == null) {
      return 'Enter a count';
    }
    if (count <= 0) {
      return 'Count must be greater than zero';
    }
    if (count > remainingCount) {
      return 'Cannot exceed remaining kits';
    }

    return null;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
