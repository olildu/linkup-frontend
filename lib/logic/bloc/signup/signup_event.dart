part of 'signup_bloc.dart';

@immutable
sealed class SignupEvent {}

final class SignupInit extends SignupEvent {
  final SignUpPageFlow signUpPageFlow;
  final int currentIndex;

  SignupInit({required this.signUpPageFlow, required this.currentIndex});
}

final class SignupNext extends SignupEvent {
  final bool isAtEnd;

  SignupNext({required this.isAtEnd});
}
