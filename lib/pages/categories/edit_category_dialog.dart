import 'package:flutter/material.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

class EditCategoryDialog extends StatefulWidget {
	final String initialName;

	const EditCategoryDialog({super.key, required this.initialName});

	static Future<String?> show(
		BuildContext context, {
		required String initialName,
	}) {
		return showDialog<String>(
			context: context,
			builder: (_) => EditCategoryDialog(initialName: initialName),
		);
	}

	@override
	State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
	late final TextEditingController _controller;

	@override
	void initState() {
		super.initState();
		_controller = TextEditingController(text: widget.initialName);
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	void _save() {
		final name = _controller.text.trim();
		if (name.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Category name is required.')),
			);
			return;
		}
		Navigator.of(context).pop(name);
	}

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			backgroundColor: AppColors.cardBg,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
			title: const Text('Edit Category'),
			contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
			content: TextField(
				controller: _controller,
				decoration: const InputDecoration(
					labelText: 'Category name',
					hintText: 'Example: Beverages',
				),
				onSubmitted: (_) => _save(),
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
