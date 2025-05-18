import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify/data/local_storage/shared_auth.dart';

class LatestNotificationsWidget extends ConsumerStatefulWidget {
  final String userId;

  const LatestNotificationsWidget({required this.userId, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _LatestNotificationsWidgetState();
}

class _LatestNotificationsWidgetState
    extends ConsumerState<LatestNotificationsWidget> {
  List<NotificationModel> oldNotifications = [];

  String getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(date);
  }

  String myType = "";
  @override
  void initState() {
    super.initState();
    getMyType();
  }

  void getMyType() {
    myType = ref.read(getTypeUserProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 1️⃣ Bail out quickly if userId is still blank / null
    if (widget.userId.isEmpty) {
      return Container(
        // you can replace with SizedBox.shrink()
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Loading notifications…',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }
    return StreamBuilder<List<NotificationModel>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('notifications')
          .orderBy('timeStamp', descending: true)
          .limit(2)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => NotificationModel.fromDoc(doc))
                    .toList(),
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(
                    IconlyLight.notification,
                    color: theme.colorScheme.primary,
                  ),
                  Text(
                    'Send your first notification! ',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }

        final dayLabel = getDayLabel(notifications.first.timeStamp.toDate());

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Container(
            key: ValueKey<String>(notifications.first.notificationId),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(dayLabel, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                ...List.generate(notifications.length, (index) {
                  final notif = notifications[index];
                  final timeFormatted = DateFormat.jm().format(
                    notif.timeStamp.toDate(),
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            if (notif.stickerUrl.isNotEmpty)
                              Container(
                                width: 80,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(12),
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(notif.stickerUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 80,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(12),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.messageTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.messageBody,
                                      style: theme.textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    timeFormatted,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: sentRecvIcon(
                                      myType: myType,
                                      sentBy: notif.sentBy,
                                      theme: theme,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

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

Widget sentRecvIcon({
  required String myType,
  required String sentBy,
  required ThemeData theme,
}) {
  final iSent = sentBy == myType;

  return Icon(
    iSent
        ? Icons.south_west
        : Icons.north_east, 
    size: 20,
    color: iSent ? Colors.green : Colors.blueGrey,

  );
}
