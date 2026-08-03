import 'package:cloud_firestore/cloud_firestore.dart';

class AsistenciaModel {
  String? id;
  String usuarioId;
  String nombreUsuario;
  Timestamp? entrada;
  Timestamp? salida;
  double? latitudEntrada;
  double? longitudEntrada;
  double? latitudSalida;
  double? longitudSalida;
  String estado;   // pendiente | completo
  String fecha;    // 'YYYY-MM-DD' para queries por día

  AsistenciaModel({
    this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    this.entrada,
    this.salida,
    this.latitudEntrada,
    this.longitudEntrada,
    this.latitudSalida,
    this.longitudSalida,
    this.estado = 'pendiente',
    required this.fecha,
  });

  Map<String, dynamic> aMap() => {
    'usuarioId': usuarioId,
    'nombreUsuario': nombreUsuario,
    'entrada': entrada,
    'salida': salida,
    'latitudEntrada': latitudEntrada,
    'longitudEntrada': longitudEntrada,
    'latitudSalida': latitudSalida,
    'longitudSalida': longitudSalida,
    'estado': estado,
    'fecha': fecha,
  };

  factory AsistenciaModel.desdeMap(String id, Map<String, dynamic> m) {
    return AsistenciaModel(
      id: id,
      usuarioId: m['usuarioId'] ?? '',
      nombreUsuario: m['nombreUsuario'] ?? '',
      entrada: m['entrada'],
      salida: m['salida'],
      latitudEntrada: (m['latitudEntrada'] as num?)?.toDouble(),
      longitudEntrada: (m['longitudEntrada'] as num?)?.toDouble(),
      latitudSalida: (m['latitudSalida'] as num?)?.toDouble(),
      longitudSalida: (m['longitudSalida'] as num?)?.toDouble(),
      estado: m['estado'] ?? 'pendiente',
      fecha: m['fecha'] ?? '',
    );
  }
}