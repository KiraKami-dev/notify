import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionMainStatus {
  final bool       connectedStatus;
  final String     mainTokenId;
  final Timestamp? mainLastTimestamp;   // ← Firestore Timestamp (nullable)
  final bool       mainOnlineStatus;

  ConnectionMainStatus({
    required this.connectedStatus,
    required this.mainLastTimestamp,
    required this.mainOnlineStatus,
    required this.mainTokenId,
  });

  factory ConnectionMainStatus.fromJson(Map<String, dynamic> json) {
    return ConnectionMainStatus(
      connectedStatus   : json['connected_status']   ?? false,
      mainLastTimestamp : json['main_last_timestamp'] as Timestamp?,
      mainOnlineStatus  : json['main_online_status'] ?? false,
      mainTokenId       : json['main_token_id']      ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connected_status'     : connectedStatus,
      'main_last_timestamp'  : mainLastTimestamp,
      'main_online_status'   : mainOnlineStatus,
      'main_token_id'        : mainTokenId,
    };
  }
}
