/// An unholy mash of a [List] and a [Map]
class ListedMap<K, V> {
  final List<K> _keys;
  final Map<K, V> _map;

  new _({required this._keys, required this._map});
  new blank() : _keys = [], _map = {};
  bool any(bool Function(K element) test) => _keys.any(test);
  ListedMap<RK, RV> cast<RK, RV>() =>
      ._(keys: _keys.cast<RK>(), map: _map.cast<RK, RV>());

  K elementAt(int index) => _keys[index];
  bool every(bool Function(K element) test) => _keys.every(test);
  K get first => _keys.first;
  K firstWhere(bool Function(K element) test, {K Function()? orElse}) =>
      _keys.firstWhere(test);
  void forEach(void Function(K key, V value) action) => _map.forEach(action);
  bool get isEmpty => _keys.isEmpty;
  bool get isNotEmpty => _keys.isNotEmpty;
  Iterator<K> get iterator => _keys.iterator;
  K get last => _keys.last;
  K lastWhere(bool Function(K element) test, {K Function()? orElse}) =>
      _keys.lastWhere(test, orElse: orElse);
  int get length => _keys.length;
  ListedMap<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K k, V v) convert) {
    final newMap = _map.map(convert);
    return ._(keys: newMap.keys.toList(), map: newMap);
  }

  K get single => _keys.single;
  K singleWhere(bool Function(K element) test, {K Function()? orElse}) =>
      _keys.singleWhere(test, orElse: orElse);
  Iterable<K> skip(int count) => _keys.skip(count);
  Iterable<K> skipWhile(bool Function(K value) test) => _keys.skipWhile(test);
  Iterable<K> take(int count) => _keys.take(count);
  Iterable<K> takeWhile(bool Function(K value) test) => _keys.takeWhile(test);
  List<K> toList({bool growable = true}) => _keys.toList();
  Set<K> toSet() => _keys.toSet();
  Iterable<K> where(bool Function(K element) test) => _keys.where(test);
  Iterable<T> whereType<T>() => _keys.whereType<T>();
  V? operator [](Object? key) => _map[key];
  void operator []=(K key, V value) {
    if (!containsKey(key)) _keys.add(key);
    _map[key] = value;
  }

  void addAll(Map<K, V> other) {
    _map.addAll(other);
    _keys.addAll(other.keys);
  }

  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    _map.addEntries(newEntries);
    _keys.addAll(newEntries.map((e) => e.key));
  }

  void clear() {
    _map.clear();
    _keys.clear();
  }

  bool containsKey(Object? key) => _map.containsKey(key);
  bool containsValue(Object? value) => _map.containsValue(value);
  Iterable<MapEntry<K, V>> get entries => _map.entries;
  List<K> get keys => _keys;
  V putIfAbsent(K key, V Function() ifAbsent) => _map.putIfAbsent(key, () {
    _keys.add(key);
    return ifAbsent();
  });
  V? remove(Object? key) {
    _keys.remove(key);
    return _map.remove(key);
  }

  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) =>
      _map.update(key, update, ifAbsent: ifAbsent);
  void updateAll(V Function(K key, V value) update) => _map.updateAll(update);
  Iterable<V> get values => _map.values;
}
