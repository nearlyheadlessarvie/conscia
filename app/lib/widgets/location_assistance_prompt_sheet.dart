import 'package:flutter/material.dart';

import 'conscia_button_row.dart';

class LocationAssistancePromptSheet extends StatelessWidget {
  const LocationAssistancePromptSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => const LocationAssistancePromptSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Turn on smart location help?',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Get nearby merchant and category suggestions wherever you need a little guidance. Suggestions only help fill things faster. You can still edit everything yourself.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'You can change this later in Settings.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ConsciaButtonRow(
              secondaryLabel: 'Not now',
              onSecondaryPressed: () => Navigator.of(context).pop(false),
              primaryLabel: 'Turn on',
              onPrimaryPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}
