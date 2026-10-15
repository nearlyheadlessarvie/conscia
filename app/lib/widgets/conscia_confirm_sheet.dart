import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'conscia_bottom_sheet.dart';

class ConsciaConfirmSheet extends StatelessWidget {
  const ConsciaConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = true,
    this.preview,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;
  final Widget? preview;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = true,
    Widget? preview,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => ConsciaConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        destructive: destructive,
        preview: preview,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final confirmColor = destructive ? colors.expense : colors.deepNavy;
    final messageLines = message
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final primaryMessage = messageLines.isEmpty ? message : messageLines.first;
    final supportingMessage =
        messageLines.length > 1 ? messageLines.skip(1).join('\n') : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ConsciaSheetHandle(),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: preview == null ? 16 : 14,
                vertical: preview == null ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: destructive ? colors.expenseSoft.withAlpha(120) : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: preview == null
                  ? _ConfirmMessage(
                      primaryMessage: primaryMessage,
                      supportingMessage: supportingMessage,
                      destructive: destructive,
                    )
                  : Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: preview!,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.mutedInk,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: Text(confirmLabel),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmMessage extends StatelessWidget {
  const _ConfirmMessage({
    required this.primaryMessage,
    required this.supportingMessage,
    required this.destructive,
  });

  final String primaryMessage;
  final String? supportingMessage;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          primaryMessage,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: destructive ? colors.ink : colors.mutedInk,
            fontWeight:
                supportingMessage == null ? FontWeight.w500 : FontWeight.w700,
            height: 1.25,
          ),
        ),
        if (supportingMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            supportingMessage!,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colors.mutedInk,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}
