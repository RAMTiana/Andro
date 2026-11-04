/// Version par défaut : rien à faire (utilisée si aucune plateforme connue).
Future<void> initDbFactory() async {}

/// Chemin de la base propre à la plateforme, ou null pour le chemin habituel.
Future<String?> platformDbPath(String name) async => null;
