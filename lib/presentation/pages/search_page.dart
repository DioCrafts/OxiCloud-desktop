import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/entities/file_item.dart';
import '../../core/entities/search_results.dart';
import '../blocs/search/search_bloc.dart';
import '../theme/oxicloud_colors.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _showAdvanced = false;

  // Advanced fields
  final _typeController = TextEditingController();
  int? _minSize;
  int? _maxSize;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _typeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty && !_showAdvanced) return;

    if (_showAdvanced) {
      final types = _typeController.text.trim();
      context.read<SearchBloc>().add(AdvancedSearchSubmitted(
            SearchCriteria(
              nameContains: query.isNotEmpty ? query : null,
              fileTypes: types.isNotEmpty
                  ? types.split(',').map((e) => e.trim()).toList()
                  : null,
              minSize: _minSize,
              maxSize: _maxSize,
            ),
          ));
    } else {
      context.read<SearchBloc>().add(SearchQuerySubmitted(query));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            icon: Icon(
              _showAdvanced ? Icons.tune_outlined : Icons.tune,
            ),
            tooltip: 'Advanced search',
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search files and folders…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              context
                                  .read<SearchBloc>()
                                  .add(const SearchCleared());
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
                if (_showAdvanced) ...[
                  const SizedBox(height: 12),
                  _buildAdvancedFields(),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Results
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is SearchLoaded) {
                  if (state.results.isEmpty) {
                    return _buildNoResults();
                  }
                  return _buildResults(context, state.results);
                }
                if (state is SearchError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(state.message),
                      ],
                    ),
                  );
                }
                // Initial state
                return _buildInitialHint();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Filters',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'File types',
                hintText: 'pdf, jpg, docx',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: 'Min size',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    value: _minSize,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Any')),
                      DropdownMenuItem(value: 1024, child: Text('1 KB')),
                      DropdownMenuItem(
                          value: 1048576, child: Text('1 MB')),
                      DropdownMenuItem(
                          value: 10485760, child: Text('10 MB')),
                      DropdownMenuItem(
                          value: 104857600, child: Text('100 MB')),
                    ],
                    onChanged: (v) => setState(() => _minSize = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: 'Max size',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    value: _maxSize,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Any')),
                      DropdownMenuItem(
                          value: 1048576, child: Text('1 MB')),
                      DropdownMenuItem(
                          value: 10485760, child: Text('10 MB')),
                      DropdownMenuItem(
                          value: 104857600, child: Text('100 MB')),
                      DropdownMenuItem(
                          value: 1073741824, child: Text('1 GB')),
                    ],
                    onChanged: (v) => setState(() => _maxSize = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: OxiColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Search your cloud files',
            style: TextStyle(fontSize: 18, color: OxiColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a search term and press Enter',
            style: TextStyle(color: OxiColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: OxiColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(fontSize: 18, color: OxiColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, SearchResults results) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            results.hasMore) {
          context.read<SearchBloc>().add(const SearchLoadMore());
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '${results.count} result${results.count == 1 ? '' : 's'}'
              '${results.totalCount != null ? ' of ${results.totalCount}' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          // Folders
          if (results.folders.isNotEmpty) ...[
            _sectionHeader(context, 'Folders', results.folders.length),
            ...results.folders.map((f) => _FolderResultTile(folder: f)),
          ],

          // Files
          if (results.files.isNotEmpty) ...[
            _sectionHeader(context, 'Files', results.files.length),
            ...results.files.map((f) => _FileResultTile(file: f)),
          ],

          if (results.hasMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        '$title ($count)',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: OxiColors.textSecondary,
            ),
      ),
    );
  }
}

// =============================================================================
// Result tiles
// =============================================================================

class _FolderResultTile extends StatelessWidget {
  final FolderItem folder;
  const _FolderResultTile({required this.folder});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder, color: OxiColors.primary, size: 36),
      title: Text(folder.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        folder.path,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () {
        // Navigate to folder in file browser
        Navigator.of(context).pushNamed('/files', arguments: folder.id);
      },
    );
  }
}

class _FileResultTile extends StatelessWidget {
  final FileItem file;
  const _FileResultTile({required this.file});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _fileIcon(file.extension),
        color: OxiColors.textSecondary,
        size: 36,
      ),
      title: Text(file.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${file.path} · ${file.formattedSize}',
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  IconData _fileIcon(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mkv':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'md':
        return Icons.description;
      case 'zip':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}
