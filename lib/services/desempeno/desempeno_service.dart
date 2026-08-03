import 'dart:convert';
import 'package:http/http.dart' as http;

class DesempenoService {
  static const _base = 'https://enersishr.azurewebsites.net/api/GestionDesempeno';

  // ── Periodos publicados ───────────────────────────────────────────────────
  Future<List<PeriodoModel>> obtenerPeriodos() async {
    try {
      final res = await http.get(Uri.parse('$_base/PeriodosPublicados'));
      if (res.statusCode != 200) return [];
      final lista = jsonDecode(res.body) as List;
      return lista.map((e) => PeriodoModel.desdeMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Resultado del equipo ──────────────────────────────────────────────────
  Future<ResultadoEquipoModel?> obtenerResultadoEquipo({
    required String periodoId,
    required String colaboradorId,
  }) async {
    try {
      final uri = Uri.parse(
          '$_base/ResultadoEquipo?periodoId=$periodoId&colaboradorId=$colaboradorId');
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      return ResultadoEquipoModel.desdeMap(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }

  // ── Detalle KPIs de un colaborador ───────────────────────────────────────
  Future<DetalleColaboradorModel?> obtenerDetalleColaborador({
    required String periodoId,
    required String colaboradorId,
  }) async {
    try {
      final uri = Uri.parse(
          '$_base/PeriodoColaborador?periodoId=$periodoId&colaboradorId=$colaboradorId');
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      return DetalleColaboradorModel.desdeMap(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────

class PeriodoModel {
  final String id;
  final String nombre;
  final DateTime inicioPeriodo;
  final DateTime finPeriodo;
  final int estatus;

  PeriodoModel({
    required this.id,
    required this.nombre,
    required this.inicioPeriodo,
    required this.finPeriodo,
    required this.estatus,
  });

  factory PeriodoModel.desdeMap(Map<String, dynamic> m) => PeriodoModel(
    id: m['id'] ?? '',
    nombre: m['nombre'] ?? '',
    inicioPeriodo: DateTime.tryParse(m['inicioPeriodo'] ?? '') ?? DateTime.now(),
    finPeriodo: DateTime.tryParse(m['finPeriodo'] ?? '') ?? DateTime.now(),
    estatus: m['estatus'] ?? 0,
  );
}

class ColaboradorResumenModel {
  final String empleadoId;
  final String nombre;
  final String nombreCompleto;
  final String fotografia;
  final double totalFinal;

  ColaboradorResumenModel({
    required this.empleadoId,
    required this.nombre,
    required this.nombreCompleto,
    required this.fotografia,
    required this.totalFinal,
  });

  factory ColaboradorResumenModel.desdeMap(Map<String, dynamic> m) =>
      ColaboradorResumenModel(
        empleadoId: m['colaborador']?['empleadoId'] ?? '',
        nombre: m['colaborador']?['nombre'] ?? '',
        nombreCompleto: m['colaborador']?['nombreCompleto'] ?? '',
        fotografia: m['colaborador']?['fotografia'] ?? '',
        totalFinal: (m['totalFinal'] as num?)?.toDouble() ?? 0,
      );
}

class ResultadoEquipoModel {
  final ColaboradorResumenModel yo;
  final List<ColaboradorResumenModel> equipo;

  ResultadoEquipoModel({required this.yo, required this.equipo});

  factory ResultadoEquipoModel.desdeMap(Map<String, dynamic> m) =>
      ResultadoEquipoModel(
        yo: ColaboradorResumenModel.desdeMap(m['me'] ?? {}),
        equipo: ((m['equipo'] as List?) ?? [])
            .map((e) => ColaboradorResumenModel.desdeMap(e))
            .toList(),
      );
}

class KpiModel {
  final String id;
  final String nombre;
  final String descripcion;
  final double meta;
  final double resultado;
  final bool cumplimiento;
  final double ponderacion;
  final double resultadoFinal;

  KpiModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.meta,
    required this.resultado,
    required this.cumplimiento,
    required this.ponderacion,
    required this.resultadoFinal,
  });

  factory KpiModel.desdeMap(Map<String, dynamic> m) => KpiModel(
    id: m['id'] ?? '',
    nombre: m['nombre'] ?? '',
    descripcion: m['descripcion'] ?? '',
    meta: (m['meta'] as num?)?.toDouble() ?? 0,
    resultado: (m['resultado'] as num?)?.toDouble() ?? 0,
    cumplimiento: m['cumplimiento'] ?? false,
    ponderacion: (m['ponderacion'] as num?)?.toDouble() ?? 0,
    resultadoFinal: (m['resultadoFinal'] as num?)?.toDouble() ?? 0,
  );
}

class DetalleColaboradorModel {
  final String nombre;
  final String nombreCompleto;
  final String fotografia;
  final List<KpiModel> kpis;

  DetalleColaboradorModel({
    required this.nombre,
    required this.nombreCompleto,
    required this.fotografia,
    required this.kpis,
  });

  factory DetalleColaboradorModel.desdeMap(Map<String, dynamic> m) =>
      DetalleColaboradorModel(
        nombre: m['colaborador']?['nombre'] ?? '',
        nombreCompleto: m['colaborador']?['nombreCompleto'] ?? '',
        fotografia: m['colaborador']?['fotografia'] ?? '',
        kpis: ((m['kpIs'] as List?) ?? [])
            .map((e) => KpiModel.desdeMap(e))
            .toList(),
      );

  double get totalFinal =>
      kpis.fold(0.0, (sum, k) => sum + k.resultadoFinal) * 100;

  int get cumplidos => kpis.where((k) => k.cumplimiento).length;
}