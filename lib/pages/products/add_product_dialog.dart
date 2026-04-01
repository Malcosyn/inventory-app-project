import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory_app_project/models/category_model.dart';
import 'package:inventory_app_project/models/supplier_model.dart';
import 'package:inventory_app_project/services/inventory_service.dart';
import 'package:inventory_app_project/services/product_service.dart';
import 'package:inventory_app_project/services/stock_movement_service.dart';
import 'package:inventory_app_project/services/supplier_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _C {
  static const bg = Color(0xFFFCF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFD5C2AB);
  static const inputBg = Color(0xFFF7F3EF);
  static const ink = Color(0xFF1A1612);
  static const inkMid = Color(0xFF4D4639);
  static const inkLight = Color(0xFF85735E);
  static const primary = Color(0xFFD9A05B);
  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFBA1A1A);
}

class AddProductDialog {
  static const int _defaultStoreId = 1;

  static Future<bool> show(
    BuildContext context, {
    required Map<int, CategoryModel> categoriesById,
    required VoidCallback onProductAdded,
  }) async {
    final nameController = TextEditingController();
    final barcodeController = TextEditingController();
    final imageUrlController = TextEditingController();
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final thresholdController = TextEditingController(text: '5');

    int? selectedCategoryId;
    String? selectedSupplierId;

    final categories = categoriesById.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    List<SupplierModel> suppliers = const [];
    try {
      suppliers = await SupplierService().getSuppliersByStoreId(_defaultStoreId);
    } catch (e) {
      debugPrint('Failed to fetch suppliers for create form: $e');
    }

    if (!context.mounted) return false;

    final shouldCreate = await showModalBottomSheet<bool>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _AddProductSheet(
            categories: categories,
            suppliers: suppliers,
            nameController: nameController,
            barcodeController: barcodeController,
            imageUrlController: imageUrlController,
            costPriceController: costPriceController,
            sellingPriceController: sellingPriceController,
            stockController: stockController,
            thresholdController: thresholdController,
            onCategoryChanged: (v) => selectedCategoryId = v,
            onSupplierChanged: (v) => selectedSupplierId = v,
          ),
        ) ??
        false;

    final name = nameController.text.trim();
    final barcode = barcodeController.text.trim();
    final imageUrl = imageUrlController.text.trim();
    final costPrice = int.tryParse(costPriceController.text.trim());
    final sellingPrice = int.tryParse(sellingPriceController.text.trim());
    final initialStock = int.tryParse(stockController.text.trim());
    final threshold = int.tryParse(thresholdController.text.trim());

    nameController.dispose();
    barcodeController.dispose();
    imageUrlController.dispose();
    costPriceController.dispose();
    sellingPriceController.dispose();
    stockController.dispose();
    thresholdController.dispose();

    if (!context.mounted || !shouldCreate) return false;

    if (name.isEmpty) {
      _snack(context, 'Nama produk wajib diisi.');
      return false;
    }

    if (costPrice == null ||
        sellingPrice == null ||
        initialStock == null ||
        threshold == null) {
      _snack(context, 'Field angka wajib diisi dengan benar.');
      return false;
    }

    if (costPrice < 0 || sellingPrice < 0 || initialStock < 0 || threshold < 0) {
      _snack(context, 'Nilai angka tidak boleh negatif.');
      return false;
    }

    try {
      final productId = await ProductService().createProductEntry(
        storeId: _defaultStoreId,
        name: name,
        categoryId: selectedCategoryId,
        supplierId: selectedSupplierId,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        barcode: barcode.isEmpty ? null : barcode,
      );

      await InventoryService().createInventoryEntry(
        productId: productId,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        stockQuantity: initialStock,
        lowStockThreshold: threshold,
        storeId: _defaultStoreId,
      );

      if (initialStock > 0) {
        await StockMovementService().createStockMovementEntry(
          productId: productId,
          type: 'IN',
          quantity: initialStock,
          stockAfter: initialStock,
          note: 'Initial stock saat tambah item',
          storeId: _defaultStoreId,
        );
      }

      if (!context.mounted) return false;
      _snack(context, 'Item berhasil ditambahkan ke gudang.', success: true);
      onProductAdded();
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      _snack(context, 'Gagal menambah item: $e');
      return false;
    }
  }

  static void _snack(BuildContext context, String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: success ? _C.success : _C.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}

