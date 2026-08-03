import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/historia_model.dart';
import '../../config/app_config.dart';
import '../../config/usuario_config.dart';

class HistoriasService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _col => _db.collection(AppConfig.historias);

  // ── Activas para Home ─────────────────────────────────────────────────────
  Stream<List<HistoriaModel>> obtenerActivas() {
    final ahora = Timestamp.now();
    return _col
        .where('estado', isEqualTo: 'aprobado')
        .where('expiraEn', isGreaterThan: ahora)
        .orderBy('expiraEn')
        .snapshots()
        .map((snap) => snap.docs
        .map((d) =>
        HistoriaModel.desdeMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  // ── Pendientes para control de contenido ─────────────────────────────────
  Stream<List<HistoriaModel>> obtenerPendientes() {
    return _col
        .where('estado', isEqualTo: 'pendiente')
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) =>
        HistoriaModel.desdeMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  // ── Crear ─────────────────────────────────────────────────────────────────
  Future<String?> crear(HistoriaModel historia) async {
    try {
      final doc = await _col.add(historia.aMap());
      return doc.id;
    } catch (e) {
      return null;
    }
  }

  // ── Aprobar ───────────────────────────────────────────────────────────────
  Future<bool> aprobar(String id) async {
    try {
      await _col.doc(id).update({
        'estado': 'aprobado',
        'aprobadoEn': Timestamp.now(),
        'aprobadoPor': UsuarioConfig.usuarioId,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Rechazar ──────────────────────────────────────────────────────────────
  Future<bool> rechazar(String id, String motivo) async {
    try {
      await _col.doc(id).update({
        'estado': 'rechazado',
        'motivoRechazo': motivo,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Eliminar ──────────────────────────────────────────────────────────────
  Future<bool> eliminar(String id) async {
    try {
      await _col.doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Marcar vista ─────────────────────────────────────────────────────────
  Future<void> marcarVista(String id) async {
    final uid = UsuarioConfig.usuarioId;
    final ref = _col.doc(id);
    final snap = await ref.get();
    if (!snap.exists) return;
    final vistoPor =
    List<String>.from((snap.data() as Map)['vistoPor'] ?? []);
    if (!vistoPor.contains(uid)) {
      await ref.update({
        'vistas': FieldValue.increment(1),
        'vistoPor': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // ── Storage ───────────────────────────────────────────────────────────────
  Future<String?> subirMedia(File archivo, {bool esVideo = false}) async {
    try {
      final ext = esVideo ? 'mp4' : 'jpg';
      final ref = _storage
          .ref('historias/${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putFile(archivo);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}