README.md

```markdown
# XDTunnel API

> Async REST API wrapper untuk CLI `addusr` — mengelola user **VMess, VLESS, Trojan, Shadowsocks, dan SSH** dari satu endpoint HTTP.

[![Python](https://img.shields.io/badge/Python-3.9%2B-blue)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100%2B-009688)](https://fastapi.tiangolo.com/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📖 Daftar Isi

- [Fitur](#-fitur)
- [Arsitektur](#-arsitektur)
- [Instalasi](#-instalasi)
- [Konfigurasi (ENV)](#-konfigurasi-env)
- [Menjalankan Server](#-menjalankan-server)
- [Autentikasi](#-autentikasi)
- [Endpoint API](#-endpoint-api)
- [Contoh Pemakaian](#-contoh-pemakaian)
- [Format Response](#-format-response)
- [Systemd Service](#-systemd-service)
- [Docker](#-docker)
- [Troubleshooting](#-troubleshooting)
- [Credit](#-credit)

---

## ✨ Fitur

- ⚡ **Async native** — semua command dijalankan lewat `asyncio.create_subprocess_exec`
- 🔐 **API key auth** — header `X-API-Key` atau query param `?api_key=`
- 🌍 **Full ENV config** — tidak ada file konfigurasi tambahan, semua dari environment variable
- ✅ **Whitelist protocol** — hanya tipe yang diizinkan yang bisa diproses
- 🛡️ **Timeout protection** — subprocess dibatasi agar tidak hang
- 📋 **14 endpoint** — cover semua operasi CRUD user
- 📚 **Auto-docs** — Swagger UI & ReDoc tersedia gratis
- 🐳 **Portable** — bisa jalan di systemd, Docker, Podman, pm2, supervisord

---

## 🏗️ Arsitektur

```

┌──────────────────────────────┐
│  Client (curl / Postman)     │
│  GET /create?type=vmess&...  │
└──────────────┬───────────────┘
│  HTTP + X-API-Key
▼
┌──────────────────────────────┐
│  FastAPI (Uvicorn)           │
│  ─ require_api_key()         │
│  ─ validate_type()           │
│  ─ _safe_run()               │
└──────────────┬───────────────┘
│  subprocess
▼
┌──────────────────────────────┐
│  CLI: addusr                 │
│  ─ add / delete / lock ...   │
│  ─ akses SQLite users.db     │
│  ─ akses xray-cli / useradd  │
└──────────────┬───────────────┘
│  JSON
▼
┌──────────────────────────────┐
│  style_api_response()        │
│  (envelope JSON konsisten)   │
└──────────────────────────────┘

