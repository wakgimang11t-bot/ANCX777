# ANCX777

Playbook [AME Wizard](https://amelabs.net) open source yang bikin Windows 10/11 terasa lebih ringan, lebih responsif, dan lebih sedikit "telepon rumah".

Versi bahasa Indonesia. Dokumentasi lengkap ada di [README.md](README.md) (Inggris).

---

## Apa ini?

Bukan ISO Windows modifikasi. Ini **Playbook** — instruksi teks yang dijalankan AME Wizard di Windows yang sudah terinstall. Tidak menyentuh aktivasi, tidak ada patcher pihak ketiga.

Semua yang diubah bisa kamu baca sendiri: `playbook.conf`, `Configuration/main.yml`, dan script di `Executables/` — semuanya teks biasa.

## Requirement

- Windows 10 (1809+) atau Windows 11
- [AME Wizard Beta](https://amelabs.net) 0.8.4+
- Windows Security diberi pengecualian untuk folder AME Wizard (Defender kadang salah deteksi AME Wizard — itu false positive)

## Cara pakai

1. **Bikin System Restore point** atau backup data penting dulu
2. Download `ANCX777.apbx` dari halaman **Releases**
3. Cek SHA256-nya dengan file `.sha256` yang disertakan
4. Jalankan `AME Wizard Beta.exe`, drag & drop file `.apbx` ke kolom Playbooks
5. Pilih opsi yang diinginkan, jalankan, lalu reboot

Password arsip: `malte`. Itu **bukan** proteksi — cuma supaya browser/antivirus tidak memindai isi arsip. Bongkar saja dan periksa isinya.

## Yang diubah

**Performance & responsiveness:**
- Hapus startup delay, menu jadi instan
- Matikan Power Throttling & background apps
- Matikan tips/suggestions/Spotlight
- Matikan last access timestamp
- Prioritas CPU untuk game
- Matikan reserved storage, bersihkan temp
- Shutdown lebih cepat
- Opsional: matikan Automatic Maintenance

**Privacy & bloat:**
- Matikan service telemetry (`DiagTrack`, `dmwappushservice`, dll)
- Matikan scheduled task telemetry
- Opsional: hapus OneDrive, Teams, WSL, Photos, Xbox, Copilot/AI
- Opsional: hapus Microsoft Edge
- Bersihkan taskbar

**Opsional:**
- Search, SysMain (Superfetch), Hibernate & Fast Startup
- Wallpaper ANCX777 (desktop + lock screen)
- Branding **ACNX+ Optimize** di About Windows (winver), muncul di baris bawah `Windows User`
- **NVIDIA Overlay (Alt+Z) dijamin tetap berfungsi**

## ⚠️ Penting soal keamanan

**Windows Defender di-disable secara default.** Kalau kamu tidak mau, pilih **Keep Defender** di halaman opsi — satu klik. Untuk PC harian, kami sarankan tetap mengaktifkan Defender.

Mematikan UAC juga bisa mengganggu login Microsoft Account.

## Mengembalikan

Tidak ada uninstaller otomatis:

- **System Restore** (kalau kamu bikin restore point sebelumnya)
- **Windows Reset** — hasil paling bersih
- **Manual** — nama service dan key registry terlihat di `main.yml`

Menjalankan playbook ulang dan memilih **Keep Defender** akan mengaktifkan Windows Security kembali.

## Build dari source

```powershell
git clone https://github.com/wakgimang11t-bot/ANCX777.git
cd ANCX777
./src/dependencies/New-Playbook.ps1
```

Hasil: `src/release-zip/ANCX777.apbx` + `.sha256`. Butuh 7-Zip di PATH.

## Kontribusi

Baca [CONTRIBUTING.md](CONTRIBUTING.md). Tweaks, perbaikan bug, dan dokumentasi semuanya diterima.

## Lisensi

[GPL-3.0](LICENSE) — sama seperti AtlasOS.
