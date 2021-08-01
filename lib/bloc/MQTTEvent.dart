import 'package:flutter/material.dart';

abstract class MQTTEvent {}

// MQTT connect
class MQTTConnect extends MQTTEvent {
  final String clientId;
  final BuildContext context;
  MQTTConnect({
    required this.clientId,
    required this.context,
  });
}

// MQTT disconnect
class MQTTDisconnect extends MQTTEvent {
  final String clientId;
  MQTTDisconnect({required this.clientId});
}
