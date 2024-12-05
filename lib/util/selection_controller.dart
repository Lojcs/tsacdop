import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import '../type/episodebrief.dart';

/// Coordinates the selection behavior of [EpisodeGrid] and [MultiSelectMenuBar].
class SelectionController extends ChangeNotifier {
  /// Called when the list of all applicable episdoes without limits is needed.
  /// It is assumed that the beginning of the return is the same as last [setSelectableEpisodes].
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

  Future getEpisodesLimitless() async {
    if (!hasAllSelectableEpisodes) {
      hasAllSelectableEpisodes = true;
      _selectableEpisodes =
          await onGetEpisodesLimitless?.call() ?? _selectableEpisodes;
      _selectionChanged();
    }
  }

  /// Wheter [getEpisodesLimitless] was called since last [setSelectableEpisodes] set.
  bool hasAllSelectableEpisodes = false;

  List<EpisodeBrief> get selectableEpisodes => _selectableEpisodes;
  List<EpisodeBrief> _selectableEpisodes = [];

  /// List of selectable episodes.
  /// Set [compatible] if this list is same as the previous one or with new episodes appended.
  /// Otherwise this might not include previously selected episodes no longer in view.
  void setSelectableEpisodes(List<EpisodeBrief> episodes,
      {bool compatible = false}) {
    for (int i = 0; i < episodes.length; i++) {}
    if (episodes != _selectableEpisodes) {
      if (compatible) {
        _selectableEpisodes =
            episodes.toList(); // Prevent spooky action at a distance
      } else {
        _previouslySelectedEpisodes.addAll(newlySelectedEpisodes);
        _selectAll = false;
        _selectBefore = null;
        _selectAfter = null;
        _selectBetween = null;
        hasAllSelectableEpisodes = false;
        _selectableEpisodes = episodes.toList();
        _explicitlySelectedIndicies.clear();
        for (int i = 0; i < _selectableEpisodes.length; i++) {
          var episode = _selectableEpisodes[i];
          if (_previouslySelectedEpisodes.contains(episode)) {
            _explicitlySelectedIndicies.add(i);
          }
        }
      }
      _selectionChanged();
    }
  }

// Flips to indicate that episodes were updated.
// Listeners aren't notified since the update most likely originates from a FutureBuilder
// and its children can just check it when rebuilding.
  bool episodesUpdated = false;

