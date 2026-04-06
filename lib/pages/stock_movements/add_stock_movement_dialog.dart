import 'package:flutter/material.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

class AddStockMovementInput {
  final int quantity;
  final String reason;
  final String note;

  const AddStockMovementInput({
    required this.quantity,
    required this.reason,
    required this.note,
  });
}

class AddStockMovementDialog {
  static const List<String> _reasons = <String>[
    'PURCHASE',
    'SALE',
    'ADJUSTMENT',
    'RETURN',
    'DAMAGE',
  ];

  static Future<AddStockMovementInput?> show(
    BuildContext context, {
    required bool isStockIn,
  }) async {
    return showDialog<AddStockMovementInput>(
      context: context,
      builder: (_) => _AddStockMovementDialogSheet(isStockIn: isStockIn),
    );
  }
}

class _AddStockMovementDialogSheet extends StatefulWidget {
  final bool isStockIn;

  const _AddStockMovementDialogSheet({required this.isStockIn});

  @override
  State<_AddStockMovementDialogSheet> createState() =>
      _AddStockMovementDialogSheetState();
}

class _AddStockMovementDialogSheetState
    extends State<_AddStockMovementDialogSheet> {
  late final TextEditingController _qtyController;
  late final TextEditingController _noteController;
  late String _selectedReason;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController();
    _noteController = TextEditingController();
    _selectedReason = widget.isStockIn ? 'PURCHASE' : 'SALE';
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = int.tryParse(_qtyController.text.trim());
    if (parsed == null || parsed <= 0) return;

    Navigator.of(context).pop(
      AddStockMovementInput(
        quantity: parsed,
        reason: _selectedReason,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(widget.isStockIn ? 'Stock In' : 'Stock Out'),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'Enter quantity',
              ),
            ),
            const SizedBox(height: 10),
            StatefulBuilder(
              builder: (context, setModalState) {
                return DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  items: AddStockMovementDialog._reasons
                      .map(
                        (reason) => DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => _selectedReason = value);
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Example: Supplier return / Offline sale',
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.textMedium),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
