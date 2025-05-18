import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notify/domain/notification_model.dart';

class FirebaseNotifications {
  Stream<List<NotificationModel>> streamLatestNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timeStamp', descending: true)
        .limit(2)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationModel.fromDoc(doc))
                  .toList(),
        );
  }

  static Future<void> addNotification({
    required String targetUserId,
    required String title,
    required String body,
    required String stickerId,
    required String stickerUrl,
    required String sentBy,
  }) async {
    final now = Timestamp.now();
    final notifDoc =
        FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .collection('notifications')
            .doc();

    await notifDoc.set({
      'message_title': title,
      'message_body': body,
      'notification_id': notifDoc.id,
      'sentBy': sentBy,
      'sticker_id': stickerId,
      'sticker_url': stickerUrl,
      'timeStamp': now,
    });
  }
}
