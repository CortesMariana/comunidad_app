import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/app_config.dart';
import '../../config/usuario_config.dart';
import '../../models/asistencia_model.dart';

class AsistenciasService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection(AppConfig.asistencias);

  String _fechaKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Registrar entrada ─────────────────────────────────────────────────────
  Future<String?> registrarEntrada({double? lat, double? lng}) async {
    final fecha = _fechaKey(DateTime.now());
    // Verificar si ya hay entrada hoy
    final snap = await _col
        .where('usuarioId', isEqualTo: UsuarioConfig.usuarioId)
        .where('fecha', isEqualTo: fecha)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) return snap.docs.first.id; // ya tiene entrada

    final asistencia = AsistenciaModel(
      usuarioId: UsuarioConfig.usuarioId,
      nombreUsuario: UsuarioConfig.nombreUsuario,
      entrada: Timestamp.now(),
      latitudEntrada: lat,
      longitudEntrada: lng,
      estado: 'pendiente',
      fecha: fecha,
    );
    final doc = await _col.add(asistencia.aMap());
    return doc.id;
  }

  // ── Registrar salida ──────────────────────────────────────────────────────
  Future<bool> registrarSalida(String asistenciaId, {double? lat, double? lng}) async {
    try {
      await _col.doc(asistenciaId).update({
        'salida': Timestamp.now(),
        'latitudSalida': lat,
        'longitudSalida': lng,
        'estado': 'completo',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Asistencia de hoy ─────────────────────────────────────────────────────
  Future<AsistenciaModel?> asistenciaHoy() async {
    final fecha = _fechaKey(DateTime.now());
    final snap = await _col
        .where('usuarioId', isEqualTo: UsuarioConfig.usuarioId)
        .where('fecha', isEqualTo: fecha)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AsistenciaModel.desdeMap(
        snap.docs.first.id, snap.docs.first.data() as Map<String, dynamic>);
  }

  // ── Historial ─────────────────────────────────────────────────────────────
  Stream<List<AsistenciaModel>> historial({int limite = 30}) {
    return _col
        .where('usuarioId', isEqualTo: UsuarioConfig.usuarioId)
        .orderBy('fecha', descending: true)
        .limit(limite)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => AsistenciaModel.desdeMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }
}