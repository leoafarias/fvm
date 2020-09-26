import 'package:fvm/fvm.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

final settingsRepoProvider = Provider((_) => Settings());

final settingsProvider = StateNotifierProvider<SettingsProvider>((ref) {
  return SettingsProvider(initialState: Settings());
});

class SettingsProvider extends StateNotifier<Settings> {
  SettingsProvider({Settings initialState}) : super(initialState) {
    // Set initial settings from local storage
    _init();
  }

  Future<void> _init() async {
    state = await Settings.read();
  }

  Future<Settings> read() async {
    return state = await Settings.read();
  }

  Future<void> save(Settings settings) async {
    state = settings;
    await settings.save();
  }

  void reload() {
    state = state;
  }
}