```

---

## 🚀 Instalasi

### Cara 1 — Otomatis via Script

```bash
bash <(curl -sL https://raw.githubusercontent.com/g9ktx7lm/api/main/api.sh)
```

Pilih menu 1. Install Service API.

Cara 2 — Manual

```bash
# 1. Dependency
apt update
apt install -y python3 python3-pip python3-venv wget curl

# 2. Virtual environment
mkdir -p /etc/api
python3 -m venv /etc/api/env
source /etc/api/env/bin/activate

# 3. Install library
pip install --upgrade pip
pip install fastapi "uvicorn[standard]"
deactivate

# 4. Ambil file
wget -O /etc/api/api.py  https://raw.githubusercontent.com/g9ktx7lm/api/main/api.py
wget -O /usr/sbin/addusr https://raw.githubusercontent.com/g9ktx7lm/api/main/addusr
chmod +x /usr/sbin/addusr

# 5. Buat api.env
cat > /etc/api/api.env <<EOF
XDT_API_KEY=$(cat /proc/sys/kernel/random/uuid)
XDT_PORT=1108
XDT_CLI=addusr
EOF
chmod 600 /etc/api/api.env

# 6. Jalankan
/etc/api/env/bin/python3 /etc/api/api.py
```

---

⚙️ Konfigurasi (ENV)

Semua konfigurasi dibaca dari environment variable. Di produksi, taruh di /etc/api/api.env (chmod 600).

Wajib

Variable Wajib Default Keterangan
XDT_API_KEY ✅ — API key untuk autentikasi. Kalau kosong, service gagal start.

Opsional

Variable Default Keterangan
XDT_API_KEY_HEADER X-API-Key Nama header API key
XDT_API_KEY_QUERY api_key Nama query param API key
XDT_CLI addusr Nama binary CLI
XDT_CLI_TIMEOUT 20 Timeout subprocess (detik)
XDT_CLI_CWD (kosong) Working directory subprocess
XDT_HOST 0.0.0.0 Bind host
XDT_PORT 2010 Bind port
XDT_WORKERS 1 Jumlah worker Uvicorn
XDT_LOG_LEVEL info Level log (debug/info/warning/error)
XDT_TITLE XDTunnel API Judul Swagger
XDT_VERSION 1.0.0 Versi API
XDT_ALLOWED_ALL_TYPES ssh,vmess,vless,trojan,shadowsocks,ss Whitelist type (CSV)
XDT_ALLOWED_XRAY_TYPES vmess,vless,trojan,shadowsocks,ss Whitelist Xray (CSV)

Contoh /etc/api/api.env

```env
# --- Auth ---
XDT_API_KEY=5a3b8c2d-1e4f-...
XDT_API_KEY_HEADER=X-API-Key
XDT_API_KEY_QUERY=api_key

# --- CLI ---
XDT_CLI=addusr
XDT_CLI_TIMEOUT=20

# --- Server ---
XDT_HOST=0.0.0.0
XDT_PORT=1108
XDT_WORKERS=1
XDT_LOG_LEVEL=info

# --- Metadata ---
XDT_TITLE=XDTunnel API
XDT_VERSION=1.0.0

# --- Whitelist ---
XDT_ALLOWED_ALL_TYPES=ssh,vmess,vless,trojan,shadowsocks,ss
XDT_ALLOWED_XRAY_TYPES=vmess,vless,trojan,shadowsocks,ss
```

---

▶️ Menjalankan Server

Development

```bash
python3 api.py
```

Produksi (langsung)

```bash
export XDT_API_KEY="rahasia123"
export XDT_PORT=1108
uvicorn api:app --host 0.0.0.0 --port 1108 --workers 2
```

Produksi (systemd)

Lihat Systemd Service.

---

🔐 Autentikasi

Semua endpoint wajib menyertakan API key. Ada 2 cara:

1. Header (direkomendasikan)

```bash
curl -H "X-API-Key: rahasia123" http://127.0.0.1:1108/member?type=vmess
```

2. Query Param

```bash
curl "http://127.0.0.1:1108/member?type=vmess&api_key=rahasia123"
```

Kode Response

Kode Arti
200 Sukses
400 Parameter kurang / tidak valid
401 API key tidak disertakan
403 API key salah
500 Error eksekusi CLI
503 API key server tidak dikonfigurasi
504 CLI timeout

---

🌐 Endpoint API

Base URL default: http://127.0.0.1:1108

Method Endpoint Deskripsi Parameter
GET / Info API + daftar endpoint —
GET /docs Swagger UI —
GET /redoc ReDoc —
GET /create Buat user baru type, username, [password], [quota], iplimit, masaaktif
GET /custom_uuid Buat user dengan UUID/pass custom type, username, quota, iplimit, masaaktif, secret
GET /trial Buat akun trial type, [quota], iplimit, waktu
GET /member List semua user type
GET /delete Hapus user type, username
GET /lock Kunci user type, username
GET /unlock Buka kunci user type, username
GET /edit_limit Ubah limit IP type, username, limit
GET /edit_quota Ubah quota (Xray only) type, username, quota
GET /renew Perpanjang masa aktif type, username, days
GET /ganti_uuid Ganti UUID/password type, username, [secret]
GET /cek_config Detail config user type, username
GET /cek_login List user online type
GET /recovery Pulihkan user yang dihapus type, username, [opsional...]

Type yang Didukung

Nilai Alias Keterangan
vmess vma, vm VMess
vless vla, vl VLESS
trojan tra, tr Trojan
shadowsocks ss, ssa Shadowsocks
ssh — SSH (Linux user)

---

💡 Contoh Pemakaian

1. Buat user VMess (quota 50GB, 2 IP, 30 hari)

```bash
curl -H "X-API-Key: rahasia123" \
  "http://127.0.0.1:1108/create?type=vmess&username=budi&quota=50&iplimit=2&masaaktif=30"
```

2. Buat user SSH

```bash
curl -H "X-API-Key: rahasia123" \
  "http://127.0.0.1:1108/create?type=ssh&username=ani&password=12345&iplimit=1&masaaktif=30"
```

3. Buat user dengan UUID custom

```bash
curl -H "X-API-Key: rahasia123" \
  "http://127.0.0.1:1108/custom_uuid?type=vless&username=citra&quota=10&iplimit=2&masaaktif=30&secret=abc-123-def"
```

4. Trial akun 60 menit

```bash
curl -H "X-API-Key: rahasia123" \
  "http://127.0.0.1:1108/trial?type=trojan&quota=1&iplimit=1&waktu=60"
```

5. List semua user VMess

```bash
curl -H "X-API-Key: rahasia123" \
  "http://127.0.0.1:1108/member?type=vmess"
```

6. Cek user online VLESS

```bash
curl -H "X-API-Key: rahasia123" \
  "http://127.0.0.1:1108/cek_login?type=vless"
```

7. Lock user

```bash
curl -H "X-API-Key: rahasia123" \
  "http://127.0.0.1:1108/lock?type=vmess&username=budi"
```

8. Perpanjang 30 hari

```bash
curl -H "X-API-Key: rahasia123" \
  "http://127.0.0.1:1108/renew?type=vmess&username=budi&days=30"
```

9. Hapus user

```bash
curl -H "X-API-Key: rahasia123" \
  "http://127.0.0.1:1108/delete?type=vmess&username=budi"
```

10. Ganti UUID (auto-generate)

```bash
curl -H "X-API-Key: rahasia123" \
  "http://127.0.0.1:1108/ganti_uuid?type=vmess&username=budi"
```

---

📦 Format Response

Sukses

```json
{
  "status": true,
  "statusCode": 200,
  "message": "User vmess 'budi' berhasil dibuat",
  "format_text": "...",
  "data": {
    "username": "budi",
    "expired": "2026-11-06",
    "quota_bytes": 53687091200,
    "quota_human": "50 GB",
    "iplimit": 2,
    "status": "active",
    "link": "vmess://..."
  }
}
```

Error

```json
{
  "status": false,
  "statusCode": 400,
  "message": "Parameter wajib tidak ada: username, quota"
}
```

Format ini otomatis dari CLI addusr — API hanya meneruskan apa adanya.

---

🔧 Systemd Service

/etc/systemd/system/xdapi.service

```ini
[Unit]
Description=XDTunnel API (FastAPI)
After=network.target

[Service]
Type=simple
WorkingDirectory=/etc/api/
EnvironmentFile=/etc/api/api.env
ExecStart=/etc/api/env/bin/python3 /etc/api/api.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Perintah Dasar

```bash
systemctl daemon-reload
systemctl enable xdapi
systemctl start xdapi

# Lihat status
systemctl status xdapi

# Lihat log realtime
journalctl -u xdapi -f

# Restart
systemctl restart xdapi

# Stop
systemctl stop xdapi

# Hapus
systemctl disable xdapi
rm /etc/systemd/system/xdapi.service
systemctl daemon-reload
```

---

🐳 Docker

Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir fastapi "uvicorn[standard]"

COPY api.py .

EXPOSE 1108

CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "1108"]
```

Build & Run

```bash
docker build -t xdtunnel-api .

