import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadCsv(String content, String fileName) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(content);
  
  final xFile = XFile(file.path);
  await Share.shareXFiles(
    [xFile],
    subject: 'Child Logs Export',
    text: 'Exported child logs',
  );
}

