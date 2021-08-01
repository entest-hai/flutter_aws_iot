import 'package:flutter/material.dart';
import 'dart:async';

class StreamBuilderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // This list holds the conversation
  List<Map<String, String>> _chatMessages = [];

  // More messages added to the _chatMessages over time
  Stream<List<Map<String, String>>> _chat() async* {
    await Future<void>.delayed(Duration(seconds: 3));
    _chatMessages.add({"user_name": "Trump", "message": "Hello"});
    yield _chatMessages;

    await Future<void>.delayed(Duration(seconds: 3));
    _chatMessages.add({"user_name": "Biden", "message": "Hi baby"});
    yield _chatMessages;

    await Future<void>.delayed(Duration(seconds: 3));
    _chatMessages.add({
      "user_name": "Trump",
      "message": "Would you like to have dinner with me?"
    });
    yield _chatMessages;

    await Future<void>.delayed(Duration(seconds: 3));
    _chatMessages.add({
      "user_name": "Biden",
      "message": "Great. I am very happy to accompany you."
    });
    yield _chatMessages;

    await Future<void>.delayed(Duration(seconds: 3));
    _chatMessages
        .add({"user_name": "Trump", "message": "Nice. I love you, my honney!"});
    yield _chatMessages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kindacode.com'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: StreamBuilder(
          stream: _chat(),
          builder:
              (context, AsyncSnapshot<List<Map<String, String>>> snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final chatItem = snapshot.data![index];
                  return ListTile(
                    leading: Text(
                      chatItem["user_name"] ?? '',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    title: Text(
                      chatItem["message"] ?? '',
                      style: TextStyle(
                          fontSize: 20,
                          color: chatItem['user_name'] == 'Trump'
                              ? Colors.pink
                              : Colors.blue),
                    ),
                  );
                },
              );
            }
            return LinearProgressIndicator();
          },
        ),
      ),
    );
  }
}
