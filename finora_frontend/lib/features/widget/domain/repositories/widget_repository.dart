import '../entities/widget_data_entity.dart';
import '../entities/widget_settings_entity.dart';

abstract class WidgetRepository {
  Future<WidgetDataEntity> getWidgetData();
  Future<WidgetSettingsEntity> getSettings();
  Future<void> saveSettings(WidgetSettingsEntity settings);
}