  /// Replaces stored episodes with the provided versions.
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
    _newlySelectedEpisodes = null;
    _selectedEpisodes = null;
    episodesUpdated = !episodesUpdated;
  }

  /// List of explicitly selected selectable episodes ordered in select order.
  final List<int> _explicitlySelectedIndicies = [];

  /// Number of explicitly selected indicies for limiting batch selection options.
  int get explicitlySelectedCount => _explicitlySelectedIndicies.length;

  /// Tentative set of indicies of selected selectable episodes.
  Set<int> get selectedIndicies {
    if (_selectedIndicies == null) {
      _selectedIndicies = {};
      if (selectAll) {
        _selectedIndicies!
            .addAll([for (int i = 0; i < _selectableEpisodes.length; i++) i]);
      } else {
        for (int i = 0; i < _selectableEpisodes.length; i++) {
          if ((selectBefore && i <= _selectBefore!) ||
              (selectAfter && i >= _selectAfter!) ||
              (selectBetween &&
                  i >= _selectBetween![0] &&
                  i <= _selectBetween![1]) ||
              _explicitlySelectedIndicies.contains(i) ||
              _previouslySelectedEpisodes.contains(_selectableEpisodes[i])) {
            _selectedIndicies!.add(i);
          }
        }
      }
    }
    return _selectedIndicies!;
  }

  Set<int>? _selectedIndicies;

  /// Tentative list of indicies of newly selected selectable episodes.
  List<int> get newlySelectedIndicies {
    if (_newlySelectedIndicies == null) {
      _newlySelectedIndicies = [];
      if (selectAll) {
        for (int i = 0; i < _selectableEpisodes.length; i++) {
          if (!_previouslySelectedEpisodes.contains(_selectableEpisodes[i])) {
            _newlySelectedIndicies!.add(i);
          }
        }
      } else {
        if (selectBefore || selectAfter || selectBetween) {
          // Ignore selection order if bulk selecting
          for (int i = 0; i < _selectableEpisodes.length; i++) {
            if ((selectBefore && i <= _selectBefore!) ||
                (selectAfter && i >= _selectAfter!) ||
                (selectBetween &&
                    i >= _selectBetween![0] &&
                    i <= _selectBetween![1]) ||
                _explicitlySelectedIndicies.contains(i)) {
              var episode = _selectableEpisodes[i];
              if (!_previouslySelectedEpisodes.contains(episode)) {
                _newlySelectedIndicies!.add(i);
              }
            }
          }
        } else {
          for (var index in _explicitlySelectedIndicies) {
            var episode = _selectableEpisodes[index];
            if (!_previouslySelectedEpisodes.contains(episode)) {
              _newlySelectedIndicies!.add(index);
            }
          }
        }
      }
    }
    return _newlySelectedIndicies!;
  }

  List<int>? _newlySelectedIndicies;

  /// Tentative list of newly selected episodes from [_selectableEpisodes].
  List<EpisodeBrief> get newlySelectedEpisodes {
    if (_newlySelectedEpisodes == null) {
      _newlySelectedEpisodes = [];
      _newlySelectedEpisodes =
          newlySelectedIndicies.map((i) => _selectableEpisodes[i]).toList();
    }
    return _newlySelectedEpisodes!;
  }

  List<EpisodeBrief>? _newlySelectedEpisodes;

  /// Episodes previously selected before [_selectableEpisodes] changed.
  /// Cleared on [selectMode] off.
  final List<EpisodeBrief> _previouslySelectedEpisodes = [];

  /// Tentative list of selected episodes.
  /// Includes episodes from [_selectableEpisodes] and previously selected episooes.
  List<EpisodeBrief> get selectedEpisodes {
    if (_selectedEpisodes == null) {
      _selectedEpisodes = [];
      _selectedEpisodes!.addAll(_previouslySelectedEpisodes);
      _selectedEpisodes!.addAll(newlySelectedEpisodes);
    }
    return _selectedEpisodes!;
  }

  List<EpisodeBrief>? _selectedEpisodes;

  /// [getEpisodesLimitless] is only called when getting [allSelectedEpisodes].
  /// Otherwise the selection is tentative if [selectAll] or [selectAfter] is used.
  bool get selectionTentative =>
      !hasAllSelectableEpisodes && (selectAll || selectAfter);

  /// Wheter selection mode is enabled.
  bool get selectMode => _selectMode;
  bool _selectMode = false;
  set selectMode(bool boo) {
    if (_selectMode != boo) {
      _selectMode = boo;
      notifyListeners();
      if (!boo) {
        _previouslySelectedEpisodes.clear();
        _explicitlySelectedIndicies.clear();
        selectAll = false;
        _selectBefore = null;
        _selectAfter = null;
        _selectBetween = null;
        _selectionChanged();
      }
    }
  }

  /// Selects all selectable episodes
  bool get selectAll => _selectAll;
  bool _selectAll = false;
  set selectAll(bool boo) {
    _selectAll = boo;
    _selectionChanged();
  }

  /// Selects all selectable episodes before the first one selected
  bool get selectBefore => _selectBefore != null;
  int? _selectBefore;
  set selectBefore(bool boo) {
    if (boo) {
      _selectBefore = _explicitlySelectedIndicies
          .reduce((value, element) => math.min(value, element));
    } else {
      _selectBefore = null;
    }
    _selectionChanged();
  }

  /// Selects all selectable episodes after the last one selected
  bool get selectAfter => _selectAfter != null;
  int? _selectAfter;
  set selectAfter(bool boo) {
    if (boo) {
      _selectAfter = _explicitlySelectedIndicies
          .reduce((value, element) => math.max(value, element));
    } else {
      _selectAfter = null;
    }
    _selectionChanged();
  }

  /// Selects all selectable episodes between all the ones selected
  bool get selectBetween => _selectBetween != null;
  List<int>? _selectBetween;
  set selectBetween(bool boo) {
    if (boo) {
      _selectBetween = [
        _explicitlySelectedIndicies
            .reduce((value, element) => math.min(value, element)),
        _explicitlySelectedIndicies
            .reduce((value, element) => math.max(value, element))
      ];
    } else {
      _selectBetween = null;
    }
    _selectionChanged();
  }

  /// Marks [i]th selectable episode with [selected]
  void select(int i) {
    if (i >= 0 && i < _selectableEpisodes.length) {
      if (_explicitlySelectedIndicies.contains(i)) {
        _previouslySelectedEpisodes.remove(_selectableEpisodes[i]);
        _explicitlySelectedIndicies.remove(i);
        if (selectBefore && i == _selectBefore!) {
          if (_explicitlySelectedIndicies.isEmpty) {
            _selectBefore = null;
          } else {
            _selectBefore = _explicitlySelectedIndicies
                .reduce((value, element) => math.min(value, element));
          }
        }
        if (selectAfter && i == _selectAfter!) {
          if (_explicitlySelectedIndicies.isEmpty) {
            _selectAfter = null;
          } else {
            _selectAfter = _explicitlySelectedIndicies
                .reduce((value, element) => math.max(value, element));
          }
        }
        if (selectBetween) {
          if (_explicitlySelectedIndicies.length == 1) {
            _selectBetween = null;
          } else {
            if (i == _selectBetween![0]) {
              _selectBetween![0] = _explicitlySelectedIndicies
                  .reduce((value, element) => math.min(value, element));
            } else if (i == _selectBetween![1]) {
              _selectBetween![1] = _explicitlySelectedIndicies
                  .reduce((value, element) => math.max(value, element));
            }
          }
        }
      } else {
        _explicitlySelectedIndicies.add(i);
        if (selectBefore && i < _selectBefore!) {
          _selectBefore = i;
        }
        if (selectAfter && i > _selectAfter!) {
          _selectAfter = i;
        }
        if (selectBetween) {
          if (i < _selectBetween![0]) {
            _selectBetween![0] = i;
          } else if (i > _selectBetween![1]) {
            _selectBetween![1] = i;
          }
        }
      }

      _selectionChanged();
    }
  }

  void _selectionChanged() {
    _selectedIndicies = null;
    _newlySelectedIndicies = null;
    _newlySelectedEpisodes = null;
    _selectedEpisodes = null;
    if (!_disposed && selectMode) notifyListeners();
  }
}
