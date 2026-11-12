# PRD — Catatan Warung

Status: **Final v1.0 — acuan implementasi produk.**  
Tanggal: 11 November 2026.  
Nama produk: **Catatan Warung**.  
Perubahan berikutnya harus mencatat versi, alasan, dan dampak cakupan. Final berarti keputusan kebutuhan v1 telah ditetapkan; bukan pernyataan bahwa aplikasi sudah dibangun atau lulus uji.

## 1. Ringkasan produk

Catatan Warung adalah aplikasi Flutter untuk mencatat utang pelanggan kepada warung dan utang warung kepada pemasok. Aplikasi mengutamakan pengguna usia 50+ yang belum terbiasa memakai aplikasi: tulisan mudah dibaca, langkah sedikit, bahasa sehari-hari, dan catatan tetap tersedia tanpa internet.

Masalah awal: pemilik warung lupa mencatat atau kesulitan mengingat transaksi sehingga terjadi perbedaan ingatan dengan pelanggan/tetangga. Produk membantu mencatat saat transaksi berlangsung dan memperlihatkan asal saldo melalui riwayat yang mudah dipahami.

Aplikasi tidak bisa mengetahui transaksi yang belum dimasukkan. Keberhasilannya juga bergantung pada kebiasaan mencatat sebelum pelanggan pergi. Karena itu, kecepatan dan kemudahan pencatatan lebih penting daripada banyaknya fitur.

## 2. Keputusan produk v1

### Sasaran penggunaan

| Hal | Keputusan |
| --- | --- |
| Teknologi aplikasi | Flutter |
| Pengguna utama | Ibu/pemilik warung usia 50+, kurang terbiasa dengan teknologi |
| Jenis pencatatan | Utang pelanggan dan utang warung ke pemasok |
| Perangkat operasional | Satu HP; keluarga membantu pengaturan |
| Isi transaksi | Total uang wajib; keterangan barang opsional |
| Karakter produk | Simpel dan sederhana |
| Biaya penggunaan | Gratis untuk pengguna dan tanpa biaya layanan backend wajib bagi pembuat; tidak mengaktifkan paket/add-on berbayar |

### Batas implementasi

| Hal | Keputusan v1 | Alasan |
| --- | --- | --- |
| Platform | Android 8.0/API 26 atau lebih baru, orientasi utama potret | Satu platform untuk penggunaan pertama dan pengujian fisik |
| Penyimpanan utama | Database SQLite di penyimpanan internal aplikasi | Transaksi tetap dapat dicatat dan dibaca tanpa internet |
| Akun aplikasi | Tidak ada login atau akun aplikasi | Pencatatan tersedia sejak penggunaan pertama |
| Cadangan | File manual terenkripsi, pengingat beranda tujuh hari, dan Android Auto Backup sebagai lapisan tambahan | Keluarga membantu menyimpan salinan di luar HP |
| Proteksi file cadangan | Kunci acak 256-bit yang dibuat aplikasi dan disimpan keluarga di luar HP | Ibu tidak mengingat kata sandi untuk transaksi harian |
| Cloud aplikasi | Supabase, login, dan antrean sinkronisasi **di luar v1** | Evaluasi v1.1 tersedia di [lampiran](PRD-lampiran-backup-cloud.md) |
| Ekspor laporan | Excel/CSV dan ringkasan WhatsApp di luar v1 | v1 hanya mengekspor file cadangan lengkap |
| Penguncian | Tidak ada PIN aplikasi di v1; gunakan kunci layar perangkat | F15 dipindahkan ke v1.1 bersama rancangan pemulihan akses |
| Batas nominal | Rp1–Rp999.999.999 per transaksi; batas akumulasi dijelaskan di bagian 7 | Mencegah input tidak valid tanpa menyamakan batas transaksi dan saldo |
| Distribusi awal | APK bertanda tangan untuk penggunaan keluarga; tidak memerlukan publikasi toko aplikasi | Tidak menambah biaya layanan wajib; kunci penandatanganan harus disimpan untuk pembaruan |

Perangkat pengguna disebut sebagai Samsung Galaxy “S12”; nama model/nomor model dan versi Android belum diverifikasi. Platform Android ditetapkan, tetapi kompatibilitas HP tersebut belum boleh diklaim. Verifikasi melalui Pengaturan → Tentang ponsel dilakukan sebelum pengujian penerimaan. Tidak perlu mengumpulkan IMEI atau nomor seri.

Tidak ada biaya backend atau langganan aplikasi pada v1. Biaya perangkat dan koneksi yang sudah digunakan keluarga berada di luar biaya layanan aplikasi. Aplikasi tidak memuat iklan, pembelian dalam aplikasi, atau layanan uji coba berbayar.

## 3. Tujuan dan batasan versi pertama

### Tujuan

1. Ibu dapat mencatat tambahan utang dengan sedikit langkah saat melayani pembeli.
2. Ibu dapat mencatat cicilan atau pelunasan tanpa menghitung sisa secara manual.
3. Pelanggan dan pemasok memiliki riwayat terpisah yang menjelaskan saldo saat ini.
4. Data tersimpan setelah aplikasi ditutup atau HP dimulai ulang.
5. Keluarga dapat membantu membuat cadangan dan memulihkan data tanpa mengubah catatan harian.

### Di luar versi pertama

- Kasir lengkap, inventaris, barcode, katalog/harga barang, dan laporan laba rugi.
- Pencatatan penjualan tunai yang tidak berkaitan dengan utang.
- Sinkronisasi dan pencatatan bersamaan dari beberapa HP.
- Pembayaran digital, integrasi bank, dan konfirmasi transfer otomatis.
- Bunga, denda, kredit pelanggan, pembayaran berlebih, dan perhitungan angsuran berjadwal.
- Pengingat/tagihan otomatis kepada pelanggan, jatuh tempo pemasok, dan pengingat pembayaran pribadi. Pengingat cadangan di beranda tetap termasuk v1.
- Berbagi ringkasan melalui WhatsApp/lembar berbagi Android.
- Ekspor Excel/CSV.
- Login akun dan replikasi otomatis ke cloud (kandidat v1.1; lihat [lampiran](PRD-lampiran-backup-cloud.md)).
- Input suara, OCR foto buku, dan AI yang menyimpulkan transaksi.
- Impor bebas dari Excel dan penggabungan dua database.
- Penghapusan piutang/utang sebagai kerugian; ini memerlukan jenis transaksi tersendiri di tahap berikutnya.
- PIN aplikasi, biometrik aplikasi, dan pemulihan PIN (F15, kandidat v1.1).
- Banyak warung dalam satu instalasi, pemindaian QR/kamera, foto bukti, dan impor kontak.

## 4. Pengguna dan bahasa aplikasi

**Pengguna utama:** pemilik warung yang ingin segera melanjutkan melayani pelanggan. Tidak perlu memahami istilah akuntansi.

**Pendamping:** anggota keluarga yang menyiapkan aplikasi, memasukkan catatan awal bersama ibu, dan membantu pencadangan/pemulihan. Pada versi pertama, pendamping menggunakan HP yang sama; belum ada akun atau peran jarak jauh.

| Konsep | Teks dalam aplikasi |
| --- | --- |
| Piutang pelanggan | Pelanggan belum bayar |
| Utang ke pemasok | Warung belum bayar |
| Menambah piutang | Tambah utang pelanggan |
| Menerima pembayaran | Pelanggan bayar |
| Menambah utang warung | Tambah utang warung |
| Membayar pemasok | Warung bayar |
| Outstanding balance | Sisa belum dibayar |
| Opening balance | Utang sebelumnya |
| Audit/correction | Riwayat perbaikan |
| Backup/restore | Cadangkan catatan / Pulihkan catatan |

Hindari tombol ambigu seperti hanya “Tambah” atau “Bayar” tanpa konteks orang dan arah pembayaran. Label pada tabel menjadi acuan prototipe; perubahan berdasarkan uji pengguna dicatat tanpa mengubah arti transaksi.

