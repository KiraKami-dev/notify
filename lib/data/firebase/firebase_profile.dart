import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:notify/domain/user_profile_model.dart';

class FirebaseProfile {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('user_profile')
          .get();

      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  static Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.userId)
          .collection('profile')
          .doc('user_profile')
          .set(profile.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  static Future<String> uploadAvatar(String userId, File imageFile) async {
    try {
      final storageRef = _storage
          .ref()
          .child('avatars')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading avatar: $e');
      rethrow;
    }
  }
} 