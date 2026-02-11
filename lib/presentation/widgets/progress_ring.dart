import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Circular progress ring widget for displaying sync progress
class ProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 64,
    this.strokeWidth = 6,
    this.backgroundColor,
    this.progressColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final fgColor = progressColor ?? theme.colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: bgColor,
              progressColor: fgColor,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        2 * math.pi * progress, // Sweep angle
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}

/// Animated version of ProgressRing
class AnimatedProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Widget? child;
  final Duration duration;
  final Curve curve;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 64,
    this.strokeWidth = 6,
    this.backgroundColor,
    this.progressColor,
    this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: duration,
      curve: curve,
      builder: (context, value, _) {
        return ProgressRing(
          progress: value,
          size: size,
          strokeWidth: strokeWidth,
          backgroundColor: backgroundColor,
          progressColor: progressColor,
          child: child,
        );
      },
    );
  }
}
