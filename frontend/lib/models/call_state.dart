enum CallState {
  initiating,
  ringing,
  connecting,
  connected,
  ended,
  failed;

  static CallState fromString(String state) {
    switch (state.toLowerCase()) {
      case 'initiating':
        return CallState.initiating;
      case 'ringing':
        return CallState.ringing;
      case 'connecting':
        return CallState.connecting;
      case 'connected':
        return CallState.connected;
      case 'ended':
        return CallState.ended;
      case 'failed':
      default:
        return CallState.failed;
    }
  }
}
