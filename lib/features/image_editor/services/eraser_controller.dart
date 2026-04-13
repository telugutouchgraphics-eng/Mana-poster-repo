import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'editor_history_service.dart';

enum EraserBlendMode { erase, restore }

@immutable
class EraserBrushSettings {
  const EraserBrushSettings({
    required this.size,
    required this.hardness,
    required this.strength,
    this.pressure = 1,
  });

  final double size;
  final double hardness;
  final double strength;
  final double pressure;

  EraserBrushSettings copyWith({
    double? size,
    double? hardness,
    double? strength,
    double? pressure,
  }) {
    return EraserBrushSettings(
      size: size ?? this.size,
      hardness: hardness ?? this.hardness,
      strength: strength ?? this.strength,
      pressure: pressure ?? this.pressure,
    );
  }
}

@immutable
class EraserStrokePoint {
  const EraserStrokePoint({
    required this.normalized,
    required this.radiusInImagePixels,
    required this.hardness,
    required this.strength,
    required this.pressure,
  });

  final Offset normalized;
  final double radiusInImagePixels;
  final double hardness;
  final double strength;
  final double pressure;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'x': normalized.dx,
      'y': normalized.dy,
      'radius': radiusInImagePixels,
      'hardness': hardness,
      'strength': strength,
      'pressure': pressure,
    };
  }

  factory EraserStrokePoint.fromMap(Map<String, dynamic> map) {
    return EraserStrokePoint(
      normalized: Offset(
        (map['x'] as num?)?.toDouble() ?? 0,
        (map['y'] as num?)?.toDouble() ?? 0,
      ),
      radiusInImagePixels: (map['radius'] as num?)?.toDouble() ?? 1,
      hardness: (map['hardness'] as num?)?.toDouble() ?? 0.35,
      strength: (map['strength'] as num?)?.toDouble() ?? 1,
      pressure: (map['pressure'] as num?)?.toDouble() ?? 1,
    );
  }
}

@immutable
class EraserStrokeChunk {
  const EraserStrokeChunk({required this.mode, required this.points});

