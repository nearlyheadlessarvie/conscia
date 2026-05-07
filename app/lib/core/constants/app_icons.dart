import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class AppIcons {
  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static IconData adaptive({
    required IconData material,
    required IconData cupertino,
  }) =>
      _isIOS ? cupertino : material;

  static IconData get home =>
      adaptive(material: Icons.home_outlined, cupertino: CupertinoIcons.house);
  static IconData get homeActive =>
      adaptive(material: Icons.home, cupertino: CupertinoIcons.house_fill);
  static IconData get transactions => adaptive(
        material: Icons.receipt_long_outlined,
        cupertino: CupertinoIcons.list_bullet,
      );
  static IconData get transactionsActive => adaptive(
        material: Icons.receipt_long,
        cupertino: CupertinoIcons.list_bullet,
      );
  static IconData get scan => adaptive(
        material: Icons.document_scanner_outlined,
        cupertino: CupertinoIcons.camera_viewfinder,
      );
  static IconData get assistant => adaptive(
        material: Icons.auto_awesome_outlined,
        cupertino: CupertinoIcons.sparkles,
      );
  static IconData get assistantActive =>
      adaptive(material: Icons.auto_awesome, cupertino: CupertinoIcons.sparkles);
  static IconData get settings => adaptive(
        material: Icons.settings_outlined,
        cupertino: CupertinoIcons.settings,
      );
  static IconData get settingsActive => adaptive(
        material: Icons.settings,
        cupertino: CupertinoIcons.settings_solid,
      );

  static IconData get add =>
      adaptive(material: Icons.add, cupertino: CupertinoIcons.add);
  static IconData get close =>
      adaptive(material: Icons.close, cupertino: CupertinoIcons.xmark);
  static IconData get check =>
      adaptive(material: Icons.check, cupertino: CupertinoIcons.checkmark);
  static IconData get chevronRight => adaptive(
        material: Icons.chevron_right,
        cupertino: CupertinoIcons.chevron_right,
      );
  static IconData get calendar => adaptive(
        material: Icons.calendar_today,
        cupertino: CupertinoIcons.calendar,
      );
  static IconData get person =>
      adaptive(material: Icons.person, cupertino: CupertinoIcons.person);

  static IconData get saver => adaptive(
        material: Icons.savings,
        cupertino: CupertinoIcons.money_dollar_circle,
      );
  static IconData get balanced => adaptive(
        material: Icons.balance,
        cupertino: CupertinoIcons.equal_circle,
      );
  static IconData get freeSpender =>
      adaptive(material: Icons.celebration, cupertino: CupertinoIcons.star);
  static IconData get employed => adaptive(
        material: Icons.work,
        cupertino: CupertinoIcons.briefcase,
      );
  static IconData get selfEmployed => adaptive(
        material: Icons.laptop,
        cupertino: CupertinoIcons.device_laptop,
      );
  static IconData get student => adaptive(
        material: Icons.school,
        cupertino: CupertinoIcons.book,
      );
  static IconData get retired => adaptive(
        material: Icons.beach_access,
        cupertino: CupertinoIcons.sun_max,
      );
  static IconData get other => adaptive(
        material: Icons.more_horiz,
        cupertino: CupertinoIcons.ellipsis,
      );
  static IconData get couple => adaptive(
        material: Icons.people,
        cupertino: CupertinoIcons.person_2,
      );
  static IconData get family => adaptive(
        material: Icons.family_restroom,
        cupertino: CupertinoIcons.person_3,
      );
  static IconData get sharedHome =>
      adaptive(material: Icons.home, cupertino: CupertinoIcons.house);
}
