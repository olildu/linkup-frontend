import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:linkup/data/web_socket_services/chat_socket_services/chat_socket_service.dart';
import 'package:meta/meta.dart';

part 'chat_sockets_event.dart';
part 'chat_sockets_state.dart';

class ChatSocketsBloc extends Bloc<ChatSocketsEvent, ChatSocketsState> {

  ChatSocketsBloc() : super(ChatSocketsInitial()) {
    on<LoadChatSocketsEvent>((event, emit) async {
      emit(ChatSocketsConnecting());
      try {
        await ChatSocketServices.connect();

        emit(ChatSocketsConnected());
      } catch (e) {
        log("ChatSockets error: $e");
        emit(ChatSocketsError());
      }
    });
  }
}
