// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

void unduhFileCsv(String namaFile, List<List> barisData) {
  final csvBuffer = StringBuffer();

  for (final baris in barisData) {
    final barisAman = baris.map((kolom) {
      final teks = kolom.toString().replaceAll('"', '""');
      return '"$teks"';
    }).join(',');
    csvBuffer.writeln(barisAman);
  }

  // Tambahkan penanda UTF-8 BOM agar Excel otomatis memisahkan kolom dengan rapi
  final bytes = utf8.encode('\uFEFF${csvBuffer.toString()}');
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', namaFile)
    ..click();

  html.Url.revokeObjectUrl(url);
}