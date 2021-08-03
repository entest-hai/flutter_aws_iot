import 'package:flutter/material.dart';
import 'package:flutter_aws_iot/bloc/MQTTBloc.dart';
import 'package:flutter_aws_iot/bloc/MQTTEvent.dart';
import 'package:flutter_aws_iot/bloc/MQTTState.dart';
import 'package:flutter_aws_iot/repository/EcgRepository.dart';
import 'package:flutter_aws_iot/repository/MQTTRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mqtt_client/mqtt_client.dart';

class AWSIoTApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
            create: (context) => MQTTClientRepository(),
          ),
          RepositoryProvider(
            create: (context) => HeartRateRepository(),
          )
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
                create: (context) => MQTTBloc(
                    repository: context.read<MQTTClientRepository>(),
                    heartRateRepository: context.read<HeartRateRepository>()
                      ..readHeartRateFile("assets/mheartrate.txt")))
          ],
          child: MQTTClient(),
        ),
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
  double _currentSliderValue = 20;
  TextEditingController idTextController = TextEditingController();
  TextEditingController messageTextController = TextEditingController();

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
                // if (state is MQTTConnected) publishButton(),
                // publishSlider(),
                if (state is MQTTConnected) publishEcg(),
                if (state is MQTTConnecting) CircularProgressIndicator(),
                if (state is MQTTConnected)
                  listMessages(context
                      .read<MQTTClientRepository>()
                      .messages
                      .reversed
                      .toList())
              ],
            );
          },
        ),
        floatingActionButton: disconnectButton());
  }

  Widget streamMessages(Stream stream) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text("Connected");
        } else {
          final mqttReceivedMessages =
              snapshot.data as List<MqttReceivedMessage<MqttMessage?>>?;
          final recMess =
              mqttReceivedMessages![0].payload as MqttPublishMessage;
          final pt =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

          return Text("${mqttReceivedMessages.length}");
        }
      },
    );
  }

  Widget listMessages(List<String> messages) {
    return Expanded(
      child: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(messages[index]));
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

  Widget publishEcg() {
    return BlocBuilder<MQTTBloc, MQTTState>(builder: (context, state) {
      return Padding(
        padding: const EdgeInsets.only(right: 23),
        child: Row(
          children: [
            Spacer(),
            TextButton(
                onPressed: () async {
                  for (var i = 0; i < 30; i++) {
                    final message = context
                        .read<HeartRateRepository>()
                        .ecg
                        .sublist(i * 10, i * 10 + 10)
                        .toString();
                    context
                        .read<MQTTClientRepository>()
                        .publishMessage(message);
                    await Future.delayed(Duration(seconds: 1));
                  }
                },
                child: Text("Publish"))
          ],
        ),
      );
    });
  }

  Widget publishSlider() {
    return BlocBuilder<MQTTBloc, MQTTState>(builder: (context, state) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Slider(
            value: _currentSliderValue,
            min: 0,
            max: 100,
            label: _currentSliderValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _currentSliderValue = value;
                context.read<MQTTClientRepository>().publishMessage(
                    "slider value ${_currentSliderValue.round().toString()}");
              });
              print(value);
            }),
      );
    });
  }

  Widget publishButton() {
    return BlocBuilder<MQTTBloc, MQTTState>(builder: (context, state) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 8),
        child: TextFormField(
          controller: messageTextController,
          decoration: InputDecoration(
              border: UnderlineInputBorder(),
              labelText: "Publish message",
              labelStyle: TextStyle(fontSize: 10),
              suffixIcon: TextButton(
                child: Text("Publish"),
                onPressed: () {
                  context
                      .read<MQTTClientRepository>()
                      .publishMessage(messageTextController.text.trim());
                },
              )),
        ),
      );
    });
  }

  Widget connectButton() {
    return BlocBuilder<MQTTBloc, MQTTState>(builder: (context, state) {
      return Container(
        // color: Colors.black26,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 8),
              child: TextFormField(
                  enabled: state is MQTTDisconnected,
                  controller: idTextController,
                  decoration: InputDecoration(
                      border: UnderlineInputBorder(),
                      labelText: 'MQTT Client Id',
                      labelStyle: TextStyle(fontSize: 10),
                      suffixIcon: TextButton(
                        onPressed: () {
                          context.read<MQTTBloc>().add(MQTTConnect(
                              clientId: "testDevice", context: context));
                        },
                        child: Text("Connect"),
                      ))),
            )
          ],
        ),
      );
    });
  }
}
