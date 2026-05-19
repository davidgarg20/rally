import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Render the widget tree under `key` as a PNG and write to a temp file.
/// Caller is responsible for not deleting it before the share sheet opens.
///
/// `pixelRatio` defaults to 3.0 (≈ 1080×1080 for a logical 360×360 card).
Future<File> captureWidgetAsPng(
  GlobalKey key, {
  double pixelRatio = 3.0,
  String prefix = 'rally-share',
}) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
