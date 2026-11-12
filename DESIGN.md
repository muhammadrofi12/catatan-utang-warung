# Design System — Catatan Warung

Dokumen ini mendefinisikan sistem desain antarmuka (Design System) untuk aplikasi **Catatan Warung**. Sistem ini dirancang spesifik untuk pengguna usia 50+ (pemilik warung tradisional) dengan prinsip kesederhanaan, keterbacaan tinggi di berbagai kondisi cahaya, dan kemudahan pengoperasian pada perangkat Android layar sentuh.

---

## 1. Prinsip Desain Utama

1. **Keterbacaan Ekstrem (Legibility First)**
   - Ukuran teks lebih besar dari aplikasi umum (minimal 18sp untuk teks isi, 30sp untuk angka saldo).
   - Kontras tinggi yang memenuhi standar WCAG 2.2 AA/AAA agar tetap terbaca jelas di bawah terik matahari atau pencahayaan warung.
   - Angka dan nominal selalu menggunakan format Rupiah dengan pemisah ribuan titik (`Rp25.000`), bukan format ringkas atau desimal.

2. **Area Sentuh Ramah Lansia (Generous Touch Targets)**
   - Tombol aksi utama memiliki tinggi minimal **56dp** dengan bentuk pil (*stadium border*).
   - Seluruh elemen interaktif lainnya (ikon, chip, baris daftar) memiliki area sentuh minimal **48 × 48dp**.
   - Jarak antar-elemen sentuh cukup longgar untuk meminimalkan salah tekan (*fat-finger errors*).

3. **Tanpa Gestur Tersembunyi (No Hidden Gestures)**
   - Tidak menggunakan *swipe-to-delete*, *long press*, atau menu tersembunyi (titik tiga) untuk fungsi harian.
   - Semua tindakan penting ditampilkan secara eksplisit dalam bentuk tombol dengan label teks yang jelas.

4. **Satu Tujuan per Layar (Cognitive Simplicity)**
   - Setiap formulir hanya fokus pada satu transaksi (misal: tambah utang atau catat bayar).
   - Ringkasan perubahan saldo ditampilkan langsung di formulir sebelum pengguna menekan tombol simpan, menghindari popup konfirmasi yang membingungkan.

5. **Umpan Balik Konkret & Terbimbing**
   - Pesan keberhasilan dan kesalahan menggunakan bahasa sehari-hari yang menyebutkan konteks nyata.
   - Jika terjadi kendala (misal: saldo menjadi negatif), aplikasi menyediakan petunjuk atau tautan langsung ke transaksi terkait, bukan sekadar kode galat.

---

## 2. Fondasi Visual & Token Desain

### 2.1 Palet Warna (Color Palette)

Aplikasi dibangun di atas Material 3 dengan warna dominan biru royal yang bersih dan tenang, dipadukan dengan aksen fungsional untuk kategori dan status pembayaran.

#### Light Mode (Mode Standar Warung)

| Token / Peran | Kode Hex | Penggunaan |
| --- | --- | --- |
| **Primary** | `#245FB0` | Tombol utama, filter aktif, fokus input |
| **On Primary** | `#FFFFFF` | Teks di atas warna primary |
| **Primary Container** | `#EAF2FD` | Latar panel saldo & ikon pelanggan |
| **On Primary Container** | `#19477F` | Teks & ikon di atas primary container |
| **Secondary Container** | `#F0F5FC` | Latar kartu informasi / notice biasa |
| **On Secondary Container** | `#304B6C` | Teks informasi umum |
| **Tertiary** | `#805900` | Aksen kategori pemasok/toko |
| **Tertiary Container** | `#FFF4DD` | Latar ikon & kartu pemasok (amber lembut) |
| **On Tertiary Container** | `#664600` | Ikon & teks pemasok |
| **Surface** | `#FFFFFF` | Latar belakang lembar konten dan kartu |
| **Surface Container Low** | `#F5F8FD` | Latar belakang isian formulir (input field) |
| **On Surface (Ink)** | `#17263B` | Teks utama, judul, nominal uang |
| **On Surface Variant** | `#53647A` | Teks sekunder, label pembantu, tanggal |
| **Outline Variant** | `#DEE6F0` | Garis pemisah (*divider*), border kartu & input |
| **Header (Custom)** | `#2865B6` | Latar app bar & header layar beranda |
| **Payment (Custom)** | `#176440` | Teks & ikon transaksi pembayaran/lunas (hijau) |
| **Payment Surface** | `#E9F6EF` | Latar badge pembayaran/lunas |

#### Dark Mode

