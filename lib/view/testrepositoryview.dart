import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RepositoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
            create: (context) => MessageRepository(),
          )
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  AddBloc(repository: context.read<MessageRepository>()),
            )
          ],
          child: BlocBuilder<AddBloc, AddState>(
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(
                  title: Text("Repository"),
                ),
                body: ListView.builder(
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final List<String> messages = state.messages;
                    return ListTile(
                      title: Text("${messages[index]} $index"),
                    );
                  },
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    BlocProvider.of<AddBloc>(context).add(AddEvent());
                  },
                  child: Icon(Icons.add),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class MessageRepository {
  List<String> messages = [];
}

class AddEvent {}

class AddState {
  List<String> messages;
  AddState({required this.messages});
}

class AddBloc extends Bloc<AddEvent, AddState> {
  final MessageRepository repository;
  AddBloc({required this.repository}) : super(AddState(messages: []));

  @override
  Stream<AddState> mapEventToState(AddEvent event) async* {
    if (event is AddEvent) {
      this.repository.messages.add("new message");
      yield AddState(messages: this.repository.messages);
    }
  }
}
