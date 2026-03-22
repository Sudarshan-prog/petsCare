import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carebridge/core/app_theme.dart';

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildServiceItem(
                context, 
                'Caretaking',
                FontAwesomeIcons.shieldHeart, 
                AppTheme.brandBlueGreen
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildServiceItem(
                context, 
                'Adopt', 
                FontAwesomeIcons.paw, 
                AppTheme.safetyTeal
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildServiceItem(
                context, 
                'AI Wellness',
                FontAwesomeIcons.robot, 
                Colors.deepPurpleAccent
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildServiceItem(
                context, 
                'SOS Help',
                FontAwesomeIcons.truckMedical, 
                AppTheme.alertRed
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem(
      BuildContext context, String title, IconData icon, Color color) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
