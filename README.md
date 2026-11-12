# Catatan Warung

Aplikasi Android Flutter untuk utang pelanggan dan utang warung kepada pemasok. Bahasa Indonesia, satu HP, penyimpanan lokal SQLite, tanpa akun, backend, iklan, atau langganan.

**Status: alpha 0.1.0 untuk uji coba.** Implementasi tersedia; belum memenuhi seluruh gerbang rilis pada [PRD](PRD.md). Identitas dan versi Android HP ibu belum dikonfirmasi. Pengujian emulator tidak menggantikan uji HP ibu dan pendampingan keluarga.

## Menjalankan

- Flutter **3.47.8 stable**, Dart **3.13.7**, Java 17, Android SDK; minimum aplikasi Android 8/API 26.
- Versi dependency hasil resolusi ada di `pubspec.lock`. Simpan lockfile dalam version control.
- VS Code: buka folder proyek, pasang ekstensi Flutter, lalu jalankan **Developer: Reload Window**. Pengaturan `.vscode/settings.json` memilih SDK stable di `C:/src/flutter-ocs-pos-stable` untuk debugger dan terminal baru. Di komputer lain, sesuaikan path tersebut dengan SDK Flutter 3.47.8 setempat.
- Jalankan emulator **OCS POS Sprint1 (API 35)**, pilih perangkat Android tersebut di VS Code, lalu tekan **F5** menggunakan konfigurasi **Catatan Warung (Android)**. Emulator Pixel 9 Pro API 24 yang tersedia di komputer ini berada di bawah minimum aplikasi.
- Untuk CLI standar, buka terminal VS Code baru setelah reload, pastikan `flutter --version` menunjukkan **3.47.8 stable**, lalu jalankan `flutter pub get` dan `flutter run`. Terminal lama dapat masih memakai SDK dari PATH sebelumnya.
- Perintah Flutter yang dijalankan ekstensi VS Code diberi `--no-version-check` agar pemeriksaan pembaruan SDK tidak menahan startup lock. Versi proyek tetap ditentukan `.flutter-version`; opsi ini tidak melewati validasi kompatibilitas Android/Gradle.
- Skrip Windows menggunakan SDK stabil yang sudah tersedia di `C:/src/flutter-ocs-pos-stable`, tanpa mengganti Flutter global. Untuk komputer lain, atur `CATATAN_FLUTTER_SDK` ke SDK yang sesuai.

```powershell
$env:CATATAN_FLUTTER_SDK = 'C:/path/to/flutter-3.47.8'
powershell -File scripts/flutter.ps1 pub get
powershell -File scripts/flutter.ps1 run
```

## Verifikasi dan APK uji

```powershell
powershell -File scripts/flutter.ps1 analyze
powershell -File scripts/flutter.ps1 test
# Hanya emulator pengujian: tes berikut menulis kunci uji pada instalasi aplikasi.
powershell -File scripts/flutter.ps1 test integration_test/android_test.dart -d emulator-5554
# Bangun kembali entry point aplikasi biasa setelah tes integrasi.
powershell -File scripts/flutter.ps1 build apk --debug
```

APK uji berada di `build/app/outputs/flutter-apk/app-debug.apk`. Salinan tampilan biru-putih terbaru ada di `artifacts/catatan-warung-0.1.0-blue-ui.apk`; `artifacts/catatan-warung-0.1.0-alpha.apk` menyimpan build tampilan sebelumnya. Pasang pada HP percobaan terlebih dahulu. APK ini memakai penandatanganan debug dan bukan paket distribusi publik.

Untuk pembaruan alpha, bangun dengan keystore debug yang sama dan pasang sebagai pembaruan; jangan menghapus aplikasi untuk memperbaruinya. Perpindahan dari tanda tangan debug ke tanda tangan rilis dapat membutuhkan pemasangan ulang: verifikasi cadangan serta kartu kunci dahulu.

Build release sengaja memerlukan keystore tetap dan `android/key.properties`; contoh konfigurasi ada di `android/key.properties.example`. Jangan commit keystore, kata sandi, file cadangan nyata, atau kartu kunci. Tidak ada kredensial layanan cloud yang perlu disediakan.

## Fitur yang tersedia

- Orang dan kategori pelanggan/pemasok terpisah; nama, pembeda, pencarian, saran nama yang mengandung teks pencarian, peringatan nama sama.
- Utang baru, saldo awal, pembayaran sebagian/lunas, riwayat, koreksi terlacak, pembatalan beralasan, arsip per kategori, hapus nama tanpa riwayat.
- Validasi saldo historis, transaksi SQLite atomik, pencegahan simpan ganda, dan pemulihan yang mengganti seluruh buku dengan salinan pengaman lokal.
- Cadangan AES-256-GCM, kartu kunci acak yang diverifikasi keluarga, status snapshot/revisi, dan pengingat tujuh hari di beranda.
- Pemilih file Android, penyimpanan kunci melalui Android Keystore, dan aturan Android Auto Backup yang hanya menyertakan database buku.

Tidak ada backend, sinkronisasi otomatis, Google Drive API, Excel/CSV, WhatsApp, jatuh tempo, notifikasi penagihan, atau PIN aplikasi. Drive dapat dipilih melalui pemilih file jika provider tersedia; aplikasi tidak mengonfirmasi keberhasilan unggahan cloud.

## Dokumen

Pratinjau tampilan biru-putih tersedia di [beranda](artifacts/ui-redesign/home.png), [daftar pelanggan](artifacts/ui-redesign/customers.png), dan [riwayat](artifacts/ui-redesign/ledger.png). Angka dan nama pada pratinjau adalah data contoh. Untuk memperbaruinya tanpa membuka database aplikasi, jalankan `powershell -File scripts/flutter.ps1 test tool/preview_screens.dart --no-pub`. Setelah perubahan tema, gunakan Hot Restart atau jalankan ulang F5.

- [PRD final](PRD.md) dan [lampiran evaluasi cloud](PRD-lampiran-backup-cloud.md).
- [Panduan ibu dan keluarga](docs/PANDUAN.md).
- [Arsitektur dan kontrak format cadangan](docs/ARSITEKTUR.md).
- [Hasil pengujian dan gerbang rilis yang tersisa](docs/VALIDASI.md).
- [Konteks produk](PRODUCT.md) dan [arah tampilan](DESIGN.md).
