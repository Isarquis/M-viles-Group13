import 'dart:collection';

class LRUCache<K, V> {
  final int capacity;
  final _cache = LinkedHashMap<K, V>();

  LRUCache(this.capacity) {
    assert(capacity > 0, 'Capacity must be greater than 0');
  }

  V? get(K key) {
    if (!_cache.containsKey(key)) return null;


    final value = _cache.remove(key)!;
    _cache[key] = value;
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length == capacity) {
      _cache.remove(_cache.keys.first); 
    }
    _cache[key] = value;
  }

  bool contains(K key) => _cache.containsKey(key);

  void remove(K key) => _cache.remove(key);

  void clear() => _cache.clear();

  int get length => _cache.length;

  List<K> get keys => _cache.keys.toList();

  List<V> get values => _cache.values.toList();

  Map<K, V> get entries => Map.unmodifiable(_cache);
}
