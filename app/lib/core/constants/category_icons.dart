import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CategoryIcons {
  CategoryIcons._();

  static const Map<String, IconData> map = {
    'Groceries': Icons.shopping_cart,
    'Dining': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Games & Recreations': Icons.videogame_asset,
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

  static final Map<String, IconData> _cupertinoMap = {
    'Groceries': CupertinoIcons.cart,
    'Dining': CupertinoIcons.square_list,
    'Transport': CupertinoIcons.car,
    'Gaming': CupertinoIcons.game_controller,
    'Entertainment': CupertinoIcons.film,
    'Shopping': CupertinoIcons.bag,
    'Health': CupertinoIcons.heart,
    'Bills': CupertinoIcons.doc_text,
    'Education': CupertinoIcons.book,
    'Travel': CupertinoIcons.airplane,
    'Coffee': CupertinoIcons.circle,
    'Subscriptions': CupertinoIcons.arrow_2_circlepath,
    'Salary': CupertinoIcons.money_dollar,
    'Freelance': CupertinoIcons.briefcase,
    'Business': CupertinoIcons.building_2_fill,
    'Investment': CupertinoIcons.chart_bar,
    'Rental Income': CupertinoIcons.house,
    'Bonus': CupertinoIcons.star,
    'Gift': CupertinoIcons.gift,
    'Other': CupertinoIcons.ellipsis_circle,
  };

  static IconData forCategory(String category) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _cupertinoMap[category] ?? CupertinoIcons.ellipsis_circle;
    }
    return map[category] ?? Icons.more_horiz;
  }
}
