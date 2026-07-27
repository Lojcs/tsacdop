import 'dart:async';
import 'dart:developer';
import 'dart:developer' as dev;

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:just_audio/just_audio.dart';

import '../local_storage/sqflite_localpodcast.dart';
import '../type/episodebrief.dart';
import '../type/media_control.dart';
import '../type/play_histroy.dart';
import '../type/playlist.dart';
import '../util/extension_helper.dart';
import 'episode_state.dart';
import 'settings/setting_state.dart';

class AudioState extends ChangeNotifier {
  /// Database access
  final DBHelper _dbHelper = DBHelper();

  late SettingState _settingState;

  late EpisodeState _episodeState;

  set context(BuildContext context) {
    _settingState = context.settingState;
    _episodeState = context.episodeState;
  }

  /// Browsable library for android auto. Needs a context with all state providers.
  /// Set this before adding the first listener.
  BrowsableLibrary? browsableLibrary;

  AudioState();

  /// Settings varibales

  /// Unused (only takes value 0). Record plyaer position.
  final int _lastPosition = 0;

  /// Auto play next episode in playlist
  late bool _autoPlay = _settingState.autoPlay.get();

  /// Auto play next episode in playlist
  bool get effectiveAutoPlay => _autoPlay && !sleepWaitingForEpisodeEnd;

  /// Speed to play audio.
  late double _currentSpeed = _settingState.audioSpeedRatio.get();

  /// Speed value used in the speed slider while sliding.
  late double _visualSpeed = _currentSpeed;

  /// Wheter to skip silence.
  late bool _skipSilence = _settingState.skipSilence.get();

  /// Wheter volume boost is active.
  late bool _volumeBoost = _settingState.volumeBoost.get();

  /// Amount of volume boost.
  late double _volumeGain = _settingState.volumeBoostDecibels.get();

  /// Mark as listened when skipped
  bool get _markPlayedOnSkip => _settingState.markPlayedWhenSkipped.get();

  /// Interval of fast forward
  late Duration _fastForwardInterval = _settingState.fastForwardInterval.get();

  /// Interval of rewind
  late Duration _rewindInterval = _settingState.rewindInterval.get();

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

  /// Wheter running or stopped.
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

  /// History to be saved.
  PlayHistory? currentHistory;

  /// Lock to prevent updating episode index and saving history while editing playlists.
  int _playlistBeingEdited = 0;

  /// Sleep variables

  /// Auto enable sleep timer according to schedule.
  late bool _sleepTimerAuto = _settingState.sleepTimerAuto.get();

  /// Start of auto sleep timer schedule period.
  late TimeOfDay _sleepTimerScheduleStart = _settingState
      .sleepTimerScheduleStart
      .get();

  /// End of auto sleep timer schedule period.
  late TimeOfDay _sleepTimerScheduleEnd = _settingState.sleepTimerScheduleEnd
      .get();

  /// Wheter to wait the episode's end to stop playback when the sleep timer expires.
  late bool _sleepWaitEpisodeEnd = _settingState.sleepTimerWaitEpisodeEnd.get();

  /// Sleep timer interval.
  late Duration _sleepInterval = _settingState.sleepTimerInterval.get();

  /// Sleep timer schedule start timer.
  late Timer _scheduleTimer = Timer(Duration.zero, () {});

  /// Sleep timer timer.
  late Timer _sleepTimer = Timer(Duration.zero, () {});

  /// Start time of the sleep timer.
  DateTime _sleepTimerStart = DateTime.now();

