import 'package:flutter/widgets.dart';

import '../type/episodebrief.dart';

/// Coordinates the selection behavior of [EpisodeGrid] and [MultiSelectPanel].
///
/// [selectedEpisodes] is the list of episodes that are selected. Its subsets are:
///
/// [selectedIndicies] = [previouslySelectedIndicies] + [newlySelectedIndicies]
/// [newlySelectedIndicies] = [batchSelectedIndicies] ?? [_explicitlySelectedIndicies]
/// [batchSelectedIndicies] = [implicitlySelectedIndicies] - [_explicitlyDeselectedIndicies]
///
/// [_selectedEpisodes], [_selectedIndicies], [_previouslySelectedEpisodes],
/// [_explicitlySelectedIndicies] and [_explicitlySelectedIndicies] are kept
/// in memory and should be cleared when [selectMode] changes.
///
/// Use [setSelectableEpisodes] to communicate change of [selectableEpisodes].
/// If compatible is false current selection is moved to [_previouslySelectedEpisodes].
/// [setSelectableEpisodes] => !compatible ? [_previouslySelectedEpisodes] = [selectedEpisodes]
///
/// Selection lists are generally sorted in the order episodes were selected.
/// If batch selection options are used [_explicitlySelectedIndicies] is cleared.
/// Sorting of [newlySelectedIndicies] is then based on their order on [selectableEpisodes].
///
/// [batchSelectedIndicies] selected due [after] or [all] are tentative
/// unless [getEpisodesLimitless] has been called since the last incomatible
/// [selectableEpisodes] change.
///
/// Only one batch selection option can be enabled at once. More simpler selections
/// can be activated after more complex ones but not vice versa. Complexity hierarchy:
///
/// explicitlySelected(>=2) > [between] > explicitlySelected(2)
/// explicitlySelected(>=1) > [after] = [before] > explicitlySelected(1)
/// explicitlySelected > [all] > noneSelected
///
class SelectionController extends ChangeNotifier {
  /// Called when the list of all applicable episdoes without limits is needed.
  /// It is assumed that the beginning of the list is the same as
  /// the list set by [setSelectableEpisodes].
  ValueGetter<Future<List<EpisodeBrief>>>? onGetEpisodesLimitless;

  SelectionController({
    this.onGetEpisodesLimitless,
  });

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Gets all episodes the selection covers so batch selection is not tentative.
  /// Always call before getting selectable episodes.
  Future<void> getEpisodesLimitless() async {
    if (selectionTentative) {
      hasAllSelectableEpisodes = true;
      _selectableEpisodes =
          await onGetEpisodesLimitless?.call() ?? _selectableEpisodes;
      _batchSelectController.selectableCount = _selectableEpisodes.length;
      _selectedIndicies = null;
      _selectedEpisodes = null;
      if (!_disposed && selectMode) notifyListeners();
    }
  }

  /// Wheter [getEpisodesLimitless] was called since last [setSelectableEpisodes] set.
  bool hasAllSelectableEpisodes = false;

  /// List of selectable episodes
  List<EpisodeBrief> get selectableEpisodes => _selectableEpisodes;
  List<EpisodeBrief> _selectableEpisodes = [];

  /// List of selectable episodes.
  /// Set [compatible] if the beginning of the list is the same as the previously set list.
  void setSelectableEpisodes(List<EpisodeBrief> episodes,
      {bool compatible = false}) {
    if (episodes != _selectableEpisodes) {
      if (compatible) {
        if (!hasAllSelectableEpisodes) {
          _selectableEpisodes =
              episodes.toList(); // Prevent spooky action at a distance
          _batchSelectController.selectableCount = _selectableEpisodes.length;
          _selectedIndicies = null;
          _selectedEpisodes = null;
        }
      } else {
        hasAllSelectableEpisodes = false;
        _previouslySelectedEpisodes = selectedEpisodes;
        _selectableEpisodes = episodes.toList();
        _batchSelectController.selectableCount = _selectableEpisodes.length;
        _batchSelectController.trySetBatchSelect(BatchSelect.none);
        _explicitlySelectedIndicies.clear();
        _explicitlyDeselectedIndicies.clear();
        _selectedIndicies = null;
        _selectedEpisodes = null;
      }
      if (!_disposed && selectMode) notifyListeners();
    }
  }

  /// Flips to indicate that episodes were updated.
  bool episodesUpdated = false;

  /// Replaces stored episodes with the provided versions and notifies listeners.
  void updateEpisodes(List<EpisodeBrief> episodes) {
    Map<int, EpisodeBrief> episodeMap = {
      for (var episode in episodes) episode.id: episode
    };
    for (int i = 0; i < selectableEpisodes.length; i++) {
      var episode = selectableEpisodes[i];
      if (episodeMap.containsKey(episode.id)) {
        selectableEpisodes[i] = episodeMap[episode.id]!;
      }
    }
    for (int i = 0; i < _previouslySelectedEpisodes.length; i++) {
      var episode = _previouslySelectedEpisodes[i];
      if (episodeMap.containsKey(episode.id)) {
        _previouslySelectedEpisodes[i] = episodeMap[episode.id]!;
      }
    }
    _selectedIndicies = null;
    _selectedEpisodes = null;
    episodesUpdated = !episodesUpdated;
    if (!_disposed && selectMode) notifyListeners();
  }

