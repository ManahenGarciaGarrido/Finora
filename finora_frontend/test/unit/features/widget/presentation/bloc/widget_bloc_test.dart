import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:finora_frontend/features/widget/presentation/bloc/widget_bloc.dart';
import 'package:finora_frontend/features/widget/presentation/bloc/widget_event.dart';
import 'package:finora_frontend/features/widget/presentation/bloc/widget_state.dart';
import 'package:finora_frontend/features/widget/domain/repositories/widget_repository.dart';
import 'package:finora_frontend/features/widget/domain/entities/widget_data_entity.dart';
import 'package:finora_frontend/features/widget/domain/entities/widget_settings_entity.dart';
import 'package:finora_frontend/features/widget/services/widget_channel_service.dart';

@GenerateMocks([WidgetRepository, WidgetChannelService])
import 'widget_bloc_test.mocks.dart';

void main() {
  late WidgetBloc bloc;
  late MockWidgetRepository mockRepo;
  late MockWidgetChannelService mockChannel;

  final tWidgetData = WidgetDataEntity(
    balance: 1250.50,
    todaySpent: 35.00,
    budgetPct: 45,
    activeGoal: WidgetActiveGoal(
      name: 'Emergency Fund',
      current: 500.0,
      target: 1000.0,
      pct: 50,
    ),
    updatedAt: '2026-04-09T10:00:00Z',
  );

  final tWidgetSettings = WidgetSettingsEntity(
    showBalance: true,
    showTodaySpent: true,
    showBudgetPct: false,
    darkMode: 'auto',
  );

  setUp(() {
    mockRepo = MockWidgetRepository();
    mockChannel = MockWidgetChannelService();
    bloc = WidgetBloc(mockRepo, mockChannel);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is WidgetInitial', () {
    expect(bloc.state, isA<WidgetInitial>());
  });

  group('LoadWidgetData', () {
    blocTest<WidgetBloc, WidgetState>(
      'emits [WidgetLoading, WidgetDataLoaded] on success',
      build: () {
        when(mockRepo.getWidgetData()).thenAnswer((_) async => tWidgetData);
        return bloc;
      },
      act: (b) => b.add(const LoadWidgetData()),
      expect: () => [isA<WidgetLoading>(), isA<WidgetDataLoaded>()],
      verify: (_) {
        verify(mockRepo.getWidgetData()).called(1);
      },
    );

    blocTest<WidgetBloc, WidgetState>(
      'WidgetDataLoaded contains correct data',
      build: () {
        when(mockRepo.getWidgetData()).thenAnswer((_) async => tWidgetData);
        return bloc;
      },
      act: (b) => b.add(const LoadWidgetData()),
      expect: () => [
        isA<WidgetLoading>(),
        predicate<WidgetState>((s) {
          if (s is WidgetDataLoaded) {
            return s.data.balance == 1250.50 &&
                s.data.todaySpent == 35.00 &&
                s.data.budgetPct == 45;
          }
          return false;
        }),
      ],
    );

    blocTest<WidgetBloc, WidgetState>(
      'emits [WidgetLoading, WidgetError] when getWidgetData fails',
      build: () {
        when(
          mockRepo.getWidgetData(),
        ).thenThrow(Exception('Widget data unavailable'));
        return bloc;
      },
      act: (b) => b.add(const LoadWidgetData()),
      expect: () => [isA<WidgetLoading>(), isA<WidgetError>()],
    );

    blocTest<WidgetBloc, WidgetState>(
      'WidgetError strips Exception: prefix',
      build: () {
        when(
          mockRepo.getWidgetData(),
        ).thenThrow(Exception('Widget data unavailable'));
        return bloc;
      },
      act: (b) => b.add(const LoadWidgetData()),
      expect: () => [
        isA<WidgetLoading>(),
        predicate<WidgetState>((s) {
          if (s is WidgetError) {
            return s.message == 'Widget data unavailable';
          }
          return false;
        }),
      ],
    );
  });

  group('LoadWidgetSettings', () {
    blocTest<WidgetBloc, WidgetState>(
      'emits [WidgetLoading, WidgetSettingsLoaded] on success',
      build: () {
        when(mockRepo.getSettings()).thenAnswer((_) async => tWidgetSettings);
        return bloc;
      },
      act: (b) => b.add(const LoadWidgetSettings()),
      expect: () => [isA<WidgetLoading>(), isA<WidgetSettingsLoaded>()],
      verify: (_) {
        verify(mockRepo.getSettings()).called(1);
      },
    );

    blocTest<WidgetBloc, WidgetState>(
      'WidgetSettingsLoaded with default values',
      build: () {
        const defaultSettings = WidgetSettingsEntity(
          showBalance: true,
          showTodaySpent: true,
          showBudgetPct: true,
          darkMode: 'auto',
        );
        when(mockRepo.getSettings()).thenAnswer((_) async => defaultSettings);
        return bloc;
      },
      act: (b) => b.add(const LoadWidgetSettings()),
      expect: () => [
        isA<WidgetLoading>(),
        predicate<WidgetState>((s) {
          if (s is WidgetSettingsLoaded) {
            return s.settings.showBalance == true &&
                s.settings.showTodaySpent == true &&
                s.settings.showBudgetPct == true &&
                s.settings.darkMode == 'auto';
          }
          return false;
        }),
      ],
    );

    blocTest<WidgetBloc, WidgetState>(
      'emits [WidgetLoading, WidgetError] when getSettings fails',
      build: () {
        when(mockRepo.getSettings()).thenThrow(Exception('Settings not found'));
        return bloc;
      },
      act: (b) => b.add(const LoadWidgetSettings()),
      expect: () => [isA<WidgetLoading>(), isA<WidgetError>()],
    );
  });

  group('SaveWidgetSettings', () {
    blocTest<WidgetBloc, WidgetState>(
      'emits [WidgetSettingsSaved, WidgetLoading, WidgetSettingsLoaded] on success',
      build: () {
        when(mockRepo.saveSettings(any)).thenAnswer((_) async {
          return;
        });
        when(mockRepo.getSettings()).thenAnswer((_) async => tWidgetSettings);
        return bloc;
      },
      act: (b) => b.add(
        const SaveWidgetSettings(
          showBalance: true,
          showTodaySpent: true,
          showBudgetPct: false,
          darkMode: 'auto',
        ),
      ),
      expect: () => [
        isA<WidgetSettingsSaved>(),
        isA<WidgetLoading>(),
        isA<WidgetSettingsLoaded>(),
      ],
      verify: (_) {
        verify(mockRepo.saveSettings(any)).called(1);
        verify(mockRepo.getSettings()).called(1);
      },
    );

    blocTest<WidgetBloc, WidgetState>(
      'auto-reloads settings after save',
      build: () {
        when(mockRepo.saveSettings(any)).thenAnswer((_) async {
          return;
        });
        when(mockRepo.getSettings()).thenAnswer((_) async => tWidgetSettings);
        return bloc;
      },
      act: (b) => b.add(
        const SaveWidgetSettings(
          showBalance: false,
          showTodaySpent: false,
          showBudgetPct: false,
          darkMode: 'dark',
        ),
      ),
      expect: () => [
        isA<WidgetSettingsSaved>(),
        isA<WidgetLoading>(),
        isA<WidgetSettingsLoaded>(),
      ],
    );

    blocTest<WidgetBloc, WidgetState>(
      'emits [WidgetError] when saveSettings fails',
      build: () {
        when(mockRepo.saveSettings(any)).thenThrow(Exception('Save failed'));
        return bloc;
      },
      act: (b) => b.add(
        const SaveWidgetSettings(
          showBalance: true,
          showTodaySpent: true,
          showBudgetPct: true,
          darkMode: 'auto',
        ),
      ),
      expect: () => [isA<WidgetError>()],
    );
  });

  group('RefreshAndPushWidget', () {
    blocTest<WidgetBloc, WidgetState>(
      'emits [WidgetPushed, WidgetDataLoaded] on success',
      build: () {
        when(mockRepo.getWidgetData()).thenAnswer((_) async => tWidgetData);
        when(mockChannel.pushWidgetData(any)).thenAnswer((_) async {
          return;
        });
        return bloc;
      },
      act: (b) => b.add(const RefreshAndPushWidget()),
      expect: () => [isA<WidgetPushed>(), isA<WidgetDataLoaded>()],
      verify: (_) {
        verify(mockRepo.getWidgetData()).called(1);
        verify(mockChannel.pushWidgetData(any)).called(1);
      },
    );

    blocTest<WidgetBloc, WidgetState>(
      'WidgetDataLoaded contains fresh data after push',
      build: () {
        when(mockRepo.getWidgetData()).thenAnswer((_) async => tWidgetData);
        when(mockChannel.pushWidgetData(any)).thenAnswer((_) async {
          return;
        });
        return bloc;
      },
      act: (b) => b.add(const RefreshAndPushWidget()),
      expect: () => [
        isA<WidgetPushed>(),
        predicate<WidgetState>((s) {
          if (s is WidgetDataLoaded) {
            return s.data.balance == 1250.50;
          }
          return false;
        }),
      ],
    );

    blocTest<WidgetBloc, WidgetState>(
      'emits [WidgetError] when getWidgetData throws',
      build: () {
        when(
          mockRepo.getWidgetData(),
        ).thenThrow(Exception('Data fetch failed'));
        return bloc;
      },
      act: (b) => b.add(const RefreshAndPushWidget()),
      expect: () => [isA<WidgetError>()],
    );

    blocTest<WidgetBloc, WidgetState>(
      'emits [WidgetError] when channel push fails',
      build: () {
        when(mockRepo.getWidgetData()).thenAnswer((_) async => tWidgetData);
        when(
          mockChannel.pushWidgetData(any),
        ).thenThrow(Exception('Channel not available'));
        return bloc;
      },
      act: (b) => b.add(const RefreshAndPushWidget()),
      expect: () => [isA<WidgetError>()],
    );
  });
}

