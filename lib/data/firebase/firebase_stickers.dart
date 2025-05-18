import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notify/domain/sticker_model.dart';

class FirebaseStickers {
  static final stickersCollection = FirebaseFirestore.instance.collection(
    'stickers',
  );
  static Future<List<Sticker>> fetchStickers() async {
    final query = await stickersCollection.get();

    return query.docs.map((doc) => Sticker.fromDoc(doc)).toList();
  }
}