| Token / Peran | Kode Hex | Penggunaan |
| --- | --- | --- |
| **Primary** | `#A8CBFF` | Tombol utama dan aksen aktif |
| **On Primary** | `#10335E` | Teks di atas primary |
| **Primary Container** | `#203B5D` | Latar panel pelanggan |
| **Surface** | `#111B29` | Latar utama aplikasi |
| **Surface Container Low** | `#172436` | Latar input formulir |
| **On Surface** | `#EDF2F8` | Teks utama |
| **Header (Custom)** | `#193D70` | Latar header layar beranda |
| **Payment (Custom)** | `#91DDB5` | Aksen transaksi pembayaran (hijau terang) |

> **Catatan Kontras:** Warna teks tidak pernah menjadi satu-satunya indikator jenis transaksi. Nominal pembayaran selalu disertai label kata seperti *"Pelanggan bayar"* atau ikon pendamping.

---

### 2.2 Tipografi (Typography)

Menggunakan font sistem **Roboto** bawaan Android untuk konsistensi rendering, kecepatan loading, dan keandalan tata letak.

| Skala (Text Style) | Ukuran (Size) | Bobot (Weight) | Tinggi Baris (Height) | Penggunaan |
| --- | --- | --- | --- | --- |
| **Headline Medium** | `30sp` | Bold (700) | 1.25 | Nominal sisa saldo utama |
| **Title Large** | `24sp` | Bold (700) | 1.25 | Judul halaman & nama orang di detail |
| **Title Medium** | `20sp` | Semi-bold (600) | 1.3 | Judul kartu kategori & section header |
| **Body Large** | `20sp` | Regular (400) | 1.4 | Teks input form & pilihan utama |
| **Body Medium** | `18sp` | Regular (400) | 1.4 | Teks riwayat, catatan keterangan, deskripsi |
| **Label Large** | `18sp` | Semi-bold (600) | 1.0 | Teks tombol aksi, chip, badge status |

#### Aksesibilitas Skala Huruf
- Tata letak mendukung pembesaran teks sistem hingga **200%** (*Large Text / Font Scaling Android*).
- Nominal uang dan teks panjang dibungkus (*soft-wrap*), tidak pernah dipotong secara kaku (*ellipsis* tanpa akses baca) atau mengecil otomatis ke ukuran tak terbaca.

---

### 2.3 Ukuran Sentuh & Tata Letak (Spacing & Layout)

- **Skala Spasi Modular:** `4dp`, `8dp`, `12dp`, `16dp`, `20dp`, `24dp`, `32dp`.
- **Batas Maksimum Layar (`maxWidth`):** `720dp`. Pada tablet atau orientasi horizontal, konten tetap berada di kolom tengah yang nyaman dijangkau tangan (*single-column layout*).
- **SafeArea:** Diterapkan di seluruh layar agar konten tidak terpotong lekukan layar (*notch*) atau tertutup navigasi sistem/keyboard.

---

### 2.4 Bentuk & Elevasi (Shape & Elevation)

- **Tombol Utama:** Bentuk pil penuh (`StadiumBorder`), memberikan kesan ramah dan mudah dikenali sebagai elemen yang dapat ditekan.
- **Input Fields:** Sudut tumpul melengkung `16dp` dengan latar belakang lembut (`#F5F8FD`) dan border garis tipis saat pasif, menebal 2dp saat aktif.
- **Lembar Konten (Content Sheet):** Sudut atas melengkung `32dp` di layar Beranda yang memisahkan area header biru dengan lembar kerja putih.
- **Kartu & Kotak Pesan:** Sudut melengkung `12dp` – `16dp`.
- **Elevasi Visual:** Mayoritas flat (elevasi 0dp) dengan pembeda garis (*outline variant*), menghindari bayangan buram yang sering menurunkan kontras pada layar ponsel murah.

---

## 3. Komponen Inti (Component Library)

### 3.1 `ActionButton`
Tombol aksi lebar penuh yang digunakan untuk navigasi dan penyimpanan.
- **Varian Utama:** `FilledButton`, tinggi minimal 56dp, teks 18sp semi-bold, warna latar `Primary`.
- **Varian Sekunder:** `OutlinedButton`, tinggi minimal 56dp, dengan border garis `OutlineVariant`.
- **Ikon Pendamping:** Ikon berukuran 24dp diletakkan di sisi kiri teks dengan jarak 10dp, dikecualikan dari screen reader (`ExcludeSemantics`) karena teks sudah mendeskripsikan tindakan.

### 3.2 `MoneyText`
Komponen penampil nominal rupiah yang konsisten.
- Mengonversi integer ke string Rupiah berformat titik (`Rp125.000`).
- Mendukung varian besar (`HeadlineMedium` 30sp) dan standar (`TitleMedium` 20sp).
- Selalu mengaktifkan `softWrap: true` agar angka besar tetap utuh meski teks sistem diperbesar.

