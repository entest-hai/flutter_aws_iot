import 'package:flutter_aws_iot/MQTTEvent.dart';
import 'package:flutter_aws_iot/MQTTRepository.dart';
import 'package:flutter_aws_iot/MQTTState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mqtt_client/mqtt_client.dart';

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
