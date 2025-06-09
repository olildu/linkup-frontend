import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:linkup/data/http_services/match_http_services/match_http_services.dart';
import 'package:linkup/data/models/chats_connection_model.dart';
import 'package:linkup/data/models/matches_connection_model.dart';
import 'package:linkup/data/web_socket_services/chat_socket_services/chat_socket_service.dart';
import 'package:meta/meta.dart';

part 'connections_event.dart';
part 'connections_state.dart';

class ConnectionsBloc extends Bloc<ConnectionsEvent, ConnectionsState> {
  StreamSubscription<String>? _socketSubscription;

  ConnectionsBloc() : super(ConnectionsInitial()) {
    on<LoadConnectionsEvent>((event, emit) async {
      emit(ConnectionsLoading());
      try {
        Map<String, dynamic> connections = await MatchHttpServices().getConnections(); 

        _socketSubscription?.cancel();
        _socketSubscription = ChatSocketServices.messageStream.listen((raw) {
          final data = jsonDecode(raw);

          if (data["type"] == "chats") {
            if (data["chats_type"] == "message") {
              add(ReloadConnectionsEvent());
            }
          }
        });

        emit(ConnectionsLoaded(
          matches: connections['matches'] as List<MatchesConnectionModel>,
          chats: connections['chats'] as List<ChatsConnectionModel>,
        ));
      } on Exception catch (e, stackTrace) {
        log('Error loading connections: $e', stackTrace: stackTrace); 
        emit(ConnectionsError());
      }
    });

    on<ReloadConnectionsEvent>((event, emit) async {
      Map<String, dynamic> connections = await MatchHttpServices().getConnections(); 
      emit(ConnectionsLoaded(
        matches: connections['matches'] as List<MatchesConnectionModel>,
        chats: connections['chats'] as List<ChatsConnectionModel>,
      ));
    });
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}
