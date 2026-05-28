import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChecadorScreen extends StatelessWidget {
  const ChecadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checador', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Pantalla de Checador - Próximamente',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}