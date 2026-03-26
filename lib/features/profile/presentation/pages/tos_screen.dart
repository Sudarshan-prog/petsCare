import 'package:flutter/material.dart';
import 'package:carebridge/core/app_theme.dart';

class TOSScreen extends StatelessWidget {
  const TOSScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text('Terms & Privacy', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy Policy & Terms of Service', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 24),
              Text('1. User Data Collection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('CareBridge collects basic profile information (name, email) and optional location data to connect pet owners with nearby caretakers. We do not sell your personal data to third parties.'),
              SizedBox(height: 24),
              Text('2. Financial Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('All payments are securely processed via Razorpay. CareBridge takes a platform fee for facilitating standard bookings. We do not store full credit card details on our servers.'),
              SizedBox(height: 24),
              Text('3. Caretaker Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('While we strive to verify caretakers, CareBridge is a marketplace. Pet owners are responsible for reviewing caretaker credentials before booking.'),
              SizedBox(height: 24),
              Text('4. Account Deletion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('You reserve the right to delete your account at any time. Initiating an account deletion will irreversibly wipe your profile, active listings, and pet data from our secure databases within 30 days.'),
              SizedBox(height: 48),
              Text('Last updated: March 2026', style: TextStyle(color: Colors.black45, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
