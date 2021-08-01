import 'package:flutter_aws_iot/bloc/MQTTEvent.dart';
import 'package:flutter_aws_iot/repository/MQTTRepository.dart';
import 'package:flutter_aws_iot/bloc/MQTTState.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MQTTBloc extends Bloc<MQTTEvent, MQTTState> {
  List<String> currentMessages = [""];

  final MQTTClientRepository repository;
  MQTTBloc({required this.repository}) : super(MQTTDisconnected());

  @override
  Stream<MQTTState> mapEventToState(MQTTEvent event) async* {
    // Try to connect to AWS IoT core
    if (event is MQTTConnect) {
      yield MQTTConnecting();
      try {
        print("trying to connect to AWS IoT core \($event.clientId)");
        await this.repository.mqttConnect("testDevice");
        emit(MQTTConnected(messages: currentMessages));
        this
            .repository
            .client
            .updates!
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
      this.repository.disconnect();
      yield (MQTTDisconnected());
    }
  }
}
