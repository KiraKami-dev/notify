import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class NotificationDetailPage extends ConsumerStatefulWidget {
  final String userId;

  const NotificationDetailPage({required this.userId, super.key});

  @override
  ConsumerState<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends ConsumerState<NotificationDetailPage> {
  late Stream<List<NotificationModel>> _notificationsStream;
  String myType = "";
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    myType = ref.read(getTypeUserProvider);
    _initializeStream();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    setState(() {
      _showScrollToBottom = currentScroll < maxScroll - 200;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _initializeStream() {
    _notificationsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('notifications')
        .orderBy('timeStamp', descending: false) // Changed to false to show oldest first
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromDoc(doc)).toList());
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  Widget _buildDateHeader(String date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          date,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBubble(NotificationModel notification, bool isSentByMe) {
    final theme = Theme.of(context);
    final time = DateFormat.jm().format(notification.timeStamp.toDate());
    
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Container(
          margin: EdgeInsets.only(
            left: isSentByMe ? 64 : 8,
            right: isSentByMe ? 8 : 64,
            bottom: 16,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {}, // Add tap effect
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isSentByMe ? 20 : 4),
                bottomRight: Radius.circular(isSentByMe ? 4 : 20),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: isSentByMe 
                      ? theme.colorScheme.primary.withOpacity(0.9)
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isSentByMe ? 20 : 4),
                    bottomRight: Radius.circular(isSentByMe ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (notification.stickerUrl.isNotEmpty)
                      Hero(
                        tag: 'sticker_${notification.notificationId}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.network(
                            notification.stickerUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.messageTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isSentByMe ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.messageBody,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSentByMe 
                                  ? Colors.white.withOpacity(0.9)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSentByMe 
                                      ? Colors.white.withOpacity(0.7)
                                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isSentByMe ? Icons.north_east : Icons.south_west,
                                size: 14,
                                color: isSentByMe 
                                    ? Colors.white.withOpacity(0.7)
                                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Notification History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: theme.colorScheme.surface.withOpacity(0.7),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      floatingActionButton: _showScrollToBottom ? FloatingActionButton.small(
        onPressed: () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
        child: const Icon(Icons.keyboard_arrow_down),
      ) : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: StreamBuilder<List<NotificationModel>>(
          stream: _notificationsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading notifications',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start sending notifications to see them here',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Only scroll to bottom on initial load
            if (!_initialScrollDone) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
                _initialScrollDone = true;
              });
            }

            String? currentDate;
            return SafeArea(
              child: AnimationLimiter(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 80,
                  ),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final date = _formatDate(notification.timeStamp.toDate());
                    final showDate = currentDate != date;
                    if (showDate) {
                      currentDate = date;
                    }

                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Column(
                            children: [
                              if (showDate) _buildDateHeader(date),
                              _buildNotificationBubble(
                                notification,
                                notification.sentBy == myType,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
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