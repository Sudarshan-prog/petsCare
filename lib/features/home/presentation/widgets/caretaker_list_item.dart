import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carebridge/core/app_theme.dart';

class CaretakerListItem extends StatelessWidget {
  final String name;
  final String role;
  final String dist;
  final String price;
  final String rating;
  final bool isPro;
  final String image;
  final VoidCallback onTap;

  const CaretakerListItem({
    super.key,
    required this.name,
    required this.role,
    required this.dist,
    required this.price,
    required this.rating,
    required this.isPro,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.safetyTeal.withOpacity(0.1),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.safetyTeal.withOpacity(0.1),
                  child: const Icon(Icons.error_outline,
                      color: AppTheme.safetyTeal),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified_user_rounded,
                        color:
                            isPro ? AppTheme.verifyGold : AppTheme.safetyTeal,
                        size: 16,
                      ),
                    ],
                  ),
                  Text('$role • $dist',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black45)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.verifyGold, size: 16),
                      Text(' $rating',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        '$price/hour',
                        style: const TextStyle(
                          color: AppTheme.brandBlueGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
