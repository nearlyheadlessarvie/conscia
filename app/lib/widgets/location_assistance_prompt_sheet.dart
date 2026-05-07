import 'package:flutter/material.dart';

class LocationAssistancePromptSheet extends StatelessWidget {
  const LocationAssistancePromptSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Not now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Turn on'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
