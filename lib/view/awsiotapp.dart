import 'package:flutter/material.dart';
import 'package:flutter_aws_iot/bloc/MQTTBloc.dart';
import 'package:flutter_aws_iot/bloc/MQTTEvent.dart';
import 'package:flutter_aws_iot/bloc/MQTTState.dart';
import 'package:flutter_aws_iot/repository/MQTTRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AWSIoTApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
            create: (context) => MQTTClientRepository(),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
                create: (context) =>
                    MQTTBloc(repository: context.read<MQTTClientRepository>()))
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
                // if (state is MQTTConnected) listMessages(state.messages)
                if (state is MQTTConnected)
                  streamMessages(
                      context.read<MQTTClientRepository>().client.updates!)
              ],
            );
          },
        ),
        floatingActionButton: disconnectButton());
  }

  Widget streamMessages(Stream stream) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshop) {
        return Text(("data"));
      },
    );
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
