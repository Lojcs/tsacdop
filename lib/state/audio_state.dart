import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:collection/priority_queue.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../local_storage/key_value_storage.dart';
import '../local_storage/sqflite_localpodcast.dart';
import '../type/episodebrief.dart';
import '../type/play_histroy.dart';
import '../type/playlist.dart';
import 'episode_state.dart';

MediaControl playControl = MediaControl(
  androidIcon: 'drawable/ic_stat_play_circle_filled',
  label: 'Play',
  action: MediaAction.play,
);
MediaControl pauseControl = MediaControl(
  androidIcon: 'drawable/ic_stat_pause_circle_filled',
  label: 'Pause',
  action: MediaAction.pause,
);
MediaControl skipToNextControl = MediaControl(
  androidIcon: 'drawable/baseline_skip_next_white_24',
  label: 'Next',
  action: MediaAction.skipToNext,
);
MediaControl skipToPreviousControl = MediaControl(
  androidIcon: 'drawable/ic_action_skip_previous',
  label: 'Previous',
  action: MediaAction.skipToPrevious,
);
MediaControl stopControl = MediaControl(
  androidIcon: 'drawable/baseline_close_white_24',
  label: 'Stop',
  action: MediaAction.stop,
);
MediaControl forwardControl = MediaControl(
  androidIcon: 'drawable/baseline_fast_forward_white_24',
  label: 'forward',
  action: MediaAction.fastForward,
);
MediaControl rewindControl = MediaControl(
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

  /// Unused. Current position.
  late int _currentPosition;

  /// Unused (only takes value 0). Record plyaer position.
  int _lastPosition = 0;

  /// Auto play next episode in playlist
  late bool _autoPlay;

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
  double? _currentSpeed = 1;
  bool? _skipSilence;
  bool? _boostVolume;
  late int _volumeGain;

  /// Mark as listened when skipped
  late bool _markListened;

  /// Current state variables

  /// Currently playing episode.
  EpisodeBrief? get _episode => _playlist?.episodes[_episodeIndex ?? 0];

  /// Index of currently playing episode
  int? _episodeIndex;

  /// Currently playing playlist.
  Playlist? _playlist;

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

  /// Current episode's start position (ms).
  int _audioStartPosition = 0;

  /// Current episode buffered position (ms).
  int _audioBufferedPosition = 0;

  /// Seekbar value, min 0, max 1.0.
  double get _seekSliderValue =>
      _audioDuration != 0 ? (_audioPosition / _audioDuration).clamp(0, 1) : 0;

  /// Unused. (Internal slider animation lock)
  bool _noSlide = true;

  /// Error message.
  String? _remoteErrorMessage;

  /// Temp episode list, playing from search result
  List<EpisodeBrief?> _playFromSearchList = [];

  bool _playingTemp = false;

  /// Last saved history to avoid sending it twice
  PlayHistory? _lastHistory;

  /// Sleep variables

  /// Set true if sleep timer mode is end of episode.
  bool _stopOnComplete = false;

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
        androidNotificationChannelName: 'Tsacdop',
        androidNotificationIcon: 'drawable/ic_notification',
        // androidEnableQueue: true,
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
  int get audioPosition => _audioPosition;

  /// Current episode's start position (ms).
  int get audioStartPosition => _audioStartPosition;

  /// Current episode buffered position (ms).
  int get audioBufferedPosition => _audioBufferedPosition;

  /// Seekbar value, min 0, max 1.0.
  double get seekSliderValue => _seekSliderValue;
  String? get remoteErrorMessage => _remoteErrorMessage;

  EpisodeBrief? get episode => _episode;
  Playlist? get playlist => _playlist;
  List<Playlist> get playlists => _playlists;
  Playlist get queue => _queue;
  AudioProcessingState get audioState => _audioState;
  bool get buffering => _audioState != AudioProcessingState.ready;

  /// Set true if sleep timer mode is end of episode.
  bool get stopOnComplete => _stopOnComplete;

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
    int cacheMax =
        await cacheStorage.getInt(defaultValue: (1024 * 1024 * 200).toInt());
    _audioHandler = await AudioService.init(
        builder: () => CustomAudioHandler(cacheMax), config: _config);
    super.addListener(listener);
  }

  @override
  void dispose() {
    _mediaItemSubscription?.cancel();
    _playbackStateSubscription?.cancel();
    _customEventSubscription?.cancel();
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
      notifyListeners();

      // Seems unused
      await KeyValueStorage(lastWorkKey).saveInt(0);
    }
  }

  Future<void> saveCurrentPosition() async {
    if (!_playingTemp && _playerRunning) {
      _savedPosition = _audioPosition;
      await _playerStateStorage.savePlayerState(
          _playlist!.id, _episode!.enclosureUrl, _audioPosition);
    }
  }

  /// Saves current history and position
  Future<void> saveHistory({bool savePosition = false}) async {
    if (!_playingTemp && _playerRunning) {
      if (savePosition) {
        saveCurrentPosition();
      }
      PlayHistory history = PlayHistory(_episode!.title, _episode!.enclosureUrl,
          _audioPosition ~/ 1000, _seekSliderValue);
      if (_lastHistory != history) {
        _lastHistory = history;
        if (_seekSliderValue > 95) {
          await _episodeState.setListened(_episode!);
        } else {
          await _dbHelper.saveHistory(history);
        }
      }
    }
  }

  /// Loads saved playlist and episode
  Future<void> loadSavedPosition({bool saveCurrent = false}) async {
    // Get playerstate saved in storage.
    List<String> lastState = await _playerStateStorage.getPlayerState();
    if (saveCurrent) await saveHistory(savePosition: true);
    // Set current playlist
    _playlist = _playlists.firstWhere((p) => p.id == lastState[0],
        orElse: () => _playlists.first);
    await _playlist!.getPlaylist();
    // Set current episode
    if (lastState[1] != '') {
      if (_playlist!.isQueue) {
        if (_playlist!.isNotEmpty &&
            _playlist!.episodes.first!.enclosureUrl == lastState[1]) {
          _episodeIndex = 0;
        } else {
          _episodeIndex = _playlist!.isNotEmpty ? 0 : null;
        }
      } else {
        _episodeIndex = _playlist!.episodes.indexWhere(
          (e) => e.enclosureUrl == lastState[1],
        );
        if (_episodeIndex == -1) {
          _episodeIndex = _playlist!.isNotEmpty
              ? 0
              : null; // TODO: Do better failure communication!
        }
      }
    } else {
      _episodeIndex = _playlist!.isNotEmpty ? 0 : null;
    }
    // Load episode position
    PlayHistory position = await _dbHelper.getPosition(_episode!);
    if (_episodeIndex != null) {
      _audioStartPosition = int.parse(lastState[2]);
      if (_audioStartPosition == 0) {
        if (position.seconds! > 0) {
          _audioStartPosition = position.seconds! * 1000;
        }
      }
    }
    notifyListeners();
  }

  /// Loads the saved position of the current episode to [_audioStartPosition]
  Future<void> loadCurrentEpisodeHistoryPosition() async {
    PlayHistory position = await _dbHelper.getPosition(_episode!);
    if (position.seconds! > 0) {
      _audioStartPosition = position.seconds! * 1000;
    }

    notifyListeners();
  }

  /// Starts or changes playback according to [_playlist], [_episodeIndex] and [_audioStartPosition] variables.
  /// Doesn't reorder queue or save history, do those before calling this.
  Future<void> playFromPosition({bool samePlaylist = false}) async {
    if (_episodeIndex != null &&
        _episodeIndex! < _playlist!.length &&
        (!_playlist!.isQueue || _episodeIndex == 0)) {
      if (_playlist!.episodes.isEmpty) {
        await _playlist!.getPlaylist();
      }
      if (_playerRunning) {
        if (samePlaylist) {
          await _audioHandler
              .skipToQueueItem(_episodeIndex!); // TODO: Override this
        } else {
          _audioHandler
              .customAction('setIsQueue', {'isQueue': _playlist!.isQueue});
          if (_autoPlay) {
            _audioHandler.replaceQueue(_playlist!.mediaItems);
          } else {
            _audioHandler.replaceQueue([_episode!.mediaItem]);
          }
          await _audioHandler
              .skipToQueueItem(_episodeIndex!); // TODO: Override this
        }
        await _audioHandler.seek(Duration(milliseconds: _audioStartPosition));
        _audioPosition = _audioStartPosition;
        _audioDuration = _episode!.enclosureDuration!;
      } else {
        await _startAudioService(_playlist!,
            position: _audioStartPosition, index: _episodeIndex!);
      }
    } else {
      log('Invalid position to play');
    }
  }

  /// Starts playback from last played playlist and episode
  Future<void> playFromLastPosition() async {
    Playlist? currentPlaylist = _playlist;
    await loadSavedPosition(saveCurrent: true);
    if (_episodeIndex != null) {
      await playFromPosition(samePlaylist: currentPlaylist == _playlist);
    } else {
      log('Playlist is empty, loading queue');
      await playlistLoad(_queue);
    }
  }

  /// Loads arbitrary playlist from start. Doesn't need to be saved
  Future<void> playlistLoad(Playlist playlist) async {
    if (playlist.isNotEmpty) {
      await saveHistory();
      _playlist = playlist;
      _episodeIndex = 0;
      _audioStartPosition = 0;
      await playFromPosition();
    }
  }

  /// Temporarily loads an episode from search // TODO: make sure the playlist is deleted once the episode finishes
  Future<void> searchEpisodeLoad(EpisodeBrief episode) async {
    Playlist tempPlaylist = Playlist(
      // TODO: add search playlist flag like local?
      "Search",
      episodeList: [episode.enclosureUrl],
      episodes: [episode],
    );
    _playingTemp = true;
    await saveHistory(savePosition: true);
    await playlistLoad(tempPlaylist);
  }

  /// Adds episode to beginning of the queue and starts playing.
  Future<void> episodeLoad(EpisodeBrief episode,
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

    addToPlaylistPlus([episode], playlist: _queue, index: 0);
    if (!(playerRunning && _playlist!.isQueue)) {
      _playlist = _queue;
      _episodeIndex = 0;
      // Set _audioStartPosition
      if (startPosition > 0) {
        _audioStartPosition = startPosition;
      } else {
        PlayHistory position = await _dbHelper.getPosition(episode);
        _audioStartPosition = position.seconds!;
      }
      await playFromPosition(samePlaylist: false);
    }

    notifyListeners();
    await _episodeState.unsetNew(episode);
  }

  /// Skips to the episode at specified index
  Future<void> loadEpisodeFromCurrentPlaylist(int episodeIndex) async {
    _episodeIndex = episodeIndex;
    if (!_playlist!.isQueue) {
      await saveHistory();
      await playFromPosition(samePlaylist: true);
    } else {
      episodeLoad(_episode!);
    }
  }

  /// Starts the audio service and player
  Future<void> _startAudioService(Playlist playlist,
      {int index = 0, int position = 0}) async {
    assert(!_playerRunning);
    // Set initial variables
    _stopOnComplete = false;
    _sleepTimerMode = SleepTimerMode.undefined;
    _switchValue = 0;
    _audioState = AudioProcessingState.loading;
    _audioPosition = _audioStartPosition;
    _audioDuration = _episode!.enclosureDuration!;
    _playerRunning = true;
    notifyListeners();
    if (!_audioHandler.playerReady) _audioHandler.initPlayer();

    /// Set if playlist is queue.
    await _audioHandler
        .customAction('setIsQueue', {'isQueue': _playlist!.isQueue});

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
    if (_autoPlay) {
      await _audioHandler.replaceQueue(_playlist!.mediaItems);
      // await _audioHandler.skipToQueueItem(_episodeIndex!);
    } else {
      await _audioHandler.replaceQueue(_playlist!.mediaItems);
    }
    // await _audioHandler.play();
    // await _audioHandler.seek(Duration(milliseconds: _audioStartPosition));

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

    _mediaItemSubscription =
        _audioHandler.mediaItem.where((event) => event != null).listen(
      (item) async {
        _audioDuration = item!.duration?.inMilliseconds ?? 0;
        notifyListeners();
      },
    );

    _playbackStateSubscription =
        _audioHandler.playbackState.listen((PlaybackState event) async {
      int newIndex = event.queueIndex!;
      if (newIndex != _episodeIndex) {
        // This doesn't catch queue
        // if (_playlist!.isQueue) {
        //   _queue.removeEpisodesAt(0);
        // }
        // Save last episode's history.
        await saveHistory();
        _episodeIndex = newIndex;
        // This is different than saveCurrentPosition
        await _playerStateStorage.savePlayerState(_playlist!.id,
            _episode!.enclosureUrl, event.updatePosition.inMilliseconds);
      }
      _audioState = event.processingState;
      _playing = event.playing;
      // _audioPosition = event.updatePosition.inMilliseconds;
      _audioBufferedPosition = event.bufferedPosition.inMilliseconds;
      _currentSpeed = event.speed;
      if (_audioState == AudioProcessingState.completed) {
        if (_switchValue > 0) _switchValue = 0;
        if (_playingTemp) {
          _playingTemp = false;
          await loadSavedPosition(saveCurrent: false);
        } else {
          await saveHistory(savePosition: true);
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
      if (_stopOnComplete) {
        _audioHandler.stop();
      }
      notifyListeners();
    });

    _customEventSubscription =
        _audioHandler.customEvent.distinct().listen((event) async {
      if (event['playerRunning'] == false && _playerRunning) {
        _playerRunning = false;
        notifyListeners();
        await saveHistory(savePosition: true);
      }
      // Communicate queue next episode
      if (event['removePlayed'] == _episode!.mediaId) {
        // await saveHistory(); // TODO: This might not save the new episode's position at all
        await _episodeState
            .setListened(_episode!); // And this just sets it to 1
        if (_playlist!.isQueue) {
          _queue.removeEpisodesAt(0);
        }
        if (_stopOnComplete) {
          _audioHandler.stop();
        }
        notifyListeners();
      }
      if (event['position'] != null) {
        _audioPosition = event['position'].inMilliseconds;
        // Save position every 5 seconds
        if (_audioPosition - _savedPosition > 5000) {
          saveCurrentPosition();
        }
        notifyListeners();
      }
    });
  }

  // Queue management

  /// Adds [episodes] to [playlist]. Handles adding to live playlist.
  /// Adds to the end of queue by default.
  /// Negative index to index from the end
  Future<void> addToPlaylistPlus(List<EpisodeBrief> episodes,
      {Playlist? playlist, int index = -1}) async {
    if (episodes.length == 0) return;
    for (int i = 0; i < episodes.length; i++) {
      // TODO: Add batch copyWithFromDB option for speed
      episodes[i] = await episodes[i].copyWithFromDB(newFields: [
        EpisodeField.enclosureDuration,
        EpisodeField.enclosureSize,
        EpisodeField.mediaId,
        EpisodeField.primaryColor,
        EpisodeField.isNew,
        EpisodeField.skipSecondsStart,
        EpisodeField.skipSecondsEnd,
        EpisodeField.episodeImage,
        EpisodeField.podcastImage,
        EpisodeField.chapterLink
      ], keepExisting: true);
      await _episodeState.unsetNew(episodes[i]);
    }
    if (playlist == null) playlist = _queue;
    if (index < 0) index += playlist.length + 1;
    EpisodeCollision ifExists =
        playlist.isQueue ? EpisodeCollision.Replace : EpisodeCollision.Ignore;

    playlist.addEpisodes(episodes, index, ifExists: ifExists);
    // The following comments describe what should be happening in each case, not what the code is doing.
    if (playlist == _playlist && _playerRunning) {
      if (_episodeIndex! < index) {
        if (_autoPlay) {
          // Add episodes to be played later
          _audioHandler.addQueueItemsAt(
              [for (var episode in episodes) episode.mediaItem], index,
              ifExists: ifExists);
        } else {
          // No problem in this case.
        }
      } else {
        if (_autoPlay) {
          if (playlist.isQueue) {
            await saveHistory();
            _audioHandler.addQueueItemsAt(
                [for (var episode in episodes) episode.mediaItem], index,
                ifExists: ifExists);
            // Player starts playing newly inserted episodes.
            loadCurrentEpisodeHistoryPosition(); // TODO: Tell this to the player
          } else {
            _audioHandler.addQueueItemsAt(
                [for (var episode in episodes) episode.mediaItem], index,
                ifExists: ifExists);
            // Current episode's index is shifted and continues playing
            _episodeIndex = _episodeIndex! + episodes.length;
          }
        } else {
          if (playlist.isQueue) {
            // Play newly inserted episodes.
            await saveHistory();
            loadCurrentEpisodeHistoryPosition();
            await playFromPosition(samePlaylist: false);
          } else {
            // Current episode's index is shifted and player remains the same
            _episodeIndex = _episodeIndex! + episodes.length;
          }
        }
      }
    }
    _savePlaylists();
    notifyListeners();
  }

  /// Adds episode to the end of queue
  Future<void> addToPlaylist(EpisodeBrief episode) async {
    await addToPlaylistPlus([episode]);
    // episode = await episode.copyWithFromDB(newFields: [
    //   EpisodeField.enclosureDuration,
    //   EpisodeField.enclosureSize,
    //   EpisodeField.mediaId,
    //   EpisodeField.primaryColor,
    //   EpisodeField.isNew,
    //   EpisodeField.skipSecondsStart,
    //   EpisodeField.skipSecondsEnd,
    //   EpisodeField.episodeImage,
    //   EpisodeField.podcastImage,
    //   EpisodeField.chapterLink
    // ], keepExisting: true);
    // await _episodeState.unsetNew(episode);
    // if (!_queue.episodes.contains(episode)) {
    //   if (playerRunning && _playlist!.isQueue) {
    //     await _audioHandler.addQueueItem(episode.toMediaItem());
    //   }
    //   if (_playlist!.isQueue && _queue.isEmpty) _episodeIndex = 0;
    //   _queue.addToPlayList(episode);
    //   await updatePlaylist(_queue, updateEpisodes: false);
    // }
  }

  /// Adds epiisode at the index of queue
  Future<void> addToPlaylistAt(EpisodeBrief episode, int index) async {
    addToPlaylistPlus([episode], index: index);
    // var episodeNew = await episode.copyWithFromDB(newFields: [
    //   EpisodeField.mediaId,
    //   EpisodeField.primaryColor,
    //   EpisodeField.isNew,
    //   EpisodeField.skipSecondsStart,
    //   EpisodeField.skipSecondsEnd,
    //   EpisodeField.episodeImage,
    //   EpisodeField.chapterLink
    // ], keepExisting: true);
    // if (episodeNew.isNew!) {
    //   await _dbHelper.removeEpisodeNewMark(episodeNew.enclosureUrl);
    // }
    // if (_playerRunning && _playlist!.isQueue) {
    //   await _audioHandler.customAction('addQueueItemAt',
    //       {'mediaItem': episodeNew.toMediaItem(), 'index': index});
    // }
    // _queue.addToPlayListAt(episodeNew, index);
    // await updatePlaylist(_queue, updateEpisodes: false);
  }

  /// Adds episodes at the end of queue
  Future<void> addNewEpisode(List<String> group) async {
    var newEpisodes = <EpisodeBrief>[];
    if (group.isEmpty) {
      newEpisodes = await _dbHelper.getEpisodes(
          optionalFields: [EpisodeField.mediaId],
          sortBy: Sorter.pubDate,
          sortOrder: SortOrder.DESC,
          filterNew: -1,
          limit: 100);
    } else {
      newEpisodes = await _dbHelper.getEpisodes(
          optionalFields: [EpisodeField.mediaId],
          feedIds: group,
          sortBy: Sorter.pubDate,
          sortOrder: SortOrder.DESC,
          filterNew: -1,
          limit: 100);
    }
    await addToPlaylistPlus(newEpisodes);
  }

// TODO: Switch to downloaded when currently playing episode finishes downloading. Github version seems to be doing that already
  /// Updates the media item if episode is downloaded while playing
  Future<void> updateMediaItem(EpisodeBrief episode) async {
    if (episode.enclosureUrl == episode.mediaId &&
        _episode != episode &&
        _playlist!.contains(episode)) {
      if (episode.isDownloaded!) print("Please use the isDownloaded field");
      var episodeNew = await episode.copyWithFromDB(newFields: [
        EpisodeField.mediaId,
        EpisodeField.primaryColor,
        EpisodeField.isNew,
        EpisodeField.skipSecondsStart,
        EpisodeField.skipSecondsEnd,
        EpisodeField.episodeImage,
        EpisodeField.chapterLink
      ], keepExisting: true);
      _playlist!.updateEpisode(episodeNew);
      if (_playerRunning) {
        await _audioHandler.updateMediaItem(episodeNew.mediaItem);
      }
    }
  }

  /// Removes [episodes] from [playlist]. [playlist] defaults to [_queue]
  Future<List<int>> removeFromPlaylistPlus(List<EpisodeBrief> episodes,
      {Playlist? playlist}) async {
    if (episodes.length == 0) return [];
    if (playlist == null) playlist = _queue;
    List<int> indexes = [];
    // The following comments describe what should be happening in each case, not what the code is doing.
    if (playlist == _playlist && _playerRunning) {
      bool currentDeleted = false;
      int beforeCurrentDeleteCount = 0;
      for (int i = 0; i < playlist.episodes.length; i++) {
        for (var episode in playlist.episodes) {
          var delEpisode = playlist.episodes[i];
          if (episode == delEpisode) {
            indexes.add(i);
            if (i < _episodeIndex!)
              beforeCurrentDeleteCount++;
            else if (i == _episodeIndex!) currentDeleted = true;
            break;
          }
        }
      }
      playlist.removeEpisodes(episodes);
      if (beforeCurrentDeleteCount == 0) {
        // No problems
      } else {
        if (_autoPlay) {
          if (currentDeleted) _audioHandler.pause();
          // Remove items in batches starting from the end
          int? index1;
          int? index2;
          int number = 1;
          index1 = indexes.removeLast();
          while (index1 != null) {
            index2 = indexes.removeLast();
            while (index1 == index2! + number) {
              number++;
              if (indexes.isNotEmpty) {
                index2 = indexes.removeLast();
              } else {
                index2 = null;
                break;
              }
            }
            _audioHandler.removeQueueItemsAt(index1 - number + 1,
                number: number);
            number = 1;
            index1 = index2;
          }
          if (currentDeleted) {
            _audioHandler.play();
            // Current episode is deleted and player starts playing the next undeleted episode
            _episodeIndex = _episodeIndex! - beforeCurrentDeleteCount;
          } else {
            // Current episode's index is shifted and continues playing
            _episodeIndex = _episodeIndex! - beforeCurrentDeleteCount;
          }
        } else {
          if (currentDeleted) {
            // Current episode is deleted and next undeleted episode is loaded.
            if (!playlist.isLocal!) {
              await saveHistory();
            }
            _episodeIndex = _episodeIndex! - beforeCurrentDeleteCount;
            loadCurrentEpisodeHistoryPosition();
            await playFromPosition(samePlaylist: false);
          } else {
            // Current episode's index is shifted and continues playing
            _episodeIndex = _episodeIndex! - beforeCurrentDeleteCount;
          }
        }
      }
    }
    _savePlaylists();
    notifyListeners();
    return indexes;
  }

  /// Removes [number] episodes from [playlist] at [index]. [playlist] defaults to [_queue]
  // TODO: Use this instead of non-index based remove to speed up
  Future<void> removeFromPlaylistAtPlus(int index,
      {int number = 1, Playlist? playlist}) async {
    if (playlist == null) playlist = _queue;
    if (index < 0) index += playlist.length + 1;
    final int end = index + number;
    if (end > playlist.length || number < 0) return;

    playlist.removeEpisodesAt(index, number: number);
    // The following comments describe what should be happening in each case, not what the code is doing.
    if (playlist == _playlist && _playerRunning) {
      if (_episodeIndex! < index) {
        if (_autoPlay) {
          // Remove episodes from the player
          _audioHandler.removeQueueItemsAt(index, number: number);
        } else {
          // No problem in this case.
        }
      } else {
        if (_autoPlay) {
          _audioHandler.removeQueueItemsAt(index, number: number);
          if (playlist.isQueue) {
            // Current episode is deleted and player starts playing the next undeleted episode
          } else {
            if (_episodeIndex! <= end) {
              // Current episode is deleted and player starts playing the next undeleted episode
              _episodeIndex = index;
            } else {
              // Current episode's index is shifted and continues playing
              _episodeIndex = _episodeIndex! - number;
            }
          }
        } else {
          if (playlist.isQueue) {
            // Current episode is deleted and next undeleted episode is loaded
            if (!playlist.isLocal!) {
              await saveHistory();
            }
            loadCurrentEpisodeHistoryPosition();
            await playFromPosition(samePlaylist: false);
          } else {
            if (_episodeIndex! < end) {
              // Current episode is deleted and next undeleted episode is loaded
              if (!playlist.isLocal!) {
                await saveHistory();
              }
              _episodeIndex = index;
              loadCurrentEpisodeHistoryPosition();
              await playFromPosition(samePlaylist: false);
            } else {
              // Current episode's index is shifted and continues playing
              _episodeIndex = _episodeIndex! - number;
            }
          }
        }
      }
    }
    _savePlaylists();
    notifyListeners();
  }

  /// Deletes episode from the queue
  Future<int> delFromPlaylist(EpisodeBrief episode) async {
    return (await removeFromPlaylistPlus([episode])).first;
    // EpisodeBrief? episodeNew;
    // var episodes = await _dbHelper.getEpisodes(episodeUrls: [
    //   episode.enclosureUrl
    // ], optionalFields: [
    //   EpisodeField.mediaId,
    //   EpisodeField.episodeImage,
    //   EpisodeField.podcastImage,
    // ]);
    // if (episodes.isEmpty)
    //   episodeNew = null;
    // else
    //   episodeNew = episodes[0];
    // if (playerRunning && _playlist!.isQueue) {
    //   await _audioHandler.removeQueueItem(episodeNew!.toMediaItem());
    // }
    // final index = _queue.delFromPlaylist(episodeNew);
    // if (index == 0) {
    //   _lastPosition = 0;
    //   await _positionStorage.saveInt(0);
    // }
    // updatePlaylist(_queue, updateEpisodes: false);
    // return index;
  }

  /// Moves [playlist] episode at [oldIndex] to [newIndex]. [playlist] defaults to [_queue]
  Future<void> reorderPlaylist(int oldIndex, int newIndex,
      {Playlist? playlist}) async {
    if (playlist == null) playlist = _queue;
    playlist.reorderPlaylist(oldIndex, newIndex);
    if (newIndex > oldIndex) newIndex -= 1;
    final EpisodeBrief episode = _queue.episodes[oldIndex]!;
    final MediaItem media = episode.mediaItem;
    // The following comments describe what should be happening in each case, not what the code is doing.
    if (playlist == _playlist && _playerRunning) {
      if (oldIndex > _episodeIndex! && newIndex > _episodeIndex! ||
          oldIndex <= _episodeIndex! && newIndex <= _episodeIndex!) {
        // Moved episode doesn't affect current episode's index
        if (_autoPlay) {
          // Reorder the player
          _audioHandler.removeQueueItemsAt(oldIndex);
          _audioHandler.addQueueItemsAt([media], newIndex);
        } else {
          // No problem
        }
      } else {
        if (playlist.isQueue) {
          // Playing episode changes
          if (oldIndex == 0) {
            // Current episode is moved away, next one plays.
          } else if (newIndex == 0) {
            // Moved episode is inserted to 0 and starts playing.
          }
        } else {
          // Current episode keeps playing with index change
          if (oldIndex > _episodeIndex!) {
            // Moved episode is moved before current episode.
            _episodeIndex = _episodeIndex! + 1;
          } else if (newIndex > _episodeIndex!) {
            // Moved episode is moved after current episode.
            _episodeIndex = _episodeIndex! - 1;
          }
        }
        if (_autoPlay) {
          _audioHandler.removeQueueItemsAt(oldIndex);
          _audioHandler.addQueueItemsAt([media], newIndex);
          // Player handles
        } else {
          // Load episode
          loadCurrentEpisodeHistoryPosition();
          await playFromPosition(samePlaylist: false);
        }
      }
    }
    _savePlaylists();
    notifyListeners();
  }

  /// Moves queue episode at [oldIndex] to [newIndex]
  Future reorderQueue(int oldIndex, int newIndex) async {
    reorderPlaylist(oldIndex, newIndex);
    // assert(_playlist!.isQueue);
    // if (newIndex > oldIndex) {
    //   newIndex -= 1;
    // }
    // final episode = _queue.episodes[oldIndex]!;
    // // Reorder the queue playlist
    // _queue.addToPlayListAt(episode, newIndex);
    // updatePlaylist(_queue, updateEpisodes: false);
    // if (playerRunning) {
    //   await _audioHandler.removeQueueItem(episode.toMediaItem());
    //   await _audioHandler.insertQueueItem(newIndex, episode.toMediaItem());
    //   // await _audioHandler.customAction('addQueueItemAt',
    //   //     {'mediaItem': episode.toMediaItem(), 'index': newIndex});
    // }
    // if (newIndex == 0) {
    //   _lastPosition = 0;
    //   await _positionStorage.saveInt(0);
    // }
  }

  /// Adds episode to be played next in queue
  Future<void> moveToTop(EpisodeBrief episode) async {
    int index = (_playerRunning && _playlist!.isQueue) ? 1 : 0;
    addToPlaylistPlus([episode], index: index);
    // await delFromPlaylist(episode);
    // var episodeNew;
    // var episodes = await _dbHelper.getEpisodes(episodeUrls: [
    //   episode.enclosureUrl
    // ], optionalFields: [
    //   EpisodeField.enclosureDuration,
    //   EpisodeField.enclosureSize,
    //   EpisodeField.mediaId,
    //   EpisodeField.isNew,
    //   EpisodeField.skipSecondsStart,
    //   EpisodeField.skipSecondsEnd,
    //   EpisodeField.episodeImage,
    //   EpisodeField.podcastImage,
    //   EpisodeField.chapterLink
    // ]);
    // if (episodes.isEmpty)
    //   episodeNew = null;
    // else
    //   episodeNew = episodes[0];
    // if (_playerRunning && _playlist!.isQueue) {
    //   await _audioHandler.customAction(
    //       '', {'mediaItem': episodeNew!.toMediaItem(), 'index': 1});
    //   _queue.addToPlayListAt(episode, 1, removeExisting: false);
    // } else {
    //   _queue.addToPlayListAt(episode, 0, removeExisting: false);
    //   if (_playlist!.isQueue) {
    //     _lastPosition = 0;
    //     _positionStorage.saveInt(_lastPosition);
    //     _episode = episodeNew;
    //   }
    // }
    // updatePlaylist(_queue, updateEpisodes: false);
    // return true;
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
      _dbHelper.deleteLocalEpisodes(playlist.episodeList);
    }
  }

  /// Adds episodes to the end of the playlist
  void addEpisodesToPlaylist(Playlist playlist,
      {required List<EpisodeBrief> episodes}) {
    addToPlaylistPlus(episodes, playlist: playlist);
    // for (var e in episodes) {
    //   playlist.addToPlayList(e);
    //   if (playerRunning && playlist == _playlist) {
    //     _audioHandler.addQueueItem(e.toMediaItem());
    //   }
    // }
    // updatePlaylist(playlist, updateEpisodes: false);
  }

  /// Removes episodes from playlist
  void removeEpisodeFromPlaylist(Playlist playlist,
      {required List<EpisodeBrief> episodes}) {
    removeFromPlaylistPlus(episodes, playlist: playlist);
    // for (var e in episodes) {
    //   playlist.delFromPlaylist(e);
    //   if (playerRunning && playlist == _playlist) {
    //     _audioHandler.removeQueueItem(e.toMediaItem());
    //   }
    // }
    // updatePlaylist(playlist, updateEpisodes: false);
  }

  /// Moves playlist episode at [oldIndex] to [newIndex]
  void reorderEpisodesInPlaylist(Playlist playlist,
      {required int oldIndex, required int newIndex}) async {
    reorderPlaylist(oldIndex, newIndex, playlist: playlist);
    // playlist.reorderPlaylist(oldIndex, newIndex);

    // if (playerRunning && playlist == _playlist) {
    //   if (newIndex > oldIndex) {
    //     newIndex -= 1;
    //   }
    //   await _audioHandler.removeQueueItem(episode!.toMediaItem());
    //   await _audioHandler.customAction('addQueueItemAt',
    //       {'mediaItem': episode!.toMediaItem(), 'index': newIndex});
    // }
    // updatePlaylist(playlist, updateEpisodes: false);
  }

  /// Clears all episodes in playlist
  void clearPlaylist(Playlist playlist) {
    removeFromPlaylistAtPlus(0, number: playlist.length, playlist: playlist);
    // if (_playerRunning && _playlist!.isQueue && playlist.isQueue) {
    //   for (var e in playlist.episodes) {
    //     if (e != _episode) {
    //       delFromPlaylist(e!);
    //     }
    //   }
    // } else {
    //   playlist.clear();
    //   if (_playlist!.isQueue) _episode = null;
    // }
    // updatePlaylist(playlist, updateEpisodes: false);
  }

  /// Replaces the playlist in [_playlists] with the provided version.
  /// This shouldn't be needed in general use.
  Future<void> updatePlaylist(Playlist playlist,
      {bool updateEpisodes = true}) async {
    deletePlaylist(playlist);
    if (updateEpisodes) await playlist.getPlaylist();
    addPlaylist(playlist);
    // _playlists = [for (var p in _playlists) p.id == playlist.id ? playlist : p];
    // if (_playlist!.id == playlist.id) {
    //   if (playlist.isQueue) {
    //     _playlist = playlist;
    //   } else if (!_playerRunning) {
    //     // TODO: Why not while the player is running?
    //     _playlist = playlist;
    //   }
    //   notifyListeners();
    // }
    // await _savePlaylists();
  }

  bool playlistExists(String? name) {
    for (var p in _playlists) {
      if (p.name == name) return true; // TODO: Compare by id
    }
    return false;
  }

  // void _updateAllPlaylists() {
  //   _playlists = [..._playlists];
  //   notifyListeners();
  //   _savePlaylists();
  // }

  Future<void> _savePlaylists() async {
    await _playlistsStorage
        .savePlaylists([for (var p in _playlists) p.toEntity()]);
  }

  /// Audio control.
  Future<void> pauseAduio() async {
    saveCurrentPosition();
    await _audioHandler.pause();
  }

  Future<void> resumeAudio() async {
    _remoteErrorMessage = null;
    notifyListeners();
    if (_audioState != AudioProcessingState.loading) {
      _audioHandler.play();
    }
  }

  /// Plays next episode in playlist, ends playback if there isn't one.
  Future<void> skipToNext() async {
    _remoteErrorMessage = null;
    if (_playlist!.length - _episodeIndex! > 1) {
      if (_autoPlay) {
        await _audioHandler.skipToNext();
      } else {
        if (_playlist!.isQueue) {
          _queue.removeEpisodesAt(0);
          loadCurrentEpisodeHistoryPosition();
          playFromPosition();
        } else {
          _episodeIndex = _episodeIndex! + 1;
          loadCurrentEpisodeHistoryPosition();
          playFromPosition();
        }
      }
    } else {
      await _audioHandler.stop();
    }
    notifyListeners();
  }

  Future<void> skipToIndex(int index) async {
    saveHistory();
    if (_playlist!.isQueue) {
      reorderPlaylist(index, 0);
    } else {
      _audioHandler.skipToQueueItem(index);
    }
  }

  /// Fast forwards audio by [s] seconds
  Future<void> forwardAudio(int s) async {
    var pos = _audioPosition! + s * 1000;
    await _audioHandler.seek(Duration(milliseconds: pos));
  }

  Future<void> fastForward() async {
    await _audioHandler.fastForward();
  }

  Future<void> rewind() async {
    await _audioHandler.rewind();
  }

  Future<void> seekTo(int position) async {
    if (_audioState != AudioProcessingState.loading) {
      await _audioHandler.seek(Duration(milliseconds: position));
    }
  }

  Future<void> sliderSeek(double val) async {
    if (_audioState != AudioProcessingState.loading) {
      await _audioHandler
          .seek(Duration(milliseconds: (val * _audioDuration).toInt()));
    }
  }

  /// Set player speed.
  Future<void> setSpeed(double speed) async {
    await _audioHandler.customAction('setSpeed', {'speed': speed});
    _currentSpeed = speed;
    await _speedStorage.saveDouble(_currentSpeed!);
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
  void sleepTimer(int? mins) {
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
        _stopOnComplete = false;
        _startSleepTimer = false;
        _switchValue = 0;
        if (_playerRunning) {
          _audioHandler.stop();
        }
        notifyListeners();
        // AudioService.disconnect();
      });
    } else if (_sleepTimerMode == SleepTimerMode.endOfEpisode) {
      _stopOnComplete = true;
      _switchValue = 1;
      notifyListeners();
      // Stopping at player prevents saving position at the next episode. This is handled by stream listeners
      // if (_queue.episodes.length > 1 && _autoPlay) {
      //   _audioHandler.customAction('stopAtEnd', {});
      // }
    }
  }

  set setSleepTimerMode(SleepTimerMode timer) {
    _sleepTimerMode = timer;
    notifyListeners();
  }

