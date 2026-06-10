// lib/presentation/widgets/category_grid.dart
import 'package:flutter/material.dart';

import '../../data/models/category.dart';

/// Uber/Rapido-style tappable category grid.
class CategoryGrid extends StatelessWidget {
  final List<ServiceCategory> categories;
  final void Function(ServiceCategory) onTap;
  const CategoryGrid({super.key, required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.82,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: categories.map((c) => _CategoryTile(category: c, onTap: () => onTap(c))).toList(),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ServiceCategory category;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFF2F2F7)
                  : const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Icon(
              category.materialIcon,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.1),
          ),
        ],
      ),
    );
  }
}
