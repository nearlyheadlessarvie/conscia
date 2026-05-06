import 'package:flutter/material.dart';

class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> map = {
    'Groceries': Icons.shopping_cart,
    'Dining': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Gaming': Icons.videogame_asset,
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
    'Business': Icons.storefront,
    'Investment': Icons.trending_up,
    'Rental Income': Icons.home,
    'Bonus': Icons.star,
    'Gift': Icons.card_giftcard,
    'Other': Icons.more_horiz,
  };

  static IconData forCategory(String category) =>
      map[category] ?? Icons.more_horiz;
}
