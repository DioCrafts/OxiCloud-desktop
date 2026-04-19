import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers.dart';
import '../../../data/datasources/remote/app_password_remote_datasource.dart';
import '../../../data/datasources/remote/device_auth_remote_datasource.dart';
import '../../shell/adaptive_shell.dart';

// --- App Passwords State ---

class AppPasswordsState {
  final List<AppPasswordDto> passwords;
  final bool loading;
  final String? error;
  final AppPasswordCreateResult? justCreated;

  const AppPasswordsState({
    this.passwords = const [],
    this.loading = false,
    this.error,
    this.justCreated,
  });

  AppPasswordsState copyWith({
    List<AppPasswordDto>? passwords,
    bool? loading,
    String? error,
    AppPasswordCreateResult? justCreated,
  }) {
    return AppPasswordsState(
      passwords: passwords ?? this.passwords,
      loading: loading ?? this.loading,
      error: error,
      justCreated: justCreated,
    );
  }
}

class AppPasswordsNotifier extends Notifier<AppPasswordsState> {
  @override
  AppPasswordsState build() => const AppPasswordsState();

  AppPasswordRemoteDatasource get _ds =>
      ref.read(appPasswordRemoteDatasourceProvider);

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final list = await _ds.list();
      state = state.copyWith(passwords: list, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> create(String name) async {
    try {
      final result = await _ds.create(name);
      state = state.copyWith(justCreated: result);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> revoke(String id) async {
    try {
      await _ds.revoke(id);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearJustCreated() {
    state = state.copyWith();
  }
}

final appPasswordsProvider =
    NotifierProvider<AppPasswordsNotifier, AppPasswordsState>(
      AppPasswordsNotifier.new,
    );

// --- Devices State ---

class DevicesState {
  final List<DeviceInfo> devices;
  final bool loading;
  final String? error;

  const DevicesState({
    this.devices = const [],
    this.loading = false,
    this.error,
  });

  DevicesState copyWith({
    List<DeviceInfo>? devices,
    bool? loading,
    String? error,
  }) {
    return DevicesState(
      devices: devices ?? this.devices,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class DevicesNotifier extends Notifier<DevicesState> {
  @override
  DevicesState build() => const DevicesState();

  DeviceAuthRemoteDatasource get _ds =>
      ref.read(deviceAuthRemoteDatasourceProvider);

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final devices = await _ds.listDevices();
      state = state.copyWith(devices: devices, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> revoke(String id) async {
    try {
      await _ds.revokeDevice(id);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final devicesProvider = NotifierProvider<DevicesNotifier, DevicesState>(
  DevicesNotifier.new,
);

// --- UI ---

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(appPasswordsProvider.notifier).load();
      ref.read(devicesProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveShell(
      currentPath: '/settings',
      title: 'Settings',
      child: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(text: 'App Passwords', icon: Icon(Icons.key_outlined)),
              Tab(text: 'Devices', icon: Icon(Icons.devices_outlined)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [_AppPasswordsTab(), _DevicesTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// --- App Passwords Tab ---

class _AppPasswordsTab extends ConsumerWidget {
  const _AppPasswordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appPasswordsProvider);
    final theme = Theme.of(context);

    // Show just-created password in a dialog
    ref.listen<AppPasswordsState>(appPasswordsProvider, (prev, next) {
      if (next.justCreated != null && prev?.justCreated != next.justCreated) {
        _showCreatedDialog(context, next.justCreated!);
        ref.read(appPasswordsProvider.notifier).clearJustCreated();
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'App Passwords',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              state.error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        Expanded(
          child: state.loading && state.passwords.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.passwords.isEmpty
              ? const Center(child: Text('No app passwords'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.passwords.length,
                  itemBuilder: (context, i) {
                    final p = state.passwords[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.key),
                        title: Text(p.name),
                        subtitle: Text(
                          '${p.prefix}*** • Created ${p.createdAt}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Revoke',
                          onPressed: () => ref
                              .read(appPasswordsProvider.notifier)
                              .revoke(p.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New App Password'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result == true && ctrl.text.isNotEmpty) {
      ref.read(appPasswordsProvider.notifier).create(ctrl.text.trim());
    }
  }

  void _showCreatedDialog(
    BuildContext context,
    AppPasswordCreateResult result,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Password Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copy this password now. It will not be shown again.'),
            const SizedBox(height: 16),
            SelectableText(
              result.password,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result.password));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// --- Devices Tab ---

class _DevicesTab extends ConsumerWidget {
  const _DevicesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(devicesProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Authorized Devices',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => ref.read(devicesProvider.notifier).load(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              state.error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        Expanded(
          child: state.loading && state.devices.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.devices.isEmpty
              ? const Center(child: Text('No authorized devices'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.devices.length,
                  itemBuilder: (context, i) {
                    final d = state.devices[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(_platformIcon(d.platform)),
                        title: Text(d.name),
                        subtitle: Text(
                          [
                            if (d.platform != null) d.platform!,
                            'Added ${d.createdAt}',
                          ].join(' • '),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.link_off),
                          tooltip: 'Revoke',
                          onPressed: () =>
                              ref.read(devicesProvider.notifier).revoke(d.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _platformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.computer;
      case 'android':
        return Icons.phone_android;
      case 'ios':
        return Icons.phone_iphone;
      default:
        return Icons.devices;
    }
  }
}
