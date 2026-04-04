import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

class AddOrderProductOption {
  final String productId;
  final String productName;
  final int currentStock;
  final int unitPrice;

  const AddOrderProductOption({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.unitPrice,
  });
}

class AddOrderInput {
  final String productId;
  final int quantity;
  final String status;
  final String unitType;

  const AddOrderInput({
    required this.productId,
    required this.quantity,
    required this.status,
    required this.unitType,
  });
}

class AddOrderDialog {
  static const List<String> _statuses = <String>[
    'PROCESSING',
    'SHIPPED',
    'DELIVERED',
    'CANCELLED',
  ];

  static const List<String> _unitTypes = <String>[
    'pcs',
    'pack',
    'box',
    'unit',
  ];

  static Future<AddOrderInput?> show(
    BuildContext context, {
    required List<AddOrderProductOption> products,
    AddOrderInput? initialValue,
    bool allowProductChange = true,
    String title = 'Add Purchase Order',
    String subtitle = 'Record incoming stock from supplier',
    String confirmLabel = 'Create',
  }) async {
    if (products.isEmpty) {
      return null;
    }

    String? selectedProductId = initialValue?.productId ?? products.first.productId;
    final quantityController = TextEditingController(
      text: (initialValue?.quantity ?? 1).toString(),
    );
    String selectedStatus = initialValue?.status ?? _statuses.first;
    String selectedUnitType = initialValue?.unitType ?? _unitTypes.first;
    String? errorText;

    final input = await showModalBottomSheet<AddOrderInput>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            AddOrderProductOption selectedProduct = products.firstWhere(
              (product) => product.productId == selectedProductId,
              orElse: () => products.first,
            );

            String formatCurrency(int value) {
              final text = value.toString();
              final buffer = StringBuffer();
              for (int i = 0; i < text.length; i++) {
                final pos = text.length - i;
                buffer.write(text[i]);
                if (pos > 1 && pos % 3 == 1) {
                  buffer.write('.');
                }
              }
              return 'Rp$buffer';
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFFC87F2E),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (allowProductChange)
                          DropdownButtonFormField<String>(
                            initialValue: selectedProductId,
                            decoration: const InputDecoration(
                              labelText: 'Product',
                            ),
                            items: products
                                .map(
                                  (product) => DropdownMenuItem<String>(
                                    value: product.productId,
                                    child: Text(product.productName),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setModalState(() {
                                selectedProductId = value;
                                errorText = null;
                              });
                            },
                          )
                        else
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Product',
                            ),
                            child: Text(
                              selectedProduct.productName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _OrderMetric(
                                  label: 'Current Stock',
                                  value: '${selectedProduct.currentStock} pcs',
                                ),
                              ),
                              Expanded(
                                child: _OrderMetric(
                                  label: 'Unit Cost',
                                  value: formatCurrency(selectedProduct.unitPrice),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            hintText: 'Enter quantity',
                          ),
                          onChanged: (_) {
                            if (errorText == null) return;
                            setModalState(() => errorText = null);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: _statuses
                              .map(
                                (status) => DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() => selectedStatus = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedUnitType,
                          decoration: const InputDecoration(
                            labelText: 'Unit Type',
                          ),
                          items: _unitTypes
                              .map(
                                (unit) => DropdownMenuItem<String>(
                                  value: unit,
                                  child: Text(unit),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() => selectedUnitType = value);
                          },
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            errorText!,
                            style: const TextStyle(
                              color: AppColors.errorText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                onPressed: () {
                                  final quantity =
                                      int.tryParse(quantityController.text.trim()) ?? 0;
                                  if (quantity <= 0) {
                                    setModalState(() {
                                      errorText = 'Quantity must be greater than zero.';
                                    });
                                    return;
                                  }

                                  Navigator.of(context).pop(
                                    AddOrderInput(
                                      productId: selectedProduct.productId,
                                      quantity: quantity,
                                      status: selectedStatus,
                                      unitType: selectedUnitType,
                                    ),
                                  );
                                },
                                child: Text(confirmLabel),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    quantityController.dispose();
    return input;
  }
}

class _OrderMetric extends StatelessWidget {
  final String label;
  final String value;

  const _OrderMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
