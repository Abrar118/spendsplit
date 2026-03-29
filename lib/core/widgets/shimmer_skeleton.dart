import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surfaceContainerHighest,
      child: child,
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    required this.height,
    super.key,
    this.radius = 20,
    this.margin,
  });

  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: GlassCard(
        radius: radius,
        margin: margin,
        child: Container(color: Colors.white.withValues(alpha: 0.04)),
      ),
    );
  }
}