  /// Wheter the selection lists include all episodes implicitly selected by
  /// batch select options
  bool get selectionTentative =>
      !hasAllSelectableEpisodes &&
      _batchSelectController.batchSelect.selectsTentatively;

  /// Wheter selection mode is enabled.
  bool get selectMode => _selectMode;
  bool _selectMode = false;
  set selectMode(bool boo) {
    if (_selectMode != boo) {
      _selectMode = boo;
      if (!boo) deselectAll();
      if (!_disposed && selectMode) notifyListeners();
    }
  }

  /// List of selected episodes.
  List<EpisodeBrief> get selectedEpisodes {
    _selectedEpisodes ??=
        selectedIndicies.map((i) => _selectableEpisodes[i]).toList();
    return _selectedEpisodes!;
  }

  List<EpisodeBrief>? _selectedEpisodes;

  /// List of selected indicies
  List<int> get selectedIndicies {
    _selectedIndicies ??= [
      ...previouslySelectedIndicies,
      ...newlySelectedIndicies
    ];
    return _selectedIndicies!;
  }

  List<int>? _selectedIndicies;

  /// Indicies of [_previouslySelectedEpisodes] that are on the current [selectableEpisodes].
  Iterable<int> get previouslySelectedIndicies => _previouslySelectedEpisodes
      .map<int?>((e) => selectableEpisodes.indexOf(e))
      .nonNulls;

  /// Episodes previously selected before [_selectableEpisodes] changed.
  /// Cleared on [selectMode] off.
  List<EpisodeBrief> _previouslySelectedEpisodes = [];

  /// Tentative list of indicies of selected selectable episodes that weren't
  /// selected previously (thus newly selected)
  Iterable<int> get newlySelectedIndicies => batchSelectedIndicies.isNotEmpty
      ? batchSelectedIndicies
      : _explicitlySelectedIndicies;

  /// Indicies selected by batch select, except the ones explicitly deselected.
  Iterable<int> get batchSelectedIndicies => implicitlySelectedIndicies
      .takeWhile((i) => !_explicitlyDeselectedIndicies.contains(i));

  /// Current batch selection mode.
  BatchSelect get batchSelect => _batchSelectController._batchSelect;
  late final _BatchSelectController _batchSelectController =
      _BatchSelectController(
    setExplicitSelection: (explicitlySelected) {
      _explicitlyDeselectedIndicies.clear();
      _explicitlySelectedIndicies.clear();
      _explicitlySelectedIndicies.addAll(explicitlySelected);
    },
    clearExplicitSelection: () => _explicitlySelectedIndicies.clear(),
  );
  set batchSelect(BatchSelect select) =>
      _batchSelectController.trySetBatchSelect(select);

  /// Wheter batch select can be set to [select].
  bool canSetBatchSelect(BatchSelect select) =>
      _batchSelectController.canSetBatchSelect(select);

  /// List of explicitly selected selectable episodes ordered in select order.
  final List<int> _explicitlySelectedIndicies = [];

  /// Number of explicitly selected indicies for limiting batch selection options.
  int get explicitlySelectedCount => _explicitlySelectedIndicies.length;

  /// Set of episode indicies that would be selected due to batch select
  /// but were explicitly deselected.
  final Set<int> _explicitlyDeselectedIndicies = {};

  /// Indicies implicitly selected by batch selection. Overrides previous selection status.
  Iterable<int> get implicitlySelectedIndicies sync* {
    for (int index in _batchSelectController.selection()) {
      if (_previouslySelectedEpisodes.remove(selectableEpisodes[index])) {
        _selectedIndicies = null;
        _selectedEpisodes = null;
      }
      yield index;
    }
  }

  /// Inverts the selection of [i]th selectable episode
  /// or changes the delimiters of batch selection
  void select(int i) {
    if (i >= 0 && i < _selectableEpisodes.length) {
      if (batchSelect == BatchSelect.none) {
        if (!_explicitlySelectedIndicies.remove(i)) {
          _explicitlySelectedIndicies.add(i);
        }
      } else {
        bool setAsDelimiter = _batchSelectController.potentialDelimiter(i);
        if (!setAsDelimiter) {
          _BatchSelectDelimiter? delimiter =
              _batchSelectController.isDelimiter(i);
          if (delimiter != null) {
            while (_explicitlyDeselectedIndicies.remove(i)) {
              i++;
            }
            _batchSelectController.replaceDelimiter(
                delimiter,
                _explicitlyDeselectedIndicies.reduce((a, b) =>
                    (a < b) ^ (delimiter == _BatchSelectDelimiter.first)
                        ? b
                        : a));
          } else if (!_explicitlyDeselectedIndicies.remove(i)) {
            _explicitlyDeselectedIndicies.add(i);
          }
        }
      }
      _selectedIndicies = null;
      _selectedEpisodes = null;
    }
  }

