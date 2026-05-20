import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';

class EditorialSectionHeader extends StatelessWidget {
  const EditorialSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.compact = false,
    this.uppercase = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool compact;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final titleText = uppercase ? title.toUpperCase() : title;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                style: uppercase
                    ? GoogleFonts.nunitoSans(
                        textStyle: textTheme.labelSmall,
                        color: colors.mutedInk,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      )
                    : GoogleFonts.libreBaskerville(
                        textStyle: compact
                            ? textTheme.titleMedium
                            : textTheme.titleLarge,
                        color: colors.deepNavy,
                        fontWeight: FontWeight.w700,
                        height: 1.08,
                      ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.nunitoSans(
                    textStyle: textTheme.bodySmall,
                    color: colors.mutedInk,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}
