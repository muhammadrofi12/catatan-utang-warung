# Lampiran — Evaluasi cloud untuk v1.1

Lampiran non-normatif untuk [PRD Final v1.0](PRD.md), diperbarui 11 November 2026. Isinya bahan evaluasi v1.1; tidak menambah cakupan atau persyaratan rilis v1. Jika ada perbedaan, PRD utama menjadi acuan.

Keputusan v1 sudah final: tanpa akun/backend, dengan cadangan file manual terenkripsi, kunci acak yang disimpan keluarga di luar HP, pengingat tujuh hari, dan Android Auto Backup sebagai lapisan tambahan. Supabase, sinkronisasi, dan PIN aplikasi hanya dipertimbangkan pada perubahan versi berikutnya. Harga, kuota, dan kebijakan layanan pada lampiran ini adalah hasil pemeriksaan 11 November 2026 dan harus diverifikasi lagi sebelum memilih layanan untuk v1.1.

---

### Batas biaya dan kandidat Supabase Free

Kebutuhan: penggunaan tanpa biaya layanan wajib, termasuk biaya backend yang ditanggung pembuat aplikasi. Backend tidak selalu berarti harus menyewa VPS: layanan terkelola memiliki paket gratis dengan batas pemakaian. Paket gratis tidak dianggap sebagai janji kapasitas atau ketersediaan tanpa batas selamanya.

Kandidat evaluasi (v1.1) adalah **Flutter + SQLite lokal + Supabase Free**, dengan alur yang diusulkan:

1. Keluarga membantu menghubungkan akun yang dapat dipakai kembali untuk pemulihan. Login Google adalah kandidat; akun anonim saja tidak memenuhi kebutuhan instal ulang.
2. Transaksi disimpan terlebih dahulu di SQLite bersama antrean pengiriman yang persisten.
3. Saat internet dan layanan tersedia, aplikasi mengirim perubahan ke database Supabase. Ini perlu dibuat di aplikasi; pemasangan SDK tidak otomatis menyinkronkan SQLite.
4. Status “Terkirim ke cloud” hanya tampil setelah server mengonfirmasi penyimpanan. Operasi yang gagal tetap antre dan tidak dikirim ganda ketika dicoba ulang.
5. Setelah instal ulang, masuk ke akun yang sama lalu unduh catatan yang berhasil terkirim. Pemulihan harus memverifikasi kelengkapan data dan saldo sebelum dipakai.

