// Conditional exports pour sélectionner la bonne implémentation de base de données
// en fonction de la plateforme

export 'database_native.dart'
  if (dart.library.js_interop) 'database_web.dart'
  if (dart.library.io) 'database_native.dart';
