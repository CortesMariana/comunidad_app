import 'dart:convert';
import 'package:http/http.dart' as http;

class VacacionesService {
  static const _base = 'https://enersishr.azurewebsites.net/api/Vacaciones';

  // ── Solicitudes del empleado ──────────────────────────────────────────────
  Future<List<SolicitudVacacionesModel>> obtenerSolicitudes(
      String empleadoId) async {
    try {
      final res = await http.get(
          Uri.parse('$_base/SolicitudesEmpleado?empleadoId=$empleadoId'));
      if (res.statusCode != 200) return [];
      final lista = jsonDecode(res.body) as List;
      return lista.map((e) => SolicitudVacacionesModel.desdeMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Conteo de días ────────────────────────────────────────────────────────
  Future<ConteoVacacionesModel?> obtenerConteo(String empleadoId) async {
    try {
      final res = await http.get(
          Uri.parse('$_base/MisVacacionesConteo?empleadoId=$empleadoId'));
      if (res.statusCode != 200) return null;
      return ConteoVacacionesModel.desdeMap(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }

  // ── Crear solicitud ───────────────────────────────────────────────────────
  Future<bool> crearSolicitud({
    required String empleadoId,
    required int tipo,
    required List<DateTime> fechas,
    required String comentarios,
  }) async {
    try {
      final body = jsonEncode({
        'empleadoId': empleadoId,
        'tipo': tipo,
        'fechas': fechas.map((f) => f.toIso8601String()).toList(),
        'comentarios': comentarios,
      });
      final res = await http.post(
        Uri.parse('$_base/Solicitud?empleadoId=$empleadoId'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────

class SolicitudVacacionesModel {
  final String id;
  final int tipo;           // 1 = Vacaciones, 2 = Día personal
  final DateTime fechaSolicitud;
  final String comentarios;
  final int conteoDias;
  final int estatus;        // 1=Pendiente, 2=Aprobado, 3=Rechazado
  final List<DateTime> fechasSolicitadas;

  SolicitudVacacionesModel({
    required this.id,
    required this.tipo,
    required this.fechaSolicitud,
    required this.comentarios,
    required this.conteoDias,
    required this.estatus,
    required this.fechasSolicitadas,
  });

  factory SolicitudVacacionesModel.desdeMap(Map<String, dynamic> m) =>
      SolicitudVacacionesModel(
        id: m['id'] ?? '',
        tipo: m['tipo'] ?? 1,
        fechaSolicitud:
        DateTime.tryParse(m['fechaSolicitud'] ?? '') ?? DateTime.now(),
        comentarios: m['comentarios'] ?? '',
        conteoDias: m['conteoDias'] ?? 0,
        estatus: m['estatus'] ?? 1,
        fechasSolicitadas: ((m['fechasSolicitadas'] as List?) ?? [])
            .map((f) => DateTime.tryParse(f ?? '') ?? DateTime.now())
            .toList(),
      );

  String get etiquetaTipo => tipo == 1 ? 'Vacaciones' : 'Día personal';

  String get etiquetaEstatus {
    switch (estatus) {
      case 1: return 'Pendiente';
      case 2: return 'Aprobado';
      case 3: return 'Rechazado';
      default: return 'Desconocido';
    }
  }
}

class ConteoVacacionesModel {
  final int solicitados;
  final int aprobados;
  final int descansados;

  ConteoVacacionesModel({
    required this.solicitados,
    required this.aprobados,
    required this.descansados,
  });

  factory ConteoVacacionesModel.desdeMap(Map<String, dynamic> m) =>
      ConteoVacacionesModel(
        solicitados: m['solicitados'] ?? 0,
        aprobados: m['aprobados'] ?? 0,
        descansados: m['descansados'] ?? 0,
      );
}