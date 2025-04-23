import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oxicloud_desktop/presentation/providers/auth_provider.dart';
import 'package:oxicloud_desktop/presentation/widgets/input_field.dart';

/// Page for user authentication
class LoginPage extends ConsumerStatefulWidget {
  /// Create a LoginPage
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _rememberMe = false;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _login() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // Get form values
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    
    // Attempt to login
    ref.read(authNotifierProvider.notifier).login(username, password);
  }
  
  void _navigateToServerSetup() {
    context.push('/server-setup');
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
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
                
                // Login form
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error message if login fails
                          if (authState.hasError)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _buildErrorMessage(authState.error.toString()),
                            ),
                          
                          // Username field
                          OptimizedInputField(
                            controller: _usernameController,
                            labelText: 'Username',
                            prefixIcon: const Icon(Icons.person),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Password field
                          OptimizedInputField(
                            controller: _passwordController,
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            obscureText: !_passwordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _login(),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Remember me checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                              const Text('Remember me'),
                              
                              const Spacer(),
                              
                              // Forgot password link
                              TextButton(
                                onPressed: () {
                                  // Handle forgot password
                                },
                                child: const Text('Forgot password?'),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Login button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _login,
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Change server link
                          Center(
                            child: TextButton(
                              onPressed: _navigateToServerSetup,
                              child: const Text('Change server'),
                            ),
                          ),
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
          'Login to your account',
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
}