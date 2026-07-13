import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../generated/l10n.dart';

/// Media control buttons for notification.
sealed class TsacdopMediaControl extends MediaControl {
  const TsacdopMediaControl({
    required super.androidIcon,
    required super.label,
    required super.action,
    required this.serial,
    required this.icon,
    super.customAction,
  });

  /// Creates a custom [MediaControl].
  TsacdopMediaControl.custom({
    required super.androidIcon,
    required super.label,
    required super.name,
    required this.serial,
    required this.icon,
    super.extras,
  }) : super.custom();

  factory TsacdopMediaControl.fromSerial(String serial) => switch (serial) {
    "play" => PlayControl(),
    "pause" => PauseControl(),
    "skipToNext" => SkipToNextControl(),
    "skipToPrevious" => SkipToPreviousControl(),
    "stop" => StopControl(),
    "fastForward" => FastForwardControl(),
    "rewind" => RewindControl(),
    "playPause" => PlayPauseControl(),
    "none" => NoneControl(),
    _ => NoneControl(),
  };

  final String serial;
  final IconData icon;
}

class PlayControl extends TsacdopMediaControl {
  PlayControl()
    : super(
        androidIcon: 'drawable/ic_stat_play_circle_filled',
        label: S.current.play,
        action: MediaAction.play,
        serial: "play",
        icon: Icons.play_arrow_rounded,
      );
}

class PauseControl extends TsacdopMediaControl {
  PauseControl()
    : super(
        androidIcon: 'drawable/ic_stat_pause_circle_filled',
        label: S.current.pause,
        action: MediaAction.pause,
        serial: "pause",
        icon: Icons.pause_rounded,
      );
}

class SkipToNextControl extends TsacdopMediaControl {
  SkipToNextControl()
    : super(
        androidIcon: 'drawable/baseline_skip_next_white_24',
        label: S.current.skipToNext,
        action: MediaAction.skipToNext,
        serial: "skipToNext",
        icon: Icons.skip_next_rounded,
      );
}

class SkipToPreviousControl extends TsacdopMediaControl {
  SkipToPreviousControl()
    : super(
        androidIcon: 'drawable/ic_action_skip_previous',
        label: S.current.skipToPrevious,
        action: MediaAction.skipToPrevious,
        serial: "skipToPrevious",
        icon: Icons.skip_previous_rounded,
      );
}

class StopControl extends TsacdopMediaControl {
  StopControl()
    : super(
        androidIcon: 'drawable/baseline_close_white_24',
        label: S.current.stop,
        action: MediaAction.stop,
        serial: "stop",
        icon: Icons.stop_rounded,
      );
}

class FastForwardControl extends TsacdopMediaControl {
  FastForwardControl()
    : super(
        androidIcon: 'drawable/baseline_fast_forward_white_24',
        label: S.current.fastForward,
        action: MediaAction.fastForward,
        serial: "fastForward",
        icon: Icons.fast_forward_rounded,
      );
}

class RewindControl extends TsacdopMediaControl {
  RewindControl()
    : super(
        androidIcon: 'drawable/baseline_fast_rewind_white_24',
        label: S.current.fastRewind,
        action: MediaAction.rewind,
        serial: "rewind",
        icon: Icons.fast_rewind_rounded,
      );
}

class PlayPauseControl extends TsacdopMediaControl {
  PlayPauseControl()
    : super(
        androidIcon: 'drawable/ic_stat_replay_10',
        label: S.current.play + S.current.pause,
        action: MediaAction.playPause,
        serial: "playPause",
        icon: Icons.adjust,
      );
}

class NoneControl extends TsacdopMediaControl {
  NoneControl()
    : super(
        androidIcon: 'drawable/ic_stat_replay_10',
        label: S.current.none,
        action: MediaAction.playPause,
        serial: "none",
        icon: Icons.remove,
      );
}
