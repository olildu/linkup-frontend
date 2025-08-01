import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:linkup/logic/bloc/connections/connections_bloc.dart';
import 'package:linkup/logic/bloc/matches/matches_bloc.dart';
import 'package:linkup/logic/bloc/profile/own/profile_bloc.dart';
import 'package:linkup/logic/bloc/web_socket/chat_sockets/chat_sockets_bloc.dart';
import 'package:linkup/logic/bloc/web_socket/connection_sockets/connections_socket_bloc.dart';
import 'package:linkup/logic/bloc/web_socket/web_socket_bloc.dart';
import 'package:meta/meta.dart';

part 'post_login_event.dart';
part 'post_login_state.dart';

class PostLoginBloc extends Bloc<PostLoginEvent, PostLoginState> {
  final MatchesBloc matchesBloc;
  final WebSocketBloc webSocketBloc;
  final ConnectionsSocketBloc connectionsSocketBloc;
  final ChatSocketsBloc chatSocketsBloc;
  final ProfileBloc profileBloc;
  final ConnectionsBloc connectionsBloc;

  PostLoginBloc({
    required this.matchesBloc,
    required this.webSocketBloc,
    required this.chatSocketsBloc,
    required this.connectionsSocketBloc,
    required this.profileBloc,
    required this.connectionsBloc,
  }) : super(PostLoginInitial()) {
    on<StartPostLoginEvent>((event, emit) async {
      emit(PostLoginLoading());

      try {
        profileBloc.add(ProfileLoadEvent());
        await profileBloc.stream.firstWhere((state) => state is ProfileLoaded || state is ProfileError);

        // We are checking if the user has completed full sign-up
        // This will return true if the user has not completed sign-up as there is no university_id = -1
        final bool goToSignUpPage = (profileBloc.state as ProfileLoaded).user.universityId == -1;
        if (goToSignUpPage) {
          log("User has not completed sign-up. Redirecting to sign-up page.");
          emit(PostLoginLoaded(goToSignUpPage: goToSignUpPage));
        } else {
          matchesBloc.add(LoadMatchesEvent());
          webSocketBloc.add(LoadWebSockEvent());
          chatSocketsBloc.add(LoadChatSocketsEvent());
          connectionsBloc.add(LoadConnectionsEvent(showLoading: true));
          connectionsSocketBloc.add(LoadConnectionSocketsEvent());

          await Future.wait([
            matchesBloc.stream.firstWhere((state) => state is MatchesLoaded || state is MatchesError || state is MatchesEmpty),
            webSocketBloc.stream.firstWhere((state) => state is WebSocketConnected || state is WebSocketError),
            chatSocketsBloc.stream.firstWhere((state) => state is ChatSocketsConnected || state is ChatSocketsError),
            connectionsSocketBloc.stream.firstWhere((state) => state is ConnectionsSocketsConnected || state is ConnectionsSocketsError),
          ]);
          log("All post-login streams loaded successfully.");
          emit(PostLoginLoaded(goToSignUpPage: goToSignUpPage));
        }
      } catch (e) {
        log("Error during post-login initialization: $e");
        emit(PostLoginError());
      }
    });
  }
}
