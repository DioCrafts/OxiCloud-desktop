import 'package:flutter/material.dart';
import '../config/constants.dart';

enum ScreenSize { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static ScreenSize screenSize(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < Constants.mobileBreakpoint) return ScreenSize.mobile;
    if (width < Constants.tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static bool isMobile(BuildContext context) =>
      screenSize(context) == ScreenSize.mobile;

  static bool isTablet(BuildContext context) =>
      screenSize(context) == ScreenSize.tablet;

  static bool isDesktop(BuildContext context) =>
      screenSize(context) == ScreenSize.desktop;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < Constants.tabletBreakpoint;

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    return switch (screenSize(context)) {
      ScreenSize.mobile => mobile,
      ScreenSize.tablet => tablet ?? desktop,
      ScreenSize.desktop => desktop,
    };
  }
}

class AdaptiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context) desktop;

  const AdaptiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return switch (Responsive.screenSize(context)) {
      ScreenSize.mobile => mobile(context),
      ScreenSize.tablet => (tablet ?? desktop)(context),
      ScreenSize.desktop => desktop(context),
    };
  }
}
