import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TtsState { stopped, playing, paused }

/// Représente une voix TTS disponible.
class TtsVoice {
  final String name;
  final String locale;

  const TtsVoice({required this.name, required this.locale});

  /// Nom court affiché à l'utilisateur (ex: "Denise (fr-FR) ✨")
  String get displayName {
    // extrait le prénom avant " - " ou avant " Online"
    final base = name
        .replaceAll(RegExp(r' Online \(Natural\)', caseSensitive: false), '')
        .replaceAll(RegExp(r' Online', caseSensitive: false), '')
        .replaceAll(RegExp(r' - .*'), '')
        .replaceAll('Microsoft ', '');
    final isNatural = name.toLowerCase().contains('natural') || name.toLowerCase().contains('neural');
    return isNatural ? '$base ✨' : base;
  }

  @override
  bool operator ==(Object other) => other is TtsVoice && other.name == name;
  @override
  int get hashCode => name.hashCode;
}

class TtsService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  TtsState _state = TtsState.stopped;
  int _currentVerseIndex = 0;
  double _speed = 1.0;
  final double _pitch = 1.0;
  List<String> _verses = [];

  List<TtsVoice> _availableVoices = [];
  TtsVoice? _selectedVoice;

  TtsState get state => _state;
  int get currentVerseIndex => _currentVerseIndex;
  double get speed => _speed;
  double get pitch => _pitch;
  bool get isPlaying => _state == TtsState.playing;

  List<TtsVoice> get availableVoices => _availableVoices;
  TtsVoice? get selectedVoice => _selectedVoice;

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(_speed);
    await _tts.setPitch(_pitch);

    // Sur le Web, on n'a pas setSharedInstance
    if (!kIsWeb) {
      try {
        await _tts.setSharedInstance(true);
      } catch (_) {}
    }

    // Charge les voix disponibles et restaure le choix sauvegardé
    // Sur Web, getVoices() est souvent vide au premier appel → retry après délai
    await _loadVoices();
    if (kIsWeb && _availableVoices.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      await _loadVoices();
    }

    _tts.setStartHandler(() {
      _state = TtsState.playing;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      _advanceToNext();
    });

    _tts.setCancelHandler(() {
      _state = TtsState.stopped;
      notifyListeners();
    });

    _tts.setPauseHandler(() {
      _state = TtsState.paused;
      notifyListeners();
    });

    _tts.setContinueHandler(() {
      _state = TtsState.playing;
      notifyListeners();
    });

    _tts.setErrorHandler((msg) {
      _state = TtsState.stopped;
      notifyListeners();
    });
  }

  /// Charge la liste des voix françaises et restaure le choix persisté.
  Future<void> _loadVoices() async {
    try {
      final voices = await _tts.getVoices;
      if (voices == null) return;
      final list = List<Map>.from(voices as List);
      final frVoices = list.where((v) {
        final locale = v['locale']?.toString() ?? '';
        final name = v['name']?.toString() ?? '';
        return locale.startsWith('fr') || name.toLowerCase().contains('fr-fr');
      }).map((v) => TtsVoice(name: v['name'] as String, locale: v['locale'] as String)).toList();

      // Trier : Natural fr-FR > Natural fr-* > standard fr-FR > reste
      frVoices.sort((a, b) {
        int score(TtsVoice v) {
          final isNat = v.name.toLowerCase().contains('natural') || v.name.toLowerCase().contains('neural');
          if (isNat && v.locale == 'fr-FR') return 0;
          if (isNat) return 1;
          if (v.locale == 'fr-FR') return 2;
          return 3;
        }
        return score(a).compareTo(score(b));
      });
      _availableVoices = frVoices;

      // Restaure le choix sauvegardé
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('tts_voice_name');
      TtsVoice? restored;
      if (savedName != null) {
        try {
          restored = frVoices.firstWhere((v) => v.name == savedName);
        } catch (_) {}
      }
      // Par défaut : meilleure voix (Natural fr-FR)
      _selectedVoice = restored ?? (frVoices.isNotEmpty ? frVoices.first : null);
      if (_selectedVoice != null) {
        await _tts.setVoice({'name': _selectedVoice!.name, 'locale': _selectedVoice!.locale});
      }
      notifyListeners();
    } catch (e) {
      debugPrint('TTS _loadVoices error: $e');
    }
  }

  /// Change la voix active et persiste le choix.
  Future<void> selectVoice(TtsVoice voice) async {
    _selectedVoice = voice;
    await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_voice_name', voice.name);
    notifyListeners();
  }

  /// Charge un nouveau chapitre et démarre la lecture depuis [fromIndex].
  Future<void> loadAndPlay({
    required List<String> verses,
    required List<int> verseNumbers,
    int fromIndex = 0,
  }) async {
    _verses = verses;
    _currentVerseIndex = fromIndex.clamp(0, verses.isEmpty ? 0 : verses.length - 1);
    await _tts.stop();
    await _speakCurrent();
  }

  /// Lecture depuis un verset précis sans recharger la liste.
  Future<void> playFrom(int index) async {
    if (_verses.isEmpty) return;
    _currentVerseIndex = index.clamp(0, _verses.length - 1);
    await _tts.stop();
    await _speakCurrent();
  }

  Future<void> pause() async {
    if (_state == TtsState.playing) {
      await _tts.pause();
    }
  }

  Future<void> resume() async {
    if (_state == TtsState.paused) {
      // flutter_tts resume() fonctionne sur Android/iOS mais pas toujours sur web
      final result = _tts.continueHandler;
      if (result == null) {
        // Fallback : relire le verset courant
        await _speakCurrent();
      }
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _state = TtsState.stopped;
    notifyListeners();
  }

  Future<void> skipNext() async {
    if (_currentVerseIndex < _verses.length - 1) {
      _currentVerseIndex++;
      _state = TtsState.playing; // évite le flicker "stopped" pendant le stop()
      notifyListeners();
      await _tts.stop();
      await _speakCurrent();
    }
  }

  Future<void> skipPrevious() async {
    if (_currentVerseIndex > 0) {
      _currentVerseIndex--;
      _state = TtsState.playing; // évite le flicker "stopped" pendant le stop()
      notifyListeners();
      await _tts.stop();
      await _speakCurrent();
    }
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.25, 2.0);
    await _tts.setSpeechRate(_speed);
    notifyListeners();
  }

  Future<void> _speakCurrent() async {
    if (_verses.isEmpty) return;
    final text = _verses[_currentVerseIndex];
    notifyListeners(); // met à jour le highlight
    await _tts.speak(text);
  }

  void _advanceToNext() {
    if (_currentVerseIndex < _verses.length - 1) {
      _currentVerseIndex++;
      _speakCurrent();
    } else {
      _state = TtsState.stopped;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
