import 'package:flutter/material.dart';
import '../models/kegiatan_model.dart';
import 'catatan_dengan_foto.dart';
import 'tangki_multi_select.dart';

class StorageForm extends StatelessWidget {
  final StorageData data;
  final ValueChanged<StorageData> onChanged;

  const StorageForm({super.key, required this.data, required this.onChanged});

  /// Kumpulan tangki yang sudah dipakai di kategori LAIN selain [indexSaatIni],
  /// supaya satu tangki hanya bisa berstatus satu hal dalam satu laporan
  /// (mis. tidak bisa "Aktif/Idle" sekaligus "Off").
  Set<String> _tangkiDipakaiDiKategoriLain(int indexSaatIni) {
    final semua = <List<String>>[
      data.tangkiLoading,
      data.tangkiDischarge,
      data.tangkiPenyaluran,
      data.tangkiAktifIdle,
      data.tangkiOff,
    ];
    final hasil = <String>{};
    for (int i = 0; i < semua.length; i++) {
      if (i == indexSaatIni) continue;
      hasil.addAll(semua[i]);
    }
    return hasil;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('4. Storage (Penimbunan)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'Satu tangki hanya bisa dipilih di satu kategori saja.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: data.personel,
              decoration: const InputDecoration(labelText: 'Personel', border: OutlineInputBorder()),
              onChanged: (v) => onChanged(data.copyWith(personel: v)),
            ),
            const SizedBox(height: 12),
            TangkiMultiSelect(
              label: 'Tangki Loading',
              selected: data.tangkiLoading,
              disabledTanks: _tangkiDipakaiDiKategoriLain(0),
              onChanged: (v) => onChanged(data.copyWith(tangkiLoading: v)),
            ),
            const SizedBox(height: 12),
            TangkiMultiSelect(
              label: 'Tangki Discharge',
              selected: data.tangkiDischarge,
              disabledTanks: _tangkiDipakaiDiKategoriLain(1),
              onChanged: (v) => onChanged(data.copyWith(tangkiDischarge: v)),
            ),
            const SizedBox(height: 12),
            TangkiMultiSelect(
              label: 'Tangki Penyaluran',
              selected: data.tangkiPenyaluran,
              disabledTanks: _tangkiDipakaiDiKategoriLain(2),
              onChanged: (v) => onChanged(data.copyWith(tangkiPenyaluran: v)),
            ),
            const SizedBox(height: 12),
            TangkiMultiSelect(
              label: 'Tangki Aktif/Idle',
              selected: data.tangkiAktifIdle,
              disabledTanks: _tangkiDipakaiDiKategoriLain(3),
              onChanged: (v) => onChanged(data.copyWith(tangkiAktifIdle: v)),
            ),
            const SizedBox(height: 12),
            TangkiMultiSelect(
              label: 'Tangki Off',
              selected: data.tangkiOff,
              disabledTanks: _tangkiDipakaiDiKategoriLain(4),
              onChanged: (v) => onChanged(data.copyWith(tangkiOff: v)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: data.kondisi,
              decoration: const InputDecoration(labelText: 'Kondisi', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: kondisiAman, child: Text(kondisiAman)),
                DropdownMenuItem(value: kondisiTidakAman, child: Text(kondisiTidakAman)),
              ],
              onChanged: (v) => onChanged(data.copyWith(kondisi: v)),
            ),
            const SizedBox(height: 8),
            CatatanDenganFoto(
              note: data.note,
              fotoPaths: data.noteFotos,
              onNoteChanged: (v) => onChanged(data.copyWith(note: v)),
              onFotoChanged: (v) => onChanged(data.copyWith(noteFotos: v)),
            ),
          ],
        ),
      ),
    );
  }
}
