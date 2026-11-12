# Validasi alpha 0.1.0

Dokumen ini membedakan implementasi, hasil uji lokal, dan penerimaan lapangan. Alpha belum boleh disebut rilis v1 yang lulus seluruh PRD.

## Bukti yang sudah tersedia

| Pemeriksaan | Hasil dan batas bukti |
| --- | --- |
| `flutter analyze --no-pub` | Tidak ada issue pada 12 November 2026 |
| `flutter test` | 23 tes lulus pada 12 November 2026 setelah penyegaran tampilan; mencakup domain, SQLite FFI nyata, kriptografi, volume, dan widget |
| Contoh saldo PRD | Saldo awal 20.000 + utang 25.000 − bayar 10.000; koreksi utang menjadi 15.000 menghasilkan 25.000; pembayaran terakhir menghasilkan nol |
| Integritas transaksi | Retry serentak tepat sekali; pemaksaan kegagalan SQL tidak mengubah model/operasi; percobaan ulang dapat berhasil; restore gagal tidak mengganti data |
| Aturan historis | Pembayaran berlebih/lampau, tanggal tidak valid, koreksi yang menyebabkan negatif ditolak; koreksi berantai, pindah orang, batas transaksi dan saldo awal diuji |
| Persistensi | Database ditutup/dibuka ulang, saldo dan audit tetap benar; snapshot rollback tetap tersedia sesudah pembukaan ulang |
| Cadangan terenkripsi | Roundtrip, kartu kunci, nonce berbeda, kunci salah, ciphertext/tag/nonce yang diubah, versi asing, dan file tidak valid diuji |
| Volume N03 | 500 orang, 1.000 kategori, 19.000 transaksi dan 1.000 audit, nama panjang/lunas/arsip; ekspor terenkripsi → decode → restore → transaksi baru lulus |
| Tampilan | Delapan layar utama pada 360 × 800 logical px dengan skala teks 100% dan 200% tanpa exception overflow; alur bayar melalui formulir mengubah saldo 25.000 menjadi 15.000 |
| Kontras regresi | Teks nama buku dan dua kartu kategori minimal 4,5:1 pada tema terang/gelap; ditemukan dan diperbaiki masalah teks pucat saat inspeksi screenshot |
| Android API 35 | Tes integrasi lulus pada emulator: SQLite Android, Android Keystore, enkripsi/pemulihan/rollback dan startup UI; bukan bukti HP fisik |
| Pemilih file Android | Pada 12 November 2026, kartu kunci disimpan lewat SAF, salinan ditarik ke komputer, kartu dibuka ulang untuk verifikasi, dan file `.catatanwarung` diekspor serta dibaca ulang. UI menampilkan sukses dan status snapshot yang benar. Provider yang diuji: Downloads lokal |
| Uninstall dan restore manual | Pada emulator API 35, dibuat pelanggan uji dengan utang Rp25.000; file dan kartu disalin ke komputer; aplikasi di-uninstall lalu dipasang kembali. Pratinjau mendeteksi 1 orang/1 transaksi/Rp25.000; pemulihan berhasil dan status meminta cadangan baru. Backup Manager sistem nonaktif selama skenario ini |
| Aturan backup sistem | Pada emulator API 35 melalui `com.android.localtransport/.LocalTransport`, buku kosong dibackup bersama metadata paket `@pm@`, data aplikasi dibersihkan, lalu restore selesai dengan status 0. SHA-256 database sebelum/sesudah sama: `57736c642fff4753603bea71a2fb11b3b2b6d9ddb72735dcab27e3c4c15d23c9`. Marker di `no_backup` tidak kembali. Ini bukti transport lokal, bukan Google cloud/perangkat fisik |
| APK debug | Build aplikasi biasa berhasil; paket `id.catatanwarung.catatan_warung`, minSdk 26. APK debug menggunakan tanda tangan pengembangan |

Tes otomatis berada di `test/` dan `integration_test/android_test.dart`. Tes volume adalah verifikasi fungsi di komputer pengembangan, bukan pengukuran p95 release pada HP ibu.

Pemeriksaan ulang 12 November 2026 setelah memperbaiki pemilihan SDK VS Code: Flutter 3.47.8 stable berhasil membangun APK debug; 21 tes lulus dan analyzer tidak menemukan issue. Sebelumnya debugger memakai Flutter 3.50 beta dari PATH sehingga menolak AGP 9.1.0 proyek. Workspace sekarang memilih SDK stable dan menyediakan konfigurasi F5; sesi VS Code yang sudah terbuka perlu Reload Window. Versi Gradle/AGP proyek tetap mengikuti baseline yang sudah diuji.

Catatan uji sistem: percobaan saat paket masih force-stop ditolak sebagai tidak memenuhi syarat backup; percobaan restore tanpa metadata `@pm@` gagal dengan -1000. Setelah prasyarat transport lokal dilengkapi, backup dan restore berhasil. Konfigurasi emulator dikembalikan ke transport Google semula dan Backup Manager nonaktif. Saat cold start emulator sempat menampilkan ANR System UI; itu tidak dihitung sebagai pengukuran performa aplikasi.

Artefak APK alpha: `artifacts/catatan-warung-0.1.0-alpha.apk` (182.846.232 byte), SHA-256 `c0c9bc06799588165e366c6c121acf0e3dc68107eecd403ee89ca0c3acc43fba`. APK universal debug memuat arm64-v8a, armeabi-v7a, dan x86_64; minSdk 26/targetSdk 36 terkonfirmasi dari manifest APK. Ukurannya belum mewakili build release.

