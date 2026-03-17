import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/gamification_repository.dart';
import 'gamification_event.dart';
import 'gamification_state.dart';

class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final GamificationRepository _repo;

  GamificationBloc(this._repo) : super(const GamificationInitial()) {
    on<LoadGamificationData>(_onLoad);
    on<RecordStreak>(_onRecordStreak);
    on<CheckBadges>(_onCheckBadges);
    on<JoinChallenge>(_onJoinChallenge);
    on<UpdateChallengeProgress>(_onUpdateProgress);
  }

  Future<void> _onLoad(
    LoadGamificationData e,
    Emitter<GamificationState> emit,
  ) async {
    emit(const GamificationLoading());
    try {
      final results = await Future.wait([
        _repo.getStreaks(),
        _repo.getBadges(),
        _repo.getChallenges(),
        _repo.getHealthScore(),
      ]);
      emit(
        GamificationLoaded(
          streaks: results[0] as dynamic,
          badges: results[1] as dynamic,
          challenges: results[2] as dynamic,
          healthScore: results[3] as dynamic,
        ),
      );
    } catch (err) {
      emit(GamificationError(_msg(err)));
    }
  }

  Future<void> _onRecordStreak(
    RecordStreak e,
    Emitter<GamificationState> emit,
  ) async {
    try {
      await _repo.recordStreak(e.streakType);
      add(const LoadGamificationData());
    } catch (err) {
      emit(GamificationError(_msg(err)));
    }
  }

  Future<void> _onCheckBadges(
    CheckBadges e,
    Emitter<GamificationState> emit,
  ) async {
    try {
      final awarded = await _repo.checkAndAwardBadges();
      if (awarded.isNotEmpty) emit(BadgesAwarded(awarded));
      add(const LoadGamificationData());
    } catch (err) {
      emit(GamificationError(_msg(err)));
    }
  }

  Future<void> _onJoinChallenge(
    JoinChallenge e,
    Emitter<GamificationState> emit,
  ) async {
    try {
      await _repo.joinChallenge(e.challengeId);
      emit(const ChallengeJoined());
      add(const LoadGamificationData());
    } catch (err) {
      emit(GamificationError(_msg(err)));
    }
  }

  Future<void> _onUpdateProgress(
    UpdateChallengeProgress e,
    Emitter<GamificationState> emit,
  ) async {
    try {
      await _repo.updateChallengeProgress(e.challengeId, e.progress);
      add(const LoadGamificationData());
    } catch (err) {
      emit(GamificationError(_msg(err)));
    }
  }

  String _msg(Object e) => e.toString().replaceAll('Exception: ', '');
}
