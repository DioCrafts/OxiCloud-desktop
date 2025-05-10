import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/presentation/providers/file_explorer_provider.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(fileExplorerProvider);
    final viewMode = ref.watch(viewModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OxiCloud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(fileExplorerProvider.notifier).loadFiles(),
          ),
          IconButton(
            icon: Icon(viewMode == ViewMode.list ? Icons.grid_view : Icons.list),
            onPressed: () => ref.read(viewModeProvider.notifier).state = 
              viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list,
          ),
        ],
      ),
      body: filesAsync.when(
        data: (files) => files.isEmpty
          ? const Center(child: Text('No hay archivos'))
          : viewMode == ViewMode.list
            ? ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return ListTile(
                    leading: Icon(file.isDirectory ? Icons.folder : Icons.insert_drive_file),
                    title: Text(file.name),
                    subtitle: Text(file.path),
                    onTap: () {
                      if (file.isDirectory) {
                        ref.read(fileExplorerProvider.notifier).navigateTo(file.path);
                      }
                    },
                  );
                },
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                ),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return GridTile(
                    child: InkWell(
                      onTap: () {
                        if (file.isDirectory) {
                          ref.read(fileExplorerProvider.notifier).navigateTo(file.path);
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(file.isDirectory ? Icons.folder : Icons.insert_drive_file, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            file.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementar subida de archivos
        },
        child: const Icon(Icons.upload),
      ),
    );
  }
} 