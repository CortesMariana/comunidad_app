import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VacantesService {
  static const _base = 'https://enersishr.azurewebsites.net/api';

  // ── Organigrama / equipo ──────────────────────────────────────────────────
  // Token temporal — reemplazar cuando se implemente autenticación real
  static const _tokenTemporal = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjJEMDY5NUFCNUREQjhCMjg2RjM1OTczMkM0NjFCMjA3IiwidHlwIjoiYXQrand0In0.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmVuZXJzaXMxMC5jb20iLCJuYmYiOjE3ODQ3MzczNTIsImlhdCI6MTc4NDczNzM1MiwiZXhwIjoxNzg0NzQwOTUyLCJhdWQiOlsiSHJBcGkiLCJodHRwczovL2FjY291bnRzLmVuZXJzaXMxMC5jb20vcmVzb3VyY2VzIl0sInNjb3BlIjpbIm9wZW5pZCIsInByb2ZpbGUiLCJIckFwaS5BcHBIciIsIm9mZmxpbmVfYWNjZXNzIl0sImFtciI6WyJwd2QiXSwiY2xpZW50X2lkIjoiQ29tbXVuaXR5UFdBIiwic3ViIjoiYWNjY2E5NWEtYjc1YS00ZGJiLTk0MjctZWVhYTkxODdjZmRmIiwiYXV0aF90aW1lIjoxNzg0NzM3MzI0LCJpZHAiOiJsb2NhbCIsIkVtcGxlYWRvSWQiOiI4ZjZkYzA1NS04NzNiLTQ2ODMtYjJiZS03OTBmMmRmNjI3ZDEiLCJDb2xhYm9yYWRvciI6Ik1pZ3VlbCBSb2RyaWd1ZXoiLCJzaWQiOiIxREY3MTgzNjM5RkQ5MTA2Q0JFM0EyNjU4NEM1NTdCRCIsImp0aSI6IjI5REI3M0UyQ0FFREJGREVFRTE2OTgxM0UwOTkzOUVGIn0.TX0i5iuYEy-eOA6xsCWH1ezfe0CR9NBiRBJQhtr0wzs_1JdgIVTheAWyYwQ8G1NtwpAeBj6nAxSzFf5VQwTl8K6rG54-R2e-7dxXg2fVhQb-AJG3MoL0yv_LS45ofiqneEiMJIkVxOrsvOt0aqNv_aPNZRl6TpWBVOyaW-9Uf-zwnU_DEJ1RziU8EXCk1-Vm9djFGQTZRKtA5259woYDPmNflLUoaUzM-D-SBLBE14OmxxxD1Jhe4l_QR3e6d6azM7GRTM47UWicRm6Cc1RdqYgwcjo4cZFdbmLlPAdXnuTCsJZAOWldhq6Ok2vyUmqCFEB9APq4yuqmjou2i5BuOA';

  Future<OrganigramaModel?> obtenerEquipo(String empleadoId) async {
    try {
      final uri = Uri.parse('$_base/Equipo/Asistencia?empleadoId=$empleadoId');
      final res = await http.get(uri, headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_tokenTemporal',
      });
      print('STATUS: ${res.statusCode}');
      if (res.statusCode != 200) return null;
      return OrganigramaModel.desdeMap(jsonDecode(res.body));
    } catch (e) {
      print('ERROR obtenerEquipo: $e');
      return null;
    }
  }

  // ── Mis solicitudes de vacante ────────────────────────────────────────────
  Future<List<SolicitudVacanteModel>> obtenerMisSolicitudes(
      String empleadoId) async {
    try {
      final res = await http.get(Uri.parse(
          '$_base/SolicitudesVacante/MisSolicitudes?empleadoId=$empleadoId'));
      if (res.statusCode != 200) return [];
      final lista = jsonDecode(res.body) as List;
      return lista.map((e) => SolicitudVacanteModel.desdeMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Puestos disponibles ───────────────────────────────────────────────────
  Future<List<PuestoModel>> obtenerPuestos() async {
    try {
      final res =
      await http.get(Uri.parse('$_base/puestos/puestos'));
      if (res.statusCode != 200) return [];
      final lista = jsonDecode(res.body) as List;
      return lista.map((e) => PuestoModel.desdeMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Crear solicitud de vacante ────────────────────────────────────────────
  Future<bool> crearSolicitud({
    required String puestoId,
    required String solicitanteId,
    required String observaciones,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/SolicitudesVacante/Crear'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'puestoId': puestoId,
          'solicitanteId': solicitanteId,
          'observaciones': observaciones,
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

class MiembroEquipoModel {
  final String empleadoId;
  final String nombre;
  final String nombreCompleto;
  final String fotografiaMiniatura;
  final DateTime? entrada;
  final DateTime? salida;

  MiembroEquipoModel({
    required this.empleadoId,
    required this.nombre,
    required this.nombreCompleto,
    required this.fotografiaMiniatura,
    this.entrada,
    this.salida,
  });

  factory MiembroEquipoModel.desdeMap(Map<String, dynamic> m) =>
      MiembroEquipoModel(
        empleadoId: m['empleadoId'] ?? '',
        nombre: m['nombre'] ?? '',
        nombreCompleto: m['nombreCompleto'] ?? '',
        fotografiaMiniatura: m['fotografiaMiniatura'] ?? '',
        entrada: m['entrada'] != null
            ? DateTime.tryParse(m['entrada'])
            : null,
        salida: m['salida'] != null
            ? DateTime.tryParse(m['salida'])
            : null,
      );

  bool get estaActivo => entrada != null && salida == null;
  bool get noRegistro => entrada == null;

  String get iniciales {
    final p = nombreCompleto.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return p.isNotEmpty ? p[0][0].toUpperCase() : '?';
  }

  Color get colorAsistencia {
    if (estaActivo) return const Color(0xFF00B37E);
    if (noRegistro) return const Color(0xFFFF6B35);
    return const Color(0xFF009BDF);
  }

  String get etiquetaAsistencia {
    if (estaActivo) return 'En oficina';
    if (noRegistro) return 'Sin registro';
    return 'Salió';
  }
}

class JefeDirectoModel {
  final String empleadoId;
  final String nombre;
  final String nombreCompleto;
  final String fotografiaMiniatura;

  JefeDirectoModel({
    required this.empleadoId,
    required this.nombre,
    required this.nombreCompleto,
    required this.fotografiaMiniatura,
  });

  factory JefeDirectoModel.desdeMap(Map<String, dynamic> m) =>
      JefeDirectoModel(
        empleadoId: m['empleadoId'] ?? '',
        nombre: m['nombre'] ?? '',
        nombreCompleto: m['nombreCompleto'] ?? '',
        fotografiaMiniatura: m['fotografiaMiniatura'] ?? '',
      );

  String get iniciales {
    final p = nombreCompleto.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return p.isNotEmpty ? p[0][0].toUpperCase() : '?';
  }
}

class OrganigramaModel {
  final JefeDirectoModel? jefeDirecto;
  final List<MiembroEquipoModel> equipo;

  OrganigramaModel({this.jefeDirecto, required this.equipo});

  factory OrganigramaModel.desdeMap(Map<String, dynamic> m) =>
      OrganigramaModel(
        jefeDirecto: m['jefeDirecto'] != null
            ? JefeDirectoModel.desdeMap(m['jefeDirecto'])
            : null,
        equipo: ((m['equipo'] as List?) ?? [])
            .map((e) => MiembroEquipoModel.desdeMap(e))
            .toList(),
      );
}

class SolicitudVacanteModel {
  final String id;
  final String puesto;
  final int estado; // 0=Pendiente, 1=Aprobado, 2=Rechazado

  SolicitudVacanteModel({
    required this.id,
    required this.puesto,
    required this.estado,
  });

  factory SolicitudVacanteModel.desdeMap(Map<String, dynamic> m) =>
      SolicitudVacanteModel(
        id: m['id'] ?? '',
        puesto: m['puesto'] ?? '',
        estado: m['estado'] ?? 0,
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
}

class PuestoModel {
  final String id;
  final String nombre;
  final String descripcion;

  PuestoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  factory PuestoModel.desdeMap(Map<String, dynamic> m) => PuestoModel(
    id: m['id'] ?? '',
    nombre: m['nombre'] ?? '',
    descripcion: m['descripcion'] ?? '',
  );
}