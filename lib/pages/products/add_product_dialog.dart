import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory_app_project/models/category_model.dart';
import 'package:inventory_app_project/models/supplier_model.dart';
import 'package:inventory_app_project/services/category_service.dart';
import 'package:inventory_app_project/services/inventory_service.dart';
import 'package:inventory_app_project/services/product_service.dart';
import 'package:inventory_app_project/services/stock_movement_service.dart';
import 'package:inventory_app_project/services/supplier_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

class AddProductDialogResult {
  final bool created;
  final String? message;

  const AddProductDialogResult({required this.created, this.message});
}

class AddProductFormData {
  final String name;
  final String barcode;
  final String imageUrl;
  final String costPriceText;
  final String sellingPriceText;
  final String stockText;
  final String thresholdText;
  final int? categoryId;
  final String? supplierId;

  const AddProductFormData({
    required this.name,
    required this.barcode,
    required this.imageUrl,
    required this.costPriceText,
    required this.sellingPriceText,
    required this.stockText,
    required this.thresholdText,
    required this.categoryId,
    required this.supplierId,
  });
}

class AddProductDialog {
  static const int _defaultStoreId = 1;

  static Future<AddProductDialogResult> show(
    BuildContext context, {
    required Map<int, CategoryModel> categoriesById,
  }) async {
    final categoryService = CategoryService();
    final supplierService = SupplierService();
    final productService = ProductService();
    final inventoryService = InventoryService();
    final stockMovementService = StockMovementService();

    List<CategoryModel> categories = const [];
    try {
      categories = await categoryService.getCategoriesByStoreId(_defaultStoreId);
    } catch (e) {
      debugPrint('Failed to fetch latest categories for create form: $e');
      categories = categoriesById.values.toList();
    }
    categories.sort((a, b) => a.name.compareTo(b.name));

    List<SupplierModel> suppliers = const [];
    try {
      suppliers = await supplierService.getSuppliersByStoreId(_defaultStoreId);
    } catch (e) {
      debugPrint('Failed to fetch suppliers for create form: $e');
    }

    if (!context.mounted) {
      return const AddProductDialogResult(created: false);
    }

    final formData = await showModalBottomSheet<AddProductFormData>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _AddProductSheet(
            categories: categories,
            suppliers: suppliers,
          ),
        ) ??
        null;

    if (!context.mounted || formData == null) {
      return const AddProductDialogResult(created: false);
    }

    final name = formData.name.trim();
    final barcode = formData.barcode.trim();
    final imageUrl = formData.imageUrl.trim();
    final costPrice = int.tryParse(formData.costPriceText.trim());
    final sellingPrice = int.tryParse(formData.sellingPriceText.trim());
    final initialStock = int.tryParse(formData.stockText.trim());
    final threshold = int.tryParse(formData.thresholdText.trim());

    final nameError = productService.validateProductName(name);
    if (nameError != null) {
      return AddProductDialogResult(created: false, message: nameError);
    }

    final inventoryError = inventoryService.validateInventoryCreateInput(
      costPrice: costPrice,
      sellingPrice: sellingPrice,
      initialStock: initialStock,
      threshold: threshold,
    );
    if (inventoryError != null) {
      return AddProductDialogResult(created: false, message: inventoryError);
    }

    if (formData.categoryId != null) {
      final validCategory = categories.any((c) => c.id == formData.categoryId);
      if (!validCategory) {
        return const AddProductDialogResult(
          created: false,
          message: 'Selected category is no longer available. Please choose another category.',
        );
      }
    }

    try {
      await productService.createProductWithInventory(
        storeId: _defaultStoreId,
        name: name,
        costPrice: costPrice!,
        sellingPrice: sellingPrice!,
        initialStock: initialStock!,
        threshold: threshold!,
        categoryId: formData.categoryId,
        supplierId: formData.supplierId,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        barcode: barcode.isEmpty ? null : barcode,
        inventoryService: inventoryService,
        stockMovementService: stockMovementService,
      );

      if (!context.mounted) {
        return const AddProductDialogResult(created: false);
      }
      return const AddProductDialogResult(
        created: true,
        message: 'Item added to warehouse successfully.',
      );
    } catch (e) {
      if (!context.mounted) {
        return const AddProductDialogResult(created: false);
      }

      final errorText = e.toString();
      if (errorText.contains('products_category_id_fkey') ||
          errorText.contains('foreign key constraint')) {
        return const AddProductDialogResult(
          created: false,
          message: 'Category is invalid or has been deleted. Please select a valid category.',
        );
      }

      return AddProductDialogResult(
        created: false,
        message: 'Failed to add item: $errorText',
      );
    }
  }
}

class _AddProductSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<SupplierModel> suppliers;

  const _AddProductSheet({
    required this.categories,
    required this.suppliers,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  final ProductService _productService = ProductService();
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _thresholdController;

  int? _categoryId;
  String? _supplierId;
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;
  bool _hasSelectedImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _barcodeController = TextEditingController();
    _imageUrlController = TextEditingController();
    _costPriceController = TextEditingController();
    _sellingPriceController = TextEditingController();
    _stockController = TextEditingController(text: '0');
    _thresholdController = TextEditingController(text: '5');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _imageUrlController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
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

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF16A34A) : AppColors.errorText,
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
              _TopBar(onClose: () => Navigator.of(context).pop()),
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
                          const SizedBox(height: 14),
                          _ResponsiveTwoColumns(
                            left: _ColumnField(
                              label: 'Cost Price',
                              child: _InputField(
                                controller: _costPriceController,
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
                                controller: _sellingPriceController,
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
                          _ResponsiveTwoColumns(
                            left: _ColumnField(
                              label: 'Initial Stock',
                              child: _InputField(
                                controller: _stockController,
                                hint: '0',
                                icon: Icons.inventory_2_outlined,
                                required: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                suffixText: 'unit',
                              ),
                            ),
                            right: _ColumnField(
                              label: 'Low Stock Threshold',
                              child: _InputField(
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _BottomActions(
                isUploadingImage: _isUploadingImage,
                canSaveAfterImagePick:
                    !_hasSelectedImage || _imageUrlController.text.trim().isNotEmpty,
                onCancel: () => Navigator.of(context).pop(),
                onSave: () => Navigator.of(context).pop(
                  AddProductFormData(
                    name: _nameController.text.trim(),
                    barcode: _barcodeController.text.trim(),
                    imageUrl: _imageUrlController.text.trim(),
                    costPriceText: _costPriceController.text.trim(),
                    sellingPriceText: _sellingPriceController.text.trim(),
                    stockText: _stockController.text.trim(),
                    thresholdText: _thresholdController.text.trim(),
                    categoryId: _categoryId,
                    supplierId: _supplierId,
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
              'Add New Item',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ],
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
                  alpha: imageBytes != null || (imageUrl != null && imageUrl!.isNotEmpty)
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
                      : const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                Text(
                  isUploading ? 'Uploading photo...' : 'Upload Product Photo',
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
      children: [
        _SectionLabel(label),
        const SizedBox(height: 8),
        child,
      ],
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
          children: [
            left,
            const SizedBox(height: 14),
            right,
          ],
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                  onPressed: (isUploadingImage || !canSaveAfterImagePick) ? null : onSave,
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
                        : Icons.check_circle_outline_rounded,
                    size: 20,
                  ),
                  label: Text(
                    isUploadingImage
                        ? 'Uploading Image...'
                        : (canSaveAfterImagePick ? 'Save Item' : 'Upload image first'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
