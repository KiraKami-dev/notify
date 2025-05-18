class ConnectionMainStatus {
  final bool connectedStatus;
  final String mainTokenId;
  final String mainLastTimestamp;
  final String mainOnlineStatus;

  ConnectionMainStatus({
    required this.connectedStatus,
    required this.mainLastTimestamp,
    required this.mainOnlineStatus,
    required this.mainTokenId,
  });

  factory ConnectionMainStatus.fromJson(Map<String, dynamic> json) {
    return ConnectionMainStatus(
      connectedStatus: json['connected_status'] ?? false,
      mainLastTimestamp: json['main_last_timestamp'] ?? '',
      mainOnlineStatus: json['main_online_status'] ?? '',
      mainTokenId: json['main_token_id'] ?? '',
    );
  }

  // Method to convert the object to a map
  Map<String, dynamic> toJson() {
    return {
      'connected_status': connectedStatus,
      'main_last_timestamp': mainLastTimestamp,
      'main_online_status': mainOnlineStatus,
      'main_token_id': mainTokenId,
    };
  }
}