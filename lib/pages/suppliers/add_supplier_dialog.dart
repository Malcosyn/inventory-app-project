import 'package:flutter/material.dart';

class AddSupplierInput {
	final String name;
	final String phone;
	final String address;
	final String? email;

	const AddSupplierInput({
		required this.name,
		required this.phone,
		required this.address,
		this.email,
	});
}

class AddSupplierDialog {
	static Future<AddSupplierInput?> show(BuildContext context) async {
		final nameController = TextEditingController();
		final phoneController = TextEditingController();
		final addressController = TextEditingController();
		final emailController = TextEditingController();

		final created = await showDialog<bool>(
			context: context,
			builder: (context) {
				return AlertDialog(
					title: const Text('Add Supplier'),
					content: SingleChildScrollView(
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								TextField(
									controller: nameController,
									decoration: const InputDecoration(
										labelText: 'Supplier name',
									),
								),
								const SizedBox(height: 8),
								TextField(
									controller: phoneController,
									keyboardType: TextInputType.phone,
									decoration: const InputDecoration(
										labelText: 'Phone',
									),
								),
								const SizedBox(height: 8),
								TextField(
									controller: addressController,
									decoration: const InputDecoration(
										labelText: 'Address',
									),
								),
								const SizedBox(height: 8),
								TextField(
									controller: emailController,
									keyboardType: TextInputType.emailAddress,
									decoration: const InputDecoration(
										labelText: 'Email (optional)',
									),
								),
							],
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
		final phone = phoneController.text.trim();
		final address = addressController.text.trim();
		final email = emailController.text.trim();

		nameController.dispose();
		phoneController.dispose();
		addressController.dispose();
		emailController.dispose();

		if (created != true) {
			return null;
		}

		return AddSupplierInput(
			name: name,
			phone: phone,
			address: address,
			email: email.isEmpty ? null : email,
		);
	}
}
