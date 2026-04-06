import 'package:flutter/material.dart';
import 'package:inventory_app_project/theme/app_theme.dart';

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
    return showDialog<AddSupplierInput>(
      context: context,
      builder: (context) {
        return const _AddSupplierDialogBody();
      },
    );
  }
}

class _AddSupplierDialogBody extends StatefulWidget {
  const _AddSupplierDialogBody();

  @override
  State<_AddSupplierDialogBody> createState() => _AddSupplierDialogBodyState();
}

class _AddSupplierDialogBodyState extends State<_AddSupplierDialogBody> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _emailController = TextEditingController();
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
    final email = _emailController.text.trim();

    Navigator.of(context).pop(
      AddSupplierInput(
        name: name,
        phone: phone,
        address: address,
        email: email.isEmpty ? null : email,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Add Supplier'),
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
