import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:linkup/logic/bloc/connections/connections_bloc.dart';
import 'package:linkup/logic/bloc/matches/matches_bloc.dart';
import 'package:linkup/logic/bloc/profile/own/profile_bloc.dart';
import 'package:linkup/logic/bloc/web_socket/chat_sockets/chat_sockets_bloc.dart';
import 'package:linkup/logic/bloc/web_socket/web_socket_bloc.dart';
import 'package:meta/meta.dart';

part 'post_login_event.dart';
part 'post_login_state.dart';

class PostLoginBloc extends Bloc<PostLoginEvent, PostLoginState> {
  final MatchesBloc matchesBloc;
  final WebSocketBloc webSocketBloc;
  final ChatSocketsBloc chatSocketsBloc;
  final ProfileBloc profileBloc;
  final ConnectionsBloc connectionsBloc;

  PostLoginBloc({
    required this.matchesBloc,
    required this.webSocketBloc,
    required this.chatSocketsBloc,
    required this.profileBloc,
    required this.connectionsBloc,
  }) : super(PostLoginInitial()) {
    on<StartPostLoginEvent>((event, emit) async {
      emit(PostLoginLoading());

      try {
        matchesBloc.add(LoadMatchesEvent());
        webSocketBloc.add(LoadWebSockEvent());
        chatSocketsBloc.add(LoadChatSocketsEvent());
        profileBloc.add(ProfileLoadEvent());
        connectionsBloc.add(LoadConnectionsEvent(showLoading: true));

        await Future.wait([
          matchesBloc.stream.firstWhere((state) => state is MatchesLoaded || state is MatchesError || state is MatchesEmpty),
          webSocketBloc.stream.firstWhere((state) => state is WebSocketConnected || state is WebSocketError),
          chatSocketsBloc.stream.firstWhere((state) => state is ChatSocketsConnected || state is ChatSocketsError),
          profileBloc.stream.firstWhere((state) => state is ProfileLoaded || state is ProfileError),
        ]);

        emit(PostLoginLoaded());
      } catch (e) {
        log("Error during post-login initialization: $e");
        emit(PostLoginError());
      }
    });
  }
}
