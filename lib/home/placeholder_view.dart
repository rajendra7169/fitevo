import 'package:flutter/material.dart';
import '../theme.dart';

class PlaceholderView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const PlaceholderView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 30, color: accent),
              ),
              const SizedBox(height: 22),
              Text(title, style: AppText.bigNumber.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(fontSize: 14)),
              const SizedBox(height: 16),
              Text('COMING SOON', style: AppText.label),
            ],
          ),
        ),
      ),
    );
  }
}
