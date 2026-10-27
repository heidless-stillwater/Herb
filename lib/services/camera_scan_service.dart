import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/product_crud_modal.dart';

class CameraScanService {
  static final ImagePicker _picker = ImagePicker();

  /// Prompts user to input and save their free Google Gemini API key if not yet configured.
  static Future<bool> ensureApiKey(BuildContext context, AppState state) async {
    if (state.geminiService.hasApiKey) return true;

    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevation2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.key_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Gemini API Key Required',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To extract real packaging details using Gemini Vision, enter your free Google Gemini API key once.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevation1,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Keys are 100% free from Google AI Studio and stored permanently on your device.',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.9)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'Paste AIzaSy... key',
                    hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: AppColors.surfaceElevation1,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste_rounded, color: AppColors.primary, size: 18),
                      tooltip: 'Paste from clipboard',
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          controller.text = data!.text!.trim();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final key = controller.text.trim();
                if (key.isNotEmpty) {
                  await state.updateGeminiApiKey(key);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save & Continue', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Prompts the user to pick Camera or Gallery, photographs the packaging,
  /// extracts data via Gemini Vision, and opens the pre-filled ProductCrudModal.
  static Future<void> startPackagingScan(
    BuildContext context, {
    required AppState state,
    VoidCallback? onProductSaved,
  }) async {
    // 0. Ensure Gemini API Key is configured before scanning
    final hasKey = await ensureApiKey(context, state);
    if (!hasKey || !context.mounted) return;

    // 1. Show Camera vs Gallery choice sheet
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceElevation2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGlow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Packaging Label',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        Text(
                          'Photograph label, jar, or pouch to auto-extract info',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevation1,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  subtitle: const Text('Uses phone camera with auto-focus & flash', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevation1,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryLight),
                  ),
                  title: const Text('Choose from Photo Gallery', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  subtitle: const Text('Upload an existing photo of your stash packaging', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !context.mounted) return;

    bool userCancelled = false;
    BuildContext? dialogContext;

    try {
      // 2. Launch Camera or Gallery with optimized mobile compression
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
      );

      if (photo == null || !context.mounted) return;

      // 3. Show analyzing progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return _buildScanningDialog(
            ctx,
            onCancel: () {
              userCancelled = true;
              Navigator.pop(ctx);
            },
          );
        },
      );

      final imageBytes = await photo.readAsBytes();
      final extracted = await state.geminiService.extractPackagingLabel(imageBytes);

      // Dismiss scanning dialog if still showing
      if (dialogContext != null && dialogContext!.mounted && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      // If user cancelled the scan dialog during processing, abort quietly
      if (userCancelled || !context.mounted) return;

      // 4. Construct draft Product from extracted AI data
      final draftProduct = Product(
        id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
        name: extracted['name'] ?? 'Scanned Cultivar',
        type: extracted['type'] ?? 'Hybrid',
        strength: extracted['strength'] ?? '24.0% THC',
        remainingGrams: extracted['remainingGrams'] ?? 14.0,
        totalGrams: extracted['remainingGrams'] ?? 14.0,
        source: extracted['source'] ?? 'Verified Dispensary',
        description: extracted['description'] ?? 'Scanned from label photo.',
        rating: extracted['rating'] ?? 9.0,
        price: 120.0,
        datePurchased: DateTime.now(),
        dateOpened: DateTime.now(),
        isFavorite: false,
        reviewNotes: 'Auto-extracted from packaging photo with Gemini Vision.',
      );

      // 5. Open ProductCrudModal in "Review & Confirm" mode
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (modalCtx) {
          return ProductCrudModal(
            state: state,
            productToEdit: draftProduct,
            onSave: (savedProduct) {
              state.addProduct(savedProduct);
              if (onProductSaved != null) onProductSaved();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ ${savedProduct.name} saved to your Stash!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      // Dismiss scanning dialog if still open
      if (dialogContext != null && dialogContext!.mounted && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }
      if (userCancelled) return;
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceElevation2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
                SizedBox(width: 8),
                Text('Vision Scan Error', style: TextStyle(fontSize: 16, color: Colors.white)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$e',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tip: You can proceed by using the pre-filled packaging template while checking your API key.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Open modal with sample packaging draft so user is never blocked
                  final sample = state.geminiService.getSamplePackagingData();
                  final fallbackProduct = Product(
                    id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
                    name: sample['name'] ?? 'Scanned Cultivar',
                    type: sample['type'] ?? 'Hybrid',
                    strength: sample['strength'] ?? '24.5% THC',
                    remainingGrams: sample['remainingGrams'] ?? 14.0,
                    totalGrams: sample['remainingGrams'] ?? 14.0,
                    source: sample['source'] ?? 'Verified Dispensary',
                    description: sample['description'] ?? 'Scanned from packaging photo.',
                    rating: sample['rating'] ?? 9.2,
                    price: 120.0,
                    datePurchased: DateTime.now(),
                    dateOpened: DateTime.now(),
                    isFavorite: false,
                    reviewNotes: 'Form populated via packaging scanner template.',
                  );
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (modalCtx) => ProductCrudModal(
                      state: state,
                      productToEdit: fallbackProduct,
                      onSave: (savedProduct) {
                        state.addProduct(savedProduct);
                        if (onProductSaved != null) onProductSaved();
                      },
                    ),
                  );
                },
                child: const Text('Fill Form with Template', style: TextStyle(color: AppColors.primaryLight)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Dismiss', style: TextStyle(color: AppColors.textMuted)),
              ),
            ],
          ),
        );
      }
    }
  }

  static Widget _buildScanningDialog(BuildContext ctx, {VoidCallback? onCancel}) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevation2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGlow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Reading Packaging Label...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gemini Vision is analyzing your packaging photo (typically 10–25 seconds)...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onCancel ?? () => Navigator.pop(ctx),
              child: const Text('Cancel Scan', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
