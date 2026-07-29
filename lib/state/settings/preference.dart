import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../episode_state.dart';
import '../../type/playlist.dart';
import '../../util/helpers.dart';
import '../../local_storage/key_value_storage.dart';

/// Interface of a preference.
abstract interface class PreferenceInterface<T> {
  /// Function to get value from legacy [KeyValueStorage].
  Future<T?> Function()? get getLegacy;

  /// Function to verify that the value is valid.
  /// Not called automatically on set, assumed to be called
  /// externally if it's possible to submit invalid values.
  Future<bool> Function(T value)? verify;

  /// Get current value.
  T get();

  /// Set new value.
  Future<void> set(T newValue);

  /// Set value to default.
  Future<void> reset();
}

typedef Pref<T> = PreferenceInterface<T>;

/// Basic wrapper for shared preferences.
sealed class Preference<T> implements PreferenceInterface<T> {
  /// Key the preference is stored at.
  final String key;

  /// Default value of the preference.
  final T defaultValue;

  /// Shared preferences instance to use.
  final SharedPreferencesWithCache prefs;

  /// Callback to call on value change.
  final void Function()? updateCallback;

  /// Function to get value from legacy [KeyValueStorage].
  @override
  final Future<T?> Function()? getLegacy;

  /// Function to verify that the value is valid.
  /// Not called automatically on set, assumed to be called
  /// externally if it's possible to submit invalid values.
  @override
  Future<bool> Function(T value)? verify;

  Preference(
    this.prefs, {
    required this.key,
    required this.defaultValue,
    this.updateCallback,
    this.getLegacy,
    this.verify,
  });

  /// Get current value.
  @override
  T get() {
    var value = _getImpl();
    if (value == null) {
      _setImpl(defaultValue);
      value = defaultValue;
    }
    return value!;
  }

  /// Set new value.
  @override
  Future<void> set(T newValue) async {
    if (newValue != get()) {
      await _setImpl(newValue);
      updateCallback?.call();
    }
  }

  /// Set value to default.
  @override
  Future<void> reset() async {
    await _setImpl(defaultValue);
    updateCallback?.call();
  }

  /// Type specific implementation of get().
  T? _getImpl();

  /// Type specific implementation of set().
  Future<void> _setImpl(T newValue);
}

class BoolPreference extends Preference<bool> {
  BoolPreference(
    super.prefs, {
    required super.key,
    required super.defaultValue,
    super.updateCallback,
    super.getLegacy,
    super.verify,
  });

  @override
  bool? _getImpl() => prefs.getBool(key);

  @override
  Future<void> _setImpl(bool newValue) => prefs.setBool(key, newValue);
}

class IntPreference extends Preference<int> {
  IntPreference(
    super.prefs, {
    required super.key,
    required super.defaultValue,
    super.updateCallback,
    super.getLegacy,
    super.verify,
  });

  @override
  int? _getImpl() => prefs.getInt(key);

  @override
  Future<void> _setImpl(int newValue) => prefs.setInt(key, newValue);
}

class DoublePreference extends Preference<double> {
  DoublePreference(
    super.prefs, {
    required super.key,
    required super.defaultValue,
    super.updateCallback,
    super.getLegacy,
    super.verify,
  });

  @override
  double? _getImpl() => prefs.getDouble(key);

  @override
  Future<void> _setImpl(double newValue) => prefs.setDouble(key, newValue);
}

class StringPreference extends Preference<String> {
  StringPreference(
    super.prefs, {
    required super.key,
    required super.defaultValue,
    super.updateCallback,
    super.getLegacy,
    super.verify,
  });

  @override
  String? _getImpl() => prefs.getString(key);

  @override
  Future<void> _setImpl(String newValue) => prefs.setString(key, newValue);
}

class StringListPreference extends Preference<List<String>> {
  StringListPreference(
    super.prefs, {
    required super.key,
    required super.defaultValue,
    super.updateCallback,
    super.getLegacy,
    super.verify,
  });

  @override
  List<String>? _getImpl() => prefs.getStringList(key);

  @override
  Future<void> _setImpl(List<String> newValue) =>
      prefs.setStringList(key, newValue);
}

/// Preference that saves a complex type via serialization.
sealed class ProxyPreference<T, S, P extends Preference<S>>
    implements PreferenceInterface<T> {
  /// Convert outward facing type to the serialized one.
  S Function(T value) serialize;

  /// Convert serialized type to the outward facing one.
  T Function(S serial) deserialize;

  /// Proxied preference.
  final P inner;

  /// Function to get value from legacy [KeyValueStorage].
  @override
  final Future<T?> Function()? getLegacy;

  /// Function to verify that the value is valid.
  /// Not called automatically on set, assumed to be called
  /// externally if it's possible to submit invalid values.
  @override
  Future<bool> Function(T value)? verify;

  ProxyPreference(
    this.inner, {
    required this.serialize,
    required this.deserialize,
    this.getLegacy,
    this.verify,
  });

  @override
  T get() => deserialize(inner.get());

  @override
  Future<void> set(T newValue) => inner.set(serialize(newValue));

  @override
  Future<void> reset() => inner.reset();
}

class BoolProxyPreference<T> extends ProxyPreference<T, bool, BoolPreference> {
  BoolProxyPreference(
    SharedPreferencesWithCache prefs, {
    required String key,
    required T defaultValue,
    void Function()? updateCallback,
    super.getLegacy,
    super.verify,
    required super.serialize,
    required super.deserialize,
  }) : super(
         BoolPreference(
           prefs,
           key: key,
           defaultValue: serialize(defaultValue),
           updateCallback: updateCallback,
         ),
       );
}

