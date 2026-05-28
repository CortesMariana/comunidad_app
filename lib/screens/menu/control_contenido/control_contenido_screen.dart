import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'control_contenido_reportados.dart';
import 'control_contenido_pendientes.dart';
import 'control_contenido_aprobados.dart';

class ControlContenidoScreen extends StatefulWidget {
  const ControlContenidoScreen({super.key});

  @override
  State<ControlContenidoScreen> createState() => _ControlContenidoScreenState();
}

class _ControlContenidoScreenState extends State<ControlContenidoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Control de contenido', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFF32836),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Reportados', icon: Icon(Icons.flag)),
            Tab(text: 'Pendientes', icon: Icon(Icons.pending)),
            Tab(text: 'Aprobados', icon: Icon(Icons.check_circle)),
          ],
          labelColor: const Color(0xFFF32836),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFF32836),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ControlContenidoReportados(),
          ControlContenidoPendientes(),
          ControlContenidoAprobados(),
        ],
      ),
    );
  }
}