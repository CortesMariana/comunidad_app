import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PermisosScreen extends StatelessWidget {
  const PermisosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permisos', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Pantalla de Permisos - Próximamente',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}