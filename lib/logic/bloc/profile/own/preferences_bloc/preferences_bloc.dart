import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:linkup/data/http_services/user_http_services/user_http_services.dart';
import 'package:linkup/data/models/user_preference_model.dart';
import 'package:meta/meta.dart';

part 'preferences_event.dart';
part 'preferences_state.dart';

class PreferencesBloc extends Bloc<PreferencesEvent, PreferencesState> {
  PreferencesBloc() : super(PreferencesInitial()) {
    on<PreferencesLoadEvent>((event, emit) async {
      emit(PreferencesLoading());

      try {
        UserPreferenceModel userPreference = await UserHttpServices().getUserPreference();
        emit(PreferencesLoaded(
          userPreference: userPreference,
        ));
      } catch (e) {
        emit(PreferencesError());
      }
    });

    on<PreferencesUpdateEvent>((event, emit) async {
      emit(PreferencesLoaded(userPreference: event.userPreference));
      log('PreferencesUpdateEvent: ${event.userPreference.toJson()}');

      await UserHttpServices().updateUserPreference(
        userPreference: event.userPreference,
      );
    });
  }
}
