import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfig {
  // ─── AMBIENTE ───────────────────────────────────────────────────────────────
  static const bool esDev = true; // cambiar a false para producción

  // ─── COLECCIONES ────────────────────────────────────────────────────────────
  static String col(String nombre) => esDev ? '$nombre-dev' : nombre;

  // Colecciones de contenido
  static String get publicaciones       => col('publicaciones');
  static String get reels               => col('reels');
  static String get historias           => col('historias');
  static String get banners             => col('banners');

  // Colecciones de RH / operaciones
  static String get asistencias         => col('asistencias');
  static String get solicitudesVacaciones => col('solicitudes_vacaciones');
  static String get solicitudesPermisos => col('solicitudes_permisos');
  static String get solicitudesUniformes => col('solicitudes_uniformes');
  static String get solicitudesVacantes => col('solicitudes_vacantes');
  static String get evaluacionesDesempeno => col('evaluaciones_desempeno');

  // Colecciones compartidas (mismo nombre en ambos ambientes)
  static String get usuarios            => 'usuarios';
  static String get reportes            => col('reportes');

}