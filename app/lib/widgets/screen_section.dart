import 'package:flutter/material.dart';

import 'editorial_section_header.dart';

class ScreenSection extends StatelessWidget {
  const ScreenSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
    this.compact = false,
    this.uppercase = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final bool compact;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 18 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EditorialSectionHeader(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            compact: compact,
            uppercase: uppercase,
          ),
          SizedBox(height: compact ? 10 : 14),
          child,
        ],
      ),
    );
  }
}
