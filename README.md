# Sol-IT Absensi Wajah (Flutter Android App)

Paket aplikasi mobile **Absensi Sensor Wajah** untuk **PT SIT Global Systems (Sol-IT)** lengkap dengan:
- **Sensor Wajah On-Device** (`google_mlkit_face_detection`) + validasi *liveness* dasar (mata terbuka & posisi wajah) + pencocokan vektor geometris wajah secara lokal (*offline-first*).
- **Validasi GPS & Anti-Fake GPS** (*geofence* radius kantor/outlet + deteksi `isMocked` Android).
- **Registrasi Wajah** (3 sampel kamera depan per karyawan).
- **CRUD Lengkap & Master Data** (Karyawan, Departemen/Outlet, Shift Kerja + toleransi keterlambatan, dan Lokasi GPS Geofence).
- **Log Absensi & Laporan Periode** lengkap dengan tombol **Ekspor ke CSV/Excel**.
- **GitHub Actions Auto-Build APK** (`.github/workflows/build-android-apk.yml`) — tinggal *push* ke GitHub untuk langsung mengunduh file `.apk`.

## Cara Compile & Download APK lewat GitHub (Tanpa Install Android Studio)

1. **Ekstrak** file `sol-it-absensi-wajah.zip` ke sebuah folder di komputer Anda.
2. Buat repository baru di **GitHub** (boleh *Private* atau *Public*), misalnya `sol-it-absensi-wajah`.
3. **Upload / Push** seluruh isi folder (pastikan folder `.github/workflows/build-android-apk.yml`, `lib/`, dan `pubspec.yaml` ikut terunggah) ke branch `main`.
4. Buka tab **Actions** di repository GitHub Anda -> klik workflow **Build Sol-IT Absensi Wajah APK** (akan otomatis berjalan saat *push*, atau klik **Run workflow**).
5. Tunggu sekitar **3–5 menit** hingga status berubah menjadi hijau (**Success**).
6. Gulir ke bagian **Artifacts** di halaman workflow tersebut, lalu klik **`sol-it-absensi-wajah-apk`** untuk mengunduh file `app-release.apk` dan memasangnya langsung di HP Android Anda.

## Catatan Penggunaan Pertama Kali di HP Android

1. Buka menu **Master -> Lokasi GPS** untuk menyetel koordinat kantor/pabrik/restoran Anda (tersedia tombol **Ambil GPS Saat Ini**).
2. Buka menu **Master -> Karyawan & Wajah**, tekan tombol **+ Karyawan**, lalu klik menu titik tiga -> **Registrasi / Update Wajah** (ambil 3 sampel wajah).
3. Buka menu **Absen**, pilih **Absen Masuk / Pulang**, lalu tekan **Scan Wajah & Catat Absensi**.
4. Lihat riwayat di tab **Log** dan unduh rekap CSV/Excel di tab **Laporan**.
