import 'package:flutter/material.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

class PageLoadingView extends StatelessWidget {
  final int itemCount;
  final double topPadding;
  final bool includeHeader;

  const PageLoadingView({
    super.key,
    this.itemCount = 4,
    this.topPadding = 16,
    this.includeHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (includeHeader) ...[
            _SkeletonLine(width: 120, height: 12),
            const SizedBox(height: 14),
          ],
          ...List.generate(itemCount, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 12),
              child: const _SkeletonCard(),
            );
          }),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.borderColor.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _SkeletonLine(width: 160, height: 12),
                SizedBox(height: 8),
                _SkeletonLine(width: 110, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.borderColor.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
