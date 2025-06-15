import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:linkup/data/http_services/user_http_services/user_http_services.dart';
import 'package:linkup/data/models/update_metadata_model.dart';
import 'package:linkup/data/models/user_model.dart';
import 'package:meta/meta.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    on<ProfileLoadEvent>((event, emit) async {
      if (event.showLoading) {
        emit(ProfileLoading());
      }
      log("Loading profile details");
      try {
        final UserModel user = await UserHttpServices().getProfileSettings();
        emit(ProfileLoaded(user: user));
      } on Exception catch (e) {
        log('Error loading profile: $e');
        emit(ProfileError());
      }
    });

    on<ProfileUpdateEvent>((event, emit) async {
      try {
        await UserHttpServices().updateUserProfile(userUpdatedModel: event.userUpdatedModel);

        add(ProfileLoadEvent(showLoading: false));
      } on Exception catch (e) {
        log('Error loading profile: $e');
        emit(ProfileError());
      }
    });
  }
}
