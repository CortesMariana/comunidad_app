import 'package:cloud_firestore/cloud_firestore.dart';

class ReelModel {
  String? id;
  String urlVideo;
  String urlMiniatura;
  String titulo;
  String descripcion;
  String usuarioId;
  String nombreUsuario;
  String avatarUsuario;
  String categoria;        // cultura | anuncios | capacitacion | reconocimiento
  String estado;           // pendiente | aprobado | rechazado
  int likes;
  int comentarios;
  int vistas;
  List<String> likedBy;
  Timestamp creadoEn;
  Timestamp? aprobadoEn;
  String? aprobadoPor;
  String? motivoRechazo;

  ReelModel({
    this.id,
    required this.urlVideo,
    this.urlMiniatura = '',
    required this.titulo,
    this.descripcion = '',
    required this.usuarioId,
    required this.nombreUsuario,
    this.avatarUsuario = '',
    this.categoria = 'cultura',
    this.estado = 'pendiente',
    this.likes = 0,
    this.comentarios = 0,
    this.vistas = 0,
    List<String>? likedBy,
    required this.creadoEn,
    this.aprobadoEn,
    this.aprobadoPor,
    this.motivoRechazo,
  }) : likedBy = likedBy ?? [];

  Map<String, dynamic> aMap() => {
    'urlVideo': urlVideo,
    'urlMiniatura': urlMiniatura,
    'titulo': titulo,
    'descripcion': descripcion,
    'usuarioId': usuarioId,
    'nombreUsuario': nombreUsuario,
    'avatarUsuario': avatarUsuario,
    'categoria': categoria,
    'estado': estado,
    'likes': likes,
    'comentarios': comentarios,
    'vistas': vistas,
    'likedBy': likedBy,
    'creadoEn': creadoEn,
    'aprobadoEn': aprobadoEn,
    'aprobadoPor': aprobadoPor,
    'motivoRechazo': motivoRechazo,
  };

  factory ReelModel.desdeMap(String id, Map<String, dynamic> m) {
    return ReelModel(
      id: id,
      urlVideo: m['urlVideo'] ?? '',
      urlMiniatura: m['urlMiniatura'] ?? '',
      titulo: m['titulo'] ?? '',
      descripcion: m['descripcion'] ?? '',
      usuarioId: m['usuarioId'] ?? '',
      nombreUsuario: m['nombreUsuario'] ?? '',
      avatarUsuario: m['avatarUsuario'] ?? '',
      categoria: m['categoria'] ?? 'cultura',
      estado: m['estado'] ?? 'pendiente',
      likes: m['likes'] ?? 0,
      comentarios: m['comentarios'] ?? 0,
      vistas: m['vistas'] ?? 0,
      likedBy: List<String>.from(m['likedBy'] ?? []),
      creadoEn: m['creadoEn'] ?? Timestamp.now(),
      aprobadoEn: m['aprobadoEn'],
      aprobadoPor: m['aprobadoPor'],
      motivoRechazo: m['motivoRechazo'],
    );
  }
}

class ComentarioReelModel {
  String? id;
  String reelId;
  String usuarioId;
  String nombreUsuario;
  String avatarUsuario;
  String texto;
  Timestamp creadoEn;

  ComentarioReelModel({
    this.id,
    required this.reelId,
    required this.usuarioId,
    required this.nombreUsuario,
    this.avatarUsuario = '',
    required this.texto,
    required this.creadoEn,
  });

  Map<String, dynamic> aMap() => {
    'reelId': reelId,
    'usuarioId': usuarioId,
    'nombreUsuario': nombreUsuario,
    'avatarUsuario': avatarUsuario,
    'texto': texto,
    'creadoEn': creadoEn,
  };

  factory ComentarioReelModel.desdeMap(String id, Map<String, dynamic> m) {
    return ComentarioReelModel(
      id: id,
      reelId: m['reelId'] ?? '',
      usuarioId: m['usuarioId'] ?? '',
      nombreUsuario: m['nombreUsuario'] ?? '',
      avatarUsuario: m['avatarUsuario'] ?? '',
      texto: m['texto'] ?? '',
      creadoEn: m['creadoEn'] ?? Timestamp.now(),
    );
  }
}