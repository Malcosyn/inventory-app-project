import 'package:flutter/material.dart';

class AddCategoryDialog {
	static Future<String?> show(BuildContext context) async {
		final nameController = TextEditingController();

		final created = await showDialog<bool>(
			context: context,
			builder: (context) {
				return AlertDialog(
					title: const Text('Add Category'),
					content: TextField(
						controller: nameController,
						decoration: const InputDecoration(
							labelText: 'Category name',
							hintText: 'Example: Beverages',
						),
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(context).pop(false),
							child: const Text('Cancel'),
						),
						FilledButton(
							onPressed: () => Navigator.of(context).pop(true),
							child: const Text('Save'),
						),
					],
				);
			},
		);

		final name = nameController.text.trim();
		nameController.dispose();

		if (created != true || name.isEmpty) {
			return null;
		}

		return name;
	}
}
