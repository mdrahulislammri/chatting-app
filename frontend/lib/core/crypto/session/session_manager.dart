enum SessionState { created, active, stale, suspended, revoked }

class DeviceSession {
  final String deviceId;
  final String publicIdentityKey;
  SessionState state;
  final DateTime createdAt;

  DeviceSession({
    required this.deviceId,
    required this.publicIdentityKey,
    this.state = SessionState.active,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class SessionManager {
  final Map<String, DeviceSession> _sessions = {};

  DeviceSession getOrCreateSession({
    required String deviceId,
    required String publicIdentityKey,
  }) {
    if (_sessions.containsKey(deviceId)) {
      final existing = _sessions[deviceId]!;
      // Check for identity key change!
      if (existing.publicIdentityKey != publicIdentityKey) {
        existing.state = SessionState.suspended;
        throw StateError("Safety Identity Key changed for device $deviceId. Session suspended pending verification.");
      }
      if (existing.state == SessionState.revoked) {
        throw StateError("Device $deviceId has been revoked. Messaging rejected.");
      }
      return existing;
    }

    final newSession = DeviceSession(
      deviceId: deviceId,
      publicIdentityKey: publicIdentityKey,
      state: SessionState.active,
    );
    _sessions[deviceId] = newSession;
    return newSession;
  }

  void revokeSession(String deviceId) {
    if (_sessions.containsKey(deviceId)) {
      _sessions[deviceId]!.state = SessionState.revoked;
    }
  }

  void approveIdentityChange(String deviceId, String newIdentityKey) {
    _sessions[deviceId] = DeviceSession(
      deviceId: deviceId,
      publicIdentityKey: newIdentityKey,
      state: SessionState.active,
    );
  }
}
