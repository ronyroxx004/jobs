class AgoraConfig {
  /// Agora App ID for 1:1 Video Calling (from user's Agora Console)
  static String appId = '9fa41116b3de464eb0cd4a55caa80138';

  /// Temporary RTC Token for testing
  static String token =
      '007eJxTYPjTuWThhR0fxEtKv5Zfk/sl9HDJNpPHHjKr/m+ewbNS+Wu/AoNlWqKJoaGhWZJxSqqJmUlqkkFyikmiqWlyYqKFgaGxhQLLwayGQEYGlXsFjIwMEAjiMzNk5ScxMAAAKF4hfA==';

  /// Testing channel name matching the temporary token
  static String testingChannel = 'job';

  /// Generates a standardized, safe Agora channel name
  static String getChannelName(String bookingId) {
    if (testingChannel.isNotEmpty) {
      return testingChannel;
    }
    final clean = bookingId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return clean.isNotEmpty ? 'call_$clean' : 'call_mentorship_room';
  }
}
