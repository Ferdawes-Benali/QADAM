import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';

/// 30-day report for the doctor, in French (the language of Tunisian medical records).
class ReportService {
  static const _site = {'mth1': '1re tête métatars.', 'mth5': '5e tête métatars.', 'hallux': 'hallux', 'heel': 'talon'};
  static const _level = {'green': 'Normal', 'amber': 'À surveiller', 'red': 'Alerte'};
  static const _src = {'hardware': 'banc réel', 'simulated': 'SIMULATION', 'manual': 'manuel'};
  static const _ctx = {'fasting': 'à jeun', 'after_meal': 'après repas', 'other': 'autre'};
  static const _type = {'t1': 'type 1', 't2': 'type 2', 'gest': 'gestationnel', 'other': 'autre'};
  static const _treat = {'insulin': 'insuline', 'tablets': 'comprimés', 'both': 'insuline + comprimés', 'diet': 'régime seul'};

  static String _d(DateTime t) => '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  static String _n(double v, [int d = 1]) => v.toStringAsFixed(d).replaceAll('.', ',');

  static Future<void> share({
    required Profile profile,
    required String? patientRef,
    required List<GlucoseEntry> glucose,
    required List<FootScan> scans,
    required int adherencePct,
  }) async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Rubik-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Rubik-SemiBold.ttf'));
    final since = DateTime.now().subtract(const Duration(days: 30));
    final g = glucose.where((e) => e.time.isAfter(since)).toList();
    final s = scans.where((e) => e.time.isAfter(since)).toList();
    final avg = g.isEmpty ? null : g.map((e) => e.gL).reduce((a, b) => a + b) / g.length;
    final inTarget = g.isEmpty ? 0 : (100 * g.where((e) => e.band == 'in_target').length / g.length).round();
    final lows = g.where((e) => e.band == 'low').length;
    final maxScan = s.isEmpty ? null : s.reduce((a, b) => a.maxDt >= b.maxDt ? a : b);
    final simulated = s.where((e) => e.isSimulated).length;
    const navy = PdfColor.fromInt(0xFF102D4B);
    const grey = PdfColor.fromInt(0xFF5F6B78);

    final doc = pw.Document(title: 'Qadam - rapport patient', author: 'Qadam');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      footer: (ctx) => pw.Text(
        'Qadam est une aide au dépistage (prototype HackCure), pas un diagnostic ni un dispositif médical validé. '
        'Page ${ctx.pageNumber}/${ctx.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: grey),
      ),
      build: (ctx) => [
        pw.Text('Qadam — Rapport patient (30 jours)', style: pw.TextStyle(fontSize: 18, font: bold, color: navy)),
        pw.SizedBox(height: 4),
        pw.Text('Édité le ${_d(DateTime.now())}${patientRef != null ? ' · code patient $patientRef' : ''}',
            style: const pw.TextStyle(fontSize: 9, color: grey)),
        pw.SizedBox(height: 12),
        pw.Text('Patient : ${profile.name} · diabète ${_type[profile.diabetesType] ?? profile.diabetesType}'
            '${profile.yearDiagnosed != null ? ' depuis ${profile.yearDiagnosed}' : ''} · '
            'traitement : ${_treat[profile.treatment] ?? profile.treatment} · '
            'antécédent d\'ulcère : ${profile.pastUlcer ? 'oui' : 'non'} · perte de sensibilité déclarée : ${profile.numbness ? 'oui' : 'non'}'),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF2F7FC)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Synthèse automatique (calculée, sans IA)', style: pw.TextStyle(font: bold)),
            pw.SizedBox(height: 4),
            pw.Text('Scans plantaires : ${s.length} — ${s.where((e) => e.level == 'red').length} en alerte, '
                '${s.where((e) => e.level == 'amber').length} à surveiller'
                '${maxScan != null ? ' ; écart maximal ${_n(maxScan.maxDt)} °C (${_site[maxScan.site] ?? maxScan.site}, ${_d(maxScan.time)})' : ''}.'
                '${simulated > 0 ? ' Dont $simulated scan(s) en SIMULATION, à ne pas interpréter.' : ''}'),
            pw.Text('Glycémie : ${g.length} mesures, moyenne ${avg == null ? '—' : _n(avg, 2)} g/L, $inTarget % dans la cible, '
                '$lows hypoglycémie(s) < 0,70 g/L. Observance déclarée (7 j) : $adherencePct %.'),
          ]),
        ),
        pw.SizedBox(height: 14),
        pw.Text('Scans des pieds', style: pw.TextStyle(font: bold, color: navy)),
        pw.SizedBox(height: 4),
        s.isEmpty
            ? pw.Text('Aucun scan sur la période.')
            : pw.TableHelper.fromTextArray(
                headers: ['Date', 'Niveau', 'Écart (°C)', 'Site', 'Gauche', 'Droite', 'Confiance', 'Source', 'Avis soignant'],
                headerStyle: pw.TextStyle(font: bold, fontSize: 8),
                cellStyle: const pw.TextStyle(fontSize: 8),
                data: [
                  for (final e in s.reversed)
                    [
                      _d(e.time),
                      _level[e.level] ?? e.level,
                      _n(e.maxDt),
                      _site[e.site] ?? e.site,
                      _n(e.left[e.site] ?? 0, 2),
                      _n(e.right[e.site] ?? 0, 2),
                      '${e.confidence}/100',
                      _src[e.source] ?? e.source,
                      e.reviewStatus == 'confirmed' ? 'confirmée' : e.reviewStatus == 'dismissed' ? 'rejetée' : '—',
                    ]
                ],
              ),
        pw.SizedBox(height: 14),
        pw.Text('Glycémies', style: pw.TextStyle(font: bold, color: navy)),
        pw.SizedBox(height: 4),
        g.isEmpty
            ? pw.Text('Aucune mesure sur la période.')
            : pw.TableHelper.fromTextArray(
                headers: ['Date', 'g/L', 'Contexte', 'Zone'],
                headerStyle: pw.TextStyle(font: bold, fontSize: 8),
                cellStyle: const pw.TextStyle(fontSize: 8),
                data: [
                  for (final e in g.reversed)
                    [
                      _d(e.time),
                      _n(e.gL, 2),
                      _ctx[e.context] ?? e.context,
                      {'low': 'hypoglycémie', 'very_high': 'très élevée', 'in_target': 'cible', 'out_of_target': 'hors cible'}[e.band] ?? e.band,
                    ]
                ],
              ),
        pw.SizedBox(height: 10),
        pw.Text('Mesures de température issues d\'un banc prototype (capteurs non cutanés, non validés cliniquement). '
            'Règle : écart gauche/droite ≥ 2,2 °C au même site deux jours de suite (IWGDF 2023).',
            style: const pw.TextStyle(fontSize: 8, color: grey)),
      ],
    ));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'qadam_rapport.pdf');
  }
}
