import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChecadorScreen extends StatelessWidget {
  const ChecadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Checador',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: const Center(child: Text('Próximamente')),
    );
  }
}