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
enum SleepTimerMode { endOfEpisode, timer, undefined }

/// Audio player height
enum PlayerHeight { short, mid, tall }

class AudioPlayerNotifier extends ChangeNotifier {
  /// Database access
  final DBHelper _dbHelper = DBHelper();

  /// Episode state propogation
  late final EpisodeState _episodeState;

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

  /// List of [PlaylistEntity]s // TODO: Move this to sql maybe?
  final _playlistsStorage = const KeyValueStorage(playlistsAllKey);

  /// [Last playing playlist id, episode enclosure url, position (unused)]
  final _playerStateStorage = const KeyValueStorage(playerStateKey);

  /// Cache size in bytes
  final cacheStorage = const KeyValueStorage(cacheMaxKey);

  /// Settings varibales

  /// Unused (only takes value 0). Record plyaer position.
  int _lastPosition = 0;

  /// Auto play next episode in playlist
  late bool _autoPlay;

  /// Auto play next episode in playlist
  bool get effectiveAutoPlay => _autoPlay && !_stopOnEndOfEpisode;

  /// Default time for sleep timer (mins)
  late int _defaultTimer;

  /// Auto stop at the end of episode when you start play at scheduled time.
  late bool _autoSleepTimer;

  /// Sleep timer mode.
  SleepTimerMode _sleepTimerMode = SleepTimerMode.undefined;

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

  /// Currently playing episode.
  EpisodeBrief? get _episode =>
      _playlist.isNotEmpty && _playlist.episodes.isNotEmpty
          ? _playlist.episodes[_episodeIndex]
          : null;

  EpisodeBrief? get _startEpisode =>
      _startPlaylist.isNotEmpty && _startPlaylist.episodes.isNotEmpty
          ? _startPlaylist.episodes[_startEpisodeIndex]
          : null;

  /// Index of currently playing episode
  int _episodeIndex = 0;

  /// Episode index to start playback from
  late int _startEpisodeIndex;

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
  /// -1 goes back an episode (loads [_lastEpisode] if queue)
  /// and skips to the next item in stack
  List<int> _undoButtonPositionsStack = [];

  /// Episode last removed from queue
  EpisodeBrief? _lastEpisode;

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

  /// Set true if sleep timer mode is end of episode.
  bool _stopOnEndOfEpisode = false;

  /// Sleep timer timer.
  late Timer _stopTimer;

  /// Sleep timer time left.
  int _timeLeft = 0;

  /// (Unused) Start sleep timer.
  bool _startSleepTimer = false;

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
        androidNotificationChannelName: 'Tsacdop',
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
  double? get currentSpeed => _currentSpeed;
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
  EpisodeBrief? get lastEpisode => _lastEpisode;

  int? get episodeIndex => _episodeIndex;
  int? get startEpisodeIndex => _startEpisodeIndex;
  EpisodeBrief? get episode => _episode;
  Playlist get playlist => _playlist;
  Playlist get startPlaylist => _startPlaylist;
  List<Playlist> get playlists => _playlists;
  Playlist get queue => _queue;
  AudioProcessingState get audioState => _audioState;
  bool get buffering => _audioState != AudioProcessingState.ready;

  String? get remoteErrorMessage => _remoteErrorMessage;

  /// Set true if sleep timer mode is end of episode.
  bool get stopOnComplete => _stopOnEndOfEpisode;

