import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:linkup/data/http_services/action_http_services/swipe_http_services.dart';
import 'package:linkup/data/http_services/match_http_services/match_http_services.dart';
import 'package:linkup/data/models/match_candidate_model.dart';
import 'package:linkup/data/models/matches_connection_model.dart';
import 'package:meta/meta.dart';

part 'matches_event.dart';
part 'matches_state.dart';

class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  MatchesBloc() : super(MatchesInitial()) {
    on<LoadMatchesEvent>((event, emit) async {
      emit(MatchesLoading());
      try {
        final List<MatchCandidateModel> matches = await MatchHttpServices().getMatchUsers();
        log(matches.toString(), name: "Mock matches loaded");

        if (matches.isEmpty) {
          emit(MatchesEmpty());
          return;
        }

        emit(MatchesLoaded(matches: matches));
      } on Exception catch (e, stackTrace) {
        log('Error loading matches: $e', stackTrace: stackTrace); 
        emit(MatchesError());
      }
    });

    on<MatchesDeckCompletedEvent>((event, emit) async {
      emit(MatchesEmpty());
    });
  
    on<ClearMatchUserEvent>((event, emit) {
      if (state is MatchesLoaded) {
        emit((state as MatchesLoaded).copyWith(clearMatchUser: true));
      }
    });

    on<SwipeProfileEvent>((event, emit) async {
      if (state is MatchesLoaded) {
        final response = await SwipeHttpServices.swipe(
          likedId: event.likedId,
          action: event.direction,
        );

        final nowState = state as MatchesLoaded;
        final isLastCard = event.previousIndex == (nowState.matches.length - 1);

        Future<void> handleOnMatchAndDeckCompletion({
          required bool didMatch
        }) async {
          if (isLastCard) {
            if (didMatch) {
              add(MatchesDeckCompletedEvent());
            } else {
              add(MatchesDeckCompletedEvent());
            }
          }
        }

        if (event.direction == CardSwiperDirection.right && response['match'] == true) {
          final matchedUserJson = Map<String, dynamic>.from(response['matched_user']);
          final MatchesConnectionModel newMatchUser = MatchesConnectionModel.fromJson(matchedUserJson);

          emit(
            (state as MatchesLoaded).copyWith(matchUser: newMatchUser)
          );
          await handleOnMatchAndDeckCompletion(didMatch: true);
        } else {
          await handleOnMatchAndDeckCompletion(didMatch: false);
        }
      }
    });
  
  }
}
