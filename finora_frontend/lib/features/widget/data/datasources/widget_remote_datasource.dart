import '../../../../core/network/api_client.dart';
import '../models/widget_models.dart';

abstract class WidgetRemoteDataSource {
  Future<WidgetDataModel> getWidgetData();
  Future<WidgetSettingsModel> getSettings();
  Future<void> saveSettings(Map<String, dynamic> settings);
}

class WidgetRemoteDataSourceImpl implements WidgetRemoteDataSource {
  final ApiClient _client;
  WidgetRemoteDataSourceImpl(this._client);

  @override
  Future<WidgetDataModel> getWidgetData() async {
    final res = await _client.get('/widget/data');
    return WidgetDataModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<WidgetSettingsModel> getSettings() async {
    final res = await _client.get('/widget/settings');
    final json = res.data['settings'] as Map<String, dynamic>? ?? {};
    return WidgetSettingsModel.fromJson(json);
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _client.patch('/widget/settings', data: {'settings': settings});
  }
}
