import 'dart:collection';

class EditorHistoryService<T> {
  EditorHistoryService({this.maxEntries = 20});

  final int maxEntries;
  final ListQueue<T> _undo = ListQueue<T>();
  final ListQueue<T> _redo = ListQueue<T>();

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(T entry) {
    _undo.addLast(entry);
    _redo.clear();
    while (_undo.length > maxEntries) {
      _undo.removeFirst();
    }
  }

  T? undo(T current) {
    if (_undo.isEmpty) {
      return null;
    }
    final previous = _undo.removeLast();
    _redo.addLast(current);
    while (_redo.length > maxEntries) {
      _redo.removeFirst();
    }
    return previous;
  }

  T? redo(T current) {
    if (_redo.isEmpty) {
      return null;
    }
    final next = _redo.removeLast();
    _undo.addLast(current);
    while (_undo.length > maxEntries) {
      _undo.removeFirst();
    }
    return next;
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
