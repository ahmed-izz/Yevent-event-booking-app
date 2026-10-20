import 'package:flutter/material.dart';

class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode we want the LIGHT (white) logo.
    final asset = isDark
        ? 'assets/branding/yevent_wordmark_light.png'
        : 'assets/branding/yevent_wordmark_dark.png';

    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}