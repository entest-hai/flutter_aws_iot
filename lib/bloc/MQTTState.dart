abstract class MQTTState {}

class MQTTConnecting extends MQTTState {}

class MQTTConnected extends MQTTState {
  List<String> messages;
  MQTTConnected({required this.messages});

  MQTTConnected copyWith({
    required List<String> messages,
  }) {
    return MQTTConnected(messages: messages);
  }
}

class MQTTDisconnected extends MQTTState {}