  final EraserBlendMode mode;
  final List<EraserStrokePoint> points;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mode': mode.name,
      'points': points.map((point) => point.toMap()).toList(growable: false),
    };
  }

  factory EraserStrokeChunk.fromMap(Map<String, dynamic> map) {
    final points = (map['points'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => EraserStrokePoint.fromMap(
            item.map(
              (Object? key, Object? value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);
    return EraserStrokeChunk(
      mode: map['mode']?.toString() == EraserBlendMode.restore.name
          ? EraserBlendMode.restore
          : EraserBlendMode.erase,
      points: points,
    );
  }
}

@immutable
class EraserSessionState {
  const EraserSessionState({
    required this.baseBytes,
    required this.pendingChunks,
    required this.completedStrokes,
  });

  final Uint8List baseBytes;
  final List<EraserStrokeChunk> pendingChunks;
  final int completedStrokes;
}

class EraserController extends ChangeNotifier {
  EraserController({
    this.maxPendingChunks = 8,
    this.maxCheckpointEntries = 12,
    this.checkpointEveryStrokes = 3,
  }) : _history = EditorHistoryService<EraserSessionState>(
         maxEntries: maxCheckpointEntries,
       );

  static const String _brushSizeKey = 'editor_eraser_brush_size_v2';
  static const String _brushHardnessKey = 'editor_eraser_brush_hardness_v2';
  static const String _brushStrengthKey = 'editor_eraser_brush_strength_v2';
  static const String _modeKey = 'editor_eraser_mode_v2';

  final int maxPendingChunks;
  final int maxCheckpointEntries;
  final int checkpointEveryStrokes;
  final EditorHistoryService<EraserSessionState> _history;
  final List<EraserStrokeChunk> _pendingChunks = <EraserStrokeChunk>[];
  final ListQueue<EraserStrokeChunk> _redoChunks =
      ListQueue<EraserStrokeChunk>();

  EraserBrushSettings _settings = const EraserBrushSettings(
    size: 40,
    hardness: 0.35,
    strength: 1,
  );
  EraserBlendMode _mode = EraserBlendMode.erase;
  List<EraserStrokePoint> _activePoints = <EraserStrokePoint>[];
  EraserStrokeChunk? _lastCommittedChunk;
  int _completedStrokes = 0;
  Uint8List? _baseBytes;
  Timer? _persistTimer;

  EraserBrushSettings get settings => _settings;
  EraserBlendMode get mode => _mode;
  List<EraserStrokeChunk> get pendingChunks =>
      List<EraserStrokeChunk>.unmodifiable(_pendingChunks);
  bool get hasPendingChanges => _pendingChunks.isNotEmpty;
  bool get canUndo => _pendingChunks.isNotEmpty || _history.canUndo;
  bool get canRedo => _redoChunks.isNotEmpty || _history.canRedo;
  int get completedStrokes => _completedStrokes;
  bool get hasActiveStroke => _activePoints.isNotEmpty;

  EraserStrokeChunk? get activeStrokeChunk => _activePoints.isEmpty
      ? null
      : EraserStrokeChunk(
          mode: _mode,
          points: List<EraserStrokePoint>.unmodifiable(_activePoints),
        );

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = _settings.copyWith(
      size: (prefs.getDouble(_brushSizeKey) ?? _settings.size).clamp(
        8.0,
        160.0,
      ),
      hardness: (prefs.getDouble(_brushHardnessKey) ?? _settings.hardness)
          .clamp(0.0, 1.0),
      strength: (prefs.getDouble(_brushStrengthKey) ?? _settings.strength)
          .clamp(0.05, 1.0),
    );
    _mode =
        (prefs.getString(_modeKey) ?? EraserBlendMode.erase.name) ==
            EraserBlendMode.restore.name
        ? EraserBlendMode.restore
        : EraserBlendMode.erase;
    notifyListeners();
  }

  void startSession(Uint8List baseBytes) {
    _baseBytes = Uint8List.fromList(baseBytes);
    _pendingChunks.clear();
    _redoChunks.clear();
    _activePoints = <EraserStrokePoint>[];
    _lastCommittedChunk = null;
    _completedStrokes = 0;
    _history.clear();
    notifyListeners();
  }

  Uint8List get baseBytes => _baseBytes ?? Uint8List(0);

  void updateBaseBytes(Uint8List bytes) {
    _baseBytes = Uint8List.fromList(bytes);
    notifyListeners();
  }

  void setMode(EraserBlendMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    _schedulePersist();
    notifyListeners();
  }

  void updateSettings({double? size, double? hardness, double? strength}) {
    _settings = _settings.copyWith(
      size: size?.clamp(8.0, 160.0),
      hardness: hardness?.clamp(0.0, 1.0),
      strength: strength?.clamp(0.05, 1.0),
    );
    _schedulePersist();
    notifyListeners();
  }

  void beginStroke(EraserStrokePoint point) {
    _redoChunks.clear();
    _activePoints = <EraserStrokePoint>[point];
    _lastCommittedChunk = null;
    notifyListeners();
  }

  void appendInterpolatedStroke(EraserStrokePoint nextPoint) {
    if (_activePoints.isEmpty) {
      _activePoints = <EraserStrokePoint>[nextPoint];
      notifyListeners();
      return;
    }
    final previous = _activePoints.last;
    final minRadius =
        previous.radiusInImagePixels < nextPoint.radiusInImagePixels
        ? previous.radiusInImagePixels
        : nextPoint.radiusInImagePixels;
    final spacing = (minRadius * 0.3).clamp(0.75, 8.0);
    final distance = (nextPoint.normalized - previous.normalized).distance;
    final steps = distance == 0 ? 1 : (distance / spacing).ceil().clamp(1, 24);
    for (var index = 1; index <= steps; index++) {
      final t = index / steps;
      _activePoints.add(
        EraserStrokePoint(
          normalized:
              Offset.lerp(previous.normalized, nextPoint.normalized, t) ??
              nextPoint.normalized,
          radiusInImagePixels:
              lerpDouble(
                previous.radiusInImagePixels,
                nextPoint.radiusInImagePixels,
                t,
              ) ??
              nextPoint.radiusInImagePixels,
          hardness:
              lerpDouble(previous.hardness, nextPoint.hardness, t) ??
              nextPoint.hardness,
          strength:
              lerpDouble(previous.strength, nextPoint.strength, t) ??
              nextPoint.strength,
          pressure:
              lerpDouble(previous.pressure, nextPoint.pressure, t) ??
              nextPoint.pressure,
        ),
      );
    }
    notifyListeners();
  }

  bool endStroke() {
    if (_activePoints.length < 2) {
      if (_activePoints.isEmpty) {
        return false;
      }
      _activePoints = <EraserStrokePoint>[..._activePoints, _activePoints.last];
    }
    if (_activePoints.isEmpty) {
      return false;
    }
    final committedChunk = EraserStrokeChunk(
      mode: _mode,
      points: List<EraserStrokePoint>.unmodifiable(_activePoints),
    );
    _pendingChunks.add(committedChunk);
    _lastCommittedChunk = committedChunk;
    _activePoints = <EraserStrokePoint>[];
    _completedStrokes += 1;
    if (checkpointEveryStrokes > 0 &&
        _completedStrokes % checkpointEveryStrokes == 0 &&
        _baseBytes != null) {
      _history.push(
        EraserSessionState(
          baseBytes: Uint8List.fromList(_baseBytes!),
          pendingChunks: List<EraserStrokeChunk>.unmodifiable(_pendingChunks),
          completedStrokes: _completedStrokes,
        ),
      );
    }
    notifyListeners();
    return true;
  }

  void cancelActiveStroke() {
    if (_activePoints.isEmpty) {
      return;
    }
    _activePoints = <EraserStrokePoint>[];
    _lastCommittedChunk = null;
    notifyListeners();
  }

  EraserStrokeChunk? takeLastCommittedChunk() {
    final chunk = _lastCommittedChunk;
    _lastCommittedChunk = null;
    return chunk;
  }

  List<EraserStrokeChunk> chunksForPreview() {
    if (_activePoints.isEmpty) {
      return pendingChunks;
    }
    return <EraserStrokeChunk>[
      ..._pendingChunks,
      EraserStrokeChunk(
        mode: _mode,
        points: List<EraserStrokePoint>.unmodifiable(_activePoints),
      ),
    ];
  }

  List<EraserStrokeChunk> takeChunksForBake({int keepLastChunks = 4}) {
    if (_pendingChunks.length <= keepLastChunks) {
      return const <EraserStrokeChunk>[];
    }
    final splitIndex = _pendingChunks.length - keepLastChunks;
    final chunks = _pendingChunks.sublist(0, splitIndex);
    _pendingChunks.removeRange(0, splitIndex);
    notifyListeners();
    return chunks;
  }

  void resetSession() {
    if (_baseBytes == null) {
      return;
    }
    _pendingChunks.clear();
    _redoChunks.clear();
    _activePoints = <EraserStrokePoint>[];
    _lastCommittedChunk = null;
    _completedStrokes = 0;
    _history.clear();
    notifyListeners();
  }

  void undo() {
    if (_activePoints.isNotEmpty) {
      _activePoints = <EraserStrokePoint>[];
      _lastCommittedChunk = null;
      notifyListeners();
      return;
    }
    if (_pendingChunks.isNotEmpty) {
      _redoChunks.addLast(_pendingChunks.removeLast());
      _lastCommittedChunk = null;
      notifyListeners();
      return;
    }
    final base = _baseBytes;
    if (base == null) {
      return;
    }
    final restored = _history.undo(
      EraserSessionState(
        baseBytes: Uint8List.fromList(base),
        pendingChunks: List<EraserStrokeChunk>.unmodifiable(_pendingChunks),
        completedStrokes: _completedStrokes,
      ),
    );
    if (restored == null) {
      return;
    }
    _baseBytes = Uint8List.fromList(restored.baseBytes);
    _lastCommittedChunk = null;
    _pendingChunks
      ..clear()
      ..addAll(restored.pendingChunks);
    _completedStrokes = restored.completedStrokes;
    notifyListeners();
  }

  void redo() {
    if (_redoChunks.isNotEmpty) {
      _pendingChunks.add(_redoChunks.removeLast());
      _lastCommittedChunk = null;
      notifyListeners();
      return;
    }
    final base = _baseBytes;
    if (base == null) {
      return;
    }
    final redone = _history.redo(
      EraserSessionState(
        baseBytes: Uint8List.fromList(base),
        pendingChunks: List<EraserStrokeChunk>.unmodifiable(_pendingChunks),
        completedStrokes: _completedStrokes,
      ),
    );
    if (redone == null) {
      return;
    }
    _baseBytes = Uint8List.fromList(redone.baseBytes);
    _lastCommittedChunk = null;
    _pendingChunks
      ..clear()
      ..addAll(redone.pendingChunks);
    _completedStrokes = redone.completedStrokes;
    notifyListeners();
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 200), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_brushSizeKey, _settings.size);
      await prefs.setDouble(_brushHardnessKey, _settings.hardness);
      await prefs.setDouble(_brushStrengthKey, _settings.strength);
      await prefs.setString(_modeKey, _mode.name);
    });
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    super.dispose();
  }
}
