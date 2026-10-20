import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const routeName = 'onboarding';
  static const routePath = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  int _index = 0;

  final _pages = const [
    _OnbPage(
      imageAsset: 'assets/onboarding/onb_1.png',
      title: 'Discover local events',
      subtitle: 'Find concerts, workshops, and gatherings happening near you.',
    ),
    _OnbPage(
      imageAsset: 'assets/onboarding/onb_2.png',
      title: 'Book tickets easily',
      subtitle: 'Secure your spot in just a few taps, without long queues or confusion.',
    ),
    _OnbPage(
      imageAsset: 'assets/onboarding/onb_3.png',
      title: 'Stay in the loop',
      subtitle: 'Get event details, updates, and reminders — all in one place.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<AppState>().completeOnboarding();
    if (!mounted) return;
    context.go(WelcomeScreen.routePath);
  }

  Future<void> _next() async {
    final isLast = _index == _pages.length - 1;
    if (isLast) return _finish();

    await _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(onPressed: _finish, child: const Text('Skip')),
          const SizedBox(width: 6),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final page = _controller.hasClients
                          ? (_controller.page ?? _index.toDouble())
                          : _index.toDouble();

                      final diff = (page - i).abs().clamp(0.0, 1.0);
                      final t = 1.0 - diff;

                      final scale = 0.96 + (0.04 * t);
                      final opacity = 0.35 + (0.65 * t);
                      final translateY = 24 * (1 - t);

                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, translateY),
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _pages[i],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 66,
              width: 66,
              child: FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  elevation: 2,
                ),
                child: Icon(
                  _index == _pages.length - 1
                      ? Icons.check
                      : Icons.arrow_forward,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: i == _index ? 20 : 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: i == _index ? cs.primary : cs.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnbPage extends StatelessWidget {
  const _OnbPage({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
  });

  final String imageAsset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Slightly smaller than before (was fixed 260).
    final screenH = MediaQuery.of(context).size.height;
    final imageH = (screenH * 0.30).clamp(200.0, 240.0); // <= smaller

    return Column(
      children: [
        const Spacer(),
        SizedBox(
          height: imageH,
          child: Image.asset(
            imageAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 20), // was 26
        Text(
          title,
          textAlign: TextAlign.center,
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}