## 5. Susunan layar dan alur utama

### Beranda

- Dua pilihan besar: **Pelanggan belum bayar** dan **Warung belum bayar**.
- Masing-masing memperlihatkan total sisa dalam kategori tersebut, secara terpisah.
- Akses sekunder ke pengaturan dan cadangan.
- Pengingat cadangan menurut F16; tidak menampilkan nama/nominal pelanggan pada notifikasi sistem.
- Tidak memerlukan grafik atau istilah pemasukan/pengeluaran untuk memulai.

### Daftar orang

- Nama/panggilan, pembeda opsional seperti “sebelah masjid”, dan sisa belum dibayar.
- Pencarian nama, tombol “Tambah pelanggan” atau “Tambah pemasok”.
- Filter “Belum lunas”, “Semua”, dan “Arsip”. “Semua” mencakup seluruh catatan aktif termasuk lunas; arsip diakses melalui filter tersendiri.
- Urutan awal berdasarkan aktivitas pencatatan terakhir, lalu nama dan ID sebagai pembeda stabil. Daftar tidak berpindah posisi selama pengguna sedang memilih.
- Pencarian mengabaikan kapital dan spasi di awal/akhir. Nama sama tetap boleh dipakai dengan peringatan dan pembeda. Saran kemiripan ejaan mengikuti F02.

### Detail orang

- Nama dan kategori selalu terlihat jelas.
- Sisa belum dibayar ditampilkan besar.
- Dua tindakan utama sesuai kategori: tambah utang dan catat pembayaran.
- Riwayat tanggal, jenis transaksi, nominal, keterangan, dan sisa setelah transaksi.
- Tindakan sekunder: perbaiki/batalkan transaksi, ubah profil, arsipkan jika saldo nol.

### Alur A — Pelanggan berutang

1. Ibu membuka “Pelanggan belum bayar” dan memilih Bu Siti.
2. Menekan “Tambah utang pelanggan”.
3. Mengisi Rp25.000; keterangan “beras dan telur” boleh diisi atau dilewati.
4. Ringkasan memperlihatkan nama, nominal, dan sisa sesudah transaksi sebelum tombol “Simpan”.
5. Setelah penulisan database berhasil, tampil “Tersimpan” dan saldo baru.

Tidak perlu dialog konfirmasi tambahan untuk setiap transaksi biasa; ringkasan berada di formulir yang sama. Target jumlah interaksi dan waktu diuji pada prototipe, bukan diasumsikan sudah tercapai.

### Alur B — Pelanggan membayar sebagian atau lunas

1. Buka Bu Siti → “Pelanggan bayar”.
2. Masukkan Rp10.000, atau gunakan “Isi sejumlah sisa” untuk pelunasan.
3. Tinjau jumlah dan simpan. Sisa dari Rp25.000 menjadi Rp15.000.
4. Pembayaran Rp15.000 berikutnya menghasilkan sisa Rp0 dan label “Lunas”.

Tombol pengisi nominal tidak langsung menyimpan pembayaran. Jika sisa melebihi batas per transaksi, tombol pengisian pelunasan tidak aktif dan formulir menjelaskan pencatatan pembayaran bertahap sesuai bagian 7.

### Alur C — Warung berutang kepada pemasok

1. Buka “Warung belum bayar” → pilih Toko Makmur.
2. “Tambah utang warung” Rp200.000, keterangan opsional “stok minuman”.
3. Saat membayar Rp50.000, gunakan “Warung bayar”.
4. Sisa ke Toko Makmur menjadi Rp150.000; saldo pelanggan tidak berubah.

### Alur D — Memindahkan buku lama

1. Keluarga dan ibu membuat nama pelanggan/pemasok.
2. Masukkan “Utang sebelumnya” beserta tanggal saldo tersebut berlaku. Bila tanggal asal tidak diketahui, gunakan tanggal mulai memakai aplikasi sebagai tanggal batas, tanpa mengklaim itu tanggal pembelian lama.
3. Jika rinciannya tidak tersedia, tampilkan sebagai saldo awal tanpa membuat transaksi barang fiktif.
4. Transaksi baru dicatat sejak batas awal tersebut agar tidak dihitung dua kali.

Saldo awal opsional dan hanya dapat ditambahkan selama belum ada riwayat transaksi pada kategori tersebut. Setelah ada riwayat, saldo awal yang sudah ada diperbaiki melalui koreksi; tidak boleh ditambah kedua kali. Tanpa saldo awal, tidak dibuat transaksi Rp0 dan tanggal batas kosong. Jika pernah ada saldo awal, tanggal batas tetap disimpan meskipun saldo awal dibatalkan, untuk menandai awal buku dan menjaga urutan riwayat. Transaksi biasa sebelum tanggal batas ditolak; tanggal batas dapat dikoreksi secara terlacak hanya jika tidak melewati transaksi biasa yang paling awal.

### Alur E — Memperbaiki salah catat

1. Buka transaksi → “Perbaiki catatan”.
2. Tampilkan nilai lama, nilai pengganti, dan pengaruh ke saldo. Alasan wajib dipilih: “Salah ketik nominal”, “Salah pilih orang”, “Salah tanggal”, “Salah jenis catatan”, “Tercatat dua kali”, atau “Lainnya”. Keterangan bebas selalu opsional, termasuk untuk “Lainnya”.
3. Simpan perbaikan sebagai pembatalan nilai lama dan pencatatan pengganti dalam satu transaksi database.
4. Catatan asal tetap dapat diperiksa dan diberi tanda “Diperbaiki”.

Untuk salah pilih orang, pembatalan pada orang lama dan pencatatan pada orang baru juga harus atomik. Koreksi lintas pelanggan/pemasok tidak tersedia; pengguna membatalkan pada kategori lama lalu membuat catatan baru pada kategori yang benar. Jika perubahan membuat saldo negatif, tolak tanpa mengubah data dan sediakan tombol “Lihat pembayaran terkait”. Tombol ini membuka riwayat pembayaran pada rentang yang menyebabkan saldo negatif, tanpa mengklaim adanya alokasi pembayaran per utang.

Layar koreksi menjelaskan bila pembayaran sah perlu dibatalkan sementara, transaksi utang diperbaiki, lalu pembayaran dicatat ulang dengan nominal/tanggal yang benar. Tidak ada pembatalan berantai otomatis. Semua langkah meninggalkan riwayat dan kondisi saldo tetap diperiksa setelah setiap langkah.

### Penggunaan pertama

1. Buka langsung beranda kosong dengan tindakan “Tambah pelanggan pertama” dan pilihan pemasok; tidak ada login atau pengenalan wajib berhalaman-halaman.
2. Nama buku bawaan “Warung saya” dapat diubah keluarga di pengaturan.
3. Tersedia “Pulihkan catatan” untuk pengguna yang sudah memiliki file cadangan.
4. Keluarga menyiapkan kunci cadangan saat backup pertama; langkah ini tidak memblokir pencatatan biasa.
5. Nama wajib 1–80 karakter setelah pemangkasan spasi; pembeda maksimal 80 karakter dan keterangan transaksi maksimal 300 karakter. Batas disampaikan sebelum penyimpanan tanpa pemotongan diam-diam.

## 6. Kebutuhan fungsional versi pertama

**Must** wajib lulus sebelum rilis. **Should** merupakan target tambahan v1; jika tidak disertakan, alasannya dicatat dalam catatan rilis dan UI tidak menampilkan kontrol yang belum bekerja. Ketentuan saldo, privasi, dan integritas data tetap wajib untuk semua fitur yang disertakan. **Deferred** bukan bagian rilis v1; ID dipertahankan agar riwayat kebutuhan tidak berubah.

