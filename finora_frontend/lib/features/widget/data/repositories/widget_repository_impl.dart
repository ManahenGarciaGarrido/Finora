import '../../domain/entities/widget_data_entity.dart';
import '../../domain/entities/widget_settings_entity.dart';
import '../../domain/repositories/widget_repository.dart';
import '../datasources/widget_remote_datasource.dart';
import '../models/widget_models.dart';

class WidgetRepositoryImpl implements WidgetRepository {
  final WidgetRemoteDataSource _ds;
  WidgetRepositoryImpl(this._ds);

  @override
  Future<WidgetDataEntity> getWidgetData() => _ds.getWidgetData();

  @override
  Future<WidgetSettingsEntity> getSettings() => _ds.getSettings();

  @override
  Future<void> saveSettings(WidgetSettingsEntity settings) =>
      _ds.saveSettings((settings as WidgetSettingsModel).toJson());
}
