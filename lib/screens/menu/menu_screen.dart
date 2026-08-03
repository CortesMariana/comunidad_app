import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/usuario_config.dart';
import '../perfil/perfil_screen.dart';
import 'autorizaciones/autorizaciones_screen.dart';
import 'checador/checador_screen.dart';
import 'vacaciones/vacaciones_screen.dart';
import 'permisos/permisos_screen.dart';
import 'uniformes/uniformes_screen.dart';
import 'desempeno/desempeno_screen.dart';
import 'vacantes/vacantes_screen.dart';
import 'control_contenido/control_contenido_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const _modulos = [
    {
      'titulo': 'Checador',
      'subtitulo': 'Entrada y salida',
      'icono': Icons.fingerprint_rounded,
      'color': Color(0xFF005DB9),
      'fondo': Color(0xFFE8F0FB),
      'ruta': 'checador',
    },
    {
      'titulo': 'Vacaciones',
      'subtitulo': 'Solicitar días',
      'icono': Icons.beach_access_rounded,
      'color': Color(0xFF009BDF),
      'fondo': Color(0xFFE0F4FC),
      'ruta': 'vacaciones',
    },
    {
      'titulo': 'Permisos',
      'subtitulo': 'Ausencias y salidas',
      'icono': Icons.event_note_rounded,
      'color': Color(0xFF7B61FF),
      'fondo': Color(0xFFEEEBFF),
      'ruta': 'permisos',
    },
    {
      'titulo': 'Uniformes',
      'subtitulo': 'Pedido de prendas',
      'icono': Icons.checkroom_rounded,
      'color': Color(0xFF00B37E),
      'fondo': Color(0xFFE0F7F1),
      'ruta': 'uniformes',
    },
    {
      'titulo': 'Desempeño',
      'subtitulo': 'Evaluación y métricas',
      'icono': Icons.insights_rounded,
      'color': Color(0xFFFF6B35),
      'fondo': Color(0xFFFFF0EB),
      'ruta': 'desempeno',
    },
    {
      'titulo': 'Vacantes',
      'subtitulo': 'Solicitar personal',
      'icono': Icons.work_outline_rounded,
      'color': Color(0xFF005DB9),
      'fondo': Color(0xFFE8F0FB),
      'ruta': 'vacantes',
    },
    {
      'titulo': 'Autorizaciones',
      'subtitulo': 'Aprobar solicitudes',
      'icono': Icons.approval_rounded,
      'color': Color(0xFF7B61FF),
      'fondo': Color(0xFFEEEBFF),
      'ruta': 'autorizaciones',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildTarjetaUsuario(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('Operaciones',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E))),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, i) => _TarjetaModulo(
                  modulo: _modulos[i],
                  onTap: () => _navegar(context, _modulos[i]['ruta'] as String),
                ),
                childCount: _modulos.length,
              ),
            ),
          ),
          if (UsuarioConfig.esModerador)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _TarjetaControlContenido(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ControlContenidoScreen()),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text('Menú',
          style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E))),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey[100]),
      ),
    );
  }

  Widget _buildTarjetaUsuario(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PerfilDetalleScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  UsuarioConfig.nombreUsuario.isNotEmpty
                      ? UsuarioConfig.nombreUsuario[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(UsuarioConfig.nombreUsuario,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Text(UsuarioConfig.puestoUsuario,
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 13)),
                  Text(UsuarioConfig.departamento,
                      style: GoogleFonts.poppins(
                          color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                UsuarioConfig.rol.toUpperCase(),
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  void _navegar(BuildContext context, String ruta) {
    final pantallas = {
      'checador': const ChecadorScreen(),
      'vacaciones': const VacacionesScreen(),
      'permisos': const PermisosScreen(),
      'uniformes': const UniformesScreen(),
      'desempeno': const DesempenoScreen(),
      'vacantes': const VacantesScreen(),
      'autorizaciones': const AutorizacionesScreen(),
    };
    final pantalla = pantallas[ruta];
    if (pantalla == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA DE MÓDULO
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaModulo extends StatelessWidget {
  final Map<String, dynamic> modulo;
  final VoidCallback onTap;

  const _TarjetaModulo({required this.modulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: modulo['fondo'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(modulo['icono'] as IconData,
                  color: modulo['color'] as Color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(modulo['titulo'] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E))),
                Text(modulo['subtitulo'] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TARJETA CONTROL DE CONTENIDO (solo moderadores)
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaControlContenido extends StatelessWidget {
  final VoidCallback onTap;
  const _TarjetaControlContenido({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF32836).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF32836).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Color(0xFFF32836), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Control de contenido',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E))),
                  Text('Moderación · Reportes · Aprobaciones',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFF32836)),
          ],
        ),
      ),
    );
  }
}