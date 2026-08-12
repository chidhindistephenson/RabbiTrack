import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/money_format.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final selectedFarm = session?.selectedFarm;

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            if (selectedFarm != null) ...[
              _CurrentFarmCard(
                name: selectedFarm.name,
                code: selectedFarm.code,
                role: selectedFarm.role,
                currency: selectedFarm.currency,
                timezone: selectedFarm.timezone,
              ),
              const SizedBox(height: 12),
            ],
            _MoreTile(
              title: 'Account',
              subtitle: session?.email ?? 'Signed-in user details',
              icon: Icons.account_circle_outlined,
              onTap: () => context.push('/account'),
            ),
            _MoreTile(
              title: 'Recent activity',
              subtitle: 'Farm changes and team actions',
              icon: Icons.history,
              onTap: () => context.push('/activity'),
            ),
            _MoreTile(
              title: 'Tasks',
              subtitle: 'Daily work list and reminders',
              icon: Icons.task_alt,
              onTap: () => context.push('/tasks'),
            ),
            _MoreTile(
              title: 'Locations',
              subtitle: 'Houses, rows, cages, and capacity',
              icon: Icons.meeting_room_outlined,
              onTap: () => context.push('/locations'),
            ),
            _MoreTile(
              title: 'Litters',
              subtitle: 'Kindling, nursing, and weaning',
              icon: Icons.child_care,
              onTap: () => context.push('/litters'),
            ),
            _MoreTile(
              title: 'Weights',
              subtitle: 'Growth records and current weights',
              icon: Icons.monitor_weight,
              onTap: () => context.push('/weights'),
            ),
            _MoreTile(
              title: 'Sales',
              subtitle: 'Rabbit sales and buyer records',
              icon: Icons.sell_outlined,
              onTap: () => context.push('/sales'),
            ),
            _MoreTile(
              title: 'Expenses',
              subtitle: 'Feed, medicine, equipment, and running costs',
              icon: Icons.payments_outlined,
              onTap: () => context.push('/expenses'),
            ),
            _MoreTile(
              title: 'Finance report',
              subtitle: 'Monthly revenue, expenses, and net income',
              icon: Icons.bar_chart,
              onTap: () => context.push('/reports/finance'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentFarmCard extends StatelessWidget {
  const _CurrentFarmCard({
    required this.name,
    required this.code,
    required this.role,
    required this.currency,
    required this.timezone,
  });

  final String name;
  final String code;
  final String role;
  final String currency;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RabbiTrackColors.forestGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: RabbiTrackColors.warmTan,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: RabbiTrackColors.forestGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: RabbiTrackColors.cream,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$code | ${_farmRoleLabel(role)} | ${currencySymbol(currency)} | $timezone',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: RabbiTrackColors.mintGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _farmRoleLabel(String role) {
  return role
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftListTile(
        icon: icon,
        iconColor: RabbiTrackColors.forestGreen,
        iconBackground: RabbiTrackColors.mintGreen,
        title: title,
        subtitle: subtitle,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
