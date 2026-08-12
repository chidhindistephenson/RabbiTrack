import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../routing/navigation_helpers.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/app_state.dart';
import '../../shared/snackbars.dart';

import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'team_controller.dart';
import 'team_options.dart';
import 'team_repository.dart';

class TeamAddScreen extends ConsumerStatefulWidget {
  const TeamAddScreen({super.key});

  @override
  ConsumerState<TeamAddScreen> createState() => _TeamAddScreenState();
}

class _TeamAddScreenState extends ConsumerState<TeamAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _role = 'worker';
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    final email = _emailController.text.trim();

    if (_formKey.currentState?.validate() != true ||
        farm == null ||
        email.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final member = await ref
          .read(teamRepositoryProvider)
          .add(farmId: farm.id, email: email, role: _role);

      ref.invalidate(teamListProvider);

      if (mounted) {
        showSuccessSnackBar(
          context,
          member.isPending
              ? 'Invitation created. They can sign up with that email.'
              : 'Member added.',
        );
        popOrGo(context, '/team');
      }
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(
          context,
          apiErrorMessage(
            error,
            'Could not add member. Check the email and role.',
          ),
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
    final selectedFarm = ref
        .watch(authControllerProvider)
        .valueOrNull
        ?.selectedFarm;

    if (selectedFarm?.role != 'owner') {
      return const Scaffold(
        body: AppState(
          icon: Icons.lock_outline,
          title: 'Owner access required',
          message: 'Only farm owners can add or invite team members.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/team'),
        title: const Text('Invite member'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email address',
                border: OutlineInputBorder(),
              ),
              validator: _emailValidator,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: assignableFarmRoles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(farmRoleLabel(role)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _role = value!),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send invite'),
            ),
          ],
        ),
      ),
    );
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter an email address';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }
}
