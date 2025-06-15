part of 'profile_bloc.dart';

@immutable
sealed class ProfileEvent {}

final class ProfileLoadEvent extends ProfileEvent {
  final bool showLoading;
  ProfileLoadEvent({this.showLoading = false});
}

final class ProfileUpdateEvent extends ProfileEvent {
  final UpdateMetadataModel userUpdatedModel;

  ProfileUpdateEvent({required this.userUpdatedModel});
}