| ID | Prioritas | Kebutuhan | Kriteria penerimaan |
| --- | --- | --- | --- |
| F01 | Must | Tambah/ubah pelanggan dan pemasok | Nama wajib, pembeda opsional, tanpa nomor telepon/akses kontak. Nama yang sama setelah normalisasi memicu peringatan; tetap boleh disimpan. Orang yang sama dapat memiliki kedua kategori tanpa menggabungkan saldonya |
| F02 | Should | Saran nama mirip | Sarankan orang yang ejaannya mirip; pengguna boleh memilih orang lama atau melanjutkan membuat orang baru. Peringatan nama persis sama tetap wajib melalui F01 |
| F03 | Must | Tambah utang | Nominal positif wajib; keterangan opsional; tanggal otomatis hari ini dan dapat diubah ke tanggal lampau yang valid |
| F04 | Must | Pembayaran sebagian/lunas | Saldo berkurang sesuai pembayaran; jumlah melebihi sisa ditolak dengan pesan jelas |
| F05 | Must | Saldo awal | Dicatat sebagai “Utang sebelumnya” dengan tanggal batas dan riwayat; tidak menciptakan detail barang yang tidak diketahui |
| F06 | Must | Riwayat | Utang, pembayaran, saldo awal, pembatalan, dan perbaikan dapat ditelusuri; catatan lunas tetap ada |
| F07 | Must | Perbaiki/batalkan | Koreksi nominal, jenis utang/pembayaran, orang dalam kategori sama, tanggal, dan keterangan terlacak; alasan pilihan wajib, keterangan bebas opsional. Tampilkan dampak sebelum konfirmasi dan pembayaran terkait jika saldo menjadi negatif |
| F08 | Must | Pencarian/filter | Cari nama/pembeda; tampilkan semua atau belum lunas; pelanggan dan pemasok tetap terpisah |
| F09 | Should | Arsip catatan | Arsip berlaku per kategori bersaldo nol dan menyembunyikannya dari daftar aktif kategori tersebut; kategori lain tetap tampil. Dapat dipulihkan tanpa kehilangan riwayat. Penambahan/koreksi transaksi memerlukan pengaktifan kembali kategori |
| F10 | Must | Simpan offline | Tambah, bayar, cari, dan riwayat berfungsi tanpa internet dan tanpa akun |
| F11 | Must | Cadangkan/pulihkan file | Cadangan lengkap dapat dipulihkan pada instalasi kosong; file salah/rusak tidak mengubah data aktif |
| F12 | Must | Status cadangan jujur | Catat waktu snapshot dan revisi data yang masuk file hanya setelah file selesai ditulis dan diverifikasi; pembatalan/gagal tidak memperbarui status. Tampilkan perubahan yang belum tercakup; keberhasilan file tidak dianggap konfirmasi unggahan cloud |
| F13 | Must | Penggunaan pertama | Layar kosong menjelaskan satu langkah berikutnya (“Tambah pelanggan pertama”); pendamping dapat menyiapkan data awal; tidak ada login atau pengenalan panjang |
| F14 | Should | Hapus orang salah buat | Orang yang belum punya transaksi apa pun dapat dihapus; yang sudah punya riwayat hanya dapat diarsipkan |
| F15 | Deferred | Kunci PIN aplikasi | Di luar v1; kandidat v1.1 dengan kebutuhan pemulihan akses tersendiri |
| F16 | Must | Pengingat cadangan tujuh hari | Pengingat dalam beranda mengikuti revisi data dan umur snapshot; tidak menghalangi transaksi dan tidak meminta izin notifikasi |
| F17 | Must | Android Auto Backup | Konfigurasi eksplisit untuk data buku yang diperlukan; file sementara dan material kunci perangkat dikecualikan. Uji pemulihan dan ketidaktersediaan backup tanpa mengklaim jadwal sistem pasti |
| F18 | Must | Proteksi dan pemulihan kunci cadangan | File terenkripsi dengan kunci acak; keluarga memverifikasi salinan kunci di luar HP sebelum backup pertama selesai. Kunci salah/file diubah ditolak tanpa mengganti data aktif |

Berbagi ringkasan melalui WhatsApp/lembar berbagi Android adalah kandidat tahap berikutnya: pengguna memilih satu orang, meninjau isi, lalu memilih penerima sendiri. Tidak mengirim otomatis atau menyertakan daftar pelanggan lain.

## 7. Aturan pencatatan dan perhitungan

1. Rupiah disimpan sebagai integer 64-bit, tanpa pecahan atau floating-point. Semua transaksi, termasuk saldo awal dan pembayaran, bernilai Rp1–Rp999.999.999. Total saldo dapat melampaui batas per transaksi; batas saldo per kategori/orang dan total masing-masing kategori adalah Rp999.999.999.999.999. Perhitungan diperiksa sebelum commit, tanpa pembulatan atau overflow. Penambahan yang melewati batas total ditolak dengan pesan yang menyebut batas tersebut.
2. Sisa per orang dan kategori = saldo awal aktif + tambahan utang aktif − pembayaran aktif. Pembatalan/perbaikan diperhitungkan tepat sekali.
3. Saldo pelanggan dan pemasok tidak saling mengurangi. Total keduanya bukan laba, saldo kas, atau nilai bersih warung.
4. Orang yang menjadi pelanggan sekaligus pemasok memiliki dua catatan kategori terpisah; versi pertama tidak melakukan saling hapus utang.
5. Tidak ada pengubahan saldo langsung. Semua perubahan harus berasal dari transaksi atau koreksi yang dapat ditelusuri.
6. Nominal kosong, nol, negatif, tidak valid, dan pembayaran melebihi sisa ditolak.
7. Pembayaran dicatat ke saldo orang secara keseluruhan, bukan dialokasikan per faktur/barang. Penanda lunas berlaku untuk saldo orang, bukan janji bahwa setiap transaksi memiliki alokasi pelunasan.
8. Tanggal efektif disimpan sebagai tanggal kalender pilihan pengguna; waktu pencatatan disimpan terpisah dalam UTC. Pergantian zona waktu tidak menggeser tanggal efektif catatan lama. Tanggal masa depan dan sebelum 1 Januari 1900 ditolak. Tanggal otomatis memakai tanggal lokal perangkat; jika jam perangkat salah, pengguna memperbaiki jam atau tanggal sebelum menyimpan.
9. Urutan perhitungan: tanggal efektif menaik, saldo awal lebih dahulu pada tanggal batas, lalu nomor urut pencatatan yang stabil dan ID sebagai pembeda. Koreksi memakai posisi urut transaksi asal dalam kategori sama; pemindahan ke orang lain diberi urutan baru pada tujuan. Hitung ulang seluruh riwayat yang terdampak. Jika saldo pada titik mana pun negatif atau melewati batas, tolak tanpa perubahan dan tampilkan rentang terkait. Riwayat dapat ditampilkan terbaru dahulu, tetapi angka sisa dihitung dengan urutan tersebut.
10. Tombol simpan tidak dapat menghasilkan transaksi ganda ketika ditekan berulang. Gunakan ID operasi yang sama untuk percobaan ulang operasi yang sama.
11. Tampilkan keberhasilan hanya setelah transaksi database selesai. Jika penyimpanan gagal, isian tetap tersedia agar bisa dicoba kembali.
12. Transaksi keuangan tidak dihapus permanen melalui pemakaian harian. Pembatalan tetap terlihat pada riwayat, dengan alasan dari pilihan siap pakai (ketik bebas opsional).
13. Koreksi tidak boleh menghasilkan rangkaian pembatalan yang dihitung ganda. Validasi dan penulisan seluruh efek koreksi dilakukan dalam satu transaksi database.
14. Riwayat aplikasi membantu menjelaskan catatan, tetapi bukan bukti bahwa pelanggan telah menyetujui transaksi atau bahwa jam perangkat selalu benar.
15. “Isi sejumlah sisa” tersedia hanya bila sisa Rp1–Rp999.999.999. Untuk sisa lebih besar, tampilkan “Sisa melebihi batas satu pembayaran. Catat pembayaran bertahap.” Jangan memecah pembayaran otomatis atau mengubah jumlah diam-diam.
16. Proyeksi saldo hanya menghitung versi transaksi yang aktif. Transaksi asal yang dibatalkan/diganti beserta peristiwa auditnya tidak dihitung lagi sebagai arus uang tambahan. Koreksi atas koreksi merujuk versi aktif; pembatalan kedua atas versi tidak aktif ditolak. Audit tetap menampilkan rantai asal dan penggantinya.
17. Saldo awal tidak diubah menjadi pembayaran atau dipindahkan ke orang lain melalui koreksi biasa. Kesalahan pemilik saldo awal diperbaiki dengan pembatalan pada buku lama lalu penyiapan buku orang yang benar, mengikuti validasi saldo dan ketentuan tanpa riwayat.
18. Orang dengan riwayat apa pun, termasuk seluruh transaksi sudah dibatalkan, tidak boleh dihapus. Orang tanpa riwayat dapat dihapus bersama kategori kosongnya setelah konfirmasi. Fitur gabung orang tidak tersedia di v1.
19. Jumlah pembayaran divalidasi terhadap sisa pada posisi tanggal efektif serta saldo berikutnya; tidak cukup hanya membandingkan dengan saldo hari ini. Semua validasi dilakukan lagi di dalam transaksi database agar tampilan lama tidak meloloskan pembayaran berlebih.

