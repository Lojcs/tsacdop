import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tuple/tuple.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../type/episodebrief.dart';
import '../type/play_histroy.dart';
import '../type/playlist.dart';
import 'episode_state.dart';

const MediaControl playControl = MediaControl(
  androidIcon: 'drawable/ic_stat_play_circle_filled',
  label: 'Play',
  action: MediaAction.play,
);
const MediaControl pauseControl = MediaControl(
  androidIcon: 'drawable/ic_stat_pause_circle_filled',
  label: 'Pause',
  action: MediaAction.pause,
);
const MediaControl skipToNextControl = MediaControl(
  androidIcon: 'drawable/baseline_skip_next_white_24',
  label: 'Next',
  action: MediaAction.skipToNext,
);
const MediaControl skipToPreviousControl = MediaControl(
  androidIcon: 'drawable/ic_action_skip_previous',
  label: 'Previous',
  action: MediaAction.skipToPrevious,
);
const MediaControl stopControl = MediaControl(
  androidIcon: 'drawable/baseline_close_white_24',
  label: 'Stop',
  action: MediaAction.stop,
);
const MediaControl forwardControl = MediaControl(
  androidIcon: 'drawable/baseline_fast_forward_white_24',
  label: 'forward',
  action: MediaAction.fastForward,
);
const MediaControl rewindControl = MediaControl(
  androidIcon: 'drawable/baseline_fast_rewind_white_24',
  label: 'rewind',
  action: MediaAction.rewind,
);

/// Sleep timer mode.
enum SleepTimerMode { endOfEpisode, timer, unset }

/// Audio player height
enum PlayerHeight {
  short(70),
  mid(75),
  tall(80);

  const PlayerHeight(this.height);
  final double height;
}

class AudioPlayerNotifier extends ChangeNotifier {
  /// Database access
  final DBHelper _dbHelper = DBHelper();

  /// Episode state propogation
  late final EpisodeState _episodeState;

  /// Browsable library for android auto. Needs a context with all state providers.
  /// Set this before adding the first listener.
  BrowsableLibrary? browsableLibrary;

  AudioPlayerNotifier(BuildContext context) {
    _episodeState = Provider.of<EpisodeState>(context, listen: false);
  }

  /// Unused. (replaced by history database)
  final _positionStorage = const KeyValueStorage(audioPositionKey);

  /// Auto play next episode in playlist
  final _autoPlayStorage = const KeyValueStorage(autoPlayKey);

  /// Default time for sleep timer (mins)
  final _defaultSleepTimerStorage = const KeyValueStorage(defaultSleepTimerKey);

  /// Auto turn on sleep timer
  final _autoSleepTimerStorage = const KeyValueStorage(autoSleepTimerKey);

  /// Auto sleep timer mode
  final _autoSleepTimerModeStorage =
      const KeyValueStorage(autoSleepTimerModeKey);

  /// Auto sleep timer schedule start time (in minutes)
  final _autoSleepTimerStartStorage =
      const KeyValueStorage(autoSleepTimerStartKey);

  /// Auto sleep timer schedule end time (in minutes)
  final _autoSleepTimerEndStorage = const KeyValueStorage(autoSleepTimerEndKey);

  /// Fast forward seconds
  final _fastForwardSecondsStorage =
      const KeyValueStorage(fastForwardSecondsKey);

  /// Rewind seconds
  final _rewindSecondsStorage = const KeyValueStorage(rewindSecondsKey);

  /// Index to [PlayerHeight]
  final _playerHeightStorage = const KeyValueStorage(playerHeightKey);

  /// Current play speed
  final _speedStorage = const KeyValueStorage(speedKey);

  /// Player skip silence bool
  final _skipSilenceStorage = const KeyValueStorage(skipSilenceKey);

  /// Volume boost bool
  final _boostVolumeStorage = const KeyValueStorage(boostVolumeKey);

  /// Volume boost level
  final _volumeGainStorage = const KeyValueStorage(volumeGainKey);

  /// Mark as listened when skipped
  final _markListenedAfterSkipStorage =
      const KeyValueStorage(markListenedAfterSkipKey);

  /// List of [Playlist]s encoded as json // TODO: Move this to sql maybe?
  final _playlistsStorage = const KeyValueStorage(playlistsAllKey);

  /// [Last playing playlist id, episode enclosure url, position (unused)]
  final _playerStateStorage = const KeyValueStorage(playerStateKey);

  /// Cache size in bytes
  final cacheStorage = const KeyValueStorage(cacheMaxKey);

  /// Settings varibales

  /// Unused (only takes value 0). Record plyaer position.
  final int _lastPosition = 0;

  /// Auto play next episode in playlist
  late bool _autoPlay;

  /// Auto play next episode in playlist
  bool get effectiveAutoPlay =>
      _autoPlay && _sleepTimerMode != SleepTimerMode.endOfEpisode;

  /// Default time for sleep timer (mins)
  late int _defaultTimer;

  /// Auto stop at the end of episode when you start play at scheduled time.
  late bool _autoSleepTimer;

  /// Sleep timer mode.
  SleepTimerMode _sleepTimerMode = SleepTimerMode.unset;

  /// Auto sleep timer schedule start time (in minutes)
  late int _startTime;

  /// Auto sleep timer schedule end time (in minutes)
  late int _endTime;

  int? _fastForwardSeconds = 0;
  int? _rewindSeconds = 0;
  PlayerHeight? _playerHeight;
  double _currentSpeed = 1;
  bool? _skipSilence;
  bool? _boostVolume;
  late int _volumeGain;

  /// Mark as listened when skipped // TODO: Actually do this.
  late bool _markListened;

  /// Current state variables

  /// Currently playing episode's id.
  int? get _episodeId =>
      _playlist.isNotEmpty ? _playlist.episodeIds[_episodeIndex] : null;

  /// Id of the episode to start playback from
  int? get _startEpisodeId => _startPlaylist.isNotEmpty
      ? _startPlaylist.episodeIds[_startEpisodeIndex]
      : null;

  /// Index of currently playing episode
  int _episodeIndex = 0;

  /// Episode index to start playback from
  late int _startEpisodeIndex;

  /// Helper to get the object of currently playing episode.
  /// Make sure [_episodeId] isn't null
  EpisodeBrief? get _episodeBrief =>
      _episodeId != null ? _episodeState[_episodeId!] : null;

  /// Helper to get the object of currently playing episode.
  /// Make sure [_episodeId] isn't null
  MediaItem? get _mediaItem => _episodeBrief?.mediaItem;

  /// Currently playing playlist.
  Playlist _playlist = Playlist("none");

  /// Playlist to start playback from
  late Playlist _startPlaylist;

  /// Playlists include queue and playlists created by user.
  List<Playlist> _playlists = [];

  /// Queue is the first playlist.
  Playlist get _queue => _playlists.first;

  /// Player state.
  AudioProcessingState _audioState = AudioProcessingState.loading;

  /// Player playing.
  bool _playing = false;

  /// Control audio player
  bool _playerRunning = false;

  /// Wheter the player just started
  bool playerInitialStart = true;

  /// Current episode duration (ms).
  int _audioDuration = 0;

  /// Current episode position (ms).
  int _audioPosition = 0;

  /// Position of the seek in progress (ms). -1 to indicate no seek in progress.
  int get _liveSeekPosition =>
      _liveSeekValue == -1 ? -1 : (_liveSeekValue * _audioDuration).toInt();

  /// Position from history (ms).
  int _historyPosition = 0;

  /// Seek ratio from history.
  double _historySeek = 0;

  /// Current episode buffered position (ms).
  int _audioBufferedPosition = 0;

  /// Seekbar value, min 0, max 1.0.
  double get _seekSliderValue =>
      _audioDuration != 0 ? (_audioPosition / _audioDuration).clamp(0, 1) : 0;

  /// Value of the seek in progress. -1 to indicate no seek in progress.
  double _liveSeekValue = -1;

  /// Enables auto skip based on [_historyPosition] and [EpisodeBrief.skipSecondsStart]
  bool _skipStart = true;

