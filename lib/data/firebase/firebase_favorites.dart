import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notify/domain/sticker_model.dart';

class FirebaseFavorites {
  static Future<void> toggleFavorite({
    required String userId,
    required String stickerId,
    required bool isFavorite,
    required Sticker sticker,
  }) async {
    final favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favoriteStickers')
        .doc(stickerId);

    if (isFavorite) {
      await favoritesRef.set({
        'sticker_id': stickerId,
        'sticker_url': sticker.url,
        'sticker_title': sticker.title,
        'sticker_body': sticker.body,
        'timeStamp': Timestamp.now(),
      });
    } else {
      await favoritesRef.delete();
    }
  }

  static Future<List<Sticker>> getFavoriteStickers(String userId) async {
    final favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favoriteStickers')
        .orderBy('timeStamp', descending: false);

    final snapshot = await favoritesRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Sticker(
        id: data['sticker_id'] as String,
        url: data['sticker_url'] as String,
        title: data['sticker_title'] as String,
        body: data['sticker_body'] as String,
        isFavorite: true,
      );
    }).toList();
  }

  static Stream<List<Sticker>> streamFavoriteStickers(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favoriteStickers')
        .orderBy('timeStamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Sticker(
                id: data['sticker_id'] as String,
                url: data['sticker_url'] as String,
                title: data['sticker_title'] as String,
                body: data['sticker_body'] as String,
                isFavorite: true,
              );
            }).toList());
  }
} 