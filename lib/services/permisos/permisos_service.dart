import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PermisosService {
  static const _base = 'https://enersishr.azurewebsites.net/api/Permisos';

  // ── Mis permisos ──────────────────────────────────────────────────────────
  Future<MisPermisosModel?> obtenerMisPermisos(String colaboradorId) async {
    try {
      final res = await http.get(
          Uri.parse('$_base/MisPermisos?colaboradorId=$colaboradorId'));
      if (res.statusCode != 200) return null;
      return MisPermisosModel.desdeMap(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }

  // ── Crear permiso ─────────────────────────────────────────────────────────
  Future<bool> crearPermiso({
    required String colaboradorId,
    required DateTime fecha,
    required DateTime horaInicio,
    required DateTime horaFin,
    required String motivo,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/Crear?colaboradorId=$colaboradorId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'colaboradorId': colaboradorId,
          'fecha': fecha.toIso8601String(),
          'horaInicio': horaInicio.toIso8601String(),
          'horaFin': horaFin.toIso8601String(),
          'motivo': motivo,
        }),
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

class MisPermisosModel {
  final List<PermisoModel> permisos;
  final double totalHorasAprobadasMes;

  MisPermisosModel({
    required this.permisos,
    required this.totalHorasAprobadasMes,
  });

  factory MisPermisosModel.desdeMap(Map<String, dynamic> m) =>
      MisPermisosModel(
        permisos: ((m['permisos'] as List?) ?? [])
            .map((e) => PermisoModel.desdeMap(e))
            .toList(),
        totalHorasAprobadasMes:
        (m['totalHorasAprobadasMes'] as num?)?.toDouble() ?? 0,
      );
}

class PermisoModel {
  final String id;
  final String colaboradorId;
  final String colaborador;
  final DateTime fecha;
  final DateTime horaInicio;
  final DateTime horaFin;
  final double horasSolicitadas;
  final String motivo;
  final int estado;  // 0=Pendiente, 1=Aprobado, 2=Rechazado
  final DateTime fechaSolicitud;

  PermisoModel({
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

  factory PermisoModel.desdeMap(Map<String, dynamic> m) => PermisoModel(
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

  String get etiquetaEstado {
    switch (estado) {
      case 0: return 'Pendiente';
      case 1: return 'Aprobado';
      case 2: return 'Rechazado';
      default: return 'Desconocido';
    }
  }

  Color get colorEstado {
    switch (estado) {
      case 0: return const Color(0xFFFF6B35);
      case 1: return const Color(0xFF00B37E);
      case 2: return const Color(0xFFF32836);
      default: return Colors.grey;
    }
  }

  String get horasTexto {
    final h = horasSolicitadas.toInt();
    final m = ((horasSolicitadas - h) * 60).toInt();
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}