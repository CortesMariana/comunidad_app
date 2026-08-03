import 'dart:convert';
import 'package:http/http.dart' as http;

class AutorizacionesService {
  static const _baseVac = 'https://enersishr.azurewebsites.net/api/Vacaciones';
  static const _basePer = 'https://enersishr.azurewebsites.net/api/Permisos';

  // ── Vacaciones pendientes de autorización ─────────────────────────────────
  Future<List<AutorizacionVacacionModel>> obtenerVacacionesPendientes(
      String jefeId) async {
    try {
      final res = await http.get(Uri.parse(
          '$_baseVac/AutorizacionesPendientes?jefeDirectoId=$jefeId'));
      if (res.statusCode != 200) return [];
      final lista = jsonDecode(res.body) as List;
      return lista
          .map((e) => AutorizacionVacacionModel.desdeMap(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Permisos pendientes de autorización ───────────────────────────────────
  Future<List<AutorizacionPermisoModel>> obtenerPermisosPendientes(
      String jefeId) async {
    try {
      final res = await http.get(Uri.parse(
          '$_basePer/ObtenerPendientes?jefeDirectoId=$jefeId'));
      if (res.statusCode != 200) return [];
      final lista = jsonDecode(res.body) as List;
      return lista
          .map((e) => AutorizacionPermisoModel.desdeMap(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Determinar vacación (aprobar / rechazar) ───────────────────────────────
  Future<bool> determinarVacacion({
    required String solicitudId,
    required bool aprobar,
    required String jefeId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseVac/Determinar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'solicitudId': solicitudId,
          'aprobar': aprobar,
          'jefeDirectoId': jefeId,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ── Resolver permiso (aprobar / rechazar) ─────────────────────────────────
  Future<bool> resolverPermiso({
    required String solicitudId,
    required bool aprobar,
    required String comentario,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_basePer/Resolver'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': solicitudId,
          'aprobado': aprobar,
          'comentario': comentario,
        }),
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────

class EmpleadoAutorizacionModel {
  final String id;
  final String nombreCompleto;
  final String fotografiaMiniatura;

  EmpleadoAutorizacionModel({
    required this.id,
    required this.nombreCompleto,
    required this.fotografiaMiniatura,
  });

  factory EmpleadoAutorizacionModel.desdeMap(Map<String, dynamic> m) =>
      EmpleadoAutorizacionModel(
        id: m['id'] ?? '',
        nombreCompleto: m['nombreCompleto'] ?? '',
        fotografiaMiniatura: m['fotografiaMiniatura'] ?? '',
      );

  String get iniciales {
    final partes = nombreCompleto.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return partes.isNotEmpty ? partes[0][0].toUpperCase() : '?';
  }
}

class AutorizacionVacacionModel {
  final String id;
  final int tipo;
  final String empleadoId;
  final EmpleadoAutorizacionModel empleado;
  final int estatus;
  final DateTime fechaSolicitud;
  final String comentarios;
  final int conteoDias;
  final List<DateTime> dias;

  AutorizacionVacacionModel({
    required this.id,
    required this.tipo,
    required this.empleadoId,
    required this.empleado,
    required this.estatus,
    required this.fechaSolicitud,
    required this.comentarios,
    required this.conteoDias,
    required this.dias,
  });

  factory AutorizacionVacacionModel.desdeMap(Map<String, dynamic> m) =>
      AutorizacionVacacionModel(
        id: m['id'] ?? '',
        tipo: m['tipo'] ?? 1,
        empleadoId: m['empleadoId'] ?? '',
        empleado: EmpleadoAutorizacionModel.desdeMap(
            m['empleado'] ?? {}),
        estatus: m['estatus'] ?? 0,
        fechaSolicitud:
        DateTime.tryParse(m['fechaSolicitud'] ?? '') ?? DateTime.now(),
        comentarios: m['comentarios'] ?? '',
        conteoDias: m['conteoDias'] ?? 0,
        dias: ((m['vacacionesSolicitudDias'] as List?) ?? [])
            .map((d) =>
        DateTime.tryParse(d['dia'] ?? '') ?? DateTime.now())
            .toList(),
      );

  String get etiquetaTipo => tipo == 1 ? 'Vacaciones' : 'Día personal';
}

class AutorizacionPermisoModel {
  final String id;
  final String colaboradorId;
  final String colaborador;
  final DateTime fecha;
  final DateTime horaInicio;
  final DateTime horaFin;
  final double horasSolicitadas;
  final String motivo;
  final int estado;
  final DateTime fechaSolicitud;

  AutorizacionPermisoModel({
    required this.id,
    required this.colaboradorId,
    required this.colaborador,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.horasSolicitadas,
    required this.motivo,
    required this.estado,
    required this.fechaSolicitud,
  });

  factory AutorizacionPermisoModel.desdeMap(Map<String, dynamic> m) =>
      AutorizacionPermisoModel(
        id: m['id'] ?? '',
        colaboradorId: m['colaboradorId'] ?? '',
        colaborador: m['colaborador'] ?? '',
        fecha: DateTime.tryParse(m['fecha'] ?? '') ?? DateTime.now(),
        horaInicio:
        DateTime.tryParse(m['horaInicio'] ?? '') ?? DateTime.now(),
        horaFin:
        DateTime.tryParse(m['horaFin'] ?? '') ?? DateTime.now(),
        horasSolicitadas:
        (m['horasSolicitadas'] as num?)?.toDouble() ?? 0,
        motivo: m['motivo'] ?? '',
        estado: m['estado'] ?? 0,
        fechaSolicitud:
        DateTime.tryParse(m['fechaSolicitud'] ?? '') ?? DateTime.now(),
      );

  String get iniciales {
    final partes = colaborador.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return partes.isNotEmpty ? partes[0][0].toUpperCase() : '?';
  }

  String get horasTexto {
    final h = horasSolicitadas.toInt();
    final m = ((horasSolicitadas - h) * 60).toInt();
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}