## Penyegaran tampilan 12 November 2026

Referensi pengguna diterapkan sebagai header biru, panel putih membulat, ikon kategori melingkar, dan tombol kapsul. Navigasi pelanggan/pemasok, pembayaran, koreksi, serta cadangan tetap menggunakan alur yang sama. Area pencarian dan filter kini dapat digulir saat keyboard terbuka; tombol tambah orang tetap tersedia di bawah layar. Pada teks besar, nominal beranda mendapat lebar penuh.

- `flutter analyze --no-pub`: tidak ada issue.
- `flutter test --no-pub`: 23 tes lulus. Tambahan pengujian memeriksa tujuan navigasi pelanggan/pemasok dan pencarian pada teks 200% dengan inset keyboard 300 logical px. Tes pembayaran, domain, database, kriptografi, dan volume tetap lulus.
- `flutter test tool/preview_screens.dart --no-pub`: lulus; menghasilkan tujuh PNG di `artifacts/ui-redesign/` dengan database sementara dan data contoh. Pratinjau mencakup beranda, daftar pelanggan, riwayat, pembayaran, cadangan, teks 200%, dan tema gelap. Ini render widget lokal, bukan bukti tampilan pada HP fisik.
- SHA-256 `lib/domain/book.dart`, `lib/data/book_repository.dart`, `lib/backup/backup.dart`, dan `PRD.md` sama dengan sebelum perubahan tampilan. Tidak ada migrasi database atau perubahan format cadangan.
- Bukti integrasi Android dan restore di atas berasal dari pengujian alpha sebelumnya; pengujian native tersebut tidak diulang untuk perubahan visual ini.
- Build APK debug berhasil. Salinan versi tampilan baru: `artifacts/catatan-warung-0.1.0-blue-ui.apk`, 182.846.232 byte, SHA-256 `3211e0898aad861d6bd7b9a0550d31e6d3f3f6b5a9f4d854b8bf709467a81224`. APK ini belum dipasang pada HP fisik; instalasi/data emulator yang sedang digunakan tidak diubah.

## Pemetaan cakupan

| PRD | Implementasi alpha |
| --- | --- |
| F01, F03–F08, F10, F13 | Tersedia; aturan inti diuji otomatis dan sebagian alur UI diuji widget |
| F02 Should | Pencarian saran berupa kecocokan substring, belum fuzzy typo/kemiripan ejaan; peringatan nama persis sama tersedia |
| F09, F14 Should | Arsip per kategori, pengaktifan ulang, hapus orang tanpa riwayat tersedia dan diuji repository |
| F11, F12, F16, F18 | Codec, restore, snapshot status, pengingat dan kunci tersedia; ketepatan perilaku provider file dan keluarga harus dibuktikan pada HP sasaran |
| F17 | Manifest dan allowlist backup database tersedia dan roundtrip transport lokal emulator lulus; belum menjadi bukti pemulihan Google cloud pada HP ibu |
| F15 | PIN tetap di luar v1 sesuai PRD |

## Gerbang yang masih harus diselesaikan sebelum rilis v1

- [ ] Konfirmasi nomor model dan versi Android HP ibu melalui Pengaturan → Tentang ponsel. Sebutan “Samsung Galaxy S12” belum cukup untuk menetapkan perangkat uji.
- [ ] Instal dan jalankan seluruh alur inti di Android API 26 dan HP ibu.
- [ ] Uji TalkBack, ukuran sentuh, keyboard, pembesaran 200%, kontras seluruh keadaan, dan kenyamanan membaca dengan ibu; tes overflow saja belum membuktikan kemudahan penggunaan.
- [ ] Ukur 20 percobaan per operasi pada release/profile HP sasaran menggunakan dataset N03: p95 simpan ≤500 ms, daftar/cari ≤1 detik, cold start ≤3 detik, ekspor/restore lokal ≤60 detik.
- [ ] Uji penghentian proses saat menyimpan/restore, ruang penyimpanan penuh, dan siklus update APK dengan tanda tangan yang sama; pengujian SQL gagal bukan pengganti seluruh kegagalan perangkat.
- [ ] Ulangi cadangan file → uninstall → install → restore pada HP fisik, beserta kartu salah, file rusak, pembatalan picker, rotasi kunci, dan cadangan lama setelah rotasi. Jalur berhasil sudah diuji lewat picker pada emulator.
- [ ] Uji Android Auto Backup pada akun/perangkat sasaran, termasuk kondisi nonaktif/tidak tersedia serta pengecualian kunci/status/rollback. Tidak menjanjikan jadwal sistem.
- [ ] Keluarga berhasil menyimpan file dan kartu kunci di lokasi terpisah di luar HP warung serta memulihkannya tanpa bantuan pengembang.
- [ ] Jalankan uji tujuh hari berdampingan dengan buku kertas; cocokkan kedua kategori, riwayat koreksi, dan pelaksanaan cadangan mingguan.
- [ ] Siapkan serta simpan salinan aman keystore rilis, konfigurasi signing lokal, dan uji pembaruan. Jangan memakai APK debug sebagai distribusi publik.

Tidak ada backend/Supabase/Drive API yang dipasang. Pemilihan Drive melalui pemilih file tidak sama dengan sinkronisasi atau konfirmasi unggahan otomatis.
