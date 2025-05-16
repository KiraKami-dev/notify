import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notify/config/const_variables.dart';
import 'package:notify/data/local_notification/notification_service.dart';
import 'presentation/connection_dialog.dart';

// Firebase Cloud Function URL

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initializeFirebaseMessaging();
  await NotificationService.init();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    NotificationService.showForegroundNotification(message);
  });
  runApp(const NotifyApp());
}

Future<void> _initializeFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  final token = await messaging.getToken();

  // if (token != null) {
  //   print("FCM Token: $token");
  //   await _storeTokenInFirestore(token);
  // }
}

Future<void> _storeTokenInFirestore(String token) async {
  try {
    await FirebaseFirestore.instance.collection('tokens').doc(token).set({
      'token_id': token,
      'timestamp': Timestamp.now(),
    }, SetOptions(merge: true));
    print('Token stored successfully in Firestore');
  } catch (e) {
    print('Error storing token in Firestore: $e');
  }
}

class NotifyApp extends StatelessWidget {
  const NotifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purpleAccent,
          secondary: Colors.deepPurpleAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purpleAccent,
          secondary: Colors.deepPurpleAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      themeMode: ThemeMode.system,
      home: const MessageSenderPage(),
    );
  }
}

class MessageSenderPage extends StatefulWidget {
  const MessageSenderPage({super.key});

  @override
  State<MessageSenderPage> createState() => _MessageSenderPageState();
}

class _MessageSenderPageState extends State<MessageSenderPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String? _partnerName;
  String? _partnerToken;

  @override
  void initState() {
    super.initState();
    _loadPartnerInfo();
  }

  Future<void> _loadPartnerInfo() async {
    // This would normally load from your database
    // For now, we'll just simulate a delay
    await Future.delayed(const Duration(milliseconds: 500));

    // In a real app, you'd fetch this from Firestore or your backend
    setState(() {
      _partnerName = null; // Set to null if no partner connected yet
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
          'image':
              'https://firebasestorage.googleapis.com/v0/b/notifyuh.firebasestorage.app/o/assets%2Fhi_girl.jpg?alt=media&token=a1a45942-5dd7-43a8-9563-a83ede569144',
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Message sent successfully!', Colors.green);
        _titleController.clear();
        _messageController.clear();

        // In a real app, you'd also save this message to Firestore
        // to maintain message history
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
      appBar: AppBar(
        title: const Text(
          'Connect',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) => UserConnectionModal(
                      mainTokenId: "",
                      onConnect: (partnerCode) {
                        // handle connection logic
                        print('Connected with: $partnerCode');
                        Navigator.of(
                          context,
                        ).pop(); // Close the dialog after connecting
                      },
                    ),
              );
            },
            tooltip: 'Connect with someone',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildConnectionStatus(theme),
              const SizedBox(height: 24),
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
                  builder:
                      (context) => UserConnectionModal(
                        mainTokenId: "",
                        onConnect: (partnerCode) {
                          // handle connection logic
                          print('Connected with: $partnerCode');
                          Navigator.of(
                            context,
                          ).pop(); // Close the dialog after connecting
                        },
                      ),
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
