import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseConnect {
  static final usersCollection = FirebaseFirestore.instance.collection('users');
  static final _rand = Random.secure();

  static Future<bool> isConnected({
    required String token,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final snap =
          await usersCollection.doc(token).get().timeout(timeout);
      if (!snap.exists) return false;
      final data = snap.data();
      if (data == null) return false;
      final s = data['connected_status'];
      return s is bool && s;
    } catch (_) {
      return false;
    }
  }

  static Future<String> createShareCode({
  required String mainTokenId,
  Duration ttl = const Duration(minutes: 10),
}) async {
  late String code;

  do {
    code = _eightDigit();
  } while (await usersCollection.doc(code).get().then((d) => d.exists));

  await usersCollection.doc(code).set({
    'connected_status':        false,
    'main_last_timestamp':     '',
    'main_online_status':      '',
    'main_token_id':           mainTokenId,
    'secondary_last_timestamp':'',
    'secondary_online_status': '',
    'secondary_token_id':      '',
    'created_at':              Timestamp.now(),
  });

  _expireIfUnconnected(code, ttl);
  return code;
}


  static String _eightDigit() =>
      (10000000 + _rand.nextInt(90000000)).toString();

  static void _expireIfUnconnected(String code, Duration ttl) {
    Future.delayed(ttl, () async {
      final snap = await usersCollection.doc(code).get();
      if (!snap.exists) return;
      final data = snap.data();
      final status = data?['connected_status'];
      if (status is bool && status) return; 
      await usersCollection.doc(code).delete();
    });
  }
}
