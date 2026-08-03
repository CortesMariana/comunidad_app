import 'package:cloud_firestore/cloud_firestore.dart';

class HistoriaModel {
  String? id;
  String usuarioId;
  String nombreUsuario;
  String avatarUsuario;
  String tipo;           // imagen | video
  String urlMedia;
  String texto;
  String estado;         // pendiente | aprobado | rechazado
  int vistas;
  List<String> vistoPor;
  Timestamp creadoEn;
  Timestamp expiraEn;
  Timestamp? aprobadoEn;
  String? aprobadoPor;
  String? motivoRechazo;

  HistoriaModel({
    this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    this.avatarUsuario = '',
    this.tipo = 'imagen',
    required this.urlMedia,
    this.texto = '',
    this.estado = 'pendiente',
    this.vistas = 0,
    List<String>? vistoPor,
    required this.creadoEn,
    required this.expiraEn,
    this.aprobadoEn,
    this.aprobadoPor,
    this.motivoRechazo,
  }) : vistoPor = vistoPor ?? [];

  Map<String, dynamic> aMap() => {
    'usuarioId': usuarioId,
    'nombreUsuario': nombreUsuario,
    'avatarUsuario': avatarUsuario,
    'tipo': tipo,
    'urlMedia': urlMedia,
    'texto': texto,
    'estado': estado,
    'vistas': vistas,
    'vistoPor': vistoPor,
    'creadoEn': creadoEn,
    'expiraEn': expiraEn,
    'aprobadoEn': aprobadoEn,
    'aprobadoPor': aprobadoPor,
    'motivoRechazo': motivoRechazo,
  };

  factory HistoriaModel.desdeMap(String id, Map<String, dynamic> m) {
    return HistoriaModel(
      id: id,
      usuarioId: m['usuarioId'] ?? '',
      nombreUsuario: m['nombreUsuario'] ?? '',
      avatarUsuario: m['avatarUsuario'] ?? '',
      tipo: m['tipo'] ?? 'imagen',
      urlMedia: m['urlMedia'] ?? '',
      texto: m['texto'] ?? '',
      estado: m['estado'] ?? 'pendiente',
      vistas: m['vistas'] ?? 0,
      vistoPor: List<String>.from(m['vistoPor'] ?? []),
      creadoEn: m['creadoEn'] ?? Timestamp.now(),
      expiraEn: m['expiraEn'] ?? Timestamp.now(),
      aprobadoEn: m['aprobadoEn'],
      aprobadoPor: m['aprobadoPor'],
      motivoRechazo: m['motivoRechazo'],
    );
  }
}