import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers.dart';

class ConnectPage extends ConsumerStatefulWidget {
  const ConnectPage({super.key});

  @override
  ConsumerState<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends ConsumerState<ConnectPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var url = _urlCtrl.text.trim();
      if (url.endsWith('/')) url = url.substring(0, url.length - 1);

      // Verify the server is reachable by calling /api/version
      final testDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      await testDio.get('$url/api/version');

      // Server is valid — save and proceed
      await ref.read(appConfigProvider.notifier).setServerUrl(url);

      if (!mounted) return;

      // Check if admin exists to decide login vs setup
      try {
        final status = await ref.read(authRepositoryProvider).getStatus();
        if (!mounted) return;
        if (!status.adminExists) {
          context.go('/setup');
        } else {
          context.go('/login');
        }
      } catch (_) {
        // If status check fails, go to login anyway
        if (mounted) context.go('/login');
      }
    } on DioException catch (e) {
      setState(() {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          _error = 'Cannot reach server. Check URL and network.';
        } else if (e.response?.statusCode == 404) {
          _error = 'Not an OxiCloud server (404). Check the URL.';
        } else {
          _error = 'Connection failed: ${e.message}';
        }
      });
    } catch (e) {
      setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text('OxiCloud', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Connect to your server',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _urlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'https://cloud.example.com',
                        prefixIcon: Icon(Icons.dns_outlined),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      autofocus: true,
                      onFieldSubmitted: (_) => _connect(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Server URL is required';
                        }
                        final url = v.trim();
                        if (!url.startsWith('http://') &&
                            !url.startsWith('https://')) {
                          return 'URL must start with http:// or https://';
                        }
                        final uri = Uri.tryParse(url);
                        if (uri == null || !uri.hasAuthority) {
                          return 'Invalid URL';
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _connect,
                        icon: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward),
                        label: Text(_loading ? 'Connecting…' : 'Connect'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
