import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/publicacion_model.dart';
import '../../config/app_config.dart';
import '../../config/usuario_config.dart';

class PublicacionesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _col => _db.collection(AppConfig.publicaciones);
  CollectionReference _comentarios(String id) =>
      _col.doc(id).collection('comentarios');
  CollectionReference _reacciones(String id) =>
      _col.doc(id).collection('reacciones');

  // ── Feed público (aprobadas + programadas cuya fecha ya pasó) ─────────────
  Stream<List<PublicacionModel>> obtenerPublicadas() {
    return _col
        .where('estado', isEqualTo: 'aprobado')
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) =>
        PublicacionModel.desdeMap(d.id, d.data() as Map<String, dynamic>))
        .where((p) {
      if (!p.estaProgramado) return true;
      return p.fechaProgramada != null &&
          !p.fechaProgramada!.isAfter(DateTime.now());
    })
        .toList());
  }

  // ── Pendientes para control de contenido ─────────────────────────────────
  Stream<List<PublicacionModel>> obtenerPendientes() {
    return _col
        .where('estado', isEqualTo: 'pendiente')
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) =>
        PublicacionModel.desdeMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  // ── Crear (siempre entra como pendiente) ──────────────────────────────────
  Future<String?> crear(PublicacionModel pub) async {
    try {
      final doc = await _col.add(pub.aMap());
      return doc.id;
    } catch (e) {
      return null;
    }
  }

  // ── Aprobar ───────────────────────────────────────────────────────────────
  Future<bool> aprobar(String id, {String? aprobadoPor}) async {
    try {
      await _col.doc(id).update({
        'estado': 'aprobado',
        'aprobadoEn': Timestamp.now(),
        'aprobadoPor': aprobadoPor ?? UsuarioConfig.usuarioId,
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

  // ── Eliminar (desde reportes) ─────────────────────────────────────────────
  Future<bool> eliminar(String id) async {
    try {
      final comentariosDocs = await _comentarios(id).get();
      for (final d in comentariosDocs.docs) {
        await d.reference.delete();
      }
      final reaccionesDocs = await _reacciones(id).get();
      for (final d in reaccionesDocs.docs) {
        await d.reference.delete();
      }
      await _col.doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Like / Unlike ─────────────────────────────────────────────────────────
  Future<void> toggleLike(String id) async {
    final uid = UsuarioConfig.usuarioId;
    final ref = _col.doc(id);
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

  Future<bool> estaLikeado(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return false;
    final data = snap.data() as Map<String, dynamic>;
    return List<String>.from(data['likedBy'] ?? [])
        .contains(UsuarioConfig.usuarioId);
  }

  // ── Reacciones ────────────────────────────────────────────────────────────
  Future<void> reaccionar(String pubId, String tipo) async {
    final uid = UsuarioConfig.usuarioId;
    final reaccionRef = _reacciones(pubId).doc(uid);
    final pubRef = _col.doc(pubId);

    await _db.runTransaction((tx) async {
      final reaccionSnap = await tx.get(reaccionRef);
      final pubSnap = await tx.get(pubRef);
      if (!pubSnap.exists) return;

      final reaccionesActuales = Map<String, int>.from(
          (pubSnap.data() as Map)['reacciones'] ?? {});

      if (reaccionSnap.exists) {
        final tipoAnterior =
        (reaccionSnap.data() as Map)['tipo'] as String;
        if (tipoAnterior == tipo) {
          tx.delete(reaccionRef);
          reaccionesActuales[tipoAnterior] =
              (reaccionesActuales[tipoAnterior] ?? 1) - 1;
          if ((reaccionesActuales[tipoAnterior] ?? 0) <= 0) {
            reaccionesActuales.remove(tipoAnterior);
          }
        } else {
          tx.set(reaccionRef,
              {'usuarioId': uid, 'tipo': tipo, 'creadoEn': Timestamp.now()});
          reaccionesActuales[tipoAnterior] =
              (reaccionesActuales[tipoAnterior] ?? 1) - 1;
          if ((reaccionesActuales[tipoAnterior] ?? 0) <= 0) {
            reaccionesActuales.remove(tipoAnterior);
          }
          reaccionesActuales[tipo] =
              (reaccionesActuales[tipo] ?? 0) + 1;
        }
      } else {
        tx.set(reaccionRef,
            {'usuarioId': uid, 'tipo': tipo, 'creadoEn': Timestamp.now()});
        reaccionesActuales[tipo] =
            (reaccionesActuales[tipo] ?? 0) + 1;
      }
      tx.update(pubRef, {'reacciones': reaccionesActuales});
    });
  }

  Future<String?> miReaccion(String pubId) async {
    final doc =
    await _reacciones(pubId).doc(UsuarioConfig.usuarioId).get();
    if (!doc.exists) return null;
    return (doc.data() as Map)['tipo'] as String?;
  }

  // ── Comentarios ───────────────────────────────────────────────────────────
  Stream<List<ComentarioModel>> obtenerComentarios(String id) {
    return _comentarios(id)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ComentarioModel.desdeMap(
        d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> agregarComentario(String pubId, String texto) async {
    final comentario = ComentarioModel(
      publicacionId: pubId,
      usuarioId: UsuarioConfig.usuarioId,
      nombreUsuario: UsuarioConfig.nombreUsuario,
      avatarUsuario: UsuarioConfig.avatarUsuario,
      texto: texto,
      creadoEn: Timestamp.now(),
    );
    await _comentarios(pubId).add(comentario.aMap());
    await _col
        .doc(pubId)
        .update({'comentarios': FieldValue.increment(1)});
  }

  // ── Storage ───────────────────────────────────────────────────────────────
  Future<String?> subirImagen(File archivo) async {
    try {
      final ref = _storage.ref(
          'publicaciones/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(archivo);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String?> subirVideo(File archivo) async {
    try {
      final ref = _storage.ref(
          'publicaciones/${DateTime.now().millisecondsSinceEpoch}.mp4');
      await ref.putFile(archivo);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}