  /// Enables auto skip based on [EpisodeBrief.skipSecondsEnd]
  bool _skipEnd = true;

  /// Amounts to skip when player button is pressed.
  /// -1 goes back an episode (loads [_lastEpisodeId] if queue)
  /// and skips to the next item in stack
  final List<int> _undoButtonPositionsStack = [];

  /// Episode last removed from queue
  int? _lastEpisodeId;

  /// Indicates seek is being undone so _undoButtonPositionsStack shouldn't be modified
  bool _undoSeekOngoing = false;

  /// Timer that'll clear undo seek after 30 seconds.
  Timer? _clearUndoSeekTimer;

  /// Error message.
  String? _remoteErrorMessage;

  /// Prevents history saving
  bool _playingTemp = false;

  /// Last saved history to avoid sending it twice
  PlayHistory? _lastHistory;

  /// Lock to prevent updating episode index and saving history while editing playlists.
  int _playlistBeingEdited = 0;

  /// Sleep variables

  /// Sleep timer timer.
  late Timer _stopTimer;

  /// Sleep timer time left.
  int _timeLeft = 0;

  /// (Redundant with above) Control sleep timer anamation.
  double _switchValue = 0;

  /// Position of last player state save
  int _savedPosition = 0;

  /// Audio service plugin
  late CustomAudioHandler _audioHandler;

  /// Subscription to AudioHandler current mediaItem broadcast
  StreamSubscription<MediaItem?>? _mediaItemSubscription;

  /// Subscription to AudioHandler playbackState broadcast
  StreamSubscription<PlaybackState>? _playbackStateSubscription;

  /// Subscription to AudioHandler custom events broadcast
  StreamSubscription<dynamic>? _customEventSubscription;

  /// Audio service config
  AudioServiceConfig get _config => AudioServiceConfig(
        androidResumeOnClick: true,
        androidNotificationChannelName: 'Tsacdop Podcast',
        androidNotificationIcon: 'drawable/ic_notification',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        preloadArtwork: false,
        fastForwardInterval: Duration(seconds: _fastForwardSeconds!),
        rewindInterval: Duration(seconds: _rewindSeconds!),
      );

  /// Getters

  /// Unused (only takes value 0). Record plyaer position.
  int get lastPosition => _lastPosition;

  /// (Unused) Auto stop at the end of episode when you start play at scheduled time.
  bool? get autoSleepTimer => _autoSleepTimer;
  int? get fastForwardSeconds => _fastForwardSeconds;
  int? get rewindSeconds => _rewindSeconds;
  PlayerHeight? get playerHeight => _playerHeight;
  double get currentSpeed => _currentSpeed;
  bool? get skipSilence => _skipSilence;
  bool? get boostVolume => _boostVolume;
  int get volumeGain => _volumeGain;

  bool get playing => _playing;
  bool get playerRunning => _playerRunning;

  /// Current episode duration (ms).
  int get audioDuration => _audioDuration;

  /// Current episode position (ms).
  int get audioPosition =>
      _liveSeekPosition != -1 ? _liveSeekPosition : _audioPosition;

  /// Current episode's start position (ms).
  int get historyPosition => _historyPosition;

  /// Current episode buffered position (ms).
  int get audioBufferedPosition => _audioBufferedPosition;

  /// Seekbar value, min 0, max 1.0.
  double get seekSliderValue =>
      _liveSeekValue != -1 ? _liveSeekValue : _seekSliderValue;

  /// Position to skip to when player button is pressed
  int? get undoButtonPosition =>
      _undoButtonPositionsStack.isEmpty ? null : _undoButtonPositionsStack.last;

  /// Episode last removed from queue
  int? get lastEpisode => _lastEpisodeId;

  int? get episodeIndex => _episodeIndex;
  int? get startEpisodeIndex => _startEpisodeIndex;
  int? get episodeId => _episodeId;
  EpisodeBrief? get episodeBrief => _episodeBrief;
  Playlist get playlist => _playlist;
  Playlist get startPlaylist => _startPlaylist;
  List<Playlist> get playlists => _playlists;
  Playlist get queue => _queue;
  AudioProcessingState get audioState => _audioState;
  bool get buffering => _audioState != AudioProcessingState.ready;

  String? get remoteErrorMessage => _remoteErrorMessage;

  /// Sleep timer time left.
  int get timeLeft => _timeLeft;
  double get switchValue => _switchValue;
  SleepTimerMode get sleepTimerMode => _sleepTimerMode;

  set switchValue(double value) {
    _switchValue = value;
    notifyListeners();
  }

  // TODO: Move this to [SettingState]
  set setPlayerHeight(PlayerHeight mode) {
    _playerHeight = mode;
    notifyListeners();
    _playerHeightStorage.saveInt(_playerHeight!.index);
  }

  @override
  void addListener(VoidCallback listener) async {
    await _loadAudioData();
    await initPlaylists();
    await loadSavedPosition();
    int cacheMax =
        await cacheStorage.getInt(defaultValue: (1024 * 1024 * 200).toInt());
    _audioHandler = await AudioService.init(
        builder: () => CustomAudioHandler(cacheMax, browsableLibrary!),
        config: _config);
    await _audioHandler.initPlayer();
    await _loadPlayer();
    _addHandlerListeners();
    super.addListener(listener);
    notifyListeners();
  }

  @override
  void dispose() async {
    await _mediaItemSubscription?.cancel();
    await _playbackStateSubscription?.cancel();
    await _customEventSubscription?.cancel();
    await _audioHandler.disposePlayer();
    super.dispose();
  }

  /// Load audio data from storage // TODO: Make these reflect settings changes.
  Future<void> _loadAudioData() async {
    _autoPlay = (await _autoPlayStorage.getInt()) == 0;
    _defaultTimer = await _defaultSleepTimerStorage.getInt(defaultValue: 30);
    _autoSleepTimer = (await _autoSleepTimerStorage.getInt()) == 1;
    int mode = await (_autoSleepTimerModeStorage.getInt());
    _sleepTimerMode = SleepTimerMode.values[mode];
    _startTime = await (_autoSleepTimerStartStorage.getInt(defaultValue: 1380));
    _endTime = await (_autoSleepTimerEndStorage.getInt(defaultValue: 360));
    _fastForwardSeconds =
        await _fastForwardSecondsStorage.getInt(defaultValue: 30);
    _rewindSeconds = await _rewindSecondsStorage.getInt(defaultValue: 30);
    int index = await _playerHeightStorage.getInt(defaultValue: 0);
    _playerHeight = PlayerHeight.values[index];
    _currentSpeed = await _speedStorage.getDouble(defaultValue: 1.0);
    _skipSilence = await _skipSilenceStorage.getBool(defaultValue: false);
    _boostVolume = await _boostVolumeStorage.getBool(defaultValue: false);
    _volumeGain = await _volumeGainStorage.getInt(defaultValue: 3000);
    _markListened =
        await _markListenedAfterSkipStorage.getBool(defaultValue: false);
  }

  /// Loads playlists
  Future<void> initPlaylists() async {
    if (_playlists.isEmpty) {
      _playlists = await _playlistsStorage.getPlaylists(_episodeState);
    }
  }

  /// Saves position to player state
  Future<void> saveCurrentPosition() async {
    if (!_playingTemp) {
      _savedPosition = _audioPosition;
      await _playerStateStorage.savePlayerState(
          _playlist.id, _episodeIndex, _audioPosition);
    }
  }

  /// Saves current history and position
  Future<void> saveHistory({bool savePosition = false}) async {
    if (_episodeId == null) return;
    if (!_playingTemp) {
      if (savePosition) {
        await saveCurrentPosition();
      }
      PlayHistory history = PlayHistory(
          _episodeBrief!.title,
          _episodeBrief!.enclosureUrl,
          _audioPosition ~/ 1000,
          _seekSliderValue);

      if (_lastHistory != history) {
        _lastHistory = history;
        if (_seekSliderValue > 0.95) {
          await _episodeState.setPlayed([_episodeBrief!.id],
              seconds: history.seconds!, seekValue: history.seekValue!);
        } else {
          await _dbHelper.saveHistory(history);
        }
      }
    }
  }

