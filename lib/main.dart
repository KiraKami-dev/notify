import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  _getFCMToken();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  

  // Send notification by calling the Firebase Cloud Function
  Future<void> _sendNotification() async {
    String tokenId = _tokenController.text.trim();
    String body = _bodyController.text.trim();
    String title = _titleController.text.trim();

    if (tokenId.isEmpty || body.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide all fields: Token, Title, and Body!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // The Cloud Function URL - replace with your function's URL
    final url = Uri.parse(
      'https://sendnotification-pjkmgzabia-uc.a.run.app/sendNotification',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': tokenId, 'title': title, 'body': body}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification Sent Successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw 'Failed to send notification';
      }
    } catch (error) {
      print('Error sending notification: ${error.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FCM Token Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // TextField for tokenId
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Enter Token ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // TextField for title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Enter Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // TextField for body
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: 'Enter Message Body',
                border: OutlineInputBorder(),
              ),
              maxLines: 4, // Allow multiple lines for the message
            ),
            SizedBox(height: 16),
            // Send button to send notification
            ElevatedButton(
              onPressed: _sendNotification,
              child: Text('Send Notification'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _getFCMToken() async {
    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      print("FCM Token: $token");

      // Store the token in Firestore
      _storeTokenInFirestore(token);
    }
  }

  // Store the token in Firestore with token as document ID
  Future<void> _storeTokenInFirestore(String token) async {
    try {
      final tokenCollectionRef = FirebaseFirestore.instance.collection(
        'tokens',
      );

      await tokenCollectionRef.doc(token).set({
        'token_id': token,
        'timestamp': Timestamp.now(),
      });

      print('Token stored successfully in Firestore');
    } catch (e) {
      print('Error storing token in Firestore: $e');
    }
  }