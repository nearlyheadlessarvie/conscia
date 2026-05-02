import 'package:flutter/material.dart';

class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> map = {
    'Groceries': Icons.shopping_cart,
    'Dining': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Games & Recreations': Icons.stadia_controller,
    'Entertainment': Icons.movie,
    'Shopping': Icons.shopping_bag,
    'Health': Icons.favorite,
    'Bills': Icons.receipt,
    'Education': Icons.school,
    'Travel': Icons.flight,
    'Coffee': Icons.coffee,
    'Subscriptions': Icons.autorenew,
    'Salary': Icons.account_balance,
    'Freelance': Icons.work,
    'Gift': Icons.card_giftcard,
    'Other': Icons.more_horiz,
  };

  static IconData forCategory(String category) =>
      map[category] ?? Icons.more_horiz;
}
