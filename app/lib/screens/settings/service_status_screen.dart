import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/health_status.dart';
import '../../providers/health_provider.dart';

const _serviceMetadata = <String, _ServiceMeta>{
  'api': _ServiceMeta(
    icon: Icons.dns,
    label: 'API Server',
    subtitle: 'Core API',
  ),
  'postgresql': _ServiceMeta(
    icon: Icons.storage,
    label: 'PostgreSQL',
    subtitle: 'Relational Database',
  ),
  'dynamodb': _ServiceMeta(
    icon: Icons.table_chart,
    label: 'DynamoDB',
    subtitle: 'Document Store',
  ),
  'ai': _ServiceMeta(
    icon: Icons.auto_awesome,
    label: 'AI Service',
    subtitle: 'Ollama / Bedrock',
  ),
};

class _ServiceMeta {
  final IconData icon;
  final String label;
  final String subtitle;

  const _ServiceMeta({
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}

class ServiceStatusScreen extends ConsumerStatefulWidget {
  const ServiceStatusScreen({super.key});

  @override
  ConsumerState<ServiceStatusScreen> createState() =>
      _ServiceStatusScreenState();
}

class _ServiceStatusScreenState extends ConsumerState<ServiceStatusScreen> {
  Timer? _countdownTimer;
  int _secondsSinceCheck = 0;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsSinceCheck++);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(healthStatusProvider);
    final theme = Theme.of(context);

    ref.listen<HealthState>(healthStatusProvider, (prev, next) {
      if (prev?.lastChecked != next.lastChecked) {
        setState(() => _secondsSinceCheck = 0);
      }
    });

    if (state.error != null && state.status == null) {
      return _buildErrorScaffold(context, theme, state.error!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Status'),
        actions: [
          IconButton(
            icon: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : () => ref.read(healthStatusProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(healthStatusProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _OverallStatusBanner(
              state: state,
              secondsAgo: _secondsSinceCheck,
            ),
            const SizedBox(height: 16),
            if (state.status != null)
              ...state.status!.checks.map(
                (check) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ServiceCard(check: check),
                ),
              ),
            if (state.status != null && state.status!.checks.isEmpty)
              ..._buildPlaceholderCards(),
            if (state.checkHistory.isNotEmpty) ...[
              const SizedBox(height: 8),
              _UptimeHistory(history: state.checkHistory),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlaceholderCards() {
    return _serviceMetadata.entries
        .map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ServiceCard(
              check: HealthCheck(
                name: e.key,
                status: 'Unknown',
                duration: '-',
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildErrorScaffold(
    BuildContext context,
    ThemeData theme,
    String error,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Status')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Cannot reach server',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Check your internet connection',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    ref.read(healthStatusProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overall Status Banner
// ---------------------------------------------------------------------------

class _OverallStatusBanner extends StatelessWidget {
  final HealthState state;
  final int secondsAgo;

  const _OverallStatusBanner({
    required this.state,
    required this.secondsAgo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    final statusColor = _statusColorForOverall(state.status?.status, colors);
    final label = state.overallLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (state.lastChecked != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Last checked: ${_formatSecondsAgo(secondsAgo)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (state.isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  String _formatSecondsAgo(int seconds) {
    if (seconds < 60) return '$seconds second${seconds == 1 ? '' : 's'} ago';
    final minutes = seconds ~/ 60;
    return '$minutes minute${minutes == 1 ? '' : 's'} ago';
  }
}

// ---------------------------------------------------------------------------
// Service Card
// ---------------------------------------------------------------------------

class _ServiceCard extends StatelessWidget {
  final HealthCheck check;

  const _ServiceCard({required this.check});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final meta = _serviceMetadata[check.name.toLowerCase()] ??
        _ServiceMeta(
          icon: Icons.miscellaneous_services,
          label: check.name,
          subtitle: '',
        );

    final statusColor = _statusColorForCheck(check.status, colors);
    final isUnhealthy = check.status == 'Unhealthy';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.15),
            foregroundColor: statusColor,
            child: Icon(meta.icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meta.label, style: theme.textTheme.titleMedium),
                if (meta.subtitle.isNotEmpty)
                  Text(
                    meta.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  'Response: ${_formatDuration(check.duration)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            isUnhealthy ? Icons.arrow_downward : Icons.arrow_upward,
            size: 16,
            color: statusColor,
          ),
        ],
      ),
    );
  }

  String _formatDuration(String duration) {
    final match = RegExp(r'([\d.]+)').firstMatch(duration);
    if (match == null) return duration;
    final value = double.tryParse(match.group(1)!);
    if (value == null) return duration;

    if (duration.contains('ms')) return '${value.toStringAsFixed(0)}ms';
    if (duration.contains('s')) return '${(value * 1000).toStringAsFixed(0)}ms';
    return duration;
  }
}

// ---------------------------------------------------------------------------
// Uptime History (status dots)
// ---------------------------------------------------------------------------

class _UptimeHistory extends StatelessWidget {
  final List<bool> history;

  const _UptimeHistory({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Uptime', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: history
                .map(
                  (ok) => Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: ok ? colors.income : colors.expense,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          Text(
            '${history.where((ok) => ok).length}/${history.length} checks healthy',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Color _statusColorForOverall(String? status, AppColors colors) {
  switch (status) {
    case 'Healthy':
      return colors.income;
    case 'Degraded':
      return colors.budgetCaution;
    default:
      return colors.expense;
  }
}

Color _statusColorForCheck(String status, AppColors colors) {
  switch (status) {
    case 'Healthy':
      return colors.income;
    case 'Degraded':
      return colors.budgetCaution;
    case 'Unhealthy':
      return colors.expense;
    default:
      return const Color(0xFF9E9E9E);
  }
}
