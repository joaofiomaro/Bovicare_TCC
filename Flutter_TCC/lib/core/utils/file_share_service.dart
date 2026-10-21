import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Salva bytes num arquivo temporário e abre a folha de compartilhamento do
/// sistema (salvar em Arquivos, Drive, WhatsApp, e-mail...).
///
/// O arquivo fica no diretório temporário do app (privado, limpo pelo
/// sistema) — nada é gravado em armazenamento público sem ação do usuário.
abstract final class FileShareService {
  static Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? subject,
  }) async {
    // Web não tem sistema de arquivos (path_provider/dart:io): o arquivo vai
    // direto da memória e o navegador compartilha ou baixa.
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
          fileNameOverrides: [fileName],
          subject: subject,
          title:   subject,
        ),
      );
      return;
    }

    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files:   [XFile(file.path, mimeType: mimeType, name: fileName)],
        subject: subject,
        title:   subject,
      ),
    );
  }
}
