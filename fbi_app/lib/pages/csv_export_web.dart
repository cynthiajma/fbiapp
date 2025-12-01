// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

Future<void> downloadCsv(String content, String fileName) async {
  // Create a Blob with the CSV content
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/csv');
  
  // Create a download URL
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Create an anchor element and trigger download
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  
  html.document.body?.children.add(anchor);
  anchor.click();
  
  // Clean up
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

