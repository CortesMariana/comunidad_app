import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UniformesCatalogoScreen extends StatelessWidget {
  const UniformesCatalogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Uniformes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Pantalla de Uniformes - Próximamente',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}