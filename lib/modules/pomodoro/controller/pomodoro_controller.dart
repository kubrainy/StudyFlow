import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/study_session_repository.dart';
import '../../../data/repositories/user_settings_repository.dart';

enum PomodoroPhase { work, rest }

enum PomodoroStatus { idle, running, paused }

class PomodoroController extends ChangeNotifier {
  final StudySessionRepository _sessions;
  final UserSettingsRepository _settings;
  final DateTime Function() _now;

  PomodoroController(this._sessions, this._settings, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  PomodoroPhase _phase = PomodoroPhase.work;
  PomodoroStatus _status = PomodoroStatus.idle;
  String? _subjectId;

  /// Çalışma aşamasının ilk başladığı an (StudySession.startedAt olacak).
  DateTime? _startedAt;

  /// Sayacın şu anki çalışma parçasını başlattığı an (duraklayınca null).
  DateTime? _runningSince;

  /// Önceki parçalarda (duraklatmalardan önce) biriken süre.
  Duration _elapsedBefore = Duration.zero;

  /// Aşama başlayınca ayarlardan kopyalanır; çalışırken ayar değişse de sayaç
  /// başladığı süreyle biter. Hazırdayken null (o zaman ayarlardan okunur).
  Duration? _lockedTotal;

  /// Erken bitirilen çalışma en az bu kadar dakikaysa kaydedilir. Oturum
  /// dakika olarak tutulduğu için 1 dakikadan kısası kaydedilemez (0 dk olurdu).
  static const minSavedMinutes = 1;

  /// Süre ayar aralıkları (dk) ve adımları. Ekrandaki +/- bunları kullanır.
  static const workRange = (min: 5, max: 120, step: 5);
  static const restRange = (min: 1, max: 30, step: 1);

  /// Oturum kaydı başarısız olursa (ör. ders silinmiş) mesajı burada durur.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Saniyede bir tick() çağırır. Controller uygulama boyunca yaşadığı için
  /// kullanıcı başka sekmedeyken de sayaç işler.
  Timer? _ticker;

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  PomodoroPhase get phase => _phase;
  PomodoroStatus get status => _status;
  String? get subjectId => _subjectId;

  /// Bu aşamanın toplam süresi; başlamışsa kilitli değeri, değilse ayarları verir.
  Duration get totalDuration => _lockedTotal ?? _durationFor(_phase);

  Duration _durationFor(PomodoroPhase phase) {
    final settings = _settings.get();
    final minutes = phase == PomodoroPhase.work
        ? settings.pomodoroMinutes
        : settings.breakMinutes;
    return Duration(minutes: minutes);
  }

  /// Bu aşamada şimdiye kadar geçen süre.
  Duration get elapsed {
    final since = _runningSince;
    if (since == null) return _elapsedBefore;
    return _elapsedBefore + _now().difference(since);
  }

  Duration get remaining {
    final left = totalDuration - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// ilerleme halkası için 0-1
  double get progress {
    final total = totalDuration.inMilliseconds;
    if (total == 0) return 0;
    return (elapsed.inMilliseconds / total).clamp(0.0, 1.0);
  }

  /// Ders seçimi opsiyonel; sadece sayaç hazırdayken değiştirilebilir.
  void selectSubject(String? subjectId) {
    if (_status != PomodoroStatus.idle) return;
    _subjectId = subjectId;
    notifyListeners();
  }

  /// Şu anki aşamanın süre aralığı.
  ({int min, int max, int step}) get durationRange =>
      _phase == PomodoroPhase.work ? workRange : restRange;

  /// Şu anki aşamanın süresini (dk) ayarlara kaydeder. Yalnızca hazırdayken
  /// çalışır; çalışan sayaç başladığı süreyle biter. Aralık dışı değer sınıra
  /// çekilir.
  Future<void> setDuration(int minutes) async {
    if (_status != PomodoroStatus.idle) return;
    final range = durationRange;
    final value = minutes.clamp(range.min, range.max);
    if (_phase == PomodoroPhase.work) {
      await _settings.update(pomodoroMinutes: value);
    } else {
      await _settings.update(breakMinutes: value);
    }
    notifyListeners();
  }

  /// Bugün kaydedilen çalışma dakikaları. [subjectId] null ise derssiz
  /// (serbest) oturumlar toplanır.
  int todayMinutes(String? subjectId) {
    final now = _now();
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    return _sessions
        .getAll()
        .where((s) => s.subjectId == subjectId && isToday(s.startedAt))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  void start() {
    if (_status != PomodoroStatus.idle) return;
    _errorMessage = null;
    _beginPhase(_phase, _now());
    notifyListeners();
  }

  void pause() {
    if (_status != PomodoroStatus.running) return;
    _elapsedBefore = elapsed; // runningSince'i silmeden ÖNCE hesapla
    _runningSince = null;
    _status = PomodoroStatus.paused;
    _stopTicker();
    notifyListeners();
  }

  void resume() {
    if (_status != PomodoroStatus.paused) return;
    _runningSince = _now();
    _status = PomodoroStatus.running;
    _startTicker();
    notifyListeners();
  }

  /// Vazgeç: hiçbir şey kaydetmeden başa döner.
  void reset() {
    _clear();
    notifyListeners();
  }

  /// Ekrandaki zamanlayıcı saniyede bir çağırır: ekranı yeniler, süre
  /// dolduysa aşamayı tamamlar.
  Future<void> tick() async {
    if (_status != PomodoroStatus.running) return;
    if (elapsed < totalDuration) {
      notifyListeners();
      return;
    }
    await _completePhase();
  }

  /// Erken bitir: çalışmada geçen tam dakikalar kaydedilir (en az
  /// [minSavedMinutes]); 1 dakikadan kısası atılır. Moladaysa hiçbir şey
  /// kaydedilmez. Bittikten sonra sayaç hazırda, [next] aşamasında bekler.
  Future<void> finishEarly({PomodoroPhase next = PomodoroPhase.work}) async {
    if (_status == PomodoroStatus.idle) return;
    final startedAt = _startedAt;
    final minutes = elapsed.inMinutes;
    final shouldSave =
        _phase == PomodoroPhase.work && minutes >= minSavedMinutes;
    _clear();
    _phase = next;
    notifyListeners();
    if (shouldSave && startedAt != null) {
      await _saveSession(startedAt, minutes);
    }
  }

  /// Odaklan / Mola şeridine dokununca: hazırdayken aşama doğrudan seçilir;
  /// sayaç çalışıyorsa önce erken bitirilir (çalışma kaydedilir), sonra
  /// seçilen aşamada hazır bekler.
  Future<void> switchPhase(PomodoroPhase target) async {
    if (target == _phase) return;
    if (_status == PomodoroStatus.idle) {
      _phase = target;
      notifyListeners();
      return;
    }
    await finishEarly(next: target);
  }

  Future<void> _completePhase() async {
    if (_phase == PomodoroPhase.rest) {
      _clear();
      notifyListeners();
      return;
    }

    final startedAt = _startedAt!;
    final minutes = totalDuration.inMinutes;
    // Uygulama arkadayken süre dolduysa mola, çalışmanın bittiği andan sayılır.
    final phaseEnd = _now().subtract(elapsed - totalDuration);

    // Önce durumu değiştir (senkron), sonra kaydet: art arda iki tick
    // aynı oturumu iki kez kaydetmesin.
    _beginPhase(PomodoroPhase.rest, phaseEnd);
    notifyListeners();
    await _saveSession(startedAt, minutes);
  }

  Future<void> _saveSession(DateTime startedAt, int minutes) async {
    try {
      await _sessions.add(_subjectId, startedAt, minutes);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _beginPhase(PomodoroPhase phase, DateTime at) {
    _phase = phase;
    _lockedTotal = _durationFor(phase);
    _startedAt = at;
    _runningSince = at;
    _elapsedBefore = Duration.zero;
    _status = PomodoroStatus.running;
    _startTicker();
  }

  void _clear() {
    _phase = PomodoroPhase.work;
    _status = PomodoroStatus.idle;
    _startedAt = null;
    _runningSince = null;
    _elapsedBefore = Duration.zero;
    _lockedTotal = null;
    _stopTicker();
  }
}
