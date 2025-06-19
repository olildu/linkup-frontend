part of 'connections_bloc.dart';

@immutable
sealed class ConnectionsEvent {}

class LoadConnectionsEvent extends ConnectionsEvent {
  final bool showLoading;

  LoadConnectionsEvent({this.showLoading = false});
}

class ReloadChatConnectionsEvent extends ConnectionsEvent {
  final LiveChatDataModel? liveChatData;

  ReloadChatConnectionsEvent({this.liveChatData});
}

class MarkMessagesSeenEvent extends ConnectionsEvent {
  final int chatRoomId;
  final int decrementCounterTo;

  MarkMessagesSeenEvent({required this.chatRoomId, this.decrementCounterTo = 0});
}