class IntProxyPreference<T> extends ProxyPreference<T, int, IntPreference> {
  IntProxyPreference(
    SharedPreferencesWithCache prefs, {
    required String key,
    required T defaultValue,
    void Function()? updateCallback,
    super.getLegacy,
    super.verify,
    required super.serialize,
    required super.deserialize,
  }) : super(
         IntPreference(
           prefs,
           key: key,
           defaultValue: serialize(defaultValue),
           updateCallback: updateCallback,
         ),
       );
}

class DoubleProxyPreference<T>
    extends ProxyPreference<T, double, DoublePreference> {
  DoubleProxyPreference(
    SharedPreferencesWithCache prefs, {
    required String key,
    required T defaultValue,
    void Function()? updateCallback,
    super.getLegacy,
    super.verify,
    required super.serialize,
    required super.deserialize,
  }) : super(
         DoublePreference(
           prefs,
           key: key,
           defaultValue: serialize(defaultValue),
           updateCallback: updateCallback,
         ),
       );
}

class StringProxyPreference<T>
    extends ProxyPreference<T, String, StringPreference> {
  StringProxyPreference(
    SharedPreferencesWithCache prefs, {
    required String key,
    required T defaultValue,
    void Function()? updateCallback,
    super.getLegacy,
    super.verify,
    required super.serialize,
    required super.deserialize,
  }) : super(
         StringPreference(
           prefs,
           key: key,
           defaultValue: serialize(defaultValue),
           updateCallback: updateCallback,
         ),
       );
}

class StringListProxyPreference<T extends Iterable>
    extends ProxyPreference<T, List<String>, StringListPreference> {
  StringListProxyPreference(
    SharedPreferencesWithCache prefs, {
    required String key,
    required T defaultValue,
    void Function()? updateCallback,
    super.getLegacy,
    super.verify,
    required super.serialize,
    required super.deserialize,
  }) : super(
         StringListPreference(
           prefs,
           key: key,
           defaultValue: serialize(defaultValue),
           updateCallback: updateCallback,
         ),
       );
}

class DateTimePreference extends IntProxyPreference<DateTime> {
  DateTimePreference(
    super.prefs, {
    required super.key,
    required super.defaultValue,
    super.updateCallback,
    super.getLegacy,
    super.verify,
  }) : super(
         serialize: (value) => value.millisecondsSinceEpoch,
         deserialize: (serial) => DateTime.fromMillisecondsSinceEpoch(serial),
       );
}

class DurationPreference extends IntProxyPreference<Duration> {
  DurationPreference(
    super.prefs, {
    required super.key,
    required super.defaultValue,
    super.updateCallback,
    super.getLegacy,
    super.verify,
  }) : super(
         serialize: (value) => value.inMilliseconds,
         deserialize: (serial) => Duration(milliseconds: serial),
       );
}

class TimeOfDayPreference extends IntProxyPreference<TimeOfDay> {
  TimeOfDayPreference(
    super.prefs, {
    required super.key,
    required super.defaultValue,
    super.updateCallback,
    super.getLegacy,
    super.verify,
  }) : super(
         serialize: (value) => value.hour * 60 + value.minute,
         deserialize: (serial) => minutesToTimeOfDay(serial),
       );
}

class KeyValueStorageUnconverted {
  final String key;
  const KeyValueStorageUnconverted(this.key);

  Future<List<Playlist>> getPlaylists(EpisodeState eState) async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getString(key) == null) {
      var playlist = Playlist('Queue');
      await prefs.setString(
        key,
        json.encode({
          'playlists': [playlist.toJson()],
        }),
      );
    }
    final playlists = json.decode(prefs.getString(key)!)['playlists'];
    List<Playlist> result = [];
    for (var playlist in playlists) {
      if (playlist.containsKey('episodeList')) {
        final urlList = List<String>.from(playlist['episodeList']);
        List<int> idList = await eState.getEpisodes(episodeUrls: urlList);
        List<int> sortedList = List<int>.filled(idList.length, -1);
        for (var id in idList) {
          sortedList[urlList.indexOf(eState[id].enclosureUrl)] = id;
        }
        playlist['episodeIdList'] = sortedList;
      }
      result.add(Playlist.fromJson(playlist));
    }
    return result;
  }

  Future<bool> savePlaylists(List<Playlist> playlists) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.setString(
      key,
      json.encode({
        'playlists': [for (var p in playlists) p.toJson()],
      }),
    );
  }

  Future<bool> savePlayerState(
    String playlist,
    int episodeIndex,
    int position,
  ) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(key, [
      playlist,
      episodeIndex.toString(),
      position.toString(),
    ]);
  }

  Future<(String, int, int)> getPlayerState() async {
    var prefs = await SharedPreferences.getInstance();
    List<String>? saved = prefs.getStringList(key);
    if (saved == null) {
      await savePlayerState('', 0, 0);
      saved = ['', '0', '0'];
    }
    int episodeIndex = 0;
    int position = 0;
    try {
      episodeIndex = int.parse(saved[1]);
    } catch (e) {
      if (e is! FormatException) {
        rethrow;
      }
    }
    position = int.parse(saved[2]);
    return (saved[0], episodeIndex, position);
  }
}
