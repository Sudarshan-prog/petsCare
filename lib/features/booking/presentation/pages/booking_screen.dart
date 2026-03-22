import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carebridge/core/app_theme.dart';
import 'package:carebridge/core/providers/caretaker_provider.dart';
import 'package:carebridge/core/providers/pet_provider.dart';
import 'package:carebridge/core/auth/auth_provider.dart';
import 'package:carebridge/features/booking/presentation/providers/booking_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carebridge/core/providers/payment_provider.dart';
import 'package:carebridge/core/config/app_config.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Caretaker caretaker;

  const BookingScreen({super.key, required this.caretaker});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '10:00 AM';
  final Set<String> _selectedServices = {};
  int _selectedHours = 1;
  Pet? _selectedPet;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _timeSlots = [
    '08:00 AM',
    '10:00 AM',
    '12:00 PM',
    '02:00 PM',
    '04:00 PM',
    '06:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    // ARCHITECT: Pre-initialize payment listeners for smooth commercial checkout
    Future.microtask(() => ref.read(paymentProvider.notifier).init());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.brandBlueGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleBooking() async {
    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pet first')),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      // Revenue Model: Base + Premiums + Owner's 2.5% Trust Fee
      final double servicePrice = widget.caretaker.price * _selectedHours;
      double totalPremiums = 0.0;
      for (var service in _selectedServices) {
        totalPremiums += widget.caretaker.serviceFees[service] ?? 0.0;
      }
      final double basePrice = servicePrice + totalPremiums;
      final double ownerTotal = AppConfig.calculateOwnerTotal(basePrice);

      // Start Commercial Payment Flow
      ref.read(paymentProvider.notifier).startPayment(
            amount: ownerTotal,
            contact: authState.user.phoneNumber ?? '',
            email: authState.user.email,
            description: 'CareBridge Booking (incl. 2.5% Safety & Trust Fee)',
            caretakerId: widget.caretaker.id,
          );
    }
  }

  void _finalizeBooking(String paymentId) async {
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      // Calculate basePrice for fallback path
      final double servicePrice = widget.caretaker.price * _selectedHours;
      double totalPremiums = 0.0;
      for (var service in _selectedServices) {
        totalPremiums += widget.caretaker.serviceFees[service] ?? 0.0;
      }
      final double basePrice = servicePrice + totalPremiums;

      // PHASE 2: Smart hybrid — Cloud Function first, then direct write fallback
      final result = await ref.read(bookingProvider.notifier).createBookingViaServer(
        ownerId: authState.user.id,
        ownerName: authState.user.name,
        caretakerId: widget.caretaker.id,
        caretakerName: widget.caretaker.name,
        petId: _selectedPet!.id,
        petName: _selectedPet!.name,
        services: _selectedServices.toList(),
        hours: _selectedHours,
        date: _selectedDate.toIso8601String(),
        timeSlot: _selectedTimeSlot,
        basePrice: basePrice,
        notes: _notesController.text,
        paymentId: paymentId,
      );

      if (mounted) {
        if (result != null && result['success'] == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Booking Requested!'),
              content: Text(
                  'Your booking request has been sent. Total: ₹${result['totalPrice']}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // dialog
                    Navigator.of(context).pop(); // booking screen
                  },
                  child: const Text('Great!'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(userPetsProvider);
    final bookingState = ref.watch(bookingProvider);
    final paymentState = ref.watch(paymentProvider);

    // ARCHITECT: Listen for payment success to finalize the booking
    ref.listen(paymentProvider, (previous, next) {
      if (next.isSuccess && next.paymentId != null) {
        _finalizeBooking(next.paymentId!);
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Error: ${next.error}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.softCream,
      appBar: AppBar(
        title: const Text('Book Caretaker',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCaretakerSummary(),
              const SizedBox(height: 30),
              if (widget.caretaker.serviceFees.isNotEmpty) ...[
                _buildSectionTitle('Select Service'),
                const SizedBox(height: 12),
                _buildServiceSelector(),
                const SizedBox(height: 30),
              ],
              _buildSectionTitle('Select Pet'),
              const SizedBox(height: 12),
              _buildPetSelector(petsAsync),
              const SizedBox(height: 30),
              _buildSectionTitle('Duration (Hours)'),
              const SizedBox(height: 12),
              _buildHourSelector(),
              const SizedBox(height: 30),
              _buildSectionTitle('Date & Time'),
              const SizedBox(height: 12),
              _buildDateTimePicker(context),
              const SizedBox(height: 30),
              _buildSectionTitle('Special Notes'),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any special instructions for the caretaker...',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(bookingState, paymentState),
    );
  }

  Widget _buildCaretakerSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.brandBlueGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandBlueGreen.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: NetworkImage(widget.caretaker.profileUrl ??
                'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?auto=format&fit=crop&q=80&w=200'),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.caretaker.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.caretaker.specialties.join(' • '),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${widget.caretaker.price} / hour',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          if (widget.caretaker.phoneNumber != null)
            IconButton(
              onPressed: () =>
                  _makeEmergencyCall(widget.caretaker.phoneNumber!),
              icon: const Icon(Icons.phone_forwarded_rounded,
                  color: Colors.white, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.all(12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _makeEmergencyCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildServiceSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.caretaker.serviceFees.keys.map((service) {
        final isSelected = _selectedServices.contains(service);
        final premium = widget.caretaker.serviceFees[service] ?? 0.0;
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedServices.remove(service);
              } else {
                _selectedServices.add(service);
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.brandBlueGreen : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.brandBlueGreen : Colors.black12,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: AppTheme.brandBlueGreen.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  service,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+₹${premium.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white.withOpacity(0.8)
                        : AppTheme.safetyTeal,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPetSelector(AsyncValue<List<Pet>> petsAsync) {
    return petsAsync.when(
      data: (pets) {
        if (pets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.alertRed),
                SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'No pets found. Please add a pet in your profile first.')),
              ],
            ),
          );
        }
        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final pet = pets[index];
              final isSelected = _selectedPet?.id == pet.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedPet = pet),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 90,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.safetyTeal : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.safetyTeal : Colors.black12,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        pet.type.toLowerCase().contains('dog')
                            ? FontAwesomeIcons.dog
                            : FontAwesomeIcons.cat,
                        color: isSelected ? Colors.white : AppTheme.safetyTeal,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pet.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, __) => Text('Error loading pets: $e'),
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month,
                    color: AppTheme.brandBlueGreen),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Icon(Icons.edit_calendar,
                    size: 20, color: Colors.black26),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 45,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _timeSlots.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final slot = _timeSlots[index];
              final isSelected = _selectedTimeSlot == slot;
              return ChoiceChip(
                label: Text(slot),
                selected: isSelected,
                onSelected: (val) => setState(() => _selectedTimeSlot = slot),
                selectedColor: AppTheme.brandBlueGreen,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontSize: 12,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHourSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Number of hours',
              style: TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              IconButton(
                onPressed: _selectedHours > 1
                    ? () => setState(() => _selectedHours--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.brandBlueGreen,
              ),
              Text(
                '$_selectedHours',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _selectedHours < 12
                    ? () => setState(() => _selectedHours++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.brandBlueGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      AsyncValue<void> bookingState, PaymentState paymentState) {
    final isLoading = (bookingState is AsyncLoading) || paymentState.isLoading;
    final double basePrice = widget.caretaker.price * _selectedHours;
    double totalPremiums = 0.0;
    for (var s in _selectedServices) {
      totalPremiums += widget.caretaker.serviceFees[s] ?? 0.0;
    }
    final ownerFee = AppConfig.calculateOwnerFee(basePrice + totalPremiums);
    final total = basePrice + totalPremiums + ownerFee;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Total Price',
                        style: TextStyle(color: Colors.black38, fontSize: 12)),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Base Cost + ₹15 Safety & Trust Fee',
                      child: Icon(Icons.info_outline,
                          size: 12, color: Colors.black26),
                    ),
                  ],
                ),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandBlueGreen),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandBlueGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)),
                            SizedBox(height: 4),
                            Text('Processing...',
                                style: TextStyle(fontSize: 10)),
                          ],
                        )
                      : const Text('Pay & Book Now',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
