import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';

/// 30-day report for the doctor, in French. The AI summary paragraph is optional.
class ReportService {
  static Future<void> shareReport({
    required Profile profile,
    required List<GlucoseEntry> glucose,
    required List<FootScan> scans,
    required int medsAdherencePct,
    String aiSummary = '',
  }) async {
    final since = DateTime.now().subtract(const Duration(days: 30));
    final g = glucose.where((e) => e.time.isAfter(since)).toList();
    final s = scans.where((e) => e.time.isAfter(since)).toList();
    String d(DateTime t) => '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final avg = g.isEmpty ? null : g.map((e) => e.gL).reduce((a, b) => a + b) / g.length;
    final inTarget = g.isEmpty ? 0 : (100 * g.where((e) => e.band == 'in_target').length / g.length).round();

    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Header(level: 0, text: 'Qadam - Rapport patient (30 jours)'),
        pw.Text('Patient : ${profile.name}   |   Diabete : ${profile.diabetesType}   |   '
            'Traitement : ${profile.treatment}   |   Antecedent d\'ulcere : ${profile.pastUlcer ? 'oui' : 'non'}'),
        pw.SizedBox(height: 8),
        pw.Text('Glycemie : ${g.length} mesures, moyenne ${avg?.toStringAsFixed(2) ?? '-'} g/L, '
            '$inTarget % dans la cible. Observance medicaments : $medsAdherencePct %.'),
        if (aiSummary.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text('Synthese (generee par IA, a verifier) :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(aiSummary),
        ],
        pw.SizedBox(height: 12),
        pw.Text('Scans des pieds', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Statut', 'Ecart max (C)', 'Site'],
          data: s.map((e) => [d(e.time), e.status, e.maxDt.toStringAsFixed(1), e.site]).toList(),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Glycemies', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'g/L', 'Contexte', 'Zone'],
          data: g.map((e) => [d(e.time), e.gL.toStringAsFixed(2), e.context, e.band]).toList(),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Outil d\'aide au depistage, ne remplace pas un examen clinique.',
            style: const pw.TextStyle(fontSize: 9)),
      ],
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'qadam_rapport.pdf');
  }
}
