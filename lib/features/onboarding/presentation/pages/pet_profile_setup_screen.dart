import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/shared/widgets/main_layout.dart';
import 'package:carebridge/shared/presentation/pages/map_selection_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PetProfileSetupScreen extends ConsumerStatefulWidget {
  const PetProfileSetupScreen({super.key});

  @override
  ConsumerState<PetProfileSetupScreen> createState() =>
      _PetProfileSetupScreenState();
}

class _PetProfileSetupScreenState extends ConsumerState<PetProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  String _selectedType = 'Dog';
  String _selectedAge = 'Adult';
  double? _lat;
  double? _lng;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.milkyWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainLayout()),
                (route) => false,
              );
            },
            child: const Text('Skip', style: TextStyle(color: Colors.black38)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LinearProgressIndicator(
                value: 0.6,
                backgroundColor: AppTheme.softCream,
                color: AppTheme.brandBlueGreen,
                minHeight: 6,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Add your first pet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                'Let\'s customize your experience for your furry friend.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 40),
              const Text('What kind of pet?',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTypeChip('Dog', Icons.pets),
                  const SizedBox(width: 12),
                  _buildTypeChip('Cat', Icons.pets),
                  const SizedBox(width: 12),
                  _buildTypeChip('Other', Icons.more_horiz),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Pet Name',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Buddy',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: Colors.black.withOpacity(0.05)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Breed',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _breedController,
                decoration: InputDecoration(
                  hintText: 'e.g. Golden Retriever',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: Colors.black.withOpacity(0.05)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Age Group',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  _buildAgeChip('Puppy/Kitten'),
                  _buildAgeChip('Young'),
                  _buildAgeChip('Adult'),
                  _buildAgeChip('Senior'),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Your Location (To find nearby help)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final result = await Navigator.push<LatLng>(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MapSelectionScreen()),
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
                            ? AppTheme.brandBlueGreen
                            : Colors.black.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          color: _lat != null
                              ? AppTheme.brandBlueGreen
                              : Colors.black38),
                      const SizedBox(width: 12),
                      Text(
                        _lat != null
                            ? 'Location Captured ✅'
                            : 'Select your area on map',
                        style: TextStyle(
                            color: _lat != null
                                ? AppTheme.brandBlueGreen
                                : Colors.black38),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_nameController.text.isNotEmpty && _lat != null) {
                            setState(() => _isLoading = true);
                            await ref
                                .read(authProvider.notifier)
                                .savePetProfile(
                                  name: _nameController.text,
                                  type: _selectedType,
                                  breed: _breedController.text,
                                  age: _selectedAge,
                                );
                            await ref
                                .read(authProvider.notifier)
                                .updateLocation(_lat!, _lng!);

                            setState(() => _isLoading = false);

                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MainLayout()),
                              (route) => false,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please enter pet name and select location')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandBlueGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Finish Setup',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandBlueGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected
                  ? AppTheme.brandBlueGreen
                  : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(type,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeChip(String age) {
    final isSelected = _selectedAge == age;
    return ChoiceChip(
      label: Text(age),
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedAge = age),
      selectedColor: AppTheme.brandBlueGreen.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.brandBlueGreen : Colors.black54,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isSelected
                ? AppTheme.brandBlueGreen
                : Colors.black.withOpacity(0.05)),
      ),
    );
  }
}
