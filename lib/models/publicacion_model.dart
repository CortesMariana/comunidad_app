import 'package:cloud_firestore/cloud_firestore.dart';

class PublicacionModel {
  String? id;
  String usuarioId;
  String nombreUsuario;
  String avatarUsuario;
  String contenido;
  String? urlImagen;
  String? urlVideo;
  String categoria;          // anuncios | capacitacion | cultura | reconocimiento
  String estado;             // pendiente | aprobado | rechazado
  int likes;
  int comentarios;
  Map<String, int> reacciones; // { 'me_gusta': 5, 'me_encanta': 2, ... }
  List<String> likedBy;
  bool estaProgramado;
  DateTime? fechaProgramada;
  Timestamp creadoEn;
  Timestamp? aprobadoEn;
  String? aprobadoPor;
  String? motivoRechazo;

  PublicacionModel({
    this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.avatarUsuario,
    required this.contenido,
    this.urlImagen,
    this.urlVideo,
    this.categoria = 'anuncios',
    this.estado = 'pendiente',
    this.likes = 0,
    this.comentarios = 0,
    Map<String, int>? reacciones,
    List<String>? likedBy,
    this.estaProgramado = false,
    this.fechaProgramada,
    required this.creadoEn,
    this.aprobadoEn,
    this.aprobadoPor,
    this.motivoRechazo,
  })  : reacciones = reacciones ?? {},
        likedBy = likedBy ?? [];

  Map<String, dynamic> aMap() => {
    'usuarioId': usuarioId,
    'nombreUsuario': nombreUsuario,
    'avatarUsuario': avatarUsuario,
    'contenido': contenido,
    'urlImagen': urlImagen,
    'urlVideo': urlVideo,
    'categoria': categoria,
    'estado': estado,
    'likes': likes,
    'comentarios': comentarios,
    'reacciones': reacciones,
    'likedBy': likedBy,
    'estaProgramado': estaProgramado,
    'fechaProgramada': fechaProgramada != null
        ? Timestamp.fromDate(fechaProgramada!)
        : null,
    'creadoEn': creadoEn,
    'aprobadoEn': aprobadoEn,
    'aprobadoPor': aprobadoPor,
    'motivoRechazo': motivoRechazo,
  };

  factory PublicacionModel.desdeMap(String id, Map<String, dynamic> m) {
    return PublicacionModel(
      id: id,
      usuarioId: m['usuarioId'] ?? '',
      nombreUsuario: m['nombreUsuario'] ?? '',
      avatarUsuario: m['avatarUsuario'] ?? '',
      contenido: m['contenido'] ?? '',
      urlImagen: m['urlImagen'],
      urlVideo: m['urlVideo'],
      categoria: m['categoria'] ?? 'anuncios',
      estado: m['estado'] ?? 'pendiente',
      likes: m['likes'] ?? 0,
      comentarios: m['comentarios'] ?? 0,
      reacciones: Map<String, int>.from(m['reacciones'] ?? {}),
      likedBy: List<String>.from(m['likedBy'] ?? []),
      estaProgramado: m['estaProgramado'] ?? false,
      fechaProgramada: (m['fechaProgramada'] as Timestamp?)?.toDate(),
      creadoEn: m['creadoEn'] ?? Timestamp.now(),
      aprobadoEn: m['aprobadoEn'],
      aprobadoPor: m['aprobadoPor'],
      motivoRechazo: m['motivoRechazo'],
    );
  }
}

// Subcolección: publicaciones/{id}/comentarios
class ComentarioModel {
  String? id;
  String publicacionId;
  String usuarioId;
  String nombreUsuario;
  String avatarUsuario;
  String texto;
  int likes;
  Timestamp creadoEn;

  ComentarioModel({
    this.id,
    required this.publicacionId,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.avatarUsuario,
    required this.texto,
    this.likes = 0,
    required this.creadoEn,
  });

  Map<String, dynamic> aMap() => {
    'publicacionId': publicacionId,
    'usuarioId': usuarioId,
    'nombreUsuario': nombreUsuario,
    'avatarUsuario': avatarUsuario,
    'texto': texto,
    'likes': likes,
    'creadoEn': creadoEn,
  };

  factory ComentarioModel.desdeMap(String id, Map<String, dynamic> m) {
    return ComentarioModel(
      id: id,
      publicacionId: m['publicacionId'] ?? '',
      usuarioId: m['usuarioId'] ?? '',
      nombreUsuario: m['nombreUsuario'] ?? '',
      avatarUsuario: m['avatarUsuario'] ?? '',
      texto: m['texto'] ?? '',
      likes: m['likes'] ?? 0,
      creadoEn: m['creadoEn'] ?? Timestamp.now(),
    );
  }
}

// Subcolección: publicaciones/{id}/reacciones
class ReaccionModel {
  String? id;           // id = usuarioId (un doc por usuario)
  String usuarioId;
  String tipo;          // me_gusta | me_encanta | me_divierte | me_asombra | me_entristece | me_enoja
  Timestamp creadoEn;

  ReaccionModel({
    this.id,
    required this.usuarioId,
    required this.tipo,
    required this.creadoEn,
  });

  Map<String, dynamic> aMap() => {
    'usuarioId': usuarioId,
    'tipo': tipo,
    'creadoEn': creadoEn,
  };

  factory ReaccionModel.desdeMap(String id, Map<String, dynamic> m) {
    return ReaccionModel(
      id: id,
      usuarioId: m['usuarioId'] ?? '',
      tipo: m['tipo'] ?? 'me_gusta',
      creadoEn: m['creadoEn'] ?? Timestamp.now(),
    );
  }
}