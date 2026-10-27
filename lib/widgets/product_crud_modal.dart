import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/camera_scan_service.dart';
import '../services/gemini_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class ProductCrudModal extends StatefulWidget {
  final Product? productToEdit;
  final Function(Product) onSave;
  final AppState? state;

  const ProductCrudModal({
    super.key,
    this.productToEdit,
    required this.onSave,
    this.state,
  });

  @override
  State<ProductCrudModal> createState() => _ProductCrudModalState();
}

class _ProductCrudModalState extends State<ProductCrudModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _sourceController;
  late TextEditingController _strengthController;
  late TextEditingController _descController;
  late TextEditingController _reviewController;
  late TextEditingController _totalGramsController;
  late TextEditingController _remainingGramsController;
  late TextEditingController _priceController;

  late String _selectedType;
  late double _rating;
  late DateTime _datePurchased;
  DateTime? _dateOpened;
  DateTime? _dateFinished;
  
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;

    _nameController = TextEditingController(text: p?.name ?? '');
    _sourceController = TextEditingController(text: p?.source ?? '');
    _strengthController = TextEditingController(text: p?.strength ?? '22.5% THC');
    _descController = TextEditingController(text: p?.description ?? '');
    _reviewController = TextEditingController(text: p?.reviewNotes ?? '');
    _totalGramsController = TextEditingController(text: p?.totalGrams.toString() ?? '14.0');
    _remainingGramsController = TextEditingController(text: p?.remainingGrams.toString() ?? '14.0');
    _priceController = TextEditingController(text: p?.price.toString() ?? '120.0');

    _selectedType = p?.type ?? 'Hybrid';
    _rating = p?.rating ?? 9.0;
    _datePurchased = p?.datePurchased ?? DateTime.now();
    _dateOpened = p?.dateOpened ?? DateTime.now();
    _dateFinished = p?.dateFinished;

      }

  @override
  void dispose() {
    _nameController.dispose();
    _sourceController.dispose();
    _strengthController.dispose();
    _descController.dispose();
    _reviewController.dispose();
    _totalGramsController.dispose();
    _remainingGramsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime initialDate, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surfaceElevation2,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  bool _isScanning = false;

  Future<void> _triggerCameraScan() async {
    // 0. Ensure API key if state is available
    if (widget.state != null && !widget.state!.geminiService.hasApiKey) {
      final configured = await CameraScanService.ensureApiKey(context, widget.state!);
      if (!configured || !mounted) return;
    }

    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 60,
    );

    if (photo == null || !mounted) return;

    setState(() => _isScanning = true);

    try {
      final bytes = await photo.readAsBytes();
      final gemini = widget.state?.geminiService ?? GeminiService();
      final extracted = await gemini.extractPackagingLabel(bytes);

      if (!mounted) return;

      setState(() {
        _nameController.text = extracted['name'] ?? _nameController.text;
        _sourceController.text = extracted['source'] ?? _sourceController.text;
        _strengthController.text = extracted['strength'] ?? _strengthController.text;
        _descController.text = extracted['description'] ?? _descController.text;
        final grams = extracted['remainingGrams']?.toString() ?? '14.0';
        _remainingGramsController.text = grams;
        _totalGramsController.text = grams;
        if (['Indica', 'Sativa', 'Hybrid', 'Extract'].contains(extracted['type'])) {
          _selectedType = extracted['type'];
        }
        if (extracted['rating'] != null && extracted['rating'] is num) {
          _rating = (extracted['rating'] as num).toDouble();
        }
        _isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Packaging extracted: ${extracted['name']}!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceElevation2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
              SizedBox(width: 8),
              Text('Packaging Scan Error', style: TextStyle(fontSize: 16, color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              '$e',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevation2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.borderHover, width: 1)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Product' : 'Add New Stash Item',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick Camera Scan Banner
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.surfaceElevation1,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isScanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isScanning ? 'Analyzing Packaging Label...' : 'Scan Packaging with Camera',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            _isScanning ? 'Extracting strain, THC %, & weight...' : 'Auto-fill fields with Gemini Vision',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!_isScanning)
                      ElevatedButton.icon(
                        onPressed: _triggerCameraScan,
                        icon: const Icon(Icons.photo_camera_rounded, size: 14),
                        label: const Text('Scan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                      ),
                  ],
                ),
              ),

              // Product Name
              _buildFieldLabel('Product / Strain Name'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('e.g. Pineapple Express, Ghost OG'),
                validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),

              // Source / Dispensary
              _buildFieldLabel('Source / Dispensary / Brand'),
              TextFormField(
                controller: _sourceController,
                decoration: _inputDecoration('e.g. Apex Botanicals, Green Horizon'),
                validator: (val) => val == null || val.isEmpty ? 'Source is required' : null,
              ),
              const SizedBox(height: 14),

              // Herb Type Chips
              _buildFieldLabel('Herb Type'),
              Wrap(
                spacing: 8,
                children: ['Hybrid', 'Indica', 'Sativa', 'Extract'].map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedType = type);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevation1,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Strength & Price Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Potency / Strength'),
                        TextFormField(
                          controller: _strengthController,
                          decoration: _inputDecoration('24.5% THC'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Price (\$)'),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('120.0'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Grams: Total & Remaining
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Total Stash (g)'),
                        TextFormField(
                          controller: _totalGramsController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('28.0'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Remaining (g)'),
                        TextFormField(
                          controller: _remainingGramsController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('14.2'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Rating (1-10 Slider)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFieldLabel('Quality Rating (1-10 Stars)'),
                  Text(
                    '★ ${_rating.toStringAsFixed(1)} / 10',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _rating,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceElevation1,
                label: _rating.toStringAsFixed(1),
                onChanged: (val) => setState(() => _rating = val),
              ),
              const SizedBox(height: 10),

              // Dates Lifecycle Section
              _buildFieldLabel('Lifecycle Tracking Dates'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevation1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildDateRow(
                      'Purchased',
                      _dateFormat.format(_datePurchased),
                      () => _selectDate(context, _datePurchased, (d) => setState(() => _datePurchased = d)),
                    ),
                    const Divider(color: AppColors.border, height: 16),
                    _buildDateRow(
                      'Opened',
                      _dateOpened != null ? _dateFormat.format(_dateOpened!) : 'Not opened yet',
                      () => _selectDate(context, _dateOpened ?? DateTime.now(), (d) => setState(() => _dateOpened = d)),
                      trailingToggle: Switch(
                        value: _dateOpened != null,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _dateOpened = val ? DateTime.now() : null;
                          });
                        },
                      ),
                    ),
                    if (_dateOpened != null) ...[
                      const Divider(color: AppColors.border, height: 16),
                      _buildDateRow(
                        'Finished',
                        _dateFinished != null ? _dateFormat.format(_dateFinished!) : 'Currently Active',
                        () => _selectDate(context, _dateFinished ?? DateTime.now(), (d) => setState(() => _dateFinished = d)),
                        trailingToggle: Switch(
                          value: _dateFinished != null,
                          activeThumbColor: AppColors.error,
                          onChanged: (val) {
                            setState(() {
                              _dateFinished = val ? DateTime.now() : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Description
              _buildFieldLabel('Description & Lineage'),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: _inputDecoration('Aroma profile, terpene characteristics...'),
              ),
              const SizedBox(height: 14),

              // Review / Notes
              _buildFieldLabel('Review & Tasting Notes'),
              TextFormField(
                controller: _reviewController,
                maxLines: 2,
                decoration: _inputDecoration('Personal experiential notes, effects breakdown...'),
              ),
              const SizedBox(height: 24),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add to Stash Vault',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.surfaceElevation1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _buildDateRow(String label, String value, VoidCallback onPick, {Widget? trailingToggle}) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onPick,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '$label: ',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        ?trailingToggle,
      ],
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      id: widget.productToEdit?.id ?? 'prod-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      source: _sourceController.text.trim(),
      type: _selectedType,
      strength: _strengthController.text.trim(),
      description: _descController.text.trim(),
      reviewNotes: _reviewController.text.trim(),
      datePurchased: _datePurchased,
      dateOpened: _dateOpened,
      dateFinished: _dateFinished,
      rating: _rating,
      totalGrams: double.tryParse(_totalGramsController.text) ?? 14.0,
      remainingGrams: double.tryParse(_remainingGramsController.text) ?? 14.0,
      price: double.tryParse(_priceController.text) ?? 120.0,
      isFavorite: widget.productToEdit?.isFavorite ?? false,
    );

    widget.onSave(product);
    Navigator.pop(context);
  }
}
