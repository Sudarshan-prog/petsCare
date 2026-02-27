import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/providers/pet_provider.dart';

class MyPetsScreen extends ConsumerWidget {
  const MyPetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(userPetsProvider);

    return Scaffold(
      backgroundColor: AppTheme.softCream,
      appBar: AppBar(
        title: const Text('My Pets',
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
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppTheme.brandBlueGreen),
            onPressed: () => _showPetDialog(context, ref),
          ),
        ],
      ),
      body: petsAsync.when(
        data: (pets) {
          if (pets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets_rounded, size: 64, color: Colors.black12),
                  const SizedBox(height: 16),
                  const Text('No pets added yet',
                      style: TextStyle(
                          color: Colors.black45, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showPetDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Pet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandBlueGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return _buildPetCard(context, ref, pet);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, WidgetRef ref, Pet pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.brandBlueGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              pet.type.toLowerCase() == 'dog'
                  ? Icons.pets_rounded
                  : Icons.pets_outlined,
              color: AppTheme.brandBlueGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Text('${pet.type} • ${pet.breed} • ${pet.age}',
                    style:
                        const TextStyle(color: Colors.black45, fontSize: 14)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black26),
            onSelected: (value) {
              if (value == 'edit') {
                _showPetDialog(context, ref, pet: pet);
              } else if (value == 'delete') {
                _confirmDelete(context, ref, pet);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: AppTheme.alertRed))),
            ],
          ),
        ],
      ),
    );
  }

  void _showPetDialog(BuildContext context, WidgetRef ref, {Pet? pet}) {
    final nameController = TextEditingController(text: pet?.name);
    final typeController = TextEditingController(text: pet?.type);
    final breedController = TextEditingController(text: pet?.breed);
    final ageController = TextEditingController(text: pet?.age);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(pet == null ? 'Add Pet' : 'Edit Pet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(
                  nameController, 'Pet Name', Icons.badge_outlined),
              const SizedBox(height: 12),
              _buildDialogTextField(
                  typeController, 'Type (e.g. Dog)', Icons.category_outlined),
              const SizedBox(height: 12),
              _buildDialogTextField(
                  breedController, 'Breed', Icons.info_outline_rounded),
              const SizedBox(height: 12),
              _buildDialogTextField(ageController, 'Age', Icons.cake_outlined),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                if (pet == null) {
                  await ref.read(petActionProvider.notifier).addPet(
                        nameController.text,
                        typeController.text,
                        breedController.text,
                        ageController.text,
                      );
                } else {
                  await ref.read(petActionProvider.notifier).updatePet(pet.id, {
                    'name': nameController.text,
                    'type': typeController.text,
                    'breed': breedController.text,
                    'age': ageController.text,
                  });
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandBlueGreen,
                foregroundColor: Colors.white),
            child: Text(pet == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet?'),
        content: Text(
            'Are you sure you want to remove ${pet.name} from your profile?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(petActionProvider.notifier).deletePet(pet.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.alertRed)),
          ),
        ],
      ),
    );
  }
}