  /// Loads saved [_startPlaylist], [_startEpisodeIndex] and [_historyPosition]
  Future<void> loadSavedPosition({bool saveCurrent = false}) async {
    // Get playerstate saved in storage.
    Tuple3<String, int, int> lastState =
        await _playerStateStorage.getPlayerState();
    if (saveCurrent) await saveHistory(savePosition: true);
    // Set playlist
    _startPlaylist = _playlists.firstWhere((p) => p.id == lastState.item1,
        orElse: () => _playlists.first);
    await _startPlaylist.cachePlaylist(_episodeState);
    // Set episode index
    if (_startPlaylist.isEmpty) {
      _startEpisodeIndex = 0;
    } else if (lastState.item2 >= 0 &&
        lastState.item2 < _startPlaylist.length) {
      if (_startPlaylist.isQueue) {
        _startEpisodeIndex = 0;
      } else {
        _startEpisodeIndex = lastState.item2;
      }
    } else {
      _startEpisodeIndex = 0;
    }
    // Load episode position
    if (_startPlaylist.isNotEmpty) {
      _historyPosition = lastState.item3;
      if (_historyPosition == 0) {
        PlayHistory position =
            await _dbHelper.getPosition(_episodeState[_startEpisodeId!]);
        _historyPosition = position.seconds! * 1000;
      }
    }
    notifyListeners();
  }

  /// Loads the saved position of the provided or start episode to [_historyPosition]
  Future<void> loadEpisodeHistoryPosition({int? id}) async {
    id ??= _startEpisodeId;
    PlayHistory position = await _dbHelper.getPosition(_episodeState[id!]);
    _historyPosition = position.seconds! * 1000;
    _historySeek = position.seekValue!;
    notifyListeners();
  }

  /// Loads the [_skipStart] position to [_audioPosition]. For visual consistency
  void _loadStartPosition() {
    if (_historyPosition != 0 &&
        _historySeek < 0.95 &&
        _historyPosition > 10000) {
      _audioPosition = _historyPosition;
    } else if (_episodeBrief!.skipSecondsStart != 0) {
      _audioPosition = _episodeBrief!.skipSecondsStart * 1000;
    } else {
      _audioPosition = 0;
    }
  }

  /// Starts or changes playback according to [_startPlaylist], [_startEpisodeIndex] variables.
  /// Doesn't reorder queue or save history, do those before calling this.
  Future<void> playFromStart({bool samePlaylist = false}) async {
    if (_startEpisodeIndex != -1 &&
        _startEpisodeIndex < _startPlaylist.length &&
        (!_startPlaylist.isQueue || _startEpisodeIndex == 0) &&
        _startPlaylist.isNotEmpty) {
      await _startPlaylist.cachePlaylist(_episodeState);
      _playlist = _startPlaylist;
      _episodeIndex = _startEpisodeIndex;
      _playerRunning = true;
      _loadStartPosition();
      _audioDuration = _episodeBrief!.enclosureDuration * 1000;
      if (samePlaylist) {
        _playlistBeingEdited++;
        await skipToIndex(_startEpisodeIndex);
        _playlistBeingEdited--;
      } else {
        if (effectiveAutoPlay) {
          _playlistBeingEdited++;
          await _audioHandler.replaceQueue(_playlist.episodeIds
              .map((id) => _episodeState[id].mediaItem)
              .toList());
          await skipToIndex(_startEpisodeIndex);
          _playlistBeingEdited--;
        } else {
          _playlistBeingEdited++;
          await _audioHandler.replaceQueue([_mediaItem!]);
          _playlistBeingEdited--;
        }
      }
    } else {
      log('Invalid position to play');
    }
  }

  /// Starts playback from last played playlist and episode
  Future<void> playFromLastPosition() async {
    if (_mediaItemSubscription != null) {
      _audioHandler.play();
    } else {
      await loadSavedPosition(saveCurrent: playerRunning);
      if (_startEpisodeIndex != -1) {
        await playFromStart(samePlaylist: _startPlaylist == _playlist);
      } else {
        log('Invalid data, loading queue');
        await playlistLoad(_queue);
      }
    }
  }

  /// Loads arbitrary playlist from start. Doesn't need to be saved
  Future<void> playlistLoad(Playlist playlist, {int index = 0}) async {
    await playlist.cachePlaylist(_episodeState);
    if (playlist.isNotEmpty) {
      await saveHistory();
      _startPlaylist = playlist;
      _startEpisodeIndex = index;
      _historyPosition = 0;
      _lastEpisodeId = null;
      await playFromStart();
      await _audioHandler.play();
      await saveHistory(savePosition: true);
    }
  }

  /// Temporarily loads an episode from search // TODO: make sure the playlist is deleted once the episode finishes
  Future<void> searchEpisodeLoad(int episodeId) async {
    Playlist tempPlaylist = Playlist(
      // TODO: add search playlist flag like local?
      "Search",
      episodeIds: [episodeId],
    );
    _playingTemp = true;
    await saveHistory(savePosition: true);
    await playlistLoad(tempPlaylist);
  }

  /// Adds episode to beginning of the queue and starts playing.
  Future<void> loadEpisodeToQueue(int episodeId,
      {int startPosition = 0}) async {
    await loadEpisodesToQueue([episodeId], startPosition: startPosition);
  }

  /// Adds episode to beginning of the queue and starts playing.
  Future<void> loadEpisodesToQueue(List<int> episodeIds,
      {int startPosition = 0}) async {
    await saveHistory();
    await addToPlaylist(episodeIds, playlist: _queue, index: 0);
    if (!(playerRunning && _playlist.isQueue)) {
      // Switch to queue
      _startPlaylist = _queue;
      _startEpisodeIndex = 0;
      // Set _audioStartPosition
      if (startPosition > 0) {
        _historyPosition = startPosition;
      } else {
        await loadEpisodeHistoryPosition();
        _loadStartPosition();
      }
      await playFromStart(samePlaylist: false);
    } else {
      if (startPosition > 0) {
        // Override the default seek to history position with provided
        _audioHandler.combinedSeek(
            position: Duration(milliseconds: startPosition));
      }
    }
    notifyListeners();
    await _episodeState.unsetNew(episodeIds);
  }

  /// Skips to the episode at specified index
  Future<void> loadEpisodeFromCurrentPlaylist(int episodeIndex) async {
    await saveHistory();
    if (!_playlist.isQueue) {
      _startEpisodeIndex = episodeIndex;
      await loadEpisodeHistoryPosition();
      _loadStartPosition();
      await playFromStart(samePlaylist: true);
    } else {
      await reorderPlaylist(episodeIndex, 0);
    }
  }

  /// Load the audio service and player. Doesn't start playback
  Future<void> _loadPlayer() async {
    _playlist = _startPlaylist;
    _episodeIndex = _startEpisodeIndex;
    _audioPosition = _historyPosition;
    // Set initial variables
    _sleepTimerMode = SleepTimerMode.unset;
    _switchValue = 0;
    _audioState = AudioProcessingState.loading;
    _audioDuration = _episodeBrief?.enclosureDuration ?? 0 * 1000;
    _skipStart = true;
    notifyListeners();

    /// Set player speed.
    if (_currentSpeed != 1.0) {
      await _audioHandler.customAction('setSpeed', {'speed': _currentSpeed});
    }

    /// Set slipsilence.
    if (_skipSilence!) {
      await _audioHandler
          .customAction('setSkipSilence', {'skipSilence': skipSilence});
    }

    /// Set boostValome.
    if (_boostVolume!) {
      await _audioHandler.customAction(
          'setBoostVolume', {'boostVolume': _boostVolume, 'gain': _volumeGain});
    }

    if (playlist.isNotEmpty) {
      if (effectiveAutoPlay) {
        final list = _playlist.episodeIds
            .map((id) => _episodeState[id].mediaItem)
            .toList();
        await _audioHandler.replaceQueue(list);
        // await _audioHandler.skipToQueueItem(_episodeIndex!);
      } else {
        await _audioHandler.replaceQueue([_mediaItem!]);
      }
      await skipToIndex(_startEpisodeIndex);

      if (_autoSleepTimer) {
        int currentTime = DateTime.now().hour * 60 + DateTime.now().minute;
        if ((_startTime > _endTime &&
                (currentTime > _startTime || currentTime < _endTime)) ||
            ((_startTime < _endTime) &&
                (currentTime > _startTime && currentTime < _endTime))) {
          sleepTimer(_defaultTimer);
        }
      }
    }
  }

