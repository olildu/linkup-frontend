import 'package:bloc/bloc.dart';
import 'package:linkup/data/http_services/auth_http_services/auth_http_services.dart';
import 'package:meta/meta.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(LoginInitial()) {
    on<LoginSubmitted>((event, emit) async {
      emit(LoginLoading());
      try {
        final int statusCode = await AuthHttpServices.login(event.email, event.password);
        
        if (statusCode == 200) {
          emit(LoginSuccess());
        } else if (statusCode == 400) {
          emit(LoginFailure(errorMessage: 'Invalid email or password'));
        } else {
          emit(LoginFailure(errorMessage: 'Something went wrong. Please try again later.'));
        }
      } catch (e) {
        emit(LoginFailure(errorMessage: 'Connection error. Please check your internet.'));
      }
    });
  }
}