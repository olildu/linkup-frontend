part of 'connections_bloc.dart';

@immutable
sealed class ConnectionsEvent {}

class LoadConnectionsEvent extends ConnectionsEvent {}

class ReloadConnectionsEvent extends ConnectionsEvent {}