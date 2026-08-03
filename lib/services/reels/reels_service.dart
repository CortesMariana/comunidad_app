import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../config/app_config.dart';
import '../../config/usuario_config.dart';
import '../../models/reel_model.dart';


class ReelsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _col => _db.collection(AppConfig.reels);
  CollectionReference _comentarios(String reelId) =>
      _col.doc(reelId).collection('comentarios');

  static const categorias = [
    {'valor': 'cultura',        'etiqueta': '🎉 Cultura'},
    {'valor': 'anuncios',       'etiqueta': '📢 Anuncios'},
    {'valor': 'capacitacion',   'etiqueta': '📚 Capacitación'},
    {'valor': 'reconocimiento', 'etiqueta': '🏆 Reconocimiento'},
  ];

  // ── Obtener reels aprobados ───────────────────────────────────────────────
  Stream<List<ReelModel>> obtenerAprobados() {
    return _col
        .where('estado', isEqualTo: 'aprobado')
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ReelModel.desdeMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  // ── Obtener pendientes ────────────────────────────────────────────────────
  Stream<List<ReelModel>> obtenerPendientes() {
    return _col
        .where('estado', isEqualTo: 'pendiente')
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ReelModel.desdeMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  // ── Crear reel ────────────────────────────────────────────────────────────
  Future<String?> crear(ReelModel reel) async {
    try {
      final doc = await _col.add(reel.aMap());
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
      final docs = await _comentarios(id).get();
      for (final d in docs.docs) await d.reference.delete();
      await _col.doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Like ──────────────────────────────────────────────────────────────────
  Future<void> toggleLike(String reelId) async {
    final uid = UsuarioConfig.usuarioId;
    final ref = _col.doc(reelId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      if (likedBy.contains(uid)) {
        tx.update(ref, {
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([uid]),
        });
      } else {
        tx.update(ref, {
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([uid]),
        });
      }
    });
  }

  Future<bool> estaLikeado(String reelId) async {
    final snap = await _col.doc(reelId).get();
    if (!snap.exists) return false;
    final data = snap.data() as Map<String, dynamic>;
    return List<String>.from(data['likedBy'] ?? [])
        .contains(UsuarioConfig.usuarioId);
  }

  // ── Vistas ────────────────────────────────────────────────────────────────
  Future<void> incrementarVistas(String reelId) async {
    await _col.doc(reelId).update({'vistas': FieldValue.increment(1)});
  }

  // ── Comentarios ───────────────────────────────────────────────────────────
  Stream<List<ComentarioReelModel>> obtenerComentarios(String reelId) {
    return _comentarios(reelId)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ComentarioReelModel.desdeMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> agregarComentario(String reelId, String texto) async {
    final comentario = ComentarioReelModel(
      reelId: reelId,
      usuarioId: UsuarioConfig.usuarioId,
      nombreUsuario: UsuarioConfig.nombreUsuario,
      avatarUsuario: UsuarioConfig.avatarUsuario,
      texto: texto,
      creadoEn: Timestamp.now(),
    );
    await _comentarios(reelId).add(comentario.aMap());
    await _col.doc(reelId).update({'comentarios': FieldValue.increment(1)});
  }

  // ── Storage ───────────────────────────────────────────────────────────────
  Future<String?> subirVideo(File archivo, {Function(double)? onProgress}) async {
    try {
      final ref = _storage
          .ref('reels/${DateTime.now().millisecondsSinceEpoch}.mp4');
      final task = ref.putFile(archivo);
      if (onProgress != null) {
        task.snapshotEvents.listen((e) {
          onProgress(e.bytesTransferred / e.totalBytes);
        });
      }
      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String?> subirMiniatura(File archivo) async {
    try {
      final ref = _storage
          .ref('reels/miniaturas/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(archivo);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}