import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory_app_project/models/category_model.dart';
import 'package:inventory_app_project/models/inventory_model.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/models/supplier_model.dart';
import 'package:inventory_app_project/services/inventory_service.dart';
import 'package:inventory_app_project/services/product_service.dart';
import 'package:inventory_app_project/services/supplier_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

class _EditProductDraft {
  final String name;
  final String barcode;
  final String imageUrl;
  final int? costPrice;
  final int? sellingPrice;
  final int? threshold;
  final int? categoryId;
  final String? supplierId;

  const _EditProductDraft({
    required this.name,
    required this.barcode,
    required this.imageUrl,
    required this.costPrice,
    required this.sellingPrice,
    required this.threshold,
    required this.categoryId,
    required this.supplierId,
  });
}

class EditProductDialog {
  static Future<bool> show(
    BuildContext context, {
    required ProductModel product,
    required InventoryModel? inventory,
    required ProductService productService,
    required InventoryService inventoryService,
    required Map<int, CategoryModel> categoriesById,
    required Future<void> Function() onUpdated,
  }) async {
    final categories = categoriesById.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    List<SupplierModel> suppliers = const [];
    try {
      suppliers = await SupplierService().getSuppliersByStoreId(
        product.storeId,
      );
    } catch (e) {
      debugPrint('Failed to fetch suppliers for edit form: $e');
    }

    if (!context.mounted) return false;

    final draft =
        await showModalBottomSheet<_EditProductDraft>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _EditProductSheet(
            product: product,
            inventory: inventory,
            categories: categories,
            suppliers: suppliers,
          ),
        ) ??
        null;

    if (!context.mounted || draft == null) return false;

    final validationMessage = productService.validateProductName(draft.name);
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return false;
    }

    if (inventory != null) {
      final inventoryValidation = inventoryService.validateInventoryUpdateInput(
        costPrice: draft.costPrice,
        sellingPrice: draft.sellingPrice,
        threshold: draft.threshold,
      );
      if (inventoryValidation != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(inventoryValidation)));
        return false;
      }
    }

    final updatedProduct = productService.buildUpdatedProduct(
      original: product,
      name: draft.name,
      barcode: draft.barcode,
      imageUrl: draft.imageUrl,
      categoryId: draft.categoryId,
      supplierId: draft.supplierId,
    );
    final updatedInventory = inventoryService.buildUpdatedInventory(
      original: inventory,
      costPrice: draft.costPrice,
      sellingPrice: draft.sellingPrice,
      threshold: draft.threshold,
    );

    try {
      await productService.updateProduct(updatedProduct);
      if (updatedInventory != null) {
        await inventoryService.updateInventory(updatedInventory);
      }

      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully.')),
      );
      await onUpdated();
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update product: $e')));
      return false;
    }

    return false;
  }
}

class _EditProductSheet extends StatefulWidget {
  final ProductModel product;
  final InventoryModel? inventory;
  final List<CategoryModel> categories;
  final List<SupplierModel> suppliers;

  const _EditProductSheet({
    required this.product,
    required this.inventory,
    required this.categories,
    required this.suppliers,
  });

  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  final ProductService _productService = ProductService();

  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _costController;
  late final TextEditingController _sellingController;
  late final TextEditingController _thresholdController;

