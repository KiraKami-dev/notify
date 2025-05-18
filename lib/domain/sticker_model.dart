import 'package:cloud_firestore/cloud_firestore.dart';

class Sticker {
  final String id;
  final String title;
  final String body;
  final String url;
  bool isFavorite;  // Add this property

  Sticker({
    required this.id,
    required this.title,
    required this.body,
    required this.url,
    this.isFavorite = false,  // default to false
  });

  factory Sticker.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Sticker(
      id: data['sticker_id'] as String,
      title: data['sticker_title'] as String? ?? '',
      body: data['sticker_body'] as String? ?? '',
      url: data['sticker_url'] as String,
      isFavorite: false,  // default, will set later from prefs
    );
  }
}
