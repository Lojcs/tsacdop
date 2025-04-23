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
/// [_selectedEpisodes], [_selectedIndicies], [previouslySelectedEpisodes],
/// [_explicitlySelectedIndicies] and [_explicitlySelectedIndicies] are kept
/// in memory and should be cleared when [selectMode] changes.
///
/// Use [setSelectableEpisodes] to communicate change of [selectableEpisodes].
/// If compatible is false current selection is moved to [previouslySelectedEpisodes].
/// [setSelectableEpisodes] => !compatible ? [previouslySelectedEpisodes] = [selectedEpisodes]
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

  void clearCachedSelectionLists() {
    _selectedIndicies = null;
    _selectedEpisodes = null;
    _previouslySelectedIndicies = null;
  }

  /// Gets all episodes the selection covers so batch selection is not tentative.
  /// Always call before getting selectable episodes.
  Future<void> getEpisodesLimitless() async {
    if (selectionTentative) {
      hasAllSelectableEpisodes = true;
      _selectableEpisodes =
          await onGetEpisodesLimitless?.call() ?? _selectableEpisodes;
      _batchSelectController.selectableCount = _selectableEpisodes.length;
      clearCachedSelectionLists();
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
          clearCachedSelectionLists();
        }
      } else {
        hasAllSelectableEpisodes = false;
        previouslySelectedEpisodes.addAll(selectedEpisodes);
        previouslySelectedEpisodes =
            previouslySelectedEpisodes.toSet().toList();
        _selectableEpisodes = episodes.toList();
        _batchSelectController.selectableCount = _selectableEpisodes.length;
        _batchSelectController.trySetBatchSelect(BatchSelect.none);
        _explicitlySelectedIndicies.clear();
        _explicitlyDeselectedIndicies.clear();
        clearCachedSelectionLists();
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
    for (int i = 0; i < previouslySelectedEpisodes.length; i++) {
      var episode = previouslySelectedEpisodes[i];
      if (episodeMap.containsKey(episode.id)) {
        previouslySelectedEpisodes[i] = episodeMap[episode.id]!;
      }
    }
    clearCachedSelectionLists();
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
      if (boo) temporarySelect = false;
      if (!boo) deselectAll();
      if (!_disposed) notifyListeners();
    }
  }

  /// If set, [selectMode] is turned off after all episodes are deselected.
  bool temporarySelect = false;

  /// List of selected episodes.
  List<EpisodeBrief> get selectedEpisodes {
    _selectedEpisodes ??= [
      ...previouslySelectedEpisodes,
      ...newlySelectedIndicies.map((i) => _selectableEpisodes[i])
    ];
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

  /// Indicies of [previouslySelectedEpisodes] that are on the current [selectableEpisodes].
  List<int> get previouslySelectedIndicies {
    _previouslySelectedIndicies ??=
        _previouslySelectedEpisodesToIndicies.toList();
    return _previouslySelectedIndicies!;
  }

  List<int>? _previouslySelectedIndicies;

  Iterable<int> get _previouslySelectedEpisodesToIndicies sync* {
    int? smallest;
    int? largest;
    for (EpisodeBrief episode in previouslySelectedEpisodes) {
      int i = selectableEpisodes.indexOf(episode);
      if (smallest != null && i < smallest) {
        smallest = i;
      } else if (largest != null && i > largest) {
        largest = i;
      }
      if (i != -1) yield i;
    }
    _batchSelectController.potentialDelimiter(smallest);
    _batchSelectController.potentialDelimiter(largest);
  }

  /// Episodes previously selected before [_selectableEpisodes] changed.
  /// Cleared on [selectMode] off.
  List<EpisodeBrief> previouslySelectedEpisodes = [];

  /// Tentative list of indicies of selected selectable episodes that weren't
  /// selected previously (thus newly selected)
  Iterable<int> get newlySelectedIndicies => batchSelect == BatchSelect.none
      ? _explicitlySelectedIndicies
      : batchSelectedIndicies;

  /// Indicies selected by batch select, except the ones explicitly deselected.
  Iterable<int> get batchSelectedIndicies sync* {
    for (int i in implicitlySelectedIndicies) {
      if (!_explicitlyDeselectedIndicies.contains(i)) yield i;
    }
  }

  /// Current batch selection mode. Setting same value toggles it with none.
  BatchSelect get batchSelect => _batchSelectController.batchSelect;
  late final _BatchSelectController _batchSelectController =
      _BatchSelectController(
    setIndividualSelection: (explicitlySelected) {
      _explicitlyDeselectedIndicies.clear();
      _explicitlySelectedIndicies.clear();
      _explicitlySelectedIndicies.addAll(explicitlySelected);
    },
    clearIndividualSelection: () {
      _explicitlySelectedIndicies.clear();
      previouslySelectedEpisodes
          .removeWhere((e) => selectableEpisodes.contains(e));
    },
  );
  set batchSelect(BatchSelect select) {
    if (select == batchSelect) {
      if (select == BatchSelect.all) {
        temporarySelect = false;
      }
      select = BatchSelect.none;
    }
    _batchSelectController.trySetBatchSelect(select);
    clearCachedSelectionLists();
    if (!_disposed && selectMode) notifyListeners();
  }

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
      if (previouslySelectedEpisodes.remove(selectableEpisodes[index])) {
        clearCachedSelectionLists();
      }
      yield index;
    }
  }

  /// Inverts the selection of [i]th selectable episode
  /// or changes the delimiters of batch selection
  bool select(int i) {
    if (i >= 0 && i < _selectableEpisodes.length) {
      if (batchSelect == BatchSelect.none) {
        // Batch select is disabled, deselect if index was explicitly selected.
        bool wasSelected = _explicitlySelectedIndicies.remove(i);
        if (!wasSelected) {
          // Index wasn't explicitly selected. Check if it was previously selected
          wasSelected = previouslySelectedIndicies.contains(i);
          if (wasSelected) {
            // It was previously selected, deselect.
            previouslySelectedEpisodes.remove(selectableEpisodes[i]);
          }
        }
        if (wasSelected) {
          // Index was selected and got deselected. Update batch select
          // delimiters if it was one of them.
          if (_explicitlySelectedIndicies.isEmpty) {
            // No episode selected, clear delimiters
            _batchSelectController.replaceDelimiter(
                _BatchSelectDelimiter.both, null);
          } else {
            _BatchSelectDelimiter delimiter =
                _batchSelectController.isDelimiter(i);
            // Find the next explicitly selected index to be the delimiter.
            _batchSelectController.replaceDelimiter(
                delimiter,
                _explicitlySelectedIndicies.reduce((a, b) =>
                    (a < b) ^ (delimiter == _BatchSelectDelimiter.first)
                        ? b
                        : a));
          }
        } else {
          // Index wasn't selected, select.
          _explicitlySelectedIndicies.add(i);
          _batchSelectController.potentialDelimiter(i);
        }
      } else {
        // Batch select enabled. Try to set index as new delimiter.
        bool setAsDelimiter = _batchSelectController.potentialDelimiter(i);
        if (!setAsDelimiter) {
          // Index isn't set as delimiter, so it's either already a delimeter
          // or will explicitly deselect
          _BatchSelectDelimiter delimiter =
              _batchSelectController.isDelimiter(i);
          if (delimiter == _BatchSelectDelimiter.none) {
            // ındex isn't a delimiter, toggle explicit deselection.
            if (!_explicitlyDeselectedIndicies.remove(i)) {
              _explicitlyDeselectedIndicies.add(i);
            }
          } else if (selectedIndicies.length == 1) {
            // No episode selected, clear delimiters
            _batchSelectController.replaceDelimiter(
                _BatchSelectDelimiter.both, null);
          } else {
            // Index is a delimeter, set next non explicitly deselected index as the
            // delimiter and remove explicit deselection of the indicies in between
            do {
              if (delimiter == _BatchSelectDelimiter.first ||
                  batchSelect == BatchSelect.after) {
                i++;
              } else {
                i--;
              }
            } while (_explicitlyDeselectedIndicies.remove(i));
            _batchSelectController.replaceDelimiter(delimiter, i);
          }
        }
      }
      clearCachedSelectionLists();
      if (temporarySelect && selectedEpisodes.isEmpty) selectMode = false;
      if (!_disposed) notifyListeners();
    }
    if (selectedIndicies.contains(i)) {
      return true;
    } else {
      return false;
    }
  }

  /// Deselects all episodes
  void deselectAll() {
    _batchSelectController.trySetBatchSelect(BatchSelect.all);
    _batchSelectController.trySetBatchSelect(BatchSelect.none);
    _explicitlyDeselectedIndicies.clear();
    _explicitlySelectedIndicies.clear();
    previouslySelectedEpisodes.clear();
    clearCachedSelectionLists();
    if (!_disposed && selectMode) notifyListeners();
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
enum _BatchSelectDelimiter { first, last, both, none }

/// Wraps [BatchSelect] and batch selection delimiters.
class _BatchSelectController {
  final void Function(List<int> explicitlySelected) setIndividualSelection;
  final void Function() clearIndividualSelection;
  _BatchSelectController(
      {required this.setIndividualSelection,
      required this.clearIndividualSelection});

  BatchSelect get batchSelect => _batchSelect;
  BatchSelect _batchSelect = BatchSelect.none;

  int selectableCount = 0;
  int? _firstSelected;
  int? _lastSelected;
  bool firstBeforeLast = true;
  List<int> get individualSelectionFromDelimiters => switch (_batchSelect) {
        BatchSelect.all => [],
        BatchSelect.after => [_firstSelected!],
        BatchSelect.before => [_lastSelected!],
        BatchSelect.between => firstBeforeLast
            ? [_firstSelected!, _lastSelected!]
            : [_lastSelected!, _firstSelected!],
        BatchSelect.none => [],
      };

  /// Wheter batch select can be set to [select].
  bool canSetBatchSelect(BatchSelect select) => switch (select) {
        BatchSelect.all => true,
        BatchSelect.after => _firstSelected != null,
        BatchSelect.before => _lastSelected != null,
        BatchSelect.between =>
          _firstSelected != null && _firstSelected != _lastSelected,
        BatchSelect.none => true,
      };

  /// Sets batch select to [select] if it can be set to it.
  void trySetBatchSelect(BatchSelect select) {
    if (canSetBatchSelect(select)) {
      if (select != BatchSelect.none && _batchSelect == BatchSelect.none) {
        clearIndividualSelection();
      } else if (select == BatchSelect.none &&
          _batchSelect != BatchSelect.none) {
        setIndividualSelection(individualSelectionFromDelimiters);
      }
      switch (select) {
        case BatchSelect.all:
          _firstSelected = null;
          _lastSelected = null;
          break;
        case BatchSelect.after:
          _lastSelected = _firstSelected;
          break;
        case BatchSelect.before:
          _firstSelected = _lastSelected;
          break;
        case BatchSelect.between:
        case BatchSelect.none:
      }
      _batchSelect = select;
    }
  }

  /// Updates a delimiter with [i] if it would expand selection and returns whether successful.
  bool potentialDelimiter(int? i) {
    if (i == null) return false;
    bool result = false;
    if (_firstSelected == null) {
      if (_batchSelect != BatchSelect.all) {
        _firstSelected = i;
        _lastSelected = i;
        result = true;
      }
    } else {
      switch (_batchSelect) {
        case BatchSelect.all:
          break;
        case BatchSelect.after:
          if (i < _firstSelected!) {
            _firstSelected = i;
            _lastSelected = i;
            result = true;
          }
        case BatchSelect.before:
          if (i > _lastSelected!) {
            _lastSelected = i;
            _firstSelected = i;
            result = true;
          }
        case BatchSelect.between:
        case BatchSelect.none:
          if (i < _firstSelected!) {
            _firstSelected = i;
            firstBeforeLast = true;
            result = true;
          } else if (i > _lastSelected!) {
            _lastSelected = i;
            firstBeforeLast = false;
            result = true;
          }
      }
    }
    return result;
  }

  /// Returns delimiter type if [i] is a delimiter or null otherwise
  _BatchSelectDelimiter isDelimiter(int i) {
    if (_firstSelected == i) {
      if (_lastSelected == i) {
        return _BatchSelectDelimiter.both;
      } else {
        return _BatchSelectDelimiter.first;
      }
    } else if (_lastSelected == i) {
      return _BatchSelectDelimiter.last;
    } else {
      return _BatchSelectDelimiter.none;
    }
  }

  /// Replaces [delimiter] with [i].
  void replaceDelimiter(_BatchSelectDelimiter delimiter, int? i) {
    switch (delimiter) {
      case _BatchSelectDelimiter.first:
        _firstSelected = i;
        break;
      case _BatchSelectDelimiter.last:
        _lastSelected = i;
        break;
      case _BatchSelectDelimiter.both:
        _firstSelected = i;
        _lastSelected = i;
        break;
      case _BatchSelectDelimiter.none:
        break;
    }
    if (_firstSelected == null || _lastSelected == null) {
      _batchSelect = BatchSelect.none;
    } else if (_firstSelected == _lastSelected &&
        _batchSelect == BatchSelect.between) {
      setIndividualSelection([_lastSelected!]);
      _batchSelect = BatchSelect.none;
    }
  }

  /// Iterable of batch selected episodes.
  Iterable<int> selection() =>
      _batchSelect.selection(selectableCount, _firstSelected, _lastSelected);
}
