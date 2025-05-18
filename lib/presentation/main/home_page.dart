import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
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
  bool _isLoading = false;
  String? _partnerName;
  String? _partnerToken;
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _showFavoritesOnly = false;

  // Sample data - Replace with your actual data
  final List<Map<String, dynamic>> _notifications = [
    {
      'image': 'https://picsum.photos/id/237/200/300',
      'title': 'Good Morning!',
      'message': 'Have a great day ahead!',
      'time': '8:00 AM',
      'isFavorite': false,
    },
    {
      'image': 'https://picsum.photos/id/238/200/300',
      'title': 'Meeting Reminder',
      'message': 'Team meeting at 2 PM',
      'time': '1:30 PM',
      'isFavorite': true,
    },
    {
      'image': 'https://picsum.photos/id/239/200/300',
      'title': 'Lunch Break',
      'message': 'Time for a healthy lunch!',
      'time': '12:00 PM',
      'isFavorite': false,
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
  }

  Future<void> _loadPartnerInfo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _partnerName = null;
      _partnerToken = null;
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _titleController.dispose();
    _messageController.dispose();
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                // TODO: Implement logout
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildConnectionStatus(theme),
              const SizedBox(height: 24),

              // Notification Preview
              Container(
                margin: const EdgeInsets.only(bottom: 20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Recent Notifications',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          _showFavoritesOnly
                              ? _notifications
                                  .where((n) => n['isFavorite'])
                                  .length
                              : _notifications.length,
                      itemBuilder: (context, index) {
                        final notifications =
                            _showFavoritesOnly
                                ? _notifications
                                    .where((n) => n['isFavorite'])
                                    .toList()
                                : _notifications;
                        final notification = notifications[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              notification['image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(notification['title']),
                          subtitle: Text(notification['message']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(notification['time']),
                              IconButton(
                                icon: Icon(
                                  notification['isFavorite']
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      notification['isFavorite']
                                          ? Colors.red
                                          : null,
                                ),
                                onPressed: () => _toggleFavorite(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Image Carousel
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    Carousel(
                      controller: _carouselCtrl,
                      height: 200,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                          _titleController.text =
                              _carouselItems[index]['title'];
                          _messageController.text =
                              _carouselItems[index]['message'];
                        });
                      },
                      children:
                          _carouselItems.map((item) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    item['image'],
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    // gradient overlay
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
                                    // fav button
                                    bottom: 16,
                                    right: 16,
                                    child: IconButton(
                                      icon: Icon(
                                        _isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.white,
                                      ),
                                      onPressed:
                                          () => setState(() {
                                            _isFavorite = !_isFavorite;
                                          }),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),

              if (_partnerToken == null)
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Token',
                    hintText: 'Enter your partner\'s token',
                    prefixIcon: Icon(Icons.key),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a token or connect with someone';
                    }
                    return null;
                  },
                ),
              if (_partnerToken == null) const SizedBox(height: 16),

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
              const SizedBox(height: 16),

              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Your Message',
                  hintText: 'Type your message here...',
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendMessage,
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
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(ThemeData theme) {
    if (_partnerName != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              radius: 24,
              child: Text(
                _partnerName![0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connected with $_partnerName',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Send them a message!',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(
                        0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Not connected yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the connect button in the top right to find someone',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => UserConnectionModal(),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Connect Now'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      );
    }
  }
}