  /// Adds listeners to keep the AudioPlayerNotifier state in sync with the CustomAudioHandler.
  /// History is saved if:
  /// - Playing episode changes
  /// - Playback is paused
  /// - Playback is stopped
  /// - Playing episode changes due to playlist editing
  /// First two are only in effect if _playlistBeingEdited is 0, since playing episode might
  /// change erratically while playlist editing functions are running and they handle history saving on their own.
  /// Even though this should cover all cases player state (not history) is also saved every 10 seconds just in case
  /// These listeners also handle queue behavior, automatic history seeking and adding positions to undo stack.
  void _addHandlerListeners() {
    _mediaItemSubscription ??=
        _audioHandler.mediaItem.distinct().whereNotNull().listen(
      (MediaItem item) async {
        Future<void> removeFirstFuture = Future(() {});
        // Handle episode change
        if (item.extras!["index"] != null) {
          int newIndex = item.extras!["index"];
          if (_playlistBeingEdited == 0) {
            if (item != _mediaItem) {
              await saveHistory();
              if (_playlist.isQueue && newIndex - 1 == _episodeIndex) {
                // Remove played episode from playlist when playlist is queue
                removeFirstFuture = removeFromPlaylistAt(0);
                _lastEpisodeId = _episodeId;
              }
            }
            _episodeIndex = newIndex;
          } else {
            _undoButtonPositionsStack.clear();
          }
          await loadEpisodeHistoryPosition(id: _episodeId);
          _loadStartPosition();
          _skipStart = true;
          _skipEnd = true;
          _audioDuration = item.duration!.inMilliseconds;
          // This saves the new episode to playerstate.
          await _playerStateStorage.savePlayerState(
              _playlist.id, _episodeIndex, _audioPosition);
        }
        notifyListeners();
        await removeFirstFuture;
      },
    );
    _playbackStateSubscription ??= _audioHandler.playbackState
        .distinct()
        .listen((PlaybackState event) async {
      Future<void> removeFirstFuture = Future(() {});
      _audioState = event.processingState;
      if (!_playing && event.playing) {
        _playerRunning = true;
      } else if (_playing && !event.playing) {
        await saveHistory(savePosition: true);
      }
      _playing = event.playing;
      // _audioPosition = event.updatePosition.inMilliseconds;
      _audioBufferedPosition = event.bufferedPosition.inMilliseconds;
      _currentSpeed = event.speed;
      if (_audioState == AudioProcessingState.completed) {
        if (_switchValue > 0) _switchValue = 0;
        _sleepTimerMode = SleepTimerMode.unset;
        await _audioHandler.pause();
        if (_playingTemp) {
          _playingTemp = false;
          await loadSavedPosition(saveCurrent: false);
        } else {
          if (_playlist.isQueue) {
            if (_playlist.length == 1) {
              await saveHistory(savePosition: true);
              await removeFromPlaylistAt(0);
              _playerRunning = false;
            } else {
              await removeFromPlaylistAt(0);
            }
          } else if (_episodeIndex != _playlist.length - 1) {
            _episodeIndex++;
          }
        }
        _audioHandler.stop();
      }

      /// Get error state.
      if (_audioState == AudioProcessingState.error) {
        _remoteErrorMessage = 'Network Error';
      }

      /// Reset error state.
      if (_audioState != AudioProcessingState.error) {
        _remoteErrorMessage = null;
      }
      notifyListeners();
      await removeFirstFuture;
    });
    _customEventSubscription ??=
        _audioHandler.customEvent.distinct().listen((event) async {
      if (event['playerRunning'] == false && _playerRunning) {
        await saveHistory(savePosition: true);
        _historyPosition = _audioPosition;
        _playerRunning = false;
        notifyListeners();
      }
      if (event['preSeekPosition'] != null && !_undoSeekOngoing) {
        Duration seekAmount = Duration(
            milliseconds: (event['preSeekPosition'] - _audioPosition).abs());
        if (seekAmount < AudioService.config.fastForwardInterval ||
            seekAmount < AudioService.config.rewindInterval) {
          return;
        }
        _undoButtonPositionsStack.add(event['preSeekPosition']);
        if (_clearUndoSeekTimer != null) _clearUndoSeekTimer!.cancel();
        _clearUndoSeekTimer = Timer(Duration(seconds: 30), () {
          _undoButtonPositionsStack.clear();
          _lastEpisodeId = null;
        });
      }
      // Set seekbar position, handle skipping start and end.
      // Ignore position updates if index doesn't match current index so that history saving is consistent
      if (event['position'] != null && event['index'] == _episodeIndex) {
        _audioPosition = event['position'].inMilliseconds;
        if (_skipStart && _episodeId != null) {
          _skipStart = false;
          if (_historyPosition / _audioDuration < 0.95 &&
              _historyPosition > 10000) {
            if (_episodeBrief!.skipSecondsStart != 0 &&
                _historyPosition > _episodeBrief!.skipSecondsStart * 1000) {
              _undoButtonPositionsStack
                  .add(_episodeBrief!.skipSecondsStart * 1000);
            }
            await seekTo(_historyPosition);
          } else if (_episodeBrief!.skipSecondsStart != 0) {
            if (_historyPosition != 0) {
              _undoButtonPositionsStack.add(_historyPosition);
            }
            await seekTo(_episodeBrief!.skipSecondsStart * 1000);
          }
        }
        if (_skipEnd && _episodeId != null) {
          if (_audioPosition >
              (_audioDuration - _episodeBrief!.skipSecondsEnd * 1000)) {
            _skipEnd = false;
            _undoButtonPositionsStack.clear();
            _undoButtonPositionsStack
                .addAll([_episodeBrief!.skipSecondsEnd, -1]);
            await seekTo(_audioDuration);
          }
        }
        // Save position every 10 seconds
        if (_audioPosition - _savedPosition > 10000 * _currentSpeed) {
          await saveCurrentPosition();
        }
        notifyListeners();
      }
      if (event['duration'] is Duration && _playlistBeingEdited == 0) {
        _audioDuration = (event['duration'] as Duration).inMilliseconds;
        notifyListeners();
      }
    });
  }

  // Queue management

  /// Helper function for when [effectiveAutoPlay] is disabled.
  Future<void> _replaceFirstQueueItem(int id) async {
    await _audioHandler.pause();
    await saveHistory();
    await loadEpisodeHistoryPosition(id: id);
    _loadStartPosition();
    await _audioHandler.addQueueItemsAt([_episodeState[id].mediaItem], 1);
    await _audioHandler.removeQueueItemsAt(0);
    await _audioHandler.play();
  }

