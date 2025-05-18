import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:notify/config/const_variables.dart';
import 'package:notify/data/firebase/firebase_connect.dart';
import 'package:notify/data/firebase/firebase_stickers.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:notify/domain/sticker_model.dart';
import 'package:notify/presentation/widgets/connection_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  int _currentImageIndex = 0;
  bool _showFavoritesOnly = false;
  bool connectedStatus = false;
  List<Sticker> stickerItems = [];

  // Sample data - Replace with your actual data
  final List<Map<String, dynamic>> _notifications = [
    {
      'image': 'https://picsum.photos/id/237/200/300',
      'title': 'Good Morning!',
      'message': 'Have a great day ahead!',
      'time': '8:00 AM',
      'sender': 'You',
      'isFavorite': true,
    },
    {
      'image': 'https://picsum.photos/id/238/200/300',
      'title': 'Meeting Reminder',
      'message': 'Team meeting at 2 PM',
      'time': '1:30 PM',
      'sender': 'Partner',
      'isFavorite': false,
    },
    {
      'image': 'https://picsum.photos/id/239/200/300',
      'title': 'Lunch Break',
      'message': 'Time for a healthy lunch!',
      'time': '12:00 PM',
      'sender': 'You',
      'isFavorite': true,
    },
  ];

  // [
  //   {
  //     'image': 'https://picsum.photos/id/237/200/300',
  //     'title': 'Good Morning!',
  //     'message': 'Have a great day ahead!',
  //     'isFavorite': false,
  //   },
  //   {
  //     'image': 'https://picsum.photos/id/238/200/300',
  //     'title': 'Meeting Reminder',
  //     'message': 'Team meeting at 2 PM',
  //     'isFavorite': false,
  //   },
  //   {
  //     'image': 'https://picsum.photos/id/239/200/300',
  //     'title': 'Lunch Break',
  //     'message': 'Time for a healthy lunch!',
  //     'isFavorite': false,
  //   },
  // ];

  @override
  void initState() {
    super.initState();
    _loadPartnerInfo();
  }

  Future<void> loadFavorites() async {
    final favIds = ref.read(getFavoriteIdsProvider); // no .future here
    setState(() {
      for (final s in stickerItems) {
        s.isFavorite = favIds.contains(s.id);
      }
    });
  }

  Future<void> _loadPartnerInfo() async {
    final tempConnectionStatus = ref.read(getConnectedStatusProvider);
    String code = ref.read(getGeneratedCodeProvider);

    if (code.isNotEmpty) {
      bool checkCode = await FirebaseConnect.codeExists(code);

      if (checkCode) {
        connectedStatus = tempConnectionStatus;
      } else {
        connectedStatus = false;
      }
    }

    if (connectedStatus) {
      String typeUser = ref.read(getTypeUserProvider);
      String? partnerToken = await FirebaseConnect.fetchPartnerToken(
        code: code,
        typeUser: typeUser,
      );
      if (partnerToken != null || partnerToken != '') {
        _partnerToken = partnerToken;
      }
    }

    stickerItems = await FirebaseStickers.fetchStickers();
    await loadFavorites();
    setState(() {});
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentImageIndex) {
        _currentImageIndex = page;
        _titleController.text = stickerItems[page].title;
        _messageController.text = stickerItems[page].body;
      }
    });

    // Set initial text from first carousel item
    _titleController.text = stickerItems[0].title;
    _messageController.text = stickerItems[0].body;
    setState(() {});
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    try {
      final response = await http.post(
        Uri.parse(notificaiotnApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': _partnerToken,
          'title': title,
          'body': message,
          'image': stickerItems[_currentImageIndex].url,
        }),
      );

      if (response.statusCode == 200) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight - MediaQuery.of(context).padding.top - kToolbarHeight;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
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
                  builder: (context) => UserConnectionModal(),
                );
              },
              tooltip: 'Connect with someone',
            ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome!',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to history
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _showFavoritesOnly = !_showFavoritesOnly;
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Recent Notifications Section
                Container(
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
                        padding: const EdgeInsets.all(0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Today', style: theme.textTheme.titleMedium),
                          ],
                        ),
                      ),
                      ...List.generate(
                        2,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                            left: Radius.circular(12),
                                          ),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          _notifications[index]['image'],
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            _notifications[index]['title'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _notifications[index]['message'],
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
                                          _notifications[index]['time'],
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        Text(
                                          _notifications[index]['sender'],
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Carousel Section with Switch
                Column(
                  children: [
                    Container(
                      width: 242,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      // decoration: BoxDecoration(
                      //   color: theme.colorScheme.surfaceVariant,
                      //   borderRadius: BorderRadius.circular(12),
                      // ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                icon: Icon(Icons.grid_view),
                                label: Text('All'),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                icon: Icon(Icons.favorite),
                                label: Text('Favorites'),
                              ),
                            ],
                            selected: {_showFavoritesOnly},
                            onSelectionChanged: (Set<bool> newSelection) {
                              setState(() {
                                _showFavoritesOnly = newSelection.first;
                              });
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: availableHeight * 0.31,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount:
                            _showFavoritesOnly
                                ? stickerItems
                                    .where((item) => item.isFavorite)
                                    .length
                                : stickerItems.length,
                        itemBuilder: (context, index) {
                          final items =
                              _showFavoritesOnly
                                  ? stickerItems
                                      .where((item) => item.isFavorite)
                                      .toList()
                                  : stickerItems;
                          final item = items[index];
                          return AnimatedScale(
                            scale: _currentImageIndex == index ? 1.0 : 0.9,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 5.0,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(item.url, fit: BoxFit.cover),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface
                                              .withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            item.isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
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
                                                  !item.isFavorite;
                                            });
                                            await ref.read(
                                              toggleFavoriteIdProvider(
                                                stickerId: item.id,
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

                const SizedBox(height: 16),

                // Message Fields
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // how tall are the non‑message widgets (title + gap)?
                      const _titleHeight = 56.0; // TextFormField default
                      const _gap = 12.0;
                      const _btnHeight = 56.0; // send button, below this column
                      const _padding = 32.0; // top/bottom padding you added
                      final remaining =
                          constraints.maxHeight -
                          (_titleHeight + _gap + _btnHeight + _padding);

                      final bool canExpand =
                          remaining > 120; // you decide the threshold

                      return Column(
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Message Title',
                              hintText: 'Enter a title for your message',
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.isEmpty)
                                        ? 'Please enter a title'
                                        : null,
                          ),
                          const SizedBox(height: 12),

                          // ── message field ──
                          TextFormField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              labelText: 'Your Message',
                              hintText: 'Type your message here…',
                              prefixIcon: Icon(Icons.message),
                              alignLabelWithHint: true,
                            ),
                            keyboardType: TextInputType.multiline,
                            expands: canExpand,
                            minLines: canExpand ? null : 2,
                            maxLines: canExpand ? null : 2,
                            validator:
                                (v) =>
                                    (v == null || v.isEmpty)
                                        ? 'Please enter a message'
                                        : null,
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Send Button
                ElevatedButton.icon(
                  onPressed:
                      _isLoading || connectedStatus == false
                          ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Please connect with user first!',
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send),
                  label: Text(_isLoading ? 'Sending...' : 'Send Message'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
