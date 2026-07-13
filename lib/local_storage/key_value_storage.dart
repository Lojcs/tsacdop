import 'package:shared_preferences/shared_preferences.dart';

class KeyValueStorage {
  final String key;
  const KeyValueStorage(this.key);

  Future<(String, int, int)> getPlayerState() async {
    var prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList(key) ?? ['', '0', '0'];
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

  Future<int?> getInt() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  Future<List<String>?> getStringList() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  Future<String?> getString() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Rreverse is used for compatite bool value save before which set true = 0, false = 1
  Future<bool?> getBool({bool reverse = false}) async {
    var prefs = await SharedPreferences.getInstance();
    var i = prefs.getInt(key);
    return switch (i) {
      0 => reverse,
      1 => !reverse,
      _ => null,
    };
  }

  Future<double?> getDouble() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }
}
