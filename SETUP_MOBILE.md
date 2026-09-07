# Setup Aplikasi Mobile (Laporan Safety Patrol)

## Fitur baru di versi ini
1. Login akun (email & password) — menggantikan pengisian nama manual.
2. Profil akun otomatis dari sistem (nama, peran, status).
3. Logout & sesi tersimpan otomatis.
4. Akses ditolak otomatis jika akun dinonaktifkan admin.
5. Tombol "Upload" per laporan untuk mengirim laporan ke server (manual, laporan tetap dibuat offline seperti biasa).
6. **UI dirapikan** — tema warna & komponen lebih konsisten, terkesan aplikasi kerja (bukan gaya "futuristik").
7. **Input laporan sekarang jadi wizard 5 langkah**: Info & Foto → Loading → Discharge → Penyaluran → Storage (Penimbunan), dengan tombol Selanjutnya/Sebelumnya. Tujuannya supaya hanya 1 bagian yang dimuat di layar dalam satu waktu (lebih ringan, tidak semua form dirender sekaligus).
8. **Dialog izin kustom sebelum minta izin sistem** — sebelum kamera/lokasi diminta oleh Android/iOS, muncul dulu penjelasan singkat dari aplikasi ("Fitur ini memerlukan akses kamera dan lokasi..."). Kalau kedua izin sudah pernah disetujui, dialog ini tidak muncul lagi (langsung lanjut ambil foto).
9. Jam dunia berjalan di komponen terpisah, supaya tidak me-render ulang seluruh halaman tiap detik (lebih ringan).

## Perbaikan bug: laporan tercampur antar-akun di device yang sama
Sebelumnya, database lokal (SQLite) tidak membedakan pemilik laporan — semua akun yang login di device yang sama akan melihat laporan yang sama. Ini sudah diperbaiki:
- Setiap laporan lokal sekarang punya kolom `user_id` (pemilik), dan seluruh query daftar/detail laporan otomatis difilter berdasarkan akun yang sedang login.
- **Laporan lama** (sebelum update ini) otomatis "diadopsi" oleh akun pertama yang login setelah update — tidak hilang, tapi jadi milik akun itu.
- **Sinkronisasi antar-device**: saat login, aplikasi otomatis menarik (download) laporan milik akun tsb dari server — jadi kalau akun A login di HP baru, laporan yang pernah diupload dari HP lama akan muncul lagi. Ada juga tombol sinkron manual (ikon 🔄 di halaman utama) untuk menarik ulang kapan saja.
- Catatan: sinkronisasi ini hanya menarik laporan yang **sudah diupload** ke server (status "Terupload"). Laporan yang masih berstatus lokal di HP lain (belum diupload) tidak akan ikut tertarik — itu sesuai desain, karena data itu memang belum pernah dikirim ke server.

## Langkah setup

0. **Keamanan dulu**: `lib/config/supabase_config.dart` berisi kredensial asli dan sudah masuk `.gitignore` — jangan pernah hapus baris itu dari `.gitignore`. Kalau file ini belum ada di project Anda, salin dari `lib/config/supabase_config.example.dart` (hapus akhiran `.example`), baru isi nilainya.
1. **Buat project Supabase** di https://supabase.com (gratis).
2. Di **SQL Editor** Supabase, jalankan seluruh isi file `supabase/schema.sql` yang ada di folder ini.
3. Di **Authentication > Providers**, pastikan Email aktif, dan matikan "Allow new users to sign up" (karena akun hanya dibuat admin).
4. Buka `lib/config/supabase_config.dart`, isi `url` dan `anonKey` sesuai punya Anda (Project Settings > API di dashboard Supabase).
5. Buat akun pertama (admin) secara manual: Authentication > Users > Add User di dashboard Supabase, lalu di tabel `profiles` (Table Editor) ubah kolom `role` akun tsb jadi `admin`.
6. Jalankan seperti biasa:
   ```
   flutter pub get
   flutter run
   ```

## Catatan
- Sebelum `lib/config/supabase_config.dart` diisi, aplikasi akan menampilkan pesan "Supabase belum dikonfigurasi" — ini normal.
- Fitur upload memerlukan bucket Storage `laporan-foto` yang sudah dibuat otomatis oleh `schema.sql`.
- Registrasi akun baru **tidak bisa** dilakukan dari aplikasi mobile — hanya admin (lewat dashboard web, tahap berikutnya) atau langsung dari Supabase dashboard untuk sementara.
