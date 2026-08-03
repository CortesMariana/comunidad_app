import 'package:cloud_firestore/cloud_firestore.dart';

class ReporteModel {
  String? id;
  String tipo;              // publicacion | reel | historia | comentario
  String contenidoId;
  String reportadoPor;
  String nombreReportador;
  String motivo;
  String detalles;
  String estado;            // pendiente | revisado | descartado
  Timestamp creadoEn;
  Timestamp? revisadoEn;
  String? revisadoPor;

  ReporteModel({
    this.id,
    required this.tipo,
    required this.contenidoId,
    required this.reportadoPor,
    required this.nombreReportador,
    required this.motivo,
    this.detalles = '',
    this.estado = 'pendiente',
    required this.creadoEn,
    this.revisadoEn,
    this.revisadoPor,
  });

  Map<String, dynamic> aMap() => {
    'tipo': tipo,
    'contenidoId': contenidoId,
    'reportadoPor': reportadoPor,
    'nombreReportador': nombreReportador,
    'motivo': motivo,
    'detalles': detalles,
    'estado': estado,
    'creadoEn': creadoEn,
    'revisadoEn': revisadoEn,
    'revisadoPor': revisadoPor,
  };

  factory ReporteModel.desdeMap(String id, Map<String, dynamic> m) {
    return ReporteModel(
      id: id,
      tipo: m['tipo'] ?? '',
      contenidoId: m['contenidoId'] ?? '',
      reportadoPor: m['reportadoPor'] ?? '',
      nombreReportador: m['nombreReportador'] ?? '',
      motivo: m['motivo'] ?? '',
      detalles: m['detalles'] ?? '',
      estado: m['estado'] ?? 'pendiente',
      creadoEn: m['creadoEn'] ?? Timestamp.now(),
      revisadoEn: m['revisadoEn'],
      revisadoPor: m['revisadoPor'],
    );
  }
}