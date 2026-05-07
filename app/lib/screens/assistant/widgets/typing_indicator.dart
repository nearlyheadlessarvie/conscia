import 'package:flutter/material.dart';

import '../../../widgets/conscience_mark.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({
    super.key,
    this.label,
  });

  final String? label;

  @override
  Widget build(BuildContext context) {
    return ConscienceLoader(
      size: 88,
      label: label,
    );
  }
}
