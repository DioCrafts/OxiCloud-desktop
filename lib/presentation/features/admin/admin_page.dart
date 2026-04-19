import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers.dart';
import '../../../data/datasources/remote/admin_remote_datasource.dart';
import '../../shell/adaptive_shell.dart';

// --- State ---

class AdminState {
  final AdminDashboard? dashboard;
  final List<AdminUser> users;
  final bool loading;
  final String? error;
  final String tab; // 'dashboard', 'users', 'settings'

  const AdminState({
    this.dashboard,
    this.users = const [],
    this.loading = false,
    this.error,
    this.tab = 'dashboard',
  });

  AdminState copyWith({
    AdminDashboard? dashboard,
    List<AdminUser>? users,
    bool? loading,
    String? error,
    String? tab,
  }) {
    return AdminState(
      dashboard: dashboard ?? this.dashboard,
      users: users ?? this.users,
      loading: loading ?? this.loading,
      error: error,
      tab: tab ?? this.tab,
    );
  }
}

// --- Notifier ---

class AdminNotifier extends Notifier<AdminState> {
  @override
  AdminState build() => const AdminState();

  AdminRemoteDatasource get _ds => ref.read(adminRemoteDatasourceProvider);

  void setTab(String tab) => state = state.copyWith(tab: tab);

  Future<void> loadDashboard() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final dashboard = await _ds.getDashboard();
      state = state.copyWith(dashboard: dashboard, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> loadUsers() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final users = await _ds.getUsers();
      state = state.copyWith(users: users, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _ds.deleteUser(id);
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleUserActive(String id, bool active) async {
    try {
      await _ds.setUserActive(id, active);
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setUserRole(String id, String role) async {
    try {
      await _ds.setUserRole(id, role);
      await loadUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final adminProvider = NotifierProvider<AdminNotifier, AdminState>(
  AdminNotifier.new,
);

// --- UI ---

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(adminProvider.notifier).loadDashboard();
      ref.read(adminProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);

    return AdaptiveShell(
      currentPath: '/admin',
      title: 'Admin',
      child: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(text: 'Dashboard', icon: Icon(Icons.dashboard_outlined)),
              Tab(text: 'Users', icon: Icon(Icons.people_outline)),
            ],
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                state.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _DashboardTab(
                  dashboard: state.dashboard,
                  loading: state.loading,
                ),
                _UsersTab(
                  users: state.users,
                  loading: state.loading,
                  onDelete: (id) =>
                      ref.read(adminProvider.notifier).deleteUser(id),
                  onToggleActive: (id, active) => ref
                      .read(adminProvider.notifier)
                      .toggleUserActive(id, active),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final AdminDashboard? dashboard;
  final bool loading;

  const _DashboardTab({required this.dashboard, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading && dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final d = dashboard;
    if (d == null) return const Center(child: Text('No data'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _StatCard('Total Users', '${d.totalUsers}', Icons.people),
          _StatCard('Active Users', '${d.activeUsers}', Icons.person),
          _StatCard('Total Files', '${d.totalFiles}', Icons.insert_drive_file),
          _StatCard('Total Folders', '${d.totalFolders}', Icons.folder),
          _StatCard(
            'Storage',
            _formatBytes(d.totalStorageBytes),
            Icons.storage,
          ),
          _StatCard('Version', d.serverVersion, Icons.info_outline),
          _StatCard('Backend', d.storageBackend, Icons.dns_outlined),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard(this.title, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  final List<AdminUser> users;
  final bool loading;
  final ValueChanged<String> onDelete;
  final void Function(String id, bool active) onToggleActive;

  const _UsersTab({
    required this.users,
    required this.loading,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final u = users[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(u.username[0].toUpperCase())),
            title: Text(u.username),
            subtitle: Text('${u.role} • ${u.isActive ? 'Active' : 'Disabled'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: u.isActive,
                  onChanged: (v) => onToggleActive(u.id, v),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDelete(u.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
