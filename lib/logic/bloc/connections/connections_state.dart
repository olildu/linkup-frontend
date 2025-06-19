part of 'connections_bloc.dart';

@immutable
sealed class ConnectionsState {}

final class ConnectionsInitial extends ConnectionsState {}

final class ConnectionsLoading extends ConnectionsState {}

final class ConnectionsError extends ConnectionsState {}

final class ConnectionsLoaded extends ConnectionsState {
  final List<ChatsConnectionModel> chats;
  final List<MatchesConnectionModel> matches;

  ConnectionsLoaded({required this.chats, required this.matches});

  ConnectionsLoaded copyWith({List<ChatsConnectionModel>? chats, List<MatchesConnectionModel>? matches}) {
    return ConnectionsLoaded(chats: chats ?? this.chats, matches: matches ?? this.matches);
  }
}
