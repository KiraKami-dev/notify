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
      final snap = await usersCollection.doc(token).get().timeout(timeout);
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
    // 1️⃣ Re‑use existing doc for this token, if any
    final existing =
        await usersCollection
            .where('main_token_id', isEqualTo: mainTokenId)
            .limit(1)
            .get();

    if (existing.docs.isNotEmpty) {
      final code = existing.docs.first.id;
      _expireIfUnconnected(code, ttl); // refresh expiry
      return code;
    }

    // 2️⃣ Otherwise generate a fresh, unused 6‑digit code
    late String code;
    do {
      code = _sixDigit();
    } while (await usersCollection.doc(code).get().then((d) => d.exists));

    await usersCollection.doc(code).set({
      'connected_status': false,
      'main_last_timestamp': Timestamp.now(),
      'main_online_status': true,
      'main_token_id': mainTokenId,
      'secondary_last_timestamp': Timestamp.now(),
      'secondary_online_status': false,
      'secondary_token_id': '',
      'created_at': Timestamp.now(),
    });

    _expireIfUnconnected(code, ttl);
    return code;
  }

  static Stream<bool> listenToConnectionStatus(String code) {
    return usersCollection.doc(code).snapshots().map((snapshot) {
      if (!snapshot.exists) return false;
      final data = snapshot.data();
      if (data == null) return false;
      return data['connected_status'] as bool? ?? false;
    });
  }

  static Future<bool> isOwnCode(String code, String mainTokenId) async {
    final doc = await usersCollection.doc(code).get();
    if (!doc.exists) return false;
    final data = doc.data();
    if (data == null) return false;
    return data['main_token_id'] == mainTokenId;
  }

  /* ---------- private helpers ---------- */

  static String _sixDigit() =>
      (100000 + _rand.nextInt(900000))
          .toString(); // 100 000 – 999 999  (6 digits)

  static void _expireIfUnconnected(String code, Duration ttl) {
    Future.delayed(ttl, () async {
      final snap = await usersCollection.doc(code).get();
      if (!snap.exists) return;
      final status = snap.data()?['connected_status'];
      if (status is bool && status) return; // connection succeeded
      await usersCollection.doc(code).delete();
    });
  }

  static Future<bool> updateSecondaryPresenceIfOffline({
    required String partnerCode,
    required String tokenId,
  }) async {
    final userDoc = usersCollection.doc(partnerCode);

    try {
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        return false; // doc doesn't exist, failure
      }

      final data = snapshot.data();
      final isOnline = data?['secondary_online_status'] == true;

      if (!isOnline) {
        await userDoc.update({
          'secondary_online_status': true,
          'secondary_last_timestamp': Timestamp.now(),
          'secondary_token_id': tokenId,
          'connected_status': true,
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> fetchPartnerToken({
    required String code,
    required String typeUser,
  }) async {
    final doc = await usersCollection.doc(code).get();
    
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    final partnerField =
        typeUser == 'main' ? 'secondary_token_id' : 'main_token_id';

    final token = data[partnerField];
    return (token is String && token.isNotEmpty) ? token : null;
  }

   static Future<bool> codeExists(String code) async {
    try {
      final doc = await usersCollection.doc(code).get();
      return doc.exists;
    } catch (_) {
      
      return false;
    }
  }
}
