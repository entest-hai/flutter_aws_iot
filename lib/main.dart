import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(AWSIoTApp());
}

class AWSIoTApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [BlocProvider(create: (context) => MQTTBloc())],
        child: MQTTClient(),
      ),
    );
  }
}

class MQTTClient extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MQTTClientState();
  }
}

class _MQTTClientState extends State<MQTTClient> {
  TextEditingController idTextController = TextEditingController();

  @override
  void dispose() {
    idTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("MQTT Client"),
        ),
        body: BlocBuilder<MQTTBloc, MQTTState>(
          builder: (context, state) {
            return Column(
              children: [
                connectButton(),
                if (state is MQTTConnecting) CircularProgressIndicator(),
                if (state is MQTTConnected) listMessages(state.messages)
              ],
            );
          },
        ),
        floatingActionButton: disconnectButton());
  }

  Widget listMessages(List<String> messages) {
    return Expanded(
      child: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return Text(messages[index]);
        },
      ),
    );
  }

  Widget disconnectButton() {
    return TextButton(
      child: Text(
        "Disconnect",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        context.read<MQTTBloc>().add(MQTTDisconnect(clientId: "testDevice"));
      },
      style: TextButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: EdgeInsets.all(10.0),
          minimumSize: Size(150, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  Widget connectButton() {
    return BlocBuilder<MQTTBloc, MQTTState>(builder: (context, state) {
      return Container(
        // color: Colors.black26,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextFormField(
                  enabled: state is MQTTDisconnected,
                  controller: idTextController,
                  decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'MQTT Client Id',
                      labelStyle: TextStyle(fontSize: 10),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.subdirectory_arrow_left),
                        onPressed: () {
                          context.read<MQTTBloc>().add(MQTTConnect(
                              clientId: "testDevice", context: context));
                        },
                      ))),
            )
          ],
        ),
      );
    });
  }
}

// MQTT Event
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

// MQTT State
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

// MQTT Bloc
class MQTTBloc extends Bloc<MQTTEvent, MQTTState> {
  List<String> currentMessages = [""];
  final repostiory = MQTTClientRepository();
  MQTTBloc() : super(MQTTDisconnected());
  @override
  Stream<MQTTState> mapEventToState(MQTTEvent event) async* {
    // Try to connect to AWS IoT core
    if (event is MQTTConnect) {
      yield MQTTConnecting();
      try {
        print("trying to connect to AWS IoT core \($event.clientId)");
        await repostiory.mqttConnect("testDevice");
        emit(MQTTConnected(messages: currentMessages));
        repostiory.client.updates!
            .listen((List<MqttReceivedMessage<MqttMessage>> c) {
          final recMess = c[0].payload as MqttPublishMessage;
          final pt =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          currentMessages.add(pt);
          emit(MQTTConnected(messages: currentMessages));
        });
      } catch (e) {
        print("not able to connect");
      }
    }
    // Try to disconnect
    if (event is MQTTDisconnect) {
      print("disconnecting to AWS IoT Core");
      repostiory.disconnect();
      yield (MQTTDisconnected());
    }
  }
}

class MQTTClientRepository {
  final MqttServerClient client = MqttServerClient(
      'a209xbcpyxq5au-ats.iot.ap-southeast-1.amazonaws.com', '');

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
    client.disconnect();
  }
}
