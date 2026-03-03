enum SavedPlaceType { home, office }

extension SavedPlaceTypeX on SavedPlaceType {
  String get key => this == SavedPlaceType.home ? 'home' : 'office';

  String get actionLabel =>
      this == SavedPlaceType.home
          ? 'Set home location'
          : 'Set office location';

  String get title =>
      this == SavedPlaceType.home ? 'Your Home' : 'Your Office';

  String get successTitle =>
      this == SavedPlaceType.home
          ? 'Home location\nsaved'
          : 'Office location\nsaved';
}
