import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:notify/presentation/notification/notification_detail_page.dart';
import 'package:notify/core/services/logger.dart';

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
  Stream<List<NotificationModel>>? _notificationsStream;
  String myType = '';

  @override
  void initState() {
    super.initState();
    myType = ref.read(getTypeUserProvider);
    _initializeStream();
  }

  @override
  void didUpdateWidget(LatestNotificationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _initializeStream();
    }
  }

  void _initializeStream() {
    if (widget.userId.isEmpty) {
      _notificationsStream = null;
      return;
    }

    _notificationsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('notifications')
        .orderBy('timeStamp', descending: true)
        .limit(2)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromDoc(doc))
            .toList());
  }

  String getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat('d MMM yyyy').format(date);
  }

  Widget _buildNotificationItem(NotificationModel notif, ThemeData theme, String timeFormatted) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationDetailPage(userId: widget.userId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
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
                    width: 75,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(notif.stickerUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          AppLogger.warn('Error loading notification image', error: exception, stackTrace: stackTrace);
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    width: 75,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications,
                      size: 32,
                      color: Colors.grey,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notif.messageTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.messageBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeFormatted,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      sentRecvIcon(
                        myType: myType,
                        sentBy: notif.sentBy,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyContainer(ThemeData theme, {String? message}) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconlyLight.notification,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              message ?? 'Connect to start receiving notifications',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.userId.isEmpty) {
      return _buildEmptyContainer(theme);
    }

    if (_notificationsStream == null) {
      return _buildEmptyContainer(theme);
    }

    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return _buildEmptyContainer(theme, message: 'Send your first notification!');
        }

        final dayLabel = getDayLabel(notifications.first.timeStamp.toDate());

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(dayLabel, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final timeFormatted = DateFormat.jm().format(
                      notif.timeStamp.toDate(),
                    );
                    return _buildNotificationItem(notif, theme, timeFormatted);
                  },
                ),
              ),
            ],
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
        ? Icons.north_east
        : Icons.south_west , 
    size: 20,
    color: iSent ? Colors.green : Colors.blueGrey,

  );
}
