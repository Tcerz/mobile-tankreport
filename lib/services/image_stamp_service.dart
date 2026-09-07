import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../models/foto_laporan_model.dart';

/// Menempelkan panel teks (label : value) di BAWAH foto (tidak menimpa
/// foto), dengan kolom label yang sejajar rapi dan tinggi panel dihitung
/// otomatis (menangani value yang wrap jadi lebih dari 1 baris).
///
/// Hasilnya langsung berupa bytes PNG di memori (tidak menulis file
/// sementara ke disk) supaya lebih cepat dan tidak menumpuk file cache.
class ImageStampService {
  /// Sumber tunggal daftar label:value yang distempel ke foto, dipakai
  /// SAMA baik untuk "Cetak JPG" maupun untuk foto yang disisipkan ke PDF,
  /// supaya keduanya selalu konsisten (termasuk koordinat).
  static List<MapEntry<String, String>> entriesUntukFoto(
    FotoLaporan foto,
    String namaPembuat,
  ) {
    return [
      MapEntry('Kategori', foto.kategori),
      MapEntry('Petugas', namaPembuat),
      MapEntry('Lokasi', foto.alamat),
      MapEntry('Koordinat', '${foto.latitude}, ${foto.longitude}'),
      MapEntry('Suhu', foto.suhu),
      MapEntry('Waktu', foto.jam),
    ];
  }

  /// Menghasilkan bytes PNG foto yang sudah ditempel panel teks di bawahnya.
  static Future<Uint8List> stampImageBytes({
    required String imagePath,
    required List<MapEntry<String, String>> entries,
  }) async {
    final imageFile = File(imagePath);
    final Uint8List imageBytes = await imageFile.readAsBytes();

    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image originalImage = frameInfo.image;

    final double imgWidth = originalImage.width.toDouble();
    final double imgHeight = originalImage.height.toDouble();

    final double padding = imgWidth * 0.04;
    final double fontSize = imgWidth * 0.032;
    final double lineSpacing = fontSize * 0.55;
    final double spacingLabelColon = fontSize * 0.2;
    final double spacingColonValue = fontSize * 0.4;

    // 1) Lebar kolom label sama untuk semua baris agar titik dua sejajar.
    double labelColumnWidth = 0;
    final List<TextPainter> labelPainters = [];
    for (final e in entries) {
      final tp = TextPainter(
        text: TextSpan(
          text: e.key,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainters.add(tp);
      if (tp.width > labelColumnWidth) labelColumnWidth = tp.width;
    }

    final TextPainter colonPainter = TextPainter(
      text: TextSpan(
        text: ':',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double colonX = padding + labelColumnWidth + spacingLabelColon;
    final double valueX = colonX + colonPainter.width + spacingColonValue;
    final double valueMaxWidth = imgWidth - valueX - padding;

    // 2) Siapkan TextPainter tiap value (word-wrap) & hitung tinggi panel.
    final List<TextPainter> valuePainters = [];
    double textBlockHeight = fontSize * 0.9;
    for (final e in entries) {
      final tp = TextPainter(
        text: TextSpan(
          text: e.value,
          style: TextStyle(color: Colors.white, fontSize: fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: valueMaxWidth);
      valuePainters.add(tp);
      textBlockHeight += tp.height + lineSpacing;
    }
    textBlockHeight += fontSize * 0.5;

    final double totalHeight = imgHeight + textBlockHeight;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, imgWidth, totalHeight),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, imgWidth, totalHeight),
      Paint()..color = Colors.black,
    );

    canvas.drawImage(originalImage, Offset.zero, Paint());

    // 3) Gambar tiap baris label + titik dua + value di panel bawah foto.
    double dy = imgHeight + (fontSize * 0.9);
    for (int i = 0; i < entries.length; i++) {
      final labelTp = labelPainters[i];
      final valueTp = valuePainters[i];

      labelTp.paint(canvas, Offset(padding, dy));
      colonPainter.paint(canvas, Offset(colonX, dy));
      valueTp.paint(canvas, Offset(valueX, dy));

      dy += valueTp.height + lineSpacing;
    }

    final ui.Picture picture = recorder.endRecording();
    final ui.Image finalImage = await picture.toImage(
      imgWidth.toInt(),
      totalHeight.toInt(),
    );
    final ByteData? byteData =
        await finalImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
