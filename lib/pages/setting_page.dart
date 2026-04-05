import 'package:flutter/material.dart';
import 'package:inventory_app_project/models/store_model.dart';
import 'package:inventory_app_project/pages/home_page.dart';
import 'package:inventory_app_project/pages/inventory_page.dart';
import 'package:inventory_app_project/pages/login_page.dart';
import 'package:inventory_app_project/pages/orders/order_page.dart';
import 'package:inventory_app_project/pages/stock_movement_page.dart';
import 'package:inventory_app_project/services/store_service.dart';
import 'package:inventory_app_project/services/supplier_service.dart';
import 'package:inventory_app_project/theme/app_theme.dart';
import 'package:inventory_app_project/widgets/bottom_navigation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingPage extends StatefulWidget {
  final bool showBottomNav;

  const SettingPage({super.key, this.showBottomNav = true});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  static const int _defaultStoreId = 1;

  final StoreService _storeService = StoreService();
  final SupplierService _supplierService = SupplierService();

  bool _isLoading = true;
  String? _error;
  User? _currentUser;
  StoreModel? _store;
  int _supplierCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No active session. Please login again.');
      }

      final stores = await _storeService.getStoresByOwnerId(user.id);
      StoreModel? firstStore = stores.isNotEmpty ? stores.first : null;

      // Fallback for existing app data that still uses a default store id.
      if (firstStore == null) {
        try {
          firstStore = await _storeService.getStoreById(_defaultStoreId);
        } catch (_) {
          firstStore = null;
        }
      }

      int supplierCount = 0;
      if (firstStore != null) {
        final suppliers = await _supplierService.getSuppliersByStoreId(firstStore.id);
        supplierCount = suppliers.length;
      }

      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _store = firstStore;
        _supplierCount = supplierCount;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _displayName(User? user) {
    if (user == null) return 'Guest User';
    final fullName = user.userMetadata?['full_name']?.toString();
    if (fullName != null && fullName.trim().isNotEmpty) return fullName.trim();
    final email = user.email;
    if (email != null && email.contains('@')) {
      final prefix = email.split('@').first;
      if (prefix.isNotEmpty) {
        return '${prefix[0].toUpperCase()}${prefix.substring(1)}';
      }
    }
    return 'User';
  }

  String _roleLabel(User? user) {
    if (user == null) return 'Inventory Member';
    final role =
        user.userMetadata?['role']?.toString() ?? user.role?.toString() ?? '';
    if (role.trim().isEmpty) return 'Inventory Member';
    final normalized = role.replaceAll('_', ' ');
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _profilePhone(User? user) {
    if (user == null) return '-';
    final phone = user.userMetadata?['phone']?.toString();
    if (phone == null || phone.trim().isEmpty) return '-';
    return phone.trim();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _editProfile() async {
    final user = _currentUser;
    if (user == null) return;

    final fullNameController = TextEditingController(
      text: user.userMetadata?['full_name']?.toString() ?? '',
    );
    final emailController = TextEditingController(text: user.email ?? '');
    final phoneController = TextEditingController(
      text: user.userMetadata?['phone']?.toString() ?? '',
    );

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Edit Profile'),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    hintText: 'Enter your name',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: 'Enter your phone number',
                  ),
                ),
              ],
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

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    if (shouldSave != true) return;
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name is required.')),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid email is required.')),
      );
      return;
    }

    try {
      final normalizedCurrentEmail = (user.email ?? '').trim().toLowerCase();
      final normalizedNewEmail = email.toLowerCase();
      final isEmailChanged = normalizedCurrentEmail != normalizedNewEmail;

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {
          ...?user.userMetadata,
          'full_name': fullName,
          'phone': phone,
        }, email: isEmailChanged ? email : null),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEmailChanged
                ? 'Profile updated. Check your email to confirm email change.'
                : 'Profile updated successfully.',
          ),
        ),
      );
      await _loadProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  Future<void> _editStoreInformation() async {
    final store = _store;
    if (store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No store data available.')),
      );
      return;
    }

    final nameController = TextEditingController(text: store.name);
    final phoneController = TextEditingController(text: store.phone);
    final addressController = TextEditingController(text: store.address);
    var isOpen24H = store.isOpen24H;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Edit Store Information'),
              contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Store name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Open 24 Hours'),
                      value: isOpen24H,
                      onChanged: (value) => setDialogState(() => isOpen24H = value),
                    ),
                  ],
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
      },
    );

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();

    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();

    if (shouldSave != true) return;
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store name, phone, and address are required.')),
      );
      return;
    }

    try {
      await _storeService.updateStore(
        StoreModel(
          id: store.id,
          ownerId: store.ownerId,
          name: name,
          phone: phone,
          address: address,
          isOpen24H: isOpen24H,
          createdAt: store.createdAt,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store information updated successfully.')),
      );
      await _loadProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update store information: $e')),
      );
    }
  }

  void _onBottomNavChanged(BuildContext context, int index) {
    final Widget page;
    switch (index) {
      case 0:
        page = const HomePage();
      case 1:
        page = const InventoryPage();
      case 2:
        page = const OrderPage();
      case 3:
        page = const StockMovementPage();
      case 4:
        return;
      default:
        return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    String? value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMedium, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.errorText),
              const SizedBox(height: 8),
              const Text(
                'Failed to load profile',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _loadProfile, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    final user = _currentUser;
    final displayName = _displayName(user);
    final roleLabel = _roleLabel(user);
    final profilePhone = _profilePhone(user);

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Row(
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _logout,
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFC87F2E)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                  child: Text(
                    _initials(displayName),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8D5A1E),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
                ),
                const SizedBox(height: 4),
                Text(
                  profilePhone == '-' ? 'No phone number' : profilePhone,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
                if (user?.email != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    user!.email!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'STORE INFORMATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Color(0xFFC87F2E)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _store?.name ?? 'No store linked',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _editStoreInformation,
                      tooltip: 'Edit store information',
                      icon: const Icon(Icons.edit_outlined, color: AppColors.textMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InfoRow(label: 'Business ID', value: _store != null ? 'STORE-${_store!.id}' : '-'),
                _InfoRow(label: 'Phone', value: _store?.phone ?? '-'),
                _InfoRow(label: 'Address', value: _store?.address ?? '-'),
                _InfoRow(label: 'Suppliers', value: '$_supplierCount'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ACCOUNT SETTINGS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Edit Profile',
                  onTap: _editProfile,
                ),
                _buildSettingsItem(
                  icon: Icons.storefront_outlined,
                  label: 'Edit Store Information',
                  onTap: _editStoreInformation,
                ),
                _buildSettingsItem(icon: Icons.shield_outlined, label: 'Security & Privacy'),
                _buildSettingsItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  value: _supplierCount > 0 ? '$_supplierCount updates' : null,
                ),
                _buildSettingsItem(icon: Icons.translate_rounded, label: 'Language', value: 'English'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'HELP & SUPPORT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SupportCard(icon: Icons.help_outline_rounded, label: 'Help Center'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SupportCard(icon: Icons.chat_bubble_outline_rounded, label: 'Contact Support'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'StockFlow v2.4.0',
              style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          _buildBody(),
          if (widget.showBottomNav)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BottomNavigation(
                selectedIndex: 4,
                onNavChanged: (index) => _onBottomNavChanged(context, index),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SupportCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFC87F2E), size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
