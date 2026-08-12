import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../routing/navigation_helpers.dart';
import '../../shared/app_state.dart';
import '../../shared/soft_list_tile.dart';
import '../../theme/rabbitrack_colors.dart';
import '../auth/auth_controller.dart';
import 'api_health_controller.dart';
import 'api_health_models.dart';
import 'api_status_options.dart';

class ApiStatusScreen extends ConsumerWidget {
  const ApiStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(apiHealthProvider);
    final isSignedIn = ref.watch(authControllerProvider).valueOrNull != null;
    final fallbackLocation = isSignedIn ? '/more' : '/login';

    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(fallbackLocation: fallbackLocation),
        title: const Text('API status'),
        backgroundColor: RabbiTrackColors.forestGreen,
        foregroundColor: RabbiTrackColors.cream,
      ),
      body: health.when(
        data: (status) => RefreshIndicator(
          onRefresh: () => ref.refresh(apiHealthProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              _StatusHeader(status: status),
              const SizedBox(height: 12),
              const _BaseUrlCard(),
              const SizedBox(height: 12),
              for (final entry in status.checks.entries) ...[
                SoftListTile(
                  icon: entry.value
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  iconColor: entry.value
                      ? RabbiTrackColors.forestGreen
                      : Colors.redAccent,
                  iconBackground: entry.value
                      ? RabbiTrackColors.mintGreen
                      : Colors.redAccent.withValues(alpha: 0.18),
                  title: apiCheckLabel(entry.key),
                  subtitle: entry.value ? 'Ready' : 'Needs attention',
                  trailing: Icon(
                    entry.value ? Icons.done : Icons.close,
                    color: entry.value
                        ? RabbiTrackColors.forestGreen
                        : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        error: (error, stackTrace) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              AppState(
                icon: Icons.cloud_off_outlined,
                title: 'Cannot reach API',
                message:
                    'Start RabbiTrack services and confirm this device can reach ${ApiConfig.baseUrl}.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(apiHealthProvider),
                minHeight: 260,
              ),
              const SizedBox(height: 12),
              const _BaseUrlCard(),
              const SizedBox(height: 12),
              const _TroubleshootingCard(),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.status});

  final ApiHealthStatus status;

  @override
  Widget build(BuildContext context) {
    final isHealthy = status.isHealthy;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHealthy ? RabbiTrackColors.forestGreen : Colors.redAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: RabbiTrackColors.cream,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'API ready' : 'API degraded',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: RabbiTrackColors.cream,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${status.app} responded with ${status.status}',
                  style: const TextStyle(color: RabbiTrackColors.cream),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BaseUrlCard extends StatelessWidget {
  const _BaseUrlCard();

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      icon: Icons.link,
      title: 'API base URL',
      subtitle: '${apiBaseUrlMode(ApiConfig.baseUrl)} | ${ApiConfig.baseUrl}',
      trailing: const Icon(Icons.info_outline),
    );
  }
}

class _TroubleshootingCard extends StatelessWidget {
  const _TroubleshootingCard();

  @override
  Widget build(BuildContext context) {
    final steps = apiTroubleshootingSteps(ApiConfig.baseUrl);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E2D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.wifi_tethering_outlined,
                color: RabbiTrackColors.forestGreen,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Wireless checklist',
                  style: TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final step in steps) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '- ',
                  style: TextStyle(
                    color: RabbiTrackColors.forestGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Expanded(
                  child: Text(
                    step,
                    style: const TextStyle(color: Color(0xFF61706A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
