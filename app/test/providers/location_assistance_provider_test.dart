import 'package:conscia_app/providers/location_assistance_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationAssistanceService extends LocationAssistanceService {
  _FakeLocationAssistanceService({required this.permissionGranted});

  final bool permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;
}

void main() {
  test('first-use prompt is needed before the user has chosen', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(locationAssistanceProvider);

    expect(state.shouldPromptOnFeatureOpen, isTrue);
    expect(state.isEnabled, isFalse);
  });

  test('decline marks the feature as prompted and stops re-prompting',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    await container.read(locationAssistanceProvider.notifier).declinePrompt();

    final state = container.read(locationAssistanceProvider);

    expect(state.shouldPromptOnFeatureOpen, isFalse);
    expect(state.isEnabled, isFalse);
  });

  test('enable marks the feature active when permission succeeds', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        locationAssistanceServiceProvider.overrideWithValue(
          _FakeLocationAssistanceService(permissionGranted: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(locationAssistanceProvider.notifier).enableFromPrompt();

    final state = container.read(locationAssistanceProvider);

    expect(state.shouldPromptOnFeatureOpen, isFalse);
    expect(state.isEnabled, isTrue);
  });
}
