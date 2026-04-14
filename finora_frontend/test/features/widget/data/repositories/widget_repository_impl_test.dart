import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/widget/data/datasources/widget_remote_datasource.dart';
import 'package:finora_frontend/features/widget/data/models/widget_models.dart';
import 'package:finora_frontend/features/widget/data/repositories/widget_repository_impl.dart';
import 'package:finora_frontend/features/widget/domain/entities/widget_data_entity.dart';
import 'package:finora_frontend/features/widget/domain/entities/widget_settings_entity.dart';

import 'widget_repository_impl_test.mocks.dart';

@GenerateMocks([WidgetRemoteDataSource])
void main() {
  late MockWidgetRemoteDataSource mockDs;
  late WidgetRepositoryImpl repository;

  final tData = WidgetDataModel.fromJson(<String, dynamic>{
    'balance': 1500.0,
    'today_spent': 45.0,
    'budget_pct': 60,
    'updated_at': '2024-06-01',
  });

  const tSettings = WidgetSettingsModel(
    showBalance: true,
    showTodaySpent: true,
    showBudgetPct: false,
    darkMode: 'auto',
  );

  setUp(() {
    mockDs = MockWidgetRemoteDataSource();
    repository = WidgetRepositoryImpl(mockDs);
  });

  // ── getWidgetData ─────────────────────────────────────────────────────────
  group('getWidgetData', () {
    test('retorna WidgetDataEntity del datasource', () async {
      when(mockDs.getWidgetData()).thenAnswer((_) async => tData);

      final result = await repository.getWidgetData();

      expect(result, isA<WidgetDataEntity>());
      expect(result.balance, 1500.0);
      verify(mockDs.getWidgetData()).called(1);
    });

    test('propaga excepción del datasource', () async {
      when(
        mockDs.getWidgetData(),
      ).thenAnswer((_) async => throw Exception('Network error'));

      expect(repository.getWidgetData(), throwsException);
    });
  });

  // ── getSettings ───────────────────────────────────────────────────────────
  group('getSettings', () {
    test('retorna WidgetSettingsEntity del datasource', () async {
      when(mockDs.getSettings()).thenAnswer((_) async => tSettings);

      final result = await repository.getSettings();

      expect(result, isA<WidgetSettingsEntity>());
      expect(result.darkMode, 'auto');
      verify(mockDs.getSettings()).called(1);
    });
  });

  // ── saveSettings ──────────────────────────────────────────────────────────
  group('saveSettings', () {
    test('delega al datasource con los settings en JSON', () async {
      when(
        mockDs.saveSettings(any),
      ).thenAnswer((_) async => Future<void>.value());

      await repository.saveSettings(tSettings);

      verify(mockDs.saveSettings(tSettings.toJson())).called(1);
    });

    test('propaga excepción del datasource', () async {
      when(
        mockDs.saveSettings(any),
      ).thenAnswer((_) async => throw Exception('Error saving'));

      expect(repository.saveSettings(tSettings), throwsException);
    });
  });
}
