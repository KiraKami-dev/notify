import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notify/data/firebase/firebase_profile.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:notify/domain/user_profile_model.dart';

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.read(getGeneratedCodeProvider) ?? '';
  if (userId.isEmpty) return null;
  return FirebaseProfile.getUserProfile(userId);
}); 