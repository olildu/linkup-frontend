import 'package:bloc/bloc.dart';
import 'package:linkup/data/http_services/auth_http_services/auth_http_services.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final res = await AuthHttpServices.login(event.email, event.password);
        if (res == 200) emit(AuthAuthenticated());
        else emit(AuthFailure(message: "Invalid email or password"));
      } catch (e) {
        emit(AuthFailure(message: e.toString()));
      }
    });

    on<AuthRegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final success = await AuthHttpServices.completeSignupCreds(emailHash: event.emailHash, password: event.password);
        if (success) emit(AuthAuthenticated());
        else emit(AuthFailure(message: "Registration failed"));
      } catch (e) {
        emit(AuthFailure(message: e.toString()));
      }
    });

    on<AuthResetPasswordRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final success = await AuthHttpServices.resetPassword(emailHash: event.emailHash, password: event.password);
        if (success) emit(AuthAuthenticated());
        else emit(AuthFailure(message: "Reset failed"));
      } catch (e) {
        emit(AuthFailure(message: e.toString()));
      }
    });
  }
}