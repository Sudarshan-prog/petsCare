import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/core/providers/caretaker_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  // Caretaker specific
  TextEditingController? _bioController;
  TextEditingController? _priceController;
  Map<String, double> _serviceFees = {};
  List<String> _specialties = [];

  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        _nameController = TextEditingController(text: authState.user.name);
        _phoneController =
            TextEditingController(text: authState.user.phoneNumber);

        if (authState.user.role == 'caretaker') {
          _bioController = TextEditingController();
          _priceController = TextEditingController();

          // Fetch existing caretaker data
          ref.listenManual(singleCaretakerProvider(authState.user.id),
              (previous, next) {
            next.whenData((caretaker) {
              if (caretaker != null) {
                setState(() {
                  _bioController?.text = caretaker.bio ?? '';
                  _priceController?.text = caretaker.price.toString();
                  _serviceFees = Map.from(caretaker.serviceFees);
                  _specialties = List.from(caretaker.specialties);
                });
              }
            });
          });
        }
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController?.dispose();
    _priceController?.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        await ref.read(authProvider.notifier).updateProfile(
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              bio: _bioController?.text.trim(),
              price: double.tryParse(_priceController?.text ?? '0'),
              specialties: _specialties,
              serviceFees: _serviceFees,
            );

        if (mounted) {
          Navigator.pop(context); // Remove loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('✨ Profile updated successfully!'),
                backgroundColor: AppTheme.safetyTeal),
          );
          Navigator.pop(context); // Go back to profile
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: AppTheme.softCream,
      appBar: AppBar(
        title: const Text('Edit Profile',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save',
                style: TextStyle(
                    color: AppTheme.brandBlueGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (val) => val!.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Phone required' : null,
              ),
              if (user.role == 'caretaker') ...[
                const SizedBox(height: 32),
                _buildSectionTitle('Caretaker Details'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _bioController!,
                  label: 'About You (Bio)',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _priceController!,
                  label: 'Base Price (₹ / hr)',
                  icon: Icons.currency_rupee_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Services & Fees'),
                const SizedBox(height: 16),
                ..._serviceFees.entries
                    .map((entry) => _buildServiceItem(entry.key, entry.value)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showAddServiceDialog,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: const Text('Add Custom Service'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppTheme.safetyTeal),
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black45,
            letterSpacing: 1.2));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.brandBlueGreen, size: 20),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildServiceItem(String name, double price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          const Text('₹', style: TextStyle(color: Colors.black45)),
          SizedBox(
            width: 60,
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                  border: InputBorder.none, hintText: '0'),
              onChanged: (val) {
                setState(() {
                  _serviceFees[name] = double.tryParse(val) ?? 0;
                });
              },
              controller: TextEditingController(text: price.toStringAsFixed(0))
                ..selection = TextSelection.fromPosition(
                    TextPosition(offset: price.toStringAsFixed(0).length)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: AppTheme.alertRed, size: 20),
            onPressed: () => setState(() => _serviceFees.remove(name)),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog() {
    String newService = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Service'),
        content: TextField(
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Service Name (e.g. Grooming)'),
          onChanged: (val) => newService = val,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (newService.isNotEmpty) {
                setState(() => _serviceFees[newService] = 0);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
