import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/publicacion_model.dart';
import '../../../models/reel_model.dart';
import '../../../models/historia_model.dart';
import '../../../models/banner_model.dart';
import '../../../models/reporte_model.dart';
import '../../../services/publicaciones/publicaciones_service.dart';
import '../../../services/reels/reels_service.dart';
import '../../../services/historias/historias_service.dart';
import '../../../services/banners/banners_service.dart';
import '../../../services/reportes/reportes_service.dart';

class ControlContenidoScreen extends StatefulWidget {
  const ControlContenidoScreen({super.key});

  @override
  State<ControlContenidoScreen> createState() => _ControlContenidoScreenState();
}

class _ControlContenidoScreenState extends State<ControlContenidoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _pubService = PublicacionesService();
  final _reelsService = ReelsService();
  final _historiasService = HistoriasService();
  final _bannersService = BannersService();
  final _reportesService = ReportesService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Control de contenido',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          labelColor: const Color(0xFF005DB9),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF005DB9),
          tabs: const [
            Tab(text: 'Publicaciones'),
            Tab(text: 'Reels'),
            Tab(text: 'Historias'),
            Tab(text: 'Banners'),
            Tab(text: 'Reportes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TabPendientes<PublicacionModel>(
            stream: _pubService.obtenerPendientes(),
            buildCard: (item) => _CardPublicacion(
              pub: item,
              onAprobar: () => _pubService.aprobar(item.id!),
              onRechazar: (m) => _pubService.rechazar(item.id!, m),
            ),
          ),
          _TabPendientes<ReelModel>(
            stream: _reelsService.obtenerPendientes(),
            buildCard: (item) => _CardReel(
              reel: item,
              onAprobar: () => _reelsService.aprobar(item.id!),
              onRechazar: (m) => _reelsService.rechazar(item.id!, m),
            ),
          ),
          _TabPendientes<HistoriaModel>(
            stream: _historiasService.obtenerPendientes(),
            buildCard: (item) => _CardHistoria(
              historia: item,
              onAprobar: () => _historiasService.aprobar(item.id!),
              onRechazar: (m) => _historiasService.rechazar(item.id!, m),
            ),
          ),
          _TabPendientes<BannerModel>(
            stream: _bannersService.obtenerPendientes(),
            buildCard: (item) => _CardBanner(
              banner: item,
              onAprobar: () => _bannersService.aprobar(item.id!),
              onRechazar: (m) => _bannersService.rechazar(item.id!, m),
            ),
          ),
          _TabReportes(
            stream: _reportesService.obtenerPendientes(),
            onEliminar: (r) => _reportesService.eliminarContenido(r),
            onDescartar: (r) => _reportesService.descartar(r.id!),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB GENÉRICO DE PENDIENTES
// ─────────────────────────────────────────────────────────────────────────────

class _TabPendientes<T> extends StatelessWidget {
  final Stream<List<T>> stream;
  final Widget Function(T item) buildCard;

  const _TabPendientes({required this.stream, required this.buildCard});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Todo al día',
                    style: GoogleFonts.poppins(
                        color: Colors.grey[400], fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (_, i) => buildCard(items[i]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARDS DE CONTENIDO PENDIENTE
// ─────────────────────────────────────────────────────────────────────────────

class _CardBase extends StatelessWidget {
  final String nombreUsuario;
  final String avatarUsuario;
  final String fechaTexto;
  final Widget contenido;
  final Future<bool> Function() onAprobar;
  final Future<bool> Function(String) onRechazar;

  const _CardBase({
    required this.nombreUsuario,
    required this.avatarUsuario,
    required this.fechaTexto,
    required this.contenido,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avatarUsuario.isNotEmpty
                      ? NetworkImage(avatarUsuario)
                      : null,
                  backgroundColor: const Color(0xFF005DB9),
                  child: avatarUsuario.isEmpty
                      ? Text(nombreUsuario.isNotEmpty
                      ? nombreUsuario[0].toUpperCase()
                      : '?',
                      style: const TextStyle(color: Colors.white))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombreUsuario,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(fechaTexto,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[400])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Pendiente',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          contenido,
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rechazar(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Rechazar',
                        style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final ok = await onAprobar();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Aprobado' : 'Error al aprobar'),
                          backgroundColor: ok
                              ? const Color(0xFF005DB9)
                              : Colors.red,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005DB9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Aprobar',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _rechazar(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rechazar contenido',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Motivo del rechazo',
            hintStyle: GoogleFonts.poppins(fontSize: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await onRechazar(controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF32836),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Rechazar', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}

class _CardPublicacion extends StatelessWidget {
  final PublicacionModel pub;
  final Future<bool> Function() onAprobar;
  final Future<bool> Function(String) onRechazar;

  const _CardPublicacion(
      {required this.pub, required this.onAprobar, required this.onRechazar});

  @override
  Widget build(BuildContext context) {
    return _CardBase(
      nombreUsuario: pub.nombreUsuario,
      avatarUsuario: pub.avatarUsuario,
      fechaTexto: _fecha(pub.creadoEn),
      onAprobar: onAprobar,
      onRechazar: onRechazar,
      contenido: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pub.contenido,
                style: GoogleFonts.poppins(fontSize: 13),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
            if (pub.urlImagen != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(pub.urlImagen!,
                    height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _fecha(dynamic ts) {
    try {
      final d = ts.toDate() as DateTime;
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}

class _CardReel extends StatelessWidget {
  final ReelModel reel;
  final Future<bool> Function() onAprobar;
  final Future<bool> Function(String) onRechazar;

  const _CardReel(
      {required this.reel, required this.onAprobar, required this.onRechazar});

  @override
  Widget build(BuildContext context) {
    return _CardBase(
      nombreUsuario: reel.nombreUsuario,
      avatarUsuario: reel.avatarUsuario,
      fechaTexto: _fecha(reel.creadoEn),
      onAprobar: onAprobar,
      onRechazar: onRechazar,
      contenido: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reel.titulo,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            if (reel.descripcion.isNotEmpty)
              Text(reel.descripcion,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2),
            const SizedBox(height: 8),
            if (reel.urlMiniatura.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(reel.urlMiniatura,
                    height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _fecha(dynamic ts) {
    try {
      final d = ts.toDate() as DateTime;
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}

class _CardHistoria extends StatelessWidget {
  final HistoriaModel historia;
  final Future<bool> Function() onAprobar;
  final Future<bool> Function(String) onRechazar;

  const _CardHistoria(
      {required this.historia,
        required this.onAprobar,
        required this.onRechazar});

  @override
  Widget build(BuildContext context) {
    return _CardBase(
      nombreUsuario: historia.nombreUsuario,
      avatarUsuario: historia.avatarUsuario,
      fechaTexto: _fecha(historia.creadoEn),
      onAprobar: onAprobar,
      onRechazar: onRechazar,
      contenido: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (historia.texto.isNotEmpty)
              Text(historia.texto,
                  style: GoogleFonts.poppins(fontSize: 13), maxLines: 2),
            const SizedBox(height: 8),
            if (historia.urlMedia.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(historia.urlMedia,
                    height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _fecha(dynamic ts) {
    try {
      final d = ts.toDate() as DateTime;
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}

class _CardBanner extends StatelessWidget {
  final BannerModel banner;
  final Future<bool> Function() onAprobar;
  final Future<bool> Function(String) onRechazar;

  const _CardBanner(
      {required this.banner, required this.onAprobar, required this.onRechazar});

  @override
  Widget build(BuildContext context) {
    return _CardBase(
      nombreUsuario: banner.nombreUsuario,
      avatarUsuario: '',
      fechaTexto: _fecha(banner.creadoEn),
      onAprobar: onAprobar,
      onRechazar: onRechazar,
      contenido: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(banner.titulo,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            if (banner.subtitulo != null && banner.subtitulo!.isNotEmpty)
              Text(banner.subtitulo!,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 8),
            if (banner.urlImagen.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(banner.urlImagen,
                    height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _fecha(dynamic ts) {
    try {
      final d = ts.toDate() as DateTime;
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB REPORTES
// ─────────────────────────────────────────────────────────────────────────────

class _TabReportes extends StatelessWidget {
  final Stream<List<ReporteModel>> stream;
  final Future<bool> Function(ReporteModel) onEliminar;
  final Future<void> Function(ReporteModel) onDescartar;

  const _TabReportes({
    required this.stream,
    required this.onEliminar,
    required this.onDescartar,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReporteModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reportes = snap.data ?? [];
        if (reportes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Sin reportes pendientes',
                    style: GoogleFonts.poppins(
                        color: Colors.grey[400], fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reportes.length,
          itemBuilder: (_, i) => _CardReporte(
            reporte: reportes[i],
            onEliminar: () => onEliminar(reportes[i]),
            onDescartar: () => onDescartar(reportes[i]),
          ),
        );
      },
    );
  }
}

class _CardReporte extends StatelessWidget {
  final ReporteModel reporte;
  final Future<bool> Function() onEliminar;
  final Future<void> Function() onDescartar;

  const _CardReporte({
    required this.reporte,
    required this.onEliminar,
    required this.onDescartar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF32836).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(reporte.tipo.toUpperCase(),
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF32836))),
                ),
                const Spacer(),
                Text(_fecha(reporte.creadoEn),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 10),
            Text('Motivo: ${reporte.motivo}',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            if (reporte.detalles.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(reporte.detalles,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600])),
            ],
            Text('Reportado por: ${reporte.nombreReportador}',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey[400])),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await onDescartar();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reporte descartado')),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Descartar',
                        style: GoogleFonts.poppins(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final ok = await onEliminar();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? 'Contenido eliminado'
                              : 'Error al eliminar'),
                          backgroundColor: ok
                              ? const Color(0xFFF32836)
                              : Colors.grey,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF32836),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Eliminar contenido',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fecha(dynamic ts) {
    try {
      final d = ts.toDate() as DateTime;
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }
}