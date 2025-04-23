import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oxicloud_desktop/application/services/auth_service.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:oxicloud_desktop/presentation/providers/auth_provider.dart';

/// Splash page shown during app initialization
class SplashPage extends ConsumerStatefulWidget {
  /// Create a SplashPage
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    // Start animation
    _animationController.forward();
    
    // Navigate after initialization
    _checkAuthAndNavigate();
  }
  
  Future<void> _checkAuthAndNavigate() async {
    // Wait for a minimum splash display time
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Check if a server URL is set
    final authService = getIt<AuthService>();
    final hasServerUrl = await authService.hasServerUrl();
    
    if (!hasServerUrl) {
      if (mounted) {
        context.go('/server-setup');
      }
      return;
    }
    
    // Check if user is logged in
    final isLoggedIn = await authService.isLoggedIn();
    
    if (!isLoggedIn) {
      if (mounted) {
        context.go('/login');
      }
      return;
    }
    
    // Check if initial setup has been completed
    // In a real implementation, you would check if this is the first run
    final isFirstRun = false; // Replace with actual check
    
    if (isFirstRun) {
      if (mounted) {
        context.go('/initial-setup');
      }
      return;
    }
    
    // Navigate to home page
    if (mounted) {
      context.go('/');
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                      // If image is not available, use placeholder
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.cloud,
                        size: 120,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App name
                    Text(
                      'OxiCloud',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Loading indicator
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}