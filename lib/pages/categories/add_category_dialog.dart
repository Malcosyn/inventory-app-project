import 'package:flutter/material.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

class AddCategoryDialog {
	static Future<String?> show(BuildContext context) async {
		final nameController = TextEditingController();

		final created = await showDialog<bool>(
			context: context,
			builder: (context) {
				return AlertDialog(
					backgroundColor: AppColors.cardBg,
					shape: RoundedRectangleBorder(
						borderRadius: BorderRadius.circular(18),
					),
					title: const Text('Add Category'),
					contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
					content: TextField(
						controller: nameController,
						decoration: const InputDecoration(
							labelText: 'Category name',
							hintText: 'Example: Beverages',
						),
					),
					actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
					actions: [
						TextButton(
							style: TextButton.styleFrom(foregroundColor: AppColors.textMedium),
							onPressed: () => Navigator.of(context).pop(false),
							child: const Text('Cancel'),
						),
						FilledButton(
							style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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
