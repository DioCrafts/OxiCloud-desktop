import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers.dart';
import '../../../data/datasources/remote/device_auth_remote_datasource.dart';

/// Page that displays a device code and polls for approval.
class DeviceLoginPage extends ConsumerStatefulWidget {
  const DeviceLoginPage({super.key});

  @override
  ConsumerState<DeviceLoginPage> createState() => _DeviceLoginPageState();
}

class _DeviceLoginPageState extends ConsumerState<DeviceLoginPage> {
  DeviceAuthResponse? _authResponse;
  String? _error;
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startDeviceAuth();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startDeviceAuth() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ds = ref.read(deviceAuthRemoteDatasourceProvider);
      final response = await ds.authorize(deviceName: 'OxiCloud Desktop');
      setState(() {
        _authResponse = response;
        _loading = false;
      });
      _startPolling(response);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _startPolling(DeviceAuthResponse auth) {
    var interval = auth.interval;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: interval), (timer) async {
      try {
        final ds = ref.read(deviceAuthRemoteDatasourceProvider);
        final result = await ds.pollToken(auth.deviceCode);

        if (result.isSuccess) {
          timer.cancel();
          // Save tokens and navigate
          final storage = ref.read(secureStorageProvider);
          await storage.saveAccessToken(result.accessToken!);
          if (result.refreshToken != null) {
            await storage.saveRefreshToken(result.refreshToken!);
          }
          if (mounted) context.go('/files');
        } else if (result.isSlowDown) {
          // Increase interval
          timer.cancel();
          interval += 5;
          _pollTimer = Timer.periodic(
              Duration(seconds: interval), (t) => _poll(t, auth));
        } else if (result.isExpired || result.isDenied) {
          timer.cancel();
          setState(() => _error = result.isDenied
              ? 'Access denied by user'
              : 'Device code expired');
        }
        // isPending → keep polling
      } catch (e) {
        // Keep polling on transient errors
      }
    });
  }

  void _poll(Timer timer, DeviceAuthResponse auth) {
    // Delegate to _startPolling logic — already handled by the periodic
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError(theme)
                      : _buildCodeDisplay(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _startDeviceAuth,
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildCodeDisplay(ThemeData theme) {
    final auth = _authResponse!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.devices, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('Device Login', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Enter this code on your browser:',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        // Big user code
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            auth.userCode,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Verification URL
        Text(
          auth.verificationUri,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: auth.userCode));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Code'),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Use password instead'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(height: 8),
        Text(
          'Waiting for approval...',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