  /// Sleep timer time left.
  int get timeLeft => _timeLeft;
  bool get sleepTimerActive => _startSleepTimer;
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
    _playlist = _startPlaylist;
    _episodeIndex = _startEpisodeIndex;
    _audioPosition = _historyPosition;
    int cacheMax =
        await cacheStorage.getInt(defaultValue: (1024 * 1024 * 200).toInt());
    _audioHandler = await AudioService.init(
        builder: () => CustomAudioHandler(cacheMax), config: _config);
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
    int _mode = await (_autoSleepTimerModeStorage.getInt());
    _sleepTimerMode = SleepTimerMode.values[_mode];
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
      List<PlaylistEntity> playlistEntities =
          await _playlistsStorage.getPlaylists();
      _playlists = [
        for (var entity in playlistEntities) Playlist.fromEntity(entity)
      ];
      // Seems unused
      await KeyValueStorage(lastWorkKey).saveInt(0);
    }
  }

  /// Saves position to player state
  Future<void> saveCurrentPosition() async {
    if (!_playingTemp && _playerRunning) {
      _savedPosition = _audioPosition;
      await _playerStateStorage.savePlayerState(
          _playlist.id, _episodeIndex, _audioPosition);
    }
  }

  /// Saves current history and position
  Future<void> saveHistory({bool savePosition = false}) async {
    if (!_playingTemp && _playerRunning) {
      if (savePosition) {
        await saveCurrentPosition();
      }
      PlayHistory history = PlayHistory(_episode!.title, _episode!.enclosureUrl,
          _audioPosition ~/ 1000, _seekSliderValue);
      if (_lastHistory != history) {
        _lastHistory = history;
        if (_seekSliderValue > 0.95) {
          await _episodeState.setListened([_episode!],
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
    await _startPlaylist.getPlaylist();
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
        PlayHistory position = await _dbHelper.getPosition(_startEpisode!);
        _historyPosition = position.seconds! * 1000;
      }
    }
    notifyListeners();
  }

  /// Loads the saved position of the provided or start episode to [_historyPosition]
  Future<void> loadEpisodeHistoryPosition({EpisodeBrief? episodeBrief}) async {
    if (episodeBrief == null) episodeBrief = _startEpisode;
    PlayHistory position = await _dbHelper.getPosition(episodeBrief!);
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
    } else if (_episode!.skipSecondsStart != 0) {
      _audioPosition = _episode!.skipSecondsStart * 1000;
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
      if (_startPlaylist.episodes.isEmpty) {
        await _startPlaylist.getPlaylist();
      }
      _playlist = _startPlaylist;
      _episodeIndex = _startEpisodeIndex;
      if (_playerRunning) {
        _loadStartPosition();
        _audioDuration = _startEpisode!.enclosureDuration! * 1000;
        if (samePlaylist) {
          _playlistBeingEdited++;
          await skipToIndex(_startEpisodeIndex);
          _playlistBeingEdited--;
        } else {
          if (effectiveAutoPlay) {
            _playlistBeingEdited++;
            await _audioHandler.replaceQueue(_startPlaylist.mediaItems);
            await skipToIndex(_startEpisodeIndex);
            _playlistBeingEdited--;
          } else {
            _playlistBeingEdited++;
            await _audioHandler.replaceQueue([_episode!.mediaItem]);
            _playlistBeingEdited--;
          }
        }
      } else {
        await _startAudioService();
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
  Future<void> playlistLoad(Playlist playlist) async {
    if (playlist.isNotEmpty) {
      await saveHistory();
      _startPlaylist = playlist;
      _startEpisodeIndex = 0;
      _historyPosition = 0;
      _lastEpisode = null;
      await playFromStart();
      await _audioHandler.play();
      await saveHistory(savePosition: true);
    }
  }

  /// Temporarily loads an episode from search // TODO: make sure the playlist is deleted once the episode finishes
  Future<void> searchEpisodeLoad(EpisodeBrief episode) async {
    Playlist tempPlaylist = Playlist(
      // TODO: add search playlist flag like local?
      "Search",
      episodeUrlList: [episode.enclosureUrl],
      episodes: [episode],
    );
    _playingTemp = true;
    await saveHistory(savePosition: true);
    await playlistLoad(tempPlaylist);
  }

  /// Adds episode to beginning of the queue and starts playing.
  Future<void> loadEpisodeToQueue(EpisodeBrief episode,
      {int startPosition = 0}) async {
    episode = await episode.copyWithFromDB(newFields: [
      EpisodeField.enclosureDuration,
      EpisodeField.enclosureSize,
      EpisodeField.mediaId,
      EpisodeField.primaryColor,
      EpisodeField.isExplicit,
      EpisodeField.isNew,
      EpisodeField.skipSecondsStart,
      EpisodeField.skipSecondsEnd,
      EpisodeField.episodeImage,
      EpisodeField.podcastImage,
      EpisodeField.chapterLink
    ], keepExisting: true);
    await saveHistory();

    await addToPlaylist([episode], playlist: _queue, index: 0);
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
    await _episodeState.unsetNew([episode]);
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

  /// Starts the audio service and player
  Future<void> _startAudioService() async {
    assert(!_playerRunning);
    // Set initial variables
    _stopOnEndOfEpisode = false;
    _sleepTimerMode = SleepTimerMode.undefined;
    _switchValue = 0;
    _audioState = AudioProcessingState.loading;
    _audioDuration = _episode!.enclosureDuration! * 1000;
    _playerRunning = true;
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

    //Check autoplay setting, if true only add one episode, else add playlist.
    _playlist = _startPlaylist;
    _episodeIndex = _startEpisodeIndex;
    if (effectiveAutoPlay) {
      await _audioHandler.replaceQueue(_startPlaylist.mediaItems);
      // await _audioHandler.skipToQueueItem(_episodeIndex!);
    } else {
      await _audioHandler.replaceQueue([_startEpisode!.mediaItem]);
    }
    await skipToIndex(_startEpisodeIndex);
    await _audioHandler.play();

    //Check auto sleep timer setting
    if (_autoSleepTimer) {
      int currentTime = DateTime.now().hour * 60 + DateTime.now().minute;
      if ((_startTime > _endTime &&
              (currentTime > _startTime || currentTime < _endTime)) ||
          ((_startTime < _endTime) &&
              (currentTime > _startTime && currentTime < _endTime))) {
        sleepTimer(_defaultTimer);
      }
    }
    // These listeners keep the AudioPlayerNotifier state in sync with the CustomAudioHandler.
    // History is saved if:
    // - Playing episode changes
    // - Playback is paused
    // - Playback is stopped
    // - Playing episode changes due to playlist editing
    // First two are only in effect if _playlistBeingEdited is 0, since playing episode might
    // change erratically while playlist editing functions are running and they handle history saving on their own.
    // Even though this should cover all cases player state (not history) is also saved every 10 seconds just in case
    // These listeners also handle queue behavior, automatic history skeeking and adding positions to undo stack.
    if (_mediaItemSubscription == null) {
      _mediaItemSubscription = _audioHandler.mediaItem.distinct().listen(
        (MediaItem? item) async {
          Future<void> removeFirstFuture = Future(() {});
          // Handle episode change
          if (item!.extras!["index"] != null) {
            int newIndex = item.extras!["index"];
            if (item.id != _episode!.mediaId) {}
            if (_playlistBeingEdited == 0) {
              if (item.id != _episode!.mediaId) {
                await saveHistory();
                if (_playlist.isQueue && newIndex - 1 == _episodeIndex) {
                  // Remove played episode from playlist when playlist is queue
                  removeFirstFuture = removeFromPlaylistAt(0);
                  _lastEpisode = _episode;
                }
              }
              _episodeIndex = newIndex;
            } else {
              _undoButtonPositionsStack.clear();
            }
            await loadEpisodeHistoryPosition(episodeBrief: _episode);
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
    }
    if (_playbackStateSubscription == null) {
      _playbackStateSubscription = _audioHandler.playbackState
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
          _stopOnEndOfEpisode = false;
          await _audioHandler.pause();
          if (_playingTemp) {
            _playingTemp = false;
            await loadSavedPosition(saveCurrent: false);
          } else {
            if (_playlist.isQueue) {
              await removeFromPlaylistAt(0);
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
    }
    if (_customEventSubscription == null) {
      _customEventSubscription =
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
              seekAmount < AudioService.config.rewindInterval) return;
          _undoButtonPositionsStack.add(event['preSeekPosition']);
          if (_clearUndoSeekTimer != null) _clearUndoSeekTimer!.cancel();
          _clearUndoSeekTimer = Timer(Duration(seconds: 30), () {
            _undoButtonPositionsStack.clear();
            _lastEpisode = null;
          });
        }
        // Set seekbar position, handle skipping start and end.
        // Ignore position updates if index doesn't match current index so that history saving is consistent
        if (event['position'] != null && event['index'] == _episodeIndex) {
          _audioPosition = event['position'].inMilliseconds;
          if (_skipStart) {
            _skipStart = false;
            if (_historyPosition / _audioDuration < 0.95 &&
                _historyPosition > 10000) {
              if (_episode!.skipSecondsStart != 0 &&
                  _historyPosition > _episode!.skipSecondsStart * 1000) {
                _undoButtonPositionsStack
                    .add(_episode!.skipSecondsStart * 1000);
              }
              await seekTo(_historyPosition);
            } else if (_episode!.skipSecondsStart != 0) {
              if (_historyPosition != 0) {
                _undoButtonPositionsStack.add(_historyPosition);
              }
              await seekTo(_episode!.skipSecondsStart * 1000);
            }
          }
          if (_skipEnd) {
            if (_audioPosition >
                (_audioDuration - _episode!.skipSecondsEnd * 1000)) {
              _skipEnd = false;
              _undoButtonPositionsStack.clear();
              _undoButtonPositionsStack.addAll([_episode!.skipSecondsEnd, -1]);
              await seekTo(_audioDuration);
            }
          }
          // Save position every 10 seconds
          if (_audioPosition - _savedPosition > 10000 * _currentSpeed) {
            await saveCurrentPosition();
          }
          notifyListeners();
        }
        if (event['duration'] != null && _playlistBeingEdited == 0) {
          _audioDuration = event['duration'].inMilliseconds;
          notifyListeners();
        }
      });
    }
  }

  // Queue management

  /// Helper function for when [effectiveAutoPlay] is disabled.
  Future<void> _replaceFirstQueueItem(EpisodeBrief episodeBrief) async {
    await _audioHandler.pause();
    await saveHistory();
    await loadEpisodeHistoryPosition(episodeBrief: episodeBrief);
    _loadStartPosition();
    await _audioHandler.addQueueItemsAt([episodeBrief.mediaItem], 1);
    await _audioHandler.removeQueueItemsAt(0);
    await _audioHandler.play();
  }

  /// Adds [episodes] to [playlist]. Handles adding to live playlist.
  /// Negative index indexes from the end.
  /// Defaults to to index -1 of [_playlist].
  Future<void> addToPlaylist(List<EpisodeBrief> episodes,
      {Playlist? playlist, int index = -1}) async {
    Future seekFuture = Future(() {});
    if (episodes.length == 0) return seekFuture;
    if (playlist == null) playlist = _playlist;
    if (index < 0)
      index += playlist.length + 1;
    else if (index > playlist.length) index = playlist.length;
    if (playlist.isNotEmpty && playlist.episodes.isEmpty)
      playlist.getPlaylist();
    for (int i = 0; i < episodes.length; i++) {
      // TODO: Add batch copyWithFromDB option for speed
      episodes[i] = await episodes[i].copyWithFromDB(newFields: [
        EpisodeField.enclosureDuration,
        EpisodeField.enclosureSize,
        EpisodeField.mediaId,
        EpisodeField.primaryColor,
        EpisodeField.isExplicit,
        EpisodeField.isNew,
        EpisodeField.skipSecondsStart,
        EpisodeField.skipSecondsEnd,
        EpisodeField.episodeImage,
        EpisodeField.podcastImage,
        EpisodeField.chapterLink
      ], keepExisting: true);
    }
    await _episodeState.unsetNew(episodes);
    EpisodeCollision ifExists =
        playlist.isQueue ? EpisodeCollision.Replace : EpisodeCollision.Ignore;

    _playlistBeingEdited++;
    if (playlist == _playlist && _playerRunning) {
      if (effectiveAutoPlay) {
        // Add episodes to the player
        await _audioHandler.addQueueItemsAt(
            [for (var episode in episodes) episode.mediaItem], index,
            ifExists: ifExists);
      }
      if (_episodeIndex < index) {
        // Current episode is not affected
      } else {
        if (playlist.isQueue) {
          // Play newly inserted episodes.
          if (effectiveAutoPlay) {
            await saveHistory();
            await loadEpisodeHistoryPosition(episodeBrief: episodes[0]);
            _loadStartPosition();
            seekFuture = _audioHandler.skipToQueueItem(0);
          } else {
            await _replaceFirstQueueItem(episodes[0]);
          }
        } else {
          _episodeIndex = _episodeIndex + episodes.length;
        }
      }
    }
    playlist.addEpisodes(episodes, index, ifExists: ifExists);
    await _savePlaylists();
    if (playlist == _playlist &&
        !_playerRunning &&
        _playlist.isQueue &&
        index == 0) {
      loadEpisodeHistoryPosition();
      _loadStartPosition();
    }
    notifyListeners();
    await seekFuture;
    _playlistBeingEdited--;
  }

  /// Adds episodes at the end of the current playlist
  Future<void> addNewEpisode(List<String> group) async {
    var newEpisodes = <EpisodeBrief>[];
    if (group.isEmpty) {
      newEpisodes = await _dbHelper.getEpisodes(
          optionalFields: [EpisodeField.mediaId],
          sortBy: Sorter.pubDate,
          sortOrder: SortOrder.DESC,
          filterNew: true,
          limit: 100);
    } else {
      newEpisodes = await _dbHelper.getEpisodes(
          optionalFields: [EpisodeField.mediaId],
          feedIds: group,
          sortBy: Sorter.pubDate,
          sortOrder: SortOrder.DESC,
          filterNew: true,
          limit: 100);
    }
    await addToPlaylist(newEpisodes);
  }

  /// Adds episode to be played next in the current playlist
  Future<void> addToTop(EpisodeBrief episode) async {
    int index = (_playerRunning && _playlist.isQueue) ? 1 : 0;
    await addToPlaylist([episode], index: index);
  }

  /// Removes [episodes] from [playlist]. [playlist] defaults to [_playlist]
  Future<List<int>> removeFromPlaylist(List<EpisodeBrief> episodes,
      {Playlist? playlist}) async {
    if (episodes.length == 0) return [];
    if (playlist == null) playlist = _playlist;
    if (playlist.isEmpty) return [];
    if (playlist.episodes.isEmpty) await playlist.getPlaylist();
    List<int> indexes = [];
    // Find episode indexes
    for (int i = 0; i < playlist.episodes.length; i++) {
      for (var episode in episodes) {
        var delEpisode = playlist.episodes[i];
        if (episode == delEpisode) {
          indexes.add(i);
          break;
        }
      }
    }
    _batchRemoveIndexesFromPlaylistHelper(indexes);
    return indexes;
  }

  /// Removes episodes at [indexes] from [playlist]. [playlist] defaults to [_playlist]
  Future<List<int>> removeIndexesFromPlaylist(List<int> indexes,
      {Playlist? playlist}) async {
    if (indexes.length == 0) return [];
    if (playlist == null) playlist = _playlist;
    if (playlist.isEmpty) return [];
    if (playlist.episodes.isEmpty) await playlist.getPlaylist();
    indexes.sort();
    _batchRemoveIndexesFromPlaylistHelper(indexes);
    return indexes;
  }

  /// Helper function for batch removing sorted indexes
  Future<void> _batchRemoveIndexesFromPlaylistHelper(List<int> indexes) async {
    // Remove items in batches starting from the end
    int? index1;
    int? index2;
    int number = 0;
    index1 = indexes.removeLast();
    while (index1 != null) {
      do {
        number++;
        if (indexes.isNotEmpty) {
          index2 = indexes.removeLast();
        } else {
          index2 = null;
          break;
        }
      } while (index1 == index2 + number);

      if (playlist == _playlist && _playerRunning) {
        await removeFromPlaylistAt(index1 - number + 1,
            number: number, playlist: playlist);
      } else {
        playlist.removeEpisodesAt(index1 - number + 1, number: number);
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
    if (playlist == null) playlist = _queue;
    if (playlist.isEmpty) return seekFuture;
    if (index < 0) index += playlist.length + 1;
    final int end = index + number;
    if (end > playlist.length || number < 0) return seekFuture;
    if (playlist.episodes.isEmpty) await playlist.getPlaylist();

    _playlistBeingEdited++;
    if (playlist == _playlist && _playerRunning) {
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
            await loadEpisodeHistoryPosition(
                episodeBrief: playlist.episodes[end]);
            _loadStartPosition();
            // Remove episodes from the player
            await _audioHandler.removeQueueItemsAt(index, number: number);
          } else {
            // Next episode is loaded and playback stops.
            await _replaceFirstQueueItem(playlist.episodes[end]);
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
    playlist.removeEpisodesAt(index, number: number);
    await _savePlaylists();
    if (playlist == _playlist &&
        !_playerRunning &&
        _playlist.isQueue &&
        index == 0) {
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
    if (playlist == null) playlist = _playlist;
    if (playlist.isEmpty) return seekFuture;
    if (oldIndex < 0) oldIndex += playlist.length;
    if (newIndex < 0) newIndex += playlist.length;
    if (oldIndex >= playlist.length || newIndex >= playlist.length)
      return seekFuture;
    if (playlist.episodes.isEmpty) await playlist.getPlaylist();

    _playlistBeingEdited++;
    if (playlist == _playlist && _playerRunning) {
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
            await loadEpisodeHistoryPosition(
                episodeBrief: playlist.episodes[1]);
            _loadStartPosition();
            seekFuture = _audioHandler.skipToQueueItem(0);
          } else {
            await _replaceFirstQueueItem(playlist.episodes[1]);
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
            await loadEpisodeHistoryPosition(
                episodeBrief: playlist.episodes[oldIndex]);
            _loadStartPosition();
            seekFuture = _audioHandler.skipToQueueItem(0);
          } else {
            await _replaceFirstQueueItem(playlist.episodes[oldIndex]);
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
        !_playerRunning &&
        _playlist.isQueue &&
        (oldIndex == 0 || newIndex == 0)) {
      loadEpisodeHistoryPosition();
      _loadStartPosition();
    }
    notifyListeners();
    await seekFuture;
    _playlistBeingEdited--;
  }

  /// Updates the media ID of an episode from the database.
  /// Replaces the playing episode if its media ID changed.
  Future<void> updateEpisodeMediaID(EpisodeBrief episode) async {
    EpisodeBrief? oldEpisode;
    EpisodeBrief? updatedEpisode;
    if (_playlist.episodes.contains(episode)) {
      oldEpisode = _playlist.episodes.firstWhere((e) => e == episode);
      updatedEpisode =
          await oldEpisode.copyWithFromDB(newFields: [EpisodeField.mediaId]);
      if (oldEpisode.mediaId != updatedEpisode.mediaId) {
        _playlistBeingEdited++;

        final List<int> indexes = _playlist.updateEpisode(updatedEpisode);
        if (_playerRunning) {
          if (indexes.remove(_episodeIndex)) {
            // Currently playing episode is replaced
            int index = _episodeIndex;
            await _audioHandler
                .addQueueItemsAt([updatedEpisode.mediaItem], index + 1);
            _episodeIndex = index;
            await _audioHandler.combinedSeek(
                position: Duration(milliseconds: _audioPosition),
                index: index + 1);
            _episodeIndex = index;
            await _audioHandler.removeQueueItemsAt(index);
          }
          // Another episode is replaced.
          if (effectiveAutoPlay) {
            for (int i in indexes) {
              await _audioHandler
                  .addQueueItemsAt([updatedEpisode.mediaItem], i + 1);
              await _audioHandler.removeQueueItemsAt(i);
            }
          }
        }
        _playlistBeingEdited--;
      }
    }
    final containingPlaylists = _playlists.where(
        (playlist) => playlist != _playlist && playlist.contains(episode));
    for (final playlist in containingPlaylists) {
      if (updatedEpisode == null) {
        updatedEpisode = await playlist.episodes
            .firstWhere((episode) => episode == episode)
            .copyWithFromDB(newFields: [EpisodeField.mediaId]);
      }
      if (oldEpisode!.mediaId != updatedEpisode.mediaId) {
        playlist.updateEpisode(updatedEpisode);
      }
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
    if (playlist.isLocal!) {
      _dbHelper.deleteLocalEpisodes(playlist.episodeUrlList);
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
    await _playlistsStorage
        .savePlaylists([for (var p in _playlists) p.toEntity()]);
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
          _playlist.removeEpisodesAt(0);
        } else {
          _startEpisodeIndex = _episodeIndex + 1;
        }
        await loadEpisodeHistoryPosition();
        await playFromStart();
      }
    } else {
      if (_playlist.isQueue) {
        _playlist.removeEpisodesAt(0);
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
    await _audioHandler.fastForward();
  }

  Future<void> rewind() async {
    await _audioHandler.rewind();
  }

  Future<void> seekTo(int position) async {
    _audioPosition = position;
    await _audioHandler.combinedSeek(
        position: Duration(milliseconds: position));
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
        if (_playlist.isQueue && _lastEpisode != null) {
          await addToPlaylist([_lastEpisode!], index: 0);
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
    if (_playerRunning && _boostVolume!) {
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
      _startSleepTimer = true;
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
        _stopOnEndOfEpisode = false;
        _startSleepTimer = false;
        _switchValue = 0;
        if (_playerRunning) {
          _audioHandler.stop();
        }
        notifyListeners();
        // AudioService.disconnect();
      });
    } else if (_sleepTimerMode == SleepTimerMode.endOfEpisode) {
      _stopOnEndOfEpisode = true;
      _switchValue = 1;
      _skipStart = true;
      _historyPosition = _audioPosition;
      _playlistBeingEdited++;
      await _audioHandler.replaceQueue([
        _episode!.mediaItem
      ]); // Loads the episode as if [_autoPlay] is enabled
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
      _startSleepTimer = false;
      _switchValue = 0;
      notifyListeners();
    } else if (_sleepTimerMode == SleepTimerMode.endOfEpisode) {
      _stopOnEndOfEpisode = false;
      _switchValue = 0;
      _skipStart = true;
      _historyPosition = _audioPosition;
      _playlistBeingEdited++;
      await _audioHandler.replaceQueue(_playlist.mediaItems);
      await skipToIndex(_episodeIndex);
      _playlistBeingEdited--;
      notifyListeners();
    }
  }
}

class CustomAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  /// Media notification layout
  final _layoutStorage = KeyValueStorage(notificationLayoutKey);
  final _equalizer = AndroidEqualizer();
  final _loudnessEnhancer = AndroidLoudnessEnhancer();

  int _cacheMax;

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

  /// Audio player audio source
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(
    useLazyPreparation: true,
    shuffleOrder: DefaultShuffleOrder(),
    children: [],
  );

  int get _index => _player.currentIndex!;
  Duration _position = const Duration();
  bool get hasNext => queue.value.length > 0;
  MediaItem? get currentMediaItem => mediaItem.value;
  bool get playing => _player.playing && _playerReady;
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

  CustomAudioHandler(this._cacheMax) {
    _handleInterruption();
    initPlayer();
  }

  /// Initialises player and its listeners
  void initPlayer() {
    _player.setAudioSource(_playlist, preload: false);
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
        if (_layoutIndex == null) {
          _layoutIndex = await _layoutStorage.getInt();
        }

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
        if (queue.value.isNotEmpty && index! < queue.value.length) {
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
      await _player.dispose();
      await _playlist.clear();
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
      {EpisodeCollision ifExists = EpisodeCollision.Ignore}) async {
    List<AudioSource> sources = [for (var item in items) _itemToSource(item)];
    if (_playerReady) {
      switch (ifExists) {
        case EpisodeCollision.KeepExisting:
          items.removeWhere((item) => queue.value.contains(item));
          break;
        case EpisodeCollision.Replace:
          List<MediaItem> queueItems = queue.value;
          for (int i = 0; i < queueItems.length; i++) {
            int newIndex = items.indexOf(queueItems[i]);
            if (newIndex != -1 && newIndex + index != i) {
              // if (_index == i) {
              //   await pause();
              // }
              queueItems.removeAt(i);
              _playlist.removeAt(i);
              i--;
            }
          }
          queue.add(queueItems);
          break;
        case EpisodeCollision.Ignore:
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
        index, end); // TODO: What happens if current is removed?
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
    if ((position != _position) || (index != _index)) {
      seekTarget = SeekTarget(position: position, index: index);
      if (!seekOngoing) {
        seekOngoing = true;
        _innerCombinedSeek();
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
    customEvent.add({'preSeekPosition': _position.inMilliseconds});
    while (seekTarget.isValid) {
      position = seekTarget.position;
      index = seekTarget.index;
      seekTarget = SeekTarget();
      if (position != null) _position = position;
      await _player.seek(position, index: index);
    }
    // Retry failed seek.
    if (position != null) {
      Duration errorMargin = Duration(seconds: 1);
      while (_player.position - position > errorMargin ||
          _player.position - position < -errorMargin) {
        log("Seek unsucessful! Before seek: $preSeekPosition, seek target: $position, seek result: ${_player.position}. Trying again...");
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
        log('Argument' + argument!['speed'].toString());
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
    _playlist = ConcatenatingAudioSource(
      useLazyPreparation: false,
      shuffleOrder: DefaultShuffleOrder(),
      children: sources,
    );
    await _player.setAudioSource(_playlist, preload: false);
    // await play();
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
