import 'package:flutter/material.dart';

abstract class MQTTEvent {}

class MQTTConnect extends MQTTEvent {
  final String clientId;
  final BuildContext context;
  MQTTConnect({
    required this.clientId,
    required this.context,
  });
}

class MQTTPublish extends MQTTEvent {
  final String message;
  MQTTPublish({required this.message});
}

class MQTTDisconnect extends MQTTEvent {
  final String clientId;
  MQTTDisconnect({required this.clientId});
}
