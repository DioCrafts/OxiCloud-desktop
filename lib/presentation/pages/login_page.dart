import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../theme/oxicloud_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthUnauthenticated) {
      if (authState.lastServerUrl != null) {
        _serverUrlController.text = authState.lastServerUrl!;
      }
      if (authState.lastUsername != null) {
        _usernameController.text = authState.lastUsername!;
      }
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginSubmitted(
            serverUrl: _serverUrlController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: OxiColors.error,
              ),
            );
          } else if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    _buildLogo(),
                    const SizedBox(height: 48),

                    // Title
                    Text(
                      'Welcome to OxiCloud',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect to your self-hosted cloud',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Server URL
                    TextFormField(
                      controller: _serverUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Server URL',
                        hintText: 'https://cloud.example.com',
                        prefixIcon: Icon(Icons.cloud_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      validator: _validateServerUrl,
                    ),
                    const SizedBox(height: 16),

                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onLogin(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;

                        return SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _onLogin,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Connect'),
                          ),
                        );
                      },
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

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        gradient: OxiColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x59FF5E3A),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.cloud,
        size: 56,
        color: Colors.white,
      ),
    );
  }

  String? _validateServerUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your server URL';
    }

    final url = value.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'URL must start with http:// or https://';
    }

    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) {
        return 'Invalid URL';
      }
    } catch (e) {
      return 'Invalid URL format';
    }

    return null;
  }
}
