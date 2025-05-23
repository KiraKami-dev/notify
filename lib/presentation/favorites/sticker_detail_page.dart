import 'package:flutter/material.dart';
import 'package:notify/domain/sticker_model.dart';
import 'package:notify/presentation/widgets/edit_sticker_dialog.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StickerDetailPage extends ConsumerWidget {
  final Sticker sticker;
  final VoidCallback onUnfavorite;
  final Function(Sticker updatedSticker)? onStickerUpdated;

  const StickerDetailPage({
    required this.sticker,
    required this.onUnfavorite,
    this.onStickerUpdated,
    super.key,
  });

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(getGeneratedCodeProvider) ?? '';
    await showDialog(
      context: context,
      builder: (context) => EditStickerDialog(
        sticker: sticker,
        userId: userId,
        onStickerUpdated: (updatedSticker) {
          if (onStickerUpdated != null) {
            onStickerUpdated!(updatedSticker);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen image with parallax effect
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: 'custom_${sticker.id}',
                  child: Image.network(
                    sticker.url,
                    fit: BoxFit.cover,
                    height: size.height * 0.7,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sticker.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              sticker.body,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              context,
                              icon: Icons.favorite,
                              label: 'Remove from\nFavorites',
                              color: theme.colorScheme.error,
                              onTap: () {
                                onUnfavorite();
                                Navigator.pop(context);
                              },
                            ),
                            _buildActionButton(
                              context,
                              icon: Icons.send_rounded,
                              label: 'Send\nNotification',
                              color: theme.colorScheme.primary,
                              onTap: () {
                                // TODO: Implement send notification
                                Navigator.pop(context);
                              },
                            ),
                            if (onStickerUpdated != null)
                              _buildActionButton(
                                context,
                                icon: Icons.edit_rounded,
                                label: 'Edit\nSticker',
                                color: theme.colorScheme.secondary,
                                onTap: () => _showEditDialog(context, ref),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 