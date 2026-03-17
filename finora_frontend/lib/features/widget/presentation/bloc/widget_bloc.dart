import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/widget_repository.dart';
import '../../data/models/widget_models.dart';
import '../../services/widget_channel_service.dart';
import 'widget_event.dart';
import 'widget_state.dart';

class WidgetBloc extends Bloc<WidgetEvent, WidgetState> {
  final WidgetRepository _repo;
  final WidgetChannelService _channel;

  WidgetBloc(this._repo, this._channel) : super(const WidgetInitial()) {
    on<LoadWidgetData>(_onLoad);
    on<LoadWidgetSettings>(_onLoadSettings);
    on<SaveWidgetSettings>(_onSave);
    on<RefreshAndPushWidget>(_onRefreshPush);
  }

  Future<void> _onLoad(LoadWidgetData e, Emitter<WidgetState> emit) async {
    emit(const WidgetLoading());
    try {
      final data = await _repo.getWidgetData();
      emit(WidgetDataLoaded(data));
    } catch (err) {
      emit(WidgetError(_msg(err)));
    }
  }

  Future<void> _onLoadSettings(
    LoadWidgetSettings e,
    Emitter<WidgetState> emit,
  ) async {
    emit(const WidgetLoading());
    try {
      final settings = await _repo.getSettings();
      emit(WidgetSettingsLoaded(settings));
    } catch (err) {
      emit(WidgetError(_msg(err)));
    }
  }

  Future<void> _onSave(SaveWidgetSettings e, Emitter<WidgetState> emit) async {
    try {
      final settings = WidgetSettingsModel(
        showBalance: e.showBalance,
        showTodaySpent: e.showTodaySpent,
        showBudgetPct: e.showBudgetPct,
        darkMode: e.darkMode,
      );
      await _repo.saveSettings(settings);
      emit(const WidgetSettingsSaved());
      add(const LoadWidgetSettings());
    } catch (err) {
      emit(WidgetError(_msg(err)));
    }
  }

  Future<void> _onRefreshPush(
    RefreshAndPushWidget e,
    Emitter<WidgetState> emit,
  ) async {
    try {
      final data = await _repo.getWidgetData();
      await _channel.pushWidgetData(data);
      emit(const WidgetPushed());
      emit(WidgetDataLoaded(data));
    } catch (err) {
      emit(WidgetError(_msg(err)));
    }
  }

  String _msg(Object e) => e.toString().replaceAll('Exception: ', '');
}
