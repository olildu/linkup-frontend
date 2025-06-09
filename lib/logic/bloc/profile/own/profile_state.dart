part of 'profile_bloc.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileError extends ProfileState {}

final class ProfileLoaded extends ProfileState {
  final UserModel user;

  ProfileLoaded({required this.user});
}