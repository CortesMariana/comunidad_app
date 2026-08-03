import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UniformesService {
  static const _base = 'https://enersishrdev.azurewebsites.net/api';

  // Token temporal — reemplazar cuando se implemente auth real
  static const _token = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjJEMDY5NUFCNUREQjhCMjg2RjM1OTczMkM0NjFCMjA3IiwidHlwIjoiYXQrand0In0.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmVuZXJzaXMxMC5jb20iLCJuYmYiOjE3ODQ3MzczNTIsImlhdCI6MTc4NDczNzM1MiwiZXhwIjoxNzg0NzQwOTUyLCJhdWQiOlsiSHJBcGkiLCJodHRwczovL2FjY291bnRzLmVuZXJzaXMxMC5jb20vcmVzb3VyY2VzIl0sInNjb3BlIjpbIm9wZW5pZCIsInByb2ZpbGUiLCJIckFwaS5BcHBIciIsIm9mZmxpbmVfYWNjZXNzIl0sImFtciI6WyJwd2QiXSwiY2xpZW50X2lkIjoiQ29tbXVuaXR5UFdBIiwic3ViIjoiYWNjY2E5NWEtYjc1YS00ZGJiLTk0MjctZWVhYTkxODdjZmRmIiwiYXV0aF90aW1lIjoxNzg0NzM3MzI0LCJpZHAiOiJsb2NhbCIsIkVtcGxlYWRvSWQiOiI4ZjZkYzA1NS04NzNiLTQ2ODMtYjJiZS03OTBmMmRmNjI3ZDEiLCJDb2xhYm9yYWRvciI6Ik1pZ3VlbCBSb2RyaWd1ZXoiLCJzaWQiOiIxREY3MTgzNjM5RkQ5MTA2Q0JFM0EyNjU4NEM1NTdCRCIsImp0aSI6IjI5REI3M0UyQ0FFREJGREVFRTE2OTgxM0UwOTkzOUVGIn0.TX0i5iuYEy-eOA6xsCWH1ezfe0CR9NBiRBJQhtr0wzs_1JdgIVTheAWyYwQ8G1NtwpAeBj6nAxSzFf5VQwTl8K6rG54-R2e-7dxXg2fVhQb-AJG3MoL0yv_LS45ofiqneEiMJIkVxOrsvOt0aqNv_aPNZRl6TpWBVOyaW-9Uf-zwnU_DEJ1RziU8EXCk1-Vm9djFGQTZRKtA5259woYDPmNflLUoaUzM-D-SBLBE14OmxxxD1Jhe4l_QR3e6d6azM7GRTM47UWicRm6Cc1RdqYgwcjo4cZFdbmLlPAdXnuTCsJZAOWldhq6Ok2vyUmqCFEB9APq4yuqmjou2i5BuOA';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  Future<List<ProductoUniformeModel>> obtenerCatalogo() async {
    try {
      final res = await http.get(
        Uri.parse('$_base/GestionUniformes/Todos'),
        headers: _headers,
      );
      if (res.statusCode != 200) return [];
      final lista = jsonDecode(res.body) as List;
      return lista.map((e) => ProductoUniformeModel.desdeMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SolicitudUniformeModel>> obtenerSolicitudes(
      String colaboradorId) async {
    try {
      final res = await http.get(
        Uri.parse('$_base/SolicitudUniformes/ObtenerSolicitudes?colaboradorId=$colaboradorId'),
        headers: _headers,
      );
      if (res.statusCode != 200) return [];
      final lista = jsonDecode(res.body) as List;
      return lista.map((e) => SolicitudUniformeModel.desdeMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> crearSolicitud({
    required String colaboradorId,
    required List<DetallePedidoModel> detalles,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/SolicitudUniformes/CrearSolicitud'),
        headers: _headers,
        body: jsonEncode({
          'colaboradorId': colaboradorId,
          'detalles': detalles.map((d) => d.aMap()).toList(),
        }),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelarSolicitud(String id) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/SolicitudUniformes/CancelarSolicitud'),
        headers: _headers,
        body: jsonEncode({'id': id}),
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<String?> generarCodigo(String solicitudId) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/SolicitudUniformes/GenerarCodigo'),
        headers: _headers,
        body: jsonEncode({'solicitudId': solicitudId}),
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      return data['codigoConfirmacion']?.toString() ??
          data['codigo']?.toString() ??
          data.toString();
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────

class VarianteModel {
  final String id;
  final String sku;
  final double precio;
  final String? fotoPortadaUrl;
  final String? color;
  final String? talla;
  final String? codigoBarras;
  final int estatus;
  final List<String> fotos;

  VarianteModel({
    required this.id,
    required this.sku,
    required this.precio,
    this.fotoPortadaUrl,
    this.color,
    this.talla,
    this.codigoBarras,
    required this.estatus,
    required this.fotos,
  });

  factory VarianteModel.desdeMap(Map<String, dynamic> m) => VarianteModel(
    id: m['id'] ?? '',
    sku: m['sKU'] ?? m['sku'] ?? '',
    precio: (m['precio'] as num?)?.toDouble() ?? 0,
    fotoPortadaUrl: m['fotoPortadaUrl'],
    color: m['color'],
    talla: m['talla'],
    codigoBarras: m['codigoBarras'],
    estatus: m['estatus'] ?? 0,
    fotos: List<String>.from(m['fotos'] ?? []),
  );
}

class ProductoUniformeModel {
  final String id;
  final String nombre;
  final String descripcion;
  final List<VarianteModel> variantes;

  ProductoUniformeModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.variantes,
  });

  factory ProductoUniformeModel.desdeMap(Map<String, dynamic> m) =>
      ProductoUniformeModel(
        id: m['id'] ?? '',
        nombre: m['nombre'] ?? '',
        descripcion: m['descripcion'] ?? '',
        variantes: ((m['variantes'] as List?) ?? [])
            .map((v) => VarianteModel.desdeMap(v))
            .toList(),
      );

  // Foto principal del producto
  String get fotoPrincipal {
    for (final v in variantes) {
      if (v.fotoPortadaUrl != null && v.fotoPortadaUrl!.isNotEmpty) {
        return v.fotoPortadaUrl!;
      }
      if (v.fotos.isNotEmpty) return v.fotos.first;
    }
    return '';
  }

  double get precioMinimo {
    if (variantes.isEmpty) return 0;
    return variantes
        .map((v) => v.precio)
        .reduce((a, b) => a < b ? a : b);
  }

  // Tallas únicas disponibles
  List<String> get tallasDisponibles {
    final set = <String>{};
    for (final v in variantes) {
      if (v.talla != null && v.talla!.isNotEmpty) set.add(v.talla!);
    }
    final orden = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];
    final lista = set.toList();
    lista.sort((a, b) {
      final ia = orden.indexOf(a.toUpperCase());
      final ib = orden.indexOf(b.toUpperCase());
      if (ia == -1 && ib == -1) return a.compareTo(b);
      if (ia == -1) return 1;
      if (ib == -1) return -1;
      return ia.compareTo(ib);
    });
    return lista;
  }

  // Colores únicos — agrupa por hex similar usando distancia de color
  List<ColorUnicoModel> get coloresUnicos {
    final mapa = <String, ColorUnicoModel>{};
    for (final v in variantes) {
      if (v.color == null || v.color!.isEmpty) continue;
      final hexLimpio = _normalizarHex(v.color!);
      final clave = _encontrarColorCercano(hexLimpio, mapa.keys.toList());
      if (clave != null) {
        mapa[clave]!.hexVariantes.add(v.color!);
      } else {
        mapa[hexLimpio] = ColorUnicoModel(
          hexRepresentativo: hexLimpio,
          hexVariantes: [v.color!],
        );
      }
    }
    return mapa.values.toList();
  }

  String _normalizarHex(String hex) {
    final limpio = hex.replaceAll('#', '').toLowerCase();
    if (limpio.length == 3) {
      return limpio.split('').map((c) => '$c$c').join();
    }
    return limpio.padLeft(6, '0');
  }

  // Encuentra un color ya registrado que sea "similar" (distancia < umbral)
  String? _encontrarColorCercano(
      String hex, List<String> existentes) {
    for (final e in existentes) {
      if (_distanciaColor(hex, e) < 40) return e;
    }
    return null;
  }

  double _distanciaColor(String a, String b) {
    try {
      final ra = int.parse(a.substring(0, 2), radix: 16);
      final ga = int.parse(a.substring(2, 4), radix: 16);
      final ba2 = int.parse(a.substring(4, 6), radix: 16);
      final rb = int.parse(b.substring(0, 2), radix: 16);
      final gb = int.parse(b.substring(2, 4), radix: 16);
      final bb2 = int.parse(b.substring(4, 6), radix: 16);
      return ((ra - rb).abs() + (ga - gb).abs() + (ba2 - bb2).abs())
          .toDouble();
    } catch (_) {
      return 999;
    }
  }

  // Variante que coincide con talla Y color seleccionados
  VarianteModel? varianteParaSeleccion(
      String? talla, ColorUnicoModel? color) {
    if (talla == null || color == null) return null;
    for (final v in variantes) {
      if (v.talla == talla &&
          v.color != null &&
          color.hexVariantes.contains(v.color)) {
        return v;
      }
    }
    return null;
  }

  // Tallas disponibles para un color dado
  List<String> tallasParaColor(ColorUnicoModel color) {
    return variantes
        .where((v) =>
    v.color != null && color.hexVariantes.contains(v.color))
        .map((v) => v.talla ?? '')
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }
}

class ColorUnicoModel {
  final String hexRepresentativo;
  final List<String> hexVariantes;

  ColorUnicoModel({
    required this.hexRepresentativo,
    required this.hexVariantes,
  });

  Color get color {
    try {
      return Color(
          int.parse('FF$hexRepresentativo', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}

class SolicitudUniformeModel {
  final String id;
  final String colaboradorId;
  final String colaborador;
  final DateTime fechaSolicitud;
  final String estado;
  final List<DetalleUniformeModel> detalles;

  SolicitudUniformeModel({
    required this.id,
    required this.colaboradorId,
    required this.colaborador,
    required this.fechaSolicitud,
    required this.estado,
    required this.detalles,
  });

  factory SolicitudUniformeModel.desdeMap(Map<String, dynamic> m) =>
      SolicitudUniformeModel(
        id: m['id'] ?? '',
        colaboradorId: m['colaboradorId'] ?? '',
        colaborador: m['colaborador'] ?? '',
        fechaSolicitud:
        DateTime.tryParse(m['fechaSolicitud'] ?? '') ??
            DateTime.now(),
        estado: m['estado'] ?? '',
        detalles: ((m['detalles'] as List?) ?? [])
            .map((e) => DetalleUniformeModel.desdeMap(e))
            .toList(),
      );

  bool get puedeRecibirOCancelar =>
      estado.toLowerCase() == 'pendiente' ||
          estado.toLowerCase() == 'aprobado';

  Color get colorEstado {
    switch (estado.toLowerCase()) {
      case 'pendiente': return const Color(0xFFFF6B35);
      case 'aprobado': return const Color(0xFF00B37E);
      case 'rechazado': return const Color(0xFFF32836);
      case 'cancelado': return Colors.grey;
      case 'entregado': return const Color(0xFF005DB9);
      default: return Colors.grey;
    }
  }

  double get total => detalles.fold(
      0, (sum, d) => sum + d.precioUnitario * d.cantidad);
}

class DetalleUniformeModel {
  final String uniformeId;
  final String fotografia;
  final int cantidad;
  final String talla;
  final String color;
  final String colorHex;
  final double precioUnitario;

  DetalleUniformeModel({
    required this.uniformeId,
    required this.fotografia,
    required this.cantidad,
    required this.talla,
    required this.color,
    required this.colorHex,
    required this.precioUnitario,
  });

  factory DetalleUniformeModel.desdeMap(Map<String, dynamic> m) =>
      DetalleUniformeModel(
        uniformeId: m['uniformeId'] ?? '',
        fotografia: m['fotografia'] ?? '',
        cantidad: m['cantidad'] ?? 1,
        talla: m['talla']?['descripcion'] ?? m['talla'] ?? '',
        color: m['color']?['descripcion'] ?? m['color'] ?? '',
        colorHex: m['color']?['colorHex'] ?? '',
        precioUnitario:
        (m['precioUnitario'] as num?)?.toDouble() ?? 0,
      );
}

class DetallePedidoModel {
  final String uniformeId;
  final String varianteId;
  final int cantidad;

  DetallePedidoModel({
    required this.uniformeId,
    required this.varianteId,
    required this.cantidad,
  });

  Map<String, dynamic> aMap() => {
    'uniformeId': uniformeId,
    'varianteId': varianteId,
    'cantidad': cantidad,
  };
}

// Item del carrito local
class ItemCarritoModel {
  final String uniformeId;
  final String varianteId;
  final String nombreUniforme;
  final String foto;
  final double precio;
  final String talla;
  final String colorHex;
  int cantidad;

  ItemCarritoModel({
    required this.uniformeId,
    required this.varianteId,
    required this.nombreUniforme,
    required this.foto,
    required this.precio,
    required this.talla,
    required this.colorHex,
    this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;
}