### Contoh perhitungan untuk pengujian

| Kejadian pada Bu Siti | Sisa |
| --- | ---: |
| Utang sebelumnya Rp20.000 | Rp20.000 |
| Tambah utang Rp25.000 | Rp45.000 |
| Pelanggan bayar Rp10.000 | Rp35.000 |
| Perbaiki tambahan Rp25.000 menjadi Rp15.000 | Rp25.000 |
| Pelanggan bayar Rp25.000 | Rp0 |

Pembatalan tambahan utang yang sudah dibayar dapat membuat saldo negatif. Versi pertama harus menolaknya dan meminta peninjauan pembayaran terkait; jangan mengubah selisih menjadi kredit pelanggan secara diam-diam.

Kasus batas wajib: tambahan Rp999.999.999 dua kali menghasilkan Rp1.999.999.998, tetap dapat ditampilkan, dan dilunasi melalui dua pembayaran yang sah. Rp1.000.000.000 sebagai satu transaksi ditolak. Saldo nol tidak membuat transaksi pembayaran Rp0. Saldo awal kosong dan saldo awal yang telah dibatalkan memiliki status tanggal batas berbeda sesuai bagian 5.

## 8. Kemudahan penggunaan untuk usia 50+

Angka berikut adalah persyaratan desain yang wajib diverifikasi pada HP sasaran; hasilnya dicatat pada pengujian penerimaan.

- Tombol utama minimal tinggi 56 logical pixels; area sentuh interaktif lain minimal 48 × 48.
- Teks utama menggunakan ukuran dasar 18–20 logical pixels dan nominal utama 28–32, dengan dukungan pembesaran teks sistem sampai 200% tanpa kehilangan fungsi. Nominal panjang membungkus atau mendapat ruang tambahan, tidak dipotong dengan elipsis.
- Kontras teks biasa minimal 4,5:1; angka dan status tidak dibedakan hanya melalui warna.
- Gunakan label teks pada tombol; ikon berfungsi sebagai pendamping.
- Satu tujuan utama per formulir, papan angka untuk nominal, format ribuan otomatis, tanpa kewajiban mengetik “Rp”.
- Pilihan tambahan tidak menutupi tombol simpan atau mengharuskan pengguna memahami istilah teknis.
- Tidak mengandalkan swipe, long press, atau ikon tiga titik untuk tindakan harian yang penting.
- Nama orang dan arah pembayaran tetap terbaca sebelum menyimpan agar tidak salah buku.
- Pesan kesalahan konkret: “Jumlah bayar lebih besar dari sisa Rp15.000.”
- Jika pengguna keluar dari formulir yang belum disimpan, tampilkan pilihan melanjutkan atau membuang isian; jangan membuat transaksi setengah jadi.
- Saat proses simpan berlangsung, beri umpan balik; notifikasi keberhasilan jangan hanya berupa pesan singkat yang cepat hilang.
- Screen reader memiliki label yang menyebut tindakan dan konteks; urutan fokus mengikuti urutan baca.
- Tidak ada iklan, promosi, atau pemberitahuan pemasaran dalam alur mencatat.

## 9. Penyimpanan, backup, sinkronisasi, dan Excel

### Istilah yang berbeda

| Istilah | Fungsi dalam produk |
| --- | --- |
| Database lokal | Sumber utama seluruh catatan di HP |
| Cache | Data sementara yang boleh dibuang; tidak digunakan sebagai penyimpanan utama utang |
| Backup/cadangan | Salinan lengkap pada satu titik waktu untuk dipulihkan |
| Sinkronisasi | Menyamakan perubahan dari beberapa perangkat dengan aturan konflik |
| Excel/CSV | Laporan yang bisa dibuka dan diolah di komputer |

