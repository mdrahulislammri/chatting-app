import 'package:flutter/material.dart';
import 'package:frontend/models/call_state.dart';
import 'package:frontend/services/webrtc_call_service.dart';

class CallScreen extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final String callerDeviceId;
  final WebRtcCallService? callService;

  const CallScreen({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.callerDeviceId,
    this.callService,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final WebRtcCallService _callService;
  CallState _state = CallState.initiating;
  bool _isMuted = false;
  bool _isVideoOff = false;
  String? _callId;

  @override
  void initState() {
    super.initState();
    _callService = widget.callService ?? WebRtcCallService();
    _initiateCall();
  }

  Future<void> _initiateCall() async {
    final result = await _callService.initiateCall(
      conversationId: widget.conversationId,
      callerDeviceId: widget.callerDeviceId,
    );

    if (result != null && result['id'] != null) {
      setState(() {
        _callId = result['id'] as String;
        _state = _callService.validateAndTransition(_state, CallState.ringing);
      });
    } else {
      setState(() {
        _state = CallState.failed;
      });
    }
  }

  void _endCall() {
    if (_callId != null) {
      _callService.sendSignal(
        conversationId: widget.conversationId,
        callId: _callId!,
        senderDeviceId: widget.callerDeviceId,
        type: 'end',
      );
    }
    setState(() {
      _state = CallState.ended;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade700,
              child: Text(
                widget.contactName.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.contactName,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _state == CallState.initiating
                  ? 'Calling...'
                  : _state == CallState.ringing
                      ? 'Ringing...'
                      : _state == CallState.connecting
                          ? 'Connecting DTLS-SRTP...'
                          : _state == CallState.connected
                              ? '00:42'
                              : 'Call Ended',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                    color: Colors.white,
                    iconSize: 32,
                    onPressed: () => setState(() => _isMuted = !_isMuted),
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: _endCall,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  IconButton(
                    icon: Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam),
                    color: Colors.white,
                    iconSize: 32,
                    onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
