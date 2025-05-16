class ConnectionStatus {
  final bool connectedStatus;
  final String mainTokenId;
  final String mainLastTimestamp;
  final String mainOnlineStatus;
  final String secondaryLastTimestamp;
  final String secondaryOnlineStatus;
  final String secondaryTokenId;

  ConnectionStatus({
    required this.connectedStatus,
    required this.mainLastTimestamp,
    required this.mainOnlineStatus,
    required this.mainTokenId,
    required this.secondaryLastTimestamp,
    required this.secondaryOnlineStatus,
    required this.secondaryTokenId,
  });

  factory ConnectionStatus.fromJson(Map<String, dynamic> json) {
    return ConnectionStatus(
      connectedStatus: json['connected_status'] ?? false,
      mainLastTimestamp: json['main_last_timestamp'] ?? '',
      mainOnlineStatus: json['main_online_status'] ?? '',
      mainTokenId: json['main_token_id'] ?? '',
      secondaryLastTimestamp: json['secondary_last_timestamp'] ?? '',
      secondaryOnlineStatus: json['secondary_online_status'] ?? '',
      secondaryTokenId: json['secondary_token_id'] ?? '',
    );
  }

  // Method to convert the object to a map
  Map<String, dynamic> toJson() {
    return {
      'connected_status': connectedStatus,
      'main_last_timestamp': mainLastTimestamp,
      'main_online_status': mainOnlineStatus,
      'main_token_id': mainTokenId,
      'secondary_last_timestamp': secondaryLastTimestamp,
      'secondary_online_status': secondaryOnlineStatus,
      'secondary_token_id': secondaryTokenId,
    };
  }
}
