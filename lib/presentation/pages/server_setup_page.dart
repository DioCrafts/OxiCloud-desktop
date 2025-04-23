import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oxicloud_desktop/presentation/providers/auth_provider.dart';
import 'package:oxicloud_desktop/presentation/widgets/input_field.dart';

/// Page for server configuration
class ServerSetupPage extends ConsumerStatefulWidget {
  /// Create a ServerSetupPage
  const ServerSetupPage({super.key});

  @override
  ConsumerState<ServerSetupPage> createState() => _ServerSetupPageState();
}

class _ServerSetupPageState extends ConsumerState<ServerSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;
  
  static const _defaultServers = [
    'https://oxicloud.example.com',
    'https://cloud.example.org',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadCurrentServer();
  }
  
  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCurrentServer() async {
    final serverUrl = await ref.read(serverUrlProvider.future);
    if (serverUrl != null && mounted) {
      _serverUrlController.text = serverUrl;
    }
  }
  
  Future<void> _validateAndSaveServer() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });
    
    try {
      var serverUrl = _serverUrlController.text.trim();
      
      // Ensure URL has a scheme
      if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
        serverUrl = 'https://$serverUrl';
      }
      
      // Remove trailing slash if present
      if (serverUrl.endsWith('/')) {
        serverUrl = serverUrl.substring(0, serverUrl.length - 1);
      }
      
      // Update controller with normalized URL
      _serverUrlController.text = serverUrl;
      
      // Save server URL
      await ref.read(authNotifierProvider.notifier).setServerUrl(serverUrl);
      
      // Navigate to login page
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to server: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }
  
  void _selectDefaultServer(String serverUrl) {
    _serverUrlController.text = serverUrl;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and title
                _buildHeader(),
                
                const SizedBox(height: 24),
                
                // Server form
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error message if validation fails
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildErrorMessage(_errorMessage!),
                            ),
                          
                          // Server URL field
                          OptimizedInputField(
                            controller: _serverUrlController,
                            labelText: 'Server URL',
                            prefixIcon: const Icon(Icons.cloud),
                            hintText: 'https://oxicloud.example.com',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a server URL';
                              }
                              
                              // Basic URL validation
                              final normalizedUrl = value.trim();
                              final urlPattern = RegExp(
                                r'^(https?:\/\/)?(www\.)?([a-zA-Z0-9][-a-zA-Z0-9]{0,62}\.)+[a-zA-Z]{2,}(:\d+)?(\/[-a-zA-Z0-9%_.~#?&=]*)?$',
                              );
                              
                              if (!urlPattern.hasMatch(normalizedUrl)) {
                                return 'Please enter a valid URL';
                              }
                              
                              return null;
                            },
                            onFieldSubmitted: (_) => _validateAndSaveServer(),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Connect button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isValidating ? null : _validateAndSaveServer,
                              child: _isValidating
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Connect',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Default servers section
                          if (_defaultServers.isNotEmpty) ...[
                            const Divider(),
                            const SizedBox(height: 16),
                            Text(
                              'Default Servers',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            ..._defaultServers.map((server) => _buildServerItem(server)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Version info
                const Center(
                  child: Text(
                    'OxiCloud Desktop v0.1.0',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 80,
          // If image is not available, use placeholder
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.cloud,
            size: 80,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'OxiCloud',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect to your server',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
  
  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildServerItem(String serverUrl) {
    return ListTile(
      title: Text(serverUrl),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: 'Use this server',
        onPressed: () => _selectDefaultServer(serverUrl),
      ),
      onTap: () => _selectDefaultServer(serverUrl),
    );
  }
}