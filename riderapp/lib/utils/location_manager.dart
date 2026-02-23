import 'package:shared_preferences/shared_preferences.dart';

class LocationManager {
  static final LocationManager _instance = LocationManager._internal();
  factory LocationManager() => _instance;
  LocationManager._internal();

  final List<Function()> _listeners = [];
  static const String _storageKey = 'recent_locations';
  static const int _maxLocations = 5;

  // Add a listener for location updates
  void addListener(Function() listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  // Remove a listener
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // Get all recent locations
  Future<List<Map<String, dynamic>>> getRecentLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocations = prefs.getStringList(_storageKey);
      
      if (savedLocations != null && savedLocations.isNotEmpty) {
        List<Map<String, dynamic>> loadedLocations = [];
        
        for (String location in savedLocations) {
          final parts = location.split('|||');
          if (parts.length >= 2) {
            loadedLocations.add({
              'name': parts[0],
              'address': parts[1],
              'timestamp': parts.length > 2 ? parts[2] : DateTime.now().toString(),
            });
          }
        }
        
        // Sort by timestamp (newest first)
        loadedLocations.sort((a, b) {
          final timeA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
          final timeB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
          return timeB.compareTo(timeA);
        });
        
        return loadedLocations;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting recent locations: $e');
      return [];
    }
  }

  // Add a new recent location
  Future<void> addRecentLocation(String name, String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocations = prefs.getStringList(_storageKey) ?? [];
      
      // Check if location already exists
      bool exists = savedLocations.any((loc) {
        final parts = loc.split('|||');
        return parts.length >= 2 && parts[1].toLowerCase() == address.toLowerCase();
      });
      
      if (!exists) {
        final newLocation = '$name|||$address|||${DateTime.now().toString()}';
        final updatedLocations = [newLocation, ...savedLocations];
        
        // Keep only last _maxLocations
        if (updatedLocations.length > _maxLocations) {
          updatedLocations.removeRange(_maxLocations, updatedLocations.length);
        }
        
        await prefs.setStringList(_storageKey, updatedLocations);
        
        // Notify listeners
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding recent location: $e');
    }
  }

  // Clear all locations
  Future<void> clearAllLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      
      // Notify listeners
      _notifyListeners();
    } catch (e) {
      debugPrint('Error clearing locations: $e');
    }
  }

  // Remove a specific location
  Future<void> removeLocation(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocations = prefs.getStringList(_storageKey) ?? [];
      
      final updatedLocations = savedLocations.where((loc) {
        final parts = loc.split('|||');
        return !(parts.length >= 2 && parts[1] == address);
      }).toList();
      
      await prefs.setStringList(_storageKey, updatedLocations);
      
      // Notify listeners
      _notifyListeners();
    } catch (e) {
      debugPrint('Error removing location: $e');
    }
  }
}
