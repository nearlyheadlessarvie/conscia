import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? colors.surfaceContainerHighest : Colors.grey.shade300,
      highlightColor: isDark ? colors.surfaceContainer : Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 16, width: 120),
          SizedBox(height: 12),
          SkeletonLoader(height: 12, width: 200),
          SizedBox(height: 8),
          SkeletonLoader(height: 12),
        ],
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SkeletonLoader(width: 40, height: 40, borderRadius: 20),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(height: 14, width: 140),
                SizedBox(height: 8),
                SkeletonLoader(height: 12, width: 100),
              ],
            ),
          ),
          SkeletonLoader(width: 60, height: 14),
        ],
      ),
    );
  }
}

class InsightSkeletonCard extends StatelessWidget {
  const InsightSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoader(height: 12, width: 140),
            SizedBox(height: 12),
            SkeletonLoader(height: 24, width: 180),
            SizedBox(height: 12),
            SkeletonLoader(height: 12),
            SizedBox(height: 8),
            SkeletonLoader(height: 12, width: 200),
          ],
        ),
      ),
    );
  }
}

class InsightSkeletonSection extends StatelessWidget {
  const InsightSkeletonSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        InsightSkeletonCard(),
        SizedBox(height: 12),
        InsightSkeletonCard(),
        SizedBox(height: 12),
        InsightSkeletonCard(),
        SizedBox(height: 12),
      ],
    );
  }
}

class BudgetSummarySkeletonCard extends StatelessWidget {
  const BudgetSummarySkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonLoader(width: 32, height: 32, borderRadius: 16),
                  SizedBox(width: 10),
                  SkeletonLoader(height: 14, width: 80),
                ],
              ),
              SizedBox(height: 16),
              SkeletonLoader(height: 8, borderRadius: 4),
              SizedBox(height: 8),
              SkeletonLoader(height: 12, width: 120),
              SizedBox(height: 6),
              SkeletonLoader(height: 12, width: 90),
            ],
          ),
        ),
      ),
    );
  }
}

class BudgetListSkeletonCard extends StatelessWidget {
  const BudgetListSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonLoader(width: 32, height: 32, borderRadius: 16),
                SizedBox(width: 12),
                Expanded(child: SkeletonLoader(height: 16)),
                SizedBox(width: 12),
                SkeletonLoader(width: 24, height: 24, borderRadius: 4),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: SkeletonLoader(height: 14)),
                SizedBox(width: 16),
                SkeletonLoader(width: 36, height: 14),
              ],
            ),
            SizedBox(height: 8),
            SkeletonLoader(height: 8, borderRadius: 4),
            SizedBox(height: 8),
            Row(
              children: [
                SkeletonLoader(width: 40, height: 12),
                Spacer(),
                SkeletonLoader(width: 100, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
