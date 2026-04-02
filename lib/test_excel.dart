import 'package:excel/excel.dart';

void test() {
  var style = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.blue,
  );
  var excel = Excel.createExcel();
  var sheet = excel['Sheet1'];
  sheet.setColumnWidth(0, 20.0);
  sheet.setColumnAutoFit(1);
}
