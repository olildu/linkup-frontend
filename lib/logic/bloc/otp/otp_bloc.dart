import 'package:bloc/bloc.dart';
import 'package:linkup/data/enums/otp_subject_enum.dart';
import 'package:linkup/data/http_services/auth_http_services/auth_http_services.dart';
import 'package:meta/meta.dart';

part 'otp_event.dart';
part 'otp_state.dart';

class OtpBloc extends Bloc<OtpBlocEvent, OtpState> {
  OtpBloc() : super(OtpInitial()) {
    on<SendOTPEvent>((event, emit) async {
      emit(OtpLoading());
      try {
        final res = await AuthHttpServices.sendEmailOTP(email: event.email);
        if (res == 200) {
          emit(OtpSent());
        } else {
          emit(OtpFailure(message: "Failed to send OTP"));
        }
      } catch (e) {
        emit(OtpFailure(message: e.toString()));
      }
    });

    on<VerifyOTPEvent>((event, emit) async {
      emit(OtpLoading());
      try {
        final res = await AuthHttpServices.verifyEmailOTP(email: event.email, otp: event.otp, subject: event.subject);
        emit(OtpVerified(emailHash: res['email_hash']));
      } catch (e) {
        emit(OtpFailure(message: e.toString()));
      }
    });
  }
}
