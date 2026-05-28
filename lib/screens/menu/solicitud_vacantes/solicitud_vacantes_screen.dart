import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SolicitudVacantesScreen extends StatelessWidget {
  const SolicitudVacantesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitud de vacantes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Pantalla de Solicitud de Vacantes - Próximamente',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}