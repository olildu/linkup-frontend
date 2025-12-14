import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:linkup/data/enums/otp_subject_enum.dart';
import 'package:linkup/data/http_services/auth_http_services/auth_http_services.dart';
import 'package:meta/meta.dart';

part 'otp_event.dart';
part 'otp_state.dart';

class OtpBloc extends Bloc<OtpBlocEvent, OtpBlocState> {
  static const String _logTag = 'OtpBloc';
  static String hash = '';

  OtpBloc() : super(OtpBlocInitial()) {
    on<SendOTPEvent>(_onSendOTP);
    on<VerifyOTPEvent>(_verifyOTP);
    on<CompleteSignUpEvent>(_sendSignupCreds);
    on<ResetPasswordSubmittedEvent>(_onResetPassword);
  }

  Future<void> _onSendOTP(SendOTPEvent event, Emitter<OtpBlocState> emit) async {
    log('SendOTPEvent triggered with email: ${event.email}', name: _logTag);
    emit(OtpSentLoading());
    log('State emitted: OtpSentLoading', name: _logTag);

    try {
      final result = await AuthHttpServices.sendEmailOTP(email: event.email);
      log('AuthHttpServices response: $result', name: _logTag);

      if (result == 200) {
        emit(OtpSent());
        log('State emitted: OtpSent', name: _logTag);
      } else {
        log('Failed to send OTP, adding EmailSendErrorEvent', name: _logTag);
        add(EmailSendErrorEvent());
      }
    } catch (e, stackTrace) {
      log('Exception caught: $e', name: _logTag, stackTrace: stackTrace);
      add(EmailSendErrorEvent());
    }
  }

  Future<void> _verifyOTP(VerifyOTPEvent event, Emitter<OtpBlocState> emit) async {
    emit(OTPVerificationLoading());
    log('VerifyOTPEvent triggered with otp: ${event.otp}', name: _logTag);

    try {
      final result = await AuthHttpServices.verifyEmailOTP(email: event.email, otp: event.otp, subject: event.subject);

      if (result['status'] == 'success') {
        log('OTP verification successful', name: _logTag);
        hash = result['email_hash'];
        emit(OTPVerified());
      } else {
        log('OTP verification failed: incorrect OTP', name: _logTag);
        emit(OTPVerificationFailed());
      }
    } catch (e, stackTrace) {
      log('Exception during OTP verification: $e', name: _logTag, error: e, stackTrace: stackTrace);
      emit(OTPVerificationFailed());
    }
  }

  Future<void> _sendSignupCreds(CompleteSignUpEvent event, Emitter<OtpBlocState> emit) async {
    emit(OTPPasswordLoading());

    try {
      final result = await AuthHttpServices.completeSignupCreds(emailHash: hash, password: event.password);

      if (result) {
        log('Account created successfully', name: _logTag);
        emit(OTPPasswordCreated());
      } else {
        emit(OTPPasswordFailed());
      }
      hash = '';
    } catch (e, stackTrace) {
      log('Exception during password send: $e', name: _logTag, error: e, stackTrace: stackTrace);
      hash = '';
      emit(OTPPasswordFailed());
    }
  }

  Future<void> _onResetPassword(ResetPasswordSubmittedEvent event, Emitter<OtpBlocState> emit) async {
    emit(OTPPasswordLoading());

    try {
      // Use the new resetPassword service method
      final result = await AuthHttpServices.resetPassword(emailHash: hash, password: event.password);

      if (result) {
        log('Password reset successfully', name: _logTag);
        emit(OTPPasswordCreated());
      } else {
        emit(OTPPasswordFailed());
      }
      hash = '';
    } catch (e, stackTrace) {
      log('Exception during password reset: $e', name: _logTag, error: e, stackTrace: stackTrace);
      hash = '';
      emit(OTPPasswordFailed());
    }
  }
}
