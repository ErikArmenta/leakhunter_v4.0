import 'dart:html' as html;

void downloadFileWeb(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void openInteractiveMapWeb(String htmlContent) {
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, "Plano Interactivo");
  // No revocamos la URL inmediatamente para que cargue el mapa,
  // el navegador la limpiará al cerrar la pestaña.
}
