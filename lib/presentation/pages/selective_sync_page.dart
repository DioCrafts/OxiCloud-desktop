import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/entities/sync_folder.dart';
import '../blocs/sync/sync_bloc.dart';

class SelectiveSyncPage extends StatefulWidget {
  const SelectiveSyncPage({super.key});

  @override
  State<SelectiveSyncPage> createState() => _SelectiveSyncPageState();
}

class _SelectiveSyncPageState extends State<SelectiveSyncPage> {
  final Set<String> _selectedFolderIds = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    context.read<SyncBloc>().add(const LoadRemoteFolders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selective Sync'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveChanges,
              child: const Text('Save'),
            ),
        ],
      ),
      body: BlocConsumer<SyncBloc, SyncState>(
        listener: (context, state) {
          if (state is RemoteFoldersLoaded) {
            setState(() {
              _selectedFolderIds.clear();
              _selectedFolderIds.addAll(state.selectedFolderIds);
            });
          }
        },
        builder: (context, state) {
          if (state is SyncError) {
            return _buildErrorState(state.message);
          }

          if (state is RemoteFoldersLoaded) {
            return _buildFolderList(state.folders);
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<SyncBloc>().add(const LoadRemoteFolders());
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderList(List<SyncFolder> folders) {
    if (folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No folders found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select which folders to sync to this device. Unselected folders will be removed from local storage.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Select all / None buttons
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFolderIds.clear();
                    _selectedFolderIds.addAll(folders.map((f) => f.id));
                    _hasChanges = true;
                  });
                },
                child: const Text('Select All'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFolderIds.clear();
                    _hasChanges = true;
                  });
                },
                child: const Text('Select None'),
              ),
              const Spacer(),
              Text(
                '${_selectedFolderIds.length} selected',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Folder list
        Expanded(
          child: ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              final isSelected = _selectedFolderIds.contains(folder.id);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedFolderIds.add(folder.id);
                    } else {
                      _selectedFolderIds.remove(folder.id);
                    }
                    _hasChanges = true;
                  });
                },
                secondary: const Icon(Icons.folder),
                title: Text(folder.name),
                subtitle: Text(
                  '${_formatBytes(folder.sizeBytes)} • ${folder.itemCount} items',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              );
            },
          ),
        ),

        // Total size footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total selected size:'),
              Text(
                _formatBytes(_calculateSelectedSize(folders)),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _calculateSelectedSize(List<SyncFolder> folders) {
    return folders
        .where((f) => _selectedFolderIds.contains(f.id))
        .fold(0, (sum, f) => sum + f.sizeBytes);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _saveChanges() {
    context.read<SyncBloc>().add(UpdateSyncFolders(_selectedFolderIds.toList()));
    setState(() {
      _hasChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync folders updated')),
    );
    Navigator.of(context).pop();
  }
}
