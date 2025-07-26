part of 'otp_bloc.dart';

@immutable
sealed class OtpBlocState {}

final class OtpBlocInitial extends OtpBlocState {}

// Email OTP Sending 
final class OtpSentLoading extends OtpBlocState {}

final class OtpSent extends OtpBlocState {}

final class OtpSentFailed extends OtpBlocState {}

// OTP Verification
final class OTPVerified extends OtpBlocState {}

final class OTPVerificationFailed extends OtpBlocState {}

final class OTPVerificationLoading extends OtpBlocState {}

// Password Creation
final class OTPPasswordCreated extends OtpBlocState {}

final class OTPPasswordFailed extends OtpBlocState {}

final class OTPPasswordLoading extends OtpBlocState {}