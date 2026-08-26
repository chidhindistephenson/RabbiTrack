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
import 'litter_models.dart';
import 'litter_repository.dart';

class LitterFosterScreen extends ConsumerStatefulWidget {
  const LitterFosterScreen({required this.litterId, super.key});

  final String litterId;

  @override
  ConsumerState<LitterFosterScreen> createState() => _LitterFosterScreenState();
}

class _LitterFosterScreenState extends ConsumerState<LitterFosterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  String? _toLitterId;
  bool _isSaving = false;

  @override
  void dispose() {
    _countController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save(LitterDetail source) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        _toLitterId == null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(litterRepositoryProvider)
          .recordFoster(
            farmId: farm.id,
            fromLitterId: widget.litterId,
            toLitterId: _toLitterId!,
            kitCount: int.tryParse(_countController.text) ?? 1,
            reason: _emptyToNull(_reasonController.text),
            notes: _emptyToNull(_notesController.text),
          );

      ref.invalidate(litterListProvider);
      ref.invalidate(litterDetailProvider(widget.litterId));
      ref.invalidate(litterDetailProvider(_toLitterId!));

      if (mounted) {
        showSuccessSnackBar(context, 'Fostering record saved.');
        popOrGo(context, '/litters/${widget.litterId}');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(error, 'Could not save fostering record. Try again.'),
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
    final source = ref.watch(litterDetailProvider(widget.litterId));
    final litters = ref.watch(litterListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: '/litters/${widget.litterId}',
        ),
        title: const Text('Record foster'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: source.when(
        data: (item) => litters.when(
          data: (allLitters) => _FormBody(
            source: item,
            candidates: allLitters
                .where(
                  (litter) =>
                      litter.id != item.id &&
                      [
                        'newborn',
                        'nursing',
                        'partially_weaned',
                      ].contains(litter.status),
                )
                .toList(),
            formKey: _formKey,
            countController: _countController,
            reasonController: _reasonController,
            notesController: _notesController,
            toLitterId: _toLitterId,
            onLitterChanged: (value) => setState(() => _toLitterId = value),
            isSaving: _isSaving,
            onSave: () => _save(item),
          ),
          error: (error, stackTrace) => AppState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load litters',
            message: 'Try again. Offline demo data should remain available.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(litterListProvider),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load source litter',
          message: 'Try again. Offline demo data should remain available.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(litterDetailProvider(widget.litterId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.source,
    required this.candidates,
    required this.formKey,
    required this.countController,
    required this.reasonController,
    required this.notesController,
    required this.toLitterId,
    required this.onLitterChanged,
    required this.isSaving,
    required this.onSave,
  });

  final LitterDetail source;
  final List<LitterSummary> candidates;
  final GlobalKey<FormState> formKey;
  final TextEditingController countController;
  final TextEditingController reasonController;
  final TextEditingController notesController;
  final String? toLitterId;
  final ValueChanged<String?> onLitterChanged;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            source.identifier,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: RabbiTrackColors.forestGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${source.doeIdentifier} | ${source.currentLiveCount} live kits',
          ),
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            initialValue: toLitterId,
            decoration: const InputDecoration(
              labelText: 'Receiving litter',
              border: OutlineInputBorder(),
            ),
            items: candidates
                .map(
                  (litter) => DropdownMenuItem(
                    value: litter.id,
                    child: Text(
                      '${litter.identifier} | ${litter.currentLiveCount} live',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: candidates.isEmpty ? null : onLitterChanged,
            validator: (value) =>
                value == null ? 'Choose a receiving litter' : null,
          ),
          if (candidates.isEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'No other active litter is available to receive kits.',
              style: TextStyle(
                color: Color(0xFF6A746D),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextFormField(
            controller: countController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Kits to foster',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final count = int.tryParse(value?.trim() ?? '');
              if (count == null || count < 1) {
                return 'Enter at least 1 kit';
              }
              if (count > source.currentLiveCount) {
                return 'Cannot exceed current live kits';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: notesController,
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
            onPressed: isSaving || candidates.isEmpty ? null : onSave,
            child: isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save foster'),
          ),
        ],
      ),
    );
  }
}
