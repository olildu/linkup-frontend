part of 'connections_bloc.dart';

@immutable
sealed class ConnectionsEvent {}

class LoadConnectionsEvent extends ConnectionsEvent {
  final bool showLoading;

  LoadConnectionsEvent({this.showLoading = false});
}

class ReloadConnectionsEvent extends ConnectionsEvent {}