docker run -d \
  --name xdtunnel-api \
  --restart unless-stopped \
  -p 1108:1108 \
  -v /etc/xray:/etc/xray \
  -v /usr/sbin/addusr:/usr/sbin/addusr:ro \
  -e XDT_API_KEY=rahasia123 \
  -e XDT_PORT=1108 \
  -e XDT_CLI=addusr \
  xdtunnel-api
```

docker-compose.yml

```yaml
version: "3.9"
services:
  api:
    build: .
    container_name: xdtunnel-api
    restart: unless-stopped
    ports:
      - "1108:1108"
    volumes:
      - /etc/xray:/etc/xray
      - /usr/sbin/addusr:/usr/sbin/addusr:ro
    environment:
      XDT_API_KEY: rahasia123
      XDT_PORT: 1108
      XDT_CLI: addusr
      XDT_LOG_LEVEL: info
```

---

🔍 Troubleshooting

Service gagal start

```bash
journalctl -u xdapi -n 50 --no-pager
```

Penyebab umum:

· XDT_API_KEY belum diset → RuntimeError
· Port sudah dipakai → ganti XDT_PORT
· File addusr tidak ada / tidak executable

Perintah 'addusr' tidak ditemukan

```bash
which addusr                    # harus ada
ls -la /usr/sbin/addusr        # harus executable
chmod +x /usr/sbin/addusr      # fix permission
```

Timeout

Naikkan di api.env:

```env
XDT_CLI_TIMEOUT=60
```

Cek port terpakai

```bash
ss -tlnp | grep 1108
```

Cek manual dari dalam venv

```bash
source /etc/api/env/bin/activate
export $(cat /etc/api/api.env | xargs)
python3 /etc/api/api.py
```

Test endpoint cepat

```bash
source /etc/api/api.env
curl -H "X-API-Key: $XDT_API_KEY" "http://127.0.0.1:$XDT_PORT/"
```

---

📂 Struktur Direktori

```
/etc/api/
├── api.env          ← semua konfigurasi (ENV)
├── api.py           ← kode FastAPI
└── env/             ← Python virtual environment

