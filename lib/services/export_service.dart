import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/fuga.dart';
import 'web_stub.dart' if (dart.library.html) 'web_download_service.dart' as web_service;

class ExportService {
  static Future<void> exportFilteredExcel(BuildContext context, List<Fuga> fugas, String subtitle) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Generando Excel ($subtitle)...")));

    var excel = xl.Excel.createExcel();
    xl.Sheet sheetObject = excel['Sheet1'];

    xl.CellStyle headerStyle = xl.CellStyle(
      bold: true,
      fontColorHex: xl.ExcelColor.white,
      backgroundColorHex: xl.ExcelColor.fromHexString('#1F497D'),
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
    );

    List<String> headerText = [
      'ID', 'Fecha/Zona', 'Tipo Fuga', 'Área', 'Ubicación', 
      'ID Máquina', 'Severidad', 'Categoría', 'L/min', 
      'Costo Anual (USD)', 'Estado', 'Comentarios'
    ];
    
    List<xl.CellValue> header = headerText.map((t) => xl.TextCellValue(t)).toList();
    sheetObject.appendRow(header);

    for (int i = 0; i < header.length; i++) {
      var cell = sheetObject.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    sheetObject.setColumnWidth(0, 10.0);
    sheetObject.setColumnWidth(1, 25.0);
    sheetObject.setColumnWidth(2, 20.0);
    sheetObject.setColumnWidth(3, 25.0);
    sheetObject.setColumnWidth(4, 20.0);
    sheetObject.setColumnWidth(5, 18.0);
    sheetObject.setColumnWidth(6, 15.0);
    sheetObject.setColumnWidth(7, 20.0);
    sheetObject.setColumnWidth(8, 12.0);
    sheetObject.setColumnWidth(9, 20.0);
    sheetObject.setColumnWidth(10, 20.0);
    sheetObject.setColumnWidth(11, 45.0);

    for (var f in fugas) {
      sheetObject.appendRow([
        xl.TextCellValue(f.id?.toString() ?? '0'),
        xl.TextCellValue(f.zona),
        xl.TextCellValue(f.tipoFuga),
        xl.TextCellValue(f.area),
        xl.TextCellValue(f.ubicacion),
        xl.TextCellValue(f.idMaquina),
        xl.TextCellValue(f.severidad),
        xl.TextCellValue(f.categoria),
        xl.TextCellValue(f.lMin.toStringAsFixed(2)),
        xl.TextCellValue(f.costoAnual.toStringAsFixed(2)),
        xl.TextCellValue(f.estado),
        xl.TextCellValue(f.comentarios),
      ]);
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final dateStr = "${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}";
      // Use clean string for filename
      final fnSub = subtitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      await _saveAndShareFile(
        context,
        bytes,
        'Export_${fnSub}_$dateStr.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Reporte Excel: $subtitle',
        'xlsx',
      );
    }
  }

  static Future<void> _saveAndShareFile(BuildContext context, List<int> bytes, String fileName, String mimeType, String subject, String extension) async {
    try {
      if (kIsWeb) {
        web_service.downloadFileWeb(bytes, fileName);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ $subject descargado")));
        }
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar $subject',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: [extension],
        );
        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes, flush: true);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Archivo guardado en: $outputFile")));
          }
        }
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        
        final xFile = XFile(file.path, mimeType: mimeType);
        await Share.shareXFiles([xFile], subject: subject, text: 'Adjunto $subject.');
      }
    } catch (e) {
      print('Error saving/sharing file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar: $e")));
      }
    }
  }
}
