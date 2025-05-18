import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionSecondaryStatus {
  final bool       connectedStatus;
  final Timestamp? secondaryLastTimestamp;   // ← Firestore Timestamp
  final bool       secondaryOnlineStatus;
  final String     secondaryTokenId;

  ConnectionSecondaryStatus({
    required this.connectedStatus,
    required this.secondaryLastTimestamp,
    required this.secondaryOnlineStatus,
    required this.secondaryTokenId,
  });

  factory ConnectionSecondaryStatus.fromJson(Map<String, dynamic> json) {
    return ConnectionSecondaryStatus(
      connectedStatus        : json['connected_status']        ?? false,
      secondaryLastTimestamp : json['secondary_last_timestamp'] as Timestamp?,
      secondaryOnlineStatus  : json['secondary_online_status'] ?? false,
      secondaryTokenId       : json['secondary_token_id']      ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connected_status'        : connectedStatus,
      'secondary_last_timestamp': secondaryLastTimestamp,
      'secondary_online_status' : secondaryOnlineStatus,
      'secondary_token_id'      : secondaryTokenId,
    };
  }
}