class _AddProductSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<SupplierModel> suppliers;
  final TextEditingController nameController;
  final TextEditingController barcodeController;
  final TextEditingController imageUrlController;
  final TextEditingController costPriceController;
  final TextEditingController sellingPriceController;
  final TextEditingController stockController;
  final TextEditingController thresholdController;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<String?> onSupplierChanged;

  const _AddProductSheet({
    required this.categories,
    required this.suppliers,
    required this.nameController,
    required this.barcodeController,
    required this.imageUrlController,
    required this.costPriceController,
    required this.sellingPriceController,
    required this.stockController,
    required this.thresholdController,
    required this.onCategoryChanged,
    required this.onSupplierChanged,
  });

  @override
  State<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<_AddProductSheet> {
  static const List<String> _storageBuckets = <String>[
    'PRODUCT-IMAGES',
    'product-images',
    'PRODUCT_BUCK',
    'product_buck',
    'products',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  int? _categoryId;
  String? _supplierId;
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;
  bool _hasSelectedImage = false;

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
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil dari Kamera'),
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
      final ext = _resolveExtension(file.name);
      final fileName =
          'product_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}.$ext';
      final storagePath = 'uploads/$fileName';

      setState(() {
        _hasSelectedImage = true;
        _selectedImageBytes = bytes;
        _isUploadingImage = true;
      });

      widget.imageUrlController.clear();
      final publicUrl = await _uploadWithFallback(
        storagePath: storagePath,
        bytes: bytes,
        ext: ext,
      );

      if (!mounted) return;
      widget.imageUrlController.text = publicUrl;
      setState(() {
        _isUploadingImage = false;
      });
      _showSnack('Foto berhasil diupload.', success: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
      });
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      _showSnack(
        'Upload gambar gagal. Login: ${isLoggedIn ? 'ya' : 'tidak'}. Error: $e',
      );
    }
  }

  Future<String> _uploadWithFallback({
    required String storagePath,
    required Uint8List bytes,
    required String ext,
  }) async {
    final errors = <String>[];

    for (final bucket in _storageBuckets) {
      try {
        final storage = Supabase.instance.client.storage.from(bucket);
        await storage.uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFor(ext),
          ),
        );
        return storage.getPublicUrl(storagePath);
      } catch (e) {
        errors.add('$bucket: $e');
      }
    }

    throw Exception(
      'Semua bucket upload gagal (${_storageBuckets.join(', ')}). ${errors.join(' | ')}',
    );
  }

  String _resolveExtension(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return 'jpg';
    final ext = parts.last.toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg' || ext == 'png' || ext == 'webp') {
      return ext;
    }
    return 'jpg';
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? _C.success : _C.danger,
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
          color: _C.bg,
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
                            imageUrl: widget.imageUrlController.text.trim(),
                            onTap: _chooseImageSource,
                          ),
                          const SizedBox(height: 20),
                          _SectionLabel('Product Name'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: widget.nameController,
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
                                    child: Text('Tanpa kategori'),
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
                                  widget.onCategoryChanged(v);
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
                                    child: Text('Tanpa supplier'),
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
                                  widget.onSupplierChanged(v);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SectionLabel('Barcode'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: widget.barcodeController,
                            hint: 'Scan atau ketik manual',
                            icon: Icons.qr_code_rounded,
                          ),
                          const SizedBox(height: 14),
                          _ResponsiveTwoColumns(
                            left: _ColumnField(
                              label: 'Harga Modal',
                              child: _InputField(
                                controller: widget.costPriceController,
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
                              label: 'Harga Jual',
                              child: _InputField(
                                controller: widget.sellingPriceController,
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
                              label: 'Stok Awal',
                              child: _InputField(
                                controller: widget.stockController,
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
                              label: 'Batas Stok Rendah',
                              child: _InputField(
                                controller: widget.thresholdController,
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
                    !_hasSelectedImage || widget.imageUrlController.text.trim().isNotEmpty,
                onCancel: () => Navigator.of(context).pop(false),
                onSave: () => Navigator.of(context).pop(true),
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
      color: _C.bg,
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.arrow_back_rounded),
              color: _C.inkMid,
              tooltip: 'Kembali',
            ),
            const Text(
              'Add New Item',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _C.ink,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.inventory_2_outlined,
              color: _C.primary,
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
          color: _C.inputBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
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
                    color: _C.surface,
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
                      : const Icon(Icons.add_a_photo_outlined, color: _C.primary),
                ),
                const SizedBox(height: 10),
                Text(
                  isUploading ? 'Uploading photo...' : 'Upload Product Photo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _C.inkMid,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PNG, JPG up to 10MB',
                  style: TextStyle(fontSize: 12, color: _C.inkLight),
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
        color: _C.inkMid,
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
        color: _C.ink,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _C.inputBg,
        hintText: required ? '$hint *' : hint,
        hintStyle: const TextStyle(
          color: _C.inkLight,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, size: 20, color: _C.inkLight),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: _C.inkMid,
          fontWeight: FontWeight.w700,
        ),
        suffixText: suffixText,
        suffixStyle: const TextStyle(
          color: _C.inkLight,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x20000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.primary, width: 1.6),
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
      icon: const Icon(Icons.expand_more_rounded, color: _C.inkLight),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _C.ink,
      ),
      dropdownColor: _C.surface,
      decoration: InputDecoration(
        filled: true,
        fillColor: _C.inputBg,
        hintText: hint,
        hintStyle: const TextStyle(
          color: _C.inkLight,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x20000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.primary, width: 1.6),
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
        color: _C.surface,
        border: Border(top: BorderSide(color: Color(0x14000000))),
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
                    backgroundColor: _C.primary,
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
                        : (canSaveAfterImagePick ? 'Save Item' : 'Upload gambar dulu'),
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
                    foregroundColor: _C.inkMid,
                    side: const BorderSide(color: _C.border),
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
