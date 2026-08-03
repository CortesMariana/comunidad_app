import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/app_config.dart';
import '../../config/usuario_config.dart';
import '../../models/reporte_model.dart';
import '../historias/historias_service.dart';
import '../publicaciones/publicaciones_service.dart';
import '../reels/reels_service.dart';

class ReportesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PublicacionesService _pubService = PublicacionesService();
  final ReelsService _reelsService = ReelsService();
  final HistoriasService _historiasService = HistoriasService();

  CollectionReference get _col => _db.collection(AppConfig.reportes);

  // ── Crear reporte ─────────────────────────────────────────────────────────
  Future<void> reportar({
    required String tipo,        // publicacion | reel | historia | comentario
    required String contenidoId,
    required String motivo,
    String detalles = '',
  }) async {
    final reporte = ReporteModel(
      tipo: tipo,
      contenidoId: contenidoId,
      reportadoPor: UsuarioConfig.usuarioId,
      nombreReportador: UsuarioConfig.nombreUsuario,
      motivo: motivo,
      detalles: detalles,
      creadoEn: Timestamp.now(),
    );
    await _col.add(reporte.aMap());
  }

  // ── Obtener reportes pendientes ───────────────────────────────────────────
  Stream<List<ReporteModel>> obtenerPendientes() {
    return _col
        .where('estado', isEqualTo: 'pendiente')
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => ReporteModel.desdeMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  // ── Eliminar contenido reportado ──────────────────────────────────────────
  Future<bool> eliminarContenido(ReporteModel reporte) async {
    bool eliminado = false;

    switch (reporte.tipo) {
      case 'publicacion':
        eliminado = await _pubService.eliminar(reporte.contenidoId);
        break;
      case 'reel':
        eliminado = await _reelsService.eliminar(reporte.contenidoId);
        break;
      case 'historia':
        eliminado = await _historiasService.eliminar(reporte.contenidoId);
        break;
    }

    if (eliminado) {
      // Marcar todos los reportes de ese contenido como revisados
      final snap = await _col
          .where('contenidoId', isEqualTo: reporte.contenidoId)
          .get();
      for (final d in snap.docs) {
        await d.reference.update({
          'estado': 'revisado',
          'revisadoEn': Timestamp.now(),
          'revisadoPor': UsuarioConfig.usuarioId,
        });
      }
    }
    return eliminado;
  }

  // ── Descartar reporte ─────────────────────────────────────────────────────
  Future<void> descartar(String reporteId) async {
    await _col.doc(reporteId).update({
      'estado': 'descartado',
      'revisadoEn': Timestamp.now(),
      'revisadoPor': UsuarioConfig.usuarioId,
    });
  }
}