Database SQLite lokal menjadi sumber utama, sehingga penyimpanan transaksi tidak menunggu jaringan. Flutter mendokumentasikan penyimpanan SQLite dan pola offline-first. [Flutter SQLite](https://docs.flutter.dev/cookbook/persistence/sqlite), [Flutter offline-first](https://docs.flutter.dev/app-architecture/design-patterns/offline-first).

Cache bisa dibersihkan Android. Data lokal persisten tetap memiliki risiko hilang ketika data aplikasi dihapus, aplikasi di-uninstall, atau HP hilang/rusak. “Tersimpan di HP” tidak sama dengan “sudah dicadangkan di luar HP”. [Penyimpanan aplikasi Android](https://developer.android.com/training/data-storage/app-specific).

### Backup minimum versi pertama

- File `.catatanwarung` berisi snapshot lengkap orang, kategori termasuk arsip, transaksi, koreksi, saldo awal, pengaturan buku, dan versi format. Tidak menyertakan kunci pembuka, kunci penandatanganan aplikasi, atau file sementara.
- Cadangan harus berasal dari snapshot konsisten. Jangan menyalin file database aktif secara sembarang karena transaksi yang belum masuk snapshot bisa terlewat.
- Payload terenkripsi memuat waktu snapshot, revisi data, identitas buku, versi aplikasi/skema, jumlah catatan, dan ringkasan saldo untuk validasi. Header hanya memuat penanda format/versi, ID kunci dan parameter kriptografi yang diperlukan; tidak memuat nama atau nominal. Header harus ikut diautentikasi agar perubahan terdeteksi.
- Cadangan awal disimpan ke lokasi yang dipilih pengguna; keluarga dapat membantu menyalin file ke luar HP. Salinan lain pada HP yang sama belum melindungi dari kehilangan perangkat.
- File menggunakan enkripsi terautentikasi AES-256-GCM melalui pustaka terpelihara, dengan kunci dari sumber acak kriptografis dan nonce unik per file. Algoritme tidak ditulis sendiri. [Panduan kriptografi Android](https://developer.android.com/privacy-and-security/cryptography).
- Backup dijalankan keluarga melalui pemilih lokasi file Android. Pengguna dapat membatalkan tanpa mengubah data. Selama pembuatan snapshot, penulisan transaksi dikunci singkat; layar menunjukkan proses tanpa membekukan antarmuka.
- File baru memiliki nama unik. Kegagalan penulisan tidak boleh menghapus backup lama. Keberhasilan baru dicatat setelah file di lokasi tujuan dapat dibaca kembali dan lolos pemeriksaan autentikasi/integritas. Bila provider belum mengizinkan verifikasi, status “Belum terverifikasi” dan tanggal backup berhasil tidak berubah.
- Tampilkan waktu snapshot terakhir yang berhasil diekspor beserta keterangan bahwa keberhasilan file belum membuktikan unggahan provider cloud selesai. Tidak memperbarui status hanya karena pemilih file atau menu bagikan terbuka.
- Pertahankan paling sedikit dua cadangan terakhir yang telah diverifikasi di luar HP melalui prosedur keluarga; aplikasi tidak menghapus file milik pengguna secara otomatis.

### Kunci cadangan

1. Pada backup pertama, aplikasi membuat kunci acak 256-bit dan ID kunci. Tampilkan kode yang bisa disalin, dikelompokkan agar mudah dibaca, serta opsi menyimpan kartu kunci sebagai file teks. Kartu berisi versi format, ID kunci, kode, dan petunjuk singkat tanpa data utang.
2. Keluarga menyimpan kartu di luar HP ibu: dicetak/ditulis, difoto menggunakan HP keluarga, atau disalin ke media lain. Kunci tidak disimpan dalam file cadangan yang dikuncinya. Tidak ada fitur kamera/pemindai QR wajib di v1.
3. Sebelum backup pertama dinyatakan selesai, keluarga memasukkan kembali kode atau membuka kartu kunci melalui pemilih file. Aplikasi memverifikasi kesesuaian; konfirmasi centang saja tidak cukup.
4. Kunci cadangan boleh disimpan lokal dengan pembungkus kunci perangkat melalui Android Keystore agar backup berikutnya tidak membutuhkan pengetikan ulang. Material ini dikecualikan dari Auto Backup dan tidak dicetak pada log. Kunci cadangan yang dapat diekspor berbeda dari kunci pembungkus perangkat yang tidak dapat diekspor. [Android Keystore](https://developer.android.com/privacy-and-security/keystore).
5. Setelah penyiapan, kunci tidak ditampilkan ulang dalam alur harian. Jika salinan luar hilang tetapi buku masih tersedia, keluarga membuat kunci baru dan cadangan baru melalui alur penyiapan yang sama. Penggantian baru berlaku setelah backup baru diverifikasi; backup lama tetap memerlukan kunci lamanya.
6. Jika material lokal hilang/tidak dapat dibuka, aplikasi tetap dapat membaca buku lokal dan meminta kartu kunci atau penyiapan kunci baru ketika membuat backup. Tidak menghapus database karena masalah kunci cadangan.
7. Pemulihan dari file membutuhkan kunci yang cocok dari luar HP. Tidak ada pemulihan kata sandi lewat server. Ibu tidak memerlukan kunci untuk mencatat harian. Uji pemulihan pertama wajib dilakukan sebelum buku nyata menjadi satu-satunya catatan.

### Pengingat dan status cadangan

- Setiap perubahan data buku yang masuk backup menaikkan revisi data. Membuka layar, mengubah filter, atau membaca riwayat tidak menaikkan revisi.
- Setelah perubahan pertama, tampilkan status “Belum pernah dicadangkan” sampai backup berhasil. Bila sudah ada backup, tampilkan waktu snapshot terakhir dan apakah ada perubahan sesudahnya.
- Pengingat beranda muncul bila ada perubahan yang belum dicadangkan dan sudah tujuh hari sejak snapshot berhasil terakhir. Jika belum pernah backup, hitung sejak perubahan pertama. Tujuh hari adalah 7 × 24 jam; ini pemicu pengingat, bukan janji bahwa cadangan otomatis dibuat.
- Pengingat tetap tersedia tanpa dialog berulang, tanpa izin notifikasi, dan tanpa memblokir pencatatan. Menutup sementara hanya menyembunyikannya untuk sesi saat itu.
- Menyimpan salinan di HP yang sama tetap disebut “File cadangan dibuat”; aplikasi menyatakan perlunya salinan di luar HP. Pernyataan pengguna bahwa file sudah dipindah tidak dianggap verifikasi cloud otomatis.
- Restore tidak mewarisi klaim bahwa file eksternal lama masih tersedia di perangkat baru. Tampilkan “Catatan dipulihkan dari cadangan [tanggal]; buat cadangan baru di perangkat ini”, lalu mulai penilaian pengingat dari pemulihan sampai backup baru berhasil.
- Perubahan jam perangkat yang tidak masuk akal tidak boleh menghasilkan klaim backup lebih baru. Pertahankan timestamp asli dan tampilkan petunjuk memeriksa waktu perangkat; pengguna tetap dapat mencadangkan manual.

### Pemulihan

1. Pengguna memilih file dan memasukkan kode/memilih kartu kunci; aplikasi memeriksa format, versi, batas ukuran, autentikasi, dan integritas. File cadangan manual selalu terenkripsi.
2. Tampilkan tanggal cadangan, jumlah orang/transaksi, dan ringkasan saldo kedua kategori sebelum menerapkan.
3. Jelaskan bahwa pemulihan **mengganti** catatan aktif, bukan menggabungkannya. Catatan setelah waktu cadangan tidak ikut kembali.
4. Jika ada data aktif, buat snapshot pengaman persisten yang tidak dapat ditimpa oleh restore, di penyimpanan privat aplikasi. Jika snapshot gagal, jangan lanjutkan. Sediakan “Kembalikan catatan sebelum pemulihan” dengan konfirmasi yang menjelaskan hilangnya perubahan setelah restore. Snapshot pengaman hanya melindungi penggantian lokal, bukan kehilangan HP.
5. Pulihkan ke database sementara, validasi relasi dan saldo, lalu ganti database aktif secara atomik.
6. File tidak cocok/rusak, versi lebih baru yang tidak didukung, kunci salah, atau ruang tidak cukup tidak boleh merusak data aktif.
7. Memulihkan file sama dua kali tidak boleh menggandakan transaksi. Pulih pada HP pengganti tidak berarti kedua HP menjadi sinkron.
8. Blokir penulisan transaksi selama penggantian database. Jika proses mati, pembukaan aplikasi berikutnya harus memilih database lama atau baru yang utuh; tidak boleh campuran atau buku kosong. Tampilkan hasil pemulihan yang dapat diperiksa.
9. Versi format awal adalah 1. Versi yang lebih baru dari kemampuan aplikasi ditolak dengan pesan memperbarui aplikasi; jangan menebak format. Saat format berkembang, migrasi harus punya uji kompatibilitas sebelum rilis.
10. Pemulihan tidak boleh menghapus snapshot pengaman terakhir secara otomatis. Jika rollback akan mengganti perubahan yang dibuat setelah restore, tawarkan membuat backup terlebih dahulu dan minta konfirmasi dampaknya.

### Kehilangan data dan uninstall

Pengguna perlu tahu bagaimana catatan kembali jika data hilang atau aplikasi dipasang ulang. Rancangan harus menyediakan cara pemulihan dari salinan di luar instalasi aplikasi, bukan hanya penyimpanan lokal.

| Keadaan | Hasil yang harus dijelaskan kepada pengguna |
| --- | --- |
| Aplikasi ditutup atau HP restart | Catatan yang berhasil disimpan tetap tersedia pada database lokal |
| Uninstall/hapus data, tanpa cadangan yang dapat diakses | Catatan lokal hilang; pemasangan ulang saja tidak bisa menciptakannya kembali |
| Uninstall dengan cadangan sistem yang dapat dipulihkan | Android dapat memulihkan snapshot yang tersedia; tidak dijanjikan mencakup transaksi terbaru |
| Memiliki file cadangan dan kunci di luar aplikasi | Instal aplikasi dan gunakan “Pulihkan catatan”; masukkan kode atau pilih kartu kunci yang cocok |
| HP hilang/rusak dan semua salinan hanya ada di HP tersebut | Tidak ada sumber pemulihan yang dapat diandalkan |
| Cadangan terakhir kemarin, ada transaksi baru hari ini | Transaksi setelah waktu snapshot belum terlindungi oleh cadangan tersebut |

v1 menggunakan cadangan manual yang dibantu keluarga, pengingat tujuh hari, dan Android Auto Backup. Catatan setelah cadangan terakhir dapat hilang; tujuh hari bukan batas maksimum kehilangan karena pengingat dapat diabaikan. Keluarga memeriksa dan menyalin cadangan setidaknya setiap minggu serta sebelum uninstall, pindah HP, atau perbaikan perangkat. Jika uji penggunaan menunjukkan prosedur ini tidak dijalankan, aplikasi belum boleh menjadi satu-satunya buku nyata; evaluasi ulang prosedur atau ajukan perubahan cakupan cloud pada versi PRD berikutnya.

### Android Auto Backup (lapisan tambahan v1)

Bila layanan backup Google perangkat tersedia dan diaktifkan, Android Auto Backup dapat mencadangkan data aplikasi ke akun Google perangkat dengan batas 25 MB per aplikasi. Jadwalnya dikelola sistem dan tidak menjamin transaksi terbaru telah dicadangkan. [Android Auto Backup](https://developer.android.com/identity/data/autobackup). Persyaratan v1:

- Sertakan database buku dan pengaturan yang diperlukan melalui aturan eksplisit sesuai versi Android. Kecualikan kunci lokal yang bergantung perangkat, kartu kunci, file ekspor sementara, snapshot rollback, dan metadata yang menyatakan akses file eksternal masih valid.
- Uji backup → uninstall → install → pemeriksaan saldo pada HP sasaran.
- Database v1 berada di penyimpanan privat aplikasi, tanpa enkripsi database tambahan yang bergantung kunci aplikasi. Enkripsi file cadangan manual tetap wajib. Aplikasi tidak menjanjikan perlindungan dari orang yang sudah bisa membuka HP atau perangkat yang dikompromikan.
- Jangan menampilkan waktu backup sistem terakhir sebagai fakta tanpa sumber status yang dapat dipercaya.
- Cadangan file tetap menjadi jalur pemulihan utama yang dapat diverifikasi.
- Jika data yang memenuhi aturan mencapai 20 MB, tampilkan petunjuk bahwa backup sistem memiliki batas dan sarankan cadangan file. Tidak menghapus riwayat untuk mengecilkan database. Keberhasilan sistem pada perangkat sasaran harus dibuktikan sebelum klaim kompatibilitas.

### Cloud otomatis dan Google Drive (di luar v1)

Supabase Free dan integrasi Google Drive API langsung tidak diimplementasikan pada v1. [Lampiran](PRD-lampiran-backup-cloud.md) hanya menjadi bahan evaluasi v1.1 dan tidak menambah persyaratan rilis v1. Pengguna tetap dapat memilih provider penyimpanan yang tersedia melalui pemilih file Android; aplikasi tidak mengelola login, unggahan otomatis, atau sinkronisasi provider tersebut.

### Sinkronisasi

Sinkronisasi antar-HP belum diperlukan karena pengguna memilih satu HP. Pengiriman catatan dari HP ke cloud untuk pemulihan (lihat [lampiran](PRD-lampiran-backup-cloud.md)) adalah kebutuhan terpisah di luar v1. Mengunggah dan mengunduh file database secara bergantian bukan sinkronisasi transaksi yang aman untuk banyak HP. Bila kebutuhan berubah, diperlukan desain hak akses, deduplikasi, konflik koreksi, serta penerapan perubahan offline dari beberapa perangkat.

### Excel

Tidak ada impor atau ekspor Excel/CSV pada v1. File `.catatanwarung` adalah format pemulihan aplikasi, bukan laporan spreadsheet. Kebutuhan laporan akan ditentukan dalam PRD versi berikutnya.

## 10. Batas arsitektur dan persyaratan non-fungsional

Bagian ini menetapkan perilaku dan batas teknis implementasi. Pilihan package, nama tabel, struktur folder, serta detail wire format dicatat dalam desain teknis sebelum modul terkait dibuat; pilihan tersebut tidak boleh mengubah kontrak produk atau menunda keputusan cakupan v1.

| Bagian | Ketentuan |
| --- | --- |
| Aplikasi | Flutter/Dart; Android minimum API 26; versi Flutter dan dependensi dikunci pada awal implementasi |
| Penyimpanan | SQLite pada direktori data persisten aplikasi |
| Akses database | Satu lapisan repository untuk baca/tulis; migrasi skema berversi dan transaksi atomik wajib, terlepas dari package SQLite yang dipilih |
| Logika saldo | Terpusat di layanan/repository agar utang dan pembayaran mengikuti validasi sama |
| Penulisan | Transaksi database atomik dan ID operasi unik |
| Cadangan | Snapshot konsisten, format berversi, validasi sebelum restore |
| Backend | Tidak ada pada v1; tidak memerlukan proyek cloud, akun aplikasi, atau kredensial layanan |
| Telemetri | Tidak ada analitik atau pelaporan isi catatan ke server; log diagnostik lokal tidak memuat nama, nominal, keterangan, atau kunci |

Model konseptual minimum:

- **Buku warung:** satu buku per instalasi, ID stabil, nama warung, mata uang, versi skema, dan revisi data yang bertambah saat berubah.
- **Orang:** ID stabil, nama/panggilan, pembeda opsional. Status tampil di daftar diturunkan dari arsip catatan kategorinya.
- **Catatan per kategori:** ID, orang, jenis pelanggan/pemasok, status arsip, tanggal batas saldo awal (kosong bila tidak pernah memiliki saldo awal pada kategori itu). Maksimal satu catatan untuk kombinasi orang dan kategori.
- **Transaksi:** ID, ID operasi, catatan kategori, jenis, nominal rupiah, tanggal efektif, waktu pencatatan, nomor urut stabil, keterangan, status versi aktif, serta referensi koreksi/pembatalan dan alasan pilihannya.
- **Metadata cadangan:** versi format, waktu snapshot, revisi buku, identitas buku, jumlah data, hasil verifikasi dan ID kunci; metadata tidak menyimpan kunci dalam teks terbuka.
- **Status perangkat:** waktu mulai pengingat dan status ekspor yang hanya berlaku pada instalasi ini. Status tidak boleh dipulihkan sebagai bukti keberadaan salinan eksternal di perangkat lain.

Saldo diturunkan dari transaksi; jika nilai saldo disimpan untuk mempercepat tampilan, nilainya harus bisa dihitung ulang dan diperiksa konsistensinya. Orang yang sudah memiliki transaksi tidak dihapus; hanya diarsipkan (F09, F14), sehingga relasi transaksi tidak terputus.

### Persyaratan non-fungsional

| ID | Aspek | Kriteria penerimaan |
| --- | --- | --- |
| N01 | Kompatibilitas | Instal dan alur inti lulus pada Android API 26 serta versi Android HP ibu; package tidak menaikkan minimum tanpa perubahan spesifikasi |
| N02 | Bahasa dan format | Bahasa Indonesia; nominal Rupiah bulat dengan titik ribuan; tanggal efektif tetap saat zona waktu berubah |
| N03 | Volume uji | 500 orang, maksimal dua kategori per orang, serta 20.000 entri termasuk audit/koreksi; dataset memuat lunas, arsip, dan nama panjang. Ini skala penerimaan, bukan batas jumlah catatan produk |
| N04 | Performa | Pada build release/profile HP sasaran dengan dataset N03: p95 simpan sampai konfirmasi ≤500 ms, daftar/pencarian ≤1 detik, dan cold start sampai beranda bisa digunakan ≤3 detik. Ukur 20 percobaan per operasi; catat perangkat serta metode |
| N05 | Cadangan | Ekspor/pemulihan dataset N03 selesai ≤60 detik pada penyimpanan lokal, di luar waktu mengetik kunci dan provider cloud; tampilkan progres dan cegah submit ulang |
| N06 | Integritas | Tidak ada penulisan parsial, transaksi ganda, atau kehilangan catatan tersimpan pada uji penghentian proses, ruang penuh, upgrade skema, dan restore |
| N07 | Aksesibilitas | Semua tindakan inti dapat dilakukan dengan TalkBack; ukuran sentuh, kontras, dan font 200% pada bagian 8 terpenuhi; keyboard tidak menutupi tindakan simpan |
| N08 | Format cadangan | Batas input file 100 MiB dan payload terurai 200 MiB; maksimal 200.000 entri per impor. File yang melampaui batas ditolak sebelum penggantian. Ekspor yang melampaui batas ditolak dengan pesan jelas, tanpa mengekspor sebagian |
| N09 | Pembaruan | Paket ID dan identitas penandatanganan dipertahankan; migrasi dari setiap skema v1 yang pernah dirilis diuji tanpa kehilangan catatan dan tanpa downgrade skema otomatis |

API 26 ditetapkan sebagai batas produk, bukan batas minimum Flutter secara umum. Dukungan platform framework dirujuk dari [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms). Kompatibilitas serta performa pada HP ibu baru dinyatakan setelah diuji; spesifikasi perangkat yang belum dikonfirmasi bukan alasan mengarang hasil pengujian.

### Privasi dan keamanan

- Nama dan catatan utang diperlakukan sebagai data pribadi. Aplikasi tidak mengirimnya ke backend aplikasi atau layanan analitik. Sistem Android dapat mencadangkannya sesuai pengaturan backup perangkat; pemilih file/provider juga dapat menyimpan file di lokasi yang dipilih pengguna.
- Halaman Cadangan menjelaskan kedua jalur tersebut dengan bahasa sederhana. Pemilihan lokasi file tidak boleh dianggap persetujuan pengiriman lain atau akses seluruh penyimpanan.
- Tidak meminta izin kontak, SMS, kamera, notifikasi, atau akses seluruh file. Pemilihan backup/kartu kunci menggunakan pemilih file sistem.
- Database berada di direktori privat aplikasi. Tidak ada PIN aplikasi v1; keluarga menggunakan kunci layar HP dan memahami bahwa orang yang dapat membuka HP dapat membuka aplikasi.
- Backup manual selalu terenkripsi; kartu kunci diperlakukan sebagai rahasia, disimpan keluarga secara terpisah dari file backup. Log, pesan kesalahan, dan laporan uji tidak menyertakan data nyata atau material kunci.
- Data sementara hasil dekripsi dibatasi di ruang privat, dibersihkan setelah selesai/gagal serta saat startup setelah crash, dan dikecualikan dari backup sistem. Jangan menghapus snapshot rollback yang masih diperlukan untuk pemulihan.
- Aplikasi memberi petunjuk tujuan penyimpanan dan cara menjaga kunci sebelum ekspor. Tidak mengklaim cadangan dapat dipulihkan jika kunci yang cocok hilang.

## 11. Ukuran keberhasilan dan rencana validasi

### Target usability penerimaan

| Sasaran | Cara mengukur |
| --- | --- |
| Ibu membedakan pelanggan/pemasok dan arah bayar | Setelah pengenalan singkat, dapat memilih alur benar pada 5 skenario contoh |
| Catatan cepat untuk orang yang sudah ada | Target median maksimal 15 detik dari daftar orang sampai tersimpan, tanpa keterangan opsional |
| Tugas selesai mandiri | Minimal 4 dari 5 tugas inti selesai tanpa arahan setelah satu sesi latihan |
| Riwayat dapat dijelaskan | Ibu dapat menemukan transaksi dan menjelaskan asal sisa pada contoh cicilan |
| Data bisa dipulihkan | Keluarga berhasil memulihkan cadangan di instalasi kosong dan mencocokkan semua saldo/riwayat |

Lima tugas inti: tambah utang pelanggan, catat cicilan, temukan riwayat pelanggan, tambah utang pemasok, dan catat pembayaran pemasok. Koreksi dan backup diuji sebagai tugas tambahan bersama keluarga.

### Pengujian sebelum data nyata menjadi catatan utama

- Perhitungan saldo awal, tambahan utang, cicilan, lunas, koreksi, dan pembatalan pada kedua kategori.
- Orang sama di dua kategori dan orang berbeda dengan nama sama.
- Tekan simpan berkali-kali, aplikasi tertutup saat menyimpan, ruang penyimpanan habis, dan percobaan ulang setelah gagal.
- Mode pesawat, aplikasi dibuka ulang, restart HP, serta upgrade database tanpa kehilangan catatan.
- Koreksi transaksi lama dan tanggal lampau yang memengaruhi saldo berikutnya.
- Backup dibuat saat ada transaksi baru; snapshot harus konsisten dan batas waktunya jelas.
- Restore file utuh, file rusak, format tidak didukung, kunci salah, data aktif, dan file sama dua kali.
- Pembesaran font, keyboard terbuka, screen reader, dan ukuran layar HP ibu.
- Jika ekspor melalui provider cloud dipilih: uji batal, offline, proses unggah tertunda, serta pengambilan file dari perangkat lain.

Mulai dengan data contoh, lalu tujuh hari operasional dengan buku pembanding. Target penerimaan tidak berubah diam-diam ketika pengujian gagal; perbaiki implementasi atau catat perubahan spesifikasi yang disepakati. Perhitungan saldo, keberhasilan simpan, dan pemulihan tidak boleh diluluskan dengan pengecualian. Keberhasilan emulator tidak menggantikan pengujian HP ibu dan latihan bersama pengguna.

### Kasus penerimaan tambahan wajib

| ID | Skenario | Hasil yang wajib |
| --- | --- | --- |
| A01 | Dua utang Rp999.999.999 | Sisa Rp1.999.999.998; pelunasan satu transaksi tidak tersedia; dua pembayaran sah menghasilkan Rp0 |
| A02 | Nominal 0, negatif, pecahan, atau Rp1.000.000.000 | Ditolak dengan isian tetap tersedia; tidak ada transaksi baru |
| A03 | Koreksi/cancel membuat saldo historis negatif | Semua perubahan ditolak; tombol pembayaran terkait membuka rentang yang relevan |
| A04 | Koreksi berulang dan double-tap simpan | Saldo menghitung satu versi aktif; percobaan ulang tidak membuat entri uang kedua |
| A05 | Tanpa saldo awal, saldo awal dibatalkan, tanggal lampau | Null dan tanggal batas mengikuti bagian 5; validasi serta urutan bagian 7 berlaku |
| A06 | Orang mempunyai pelanggan dan pemasok | Saldo tidak saling mengurangi; bila arsip disertakan, arsip satu kategori tidak menyembunyikan yang lain |
| A07 | Backup dibatalkan, ruang habis, atau file tujuan tidak dapat diverifikasi | Timestamp backup berhasil tidak berubah; cadangan lama tetap ada; tidak ada klaim berhasil |
| A08 | Data berubah setelah backup dan melewati tujuh hari | Pengingat muncul; tanpa perubahan belum tercakup tidak muncul; jika belum pernah backup hitung dari perubahan pertama |
| A09 | Kunci salah, file diubah, versi terlalu baru, atau batas impor terlewati | Pemulihan ditolak tanpa mengubah buku aktif |
| A10 | Restore saat ada buku aktif lalu proses dihentikan | Database lama/baru yang utuh dapat dibuka; rollback tersedia dan tidak menggandakan transaksi |
| A11 | Instalasi kosong + file backup + kartu kunci keluarga | Seluruh saldo, koreksi, kategori/arsip, dan jumlah catatan cocok; restore dua kali tidak menggandakan data |
| A12 | Auto Backup tersedia / dinonaktifkan / pemulihan ke instalasi lain | Jalur sistem diuji; jika tidak tersedia aplikasi tetap berfungsi dan mengarahkan ke file manual. Kunci lokal hilang tidak merusak buku |
| A13 | Kehilangan kartu kunci dengan buku lokal masih ada | Penyiapan kunci baru dan file baru berhasil; file lama tidak diklaim bisa dibuka dengan kunci baru |
| A14 | Upgrade APK bertanda tangan sama | Migrasi berhasil tanpa meminta uninstall; buku dan riwayat cocok sebelum/sesudah |
| A15 | Nama sama, nama panjang, font 200%, TalkBack | Nama sama memicu peringatan; orang tetap dibedakan; nominal dan tindakan inti tidak hilang |

### Kriteria siap dirilis (definition of done v1)

1. Semua Must **F01, F03–F08, F10–F13, F16–F18** lulus. Status Should F02, F09, F14 tercatat sebagai disertakan dan lulus atau ditunda beserta alasannya; F15 tidak masuk rilis.
2. Contoh perhitungan bagian 7 dan kasus A01–A05 lulus uji otomatis; A06–A15 lulus dengan bukti yang sesuai dan tidak ada kehilangan/penggandaan data.
3. N01–N09 dan seluruh ketentuan aksesibilitas lulus. Nomor model/versi Android, build aplikasi, dataset, waktu uji, dan hasil dicatat.
4. Keluarga berhasil memulihkan cadangan pada instalasi kosong dengan kartu kunci dari luar HP. Cocokkan saldo, jumlah catatan, serta riwayat pembatalan/koreksi, bukan hanya berhasil membuka aplikasi.
5. Android Auto Backup diuji melalui backup → instal ulang → verifikasi data pada perangkat yang mendukung. Pada HP ibu, status pengaturan dan hasil pengujian dicatat. Jika fasilitas sistem tidak tersedia, nyatakan keterbatasan itu dalam catatan rilis dan wajib buktikan jalur file manual; jangan mengklaim auto-restore bekerja.
6. Ibu memenuhi target usability bagian 11 setelah sesi pengenalan. Tujuh hari operasional dengan buku pembanding selesai tanpa selisih yang tidak dapat dijelaskan.
7. Satu anggota keluarga ditetapkan sebagai penanggung jawab cadangan. Terdapat cadangan di luar HP dan kartu kunci yang dapat diakses; latihan backup berkala telah dilakukan selama uji penggunaan.
8. Tidak ada masalah terbuka yang menyebabkan saldo salah, data hilang, file backup tidak dapat dipulihkan, data bocor, atau tindakan inti tidak dapat digunakan. Laporan membedakan hasil otomatis, emulator, perangkat fisik, dan penggunaan bersama ibu.

## 12. Urutan implementasi

1. **Persiapan dan prototipe:** catat model/OS HP, pilih package terpelihara yang memenuhi API 26, dokumentasikan desain teknis, lalu uji istilah dan tiga tugas utama bersama ibu.
2. **Fondasi lokal:** pelanggan/pemasok, saldo awal, tambah utang, pembayaran, riwayat, validasi dan koreksi.
3. **Ketahanan data:** backup lengkap, restore, proteksi cadangan, pengujian kegagalan dan migrasi. Selesai sebelum aplikasi menjadi satu-satunya catatan nyata.
4. **Uji penggunaan:** jalankan pada HP ibu, ukur waktu dan salah input, sederhanakan bagian yang membingungkan.
5. **Rilis keluarga v1:** selesaikan kriteria rilis, simpan APK dan identitas penandatanganan, serta berikan petunjuk singkat pencatatan, cadangan, dan pemulihan.
6. **Evaluasi setelah v1:** pertimbangkan PIN, cloud, WhatsApp, Excel, atau pengingat pembayaran melalui perubahan PRD v1.1, berdasarkan masalah nyata dari uji penggunaan. Tidak ada fitur tersebut yang menjadi syarat menyelesaikan v1.

Estimasi jadwal disusun setelah desain teknis dan pemeriksaan perangkat; jadwal bukan bagian dari kriteria keberhasilan fungsional.

## 13. Risiko utama

| Risiko | Dampak | Mitigasi awal |
| --- | --- | --- |
| Ibu lupa atau tidak sempat mencatat | Saldo tidak lengkap; produk gagal menyelesaikan masalah awal | Alur tercepat, uji 15 detik, buku pembanding selama uji |
| Cadangan tidak pernah dibuat | Data hilang saat HP rusak/hilang | Pengingat tujuh hari, bantuan keluarga, Android Auto Backup, tinjau ulang cloud di v1.1 |
| Kartu kunci cadangan hilang | File cadangan tidak bisa dibuka | Kunci disimpan keluarga di luar HP, diverifikasi saat setup, diuji saat restore; buat kunci dan backup baru selagi buku lokal tersedia |
| Salah pilih orang atau arah bayar | Saldo salah buku | Ringkasan sebelum simpan, perbaikan yang dapat ditelusuri |
| Koreksi tanggal lampau menghasilkan saldo negatif | Pengguna buntu | Pesan konkret dan tombol “Lihat pembayaran terkait” |
| Model/OS HP belum diverifikasi | Kompatibilitas belum terbukti | Catat model dan Android sebelum pengujian; batas produk API 26, perangkat lebih tua memerlukan perubahan cakupan |
| Data pribadi terbuka bila HP dipinjam dalam keadaan terbuka | Privasi pelanggan | Kunci layar perangkat dan pengarahan keluarga; tidak mengklaim perlindungan PIN aplikasi v1 |
| File lokal dianggap sudah berada di cloud | Pemulihan tidak tersedia saat HP hilang | Status F12 membedakan ekspor file, salinan luar HP, dan status provider yang belum diketahui |
| Pembaruan memerlukan uninstall karena identitas APK berubah | Data lokal berisiko hilang | Simpan identitas penandatanganan, uji upgrade, buat cadangan sebelum pemindahan/perbaikan perangkat |

## 14. Pemeriksaan lapangan dan pengendalian perubahan

Tidak ada pilihan cakupan v1 yang menunggu brainstorming lanjutan. Pemeriksaan berikut adalah pekerjaan penerapan/pengujian, bukan fitur yang belum diputuskan:

| Pemeriksaan | Penanggung jawab | Batas waktu |
| --- | --- | --- |
| Nama model, nomor model, versi Android, ruang kosong, dan ukuran tampilan HP ibu | Pengembang bersama keluarga | Sebelum uji penerimaan perangkat; jangan mengasumsikan “S12” adalah A12 |
| Anggota keluarga penyimpan kartu kunci dan lokasi salinan backup di luar HP | Keluarga | Sebelum backup pertama dengan data nyata |
| Kebenaran saldo dari buku lama dan tanggal mulai pencatatan | Ibu bersama keluarga | Sebelum memasukkan saldo awal nyata; angka yang belum disepakati tidak ditandai terverifikasi |
| Keberhasilan memilih nama dari daftar/pencarian dan menyelesaikan tugas | Pengembang bersama ibu | Saat prototipe dan pengujian usability |
| Status backup Android, keterbatasan provider file, dan hasil latihan restore | Pengembang bersama keluarga | Sebelum aplikasi menjadi catatan utama |

Nama model yang belum terverifikasi tidak menahan finalisasi kebutuhan Android v1, tetapi menahan klaim kompatibilitas perangkat. Bila perangkat ternyata tidak memenuhi API 26, selesaikan melalui perubahan platform yang eksplisit sebelum rilis.

Setiap perubahan cakupan setelah dokumen ini difinalkan harus menyebut bagian/ID kebutuhan, alasan, dampak pada data dan pemulihan, serta pengujian yang perlu diulang. Permintaan cloud wajib, perubahan batas nominal, atau perubahan mekanisme kunci tidak boleh dimasukkan diam-diam sebagai detail implementasi.

## 15. Ringkasan revisi final

- v1.0 menggantikan Draft 0.4 sebagai acuan implementasi.
- Android, satu buku/satu HP, tanpa akun/backend; manual backup dan lapisan backup sistem dipertahankan.
- Kunci acak cadangan ditetapkan; opsi kata sandi sederhana dihapus dan F15 PIN ditunda.
- F12 dinaikkan menjadi Must; F16 pengingat, F17 Auto Backup, dan F18 proteksi kunci ditambahkan sebagai Must.
- Aturan saldo akumulasi, pembayaran bertahap, tanggal, koreksi, dan restore dibuat eksplisit.
- Target non-fungsional, skenario penerimaan, kewajiban uji perangkat, dan kriteria rilis ditetapkan. Seluruhnya masih harus dibuktikan saat implementasi.
