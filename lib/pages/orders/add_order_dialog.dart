import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/product_model.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

class AddOrderInput {
	final String productId;
	final int totalPrice;
	final int totalItem;
	final String status;
	final String unitType;

	const AddOrderInput({
		required this.productId,
		required this.totalPrice,
		required this.totalItem,
		required this.status,
		required this.unitType,
	});
}

class AddOrderDialog extends StatefulWidget {
	final List<ProductModel> products;

	const AddOrderDialog({super.key, required this.products});

	static Future<AddOrderInput?> show(
		BuildContext context, {
		required List<ProductModel> products,
	}) {
		return showDialog<AddOrderInput>(
			context: context,
			builder: (_) => AddOrderDialog(products: products),
		);
	}

	@override
	State<AddOrderDialog> createState() => _AddOrderDialogState();
}

class _AddOrderDialogState extends State<AddOrderDialog> {
	static const List<_StatusOption> _statusOptions = [
		_StatusOption(label: 'Processing', value: 'PROCESSING'),
		_StatusOption(label: 'Shipped', value: 'SHIPPED'),
		_StatusOption(label: 'Delivered', value: 'DELIVERED'),
		_StatusOption(label: 'Cancelled', value: 'CANCELLED'),
	];
	static const List<String> _unitTypeOptions = [
		'pcs',
		'box',
		'pack',
		'kg',
		'liter',
	];

	final TextEditingController _totalItemController = TextEditingController();
	final TextEditingController _totalPriceController = TextEditingController();

	String? _selectedProductId;
	String _selectedStatus = _statusOptions.first.value;
	String _selectedUnitType = _unitTypeOptions.first;

	@override
	void initState() {
		super.initState();
		if (widget.products.isNotEmpty) {
			_selectedProductId = widget.products.first.id;
		}
	}

	@override
	void dispose() {
		_totalItemController.dispose();
		_totalPriceController.dispose();
		super.dispose();
	}

	void _save() {
		final productId = _selectedProductId;
		final totalItem = int.tryParse(_totalItemController.text.trim()) ?? 0;
		final totalPrice = int.tryParse(_totalPriceController.text.trim()) ?? 0;

		if (productId == null || productId.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please select a product.')),
			);
			return;
		}

		if (totalItem <= 0 || totalPrice <= 0) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Total item and total price must be greater than zero.')),
			);
			return;
		}

		Navigator.of(context).pop(
			AddOrderInput(
				productId: productId,
				totalPrice: totalPrice,
				totalItem: totalItem,
				status: _selectedStatus,
				unitType: _selectedUnitType,
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			backgroundColor: AppColors.cardBg,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
			title: const Text('Add Order'),
			contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
			content: SingleChildScrollView(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						DropdownButtonFormField<String>(
							value: _selectedProductId,
							isExpanded: true,
							decoration: const InputDecoration(labelText: 'Product'),
							items: widget.products
									.map(
										(product) => DropdownMenuItem<String>(
											value: product.id,
											child: Text(
												product.name,
												overflow: TextOverflow.ellipsis,
											),
										),
									)
									.toList(),
							onChanged: (value) {
								setState(() {
									_selectedProductId = value;
								});
							},
						),
						const SizedBox(height: 8),
						TextField(
							controller: _totalItemController,
							keyboardType: TextInputType.number,
							decoration: const InputDecoration(
								labelText: 'Total item',
								hintText: 'Example: 12',
							),
						),
						const SizedBox(height: 8),
						DropdownButtonFormField<String>(
							value: _selectedUnitType,
							decoration: const InputDecoration(labelText: 'Unit type'),
							items: _unitTypeOptions
									.map(
										(unit) => DropdownMenuItem<String>(
											value: unit,
											child: Text(unit),
										),
									)
									.toList(),
							onChanged: (value) {
								if (value == null) return;
								setState(() {
									_selectedUnitType = value;
								});
							},
						),
						const SizedBox(height: 8),
						TextField(
							controller: _totalPriceController,
							keyboardType: TextInputType.number,
							decoration: const InputDecoration(
								labelText: 'Total price',
								hintText: 'Example: 50000',
							),
						),
						const SizedBox(height: 8),
						DropdownButtonFormField<String>(
							value: _selectedStatus,
							decoration: const InputDecoration(labelText: 'Status'),
							items: _statusOptions
									.map(
										(option) => DropdownMenuItem<String>(
											value: option.value,
											child: Text(option.label),
										),
									)
									.toList(),
							onChanged: (value) {
								if (value == null) return;
								setState(() {
									_selectedStatus = value;
								});
							},
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

class _StatusOption {
	final String label;
	final String value;

	const _StatusOption({required this.label, required this.value});
}
