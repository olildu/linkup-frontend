part of 'otp_bloc.dart';

@immutable
sealed class OtpBlocEvent {}

final class SendOTPEvent extends OtpBlocEvent {
  final String email;
  SendOTPEvent({required this.email});
}

final class SendPasswordEvent extends OtpBlocEvent {
  final String password;
  SendPasswordEvent({required this.password});
}

final class VerifyOTPEvent extends OtpBlocEvent {
  final int otp;
  final String email;

  VerifyOTPEvent({required this.otp, required this.email});
}

final class OtpVerificationErrorEvent extends OtpBlocEvent {}

final class EmailSendErrorEvent extends OtpBlocEvent {}