  /// Adds [episodeIds] to [playlist]. Handles adding to live playlist.
  /// Negative index indexes from the end.
  /// Defaults to to index -1 of [_playlist].
  Future<void> addToPlaylist(List<int> episodeIds,
      {Playlist? playlist, int index = -1}) async {
    Future seekFuture = Future(() {});
    if (episodeIds.isEmpty) return seekFuture;
    playlist ??= _playlist;
    if (index < 0) {
      index += playlist.length + 1;
    } else if (index > playlist.length) {
      index = playlist.length;
    }
    await playlist.cachePlaylist(_episodeState);
    await _episodeState.unsetNew(episodeIds);
    EpisodeCollision ifExists =
        playlist.isQueue ? EpisodeCollision.replace : EpisodeCollision.ignore;

    _playlistBeingEdited++;
    if (playlist == _playlist && playlist.isNotEmpty) {
      if (effectiveAutoPlay) {
        // Add episodes to the player
        await _audioHandler.addQueueItemsAt([
          for (var episodeId in episodeIds) _episodeState[episodeId].mediaItem
        ], index, ifExists: ifExists);
      }
      if (_episodeIndex < index) {
        // Current episode is not affected
      } else {
        if (playlist.isQueue) {
          // Play newly inserted episodes.
          if (effectiveAutoPlay) {
            await saveHistory();
            await loadEpisodeHistoryPosition(id: episodeIds[0]);
            _loadStartPosition();
            seekFuture = _audioHandler.skipToQueueItem(0);
          } else {
            await _replaceFirstQueueItem(episodeIds[0]);
          }
        } else {
          _episodeIndex = _episodeIndex + episodeIds.length;
        }
      }
    }
    playlist.addEpisodes(episodeIds, index, ifExists: ifExists);
    await _savePlaylists();
    if (playlist == _playlist && _playlist.isQueue && index == 0) {
      loadEpisodeHistoryPosition();
      _loadStartPosition();
    }
    notifyListeners();
    await seekFuture;
    _playlistBeingEdited--;
  }

  /// Adds episodes at the end of the current playlist
  Future<void> addNewEpisode(List<String> group) async {
    var newEpisodes = <int>[];
    if (group.isEmpty) {
      newEpisodes = await _episodeState.getEpisodes(
          sortBy: Sorter.pubDate,
          sortOrder: SortOrder.desc,
          filterNew: true,
          limit: 100);
    } else {
      newEpisodes = await _episodeState.getEpisodes(
          feedIds: group,
          sortBy: Sorter.pubDate,
          sortOrder: SortOrder.desc,
          filterNew: true,
          limit: 100);
    }
    await addToPlaylist(newEpisodes);
  }

  /// Adds episode to be played next in the current playlist
  Future<void> addToTop(int episodeId) async {
    int index = _playlist.isQueue ? 1 : 0;
    await addToPlaylist([episodeId], index: index);
  }

  /// Removes [episodeIds] from [playlist]. [playlist] defaults to [_playlist]
  Future<List<int>> removeFromPlaylist(List<int> episodeIds,
      {Playlist? playlist}) async {
    if (episodeIds.isEmpty) return [];
    playlist ??= _playlist;
    if (playlist.isEmpty) return [];
    await playlist.cachePlaylist(_episodeState);
    List<int> indicies = [];
    // Find episode indexes
    for (int i = 0; i < playlist.episodeIds.length; i++) {
      for (var episodeId in episodeIds) {
        var delEpisodeId = playlist.episodeIds[i];
        if (episodeId == delEpisodeId) {
          indicies.add(i);
          break;
        }
      }
    }
    _batchRemoveIndexesFromPlaylistHelper(indicies, playlist: playlist);
    return indicies;
  }

  /// Removes episodes at [indicies] from [playlist]. [playlist] defaults to [_playlist]
  Future<List<int>> removeIndexesFromPlaylist(List<int> indicies,
      {Playlist? playlist}) async {
    if (indicies.isEmpty) return [];
    playlist ??= _playlist;
    if (playlist.isEmpty) return [];
    await playlist.cachePlaylist(_episodeState);
    indicies.sort();
    _batchRemoveIndexesFromPlaylistHelper(indicies, playlist: playlist);
    return indicies;
  }

  /// Helper function for batch removing sorted indexes
  Future<void> _batchRemoveIndexesFromPlaylistHelper(List<int> indicies,
      {Playlist? playlist}) async {
    // Remove items in batches starting from the end
    playlist ??= _playlist;
    int? index1;
    int? index2;
    int number = 0;
    index1 = indicies.removeLast();
    while (index1 != null) {
      do {
        number++;
        if (indicies.isNotEmpty) {
          index2 = indicies.removeLast();
        } else {
          index2 = null;
          break;
        }
      } while (index1 == index2 + number);

      if (playlist == _playlist) {
        await removeFromPlaylistAt(index1 - number + 1,
            number: number, playlist: playlist);
      } else {
        playlist.removeEpisodesAt(_episodeState, index1 - number + 1,
            number: number);
      }
      number = 0;
      index1 = index2;
    }
    await _savePlaylists();
    notifyListeners();
  }

  /// Removes [number] episodes from [playlist] at [index]. [playlist] defaults to [_playlist]
  Future<void> removeFromPlaylistAt(int index,
      {int number = 1, Playlist? playlist}) async {
    Future seekFuture = Future(() {});
    playlist ??= _playlist;
    if (playlist.isEmpty) return seekFuture;
    if (index < 0) index += playlist.length + 1;
    final int end = index + number;
    if (end > playlist.length || number < 0) return seekFuture;
    await playlist.cachePlaylist(_episodeState);

    _playlistBeingEdited++;
    if (playlist == _playlist) {
      if (_episodeIndex < index) {
        // Current episode is not affected
        if (effectiveAutoPlay) {
          // Remove episodes from the player
          await _audioHandler.removeQueueItemsAt(index, number: number);
        }
      } else if (_episodeIndex <= end) {
        // Current episode is deleted
        if (end < playlist.length) {
          if (effectiveAutoPlay) {
            // Player starts playing the next undeleted episode
            await loadEpisodeHistoryPosition(id: playlist.episodeIds[end]);
            _loadStartPosition();
            // Remove episodes from the player
            await _audioHandler.removeQueueItemsAt(index, number: number);
          } else {
            // Next episode is loaded and playback stops.
            await _replaceFirstQueueItem(playlist.episodeIds[end]);
            await _audioHandler.stop();
          }
          _episodeIndex = index;
        } else {
          // Playback stops
          await _audioHandler.stop();
        }
      } else if (_episodeIndex > end) {
        // Current episode's index is shifted and continues playing
        _episodeIndex = _episodeIndex - number;
        if (effectiveAutoPlay) {
          // Remove episodes from the player
          await _audioHandler.removeQueueItemsAt(index, number: number);
        }
      }
    }
    playlist.removeEpisodesAt(_episodeState, index, number: number);
    await _savePlaylists();
    if (playlist == _playlist &&
        _playlist.isQueue &&
        index == 0 &&
        _playlist.isNotEmpty) {
      loadEpisodeHistoryPosition();
      _loadStartPosition();
    }
    notifyListeners();
    await seekFuture;
    _playlistBeingEdited--;
  }

  /// Moves [playlist] episode at [oldIndex] to [newIndex]. [playlist] defaults to [_playlist]
  Future<void> reorderPlaylist(int oldIndex, int newIndex,
      {Playlist? playlist}) async {
    Future seekFuture = Future(() {});
    if (oldIndex == newIndex) return seekFuture;
    playlist ??= _playlist;
    if (playlist.isEmpty) return seekFuture;
    if (oldIndex < 0) oldIndex += playlist.length;
    if (newIndex < 0) newIndex += playlist.length;
    if (oldIndex >= playlist.length || newIndex >= playlist.length) {
      return seekFuture;
    }
    await playlist.cachePlaylist(_episodeState);

    _playlistBeingEdited++;
    if (playlist == _playlist) {
      if (effectiveAutoPlay) {
        // Reorder the player
        await _audioHandler.reorderQueueItems(
          oldIndex,
          newIndex,
        );
      }
      if (oldIndex == _episodeIndex) {
        // Current episode is moved
        if (playlist.isQueue) {
          // Playing episode changes
          _episodeIndex = 1;
          if (effectiveAutoPlay) {
            await saveHistory();
            await loadEpisodeHistoryPosition(id: playlist.episodeIds[1]);
            _loadStartPosition();
            seekFuture = _audioHandler.skipToQueueItem(0);
          } else {
            await _replaceFirstQueueItem(playlist.episodeIds[1]);
          }
        } else {
          _episodeIndex = newIndex;
        }
      } else if (oldIndex > _episodeIndex && newIndex > _episodeIndex ||
          oldIndex < _episodeIndex && newIndex < _episodeIndex) {
        // Moved episode doesn't affect current episode's index
      } else if (oldIndex > _episodeIndex && newIndex <= _episodeIndex) {
        // Current episode's index is increased.
        if (playlist.isQueue) {
          // Playing episode changes
          if (effectiveAutoPlay) {
            await saveHistory();
            await loadEpisodeHistoryPosition(id: playlist.episodeIds[oldIndex]);
            _loadStartPosition();
            seekFuture = _audioHandler.skipToQueueItem(0);
          } else {
            await _replaceFirstQueueItem(playlist.episodeIds[oldIndex]);
          }
        } else {
          _episodeIndex = _episodeIndex + 1;
        }
      } else if (oldIndex < _episodeIndex && newIndex >= _episodeIndex) {
        // Current episode's index is decreased
        if (playlist.isQueue) {
          // Impossible
        } else {
          _episodeIndex = _episodeIndex - 1;
        }
      }
    }
    playlist.reorderPlaylist(oldIndex, newIndex);
    await _savePlaylists();
    if (playlist == _playlist &&
        _playlist.isQueue &&
        (oldIndex == 0 || newIndex == 0)) {
      loadEpisodeHistoryPosition();
      _loadStartPosition();
    }
    notifyListeners();
    await seekFuture;
    _playlistBeingEdited--;
  }

