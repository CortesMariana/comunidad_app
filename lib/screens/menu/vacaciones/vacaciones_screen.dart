import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VacacionesScreen extends StatelessWidget {
  const VacacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vacaciones', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Pantalla de Vacaciones - Próximamente',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}