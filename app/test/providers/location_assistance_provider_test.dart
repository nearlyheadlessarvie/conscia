import 'package:conscia_app/providers/location_assistance_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
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
  ProviderContainer buildContainer(
    SharedPreferences prefs, {
    LocationAssistanceService? service,
  }) {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (service != null)
          locationAssistanceServiceProvider.overrideWithValue(service),
      ],
    );
  }

  test('first-use prompt is needed before the user has chosen', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(prefs);
    addTearDown(container.dispose);

    final state = container.read(locationAssistanceProvider);

    expect(state.shouldPromptOnFeatureOpen, isTrue);
    expect(state.isEnabled, isFalse);
  });

  test('decline marks the feature as prompted and stops re-prompting',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(prefs);
    addTearDown(container.dispose);

    await container.read(locationAssistanceProvider.notifier).declinePrompt();

    final rehydratedContainer = buildContainer(prefs);
    addTearDown(rehydratedContainer.dispose);
    final state = rehydratedContainer.read(locationAssistanceProvider);

    expect(state.shouldPromptOnFeatureOpen, isFalse);
    expect(state.hasPrompted, isTrue);
    expect(state.isEnabled, isFalse);
  });

  test('enable marks the feature active when permission succeeds', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(permissionGranted: true),
    );
    addTearDown(container.dispose);

    await container.read(locationAssistanceProvider.notifier).enableFromPrompt();

    final rehydratedContainer = buildContainer(
      prefs,
      service: _FakeLocationAssistanceService(permissionGranted: true),
    );
    addTearDown(rehydratedContainer.dispose);
    final state = rehydratedContainer.read(locationAssistanceProvider);

    expect(state.shouldPromptOnFeatureOpen, isFalse);
    expect(state.hasPrompted, isTrue);
    expect(state.isEnabled, isTrue);
  });
}