  /// Updates the media ID of an episode with the one provided.
  /// Replaces the playing episode if its media ID changed.
  Future<void> updateEpisodeMediaID(EpisodeBrief episode) async {
    List<int> indexes = [];
    for (int i = 0; i < _playlist.length; i++) {
      if (_playlist[i] == episode.id) {
        indexes.add(i);
      }
    }
    if (indexes.isNotEmpty) {
      _playlistBeingEdited++;
      if (indexes.remove(_episodeIndex)) {
        // Currently playing episode is replaced
        int index = _episodeIndex;
        await _audioHandler.addQueueItemsAt([episode.mediaItem], index + 1);
        _episodeIndex = index;
        await _audioHandler.combinedSeek(
            position: Duration(milliseconds: _audioPosition), index: index + 1);
        _episodeIndex = index;
        await _audioHandler.removeQueueItemsAt(index);
      }
      // Another episode is replaced.
      if (effectiveAutoPlay) {
        for (int i in indexes) {
          await _audioHandler.addQueueItemsAt([episode.mediaItem], i + 1);
          await _audioHandler.removeQueueItemsAt(i);
        }
      }
      _playlistBeingEdited--;
    }
  }

  /// Custom playlist management.

  /// Adds playlist to playlists
  void addPlaylist(Playlist playlist) {
    _playlists.add(playlist);
    notifyListeners();
    _savePlaylists();
  }

  /// Deletes playlist from playlists. Doesn't unload it from player.
  void deletePlaylist(Playlist playlist) {
    _playlists.remove(playlist);
    notifyListeners();
    _savePlaylists();
    if (playlist.isLocal) {
      _dbHelper.deleteLocalEpisodes(playlist.episodeIds);
    }
  }

  /// Clears all episodes in playlist
  void clearPlaylist(Playlist playlist) {
    removeFromPlaylistAt(0, number: playlist.length, playlist: playlist);
  }

  bool playlistExists(String? name) {
    for (var p in _playlists) {
      if (p.name == name) return true; // TODO: Compare by id
    }
    return false;
  }

  Future<void> _savePlaylists() async {
    _playlists.add(Playlist(
        "Refresh")); // Crude way to make playlist changes reflect on ui
    _playlists.removeLast();
    await _playlistsStorage.savePlaylists([for (var p in _playlists) p]);
  }

  /// Audio control. These functions only relay information to AudioHandler.
  /// State change is done by the AudioHandler stream listeners.
  Future<void> pauseAduio() async {
    saveCurrentPosition();
    await _audioHandler.pause();
  }

  Future<void> resumeAudio() async {
    _remoteErrorMessage = null;
    if (_audioState != AudioProcessingState.loading) {
      _audioHandler.play();
    }
  }

  /// Plays next episode in playlist, ends playback if there isn't one.
  Future<void> skipToNext() async {
    _remoteErrorMessage = null;
    if (_playlist.length - _episodeIndex > 1) {
      if (effectiveAutoPlay) {
        await _audioHandler.skipToNext();
      } else {
        if (_playlist.isQueue) {
          _playlist.removeEpisodesAt(_episodeState, 0);
        } else {
          _startEpisodeIndex = _episodeIndex + 1;
        }
        await loadEpisodeHistoryPosition();
        await playFromStart();
      }
    } else {
      if (_playlist.isQueue) {
        _playlist.removeEpisodesAt(_episodeState, 0);
      } else {
        _startEpisodeIndex = _episodeIndex + 1;
      }
      await _audioHandler.stop();
    }
    notifyListeners();
  }

  Future<void> skipToIndex(int index) async {
    if (_playlist.isQueue) {
      await reorderPlaylist(index, 0);
    } else {
      await _audioHandler.skipToQueueItem(index);
    }
  }

  Future<void> fastForward() async {
    _audioHandler.fastForward();
  }

  Future<void> rewind() async {
    _audioHandler.rewind();
  }

  Future<void> seekTo(int position) async {
    _audioPosition = position;
    _audioHandler.combinedSeek(position: Duration(milliseconds: position));
  }

  /// Changes the visual value of the seekbar
  Future<void> seekbarVisualSeek(double val) async {
    _liveSeekValue = val;
    notifyListeners();
  }

  /// Seeks to the given value
  Future<void> seekbarSeek(double val) async {
    _liveSeekValue = -1;
    await seekTo((val * _audioDuration).toInt());
  }

  /// Undoes last seek
  Future<void> undoSeek() async {
    if (_undoButtonPositionsStack.isNotEmpty) {
      if (_undoButtonPositionsStack.last == -1) {
        _undoSeekOngoing = true;
        _undoButtonPositionsStack.removeLast();
        if (_playlist.isQueue && _lastEpisodeId != null) {
          await addToPlaylist([_lastEpisodeId!], index: 0);
        }
        _undoSeekOngoing = false;
      }
    }
    if (_undoButtonPositionsStack.isNotEmpty) {
      _undoSeekOngoing = true;
      await _audioHandler.combinedSeek(
          position:
              Duration(milliseconds: _undoButtonPositionsStack.removeLast()));
      _undoSeekOngoing = false;
    }
  }

  /// Set player speed.
  Future<void> setSpeed(double speed) async {
    await _audioHandler.customAction('setSpeed', {'speed': speed});
    _currentSpeed = speed;
    await _speedStorage.saveDouble(_currentSpeed);
    notifyListeners();
  }

  // Set skip silence.
  Future<void> setSkipSilence({required bool skipSilence}) async {
    await _audioHandler
        .customAction('setSkipSilence', {'skipSilence': skipSilence});
    _skipSilence = skipSilence;
    await _skipSilenceStorage.saveBool(_skipSilence);
    notifyListeners();
  }

  set setVolumeGain(int volumeGain) {
    _volumeGain = volumeGain;
    if (_boostVolume!) {
      setBoostVolume(boostVolume: _boostVolume!, gain: _volumeGain);
    }
    notifyListeners();
    _volumeGainStorage.saveInt(volumeGain);
  }

  Future<void> setBoostVolume({required bool boostVolume, int? gain}) async {
    await _audioHandler.customAction(
        'setBoostVolume', {'boostVolume': boostVolume, 'gain': _volumeGain});
    _boostVolume = boostVolume;
    notifyListeners();
    await _boostVolumeStorage.saveBool(boostVolume);
  }

  //Set sleep timer
  void sleepTimer(int? mins) async {
    if (_sleepTimerMode == SleepTimerMode.timer) {
      _switchValue = 1;
      notifyListeners();
      _timeLeft = mins! * 60;
      Timer.periodic(Duration(seconds: 1), (timer) {
        if (_timeLeft == 0) {
          timer.cancel();
          notifyListeners();
        } else {
          _timeLeft = _timeLeft - 1;
          notifyListeners();
        }
      });
      _stopTimer = Timer(Duration(minutes: mins), () {
        _sleepTimerMode = SleepTimerMode.unset;
        _switchValue = 0;
        if (_playerRunning) {
          _audioHandler.stop();
        }
        notifyListeners();
      });
    } else if (_sleepTimerMode == SleepTimerMode.endOfEpisode) {
      _switchValue = 1;
      _skipStart = true;
      _historyPosition = _audioPosition;
      _playlistBeingEdited++;
      await _audioHandler.replaceQueue([_mediaItem!]);
      // Loads the episode as if [_autoPlay] is disabled
      _playlistBeingEdited--;
      notifyListeners();
    }
  }

