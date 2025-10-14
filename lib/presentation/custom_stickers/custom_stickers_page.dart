import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:notify/data/firebase/firebase_stickers.dart';
import 'package:notify/data/firebase/firebase_favorites.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:notify/data/providers/favorite_provider.dart';
import 'package:notify/domain/sticker_model.dart';
import 'package:notify/presentation/favorites/sticker_detail_page.dart';
import 'package:notify/presentation/widgets/custom_sticker_dialog.dart';

class CustomStickersPage extends ConsumerStatefulWidget {
  const CustomStickersPage({super.key});

  @override
  ConsumerState<CustomStickersPage> createState() => _CustomStickersPageState();
}

class _CustomStickersPageState extends ConsumerState<CustomStickersPage> {
  List<Sticker> _customStickers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStickers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStickers() async {
    setState(() => _isLoading = true);
    try {
      final userId = ref.read(getGeneratedCodeProvider) ?? '';
      final customStickers = await FirebaseStickers.fetchCustomStickers(userId);
      final favoriteStickers = await FirebaseFavorites.getFavoriteStickers(userId);
      final favoriteIds = favoriteStickers.map((s) => s.id).toSet();

      // Update favorites in a single pass
      for (var sticker in customStickers) {
        sticker.isFavorite = favoriteIds.contains(sticker.id);
      }
      
      setState(() {
        _customStickers = customStickers;
        _updateCustomStickersList();
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateCustomStickersList() {
    _customStickers = _customStickers
        .where((sticker) => 
          sticker.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _updateCustomStickersList();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search custom stickers...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _updateCustomStickersList();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildStickerGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_customStickers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No custom stickers yet'
                  : 'No matches found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Create your first custom sticker!'
                  : 'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isEmpty)
              FilledButton.icon(
                onPressed: () => _showCustomStickerDialog(context),
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Create Custom Sticker'),
              ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _customStickers.length,
        itemBuilder: (context, index) {
          final sticker = _customStickers[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildStickerCard(sticker),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickerCard(Sticker sticker) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _showStickerDetail(sticker);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'custom_${sticker.id}',
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(sticker.url),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sticker.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sticker.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          sticker.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: sticker.isFavorite ? Colors.red : theme.colorScheme.onSurface,
                        ),
                        onPressed: () async {
                          await ref.read(
                            toggleFavoriteProvider((
                              sticker: sticker,
                              isFavorite: !sticker.isFavorite,
                            )).future,
                          );
                          _updateCustomStickersList();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          // Navigate to send notification with this sticker
                          Navigator.pop(context); // Return to home
                          Navigator.pop(context); // Close custom stickers
                        },
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

  void _showStickerDetail(Sticker sticker) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StickerDetailPage(
          sticker: sticker,
          onUnfavorite: () {
            setState(() {
              _customStickers.removeWhere((s) => s.id == sticker.id);
            });
          },
          onStickerUpdated: (updatedSticker) {
            setState(() {
              final index = _customStickers.indexWhere((s) => s.id == updatedSticker.id);
              if (index != -1) {
                _customStickers[index] = updatedSticker;
              }
            });
          },
        ),
      ),
    );
  }

  Future<void> _showCustomStickerDialog(BuildContext context) async {
    final userId = ref.read(getGeneratedCodeProvider) ?? '';
    await showDialog(
      context: context,
      builder: (context) => CustomStickerDialog(
        userId: userId,
        onStickerCreated: (image, title, message) async {
          await _loadStickers();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Custom Stickers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded),
            onPressed: () => _showCustomStickerDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStickers,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStickers,
              child: _buildStickerGrid(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomStickerDialog(context),
        child: const Icon(Icons.add_photo_alternate_rounded),
      ),
    );
  }
} 