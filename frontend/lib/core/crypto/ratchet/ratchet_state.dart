import 'dart:typed_data';

class RatchetState {
  Uint8List rootKey;
  Uint8List? sendingChainKey;
  Uint8List? receivingChainKey;
  int sequenceNumber;
  int previousChainLength;
  final Map<String, Uint8List> skippedMessageKeys;

  RatchetState({
    required this.rootKey,
    this.sendingChainKey,
    this.receivingChainKey,
    this.sequenceNumber = 0,
    this.previousChainLength = 0,
    Map<String, Uint8List>? skippedMessageKeys,
  }) : skippedMessageKeys = skippedMessageKeys ?? {};
}