  set setSleepTimerMode(SleepTimerMode timer) {
    _sleepTimerMode = timer;
    notifyListeners();
  }

//Cancel sleep timer
  void cancelTimer() async {
    if (_sleepTimerMode == SleepTimerMode.timer) {
      _stopTimer.cancel();
      _timeLeft = 0;
      _switchValue = 0;
    } else if (_sleepTimerMode == SleepTimerMode.endOfEpisode) {
      _switchValue = 0;
      _skipStart = true;
      _historyPosition = _audioPosition;
      _playlistBeingEdited++;
      await _audioHandler.replaceQueue(_playlist.episodeIds
          .map((id) => _episodeState[id].mediaItem)
          .toList());
      await skipToIndex(_episodeIndex);
      _playlistBeingEdited--;
    }
    _sleepTimerMode = SleepTimerMode.unset;
    notifyListeners();
  }
}

class CustomAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  /// Media notification layout
  final _layoutStorage = KeyValueStorage(notificationLayoutKey);
  final _equalizer = AndroidEqualizer();
  final _loudnessEnhancer = AndroidLoudnessEnhancer();

  final int _cacheMax;

  /// JustAudio audio player
  late final AudioPlayer _player = AudioPlayer(
    // Using cache size to determine buffer size. TODO: Use [LockCachingAudioSource] for online streams to actually cache them
    // audioLoadConfiguration: AudioLoadConfiguration(
    //     androidLoadControl: AndroidLoadControl(targetBufferBytes: _cacheMax)),
    audioPipeline: AudioPipeline(
      androidAudioEffects: [
        _loudnessEnhancer,
        _equalizer,
      ],
    ),
  );

  /// Playback is paused while interrupted
  bool _interrupted = false;

  /// Media notification layout
  int? _layoutIndex;

  int get _index => _player.currentIndex!;
  Duration _position = const Duration();
  bool get hasNext => queue.value.isNotEmpty;
  MediaItem? get currentMediaItem => mediaItem.value;
  bool get playing =>
      _player.playing && _playerReady && _player.currentIndex != null;
  bool _playerReady = false;

  late StreamSubscription<PlaybackEvent> _playbackEventSubscription;
  late StreamSubscription<int?> _currentIndexSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<List<IndexedAudioSource>?> _sequenceSubscription;
  late StreamSubscription<Duration?> _durationSubscription;

  bool get playerReady => _playerReady;
  @override
  PublishSubject<Map<String, dynamic>> customEvent = PublishSubject()..add({});

  SeekTarget seekTarget = SeekTarget();
  bool seekOngoing = false;
  bool seekInputBuffer = false;

  BrowsableLibrary browsableRoot;

  CustomAudioHandler(this._cacheMax, this.browsableRoot) {
    _handleInterruption();
  }

  /// Initialises player and its listeners. Call this after construction!
  Future<void> initPlayer() async {
    await _player.setAudioSources([], preload: false);
    // _player.cacheMax = cacheMax;
    // Transmit events received from player
    playbackState.add(PlaybackState(
      androidCompactActionIndices: [0, 1, 2],
      // This is ignored on A13 / SDK33 and middle ones are shown.
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.fastForward,
        MediaAction.rewind,
      },
    ));
    _playbackEventSubscription = _player.playbackEventStream.listen(
      (event) async {
        _layoutIndex ??= await _layoutStorage.getInt();

        playbackState.add(
          playbackState.value.copyWith(
            controls: await _getControls(_layoutIndex),
            processingState: {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState]!,
            playing: _player.playing,
            updatePosition: _position,
            bufferedPosition: event.bufferedPosition,
            queueIndex: event.currentIndex ?? 0,
            speed: _player.speed,
          ),
        );
        // _player.durationStream is transmitted only on new audio load, so doesn't work when playing already loaded episodes
        if (event.duration != null) {
          customEvent.add({'duration': event.duration});
          mediaItem.add(mediaItem.value!.copyWith(duration: event.duration));
        }
      },
    );
    // Stream for currentIndex (same as playbackEvent.currentIndex)
    _currentIndexSubscription =
        _player.currentIndexStream.whereNotNull().listen(
      (index) {
        if (queue.value.isNotEmpty && index < queue.value.length) {
          queue.value[index].extras!["index"] = index;
          mediaItem.add(queue.value[index]);
        }
      },
    );
    // Positions in positionStream are smoothed from playbackEventStream
    _positionSubscription = _player.positionStream.listen((event) {
      customEvent.add({'position': event, 'index': _player.currentIndex});
      // This is necessary as _player.postition and playbackEvent.updatePosition both seem inaccurate beyond animation unsmoothness
      _position = event;
    });

    _playerReady = true;
  }

  Future<void> disposePlayer() async {
    if (_playerReady) {
      _playerReady = false;
      await _player.stop();
      await _player.clearAudioSources();
      await _player.dispose();
      await _playbackEventSubscription.cancel();
      await _currentIndexSubscription.cancel();
      await _positionSubscription.cancel();
      await _sequenceSubscription.cancel();
      await _durationSubscription.cancel();
    }
  }

  /// Handles interruptions from the os
  void _handleInterruption() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.pause:
            if (playing) {
              pause();
              _interrupted = true;
            }
            break;
          case AudioInterruptionType.duck:
            if (playing) {
              pause();
              _interrupted = true;
            }
            break;
          case AudioInterruptionType.unknown:
            if (playing) {
              pause();
              _interrupted = true;
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.pause:
            if (!playing && _interrupted) {
              play();
            }
            break;
          case AudioInterruptionType.duck:
            if (!playing && _interrupted) {
              play();
            }
            break;
          case AudioInterruptionType.unknown:
            break;
        }
        _interrupted = false;
      }
    });
    session.becomingNoisyEventStream.listen((_) {
      if (playing) pause();
    });
  }

  @override
  Future<List<MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    switch (parentMediaId) {
      case AudioService.recentRootId:
        // When the user resumes a media session, tell the system what the most
        // recently played item was.
        return mediaItem.hasValue ? [mediaItem.value!] : [];
      case AudioService.browsableRootId:
        return browsableRoot[parentMediaId];
      default:
        return browsableRoot[parentMediaId];
    }
  }

  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    await browsableRoot[mediaId];
  }

  /// Play/pause toggle
  void playPause() {
    if (_playerReady) {
      if (playing) {
        pause();
      } else {
        play();
      }
    }
  }

  @override
  Future<void> play() async {
    if (_playerReady) {
      _player.play();
      await super.play();
      await _seekRelative(Duration(seconds: -3));
    }
  }

  @override
  Future<void> pause() async {
    if (_playerReady) {
      await _player.pause();
      await super.pause();
    }
  }

  @override
  Future<void> stop() async {
    await pause();
    _player.stop();
    customEvent.add({'playerRunning': false});
    await super.stop();
  }

  @override
  Future<void> addQueueItem(MediaItem item) async {
    await addQueueItemsAt([item], queue.value.length);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> items) async {
    await addQueueItemsAt(items, queue.value.length);
  }

  /// Adds [items] to the queue at [index]. Handles live adding.
  Future<void> addQueueItemsAt(List<MediaItem> items, int index,
      {EpisodeCollision ifExists = EpisodeCollision.ignore}) async {
    List<AudioSource> sources = [for (var item in items) _itemToSource(item)];
    if (_playerReady) {
      switch (ifExists) {
        case EpisodeCollision.keepExisting:
          items.removeWhere((item) => queue.value.contains(item));
          break;
        case EpisodeCollision.replace:
          List<MediaItem> queueItems = queue.value;
          for (int i = 0; i < queueItems.length; i++) {
            int newIndex = items.indexOf(queueItems[i]);
            if (newIndex != -1 && newIndex + index != i) {
              // if (_index == i) {
              //   await pause();
              // }
              queueItems.removeAt(i);
              await _player.removeAudioSourceAt(i);
              i--;
            }
          }
          queue.add(queueItems);
          break;
        case EpisodeCollision.ignore:
          break;
      }
      if (index >= queue.value.length) {
        queue.value.addAll(items);
        await _player.addAudioSources(sources);
      } else {
        queue.value.insertAll(index, items);
        await _player.insertAudioSources(index, sources);
      }
      queue.add(queue.value);
    }
  }

  /// Removes [number] items from [index]. Handles live removing.
  Future<void> removeQueueItemsAt(int index, {int number = 1}) async {
    int end = index + number;
    queue.add(queue.value..removeRange(index, end));
    await _player.removeAudioSourceRange(
        index, end); // TODO: What happens if current is removed?
  }

  /// Moves episode at [oldIndex] to [newIndex]. Handles live adding.
  Future<void> reorderQueueItems(int oldIndex, int newIndex) async {
    if (oldIndex != newIndex) {
      List<MediaItem> reorderedQueue = queue.value;
      MediaItem reorderItem = reorderedQueue.removeAt(oldIndex);
      reorderedQueue.insert(newIndex, reorderItem);
      queue.add(reorderedQueue);
      await _player.moveAudioSource(oldIndex, newIndex);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await combinedSeek(position: position);
  }

  /// Position and or index combined seek.
  /// Use this instead of calling [AudioPlayer.seek] or [_innerCombinedSeek] directly.
  Future<void> combinedSeek({final Duration? position, int? index}) async {
    if (!playing || (position != _position) || (index != _index)) {
      seekTarget = SeekTarget(position: position, index: index);
      seekInputBuffer = true;
      if (!seekOngoing) {
        seekOngoing = true;
        await _innerCombinedSeek();
        seekOngoing = false;
      }
    }
  }

  /// Position and or index combined seek.
  /// Continuously seeks to the target specified at [seekTarget] until it is null.
  /// Only one instance of this function needs to run.
  /// Retries seeks that fail.
  Future<void> _innerCombinedSeek() async {
    Duration? position;
    int? index;
    Duration preSeekPosition = _position;
    DateTime preSeekTime = DateTime.now();
    customEvent.add({'preSeekPosition': _position.inMilliseconds});
    while (seekInputBuffer) {
      seekInputBuffer = false;
      await Future.delayed(Duration(milliseconds: 300));
    }
    while (seekTarget.isValid) {
      position = seekTarget.position;
      index = seekTarget.index;
      seekTarget = SeekTarget();
      if (position != null) _position = position;
      await _player.seek(position, index: index);
    }
    // Retry failed seek.
    if (position != null) {
      Duration timeSpan = DateTime.now().difference(preSeekTime);
      Duration errorMargin = Duration(seconds: 1);
      while (_player.position - position > timeSpan + errorMargin ||
          _player.position - position < -errorMargin) {
        log("Seek unsucessful & took $timeSpan. Before seek: $preSeekPosition, seek target: $position, seek result: ${_player.position}. Trying again...");
        preSeekPosition = _position;
        errorMargin = errorMargin * 2;
        await _player.seek(position, index: index);
      }
    }
  }

  /// Seeks current episode relative to the current position.
  /// Takes ongoing seeks into account.
  /// Clamps to the current episode's duration.
  Future<void> _seekRelative(Duration offset) async {
    Duration newPosition;
    if (seekTarget.position != null) {
      newPosition = seekTarget.position! + offset;
    } else {
      newPosition = _position + offset;
    }
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    } else if (mediaItem.value!.duration != null &&
        newPosition >= mediaItem.value!.duration!) {
      newPosition = mediaItem.value!.duration!;
    }
    combinedSeek(position: newPosition);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await combinedSeek(index: index);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await removeQueueItemsAt(index);
  }

  @override
  Future<void> skipToNext() async {
    if (queue.value.length - _index == 1) {
      await stop();
    } else {
      await skipToQueueItem(_index + 1);
    }
  }

  @override
  Future<void> fastForward() async {
    _seekRelative(AudioService.config.fastForwardInterval);
  }

  @override
  Future<void> rewind() async {
    _seekRelative(-AudioService.config.rewindInterval);
  }

  Future<void> onClick(MediaButton button) async {
    switch (button) {
      case MediaButton.media:
        playPause();
        break;
      case MediaButton.next:
        await fastForward();
        break;
      case MediaButton.previous:
        await rewind();
        break;
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem item) async {
    addQueueItemsAt([item], index);
  }

  @override
  Future<void> customAction(function, [argument]) async {
    switch (function) {
      case 'setSpeed':
        log('Argument${argument!['speed']}');
        await _player.setSpeed(argument['speed']);
        break;
      case 'setSkipSilence':
        await _setSkipSilence(argument!['skipSilence']);
        break;
      case 'setBoostVolume':
        await _setBoostVolume(argument!['boostVolume'], argument['gain']);
        break;
      default:
        super.customAction(function, argument);
    }
  }

  Future<void> replaceQueue(List<MediaItem> newQueue) async {
    // await pause();
    queue.add(newQueue);
    mediaItem.add(newQueue.first);
    List<AudioSource> sources = [
      for (var item in newQueue) _itemToSource(item)
    ];
    await _player.setAudioSources(sources, preload: false);
  }

  Future<void> _setSkipSilence(bool boo) async {
    await _player.setSkipSilenceEnabled(boo);
  }

  Future<void> _setBoostVolume(bool enabled, int gain) async {
    await _loudnessEnhancer.setEnabled(enabled);
    await _loudnessEnhancer.setTargetGain(gain / 2000);
  }

  /// Due to android 13 (sdk 33) restrictions play/pause button is always in the middle
  /// and its icon can't be changed. If included in PlaybackState systemActions or here,
  /// skipToPrevious and skipToNext are immediately to its left and right
  /// respectively, and their icons can't be changed. If they're not included,
  /// custom buttons are shown in their place. Additionally 2 custom buttons
  /// can be shown on leftmost and rightmost positions in extended notification.
  ///
  /// The list returned from this function determines the custom buttons.
  /// Play/pause, skipToPrevious, skipToNext here are placed as if in systemActions.
  /// Other buttons are placed in the lowest unoccuppied position:
  /// | 2 | 0 | play | 1 | 3 |
  ///
  /// On SDK 33 and above the function returns a different list to accomodate this.
  Future<List<MediaControl>> _getControls(int? index) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt < 33) {
      switch (index) {
        case 0:
          return [
            playing ? pauseControl : playControl,
            forwardControl,
            skipToNextControl,
            stopControl
          ];
        case 1:
          return [
            playing ? pauseControl : playControl,
            rewindControl,
            skipToNextControl,
            stopControl
          ];
        case 2:
          return [
            rewindControl,
            playing ? pauseControl : playControl,
            forwardControl,
            stopControl
          ];
        default:
          return [
            playing ? pauseControl : playControl,
            forwardControl,
            skipToNextControl,
            stopControl
          ];
      }
    } else {
      switch (index) {
        case 0:
          return [skipToNextControl, stopControl, forwardControl];
        case 1:
          return [skipToNextControl, stopControl, rewindControl];
        case 2:
          return [rewindControl, forwardControl, stopControl];
        default:
          return [skipToNextControl, stopControl, forwardControl];
      }
    }
  }

  static AudioSource _itemToSource(MediaItem item) {
    return ClippingAudioSource(
        // start: Duration(seconds: item.extras!['skipSecondsStart']),
        // end: Duration(seconds: item.extras!['skipSecondsEnd']), // This causes instant skipping problems
        child: AudioSource.uri(Uri.parse(item.id)));
  }
}

class SeekTarget {
  Duration? position;
  int? index;
  SeekTarget({this.position, this.index});

  bool get isValid => position != null || index != null;
}
