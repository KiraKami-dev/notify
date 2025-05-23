import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:notify/config/const_variables.dart';
import 'package:notify/data/firebase/firebase_connect.dart';
import 'package:notify/data/firebase/firebase_favorites.dart';
import 'package:notify/data/firebase/firebase_notification.dart';
import 'package:notify/data/firebase/firebase_stickers.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:notify/domain/sticker_model.dart';
import 'package:notify/presentation/todo/todo_page.dart';
import 'package:notify/presentation/widgets/connection_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify/presentation/widgets/latest_notification_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notify/presentation/notification/notification_detail_page.dart';
import 'package:notify/presentation/favorites/favorites_page.dart';
import 'package:notify/presentation/custom_stickers/custom_stickers_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:notify/presentation/widgets/custom_sticker_dialog.dart';
import 'package:notify/presentation/widgets/custom_sticker_view.dart';
import 'package:notify/data/providers/favorite_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:notify/data/providers/profile_provider.dart';
import 'package:notify/domain/user_profile_model.dart';
import 'package:notify/presentation/widgets/profile_dialog.dart';

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
  final _mainPageController = PageController();
  bool _isLoading = false;
  String? _partnerStatus;
  String? _partnerToken;
  String generatedCode = "";
  String myType = "";
  int _currentImageIndex = 0;
  StickerViewType _currentViewType = StickerViewType.all;
  bool connectedStatus = false;
  List<Sticker> stickerItems = [];
  List<Sticker> customStickerItems = [];
  File? _customImage;
  List<Sticker> _favoriteStickers = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPartnerInfo();
    _mainPageController.addListener(() {
      if (_mainPageController.page != null) {
        setState(() {
          _currentPage = _mainPageController.page!.round();
        });
      }
    });
  }

  Future<void> _loadPartnerInfo() async {
    try {
      print('Loading partner info...');

      // Initialize empty lists/values if null
      stickerItems = stickerItems ?? [];
      customStickerItems = customStickerItems ?? [];
      _favoriteStickers = _favoriteStickers ?? [];
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

      // Load initial stickers
      await _loadInitialStickers();

      if (mounted) {
        setState(() {});
      }

      _pageController.addListener(() {
        if (!mounted) return;
        final page = _pageController.page?.round() ?? 0;
        if (page != _currentImageIndex) {
          setState(() {
            _currentImageIndex = page;
          });
          _updateMessageFields();
        }
      });

      // Set initial text from first carousel item
      if (stickerItems.isNotEmpty) {
        _updateMessageFields();
      }
    } catch (e, stackTrace) {
      print('Error loading partner info: $e');
      print('Stack trace: $stackTrace');
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

  Future<void> _loadInitialStickers() async {
    try {
      final fetchedStickers = await FirebaseStickers.fetchStickers();
      if (fetchedStickers != null) {
        setState(() {
          stickerItems = fetchedStickers;
        });
        print('Stickers fetched: ${stickerItems.length}');
      } else {
        print('No stickers returned from Firebase');
        stickerItems = [];
      }
    } catch (e) {
      print('Error fetching stickers: $e');
      stickerItems = [];
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _pageController.dispose();
    _mainPageController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteStickers() async {
    if (customStickerItems.isEmpty && generatedCode.isNotEmpty) {
      await _loadCustomStickers();
    }

    final favoriteStickers = await FirebaseFavorites.getFavoriteStickers(
      generatedCode,
    );

    if (mounted) {
      setState(() {
        _favoriteStickers = favoriteStickers;
      });
    }
  }

  Future<void> _loadCustomStickers() async {
    if (generatedCode.isNotEmpty) {
      try {
        final fetchedCustomStickers =
            await FirebaseStickers.fetchCustomStickers(generatedCode);
        final favoriteStickers = await FirebaseFavorites.getFavoriteStickers(
          generatedCode,
        );
        final favoriteIds = favoriteStickers.map((s) => s.id).toSet();

        // Update favorites in a single pass
        for (var sticker in fetchedCustomStickers) {
          sticker.isFavorite = favoriteIds.contains(sticker.id);
        }

        if (mounted) {
          setState(() {
            customStickerItems = fetchedCustomStickers;
          });
        }
        print('Custom stickers fetched: ${customStickerItems.length}');
      } catch (e) {
        print('Error fetching custom stickers: $e');
        if (mounted) {
          setState(() {
            customStickerItems = [];
          });
        }
      }
    }
  }

  void _updateMessageFields() {
    if (!mounted) return;

    List<Sticker> currentStickers;
    switch (_currentViewType) {
      case StickerViewType.favorites:
        currentStickers = _favoriteStickers;
        break;
      case StickerViewType.custom:
        currentStickers = customStickerItems;
        break;
      case StickerViewType.all:
      default:
        currentStickers = stickerItems;
        break;
    }

    if (currentStickers.isNotEmpty &&
        _currentImageIndex < currentStickers.length) {
      setState(() {
        _titleController.text = currentStickers[_currentImageIndex].title ?? '';
        _messageController.text =
            currentStickers[_currentImageIndex].body ?? '';
      });
    } else {
      setState(() {
        _titleController.text = '';
        _messageController.text = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    // final availableHeight =
    //     screenHeight - MediaQuery.of(context).padding.top - kToolbarHeight;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text(
          'Notify',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(_currentPage == 1 ? Icons.notifications : Icons.checklist),
          onPressed: () {
            _mainPageController.animateToPage(
              _currentPage == 0 ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        actions: [
          if (connectedStatus)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),
          if (!connectedStatus)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => UserConnectionModal(
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
      endDrawer: connectedStatus ? _buildDrawer(context, ref) : null,
      body: SafeArea(
        child: PageView(
          controller: _mainPageController,
          children: [
            Column(
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
                            height: MediaQuery.of(context).size.height * 0.243,
                            child: LatestNotificationsWidget(
                              userId: generatedCode,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Carousel Section with Switch
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.35,
                            child: Column(
                              children: [
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
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
                                            icon: Icon(
                                              Icons.grid_view,
                                              size: 18,
                                            ),
                                            label: Text(
                                              'Collection',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          ButtonSegment<StickerViewType>(
                                            value: StickerViewType.favorites,
                                            icon: Icon(
                                              Icons.favorite,
                                              size: 18,
                                            ),
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
                                        ) async {
                                          setState(() {
                                            _currentViewType = selected.first;
                                            _currentImageIndex = 0;
                                          });

                                          // Load data based on selected view type
                                          if (_currentViewType ==
                                              StickerViewType.custom) {
                                            await _loadCustomStickers();
                                          } else if (_currentViewType ==
                                              StickerViewType.favorites) {
                                            await _loadFavoriteStickers();
                                          }

                                          _updateMessageFields();
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
                                  child: _currentViewType ==
                                          StickerViewType.custom
                                      ? customStickerItems.isEmpty
                                          ? CustomStickerView(
                                              onAddPressed: () =>
                                                  _showCustomStickerDialog(
                                                context,
                                              ),
                                            )
                                          : PageView.builder(
                                              controller: _pageController,
                                              itemCount:
                                                  customStickerItems.length,
                                              itemBuilder: (context, index) {
                                                final item =
                                                    customStickerItems[index];
                                                return AnimatedScale(
                                                  scale: _currentImageIndex ==
                                                          index
                                                      ? 1.0
                                                      : 0.9,
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  child: Container(
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 5.0,
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        16,
                                                      ),
                                                      child: Stack(
                                                        fit: StackFit.expand,
                                                        children: [
                                                          _buildStickerImage(
                                                            item.url,
                                                          ),
                                                          Positioned(
                                                            top: 8,
                                                            right: 8,
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: theme
                                                                    .colorScheme
                                                                    .surface
                                                                    .withOpacity(
                                                                  0.8,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  20,
                                                                ),
                                                              ),
                                                              child: IconButton(
                                                                icon: Icon(
                                                                  item.isFavorite
                                                                      ? Icons
                                                                          .favorite
                                                                      : Icons
                                                                          .favorite_border,
                                                                  color: item
                                                                          .isFavorite
                                                                      ? Colors
                                                                          .red
                                                                      : theme
                                                                          .colorScheme
                                                                          .onSurface,
                                                                ),
                                                                onPressed:
                                                                    () async {
                                                                  setState(() {
                                                                    item.isFavorite =
                                                                        !item
                                                                            .isFavorite;
                                                                  });
                                                                  await ref
                                                                      .read(
                                                                    toggleFavoriteProvider((
                                                                      sticker:
                                                                          item,
                                                                      isFavorite:
                                                                          item.isFavorite,
                                                                    )).future,
                                                                  );
                                                                  if (_currentViewType ==
                                                                      StickerViewType
                                                                          .favorites) {
                                                                    await _loadFavoriteStickers();
                                                                  }
                                                                  _updateMessageFields();
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
                                            )
                                      : _currentViewType ==
                                              StickerViewType.favorites
                                          ? _favoriteStickers.isEmpty
                                              ? Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.favorite_border,
                                                        size: 48,
                                                        color: theme.colorScheme
                                                            .onSurfaceVariant
                                                            .withOpacity(0.5),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'No favorite stickers yet',
                                                        style: theme.textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .onSurfaceVariant
                                                              .withOpacity(
                                                            0.7,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : PageView.builder(
                                                  controller: _pageController,
                                                  itemCount:
                                                      _favoriteStickers.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final item =
                                                        _favoriteStickers[
                                                            index];
                                                    return AnimatedScale(
                                                      scale:
                                                          _currentImageIndex ==
                                                                  index
                                                              ? 1.0
                                                              : 0.9,
                                                      duration: const Duration(
                                                        milliseconds: 200,
                                                      ),
                                                      child: Container(
                                                        margin: const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 5.0,
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            16,
                                                          ),
                                                          child: Stack(
                                                            fit:
                                                                StackFit.expand,
                                                            children: [
                                                              _buildStickerImage(
                                                                item.url,
                                                              ),
                                                              Positioned(
                                                                top: 8,
                                                                right: 8,
                                                                child:
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: theme
                                                                        .colorScheme
                                                                        .surface
                                                                        .withOpacity(
                                                                      0.8,
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                      20,
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      IconButton(
                                                                    icon: Icon(
                                                                      item.isFavorite
                                                                          ? Icons
                                                                              .favorite
                                                                          : Icons
                                                                              .favorite_border,
                                                                      color: item.isFavorite
                                                                          ? Colors
                                                                              .red
                                                                          : theme
                                                                              .colorScheme
                                                                              .onSurface,
                                                                    ),
                                                                    onPressed:
                                                                        () async {
                                                                      setState(
                                                                          () {
                                                                        item.isFavorite =
                                                                            !item.isFavorite;
                                                                      });
                                                                      await ref
                                                                          .read(
                                                                        toggleFavoriteProvider((
                                                                          sticker:
                                                                              item,
                                                                          isFavorite:
                                                                              item.isFavorite,
                                                                        )).future,
                                                                      );
                                                                      if (_currentViewType ==
                                                                          StickerViewType
                                                                              .favorites) {
                                                                        await _loadFavoriteStickers();
                                                                      }
                                                                      _updateMessageFields();
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
                                                )
                                          : PageView.builder(
                                              controller: _pageController,
                                              itemCount: _currentViewType ==
                                                      StickerViewType.favorites
                                                  ? stickerItems
                                                      .where(
                                                        (item) =>
                                                            item.isFavorite,
                                                      )
                                                      .length
                                                  : stickerItems.length,
                                              itemBuilder: (context, index) {
                                                final items =
                                                    _currentViewType ==
                                                            StickerViewType
                                                                .favorites
                                                        ? stickerItems
                                                            .where(
                                                              (item) => item
                                                                  .isFavorite,
                                                            )
                                                            .toList()
                                                        : stickerItems;
                                                final item = items[index];
                                                return AnimatedScale(
                                                  scale: _currentImageIndex ==
                                                          index
                                                      ? 1.0
                                                      : 0.9,
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  child: Container(
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 5.0,
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        16,
                                                      ),
                                                      child: Stack(
                                                        fit: StackFit.expand,
                                                        children: [
                                                          _buildStickerImage(
                                                            item.url,
                                                          ),
                                                          Positioned(
                                                            top: 8,
                                                            right: 8,
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: theme
                                                                    .colorScheme
                                                                    .surface
                                                                    .withOpacity(
                                                                  0.8,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                  20,
                                                                ),
                                                              ),
                                                              child: IconButton(
                                                                icon: Icon(
                                                                  item.isFavorite
                                                                      ? Icons
                                                                          .favorite
                                                                      : Icons
                                                                          .favorite_border,
                                                                  color: item
                                                                          .isFavorite
                                                                      ? Colors
                                                                          .red
                                                                      : theme
                                                                          .colorScheme
                                                                          .onSurface,
                                                                ),
                                                                onPressed:
                                                                    () async {
                                                                  setState(() {
                                                                    item.isFavorite =
                                                                        !item
                                                                            .isFavorite;
                                                                  });
                                                                  await ref
                                                                      .read(
                                                                    toggleFavoriteProvider((
                                                                      sticker:
                                                                          item,
                                                                      isFavorite:
                                                                          item.isFavorite,
                                                                    )).future,
                                                                  );
                                                                  if (_currentViewType ==
                                                                      StickerViewType
                                                                          .favorites) {
                                                                    await _loadFavoriteStickers();
                                                                  }
                                                                  _updateMessageFields();
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
                                  validator: (v) => (v == null || v.isEmpty)
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
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Please enter a message'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (_currentViewType ==
                                        StickerViewType.custom)
                                      const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading ||
                                                connectedStatus == false
                                            ? () {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      'Please connect with user first!',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        10,
                                                      ),
                                                    ),
                                                    margin:
                                                        const EdgeInsets.all(
                                                      16,
                                                    ),
                                                  ),
                                                );
                                              }
                                            : _sendMessage,
                                        icon: _isLoading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.send),
                                        label: Text(
                                          _isLoading
                                              ? 'Sending...'
                                              : 'Send Message',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(
                                            double.infinity,
                                            48,
                                          ),
                                          backgroundColor:
                                              theme.colorScheme.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (_currentViewType ==
                                        StickerViewType.custom)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.add_photo_alternate_rounded,
                                            color:
                                                theme.colorScheme.onSecondary,
                                          ),
                                          onPressed: () =>
                                              _showCustomStickerDialog(
                                            context,
                                          ),
                                          style: IconButton.styleFrom(
                                            padding: const EdgeInsets.all(12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
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
              ],
            ),
            TodoPage(),
            // Home Page
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
      if (_currentViewType == StickerViewType.custom) {
        // Get the URL from the custom sticker items
        if (customStickerItems.isNotEmpty &&
            _currentImageIndex < customStickerItems.length) {
          imageUrl = customStickerItems[_currentImageIndex].url;
        }
      } else {
        // Get the URL from the regular sticker items
        if (stickerItems.isNotEmpty &&
            _currentImageIndex < stickerItems.length) {
          imageUrl = stickerItems[_currentImageIndex].url;
        }
      }

      if (imageUrl.isEmpty) {
        throw 'No valid sticker selected';
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
          stickerId: _currentViewType == StickerViewType.custom
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
      _showSnackBar('Failed to send message: $error', Colors.red);
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
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Confirm Disconnect'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to Disconnect?',
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
            child: const Text('Disconnect'),
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
      _showSnackBar('Failed to Disconnect: $error', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showCustomStickerDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => CustomStickerDialog(
        userId: generatedCode,
        onStickerCreated: (File image, String title, String message) async {
          // Refresh custom stickers list
          final fetchedCustomStickers =
              await FirebaseStickers.fetchCustomStickers(generatedCode);
          setState(() {
            customStickerItems = fetchedCustomStickers;
            _currentImageIndex = 0; // Reset to first sticker
          });
          _updateMessageFields(); // Update message fields with new sticker
        },
      ),
    );
  }

  Widget _buildStickerImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.grey, size: 40),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.read(getGeneratedCodeProvider) ?? '';
    final userProfileAsync = ref.watch(userProfileProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
            ),
            child: DrawerHeader(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showProfileDialog(context, ref),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: userProfileAsync.when(
                                data: (profile) => CircleAvatar(
                                  radius: 35,
                                  backgroundColor: theme.colorScheme.surface,
                                  backgroundImage: profile?.avatarUrl != null
                                      ? NetworkImage(profile!.avatarUrl!)
                                      : null,
                                  child: profile?.avatarUrl == null
                                      ? Icon(
                                          Icons.person,
                                          size: 35,
                                          color: theme.colorScheme.onSurface,
                                        )
                                      : null,
                                ),
                                loading: () => const CircleAvatar(
                                  radius: 35,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                error: (_, __) => CircleAvatar(
                                  radius: 35,
                                  backgroundColor: theme.colorScheme.surface,
                                  child: Icon(
                                    Icons.error_outline,
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: theme.colorScheme.onSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 8),
                                Text(
                                  'Welcome!',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            userProfileAsync.when(
                              data: (profile) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        profile?.mood ??
                                            'How\'s your heart feeling?',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              loading: () => const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              error: (_, __) => Text(
                                'Error loading mood',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
                  builder: (context) => NotificationDetailPage(userId: userId),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite_rounded),
            title: const Text('Favorites'),
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
          ListTile(
            leading: const Icon(Icons.add_photo_alternate_rounded),
            title: const Text('Custom Stickers'),
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
                  builder: (context) => const CustomStickersPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: _isLoading
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
              _isLoading ? 'Disconneting...' : 'Disconnet',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            enabled: !_isLoading,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileDialog(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(getGeneratedCodeProvider) ?? '';
    final currentProfile = await ref.read(userProfileProvider.future);

    await showDialog(
      context: context,
      builder: (context) => ProfileDialog(
        userId: userId,
        currentProfile: currentProfile,
        onProfileUpdated: (updatedProfile) {
          ref.invalidate(userProfileProvider);
        },
      ),
    );
  }
}
