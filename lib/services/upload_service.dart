import 'dart:io';
import '../database/database_helper.dart';
import '../models/laporan_model.dart';
import 'auth_service.dart';

/// Mengunggah satu laporan (header + foto) ke Supabase secara manual,
/// dipicu oleh tombol "Upload" di tiap laporan (bukan sinkronisasi otomatis).
class UploadService {
  static Future<void> uploadLaporan(Laporan laporan) async {
    final uid = AuthService.currentUser?.id;
    if (uid == null || laporan.id == null) throw Exception('Belum login');

    await DatabaseHelper.instance.updateStatusUpload(laporan.id!, 'UPLOADING');
    try {
      final client = AuthService.client;

      final report = await client
          .from('reports')
          .insert({
            'user_id': uid,
            'nama_pembuat': laporan.namaPembuat,
            'tanggal': laporan.tanggal,
            'jam_patroli': laporan.jamPatroli,
            'pic_patroli': laporan.picPatroli,
            'waktu_dibuat': laporan.waktuDibuat,
            'loading_data': laporan.loading.toJson(),
            'discharge_data': laporan.discharge.toJson(),
            'penyaluran_data': laporan.penyaluran.toJson(),
            'storage_data': laporan.storage.toJson(),
          })
          .select('id')
          .single();
      final reportId = report['id'];

      for (final foto in laporan.fotos) {
        final file = File(foto.imagePath);
        if (!await file.exists()) continue;
        final path = '$uid/$reportId/${foto.kategori}.jpg';
        await client.storage.from('laporan-foto').upload(path, file);
        final url = client.storage.from('laporan-foto').getPublicUrl(path);

        await client.from('report_photos').insert({
          'report_id': reportId,
          'kategori': foto.kategori,
          'photo_url': url,
          'latitude': foto.latitude,
          'longitude': foto.longitude,
          'alamat': foto.alamat,
          'jam': foto.jam,
          'suhu': foto.suhu,
        });
      }

      await DatabaseHelper.instance.updateRemoteId(laporan.id!, reportId as String);
      await DatabaseHelper.instance.updateStatusUpload(laporan.id!, 'UPLOADED');
    } catch (e) {
      await DatabaseHelper.instance.updateStatusUpload(laporan.id!, 'FAILED');
      rethrow;
    }
  }
}
