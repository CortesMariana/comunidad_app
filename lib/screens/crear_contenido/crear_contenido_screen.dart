import 'package:flutter/material.dart';
import 'crear_publicacion_screen.dart';
import 'crear_reel_screen.dart';
import 'crear_historia_screen.dart';

class CrearContenidoScreen extends StatelessWidget {
  const CrearContenidoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear contenido'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF005DB9),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildOption(
              context,
              icon: Icons.slow_motion_video,
              title: 'Reel',
              description: 'Video corto vertical',
              color: const Color(0xFFF32836),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearReelScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOption(
              context,
              icon: Icons.post_add,
              title: 'Publicación',
              description: 'Imagen y texto (puede programarse)',
              color: const Color(0xFF005DB9),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearPublicacionScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOption(
              context,
              icon: Icons.history,
              title: 'Historia',
              description: 'Foto o video que dura 24h',
              color: const Color(0xFF009BDF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearHistoriaScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}