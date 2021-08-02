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
                  itemCount: context.read<MessageRepository>().messages.length,
                  itemBuilder: (context, index) {
                    final List<String> messages =
                        context.read<MessageRepository>().messages;
                    return ListTile(
                      title: Text("${messages[index]} $index"),
                    );
                  },
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    context.read<AddBloc>().add(AddEvent());
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

class AddState {}

class AddBloc extends Bloc<AddEvent, AddState> {
  final MessageRepository repository;
  AddBloc({required this.repository}) : super(AddState());

  @override
  Stream<AddState> mapEventToState(AddEvent event) async* {
    if (event is AddEvent) {
      this.repository.messages.add("new message");
      yield AddState();
    }
  }
}
