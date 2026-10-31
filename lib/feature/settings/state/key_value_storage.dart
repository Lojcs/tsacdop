import 'package:shared_preferences/shared_preferences.dart';

class KeyValueStorage {
  late final SharedPreferences backend;
  late final Future<void> ready;
  KeyValueStorage() {
    ready = _initDefault();
  }

  Future<void> _initDefault() async {
    backend = await SharedPreferences.getInstance();
  }

  KeyValueStorage.withBackend(this.backend) : ready = Future.value();

  Future<void> clear() => backend.clear();

  Future<(String, int, int)> getPlayerState(String key) async {
    await ready;
    List<String> saved = backend.getStringList(key) ?? ['', '0', '0'];
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

  Future<int?> getInt(String key) async {
    await ready;
    return backend.getInt(key);
  }

  Future<List<String>?> getStringList(String key) async {
    await ready;
    return backend.getStringList(key);
  }

  Future<String?> getString(String key) async {
    await ready;
    return backend.getString(key);
  }

  /// Rreverse is used for compatite bool value save before which set true = 0, false = 1
  Future<bool?> getBool(String key, {bool reverse = false}) async {
    await ready;
    return switch (backend.getInt(key)) {
      0 => reverse,
      1 => !reverse,
      _ => null,
    };
  }

  Future<double?> getDouble(String key) async {
    await ready;
    return backend.getDouble(key);
  }
}
