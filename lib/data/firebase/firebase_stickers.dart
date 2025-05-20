import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:notify/domain/sticker_model.dart';

class FirebaseStickers {
  static final stickersCollection = FirebaseFirestore.instance.collection(
    'stickers',
  );
  static Future<List<Sticker>> fetchStickers() async {
    final query = await stickersCollection.get();

    return query.docs.map((doc) => Sticker.fromDoc(doc)).toList();
  }

  static Future<String> uploadCustomSticker({
    required String userId,
    required File image,
    required String title,
    required String message,
  }) async {
    try {
      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('custom_stickers')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(image);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      final customStickerId = DateTime.now().millisecondsSinceEpoch.toString();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('customStickers')
          .doc(customStickerId)
          .set({
        'sticker_id': customStickerId,
        'sticker_url': imageUrl,
        'message_title': title,
        'message_body': message,
        'timeStamp': Timestamp.now(),
      });

      return customStickerId;
    } catch (e) {
      print('Error uploading custom sticker: $e');
      rethrow;
    }
  }

  static Future<List<Sticker>> fetchCustomStickers(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('customStickers')
          .orderBy('timeStamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Sticker(
          id: data['sticker_id'] as String,
          url: data['sticker_url'] as String,
          title: data['message_title'] as String,
          body: data['message_body'] as String,
          
        );
      }).toList();
    } catch (e) {
      print('Error fetching custom stickers: $e');
      return [];
    }
  }
}
