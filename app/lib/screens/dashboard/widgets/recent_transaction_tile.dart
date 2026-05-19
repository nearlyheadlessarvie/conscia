import 'package:flutter/material.dart';

import '../../transactions/widgets/editorial_transaction_row.dart';

class RecentTransactionTile extends StatelessWidget {
  final String id;
  final Widget categoryBadge;
  final String counterparty;
  final String category;
  final DateTime date;
  final double amount;
  final bool isIncome;
  final String currencyCode;
  final int? regretLevel;
  final bool isRecurring;
  final bool isFamily;
  final String? locale;

  const RecentTransactionTile({
    super.key,
    required this.id,
    required this.categoryBadge,
    required this.counterparty,
    required this.category,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.currencyCode,
    this.regretLevel,
    this.isRecurring = false,
    this.isFamily = false,
    this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return EditorialTransactionRow(
      data: EditorialTransactionRowData(
        id: id,
        isIncome: isIncome,
        amount: amount,
        currencyCode: currencyCode,
        category: category,
        title: counterparty,
        regretLevel: regretLevel,
        isRecurring: isRecurring,
        isFamily: isFamily,
      ),
      locale: locale,
    );
  }
}
