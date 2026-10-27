import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Indica':
        return AppColors.indicaTag;
      case 'Sativa':
        return AppColors.sativaTag;
      case 'Hybrid':
        return AppColors.hybridTag;
      case 'Extract':
        return AppColors.extractTag;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final typeColor = _getTypeColor(product.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevation2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: typeColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              product.type.toUpperCase(),
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.isOpen)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'OPEN IN STASH',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (product.isFinished)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FINISHED',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                // Rating Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevation1,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Source and Potency Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    product.source,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevation1,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.strength,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryLight),
                  ),
                ),
              ],
            ),
          ),

          // Description & Notes
          if (product.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                product.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          if (product.reviewNotes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevation1.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.primaryLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        product.reviewNotes,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Progress & Stash Remaining
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stash Remaining: ${product.remainingGrams.toStringAsFixed(1)}g / ${product.totalGrams.toStringAsFixed(1)}g',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      '\$${product.price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: product.progress,
                    backgroundColor: AppColors.surfaceElevation1,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      product.progress > 0.3 ? AppColors.primary : AppColors.error,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // Dates Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  'Purchased: ${dateFormat.format(product.datePurchased)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (product.dateOpened != null)
                  Text(
                    'Opened: ${dateFormat.format(product.dateOpened!)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (product.dateFinished != null)
                  Text(
                    'Finished: ${dateFormat.format(product.dateFinished!)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.error),
                  ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 16),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    product.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: product.isFavorite ? AppColors.primary : AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: onToggleFavorite,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                  label: const Text('Edit', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                  label: const Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
