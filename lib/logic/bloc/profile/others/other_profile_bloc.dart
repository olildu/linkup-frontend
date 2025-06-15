
import 'package:bloc/bloc.dart';
import 'package:linkup/data/http_services/user_http_services/user_http_services.dart';
import 'package:linkup/data/models/match_candidate_model.dart';
import 'package:meta/meta.dart';

part 'other_profile_event.dart';
part 'other_profile_state.dart';

class OtherProfileBloc extends Bloc<OtherProfileEvent, OtherProfileState> {
  OtherProfileBloc() : super(OtherProfileInitial()) {
    on<LoadOtherProfileEvent>((event, emit) async {
      emit(OtherProfileLoading());

        final user = await UserHttpServices().getOtherProfile(userId: event.userId);
        emit(OtherProfileLoaded(user: user));

    });
  }
}
