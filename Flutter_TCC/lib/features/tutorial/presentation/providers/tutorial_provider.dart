import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kIntroSeen   = 'tutorial_intro_seen';
const _kTipsEnabled = 'tutorial_tips_enabled';
const _kSeenScreens = 'tutorial_seen_screens';

/// Preferências do tutorial, guardadas no aparelho.
class TutorialPrefs {
  const TutorialPrefs({
    this.loaded = false,
    this.introSeen = false,
    this.tipsEnabled = true,
    this.seenScreens = const {},
  });

  /// Já leu do aparelho (antes disso nada é oferecido).
  final bool loaded;

  /// Boas-vindas já exibidas (vistas ou puladas).
  final bool introSeen;

  /// Oferecer o passo a passo na primeira visita a cada tela.
  final bool tipsEnabled;

  /// Telas cujo tutorial já foi oferecido.
  final Set<String> seenScreens;

  /// Deve perguntar se o usuário quer ver o tutorial da tela [id]?
  bool shouldOffer(String id) =>
      loaded && introSeen && tipsEnabled && !seenScreens.contains(id);

  TutorialPrefs copyWith({
    bool? loaded,
    bool? introSeen,
    bool? tipsEnabled,
    Set<String>? seenScreens,
  }) =>
      TutorialPrefs(
        loaded:      loaded ?? this.loaded,
        introSeen:   introSeen ?? this.introSeen,
        tipsEnabled: tipsEnabled ?? this.tipsEnabled,
        seenScreens: seenScreens ?? this.seenScreens,
      );
}

final tutorialProvider = StateNotifierProvider<TutorialNotifier, TutorialPrefs>(
  (ref) => TutorialNotifier(),
);

class TutorialNotifier extends StateNotifier<TutorialPrefs> {
  TutorialNotifier() : super(const TutorialPrefs()) {
    unawaited(_load());
  }

  final _ready = Completer<void>();

  /// Completa quando as preferências foram lidas do aparelho.
  Future<void> get ready => _ready.future;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = TutorialPrefs(
        loaded:      true,
        introSeen:   prefs.getBool(_kIntroSeen) ?? false,
        tipsEnabled: prefs.getBool(_kTipsEnabled) ?? true,
        seenScreens: (prefs.getStringList(_kSeenScreens) ?? const []).toSet(),
      );
    } on Exception {
      // Sem armazenamento local: não mostra as boas-vindas a cada abertura.
      state = const TutorialPrefs(loaded: true, introSeen: true, tipsEnabled: false);
    }
    if (!_ready.isCompleted) _ready.complete();
  }

  /// Fecha as boas-vindas. [tips] liga ou desliga o passo a passo nas telas.
  Future<void> finishIntro({required bool tips}) async {
    state = state.copyWith(introSeen: true, tipsEnabled: tips);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIntroSeen, true);
    await prefs.setBool(_kTipsEnabled, tips);
  }

  /// Marca a tela [id] como apresentada (o convite não volta a aparecer).
  Future<void> markSeen(String id) async {
    if (state.seenScreens.contains(id)) return;
    state = state.copyWith(seenScreens: {...state.seenScreens, id});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kSeenScreens, state.seenScreens.toList());
  }

  Future<void> setTipsEnabled({required bool enabled}) async {
    state = state.copyWith(tipsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTipsEnabled, enabled);
  }

  /// Volta a oferecer o tutorial em todas as telas.
  Future<void> resetScreens() async {
    state = state.copyWith(seenScreens: const {}, tipsEnabled: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSeenScreens);
    await prefs.setBool(_kTipsEnabled, true);
  }
}
