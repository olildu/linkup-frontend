part of 'signup_bloc.dart';

@immutable
sealed class SignupState {}

final class SignupInitial extends SignupState {
  final String buttonText;
  final int currentIndex;
  final int progessBarIndex;

  SignupInitial({this.buttonText = "Next", required this.currentIndex, required this.progessBarIndex});
}

final class SingupPhotoUploading extends SignupState {}

final class SingupPhotoUploaded extends SignupState {}

final class SingupPhotoUploadError extends SignupState {
  final String message;
  SingupPhotoUploadError({required this.message});
}