Data disimpan pada database Supabase, bukan Google Drive dan bukan Excel. Supabase mendukung login Google. [Supabase Google sign-in](https://supabase.com/docs/guides/auth/social-sign-in/auth-google).

Pada pemeriksaan 11 November 2026, paket Free berharga $0/bulan dengan database 500 MB, file storage 1 GB, egress 5 GB, dan maksimal dua proyek aktif. Proyek gratis dijeda setelah satu minggu tidak aktif. Kuota tersebut milik proyek/organisasi sesuai metriknya, bukan jatah terpisah setiap warung. [Supabase Pricing](https://supabase.com/pricing).

Untuk satu warung dengan transaksi teks/angka, paket ini layak dievaluasi. Kecukupan kapasitas harus diukur dari jumlah catatan, indeks, riwayat koreksi, dan pola pengiriman; tidak menjanjikan jumlah transaksi tanpa pengukuran.

Persyaratan bila Supabase dipilih:

- Tetap memakai paket Free, tanpa upgrade atau add-on berbayar. Biaya internet/perangkat bukan biaya layanan aplikasi; distribusi publik melalui toko aplikasi perlu dievaluasi terpisah.
- Data hanya dapat diakses pemiliknya melalui aturan otorisasi server/RLS. Kunci administratif tidak boleh berada dalam aplikasi Flutter.
- Jika layanan dijeda, kuota tercapai, sesi login berakhir, atau jaringan gagal, pencatatan lokal tetap berjalan dan status cloud menjelaskan bahwa pengiriman tertunda.
- Pengelola memantau kuota serta pemberitahuan proyek. Layanan gratis tetap memerlukan pemeliharaan; jika proyek dijeda, pemulihan cloud perlu menunggu proyek tersedia kembali.
- Gunakan ID operasi stabil, validasi, dan penulisan atomik agar koreksi serta percobaan ulang tidak mengubah saldo dua kali.
- Pemulihan file lama tidak boleh langsung menimpa data cloud yang lebih baru. Prosedur rekonsiliasi/pemilihan buku harus dirancang sebelum fitur cloud dirilis.
- Tetap satu HP pencatat aktif. Perpindahan HP harus mempunyai prosedur agar antrean dari HP lama tidak menimpa catatan perangkat pengganti.
- Akun dan antrean lokal harus terikat pada buku yang tepat; mengganti akun tidak boleh mengunggah catatan ke pemilik lain.

Salinan data aktif di Supabase membantu saat HP hilang/uninstall, tetapi bukan backup historis yang melindungi dari semua kesalahan penghapusan. Backup harian terkelola tidak termasuk paket Free; dokumentasi menyarankan ekspor berkala dan cadangan terpisah untuk proyek gratis. Fitur ekspor cadangan aplikasi tetap diperlukan. [Supabase Database Backups](https://supabase.com/docs/guides/platform/backups).

Sebelum memilih final, uji antrean offline, putus jaringan saat mengirim, instal ulang, akun salah, layanan tidak tersedia, dan pemulihan tanpa menggandakan transaksi. Belum ada proyek Supabase dibuat atau integrasi diimplementasikan.

### Android Auto Backup: rujukan keputusan v1

Jika perangkat sasaran Android dengan layanan backup Google, Android Auto Backup dapat mencadangkan data aplikasi, termasuk database, ke akun Google perangkat. Batasnya 25 MB per aplikasi. Ini mekanisme sistem Android, berbeda dari pemanggilan Drive API oleh aplikasi. [Android Auto Backup](https://developer.android.com/identity/data/autobackup).

Backup memerlukan pengaturan aktif dan kondisi jaringan/perangkat yang sesuai; jadwalnya bukan setiap transaksi. Pemulihan dapat berlangsung saat pemasangan aplikasi jika cadangan yang cocok tersedia. Karena itu, fitur ini tidak menjamin semua catatan kembali setelah uninstall. [Android backup overview](https://developer.android.com/identity/data/backup).

Aturan data yang disertakan/dikecualikan, kunci lokal, batas ukuran, status cadangan, serta pengujian uninstall/pemulihan mengikuti bagian 9 dan 11 PRD utama. Lampiran ini tidak menyediakan opsi enkripsi database atau alur kunci alternatif untuk v1.

Untuk evaluasi v1.1, cadangan segera setelah transaksi saat internet tersedia memerlukan layanan cloud aplikasi, percobaan ulang, versi cadangan, dan status yang terverifikasi. Tampilkan “Tersimpan di HP — menunggu cadangan” sampai server mengonfirmasi. Saat instal ulang, akun yang sama dapat digunakan untuk mengambil cadangan yang tersedia. Pemilihan provider dan autentikasi v1.1 belum dilakukan; pencatatan dari banyak HP tidak otomatis masuk cakupan.

### Integrasi Google Drive API langsung: mekanisme belum dikunci

Dokumentasi Drive menjelaskan `appDataFolder` untuk data khusus aplikasi. Namun, kebijakan Google Workspace yang diperiksa pada 11 November 2026 mencantumkan backup konten pengguna/aplikasi dari aplikasi pengembang ke Drive sebagai penggunaan Drive scopes yang tidak diizinkan. Karena itu, tersedianya API tidak cukup untuk menjanjikan fitur backup otomatis ini. Integrasi langsung memerlukan kejelasan kebijakan sebelum dipilih. [Drive app data](https://developers.google.com/workspace/drive/api/guides/appdata), [Google Workspace user data and developer policy](https://developers.google.com/workspace/workspace-api-user-data-developer-policy).

Pada v1, alurnya adalah ekspor file yang dikendalikan pengguna ke lokasi pilihan melalui pemilih dokumen Android. Kemunculan Drive, perilaku unggah, dan kemampuan membuka kembali file perlu diuji pada perangkat; tidak dijanjikan selalu tersedia atau langsung selesai di cloud. Jalur ini tidak dianggap konfirmasi kelayakan integrasi Drive API langsung pada v1.1. [Android Storage Access Framework](https://developer.android.com/training/data-storage/shared/documents-files).

Jika backup otomatis menjadi syarat utama, evaluasi layanan penyimpanan yang secara eksplisit mendukung kebutuhan tersebut. Keputusan itu mencakup biaya operasional, autentikasi, privasi, dan pemulihan akun. Login Google sendiri tidak berarti data otomatis tersimpan di Google Drive.