### 3.3 `AmountFormatter`
Input formatter otomatis untuk kolom pengisian uang:
- Hanya menerima angka `0-9`.
- Otomatis memformat titik ribuan saat pengguna mengetik (misal: mengetik `50000` langsung tampil `50.000`).
- Membatasi panjang maksimal 9 digit (maksimum transaksi Rp999.999.999).
- Tidak mengharuskan pengguna mengetik "Rp" secara manual.

### 3.4 `IconBadge`
Avatar sirkular berdiameter **48 × 48dp** dengan ikon 25dp di tengahnya.
- **Pelanggan:** Ikon orang dengan latar `PrimaryContainer` (`#EAF2FD`).
- **Pemasok:** Ikon toko dengan latar `TertiaryContainer` (`#FFF4DD`).
- **Pembayaran:** Ikon centang/bayar dengan latar `PaymentSurface` (`#E9F6EF`).

### 3.5 `Notice`
Banner pemberitahuan status, peringatan, atau error.
- Latar container bersudut 12dp.
- Dilengkapi `Semantics(liveRegion: true)` agar perubahan status otomatis diumumkan oleh TalkBack.
- Menyediakan slot tombol aksi langsung di dalam banner jika diperlukan pemulihan kendala.

### 3.6 `DirtyGuard`
Komponen pelindung isian formulir:
- Menangkap gestur atau tombol *Back* sistem Android.
- Menampilkan dialog konfirmasi ramah jika ada perubahan isian yang belum disimpan, mencegah data ketikan hilang karena ketidaksengajaan.

---

## 4. Pola Layar (Screen Patterns)

### 4.1 Layar Beranda (Home Screen)
- **Header Atas:** Warna biru royal `#2865B6` berisi nama warung dan identitas buku.
- **Lembar Putih (Sheet 32dp):** Menampung dua tombol/kartu kategori besar:
  1. *Pelanggan belum bayar* (menampilkan total sisa piutang).
  2. *Warung belum bayar* (menampilkan total sisa utang ke pemasok).
- **Status Cadangan:** Kotak ringkas di bagian bawah lembar yang jujur mengabarkan tanggal cadangan terakhir tanpa mengganggu alur transaksi.

### 4.2 Layar Daftar Orang (People List)
- Kolom pencarian instan di bagian atas.
- Filter pill sederhana: **Belum lunas** (default) dan **Semua**.
- Setiap baris menampilkan nama jelas, pembeda tempat/lokasi (opsional), sisa utang dengan format tebal, dan `IconBadge`.

### 4.3 Layar Detail Orang (Ledger Detail)
- **Panel Saldo Teratas:** Kartu berwarna kontras menampilkan sisa nominal belum dibayar dengan angka 30sp.
- **Dua Tombol Aksi Langsung:**
  - Tombol 1: *Tambah utang pelanggan* (atau *Tambah utang warung*).
  - Tombol 2: *Pelanggan bayar* (atau *Warung bayar*).
- **Timeline Riwayat:** Daftar riwayat terurut dari yang terbaru, menampilkan tanggal, jenis, nominal, keterangan, serta penanda status koreksi jika transaksi pernah diperbaiki.

### 4.4 Layar Formulir Transaksi (Entry Form)
- Menampilkan nama orang yang bersangkutan secara permanen di bagian atas formulir.
- Input nominal uang besar dengan keypad numerik otomatis.
- Ringkasan langsung: menampilkan saldo saat ini, perubahan nominal, dan estimasi sisa saldo baru sebelum tombol "Simpan" ditekan.
- Tombol simpan dinonaktifkan saat proses tulis database berlangsung untuk mencegah penekanan ganda (*double-tap prevention*).

---

## 5. Pedoman Aksesibilitas & Pengujian (Accessibility & QA)

1. **Uji Skala Teks 200%:** Seluruh layar wajib diuji dengan setelan *Font Size* dan *Display Size* maksimum di Android. Tidak boleh ada teks yang terpotong atau tata letak yang bertumpuk (*render overflow*).
2. **Uji TalkBack:** Setiap tombol harus memiliki label yang dapat dibaca jelas oleh pembaca layar, mencakup nama aksi dan konteks (contoh: *"Tambah utang untuk Bu Siti"*).
3. **Pencahayaan Layar:** Kontras diuji pada rentang kecerahan rendah hingga tinggi untuk menjamin kenyamanan pemilik warung di lokasi toko yang bervariasi.
4. **Verifikasi Prototipe:** Tangkapan layar pratinjau yang dihasilkan melalui script otomasi pengujian (`tool/preview_screens.dart`) menjadi acuan visual implementasi komponen.
