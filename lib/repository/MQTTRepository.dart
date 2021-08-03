import 'dart:io';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTClientRepository {
  final builder = MqttClientPayloadBuilder();

  final MqttServerClient client = MqttServerClient(
      'a209xbcpyxq5au-ats.iot.ap-southeast-1.amazonaws.com', '');

  List<String> messages = [];

  Future<bool> mqttConnect(String uniqueId) async {
    // topic
    const topic = 'slider';
    // set certs
    ByteData rootCA = await rootBundle.load('assets/certs/root.pem');
    ByteData deviceCert =
        await rootBundle.load('assets/certs/90dd0acc83-certificate.pem.crt');
    ByteData privateKey =
        await rootBundle.load('assets/certs/90dd0acc83-private.pem.key');
    SecurityContext context = SecurityContext.defaultContext;
    context.setClientAuthoritiesBytes(rootCA.buffer.asUint8List());
    context.useCertificateChainBytes(deviceCert.buffer.asUint8List());
    context.usePrivateKeyBytes(privateKey.buffer.asUint8List());
    client.securityContext = context;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.port = 8883;
    client.secure = true;
    // set callbacks
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.pongCallback = pong;
    // connect message
    final MqttConnectMessage connMess =
        MqttConnectMessage().withClientIdentifier(uniqueId).startClean();
    client.connectionMessage = connMess;
    // coonect
    await client.connect();
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print("Connected to AWS Successfully!");
    } else {
      return false;
    }
    // subscribe to a topic
    client.subscribe(topic, MqttQos.atMostOnce);
    // stream data
    getDataStream();

    return true;
  }

  void onConnected() {
    print("Client connection was successful");
  }

  void onDisconnected() {
    print("Client Disconnected");
  }

  void pong() {
    print('Ping response client callback invoked');
  }

  void disconnect() {
    print("disconnectting client ...");
    this.messages.clear();
    client.disconnect();
  }

  void getDataStream() {
    this.client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      messages.add(pt);
    });
  }

  void publishMessage(String message) {
    builder.clear();
    builder.addString(message);
    this.client.publishMessage("slider", MqttQos.atLeastOnce, builder.payload!);
  }
}
