import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/shared/widgets/main_layout.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carebridge/shared/presentation/pages/map_selection_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CaretakerSetupScreen extends ConsumerStatefulWidget {
  const CaretakerSetupScreen({super.key});

  @override
  ConsumerState<CaretakerSetupScreen> createState() =>
      _CaretakerSetupScreenState();
}

class _CaretakerSetupScreenState extends ConsumerState<CaretakerSetupScreen> {
  final _bioController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<String> _selectedSpecialties = [];
  double? _lat;
  double? _lng;
  bool _isLoading = false;

  // ARCHITECT: Phone Verification State
  String? _verificationId;
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isPhoneVerified = false;

  final List<Map<String, dynamic>> _specialties = [
    {'name': 'Dogs', 'icon': FontAwesomeIcons.dog},
    {'name': 'Cats', 'icon': FontAwesomeIcons.cat},
    {'name': 'Birds', 'icon': FontAwesomeIcons.crow},
    {'name': 'Medical Care', 'icon': FontAwesomeIcons.suitcaseMedical},
  ];

  final Map<String, double> _availableServices = {
    'Walking': 50.0,
    'Bathing': 200.0,
    'Poop Cleanup': 150.0,
    'Feeding': 30.0,
  };
  final Set<String> _offeredServices = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.milkyWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Caretaker Profile',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create your storefront',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const Text('Show pet parents why you are the best choice.',
                  style: TextStyle(color: Colors.black45)),
              const SizedBox(height: 32),
              const Text('Bio / Experience',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe your experience with animals...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const Text('I specialize in:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    _specialties.map((s) => _buildSpecialtyChip(s)).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Premium Services Offered:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableServices.keys.map((service) {
                  final isSelected = _offeredServices.contains(service);
                  return FilterChip(
                    label: Text('$service (+₹${_availableServices[service]})'),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _offeredServices.add(service);
                        } else {
                          _offeredServices.remove(service);
                        }
                      });
                    },
                    selectedColor: AppTheme.brandBlueGreen,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              const Text('Base Price (per hour)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '500',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Phone Number (Direct Contact)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_isPhoneVerified,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone, size: 20),
                        hintText: '+91 98765 43210',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_isPhoneVerified)
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading || _phoneController.text.isEmpty
                            ? null
                            : _sendVerificationCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.safetyTeal.withOpacity(0.1),
                          foregroundColor: AppTheme.safetyTeal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _otpSent
                            ? const Text('Resend')
                            : const Text('Verify'),
                      ),
                    )
                  else
                    const SizedBox(
                      height: 56,
                      child:
                          Icon(Icons.check_circle, color: AppTheme.safetyTeal),
                    ),
                ],
              ),
              if (_otpSent && !_isPhoneVerified) ...[
                const SizedBox(height: 16),
                const Text('Enter OTP',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: '      1 2 3 4 5 6',
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.safetyTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const Text('Service Location',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final result = await Navigator.push<LatLng>(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MapSelectionScreen(
                            initialLocation:
                                _lat != null ? LatLng(_lat!, _lng!) : null)),
                  );
                  if (result != null) {
                    setState(() {
                      _lat = result.latitude;
                      _lng = result.longitude;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _lat != null
                            ? AppTheme.safetyTeal
                            : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.map_rounded,
                          color: _lat != null
                              ? AppTheme.safetyTeal
                              : Colors.black38),
                      const SizedBox(width: 12),
                      Text(
                        _lat != null
                            ? 'Location Marked ✅'
                            : 'Tap to select location on map',
                        style: TextStyle(
                            color: _lat != null
                                ? AppTheme.safetyTeal
                                : Colors.black38),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.safetyTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Launch My Profile',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyChip(Map<String, dynamic> specialty) {
    final name = specialty['name'] as String;
    final isSelected = _selectedSpecialties.contains(name);
    return FilterChip(
      label: Text(name),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          if (val) {
            _selectedSpecialties.add(name);
          } else {
            _selectedSpecialties.remove(name);
          }
        });
      },
      avatar: Icon(specialty['icon'] as IconData,
          size: 14, color: isSelected ? Colors.white : AppTheme.safetyTeal),
      selectedColor: AppTheme.safetyTeal,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
    );
  }

  Future<void> _sendVerificationCode() async {
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).sendOTP(
      _phoneController.text,
      onCodeSent: (id, token) {
        setState(() {
          _verificationId = id;
          _otpSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP Sent successfully!')));
      },
      onError: (msg) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  Future<void> _verifyOTP() async {
    if (_verificationId == null) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .verifyOTP(_verificationId!, _otpController.text);
      setState(() {
        _isPhoneVerified = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number verified!')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid OTP: $e')));
    }
  }

  Future<void> _handleSave() async {
    if (_bioController.text.isEmpty ||
        _priceController.text.isEmpty ||
        !_isPhoneVerified ||
        _lat == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill in all details and verify your phone')));
      return;
    }

    setState(() => _isLoading = true);

    final Map<String, double> serviceFees = {};
    for (var s in _offeredServices) {
      serviceFees[s] = _availableServices[s]!;
    }

    await ref.read(authProvider.notifier).saveCaretakerProfile(
          bio: _bioController.text,
          specialties: _selectedSpecialties,
          price: _priceController.text,
          phoneNumber: _phoneController.text,
          latitude: _lat!,
          longitude: _lng!,
          serviceFees: serviceFees,
          isVerified: _isPhoneVerified, // Pass actual verification status
        );

    setState(() => _isLoading = false);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainLayout()),
      (route) => false,
    );
  }
}
