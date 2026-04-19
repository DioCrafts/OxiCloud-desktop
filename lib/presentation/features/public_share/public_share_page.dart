import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers.dart';
import '../../../data/datasources/remote/public_share_remote_datasource.dart';

class PublicSharePage extends ConsumerStatefulWidget {
  final String token;
  const PublicSharePage({super.key, required this.token});

  @override
  ConsumerState<PublicSharePage> createState() => _PublicSharePageState();
}

class _PublicSharePageState extends ConsumerState<PublicSharePage> {
  PublicShareInfo? _info;
  bool _loading = true;
  String? _error;
  bool _needsPassword = false;
  bool _passwordVerified = false;
  bool _downloading = false;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShareInfo();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadShareInfo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = ref.read(publicShareRemoteDatasourceProvider);
      final info = await ds.getShareInfo(widget.token);
      setState(() {
        _info = info;
        _needsPassword = info.passwordProtected && !_passwordVerified;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _verifyPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    setState(() => _loading = true);
    try {
      final ds = ref.read(publicShareRemoteDatasourceProvider);
      final ok = await ds.verifyPassword(widget.token, password);
      if (ok) {
        setState(() {
          _passwordVerified = true;
          _needsPassword = false;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Incorrect password';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _download() async {
    final savePath = await FilePicker.saveFile(
      dialogTitle: 'Save shared file',
      fileName: _info?.name ?? 'download',
    );
    if (savePath == null) return;

    setState(() => _downloading = true);
    try {
      final ds = ref.read(publicShareRemoteDatasourceProvider);
      await ds.download(widget.token, savePath);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download complete')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared Item')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(_error!, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loadShareInfo,
                    child: const Text('Retry'),
                  ),
                ],
              )
            : _needsPassword
            ? _buildPasswordForm()
            : _buildShareDetails(),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 48),
          const SizedBox(height: 16),
          Text(
            'This share is password-protected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _verifyPassword(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _verifyPassword, child: const Text('Unlock')),
        ],
      ),
    );
  }

  Widget _buildShareDetails() {
    final info = _info!;
    final isFile = info.itemType == 'file';
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFile ? Icons.insert_drive_file_outlined : Icons.folder_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(info.name, style: Theme.of(context).textTheme.headlineSmall),
          if (info.size != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatSize(info.size!),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (info.expiresAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Expires: ${info.expiresAt}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          if (isFile)
            FilledButton.icon(
              onPressed: _downloading ? null : _download,
              icon: _downloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_downloading ? 'Downloading...' : 'Download'),
            ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
