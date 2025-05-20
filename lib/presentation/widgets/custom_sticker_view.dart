import 'package:flutter/material.dart';

class CustomStickerView extends StatelessWidget {
  final VoidCallback onAddPressed;

  const CustomStickerView({
    super.key,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(
                Icons.add_photo_alternate_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              onPressed: onAddPressed,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add Custom Sticker',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to create your own sticker',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
} 