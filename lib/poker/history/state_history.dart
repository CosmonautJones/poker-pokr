/// Generic undo/redo state history.
///
/// Pure Dart - no Flutter imports.
library;

class StateHistory<T> {
  final List<T> _states;
  int _currentIndex;

  /// Create a new history seeded with an initial state.
  StateHistory(T initialState)
      : _states = [initialState],
        _currentIndex = 0;

  /// Create a history from an existing list of states positioned at [index].
  StateHistory._fromList(List<T> states, this._currentIndex)
      : _states = states;

  /// The current state.
  T get current => _states[_currentIndex];

  /// All states in the history (unmodifiable).
  List<T> get states => List.unmodifiable(_states);

  /// Push a new state, discarding any future (redo) states.
  void push(T state) {
    // Truncate any states after the current index.
    if (_currentIndex < _states.length - 1) {
      _states.removeRange(_currentIndex + 1, _states.length);
    }
    _states.add(state);
    _currentIndex = _states.length - 1;
  }

  /// Move back one state. Returns the new current state, or `null` if already
  /// at the beginning.
  T? undo() {
    if (!canUndo) return null;
    _currentIndex--;
    return _states[_currentIndex];
  }

  /// Move forward one state. Returns the new current state, or `null` if
  /// already at the end.
  T? redo() {
    if (!canRedo) return null;
    _currentIndex++;
    return _states[_currentIndex];
  }

  /// Whether there is a previous state to undo to.
  bool get canUndo => _currentIndex > 0;

  /// Whether there is a future state to redo to.
  bool get canRedo => _currentIndex < _states.length - 1;

  /// Total number of states in the history.
  int get length => _states.length;

  /// The current position in the history (0-based).
  int get currentIndex => _currentIndex;

  /// Create a new history that is a fork (copy) of this history truncated to
  /// [index].
  ///
  /// The returned history contains states 0..index and is positioned at
  /// [index].
  StateHistory<T> forkAt(int index) {
    if (index < 0 || index >= _states.length) {
      throw RangeError.range(index, 0, _states.length - 1, 'index');
    }
    final forkedStates = List<T>.of(_states.sublist(0, index + 1));
    return StateHistory<T>._fromList(forkedStates, index);
  }

  @override
  String toString() =>
      'StateHistory(length: $length, currentIndex: $_currentIndex)';
}
