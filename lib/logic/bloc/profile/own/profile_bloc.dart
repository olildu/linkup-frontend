import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:linkup/data/http_services/user_http_services/user_http_services.dart';
import 'package:linkup/data/models/user_model.dart';
import 'package:meta/meta.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    on<ProfileLoadEvent>((event, emit) async {
      emit(ProfileLoading());
      try {
        final UserModel user = await UserHttpServices().getProfileSettings();
        emit(ProfileLoaded(user: user));
      } on Exception catch (e) {
        log('Error loading profile: $e'); 
        emit(ProfileError());
      }
    });
  }
}
