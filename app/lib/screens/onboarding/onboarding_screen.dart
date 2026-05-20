import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:conscia_app/core/assets/onboarding_illustrations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              colors.primaryContainer.withValues(alpha: 0.3),
              colors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: const [
                    _Slide(
                      illustration: OnboardingIllustration1(size: 252),
                      title: 'Build a calmer money rhythm',
                      subtitle:
                          'Start with small check-ins that make spending feel easier to understand.',
                    ),
                    _Slide(
                      illustration: OnboardingIllustration2(size: 252),
                      title: 'Notice patterns without shame',
                      subtitle:
                          'Log what happened, see the signal, and keep the tone kind.',
                    ),
                    _Slide(
                      illustration: OnboardingIllustration3(size: 252),
                      title: 'Let gentle guardrails help',
                      subtitle:
                          'Budgets, reflections, and insights work together without the pressure.',
                    ),
                  ],
                ),
              ),
              _PageIndicators(
                count: 3,
                current: _currentPage,
                primaryColor: colors.primary,
                inactiveColor: colors.outlineVariant,
              ),
              const SizedBox(height: 32),
              if (_currentPage == 2) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => context.go('/onboarding/sign-up'),
                      child: const Text('Create Account'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/onboarding/sign-in'),
                  child: Text(
                    'Already have an account? Sign In',
                    style: TextStyle(color: colors.primary),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.tonal(
                      onPressed: () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Next'),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String subtitle;

  const _Slide({
    required this.illustration,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            flex: 60,
            child: Center(child: illustration),
          ),
          Expanded(
            flex: 40,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  title,
                  style: textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  subtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  final int count;
  final int current;
  final Color primaryColor;
  final Color inactiveColor;

  const _PageIndicators({
    required this.count,
    required this.current,
    required this.primaryColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 10 : 8,
          height: isActive ? 10 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? primaryColor : inactiveColor,
          ),
        );
      }),
    );
  }
}