  /// Deselects all episodes
  void deselectAll() {
    _batchSelectController.trySetBatchSelect(BatchSelect.none);
    _explicitlyDeselectedIndicies.clear();
    _explicitlySelectedIndicies.clear();
    _previouslySelectedEpisodes.clear();
    _selectedIndicies = null;
    _selectedEpisodes = null;
  }
}

/// Options for batch selection
enum BatchSelect {
  /// Select all selectable
  all(selection: _selectAll, selectsTentatively: true),

  /// Select all after first selected (inclusive)
  after(selection: _selectAfter, selectsTentatively: true),

  /// Select all until last selected (inclusive)
  before(selection: _selectBefore, selectsTentatively: false),

  /// Select all between first selected and last selected (inclusive)
  between(selection: _selectBetween, selectsTentatively: false),

  /// Don't batch select
  none(selection: _selectNone, selectsTentatively: false);

  const BatchSelect(
      {required this.selection, required this.selectsTentatively});

  /// Iterable of batch selected episodes.
  final Iterable<int> Function(
      int? selectableCount, int? firstSelected, int? lastSelected) selection;
  final bool selectsTentatively;

  static Iterable<int> _selectAll(int? selectableCount, int? _, int? __) =>
      Iterable<int>.generate(selectableCount!);
  static Iterable<int> _selectAfter(
          int? selectableCount, int? firstSelected, int? _) =>
      Iterable<int>.generate(
          selectableCount! - firstSelected!, (i) => firstSelected + i);
  static Iterable<int> _selectBefore(int? _, int? __, int? lastSelected) =>
      Iterable<int>.generate(lastSelected! + 1);
  static Iterable<int> _selectBetween(
          int? _, int? firstSelected, int? lastSelected) =>
      Iterable<int>.generate(
          (lastSelected! - firstSelected! + 1), (i) => firstSelected + i);
  static Iterable<int> _selectNone(int? _, int? __, int? ___) =>
      Iterable<int>.empty();
}

/// Delimiter type for batch select
enum _BatchSelectDelimiter { first, last }

/// Wraps [BatchSelect] and batch selection delimiters.
class _BatchSelectController {
  final void Function(List<int> explicitlySelected) setExplicitSelection;
  final void Function() clearExplicitSelection;
  _BatchSelectController(
      {required this.setExplicitSelection,
      required this.clearExplicitSelection});

  BatchSelect get batchSelect => _batchSelect;
  BatchSelect _batchSelect = BatchSelect.none;

  int selectableCount = 0;
  int? _firstSelected;
  int? _lastSelected;
  bool firstBeforeLast = true;
  List<int> get selectionOrderedDelimiters => _firstSelected != null
      ? _lastSelected != null
          ? firstBeforeLast
              ? [_firstSelected!, _lastSelected!]
              : [_lastSelected!, _firstSelected!]
          : [_firstSelected!]
      : _lastSelected != null
          ? [_lastSelected!]
          : [];

  /// Wheter batch select can be set to [select].
  bool canSetBatchSelect(BatchSelect select) {
    switch (select) {
      case BatchSelect.all:
        return true;
      case BatchSelect.after:
        return _firstSelected != null;
      case BatchSelect.before:
        return _lastSelected != null;
      case BatchSelect.between:
        return _firstSelected != null && _lastSelected != null;
      case BatchSelect.none:
        return true;
    }
  }

  /// Sets batch select to [select] if it can be set to it.
  void trySetBatchSelect(BatchSelect select) {
    if (select != BatchSelect.none && _batchSelect == BatchSelect.none) {
      setExplicitSelection([]);
    } else if (select == BatchSelect.none && _batchSelect != BatchSelect.none) {
      clearExplicitSelection();
    } else {
      if (canSetBatchSelect(select)) _batchSelect = select;
    }
  }

  /// Updates a delimiter with [i] if it would expand selection and returns whether successful.
  bool potentialDelimiter(int i) {
    if (_firstSelected != null) {
      if (i < _firstSelected!) {
        _firstSelected = i;
        firstBeforeLast = true;
        return true;
      }
    }
    if (_lastSelected != null) {
      if (i > _lastSelected!) {
        _lastSelected = i;
        firstBeforeLast = false;
        return true;
      }
    }
    return false;
  }

  /// Returns delimiter type if [i] is a delimiter or null otherwise
  _BatchSelectDelimiter? isDelimiter(int i) {
    if (_firstSelected == i) {
      return _BatchSelectDelimiter.first;
    } else if (_lastSelected == i) {
      return _BatchSelectDelimiter.last;
    } else {
      return null;
    }
  }

  /// Replaces [delimiter] with [i].
  void replaceDelimiter(_BatchSelectDelimiter delimiter, int i) {
    switch (delimiter) {
      case _BatchSelectDelimiter.first:
        _firstSelected = i;
      case _BatchSelectDelimiter.last:
        _lastSelected = i;
    }
  }

  /// Iterable of batch selected episodes.
  Iterable<int> selection() =>
      _batchSelect.selection(selectableCount, _firstSelected, _lastSelected);
}
