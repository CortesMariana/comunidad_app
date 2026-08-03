import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  String? id;
  String usuarioId;
  String nombreUsuario;
  String titulo;
  String? subtitulo;
  String urlImagen;
  String? urlAccion;         // deep link o URL externa al tocar el banner
  String estado;             // pendiente | aprobado | rechazado
  bool activo;
  int orden;                 // para ordenar en el carrusel
  Timestamp creadoEn;
  Timestamp? aprobadoEn;
  String? aprobadoPor;
  Timestamp? expiraEn;
  String? motivoRechazo;

  BannerModel({
    this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.titulo,
    this.subtitulo,
    required this.urlImagen,
    this.urlAccion,
    this.estado = 'pendiente',
    this.activo = true,
    this.orden = 0,
    required this.creadoEn,
    this.aprobadoEn,
    this.aprobadoPor,
    this.expiraEn,
    this.motivoRechazo,
  });

  Map<String, dynamic> aMap() => {
    'usuarioId': usuarioId,
    'nombreUsuario': nombreUsuario,
    'titulo': titulo,
    'subtitulo': subtitulo,
    'urlImagen': urlImagen,
    'urlAccion': urlAccion,
    'estado': estado,
    'activo': activo,
    'orden': orden,
    'creadoEn': creadoEn,
    'aprobadoEn': aprobadoEn,
    'aprobadoPor': aprobadoPor,
    'expiraEn': expiraEn,
    'motivoRechazo': motivoRechazo,
  };

  factory BannerModel.desdeMap(String id, Map<String, dynamic> m) {
    return BannerModel(
      id: id,
      usuarioId: m['usuarioId'] ?? '',
      nombreUsuario: m['nombreUsuario'] ?? '',
      titulo: m['titulo'] ?? '',
      subtitulo: m['subtitulo'],
      urlImagen: m['urlImagen'] ?? '',
      urlAccion: m['urlAccion'],
      estado: m['estado'] ?? 'pendiente',
      activo: m['activo'] ?? true,
      orden: m['orden'] ?? 0,
      creadoEn: m['creadoEn'] ?? Timestamp.now(),
      aprobadoEn: m['aprobadoEn'],
      aprobadoPor: m['aprobadoPor'],
      expiraEn: m['expiraEn'],
      motivoRechazo: m['motivoRechazo'],
    );
  }
}