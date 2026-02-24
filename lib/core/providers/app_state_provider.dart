import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  final bool isFirstRun;
  final bool isInitialized;

  AppState({this.isFirstRun = true, this.isInitialized = false});

  AppState copyWith({bool? isFirstRun, bool? isInitialized}) {
    return AppState(
      isFirstRun: isFirstRun ?? this.isFirstRun,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('isFirstRun') ?? true;
    state = state.copyWith(isFirstRun: isFirstRun, isInitialized: true);
  }

  Future<void> markFirstRunComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);
    state = state.copyWith(isFirstRun: false);
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});
