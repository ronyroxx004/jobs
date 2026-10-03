class AgoraConfig {
  /// Agora App ID for 1:1 Video Calling.
  /// Users can replace this with their Agora Console App ID.
  /// By default, Agora apps in testing mode work with App ID and empty token.
  static String appId = 'bcae46eecfbc4a3194dc6b51b3a62886';

  /// Token for authentication (leave empty for testing App ID without certificate)
  static String token = '';

  /// Generates a standardized, safe Agora channel name from booking ID
  static String getChannelName(String bookingId) {
    final clean = bookingId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return clean.isNotEmpty ? 'call_$clean' : 'call_mentorship_room';
  }
}
