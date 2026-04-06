import 'package:flutter/material.dart';

enum InventoryQuickAction {
	addItem,
	addSupplier,
	addCategory,
	addOrder,
	stockIn,
	stockOut,
}

class InventoryQuickActionsSection extends StatelessWidget {
	final double bottomOffset;
	final Future<void> Function(InventoryQuickAction action) onActionSelected;
	final String heroTag;

	const InventoryQuickActionsSection({
		super.key,
		required this.bottomOffset,
		required this.onActionSelected,
		this.heroTag = 'quick_actions_fab',
	});

	@override
	Widget build(BuildContext context) {
		return Positioned(
			right: 16,
			bottom: bottomOffset,
			child: FloatingActionButton(
				heroTag: heroTag,
				onPressed: () => _showQuickActions(context),
				backgroundColor: const Color(0xFFC87F2E),
				foregroundColor: Colors.white,
				elevation: 3,
				shape: RoundedRectangleBorder(
					borderRadius: BorderRadius.circular(16),
				),
				child: const Icon(Icons.add_rounded, size: 26),
			),
		);
	}

	Future<void> _showQuickActions(BuildContext context) async {
		final action = await showModalBottomSheet<InventoryQuickAction>(
			context: context,
			useRootNavigator: true,
			useSafeArea: true,
			backgroundColor: Colors.white,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
			),
			builder: (context) {
				return Wrap(
					children: [
						ListTile(
							leading: const Icon(Icons.inventory_2_outlined),
							title: const Text('Add Item'),
							onTap: () => Navigator.of(context).pop(InventoryQuickAction.addItem),
						),
						ListTile(
							leading: const Icon(Icons.local_shipping_outlined),
							title: const Text('Add Supplier'),
							onTap: () => Navigator.of(context).pop(InventoryQuickAction.addSupplier),
						),
						ListTile(
							leading: const Icon(Icons.category_outlined),
							title: const Text('Add Category'),
							onTap: () => Navigator.of(context).pop(InventoryQuickAction.addCategory),
						),
						ListTile(
							leading: const Icon(Icons.receipt_long_outlined),
							title: const Text('Add Order'),
							onTap: () => Navigator.of(context).pop(InventoryQuickAction.addOrder),
						),
						ListTile(
							leading: const Icon(Icons.arrow_downward_rounded),
							title: const Text('Stock In'),
							onTap: () => Navigator.of(context).pop(InventoryQuickAction.stockIn),
						),
						ListTile(
							leading: const Icon(Icons.arrow_upward_rounded),
							title: const Text('Stock Out'),
							onTap: () => Navigator.of(context).pop(InventoryQuickAction.stockOut),
						),
					],
				);
			},
		);

		if (action == null || !context.mounted) return;

		WidgetsBinding.instance.addPostFrameCallback((_) {
			onActionSelected(action);
		});
	}
}
