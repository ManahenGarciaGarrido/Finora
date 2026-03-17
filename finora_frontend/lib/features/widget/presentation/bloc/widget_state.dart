import '../../domain/entities/widget_data_entity.dart';
import '../../domain/entities/widget_settings_entity.dart';

abstract class WidgetState {
  const WidgetState();
}

class WidgetInitial extends WidgetState {
  const WidgetInitial();
}

class WidgetLoading extends WidgetState {
  const WidgetLoading();
}

class WidgetDataLoaded extends WidgetState {
  final WidgetDataEntity data;
  const WidgetDataLoaded(this.data);
}

class WidgetSettingsLoaded extends WidgetState {
  final WidgetSettingsEntity settings;
  const WidgetSettingsLoaded(this.settings);
}

class WidgetSettingsSaved extends WidgetState {
  const WidgetSettingsSaved();
}

class WidgetPushed extends WidgetState {
  const WidgetPushed();
}

class WidgetError extends WidgetState {
  final String message;
  const WidgetError(this.message);
}
