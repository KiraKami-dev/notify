import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:notify/config/const_variables.dart';
import 'package:notify/presentation/widgets/connection_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  // Sample data - Replace with your actual data
  final List<Map<String, dynamic>> _notifications = [
    {
      'image': 'https://picsum.photos/id/237/200/300',
      'title': 'Good Morning!',
      'message': 'Have a great day ahead!',
      'time': '8:00 AM',
      'isFavorite': true,
    },
    {
      'image': 'https://picsum.photos/id/238/200/300',
      'title': 'Meeting Reminder',
      'message': 'Team meeting at 2 PM',
      'time': '1:30 PM',
      'isFavorite': false,
    },
    {
      'image': 'https://picsum.photos/id/239/200/300',
      'title': 'Lunch Break',
      'message': 'Time for a healthy lunch!',
      'time': '12:00 PM',
      'isFavorite': true,
    },
  ];

  final List<Map<String, dynamic>> _carouselItems = [
    {
      'image': 'https://picsum.photos/id/237/200/300',
      'title': 'Good Morning!',
      'message': 'Have a great day ahead!',
    },
    {
      'image': 'https://picsum.photos/id/238/200/300',
      'title': 'Meeting Reminder',
      'message': 'Team meeting at 2 PM',
    },
    {
      'image': 'https://picsum.photos/id/239/200/300',
      'title': 'Lunch Break',
      'message': 'Time for a healthy lunch!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPartnerInfo();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentImageIndex) {
        setState(() {
          _currentImageIndex = page;
          _titleController.text = _carouselItems[page]['title'];
          _messageController.text = _carouselItems[page]['message'];
        });
      }
    });
  }

  Future<void> _loadPartnerInfo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _partnerStatus = null;
      _partnerToken = null;
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFavorite(int index) {
    setState(() {
      _notifications[index]['isFavorite'] =
          !_notifications[index]['isFavorite'];
    });
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final tokenId = _tokenController.text.trim();
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    try {
      final response = await http.post(
        Uri.parse(notificaiotnApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': tokenId,
          'title': title,
          'body': message,
          'image': _carouselItems[_currentImageIndex]['image'],
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Message sent successfully!', Colors.green);
        _titleController.clear();
        _messageController.clear();
      } else {
        throw 'Server returned status code: ${response.statusCode}';
      }
    } catch (error) {
      print('Error sending message: $error');
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
    final availableHeight = screenHeight - MediaQuery.of(context).padding.top - kToolbarHeight;

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
      drawer: Drawer(
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
            padding: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Latest Notifications',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      ...List.generate(
                        2,
                        (index) => ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _notifications[index]['image'],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            _notifications[index]['title'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _notifications[index]['message'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(_notifications[index]['time']),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Carousel Section with Switch
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Image Gallery',
                            style: theme.textTheme.titleMedium,
                          ),
                          Row(
                            children: [
                              Text(
                                'Show Favorites',
                                style: theme.textTheme.bodySmall,
                              ),
                              Switch(
                                value: _showFavoritesOnly,
                                onChanged: (value) {
                                  setState(() {
                                    _showFavoritesOnly = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: availableHeight * 0.3, // 30% of available height
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _showFavoritesOnly
                            ? _carouselItems.where((item) => item['isFavorite'] ?? false).length
                            : _carouselItems.length,
                        itemBuilder: (context, index) {
                          final items = _showFavoritesOnly
                              ? _carouselItems.where((item) => item['isFavorite'] ?? false).toList()
                              : _carouselItems;
                          final item = items[index];
                          return AnimatedScale(
                            scale: _currentImageIndex == index ? 1.0 : 0.9,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      item['image'],
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 16,
                                      right: 16,
                                      child: IconButton(
                                        icon: Icon(
                                          item['isFavorite'] ?? false
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            item['isFavorite'] = !(item['isFavorite'] ?? false);
                                          });
                                        },
                                      ),
                                    ),
                                    if (_currentImageIndex == index)
                                      Positioned(
                                        bottom: 16,
                                        left: 16,
                                        child: Text(
                                          item['title'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
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
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Message Title',
                            hintText: 'Enter a title for your message',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            labelText: 'Your Message',
                            hintText: 'Type your message here...',
                            prefixIcon: Icon(Icons.message),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a message';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Send Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: _isLoading
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
