part of 'matches_bloc.dart';

@immutable
sealed class MatchesEvent {}

class LoadMatchesEvent extends MatchesEvent{}

class MatchesDeckCompletedEvent extends MatchesEvent{}

final class ClearMatchUserEvent extends MatchesEvent {}

class SwipeProfileEvent extends MatchesEvent{
  final int likedId;
  final int previousIndex;
  final CardSwiperDirection direction;

  SwipeProfileEvent({
    required this.likedId, 
    required this.direction,
    required this.previousIndex,
  });
}