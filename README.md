# Kuesioner Online

Website kuesioner publik: responden bisa mengisi kuesioner lewat link, sedangkan pengelolaan kuesioner dan hasilnya membutuhkan login.

**Stack:** Vue 3 · Vite · Supabase (PostgreSQL) · Chart.js · Vercel · GitHub

## Fitur

- Buat kuesioner dengan 3 jenis pertanyaan: pilihan (pilih satu), rating 1–5, dan teks bebas
- Link isian publik: `/isi/:id`
- Login hardcode untuk pengelola: `admin` / `admin123`
- Halaman hasil dan edit kuesioner hanya untuk pengguna yang sudah login
- Halaman hasil: `/hasil/:id` — total responden, grafik batang per pertanyaan, rata-rata rating, daftar jawaban teks
- Kuesioner yang sudah dibuat dapat diedit lewat tombol `Edit`
- Tombol unduh seluruh data kuesioner untuk Excel (`.csv`) tersedia di halaman hasil
- Hasil menyegarkan otomatis tiap 20 detik
- Nama responden **tidak** bisa dibaca dari API publik (hanya dari dashboard Supabase)

## 1. Siapkan Supabase

1. Buat akun & project baru di [supabase.com](https://supabase.com).
2. Buka **SQL Editor → New query**, tempel seluruh isi `supabase/schema.sql`, lalu **Run**.
3. Buka **Project Settings → API**, salin:
   - **Project URL**
   - **anon / publishable key** (aman dipakai di frontend karena dibatasi RLS)

## 2. Jalankan di komputer

```bash
npm install
cp .env.example .env     # lalu isi URL dan key dari Supabase
npm run dev
```

Buka http://localhost:5173

## 3. Upload ke GitHub

```bash
git init
git add .
git commit -m "Kuesioner online"
git branch -M main
git remote add origin https://github.com/USERNAME/NAMA-REPO.git
git push -u origin main
```

File `.env` sudah masuk `.gitignore`, jadi tidak ikut ter-upload.

## 4. Deploy ke Vercel

1. Masuk ke [vercel.com](https://vercel.com) → **Add New → Project** → import repo GitHub tadi.
2. Framework otomatis terdeteksi sebagai **Vite**.
3. Di **Environment Variables**, tambahkan:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
4. Klik **Deploy**. Setiap `git push` ke `main` akan otomatis deploy ulang.

`vercel.json` sudah mengatur agar link seperti `/isi/xxxx` tetap terbuka saat di-refresh.

## Struktur

```
supabase/schema.sql        skema tabel + aturan keamanan (RLS)
src/supabase.js            koneksi Supabase
src/router.js              rute halaman
src/views/                 Home, Buat, Isi, Hasil
src/components/ChartCanvas.vue   pembungkus Chart.js
```

## Catatan keamanan

- Login saat ini sengaja dibuat hardcode di frontend sesuai kebutuhan aplikasi. Ini hanya pembatasan akses antarmuka dan **bukan autentikasi aman untuk produksi** karena kredensial dapat dilihat dari source code dan sesi dapat dimanipulasi dari browser.
- Policy update/delete di `supabase/schema.sql` diperlukan agar fitur edit bekerja, tetapi policy tersebut juga masih bersifat publik. Untuk keamanan sebenarnya, gunakan Supabase Auth dan RLS berbasis `auth.uid()`/pemilik kuesioner.
- Belum ada perlindungan spam/bot. Jika nanti ramai, pertimbangkan Cloudflare Turnstile atau mewajibkan login untuk pembuat kuesioner.
