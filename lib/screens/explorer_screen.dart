import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/camera_scan_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/product_crud_modal.dart';

class ExplorerScreen extends StatefulWidget {
  final AppState state;

  const ExplorerScreen({
    super.key,
    required this.state,
  });

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductCrudModal(
        state: widget.state,
        onSave: (newProduct) {
          widget.state.addProduct(newProduct);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${newProduct.name}" to stash!'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  void _openEditModal(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProductCrudModal(
        state: widget.state,
        productToEdit: product,
        onSave: (updated) {
          widget.state.updateProduct(updated);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated "${updated.name}"'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevation2,
        title: const Text('Delete Product?'),
        content: Text(
          'Are you sure you want to remove "${product.name}" from your stash records? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.state.deleteProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${product.name}"'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final products = state.filteredProducts;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Vault',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.products.length} Products Logged',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => CameraScanService.startPackagingScan(context, state: state),
                        icon: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20),
                        tooltip: 'Scan packaging label',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevation2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _openAddModal(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar & Clear
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevation2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => state.setSearchQuery(val),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              state.setSearchQuery('');
                            },
                          )
                        : null,
                    hintText: 'Search strain name, dispensary, notes...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Status Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: ['All', 'In Stash', 'Unopened', 'Finished'].map((status) {
                  final isSelected = state.selectedStatus == status;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () => state.setSelectedStatus(status),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.surfaceElevation3 : AppColors.surfaceElevation1,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Sort Dropdown Pill Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Sort: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ...['Highest Rated', 'Strength %', 'Recently Purchased', 'Name A-Z'].map((sort) {
                      final isSelected = state.selectedSort == sort;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(sort),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) state.setSelectedSort(sort);
                          },
                          selectedColor: AppColors.primaryGlow,
                          backgroundColor: Colors.transparent,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Product List
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No products match your criteria',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              state.setSearchQuery('');
                              state.setSelectedStatus('All');
                              state.setSelectedType('All');
                            },
                            child: const Text('Reset Filters', style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onEdit: () => _openEditModal(context, product),
                          onDelete: () => _confirmDelete(context, product),
                          onToggleFavorite: () => state.toggleFavorite(product.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