//Cancel sleep timer
  void cancelTimer() {
    if (_sleepTimerMode == SleepTimerMode.timer) {
      _stopTimer.cancel();
      _timeLeft = 0;
      _startSleepTimer = false;
      _switchValue = 0;
      notifyListeners();
    } else if (_sleepTimerMode == SleepTimerMode.endOfEpisode) {
      // Stopping at player prevents saving position at the next episode. This is handled by stream listeners
      // _audioHandler.customAction('cancelStopAtEnd', {});
      _switchValue = 0;
      _stopOnComplete = false;
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
  late final AudioPlayer _player;

  /// Playback is paused while interrupted
  bool _interrupted = false;

  /// Media notification layout
  int? _layoutIndex;

  /// Sleep timer stop at end of episode
  bool _stopAtEnd = false;
  bool _isQueue = false;

  /// Enables sending queue new episode events ('removePlayed')
  bool _autoSkip = true;

  /// Audio player audio source
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(
    useLazyPreparation: false,
    shuffleOrder: DefaultShuffleOrder(),
    children: [],
  );

// TODO: These should target player instead of handler
  int get _index => _player.currentIndex!;
  bool get hasNext => queue.value.length > 0;
  MediaItem? get currentMediaItem => mediaItem.value;
  bool get playing => playbackState.value.playing && _playerReady;
  bool _playerReady = false;

  late StreamSubscription<PlaybackEvent> _playbackEventSubscription;
  late StreamSubscription<int?> _currentIndexSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<List<IndexedAudioSource>?> _sequenceSubscription;
  late StreamSubscription<Duration?> _durationSubscription;

  bool get playerReady => _playerReady;
  @override
  PublishSubject<Map<String, dynamic>> customEvent = PublishSubject()..add({});

  CustomAudioHandler(int this._cacheMax) {
    _handleInterruption();
    // initPlayer(cacheMax);
  }

  /// Initialises player and its listeners
  void initPlayer() {
    _player = AudioPlayer(
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
    _player.setAudioSource(_playlist, preload: true);
    // _player.cacheMax = cacheMax;
    // Transmit events received from player
    _playbackEventSubscription =
        _player.playbackEventStream.listen((event) async {
      if (_layoutIndex == null) {
        _layoutIndex = await _layoutStorage.getInt();
      }
      playbackState.add(playbackState.value.copyWith(
        controls: _getControls(_layoutIndex),
        androidCompactActionIndices: [0, 1, 2],
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        queueIndex: event.currentIndex ?? 0,
        speed: _player.speed,
      ));
    });
    // Stream for currentIndex (same as playbackEvent.currentIndex)
    _currentIndexSubscription = _player.currentIndexStream.listen(
      (index) {
        if (queue.value.isNotEmpty && index! < queue.value!.length) {
          mediaItem.add(queue.value![index]);
        }
        if (_isQueue && _autoSkip) {
          customEvent.add({'removePlayed': queue.value!.first.id});
        }
        _autoSkip = true;
      },
    );
    // Positions in positionStream are smoothed from playbackEventStream, so this is transmitted seperately
    _positionSubscription = _player.positionStream.listen((event) {
      customEvent.add({'position': event});
    });

    _sequenceSubscription = _player.sequenceStream.listen((event) {
      log(event.toString());
    });
    // Transmitted only on new audio load
    _durationSubscription = _player.durationStream.listen((event) {
      mediaItem.add(mediaItem.value!.copyWith(duration: _player.duration!));
    });
    _playerReady = true;
  }

  Future<void> _disposePlayer() async {
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
      if (!playing) {
        await _player.play();
        await super.play();
      } else {
        await _player.play();
        super.play();
        // await _seekRelative(Duration(seconds: -3));
      }
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
    await _disposePlayer();
    customEvent.add({'playerRunning': false});
    await super.stop();
  }

  Future<void> taskRemoved() async {
    await stop();
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
              if (_index == i) {
                await pause();
              }
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
      List<AudioSource> sources = [for (var item in items) _itemToSource(item)];
      queue.add(queue.value..insertAll(index, items));
      if (_index < index) {
        _playlist.insertAll(index, sources);
      } else {
        if (_isQueue) {
          // TODO: Unsure what needs to be done to achieve the goal (test)
          // _player.pause();
          _playlist.insertAll(index, sources);
          mediaItem.add(items.first);
          // _player.seek(firstItemStartPosition, index: 0);
          // Player starts playing newly inserted episodes.
        } else {
          // _player.pause();
          _playlist.insertAll(index, sources);
          // _player.seek(firstItemStartPosition,
          //     index: _index + sources.length);
          // Current episode's index is shifted and continues playing
        }
      }
      await play();
    }
  }

  /// Removes [number] items from [index]. Handles live removing.
  Future<void> removeQueueItemsAt(int index, {int number = 1}) async {
    if (_playerReady) {
      int end = index + number;
      if (_index! < index) {
        queue.add(queue.value..removeRange(index, end));
        _playlist.removeRange(index, end);
      } else {
        if (_isQueue) {
          // TODO: Unsure what needs to be done to achieve the goal (test)
          // _player.pause();
          queue.add(queue.value..removeRange(index, end));
          _playlist.removeRange(index, end);
          mediaItem.add(queue.value[index + number]);
          // _player.seek(firstItemStartPosition, index: 0);
          // Current episode is deleted and player starts playing the next undeleted episode
        } else {
          if (_index <= end) {
            // _player.pause();
            queue.add(queue.value..removeRange(index, end));
            _playlist.removeRange(index, end);
            mediaItem.add(queue.value[index]);
            // _player.seek(firstItemStartPosition, index: 0);
            // Current episode is deleted and player starts playing the next undeleted episode
          } else {
            // _player.pause();
            queue.add(queue.value..removeRange(index, end));
            _playlist.removeRange(index, end);
            // _player.seek(firstItemStartPosition, index: 0);
            // Current episode's index is shifted and continues playing
          }
        }
      }
      await play();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    super.seek(position);
  }

  /// Naive combined seek
  Future<void> combinedSeek(final Duration position, {int? index}) async {
    await _player.seek(position, index: index);
    super.seek(position);
  }

  Future<void> _seekRelative(Duration offset) async {
    if (mediaItem.value!.duration == 0)
      return; // TODO: Fix skipping episode by seeking beyond audio duration if duration is 0 (while loading)
    var newPosition = playbackState.value.position + offset;
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    await seek(newPosition);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final Duration position =
        Duration(seconds: queue.value[index].extras!['skipSecondsStart']);
    await combinedSeek(position, index: index);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await removeQueueItemsAt(index);
  }

  @override
  Future<void> skipToNext() async {
    if (queue.value.length - _index == 1 || _stopAtEnd) {
      await stop();
    } else {
      _player.seekToNext();
    }
  }

  Future<void> fastForward() async {
    _seekRelative(AudioService.config.fastForwardInterval);
  }

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

  /// Plays the current audio source from the start (with skips)
  Future<void> _playFromStart() async {
    AudioSession.instance.then((value) => value.setActive(true));
    if (mediaItem.value!.extras!['skipSecondsStart'] > 0 ||
        mediaItem.value!.extras!['skipSecondsEnd'] > 0) {
      _player.seek(
          Duration(seconds: mediaItem.value!.extras!['skipSecondsStart']));
    }
    if (_player.playbackEvent.processingState !=
        AudioProcessingState.buffering) {
      try {
        _player.play();
      } catch (e) {
        // _setState(processingState: AudioProcessingState.error);
      }
    }
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem item) async {
    addQueueItemsAt([item], index);
  }

  @override
  Future<dynamic> customAction(function, [argument]) async {
    switch (function) {
      case 'stopAtEnd':
        _stopAtEnd = true;
        break;
      case 'cancelStopAtEnd':
        _stopAtEnd = false;
        break;
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
      case 'setIsQueue':
        log('Argument' + argument!['isQueue'].toString());
        _isQueue = argument['isQueue'];
        break;
      default:
        super.customAction(function, argument);
    }
  }

  Future replaceQueue(List<MediaItem> newQueue) async {
    await pause();
    queue.add(newQueue);
    List<AudioSource> sources = [
      for (var item in newQueue) _itemToSource(item)
    ];
    _playlist = ConcatenatingAudioSource(
      useLazyPreparation: false,
      shuffleOrder: DefaultShuffleOrder(),
      children: sources,
    );
    _player.setAudioSource(_playlist, preload: false);
    play();
  }

  Future _setSkipSilence(bool boo) async {
    await _player.setSkipSilenceEnabled(boo);
  }

  Future _setBoostVolume(bool enabled, int gain) async {
    await _loudnessEnhancer.setEnabled(enabled);
    await _loudnessEnhancer.setTargetGain(gain / 2000);
  }

  List<MediaControl> _getControls(int? index) {
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
  }

  static AudioSource _itemToSource(MediaItem item) {
    return ClippingAudioSource(
        start: Duration(seconds: item.extras!['skipSecondsStart']),
        // end: Duration(seconds: item.extras!['skipSecondsEnd']),
        child: AudioSource.uri(Uri.parse(item.id)));
  }
}
