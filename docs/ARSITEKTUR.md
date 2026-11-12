# Arsitektur alpha 0.1.0

## Penyimpanan dan konsistensi

Flutter 3.47.8/Dart 3.13.7, Material 3, locale Indonesia. `BookRepository` menjadi satu-satunya penulis SQLite melalui sqflite. Tabel `meta`, `people`, `ledgers`, `entries`, `audits`, dan `operations` menyimpan ID primer dan payload JSON berversi. Struktur relasi diperiksa domain sebelum commit; tidak mengandalkan foreign key SQL karena referensi berada dalam payload. Skema saat ini versi 1; downgrade ditolak.

Perubahan mengambil lock repository, menyalin model tanpa berbagi map operasi, memvalidasi seluruh saldo historis, lalu menulis selisih record dalam satu transaksi SQLite. Model UI dan pesan sukses dipublikasikan sesudah commit. ID operasi yang sama mengembalikan hasil sebelumnya. Kegagalan database tidak menandai operasi sebagai berhasil. `synchronous=FULL` dipakai; jaminan akhir tetap bergantung perangkat dan storage Android.

Nominal integer Rupiah, maksimum Rp999.999.999 per transaksi. Saldo maksimum Rp999.999.999.999.999. Urutan efektif: tanggal kalender, saldo awal terlebih dahulu, nomor urut stabil, ID. Waktu pembuatan UTC terpisah. Koreksi menonaktifkan versi lama, membuat pengganti, dan menulis audit bersama. Penghapusan transaksi keuangan tidak tersedia.

Model buku dimuat dalam memori; daftar memakai indeks saldo sementara, sementara validasi dan diff penyimpanan memeriksa keseluruhan buku. Dataset 20.000 entri diuji secara fungsional. Batas p95 pada HP sasaran belum diukur; optimasi indeks/database harus mempertahankan kontrak historis sebelum mengubah strategi ini.

## Format cadangan manual

File UTF-8 JSON `.catatanwarung`, versi 1:

```text
header: {format: catatanwarung, version: 1, cipher: AES-256-GCM, keyId}
nonce: base64 nonce 12 byte
ciphertext: base64 payload terenkripsi
tag: base64 tag autentikasi 16 byte
```

AAD adalah UTF-8 dari `jsonEncode(header)` dalam urutan field header yang terdapat di file. Mengubah versi/identitas kunci atau urutan serialisasi header tidak boleh mengabaikan pemeriksaan autentikasi. Payload berisi `snapshotAt` UTC, ringkasan jumlah record dan saldo dua kategori, serta seluruh buku termasuk audit dan ID operasi. Tidak ada kompresi. Nonce baru dibuat oleh implementasi AES-GCM untuk setiap ekspor.

Kunci AES acak 32 byte dihasilkan `cryptography`; kartu berupa JSON `catatanwarung-key`, versi 1, ID dan kode heksadesimal 64 karakter. ID adalah 8 byte pertama SHA-256 kunci dalam heksadesimal; ID bukan kunci. Kartu dan kunci tidak berada dalam file cadangan. Enkripsi/dekripsi dijalankan melalui `compute` di isolate tersendiri.

Salinan kunci lokal dibungkus AES-GCM oleh Android Keystore dan disimpan di `noBackupFilesDir/backup-key.bin`. Kehilangan kunci lokal tidak menghapus database; pengguna menyiapkan kartu baru untuk ekspor baru. Kartu eksternal tetap diperlukan untuk file lama. Kunci baru disimpan lokal setelah file cadangan berhasil ditulis/dibaca ulang.

Pemilih file native menggunakan Storage Access Framework `ACTION_CREATE_DOCUMENT`/`ACTION_OPEN_DOCUMENT`, tanpa izin penyimpanan luas. Penulisan diikuti pembacaan ulang dan pembandingan SHA-256. Provider dapat tetap mengunggah ke cloud sesudahnya; keberhasilan ini bukan bukti unggahan remote. Pembatalan/gagal tidak memajukan status snapshot.

Batas: file 100 MiB, payload terurai 200 MiB, total record orang/kategori/transaksi/audit 200.000; daftar operasi maksimal 600.000. Decode menolak skema asing, autentikasi salah, ID duplikat, relasi/rantai audit rusak, ketidakcocokan jumlah/saldo, dan pelanggaran domain sebelum menyentuh database aktif.

## Pemulihan

Decode dan validasi → pratinjau pengguna → konfirmasi penggantian → batalkan metadata ekspor perangkat → tulis/flush/validasi snapshot pengaman ke `noBackupFilesDir` jika ada buku aktif → penggantian seluruh tabel dalam transaksi → publikasi model baru. Snapshot pengaman berada di luar database sehingga tetap tersedia setelah proses dimulai ulang. Rollback mengganti buku dengan snapshot tersebut dan tidak menimpanya. File cadangan sumber tidak diubah.

Metadata ekspor, snapshot pengaman, dan kunci lokal dikecualikan dari backup sistem. Jika proses berhenti sesudah commit tetapi sebelum metadata status tersimpan, UI tetap konservatif: tidak mengklaim buku baru telah diekspor.

## Android Auto Backup

Manifest mengaktifkan backup dan menunjuk aturan sebelum Android 12 serta `dataExtractionRules` Android 12+. Allowlist hanya database `catatan_warung.db` dan jurnal SQLite terkait. Keystore, status file eksternal, file sementara, snapshot rollback, dan kunci tidak dicadangkan. Database lokal privat tidak memakai enkripsi tambahan yang bergantung kunci aplikasi, sesuai PRD.

Tidak ada backend atau analytics. Main manifest tidak meminta izin internet; manifest debug/profile bawaan Flutter memerlukannya untuk tooling pengembangan. Build release memerlukan konfigurasi penandatanganan tetap dan tidak otomatis memakai kunci debug.

## Struktur kode

| Folder | Tanggung jawab |
| --- | --- |
| `lib/domain` | Model, parse/validasi, saldo, tanggal, riwayat |
| `lib/data` | SQLite, lock, transaksi, idempotensi, restore/rollback |
| `lib/backup` | Kriptografi, format, status perangkat, kanal native |
| `lib/ui` | Formulir, aksesibilitas dasar, daftar, riwayat, cadangan |
| `android/app/src/main` | Keystore, pemilih file, backup rules, ikon |
| `test` | Domain, database nyata FFI, kriptografi, widget, volume |
| `integration_test` | SQLite dan Keystore Android, restore, startup UI |
