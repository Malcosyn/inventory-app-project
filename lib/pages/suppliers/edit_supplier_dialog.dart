import 'package:flutter/material.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

class EditSupplierResult {
	final String name;
	final String phone;
	final String address;
	final String? email;

	const EditSupplierResult({
		required this.name,
		required this.phone,
		required this.address,
		required this.email,
	});
}

class EditSupplierDialog extends StatefulWidget {
	final String initialName;
	final String initialPhone;
	final String initialAddress;
	final String? initialEmail;

	const EditSupplierDialog({
		super.key,
		required this.initialName,
		required this.initialPhone,
		required this.initialAddress,
		this.initialEmail,
	});

	static Future<EditSupplierResult?> show(
		BuildContext context, {
		required String initialName,
		required String initialPhone,
		required String initialAddress,
		String? initialEmail,
	}) {
		return showDialog<EditSupplierResult>(
			context: context,
			builder: (_) => EditSupplierDialog(
				initialName: initialName,
				initialPhone: initialPhone,
				initialAddress: initialAddress,
				initialEmail: initialEmail,
			),
		);
	}

	@override
	State<EditSupplierDialog> createState() => _EditSupplierDialogState();
}

class _EditSupplierDialogState extends State<EditSupplierDialog> {
	late final TextEditingController _nameController;
	late final TextEditingController _phoneController;
	late final TextEditingController _addressController;
	late final TextEditingController _emailController;

	@override
	void initState() {
		super.initState();
		_nameController = TextEditingController(text: widget.initialName);
		_phoneController = TextEditingController(text: widget.initialPhone);
		_addressController = TextEditingController(text: widget.initialAddress);
		_emailController = TextEditingController(text: widget.initialEmail ?? '');
	}

	@override
	void dispose() {
		_nameController.dispose();
		_phoneController.dispose();
		_addressController.dispose();
		_emailController.dispose();
		super.dispose();
	}

	void _save() {
		final name = _nameController.text.trim();
		final phone = _phoneController.text.trim();
		final address = _addressController.text.trim();
		final emailText = _emailController.text.trim();

		if (name.isEmpty || phone.isEmpty || address.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Name, phone, and address are required.')),
			);
			return;
		}

		Navigator.of(context).pop(
			EditSupplierResult(
				name: name,
				phone: phone,
				address: address,
				email: emailText.isEmpty ? null : emailText,
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			backgroundColor: AppColors.cardBg,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
			title: const Text('Edit Supplier'),
			contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
			content: SingleChildScrollView(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						TextField(
							controller: _nameController,
							decoration: const InputDecoration(
								labelText: 'Supplier name',
								hintText: 'Example: ABC Supplier',
							),
						),
						const SizedBox(height: 8),
						TextField(
							controller: _phoneController,
							keyboardType: TextInputType.phone,
							decoration: const InputDecoration(labelText: 'Phone'),
						),
						const SizedBox(height: 8),
						TextField(
							controller: _addressController,
							decoration: const InputDecoration(labelText: 'Address'),
						),
						const SizedBox(height: 8),
						TextField(
							controller: _emailController,
							keyboardType: TextInputType.emailAddress,
							decoration: const InputDecoration(labelText: 'Email (optional)'),
							onSubmitted: (_) => _save(),
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
