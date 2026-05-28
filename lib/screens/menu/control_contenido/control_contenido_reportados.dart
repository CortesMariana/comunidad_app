import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/reports/report_service.dart';

class ControlContenidoReportados extends StatefulWidget {
  const ControlContenidoReportados({super.key});

  @override
  State<ControlContenidoReportados> createState() => _ControlContenidoReportadosState();
}

class _ControlContenidoReportadosState extends State<ControlContenidoReportados> {
  final ReportService _reportService = ReportService();

  Future<void> _deleteReel(String reelId, String reportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar contenido'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este contenido?\n\n'
              'Esta acción:\n'
              '• Eliminará el reel permanentemente\n'
              '• Eliminará todos sus comentarios\n'
              '• No se puede deshacer',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF32836),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _reportService.deleteReelAndReports(reelId, reportId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contenido eliminado correctamente'),
              backgroundColor: Color(0xFFF32836),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _dismissReport(String reportId, String contentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ignorar reporte'),
        content: const Text(
          '¿Estás seguro de que quieres ignorar este reporte?\n\n'
              'El contenido no será eliminado y este reporte se marcará como resuelto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            child: const Text('Ignorar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _reportService.dismissReport(reportId, contentId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte ignorado'),
              backgroundColor: Colors.grey,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reportService.getPendingReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No hay contenido reportado',
                  style: GoogleFonts.poppins(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFF32836).withOpacity(0.1),
                          child: Text(report['reporterName'][0].toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report['reporterName'],
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _formatDate(report['createdAt']),
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF32836).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 12, color: Color(0xFFF32836)),
                              const SizedBox(width: 4),
                              Text('Reportado', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFF32836))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.category, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text('Tipo: ${report['type']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.report_problem, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text('Motivo: ${report['reason']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                          if (report['details'].isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Detalles: ${report['details']}',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ID del contenido: ${report['contentId']}',
                                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _dismissReport(report['id'], report['contentId']),
                          child: Text('Ignorar', style: GoogleFonts.poppins(color: Colors.grey[600])),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _deleteReel(report['contentId'], report['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF32836),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'hace ${difference.inMinutes} minutos';
    }
  }
}