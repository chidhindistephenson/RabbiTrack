import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/app_state.dart';
import '../../shared/money_format.dart';
import '../../shared/offline_action_queue.dart';
import '../../shared/offline_demo_data.dart';
import '../../shared/snackbars.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_models.dart';
import '../team/team_options.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final selectedFarm = session?.selectedFarm;

    if (session == null) {
      return const Scaffold(
        body: AppState(
          icon: Icons.lock_outline,
          title: 'Please sign in',
          message: 'Your account details will appear after you sign in.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: RabbiTrackColors.cream,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.go('/more'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('My account'),
        centerTitle: true,
        backgroundColor: RabbiTrackColors.cream,
        foregroundColor: RabbiTrackColors.forestGreen,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Farm settings',
            onPressed: () => context.push('/farms/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
        children: [
          _ProfileHeader(session: session),
          const SizedBox(height: 16),
          _AccountSection(
            title: 'Personal info',
            children: [
              _AccountRow(
                icon: Icons.person_outline,
                title: 'Your name',
                subtitle: session.userName,
              ),
              _AccountRow(
                icon: Icons.mail_outline,
                title: 'Email address',
                subtitle: session.email,
              ),
              _AccountRow(
                icon: Icons.alternate_email,
                title: 'Username',
                subtitle: session.username ?? 'Not set',
              ),
              _AccountRow(
                icon: Icons.phone_outlined,
                title: 'Phone number',
                subtitle: session.phone ?? 'Not set',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AccountSection(
            title: 'Farm access',
            children: [
              for (final farm in session.farms)
                _FarmAccessRow(
                  farm: farm,
                  isSelected: session.selectedFarm?.id == farm.id,
                ),
              _AccountRow(
                icon: Icons.swap_horiz,
                title: 'Switch farm',
                subtitle: 'Change the active rabbitry',
                onTap: () => context.push('/farms'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AccountSection(
            title: 'Settings',
            children: [
              _AccountRow(
                icon: Icons.home_work_outlined,
                title: 'Farm settings',
                subtitle: session.selectedFarm?.name ?? 'No farm selected',
                onTap: () => context.push('/farms/settings'),
              ),
              _AccountRow(
                icon: Icons.groups_outlined,
                title: 'Team access',
                subtitle: 'Manage farm members',
                onTap: () => context.push('/team'),
              ),
              _AccountRow(
                icon: Icons.cloud_done_outlined,
                title: 'API status',
                subtitle: 'Check backend connection',
                onTap: () => context.push('/api-status'),
              ),
              if (isOfflineDemoSession(session) && selectedFarm != null)
                _AccountRow(
                  icon: Icons.restart_alt,
                  title: 'Reset offline records',
                  subtitle: 'Clear local changes for ${selectedFarm.name}',
                  onTap: () =>
                      _confirmResetOfflineRecords(context, ref, selectedFarm),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _AccountSection(
            children: [
              _AccountRow(
                icon: Icons.logout,
                title: 'Sign out',
                subtitle: 'End this device session',
                iconColor: const Color(0xFFB4493B),
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetOfflineRecords(
    BuildContext context,
    WidgetRef ref,
    FarmSummary farm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset offline records?'),
        content: Text(
          'This clears local changes saved on ${farm.name}. Demo starter records will remain available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(offlineActionQueueProvider).clearForFarm(farm.id);

    if (!context.mounted) {
      return;
    }

    showSuccessSnackBar(context, 'Offline records reset.');
    context.go('/home');
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final selectedFarm = session.selectedFarm;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: RabbiTrackColors.warmTan,
                child: Text(
                  session.userName.isEmpty
                      ? '?'
                      : session.userName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: RabbiTrackColors.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: RabbiTrackColors.forestGreen),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: RabbiTrackColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            session.userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: RabbiTrackColors.cream,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            selectedFarm == null
                ? 'No farm selected'
                : '${selectedFarm.name} | ${farmRoleLabel(selectedFarm.role)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: RabbiTrackColors.mintGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            const SizedBox(height: 16),
            Text(
              title!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: RabbiTrackColors.forestGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
          ],
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(height: 1, indent: 62),
          ],
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = RabbiTrackColors.forestGreen,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: onTap == null
          ? null
          : const Icon(
              Icons.chevron_right,
              color: RabbiTrackColors.forestGreen,
            ),
      onTap: onTap,
    );
  }
}

class _FarmAccessRow extends StatelessWidget {
  const _FarmAccessRow({required this.farm, required this.isSelected});

  final FarmSummary farm;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.home_work_outlined,
        color: RabbiTrackColors.forestGreen,
      ),
      title: Text(
        farm.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${farm.code} | ${farmRoleLabel(farm.role)} | ${currencySymbol(farm.currency)} | ${farm.timezone}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isSelected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: RabbiTrackColors.mintGreen,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: RabbiTrackColors.forestGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : null,
    );
  }
}
