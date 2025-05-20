import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:notify/config/const_variables.dart';
import 'package:notify/data/firebase/firebase_connect.dart';
import 'package:notify/data/firebase/firebase_notification.dart';
import 'package:notify/data/firebase/firebase_stickers.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:notify/domain/sticker_model.dart';
import 'package:notify/presentation/widgets/connection_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify/presentation/widgets/latest_notification_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notify/presentation/notification/notification_detail_page.dart';
import 'package:notify/presentation/favorites/favorites_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:notify/presentation/widgets/custom_sticker_dialog.dart';
import 'package:notify/presentation/widgets/custom_sticker_view.dart';

enum StickerViewType { all, favorites, custom }

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _pageController = PageController(viewportFraction: 0.85);
  bool _isLoading = false;
  String? _partnerStatus;
  String? _partnerToken;
  String generatedCode = "";
  String myType = "";
  int _currentImageIndex = 0;
  StickerViewType _currentViewType = StickerViewType.all;
  bool connectedStatus = false;
  List<Sticker> stickerItems = [];
  File? _customImage;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPartnerInfo();
  }

  Future<void> _loadPartnerInfo() async {
    try {
      print('Loading partner info...');

      // Initialize empty lists/values if null
      stickerItems = stickerItems ?? [];
      _partnerToken = _partnerToken ?? '';
      myType = myType ?? '';

      final tempConnectionStatus = ref.read(getConnectedStatusProvider);
      String code = ref.read(getGeneratedCodeProvider) ?? '';
      print('Connection status: $tempConnectionStatus, Code: $code');

      if (code.isNotEmpty) {
        bool checkCode = await FirebaseConnect.codeExists(code);
        print('Code exists: $checkCode');

        if (checkCode) {
          setState(() {
            connectedStatus = tempConnectionStatus;
            generatedCode = code;
          });
        } else {
          setState(() {
            connectedStatus = false;
            generatedCode = "";
          });
        }
      } else {
        setState(() {
          connectedStatus = false;
          generatedCode = "";
        });
      }

      if (connectedStatus) {
        myType = ref.read(getTypeUserProvider) ?? '';
        String? partnerToken = await FirebaseConnect.fetchPartnerToken(
          code: code,
          typeUser: myType,
        );
        print('Partner token: $partnerToken');
        if (partnerToken != null && partnerToken.isNotEmpty) {
          setState(() {
            _partnerToken = partnerToken;
          });
        }
      }

      print('Fetching stickers...');
      try {
        final fetchedStickers = await FirebaseStickers.fetchStickers();
        if (fetchedStickers != null) {
          stickerItems = fetchedStickers;
          print('Stickers fetched: ${stickerItems.length}');
        } else {
          print('No stickers returned from Firebase');
          stickerItems = [];
        }
      } catch (e) {
        print('Error fetching stickers: $e');
        stickerItems = [];
      }

      if (mounted) {
        setState(() {});
      }

      try {
        await loadFavorites();
      } catch (e) {
        print('Error loading favorites: $e');
      }

      if (mounted) {
        setState(() {});
      }

      _pageController.addListener(() {
        if (!mounted) return;
        final page = _pageController.page?.round() ?? 0;
        if (page != _currentImageIndex &&
            stickerItems.isNotEmpty &&
            page < stickerItems.length) {
          setState(() {
            _currentImageIndex = page;
            _titleController.text = stickerItems[page].title ?? '';
            _messageController.text = stickerItems[page].body ?? '';
          });
        }
      });

      // Set initial text from first carousel item
      if (stickerItems.isNotEmpty) {
        setState(() {
          _titleController.text = stickerItems[0].title ?? '';
          _messageController.text = stickerItems[0].body ?? '';
        });
      }
    } catch (e, stackTrace) {
      print('Error loading partner info: $e');
      print('Stack trace: $stackTrace');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    // final availableHeight =
    //     screenHeight - MediaQuery.of(context).padding.top - kToolbarHeight;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Latest Notifications
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                        child: LatestNotificationsWidget(userId: generatedCode),
                      ),

                      const SizedBox(height: 4),

                      // Carousel Section with Switch
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.35,
                        child: Column(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SegmentedButton<StickerViewType>(
                                    segments: const [
                                      ButtonSegment<StickerViewType>(
                                        value: StickerViewType.all,
                                        icon: Icon(Icons.grid_view, size: 18),
                                        label: Text(
                                          'All',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      ButtonSegment<StickerViewType>(
                                        value: StickerViewType.favorites,
                                        icon: Icon(Icons.favorite, size: 18),
                                        label: Text(
                                          'Favorites',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      ButtonSegment<StickerViewType>(
                                        value: StickerViewType.custom,
                                        icon: Icon(
                                          Icons.add_photo_alternate,
                                          size: 18,
                                        ),
                                        label: Text(
                                          'Custom',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                    selected: {_currentViewType},
                                    onSelectionChanged: (
                                      Set<StickerViewType> selected,
                                    ) {
                                      setState(() {
                                        _currentViewType = selected.first;
                                      });
                                    },
                                    showSelectedIcon: false,
                                    style: ButtonStyle(
                                      visualDensity: VisualDensity.compact,
                                      padding: MaterialStateProperty.all(
                                        const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _currentViewType == StickerViewType.custom
                                  ? CustomStickerView(
                                      onAddPressed: () => _showCustomStickerDialog(context),
                                    )
                                  : PageView.builder(
                                      controller: _pageController,
                                      itemCount:
                                          _currentViewType ==
                                                  StickerViewType.favorites
                                              ? stickerItems
                                                  .where(
                                                    (item) => item.isFavorite,
                                                  )
                                                  .length
                                              : stickerItems.length,
                                      itemBuilder: (context, index) {
                                        final items =
                                            _currentViewType ==
                                                    StickerViewType.favorites
                                                ? stickerItems
                                                    .where(
                                                      (item) =>
                                                          item.isFavorite,
                                                    )
                                                    .toList()
                                                : stickerItems;
                                        final item = items[index];
                                        return AnimatedScale(
                                          scale:
                                              _currentImageIndex == index
                                                  ? 1.0
                                                  : 0.9,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: Container(
                                            margin:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 5.0,
                                                ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.network(
                                                    item.url,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: theme
                                                            .colorScheme
                                                            .surface
                                                            .withOpacity(0.8),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      child: IconButton(
                                                        icon: Icon(
                                                          item.isFavorite
                                                              ? Icons.favorite
                                                              : Icons
                                                                  .favorite_border,
                                                          color:
                                                              item.isFavorite
                                                                  ? Colors.red
                                                                  : theme
                                                                      .colorScheme
                                                                      .onSurface,
                                                        ),
                                                        onPressed: () async {
                                                          setState(() {
                                                            item.isFavorite =
                                                                !item
                                                                    .isFavorite;
                                                          });
                                                          await ref.read(
                                                            toggleFavoriteIdProvider(
                                                              stickerId:
                                                                  item.id,
                                                            ).future,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Message Fields and Send Button
                      Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              MediaQuery.of(context).viewInsets.bottom > 0
                                  ? 8
                                  : 0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Message Title',
                                hintText: 'Enter a title for your message',
                                prefixIcon: Icon(Icons.title),
                                filled: true,
                              ),
                              validator:
                                  (v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Please enter a title'
                                          : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                labelText: 'Your Message',
                                hintText: 'Type your message here…',
                                prefixIcon: Icon(Icons.message),
                                alignLabelWithHint: true,
                                filled: true,
                              ),
                              keyboardType: TextInputType.multiline,
                              minLines: 2,
                              maxLines: 3,
                              validator:
                                  (v) =>
                                      (v == null || v.isEmpty)
                                          ? 'Please enter a message'
                                          : null,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed:
                                  _isLoading || connectedStatus == false
                                      ? () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Please connect with user first!',
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      }
                                      : _sendMessage,
                              icon:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(Icons.send),
                              label: Text(
                                _isLoading ? 'Sending...' : 'Send Message',
                              ),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text(
          'Notify',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          if (!connectedStatus)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) => UserConnectionModal(
                        fetch: () {
                          _loadPartnerInfo();
                        },
                      ),
                );
              },
              tooltip: 'Connect with someone',
            ),
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              // decoration: BoxDecoration(
              //   gradient: LinearGradient(
              //     begin: Alignment.topLeft,
              //     end: Alignment.bottomRight,
              //     colors: [
              //       theme.colorScheme.primary,
              //       theme.colorScheme.primary.withOpacity(0.8),
              //     ],
              //   ),
              // ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Welcome!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_rounded),
                    title: const Text('Home'),
                    selected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: const Text('History'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  NotificationDetailPage(userId: generatedCode),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite_rounded),
                    title: const Text('Favorites'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'New',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        _isLoading
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.error,
                              ),
                            )
                            : Icon(
                              Icons.logout_rounded,
                              color: theme.colorScheme.error,
                            ),
                    title: Text(
                      _isLoading ? 'Logging out...' : 'Logout',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    enabled: !_isLoading,
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    try {
      String imageUrl = '';
      if (_currentViewType == StickerViewType.custom && _customImage != null) {
        // TODO: Implement image upload to Firebase Storage
        // For now, we'll use a placeholder URL
        imageUrl = 'https://placeholder.com/custom-image';
      } else {
        imageUrl = stickerItems[_currentImageIndex].url;
      }

      final response = await http.post(
        Uri.parse(notificaiotnApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': _partnerToken,
          'title': title,
          'body': message,
          'image': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        await FirebaseNotifications.addNotification(
          targetUserId: generatedCode,
          title: title,
          body: message,
          stickerId:
              _currentViewType == StickerViewType.custom
                  ? 'custom'
                  : stickerItems[_currentImageIndex].id,
          stickerUrl: imageUrl,
          sentBy: myType,
        );
        _showSnackBar('Message sent successfully!', Colors.green);
      } else {
        throw 'Server returned status code: ${response.statusCode}';
      }
    } catch (error) {
      _showSnackBar('Failed to send message', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> loadFavorites() async {
    try {
      final favIds = ref.read(getFavoriteIdsProvider);
      if (mounted) {
        setState(() {
          for (final s in stickerItems) {
            s.isFavorite = favIds.contains(s.id);
          }
        });
      }
    } catch (e) {
      print('Error in loadFavorites: $e');
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                const Text('Confirm Logout'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to logout?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'This will delete all your notifications and disconnect from your partner.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Delete notifications subcollection
      if (generatedCode.isNotEmpty) {
        final notificationsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(generatedCode)
            .collection('notifications');

        final notifications = await notificationsRef.get();
        for (final doc in notifications.docs) {
          await doc.reference.delete();
        }

        // Delete the user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(generatedCode)
            .delete();
      }

      // Clear all shared preferences except mainTokenId
      final prefs = await SharedPreferences.getInstance();
      final mainTokenId = prefs.getString('mainTokenId'); // Save mainTokenId
      await prefs.clear(); // Clear everything
      if (mainTokenId != null) {
        await prefs.setString(
          'mainTokenId',
          mainTokenId,
        ); // Restore mainTokenId
      }

      // Reset local state
      setState(() {
        connectedStatus = false;
        generatedCode = "";
        myType = "";
        _partnerToken = null;
        _partnerStatus = null;
        stickerItems.forEach((sticker) => sticker.isFavorite = false);
      });

      if (mounted) {
        _showSnackBar('Logged out successfully', Colors.green);
        Navigator.pop(context); // Close drawer
      }
    } catch (error) {
      _showSnackBar('Failed to logout: $error', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showCustomStickerDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => CustomStickerDialog(
        userId: generatedCode,
        onStickerCreated: (File image, String title, String message) {
          setState(() {
            _customImage = image;
            _titleController.text = title;
            _messageController.text = message;
          });
        },
      ),
    );
  }
}
