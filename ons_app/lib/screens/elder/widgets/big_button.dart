import 'package:flutter/material.dart';

class BigButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  const BigButton({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      height: 92,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: danger ? Colors.red : null,
          foregroundColor: danger ? Colors.white : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(subtitle!, style: t.bodyMedium),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
