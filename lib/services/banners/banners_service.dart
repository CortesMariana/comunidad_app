import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/banner_model.dart';
import '../../config/app_config.dart';
import '../../config/usuario_config.dart';

class BannersService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _col => _db.collection(AppConfig.banners);

  // ── Activos para Home ─────────────────────────────────────────────────────
  Stream<List<BannerModel>> obtenerActivos() {
    return _col
        .where('estado', isEqualTo: 'aprobado')
        .where('activo', isEqualTo: true)
        .orderBy('orden')
        .snapshots()
        .map((snap) {
      final ahora = DateTime.now();
      return snap.docs
          .map((d) =>
          BannerModel.desdeMap(d.id, d.data() as Map<String, dynamic>))
          .where((b) =>
      b.expiraEn == null ||
          b.expiraEn!.toDate().isAfter(ahora))
          .toList();
    });
  }

  // ── Pendientes para control de contenido ─────────────────────────────────
  Stream<List<BannerModel>> obtenerPendientes() {
    return _col
        .where('estado', isEqualTo: 'pendiente')
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) =>
        BannerModel.desdeMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  // ── Crear ─────────────────────────────────────────────────────────────────
  Future<String?> crear(BannerModel banner) async {
    try {
      final doc = await _col.add(banner.aMap());
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

  // ── Storage ───────────────────────────────────────────────────────────────
  Future<String?> subirImagen(File archivo) async {
    try {
      final ref = _storage
          .ref('banners/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(archivo);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}