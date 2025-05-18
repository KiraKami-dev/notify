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
}