  /// Wheter sleep timer is running.
  bool _sleepTimerRunning = false;

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
  );

  /// Getters

  /// Unused (only takes value 0). Record plyaer position.
  int get lastPosition => _lastPosition;

  double get currentSpeed => _currentSpeed;
  double get visualSpeed => _visualSpeed;
  bool? get skipSilence => _skipSilence;
  bool? get volumeBoost => _volumeBoost;

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

  /// Sleep timer interval
  Duration get sleepInterval => _sleepInterval;
  set sleepInterval(Duration duration) {
    _sleepInterval = duration;
    notifyListeners();
  }

  Duration get sleepTimerTimeLeft => _sleepTimerRunning
      ? _sleepInterval - DateTime.now().difference(_sleepTimerStart)
      : _sleepInterval;
  bool get sleepWaitingForEpisodeEnd =>
      _playerRunning &&
      _sleepTimerRunning &&
      _sleepWaitEpisodeEnd &&
      !_sleepTimer.isActive;
  bool get sleepTimerRunning => _sleepTimerRunning;
  bool get sleepWaitEpisodeEnd => _sleepWaitEpisodeEnd;
  set sleepWaitEpisodeEnd(bool boo) {
    _sleepWaitEpisodeEnd = boo;
    notifyListeners();
  }

  /// Assumed to be called once.
  @override
  void addListener(VoidCallback listener) async {
    await Future.delayed(Duration(seconds: 1));
    _settingState.onPlaybackChanged = onPlaybackChanged;
    await initPlaylists();
    await loadSavedPosition();
    _audioHandler = await AudioService.init(
      builder: () => CustomAudioHandler(
        this,
        _settingState,
        browsableLibrary!,
        _fastForwardInterval,
        _rewindInterval,
      ),
      config: _config,
    );
    await _audioHandler.initPlayer();
    await _audioHandler.setSpeed(_currentSpeed);
    await _audioHandler.setSkipSilence(_skipSilence);
    await _audioHandler.setVolumeBoost(_volumeBoost);
    await _audioHandler.setVolumeBoostDecibels(_volumeGain);
    await _loadPlayer();
    await _setSleepTimerSchedule();
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

  /// Called when the playback settings are changed.
  void onPlaybackChanged() async {
    final autoPlay = _settingState.autoPlay.get();
    if (_autoPlay != autoPlay) {
      _autoPlay = autoPlay;
      if (effectiveAutoPlay) {
        await _reloadWithAutoPlay();
      } else if (!sleepWaitingForEpisodeEnd) {
        await _reloadWithoutAutoPlay();
      }
    }
    final currentSpeed = _settingState.audioSpeedRatio.get();
    if (_currentSpeed != currentSpeed) {
      _currentSpeed = currentSpeed;
      await _audioHandler.setSpeed(_currentSpeed);
    }
    final skipSilence = _settingState.skipSilence.get();
    if (_skipSilence != skipSilence) {
      _skipSilence = skipSilence;
      await _audioHandler.setSkipSilence(_skipSilence);
    }
    final volumeBoost = _settingState.volumeBoost.get();
    if (_volumeBoost != volumeBoost) {
      _volumeBoost = volumeBoost;
      await _audioHandler.setVolumeBoost(_volumeBoost);
    }
    final volumeGain = _settingState.volumeBoostDecibels.get();
    if (_volumeGain != volumeGain) {
      _volumeGain = volumeGain;
      await _audioHandler.setVolumeBoostDecibels(_volumeGain);
    }
    final fastForwardInterval = _settingState.fastForwardInterval.get();
    if (_fastForwardInterval != fastForwardInterval) {
      _fastForwardInterval = fastForwardInterval;
      _audioHandler.fastForwardInterval = _fastForwardInterval;
    }
    final rewindInterval = _settingState.rewindInterval.get();
    if (_rewindInterval != rewindInterval) {
      _rewindInterval = rewindInterval;
      _audioHandler.rewindInterval = _rewindInterval;
    }
    var STchanged = false;
    final sleepTimerAuto = _settingState.sleepTimerAuto.get();
    if (_sleepTimerAuto != sleepTimerAuto) {
      _sleepTimerAuto = sleepTimerAuto;
      STchanged = true;
    }
    final sleepTimerScheduleStart = _settingState.sleepTimerScheduleStart.get();
    if (_sleepTimerScheduleStart != sleepTimerScheduleStart) {
      _sleepTimerScheduleStart = sleepTimerScheduleStart;
      STchanged = true;
    }
    final sleepTimerScheduleEnd = _settingState.sleepTimerScheduleEnd.get();
    if (_sleepTimerScheduleEnd != sleepTimerScheduleEnd) {
      _sleepTimerScheduleEnd = sleepTimerScheduleEnd;
      STchanged = true;
    }
    if (STchanged) {
      await _setSleepTimerSchedule();
    }
    notifyListeners();
  }

  /// Loads playlists
  Future<void> initPlaylists() async {
    if (_playlists.isEmpty) {
      _playlists = await _dbHelper.getPlaylists();
      for (var playlist in _playlists) {
        await _episodeState.cacheEpisodes(playlist.episodeIds);
      }
    }
  }

  /// Saves position to player state
  Future<void> saveCurrentPosition() async {
    if (!_playingTemp) {
      _savedPosition = _audioPosition;
      await _settingState.currentPlaylistId.set(_playlist.id);
      await _settingState.currentEpisodeIndex.set(_episodeIndex);
      await _settingState.currentPosition.set(
        Duration(milliseconds: _audioPosition),
      );
    }
  }

  void setCurrentHistory() => currentHistory ??= PlayHistory(
    _episodeBrief!.title,
    _episodeBrief!.enclosureUrl,
    _audioPosition ~/ 1000,
    _seekSliderValue,
  );

  /// Saves current history and position
  Future<void> saveHistory({
    bool savePosition = false,
    bool skipped = false,
  }) async {
    if (_episodeId == null) return;
    if (!_playingTemp) {
      if (savePosition) {
        await saveCurrentPosition();
      }
      setCurrentHistory();

      if (_lastHistory != currentHistory) {
        _lastHistory = currentHistory;
        if (_seekSliderValue > 0.95 || (skipped && _markPlayedOnSkip)) {
          await _episodeState.setPlayed(
            [_episodeId!],
            seconds: currentHistory!.seconds!,
            seekValue: currentHistory!.seekValue!,
          );
        } else {
          await _dbHelper.saveHistory(currentHistory!);
        }
      }
      currentHistory = null;
    }
  }

  /// Loads saved [_startPlaylist], [_startEpisodeIndex] and [_historyPosition]
  Future<void> loadSavedPosition({bool saveCurrent = false}) async {
    // Get playerstate saved in storage.
    String currentPlaylistId = _settingState.currentPlaylistId.get();
    int currentEpisodeIndex = _settingState.currentEpisodeIndex.get();
    Duration currentPosition = _settingState.currentPosition.get();
    if (saveCurrent) await saveHistory(savePosition: true);
    // Set playlist
    _startPlaylist = _playlists.firstWhere(
      (p) => p.id == currentPlaylistId,
      orElse: () => _playlists.first,
    );
    await _startPlaylist.cachePlaylist(_episodeState);
    // Set episode index
    if (_startPlaylist.isEmpty) {
      _startEpisodeIndex = 0;
    } else if (currentEpisodeIndex >= 0 &&
        currentEpisodeIndex < _startPlaylist.length) {
      if (_startPlaylist.isQueue) {
        _startEpisodeIndex = 0;
      } else {
        _startEpisodeIndex = currentEpisodeIndex;
      }
    } else {
      _startEpisodeIndex = 0;
    }
    // Load episode position
    if (_startPlaylist.isNotEmpty) {
      _historyPosition = currentPosition.inMilliseconds;
      if (_historyPosition == 0) {
        PlayHistory position = await _dbHelper.getPosition(
          _episodeState[_startEpisodeId!],
        );
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
      _playlistBeingEdited++;
      if (effectiveAutoPlay) {
        if (!samePlaylist) {
          await _audioHandler.replaceQueue(
            _playlist.episodeIds
                .map((id) => _episodeState[id].mediaItem)
                .toList(),
          );
        }
        await skipToIndex(_startEpisodeIndex);
      } else {
        await _audioHandler.replaceQueue([_mediaItem!]);
      }
      _playlistBeingEdited--;
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
  Future<void> loadEpisodeToQueue(
    int episodeId, {
    int startPosition = 0,
  }) async {
    await loadEpisodesToQueue([episodeId], startPosition: startPosition);
  }

  /// Adds episode to beginning of the queue and starts playing.
  Future<void> loadEpisodesToQueue(
    List<int> episodeIds, {
    int startPosition = 0,
  }) async {
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
        await _audioHandler.combinedSeek(
          position: Duration(milliseconds: startPosition),
        );
      }
    }
    notifyListeners();
  }

  /// Skips to the episode at specified index
  Future<void> loadEpisodeFromCurrentPlaylist(int episodeIndex) async {
    // await saveHistory();
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
    _audioState = AudioProcessingState.loading;
    _audioDuration = (_episodeBrief?.enclosureDuration ?? 0) * 1000;
    _skipStart = true;
    notifyListeners();

    if (playlist.isNotEmpty) {
      // The playlist should be set first thing so MediaItem data is ready
      // before the player is late initialized.
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
    _mediaItemSubscription ??= _audioHandler.mediaItem
        .distinct()
        .whereNotNull()
        .listen((MediaItem item) async {
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
            await _settingState.currentPlaylistId.set(_playlist.id);
            await _settingState.currentEpisodeIndex.set(_episodeIndex);
            await _settingState.currentPosition.set(
              Duration(milliseconds: _audioPosition),
            );
          }
          notifyListeners();
          await removeFirstFuture;
        });
    _playbackStateSubscription ??= _audioHandler.playbackState
        .distinct()
        .listen((PlaybackState event) async {
          Future<void> removeFirstFuture = Future(() {});
          if (!_playing && event.playing) {
            _playerRunning = true;
          } else if (_playing && !event.playing) {
            _playing = event.playing; // Before the async!
            await saveHistory(savePosition: true);
          }
          _playing = event.playing;
          // _audioPosition = event.updatePosition.inMilliseconds;
          _audioBufferedPosition = event.bufferedPosition.inMilliseconds;
          // _currentSpeed = event.speed;
          if (event.processingState == AudioProcessingState.completed &&
              _audioState != AudioProcessingState.completed) {
            _audioState = event.processingState; // Before the async!
            await _audioHandler.pause();
            if (_playingTemp) {
              _playingTemp = false;
              await loadSavedPosition(saveCurrent: false);
            } else {
              if (_playlist.isQueue) {
                if (_playlist.length > 1) {
                  await removeFromPlaylistAt(0);
                }
              } else if (_episodeIndex != _playlist.length - 1) {
                _episodeIndex++;
              }
            }
            await _audioHandler.stop();
          }
          _audioState = event.processingState;

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
    _customEventSubscription ??= _audioHandler.customEvent.distinct().listen((
      event,
    ) async {
      if (event['playerRunning'] == false && _playerRunning) {
        await saveHistory(savePosition: true);
        _historyPosition = _audioPosition;
        _playerRunning = false;
        if (_sleepTimerRunning) _cancelSleepTimer();
        notifyListeners();
      }
      if (event['preSeekPosition'] != null && !_undoSeekOngoing) {
        Duration seekAmount = Duration(
          milliseconds: (event['preSeekPosition'] - _audioPosition).abs(),
        );
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
      if (event['position'] != null &&
          (event['index'] == _episodeIndex ||
              (!effectiveAutoPlay && event['index'] == 0))) {
        _audioPosition = event['position'].inMilliseconds;
        if (_skipStart && _episodeId != null) {
          _skipStart = false;
          if (_playlistBeingEdited == 0) {
            if ((_historyPosition / _audioDuration < 0.95 &&
                _historyPosition > 10000)) {
              if (_episodeBrief!.skipSecondsStart != 0 &&
                  _historyPosition > _episodeBrief!.skipSecondsStart * 1000) {
                _undoButtonPositionsStack.add(
                  _episodeBrief!.skipSecondsStart * 1000,
                );
              }
              await seekTo(_historyPosition);
            } else if (_episodeBrief!.skipSecondsStart != 0) {
              if (_historyPosition != 0) {
                _undoButtonPositionsStack.add(_historyPosition);
              }
              await seekTo(_episodeBrief!.skipSecondsStart * 1000);
            }
          }
        }
        if (_skipEnd && _episodeId != null) {
          if (_audioPosition >
              (_audioDuration - _episodeBrief!.skipSecondsEnd * 1000)) {
            _skipEnd = false;
            _undoButtonPositionsStack.clear();
            _undoButtonPositionsStack.addAll([
              _episodeBrief!.skipSecondsEnd,
              -1,
            ]);
            await seekTo(_audioDuration);
          }
        }
        // Save position every 10 seconds
        if (_audioPosition - _savedPosition > 10000 * _currentSpeed) {
          await saveCurrentPosition();
        }
        notifyListeners();
      }
      // if (event['duration'] is Duration && _playlistBeingEdited == 0) {
      //   _audioDuration = (event['duration'] as Duration).inMilliseconds;
      //   notifyListeners();
      // }
      if (event['skipped'] != null) {
        await saveHistory(skipped: true);
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
  Future<void> addToPlaylist(
    List<int> episodeIds, {
    Playlist? playlist,
    int index = -1,
  }) async {
    Future seekFuture = Future(() {});
    if (episodeIds.isEmpty) return seekFuture;
    playlist ??= _playlist;
    if (index < 0) {
      index += playlist.length + 1;
    } else if (index > playlist.length) {
      index = playlist.length;
    }
    await playlist.cachePlaylist(_episodeState);
    EpisodeCollision ifExists = playlist.isQueue
        ? EpisodeCollision.replace
        : EpisodeCollision.ignore;

    _playlistBeingEdited++;
    if (playlist == _playlist && playlist.isNotEmpty) {
      if (effectiveAutoPlay) {
        // Add episodes to the player
        await _audioHandler.addQueueItemsAt(
          [
            for (var episodeId in episodeIds)
              _episodeState[episodeId].mediaItem,
          ],
          index,
          ifExists: ifExists,
        );
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
    await _dbHelper.updatePlaylist(playlist);
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
        limit: 100,
      );
    } else {
      newEpisodes = await _episodeState.getEpisodes(
        podcastIds: group,
        sortBy: Sorter.pubDate,
        sortOrder: SortOrder.desc,
        filterNew: true,
        limit: 100,
      );
    }
    await addToPlaylist(newEpisodes);
  }

  /// Adds episode to be played next in the current playlist
  Future<void> addToTop(int episodeId) async {
    int index = _playlist.isQueue ? 1 : 0;
    await addToPlaylist([episodeId], index: index);
  }

  /// Removes [episodeIds] from [playlist]. [playlist] defaults to [_playlist]
  Future<List<int>> removeFromPlaylist(
    List<int> episodeIds, {
    Playlist? playlist,
  }) async {
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
    _batchRemoveIndeciesFromPlaylistHelper(indicies, playlist: playlist);
    return indicies;
  }

  /// Removes episodes at [indicies] from [playlist]. [playlist] defaults to [_playlist]
  Future<List<int>> removeIndexesFromPlaylist(
    List<int> indicies, {
    Playlist? playlist,
  }) async {
    if (indicies.isEmpty) return [];
    playlist ??= _playlist;
    if (playlist.isEmpty) return [];
    await playlist.cachePlaylist(_episodeState);
    indicies.sort();
    _batchRemoveIndeciesFromPlaylistHelper(indicies, playlist: playlist);
    return indicies;
  }

  /// Helper function for batch removing sorted indexes
  Future<void> _batchRemoveIndeciesFromPlaylistHelper(
    List<int> indicies, {
    Playlist? playlist,
  }) async {
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
        await removeFromPlaylistAt(
          index1 - number + 1,
          number: number,
          playlist: playlist,
        );
      } else {
        playlist.removeEpisodesAt(
          _episodeState,
          index1 - number + 1,
          number: number,
        );
      }
      number = 0;
      index1 = index2;
    }
    await _dbHelper.updatePlaylist(playlist);
    notifyListeners();
  }

  /// Removes [number] episodes from [playlist] at [index]. [playlist] defaults to [_playlist]
  Future<void> removeFromPlaylistAt(
    int index, {
    int number = 1,
    Playlist? playlist,
  }) async {
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
    await _dbHelper.updatePlaylist(playlist);
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
  Future<void> reorderPlaylist(
    int oldIndex,
    int newIndex, {
    Playlist? playlist,
  }) async {
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
        setCurrentHistory();
        await _audioHandler.reorderQueueItems(oldIndex, newIndex);
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
    await _dbHelper.updatePlaylist(playlist);
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
    List<int> indecies = [];
    for (int i = 0; i < _playlist.length; i++) {
      if (_playlist[i] == episode.id) {
        indecies.add(i);
      }
    }
    if (indecies.isNotEmpty) {
      _playlistBeingEdited++;
      if (indecies.remove(_episodeIndex)) {
        // Currently playing episode is replaced
        if (effectiveAutoPlay) {
          int index = _episodeIndex;
          await _audioHandler.addQueueItemsAt([episode.mediaItem], index + 1);
          await _audioHandler.combinedSeek(
            position: Duration(milliseconds: _audioPosition),
            index: index + 1,
          );
          await _audioHandler.removeQueueItemsAt(index);
        } else {
          await _audioHandler.addQueueItemsAt([episode.mediaItem], 1);
          await _audioHandler.combinedSeek(
            position: Duration(milliseconds: _audioPosition),
            index: 1,
          );
          await _audioHandler.removeQueueItemsAt(0);
        }
      }
      // Another episode is replaced.
      if (effectiveAutoPlay) {
        for (int i in indecies) {
          await _audioHandler.addQueueItemsAt([episode.mediaItem], i + 1);
          await _audioHandler.removeQueueItemsAt(i);
        }
      }
      _playlistBeingEdited--;
    }
  }

  /// Custom playlist management.

  /// Adds playlist to playlists
  Future<void> addPlaylist(Playlist playlist) async {
    _playlists.add(playlist);
    await _dbHelper.addPlaylist(playlist);
    notifyListeners();
  }

  /// Deletes playlist from playlists. Doesn't unload it from player.
  Future<void> deletePlaylist(Playlist playlist) async {
    _playlists.remove(playlist);
    await _dbHelper.deletePlaylist(playlist.id);
    if (playlist.isLocal) {
      await _episodeState.deleteEpisodes(playlist.episodeIds);
    }
    notifyListeners();
  }

  /// Clears all episodes in playlist
  void clearPlaylist(Playlist playlist) {
    removeFromPlaylistAt(0, number: playlist.length, playlist: playlist);
  }

  /// Since users can't see the playlist id, the name should also be unique.
  bool playlistExists(String? name) {
    for (var p in _playlists) {
      if (p.name == name) return true;
    }
    return false;
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
        await _audioHandler.skipToNext(true);
      } else {
        if (_markPlayedOnSkip) {
          await _episodeState.setPlayed(
            [_episodeId!],
            seconds: _audioPosition ~/ 1000,
            seekValue: _seekSliderValue,
          );
        }
        if (_playlist.isQueue) {
          _playlist.removeEpisodesAt(_episodeState, 0);
        } else {
          _startEpisodeIndex = _episodeIndex + 1;
        }
        await loadEpisodeHistoryPosition();
        await playFromStart();
      }
    } else {
      await _audioHandler.skipToNext(true);
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
        position: Duration(
          milliseconds: _undoButtonPositionsStack.removeLast(),
        ),
      );
      _undoSeekOngoing = false;
    }
  }

  /// Set player speed.
  Future<void> setVisualSpeed(double speed) async {
    _visualSpeed = speed;
    notifyListeners();
  }

  /// Reloads the current playlist with autoPlay enabled.
  Future<void> _reloadWithAutoPlay() async {
    dev.log("Reloading player with autoPlay enabled.");
    _playlistBeingEdited++;
    final position = _audioPosition - 3;
    await _audioHandler.replaceQueue(
      _playlist.episodeIds.map((id) => _episodeState[id].mediaItem).toList(),
    );
    await _audioHandler.combinedSeek(
      index: _startEpisodeIndex,
      position: Duration(milliseconds: position),
    );
    _playlistBeingEdited--;
  }

  /// Reloads the current playlist with autoPlay disabled.
  Future<void> _reloadWithoutAutoPlay() async {
    dev.log("Reloading player with autoPlay disabled.");
    _playlistBeingEdited++;
    final position = _audioPosition - 3;
    await _audioHandler.replaceQueue([_mediaItem!]);
    await _audioHandler.combinedSeek(
      position: Duration(milliseconds: position),
    );
    _playlistBeingEdited--;
  }

  /// Schedules or starts the sleep timer based on the variables.
  Future<void> _setSleepTimerSchedule() async {
    if (_sleepTimerAuto) {
      final now = DateTime.now();
      if (TimeOfDay.fromDateTime(
        now,
      ).isBetween(_sleepTimerScheduleStart, _sleepTimerScheduleEnd)) {
        await _startSleepTimerAutomatically();
      } else {
        await _cancelSleepTimerAutomatically();
      }
    }
  }

  /// Starts sleep timer and schedules scheduled end.
  Future<void> _startSleepTimerAutomatically() async {
    if (!_sleepTimerRunning) await _startSleepTimer();
    await sleepTimerScheduleEnd();
  }

  /// Cancels sleep timer and schedules scheduled start.
  Future<void> _cancelSleepTimerAutomatically() async {
    await _cancelSleepTimer();
    await sleepTimerScheduleStart();
  }

  /// Starts sleep timer and disables sleep timer schedule for one day or app restart.
  Future<void> startSleepTimerExplicitly() async {
    if (!_sleepTimerRunning) await _startSleepTimer();
    await sleepTimerScheduleStart(Duration(days: 1));
  }

  /// Cancels sleep timer and disables sleep timer schedule for one day or app restart.
  Future<void> cancelSleepTimerExplicitly() async {
    await _cancelSleepTimer();
    await sleepTimerScheduleStart(Duration(days: 1));
  }

  /// Schedules the start of auto sleep timer. No checks.
  Future<void> sleepTimerScheduleStart([
    Duration deadTime = Duration.zero,
  ]) async {
    final now = DateTime.now();
    final timerDuration = _sleepTimerScheduleStart
        .after(now.add(deadTime))
        .difference(now);
    dev.log("Sleep timer schedule start timer: ${timerDuration.toString()}");
    _scheduleTimer.cancel();
    _scheduleTimer = Timer(timerDuration, _startSleepTimerAutomatically);
  }

  /// Schedules the end of auto sleep timer. No checks.
  Future<void> sleepTimerScheduleEnd([
    Duration deadTime = Duration.zero,
  ]) async {
    final now = DateTime.now();
    final timerDuration = _sleepTimerScheduleEnd
        .after(now.add(deadTime))
        .difference(now);
    dev.log("Sleep timer schedule end timer: ${timerDuration.toString()}");
    _scheduleTimer.cancel();
    _scheduleTimer = Timer(timerDuration, _cancelSleepTimerAutomatically);
  }

  /// Starts sleep timer. No checks.
  Future<void> _startSleepTimer() async {
    _sleepTimerRunning = true;
    _sleepTimerStart = DateTime.now();
    _sleepTimer = Timer(_sleepInterval, _onSleepTimerExpired);
    notifyListeners();
  }

  /// Cancels sleep timer. No checks.
  Future<void> _cancelSleepTimer() async {
    _sleepTimer.cancel();
    if (sleepWaitingForEpisodeEnd) {
      if (_autoPlay) {
        await _reloadWithAutoPlay();
      }
    }
    _sleepTimerRunning = false;
    notifyListeners();
  }

  /// What to do when sleep timer expires.
  Future<void> _onSleepTimerExpired() async {
    if (_sleepWaitEpisodeEnd) {
      if (_autoPlay) {
        await _reloadWithoutAutoPlay();
      }
    } else {
      _sleepTimerRunning = false;
      if (_playerRunning) {
        await _audioHandler.stop();
      }
    }
    notifyListeners();
  }
}

/// Samsung and Google treat the media control indicies differently.
/// These are the mappings from  stored indicies to the indicies the devices want.
final Map<String, List<int>> manufacturerControlMapper = {
  "samsung": [1, 2, 0, 3],
  "Google": [0, 1, 2, 3],
};

class CustomAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _equalizer = AndroidEqualizer();
  final _loudnessEnhancer = AndroidLoudnessEnhancer();

  Duration fastForwardInterval;
  Duration rewindInterval;

  /// JustAudio audio player
  late final AudioPlayer _player = AudioPlayer(
    // Using cache size to determine buffer size. TODO: Use [LockCachingAudioSource] for online streams to actually cache them
    // audioLoadConfiguration: AudioLoadConfiguration(
    //     androidLoadControl: AndroidLoadControl(targetBufferBytes: _cacheMax)),
    audioPipeline: AudioPipeline(
      androidAudioEffects: [_loudnessEnhancer, _equalizer],
    ),
  );

  /// Playback is paused while interrupted
  bool _interrupted = false;

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

  SeekTarget seekTarget = SeekTarget();

  /// Don't update time or start another inner seek while seek is ongoing.
  bool seekOngoing = false;

  /// Buffer seeks for 300 ms.
  /// This prevents rapid seeks causing lag
  /// And seeks too soon after media changes from not being effective.
  bool seekInputBuffer = false;

  final SettingState settings;
  final AudioState audio;

  BrowsableLibrary browsableRoot;

  CustomAudioHandler(
    this.audio,
    this.settings,
    this.browsableRoot,
    this.fastForwardInterval,
    this.rewindInterval,
  ) {
    _handleInterruption();
  }

  /// Audio player audio source
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(
    useLazyPreparation: true,
    shuffleOrder: DefaultShuffleOrder(),
    children: [],
  );

  late String manufacturer;

  /// Initialises player and its listeners. Call this after construction!
  Future<void> initPlayer() async {
    await _player.setAudioSource(_playlist, preload: false);
    // _player.cacheMax = cacheMax;
    // Transmit events received from player
    playbackState.add(
      PlaybackState(
        androidCompactActionIndices: [0, 1, 2],
        // This is ignored on A13 / SDK33 and middle ones are shown.
      ),
    );
    manufacturer = (await DeviceInfoPlugin().androidInfo).manufacturer;
    final mapper = manufacturerControlMapper.containsKey(manufacturer)
        ? manufacturerControlMapper[manufacturer]!
        : manufacturerControlMapper["Google"]!;
    _playbackEventSubscription = _player.playbackEventStream.distinct().listen((
      event,
    ) async {
      final layout = settings.notificationLayout.get();
      var remapped = layout.mapIndexed((i, c) => layout[mapper[i]]).toList();

      final last = remapped.lastIndexWhere((e) => e is! NoneControl);
      remapped = remapped.sublist(0, last + 1);
      playbackState.add(
        playbackState.value.copyWith(
          controls: remapped,
          systemActions: {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
            MediaAction.fastForward,
            MediaAction.rewind,
            if (remapped.any((e) => e.action == .skipToPrevious))
              MediaAction.skipToPrevious,
            if (remapped.any((e) => e.action == .skipToNext))
              MediaAction.skipToNext,
          },
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
    });
    // Stream for currentIndex (same as playbackEvent.currentIndex)
    _currentIndexSubscription = _player.currentIndexStream
        .whereNotNull()
        .listen((index) {
          if (queue.value.isNotEmpty && index < queue.value.length) {
            queue.value[index].extras!["index"] = index;
            mediaItem.add(queue.value[index]);
          }
        });
    // Positions in positionStream are smoothed from playbackEventStream
    _positionSubscription = _player.positionStream.listen((event) {
      if (!seekOngoing) {
        customEvent.add({'position': event, 'index': _player.currentIndex});
        // This is necessary as _player.postition and playbackEvent.updatePosition both seem inaccurate beyond animation unsmoothness
      }
      _position = event;
    });

    _playerReady = true;
  }

  Future<void> disposePlayer() async {
    if (_playerReady) {
      _playerReady = false;
      await _player.stop();
      await _playlist.clear();
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
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
  Future<void> setSkipSilence(bool enabled) =>
      _player.setSkipSilenceEnabled(enabled);

  Future<void> setVolumeBoost(bool enabled) =>
      _loudnessEnhancer.setEnabled(enabled);

  Future<void> setVolumeBoostDecibels(double gain) => _loudnessEnhancer
      .setTargetGain(gain * 10); // Remove the factor when justaudio is updated.

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
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
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
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
  Future<void> addQueueItemsAt(
    List<MediaItem> items,
    int index, {
    EpisodeCollision ifExists = EpisodeCollision.ignore,
  }) async {
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
              await _playlist.removeAt(i);
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
        await _playlist.addAll(sources);
      } else {
        queue.value.insertAll(index, items);
        await _playlist.insertAll(index, sources);
      }
      queue.add(queue.value);
    }
  }

  /// Removes [number] items from [index]. Handles live removing.
  Future<void> removeQueueItemsAt(int index, {int number = 1}) async {
    int end = index + number;
    queue.add(queue.value..removeRange(index, end));
    await _playlist.removeRange(
      index,
      end,
    ); // TODO: What happens if current is removed?
  }

  /// Moves episode at [oldIndex] to [newIndex]. Handles live adding.
  Future<void> reorderQueueItems(int oldIndex, int newIndex) async {
    if (oldIndex != newIndex) {
      List<MediaItem> reorderedQueue = queue.value;
      MediaItem reorderItem = reorderedQueue.removeAt(oldIndex);
      reorderedQueue.insert(newIndex, reorderItem);
      queue.add(reorderedQueue);
      await _playlist.move(oldIndex, newIndex);
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
        try {
          await _innerCombinedSeek();
        } catch (e) {
          seekOngoing = false;
          rethrow;
        }
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
        log(
          "Seek unsucessful & took $timeSpan. Before seek: $preSeekPosition, seek target: $position, seek result: ${_player.position}. Trying again...",
        );
        preSeekPosition = _player.position;
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
    await combinedSeek(position: newPosition);
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
  Future<void> skipToNext([bool actually = false]) async {
    if (actually) {
      customEvent.add({
        'skipped': (
          mediaItem.value!.extras!['episodeId'],
          _position,
          _player.duration,
        ),
      });
      if (queue.value.length - _index == 1) {
        await stop();
      } else {
        await skipToQueueItem(_index + 1);
      }
    } else {
      // I hate this solution so much. This warrants rewriting the audio state.
      await audio.skipToNext();
    }
  }

  @override
  Future<void> fastForward() async {
    _seekRelative(fastForwardInterval);
  }

  @override
  Future<void> rewind() async {
    _seekRelative(-rewindInterval);
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

  Future<void> replaceQueue(List<MediaItem> newQueue) async {
    // await pause();
    queue.add(newQueue);
    mediaItem.add(newQueue.first);
    List<AudioSource> sources = [
      for (var item in newQueue) _itemToSource(item),
    ];
    _playlist = ConcatenatingAudioSource(
      useLazyPreparation: false,
      shuffleOrder: DefaultShuffleOrder(),
      children: sources,
    );
    await _player.setAudioSource(_playlist, preload: false);
  }

  static AudioSource _itemToSource(MediaItem item) {
    return ClippingAudioSource(
      // start: Duration(seconds: item.extras!['skipSecondsStart']),
      // end: Duration(seconds: item.extras!['skipSecondsEnd']), // This causes instant skipping problems
      child: AudioSource.uri(Uri.parse(item.id)),
    );
  }
}

class SeekTarget {
  Duration? position;
  int? index;
  SeekTarget({this.position, this.index});

  bool get isValid => position != null || index != null;
}
