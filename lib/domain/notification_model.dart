import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String messageBody;
  final String messageTitle;
  final String notificationId;
  final String sentBy;
  final String stickerId;
  final String stickerUrl;
  final Timestamp timeStamp;

  NotificationModel({
    required this.messageBody,
    required this.messageTitle,
    required this.notificationId,
    required this.sentBy,
    required this.stickerId,
    required this.stickerUrl,
    required this.timeStamp,
  });

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      messageBody: data['message_body'] ?? '',
      messageTitle: data['message_title'] ?? '',
      notificationId: data['notification_id'] ?? '',
      sentBy: data['sentBy'] ?? '',
      stickerId: data['sticker_id'] ?? '',
      stickerUrl: data['sticker_url'] ?? '',
      timeStamp: data['timeStamp'] ?? Timestamp.now(),
    );
  }
}