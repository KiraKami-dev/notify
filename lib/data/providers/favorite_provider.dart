import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify/data/firebase/firebase_favorites.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:notify/domain/sticker_model.dart';

final favoriteStickersProvider = StreamProvider<List<Sticker>>((ref) {
  final userId = ref.watch(getGeneratedCodeProvider);
  if (userId == null || userId.isEmpty) {
    return Stream.value([]);
  }
  return FirebaseFavorites.streamFavoriteStickers(userId);
});

final toggleFavoriteProvider = FutureProvider.family<void, ({Sticker sticker, bool isFavorite})>((ref, params) async {
  final userId = ref.read(getGeneratedCodeProvider);
  if (userId == null || userId.isEmpty) {
    throw Exception('User ID is not available');
  }
  
  await FirebaseFavorites.toggleFavorite(
    userId: userId,
    stickerId: params.sticker.id,
    isFavorite: params.isFavorite,
    sticker: params.sticker,
  );
}); 