/usr/sbin/
└── addusr           ← CLI binary

/etc/systemd/system/
└── xdapi.service    ← systemd unit
```

---

🔒 Keamanan

Yang Sudah Diterapkan

· ✅ Subprocess dipanggil tanpa shell=True (aman dari shell injection)
· ✅ Whitelist type (hanya nilai yang diizinkan)
· ✅ Timeout subprocess (anti DoS)
· ✅ API key via ENV (tidak ada di source code)
· ✅ Format JSON konsisten (tidak bocorkan stack trace ke client)

Rekomendasi Tambahan

1. Bind ke localhost kalau di belakang reverse proxy:
   ```env
   XDT_HOST=127.0.0.1
   ```
2. Pakai HTTPS via Nginx + Let's Encrypt:
   ```nginx
   server {
       listen 443 ssl http2;
       server_name api.example.com;
   
       ssl_certificate     /etc/letsencrypt/live/api.example.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/api.example.com/privkey.pem;
   
       location / {
           proxy_pass http://127.0.0.1:1108;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```
3. Firewall — hanya buka port yang perlu:
   ```bash
   ufw allow 22/tcp
   ufw allow 443/tcp
   ufw deny 1108
   ```
4. Rate limiting via Nginx:
   ```nginx
   limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
   location / {
       limit_req zone=api burst=20 nodelay;
       proxy_pass http://127.0.0.1:1108;
   }
   ```
5. Rotate API key berkala via menu API (6. Change Or Regenerate Key).

---

📜 License

MIT License — bebas dipakai & dimodifikasi.

---

💚 Credit

· XDTunnel — Telegram | WhatsApp
· Dibangun dengan FastAPI & Uvicorn

---

⭐ Kalau project ini bermanfaat, jangan lupa bintang!

```

---

## Ringkasan Isi README

| Section | Isi |
|---|---|
| **Fitur** | Highlight utama (async, ENV, auto-docs, dll.) |
| **Arsitektur** | Diagram alur client → API → CLI → DB |
| **Instalasi** | 2 cara: otomatis (script) & manual |
| **Konfigurasi** | Tabel lengkap semua ENV + contoh `api.env` |
| **Menjalankan** | Dev / Prod / systemd |
| **Autentikasi** | Header vs query, tabel kode response |
| **Endpoint** | Tabel semua 14 endpoint + alias type |
| **Contoh** | 10 contoh curl siap copy-paste |
| **Response** | Format JSON sukses & error |
| **Systemd** | Unit file + perintah dasar |
| **Docker** | Dockerfile + compose + perintah run |
| **Troubleshooting** | Masalah umum & solusinya |
| **Struktur** | Layout direktori |
| **Keamanan** | Yang sudah ada + rekomendasi Nginx/firewall/rate limit |
| **Credit** | Info kontak |

README-nya sudah **self-contained** — tinggal simpan sebagai `README.md` di root repo, dan siap ditampilkan di GitHub.
