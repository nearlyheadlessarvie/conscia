import 'package:flutter/material.dart';

import 'selection_chip_group.dart';
import '../../../widgets/form_label.dart';

class RecurringScheduleSection extends StatelessWidget {
  const RecurringScheduleSection({
    super.key,
    required this.enabled,
    required this.cadence,
    required this.endDate,
    required this.onEnabledChanged,
    required this.onCadenceChanged,
    required this.onEndDateChanged,
  });

  final bool enabled;
  final String cadence;
  final DateTime? endDate;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onCadenceChanged;
  final ValueChanged<DateTime?> onEndDateChanged;

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      onEndDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const FormLabel(label: 'RECURRING'),
          subtitle: const Text(
            'Repeat on a schedule.',
          ),
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        if (enabled) ...[
          const SizedBox(height: 12),
          SelectionChipGroup(
            options: const ['Weekly', 'Monthly', 'Yearly'],
            value: cadence,
            onSelected: onCadenceChanged,
            scrollable: true,
          ),
          const SizedBox(height: 12),
          const FormLabel(label: 'END DATE'),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _pickEndDate(context),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                hintText: 'Never ends',
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      endDate == null ? 'Never ends' : _formatDate(endDate!),
                    ),
                  ),
                  if (endDate != null)
                    IconButton(
                      tooltip: 'Clear end date',
                      onPressed: () => onEndDateChanged(null),
                      icon: const Icon(Icons.close, size: 18),
                    )
                  else
                    const Icon(Icons.calendar_today_outlined, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
