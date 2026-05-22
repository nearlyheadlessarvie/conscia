import 'package:flutter/material.dart';

class LevelUpConfetti extends StatelessWidget {
  const LevelUpConfetti({
    super.key,
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: SizedBox.expand(
        key: ValueKey('journey-level-up-confetti'),
      ),
    );
  }
}
