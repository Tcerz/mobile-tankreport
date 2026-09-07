import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/foto_laporan_model.dart';
import '../models/laporan_model.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

class LaporanProvider extends ChangeNotifier {
  List<Laporan> _daftarLaporan = [];
  List<Laporan> get daftarLaporan => _daftarLaporan;

  bool _sinkronBerjalan = false;
  bool get sinkronBerjalan => _sinkronBerjalan;

  String get _uid => AuthService.currentUser?.id ?? '';

  /// Dipanggil sekali tiap kali user berhasil login (lihat main.dart).
  /// 1) Mengadopsi laporan lokal lama yang belum punya pemilik (migrasi).
  /// 2) Menarik laporan milik user ini dari server (device lain / install ulang).
  Future<void> bootstrapUntukUser() async {
    if (_uid.isEmpty) return;
    await DatabaseHelper.instance.adopsiLaporanLama(_uid);
    await fetchAll();
    await sinkronDariServer();
  }

  void reset() {
    _daftarLaporan = [];
    notifyListeners();
  }

  Future<void> fetchAll() async {
    if (_uid.isEmpty) {
      _daftarLaporan = [];
    } else {
      _daftarLaporan = await DatabaseHelper.instance.getAllLaporanHeader(_uid);
    }
    notifyListeners();
  }

  Future<Laporan?> fetchDetail(int id) async {
    return await DatabaseHelper.instance.getLaporanDetail(id, _uid);
  }

  Future<int> simpanLaporan(Laporan laporan, List<FotoLaporan> fotos) async {
    final id = await DatabaseHelper.instance.insertLaporan(laporan.copyWith(userId: _uid), fotos);
    await fetchAll();
    return id;
  }

  Future<void> hapusLaporan(int id) async {
    await DatabaseHelper.instance.deleteLaporan(id);
    await fetchAll();
  }

  Future<void> updateLaporan(Laporan laporan, List<FotoLaporan> fotos) async {
    await DatabaseHelper.instance.updateLaporan(laporan, fotos);
    await fetchAll();
  }

  /// Menarik ulang laporan milik user ini dari server -- supaya laporan
  /// yang diupload dari device lain juga muncul di device sekarang.
  /// Return jumlah laporan baru yang berhasil ditarik.
  Future<int> sinkronDariServer() async {
    if (_uid.isEmpty || _sinkronBerjalan) return 0;
    _sinkronBerjalan = true;
    notifyListeners();
    int jumlahBaru = 0;
    try {
      jumlahBaru = await SyncService.tarikLaporanSaya();
      if (jumlahBaru > 0) await fetchAll();
    } finally {
      _sinkronBerjalan = false;
      notifyListeners();
    }
    return jumlahBaru;
  }
}
