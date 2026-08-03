import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Notificaciones',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Sin notificaciones',
                style: GoogleFonts.poppins(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}