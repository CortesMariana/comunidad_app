import 'package:comunidad_app/screens/menu/permisos/permisos_screen.dart';
import 'package:comunidad_app/screens/menu/solicitud_vacantes/solicitud_vacantes_screen.dart';
import 'package:comunidad_app/screens/menu/uniformes/uniformes_catalogo_screen.dart';
import 'package:comunidad_app/screens/menu/vacaciones/vacaciones_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'checador/checador_screen.dart';
import 'control_contenido/control_contenido_screen.dart';
import 'desempeno/desempeno_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  final List<Map<String, dynamic>> _menuItems = const [
    {
      'icon': Icons.access_time_filled,
      'title': 'Checador',
      'subtitle': 'Registro de entradas y salidas',
      'color': '005DB9',
    },
    {
      'icon': Icons.beach_access,
      'title': 'Vacaciones',
      'subtitle': 'Solicitar y consultar vacaciones',
      'color': '009BDF',
    },
    {
      'icon': Icons.event_note,
      'title': 'Permisos',
      'subtitle': 'Solicitar permisos de ausencia',
      'color': '005DB9',
    },
    {
      'icon': Icons.checkroom,
      'title': 'Uniformes',
      'subtitle': 'Solicitud de uniformes',
      'color': '009BDF',
    },
    {
      'icon': Icons.trending_up,
      'title': 'Desempeño',
      'subtitle': 'Evaluación y métricas',
      'color': '005DB9',
    },
    {
      'icon': Icons.work_outline,
      'title': 'Solicitud de vacantes',
      'subtitle': 'Pedir nuevo personal',
      'color': '009BDF',
    },
    {
      'icon': Icons.admin_panel_settings,
      'title': 'Control de contenido',
      'subtitle': 'Moderación de reels y publicaciones',
      'color': 'F32836',
    },
  ];

  void _navigateTo(BuildContext context, String title) {
    Widget screen;

    switch (title) {
      case 'Checador':
        screen = const ChecadorScreen();
        break;
      case 'Vacaciones':
        screen = const VacacionesScreen();
        break;
      case 'Permisos':
        screen = const PermisosScreen();
        break;
      case 'Uniformes':
        screen = const UniformesCatalogoScreen();
        break;
      case 'Desempeño':
        screen = const DesempenoScreen();
        break;
      case 'Solicitud de vacantes':
        screen = const SolicitudVacantesScreen();
        break;
      case 'Control de contenido':
        screen = const ControlContenidoScreen();
        break;
      default:
        return; // Salir si no coincide con ninguna opción
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF005DB9), Color(0xFF009BDF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Bienvenido 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'Mariana Cortes',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Coordinadora de RH',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            // Grid de menú
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = _menuItems[index];
                    return _buildMenuCard(context, item);
                  },
                  childCount: _menuItems.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, Map<String, dynamic> item) {
    final Color color = Color(int.parse('0xFF${item['color']}'));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateTo(context, item['title']),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(item['icon'], size: 30, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                item['title'],
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['subtitle'],
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}