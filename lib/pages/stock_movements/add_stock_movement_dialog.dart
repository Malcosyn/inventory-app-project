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
		final qtyController = TextEditingController();
		final noteController = TextEditingController();
		String selectedReason = isStockIn ? 'PURCHASE' : 'SALE';

		final input = await showDialog<AddStockMovementInput>(
			context: context,
			builder: (context) {
				return AlertDialog(
					backgroundColor: AppColors.cardBg,
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(18),
					),
					title: Text(isStockIn ? 'Stock In' : 'Stock Out'),
					contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
					content: SingleChildScrollView(
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								TextField(
									controller: qtyController,
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
											initialValue: selectedReason,
											decoration: const InputDecoration(
												labelText: 'Reason',
											),
											items: _reasons
												.map(
													(reason) => DropdownMenuItem<String>(
														value: reason,
														child: Text(reason),
													),
												)
												.toList(),
											onChanged: (value) {
												if (value == null) return;
												setModalState(() => selectedReason = value);
											},
										);
									},
								),
								const SizedBox(height: 10),
								TextField(
									controller: noteController,
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
							onPressed: () {
								final parsed = int.tryParse(qtyController.text.trim());
								if (parsed == null || parsed <= 0) return;
								Navigator.of(context).pop(
									AddStockMovementInput(
										quantity: parsed,
										reason: selectedReason,
										note: noteController.text.trim(),
									),
								);
							},
							child: const Text('Save'),
						),
					],
				);
			},
		);

		qtyController.dispose();
		noteController.dispose();
		return input;
	}
}
