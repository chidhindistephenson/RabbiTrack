import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/soft_list_tile.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'team_controller.dart';
import 'team_models.dart';
import 'team_options.dart';
import 'team_repository.dart';

class TeamListScreen extends ConsumerWidget {
  const TeamListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(teamListProvider);
    final selectedFarm = ref
        .watch(authControllerProvider)
        .valueOrNull
        ?.selectedFarm;
    final isOwner = selectedFarm?.role == 'owner';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/team/new'),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Member'),
            )
          : null,
      body: members.when(
        data: (items) {
          if (items.isEmpty) {
            return AppState(
              icon: Icons.groups_outlined,
              title: 'No team members found',
              message: isOwner
                  ? 'Invite workers, managers, veterinarians, or viewers to help manage this farm.'
                  : 'Team members will appear here when the farm owner adds them.',
              actionLabel: isOwner ? 'Add member' : null,
              actionIcon: Icons.person_add_alt_1,
              onAction: isOwner ? () => context.push('/team/new') : null,
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(teamListProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
              itemBuilder: (context, index) => _TeamTile(
                member: items[index],
                canManage:
                    isOwner &&
                    (items[index].isPending || items[index].role != 'owner'),
                onChangeRole: () => _changeRole(context, ref, items[index]),
                onRemove: () => _removeMember(context, ref, items[index]),
                onResendInvite: () =>
                    _resendInvitation(context, ref, items[index]),
                onCancelInvite: () =>
                    _cancelInvitation(context, ref, items[index]),
              ),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemCount: items.length,
            ),
          );
        },
        error: (error, stackTrace) => AppState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load team',
          message: 'Check the API server and try again.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(teamListProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    FarmMemberSummary member,
  ) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    final role = await showDialog<String>(
      context: context,
      builder: (context) => _RoleDialog(initialRole: member.role),
    );

    if (role == null) {
      return;
    }

    try {
      await ref
          .read(teamRepositoryProvider)
          .updateRole(farmId: farm.id, memberId: member.id, role: role);
      ref.invalidate(teamListProvider);
      if (context.mounted) {
        showSuccessSnackBar(context, 'Member role updated.');
      }
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Could not update member role.');
      }
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    FarmMemberSummary member,
  ) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('${member.name} will lose access to this farm.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(teamRepositoryProvider)
          .remove(farmId: farm.id, memberId: member.id);
      ref.invalidate(teamListProvider);
      if (context.mounted) {
        showSuccessSnackBar(context, 'Member removed.');
      }
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Could not remove member.');
      }
    }
  }

  Future<void> _resendInvitation(
    BuildContext context,
    WidgetRef ref,
    FarmMemberSummary member,
  ) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    try {
      await ref
          .read(teamRepositoryProvider)
          .resendInvitation(farmId: farm.id, invitationId: member.id);
      if (context.mounted) {
        showSuccessSnackBar(context, 'Invitation resent.');
      }
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Could not resend invitation.');
      }
    }
  }

  Future<void> _cancelInvitation(
    BuildContext context,
    WidgetRef ref,
    FarmMemberSummary member,
  ) async {
    final farm = ref.read(authControllerProvider).valueOrNull?.selectedFarm;
    if (farm == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel invitation?'),
        content: Text(
          '${member.email} will no longer be able to join from this invite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep invite'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel invite'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(teamRepositoryProvider)
          .cancelInvitation(farmId: farm.id, invitationId: member.id);
      ref.invalidate(teamListProvider);
      if (context.mounted) {
        showSuccessSnackBar(context, 'Invitation cancelled.');
      }
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Could not cancel invitation.');
      }
    }
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.member,
    required this.canManage,
    required this.onChangeRole,
    required this.onRemove,
    required this.onResendInvite,
    required this.onCancelInvite,
  });

  final FarmMemberSummary member;
  final bool canManage;
  final VoidCallback onChangeRole;
  final VoidCallback onRemove;
  final VoidCallback onResendInvite;
  final VoidCallback onCancelInvite;

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      icon: Icons.account_circle_outlined,
      title: member.name,
      subtitle: member.isPending
          ? '${member.email} | Pending invite'
          : member.email,
      trailing: canManage
          ? PopupMenuButton<_TeamAction>(
              onSelected: (action) {
                switch (action) {
                  case _TeamAction.changeRole:
                    onChangeRole();
                  case _TeamAction.remove:
                    onRemove();
                  case _TeamAction.resendInvite:
                    onResendInvite();
                  case _TeamAction.cancelInvite:
                    onCancelInvite();
                }
              },
              itemBuilder: (context) => member.isPending
                  ? const [
                      PopupMenuItem(
                        value: _TeamAction.resendInvite,
                        child: Text('Resend invite'),
                      ),
                      PopupMenuItem(
                        value: _TeamAction.cancelInvite,
                        child: Text('Cancel invite'),
                      ),
                    ]
                  : const [
                      PopupMenuItem(
                        value: _TeamAction.changeRole,
                        child: Text('Change role'),
                      ),
                      PopupMenuItem(
                        value: _TeamAction.remove,
                        child: Text('Remove access'),
                      ),
                    ],
              child: _RoleText(role: member.role),
            )
          : _RoleText(role: member.role),
    );
  }
}

class _RoleText extends StatelessWidget {
  const _RoleText({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Text(
      farmRoleLabel(role),
      style: const TextStyle(
        color: RabbiTrackColors.forestGreen,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _RoleDialog extends StatefulWidget {
  const _RoleDialog({required this.initialRole});

  final String initialRole;

  @override
  State<_RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends State<_RoleDialog> {
  late String _role = widget.initialRole;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change role'),
      content: DropdownButtonFormField<String>(
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_role),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

enum _TeamAction { changeRole, remove, resendInvite, cancelInvite }
