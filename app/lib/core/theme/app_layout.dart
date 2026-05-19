import 'package:flutter/material.dart';

/// Layout constants that sit above raw spacing tokens.
///
/// Keep these values named so screens choose a design pattern instead of
/// sprinkling `MediaQuery.paddingOf(context).top + n` through the app.
abstract final class AppLayout {
  static const double screenPadding = 20;
  static const double heroBottomPadding = 28;

  /// Matches [ConsciaAppBar.preferredSize].
  static const double appBarHeight = 68;
  static const double appBarCapsuleHeight = 52;
  static const double listIconSize = 30;

  /// Bleeding editorial heroes start under the transparent app bar, not below
  /// an opaque toolbar rectangle. This is the default for Settings, Shared
  /// Conscia, Profile, and onboarding.
  static const double bleedingHeroTopGap = 12;

  /// Use only when hero content truly needs to clear the full transparent app
  /// bar, for example a dense hero that begins with controls rather than copy.
  static const double appBarClearHeroTopGap = appBarHeight + 8;

  /// Home owns a resident profile/notification header inside the hero, so the
  /// main hero copy starts lower than ordinary editorial heroes.
  static const double dashboardHeroTopGap = 88;

  /// Insight drilldowns use a compact floating app bar over a hero summary.
  static const double drilldownHeroTopGap = 85;

  /// Budget hero has a compact app bar but a visual donut beside the copy, so
  /// it needs a small extra step down from the default bleed.
  static const double budgetHeroTopGap = 24;

  static const double insightsHeroTopGap = 70;
  static const double transactionListHeroTopGap = 75;
  static const double transactionDetailHeroTopGap = 68;
  static const double assistantHeroTopGap = 68;
  static const double assistantScrollTargetTopGap = 104;
  static const double journeyHeaderTopGap = 60;
  static const double stickyHeaderTopGap = 8;

  static const double transactionFilterPinnedGap = 62;

  static double safeTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  static double bleedingHeroTop(BuildContext context) =>
      safeTop(context) + bleedingHeroTopGap;

  static double appBarClearHeroTop(BuildContext context) =>
      safeTop(context) + appBarClearHeroTopGap;

  static double dashboardHeroTop(BuildContext context) =>
      safeTop(context) + dashboardHeroTopGap;

  static double drilldownHeroTop(BuildContext context) =>
      safeTop(context) + drilldownHeroTopGap;

  static double budgetHeroTop(BuildContext context) =>
      safeTop(context) + budgetHeroTopGap;

  static double insightsHeroTop(BuildContext context) =>
      safeTop(context) + insightsHeroTopGap;

  static double transactionListHeroTop(BuildContext context) =>
      safeTop(context) + transactionListHeroTopGap;

  static double transactionDetailHeroTop(BuildContext context) =>
      safeTop(context) + transactionDetailHeroTopGap;

  static double assistantHeroTop(BuildContext context) =>
      safeTop(context) + assistantHeroTopGap;

  static double assistantScrollTargetTop(BuildContext context) =>
      safeTop(context) + assistantScrollTargetTopGap;

  static double journeyHeaderTop(BuildContext context) =>
      safeTop(context) + journeyHeaderTopGap;

  static double transactionFilterPinnedTop(BuildContext context) =>
      safeTop(context) + transactionFilterPinnedGap;
}
