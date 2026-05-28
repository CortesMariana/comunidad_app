import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesempenoScreen extends StatelessWidget {
  const DesempenoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Desempeño', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Pantalla de Desempeño - Próximamente',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}