  int? _categoryId;
  String? _supplierId;
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;
  bool _hasSelectedImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _barcodeController = TextEditingController(
      text: widget.product.barcode ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.product.imageUrl ?? '',
    );
    _costController = TextEditingController(
      text: widget.inventory?.costPrice.toString() ?? '',
    );
    _sellingController = TextEditingController(
      text: widget.inventory?.sellingPrice.toString() ?? '',
    );
    _thresholdController = TextEditingController(
      text: widget.inventory?.lowStockThreshold.toString() ?? '',
    );
    _categoryId = widget.product.categoryId;
    _supplierId = widget.product.supplierId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _imageUrlController.dispose();
    _costController.dispose();
    _sellingController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _chooseImageSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pick from Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take from Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) return;
    await _pickAndUploadImage(source);
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();

      setState(() {
        _hasSelectedImage = true;
        _selectedImageBytes = bytes;
        _isUploadingImage = true;
      });

      _imageUrlController.clear();
      final publicUrl = await _productService.uploadProductImage(
        bytes: bytes,
        originalName: file.name,
      );

      if (!mounted) return;
      _imageUrlController.text = publicUrl;
      setState(() {
        _isUploadingImage = false;
      });
      _showSnack('Photo uploaded successfully.', success: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
      });
      _showSnack('Image upload failed: $e');
    }
  }

  void _save() {
    if (_isUploadingImage) return;

    final draft = _EditProductDraft(
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      costPrice: int.tryParse(_costController.text.trim()),
      sellingPrice: int.tryParse(_sellingController.text.trim()),
      threshold: int.tryParse(_thresholdController.text.trim()),
      categoryId: _categoryId,
      supplierId: _supplierId,
    );

    if (_hasSelectedImage && draft.imageUrl.isEmpty) {
      _showSnack('Please wait until the image upload finishes.');
      return;
    }

    Navigator.of(context).pop(draft);
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? const Color(0xFF16A34A)
            : AppColors.errorText,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final isDesktop = media.size.width >= 900;

    return FractionallySizedBox(
      heightFactor: isDesktop ? 0.93 : 0.97,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: Material(
          color: AppColors.cardBg,
          child: Column(
            children: [
              _TopBar(onClose: () => Navigator.of(context).pop(false)),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ImageHero(
                            isUploading: _isUploadingImage,
                            imageBytes: _selectedImageBytes,
                            imageUrl: _imageUrlController.text.trim(),
                            onTap: _chooseImageSource,
                          ),
                          const SizedBox(height: 20),
                          _SectionLabel('Product Name'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _nameController,
                            hint: 'e.g. Organic Honey Jar',
                            icon: Icons.label_outline,
                            required: true,
                          ),
                          const SizedBox(height: 14),
                          _ResponsiveTwoColumns(
                            left: _ColumnField(
                              label: 'Category',
                              child: _SelectField<int?>(
                                hint: 'Select category',
                                initialValue: _categoryId,
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('No category'),
                                  ),
                                  ...widget.categories.map(
                                    (c) => DropdownMenuItem<int?>(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() => _categoryId = v);
                                },
                              ),
                            ),
                            right: _ColumnField(
                              label: 'Supplier',
                              child: _SelectField<String?>(
                                hint: 'Select supplier',
                                initialValue: _supplierId,
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('No supplier'),
                                  ),
                                  ...widget.suppliers.map(
                                    (s) => DropdownMenuItem<String?>(
                                      value: s.id,
                                      child: Text(s.name),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() => _supplierId = v);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SectionLabel('Barcode'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _barcodeController,
                            hint: 'Scan or type manually',
                            icon: Icons.qr_code_rounded,
                          ),
                          if (widget.inventory != null) ...[
                            const SizedBox(height: 14),
                            _ResponsiveTwoColumns(
                              left: _ColumnField(
                                label: 'Cost Price',
                                child: _InputField(
                                  controller: _costController,
                                  hint: '0',
                                  icon: Icons.shopping_bag_outlined,
                                  required: true,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  prefixText: 'Rp ',
                                ),
                              ),
                              right: _ColumnField(
                                label: 'Selling Price',
                                child: _InputField(
                                  controller: _sellingController,
                                  hint: '0',
                                  icon: Icons.sell_outlined,
                                  required: true,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  prefixText: 'Rp ',
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _SectionLabel('Low Stock Threshold'),
                            const SizedBox(height: 8),
                            _InputField(
                              controller: _thresholdController,
                              hint: '5',
                              icon: Icons.warning_amber_outlined,
                              required: true,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              suffixText: 'unit',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _BottomActions(
                isUploadingImage: _isUploadingImage,
                canSaveAfterImagePick:
                    !_hasSelectedImage ||
                    _imageUrlController.text.trim().isNotEmpty,
                onCancel: () => Navigator.of(context).pop(),
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;

  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textMedium,
              tooltip: 'Back',
            ),
            const Text(
              'Edit Product',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            const Icon(Icons.edit_rounded, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        color: AppColors.textMedium,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ColumnField extends StatelessWidget {
  final String label;
  final Widget child;

  const _ColumnField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_SectionLabel(label), const SizedBox(height: 8), child],
    );
  }
}

class _ResponsiveTwoColumns extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _ResponsiveTwoColumns({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 14),
              Expanded(child: right),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: 14), right],
        );
      },
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool required;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final String? suffixText;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.prefixText,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: required ? '$hint *' : hint,
        hintStyle: const TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textLight),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: AppColors.textMedium,
          fontWeight: FontWeight.w700,
        ),
        suffixText: suffixText,
        suffixStyle: const TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _SelectField<T> extends StatelessWidget {
  final String hint;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _SelectField({
    required this.hint,
    required this.initialValue,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      items: items,
      onChanged: onChanged,
      icon: const Icon(Icons.expand_more_rounded, color: AppColors.textLight),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      dropdownColor: AppColors.cardBg,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _ImageHero extends StatelessWidget {
  final bool isUploading;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final VoidCallback onTap;

  const _ImageHero({
    required this.isUploading,
    required this.imageBytes,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(imageBytes!, fit: BoxFit.cover),
              )
            else if (imageUrl != null && imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha:
                      imageBytes != null ||
                          (imageUrl != null && imageUrl!.isNotEmpty)
                      ? 0.28
                      : 0,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  isUploading ? 'Uploading photo...' : 'Update Product Photo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PNG, JPG up to 10MB',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final bool isUploadingImage;
  final bool canSaveAfterImagePick;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _BottomActions({
    required this.isUploadingImage,
    required this.canSaveAfterImagePick,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: (isUploadingImage || !canSaveAfterImagePick)
                      ? null
                      : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    isUploadingImage
                        ? Icons.cloud_upload_outlined
                        : Icons.save_outlined,
                    size: 20,
                  ),
                  label: Text(
                    isUploadingImage
                        ? 'Uploading Image...'
                        : (canSaveAfterImagePick
                              ? 'Save Changes'
                              : 'Upload image first'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMedium,
                    side: const BorderSide(color: AppColors.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
