# 📡 API Documentation — VPN Account Manager

Base URL: `http://<server-ip>:1108`

Autentikasi menggunakan **API Key** yang disimpan di `/etc/api/.api.db`.  
Key dikirim via header **atau** query param.

```
Header  : X-API-Key: <api_key>
Query   : ?api_key=<api_key>
```

---

## 🔐 Autentikasi

Semua endpoint **wajib** menyertakan API key.

| Status | Kode | Keterangan |
|--------|------|------------|
| ✅ Valid | — | Request dilanjutkan |
| ❌ Tidak ada key | 401 | Wajib sertakan API key |
| ❌ Key salah | 403 | API key tidak valid |
| ❌ File tidak ada | 503 | Konfigurasi server bermasalah |

---

## 📌 Endpoint

### 1. `GET /ssh/create` — Buat Akun SSH

**Query Parameters:**

| Parameter | Tipe | Wajib | Keterangan |
|-----------|------|-------|------------|
| `api_key` | string | ✅ | API key (atau via header) |
| `username` | string | ✅ | Huruf, angka, underscore |
| `password` | string | ✅ | Password akun SSH |
| `iplimit` | integer | ✅ | Maks perangkat terhubung (`0` = unlimited) |
| `masaaktif` | integer | ✅ | Lama aktif dalam hari |

**Contoh Request:**
```
GET /ssh/create?api_key=xxx&username=john&password=pass123&iplimit=2&masaaktif=30
```

**Contoh Response (200):**
```json
{
  "status": true,
  "statusCode": 200,
  "message": "SUCCESS",
  "data": {
    "username": "john",
    "password": "pass123",
    "expired": "2026-08-11",
    "iplimit": "2"
  }
}
```

---

### 2. `GET /ssh/trial` — Buat Akun SSH Trial

**Query Parameters:**

| Parameter | Tipe | Wajib | Keterangan |
|-----------|------|-------|------------|
| `api_key` | string | ✅ | API key (atau via header) |
| `iplimit` | integer | ✅ | Maks perangkat terhubung |
| `waktu` | integer | ✅ | Durasi trial dalam **menit** |

**Contoh Request:**
```
GET /ssh/trial?api_key=xxx&iplimit=1&waktu=60
```

**Contoh Response (200):**
```json
{
  "status": true,
  "statusCode": 200,
  "message": "SUCCESS",
  "data": {
    "username": "trial-4821",
    "password": "1",
    "expired": "2026-07-13",
    "iplimit": "1",
    "waktu": "60 menit"
  }
}
```

---

### 3. `GET /create` — Buat Akun Xray (VMess / VLess / Trojan)

**Query Parameters:**

| Parameter | Tipe | Wajib | Keterangan |
|-----------|------|-------|------------|
| `api_key` | string | ✅ | API key (atau via header) |
| `type` | string | ✅ | `vmess` / `vless` / `trojan` |
| `username` | string | ✅ | Huruf, angka, underscore |
| `quota` | integer | ✅ | Kuota dalam GB (`0` = unlimited) |
| `iplimit` | integer | ✅ | Maks perangkat terhubung |
| `masaaktif` | integer | ✅ | Lama aktif dalam hari |

**Contoh Request:**
```
GET /create?api_key=xxx&type=vmess&username=john&quota=10&iplimit=2&masaaktif=30
```

**Contoh Response (200):**
```json
{
  "status": true,
  "statusCode": 200,
  "message": "SUCCESS",
  "data": {
    "username": "john",
    "expired": "2026-08-11",
    "quota": "10 GB",
    "iplimit": "2",
    "vmesslink": "vmess://..."
  }
}
```

---

### 4. `GET /trial` — Buat Akun Xray Trial (VMess / VLess / Trojan)

**Query Parameters:**

| Parameter | Tipe | Wajib | Keterangan |
|-----------|------|-------|------------|
| `api_key` | string | ✅ | API key (atau via header) |
| `type` | string | ✅ | `vmess` / `vless` / `trojan` |
| `quota` | integer | ✅ | Kuota dalam GB |
| `iplimit` | integer | ✅ | Maks perangkat terhubung |
| `waktu` | integer | ✅ | Durasi trial dalam **menit** |

**Contoh Request:**
```
GET /trial?api_key=xxx&type=vless&quota=5&iplimit=1&waktu=60
```

**Contoh Response (200):**
```json
{
  "status": true,
  "statusCode": 200,
  "message": "SUCCESS",
  "data": {
    "username": "trial-3917",
    "expired": "2026-07-13",
    "quota": "5 GB",
    "iplimit": "1",
    "waktu": "60 menit",
    "vlesslink": "vless://..."
  }
}
```

---

### 5. `GET /member` — Daftar Member Aktif

**Query Parameters:**

| Parameter | Tipe | Wajib | Keterangan |
|-----------|------|-------|------------|
| `key` | string | ✅ | API key (atau via header `X-API-Key`) |
| `type` | string | ✅ | `ssh` / `vmess` / `vless` / `trojan` |

**Contoh Request:**
```
GET /member?key=xxx&type=ssh
```

**Contoh Response (200):**
```json
{
  "status": true,
  "statusCode": 200,
  "message": "SUCCESS",
  "data": [
    { "no": 1, "username": "john", "expired": "2026-08-11", "status": "unlocked", "usage": "2GB" },
    { "no": 2, "username": "jane", "expired": "2026-07-20", "status": "locked",   "usage": "0" }
  ]
}
```

---

### 6. `GET /delete` — Hapus Akun

**Query Parameters:**

| Parameter | Tipe | Wajib | Keterangan |
|-----------|------|-------|------------|
| `api_key` | string | ✅ | API key (atau via header) |
| `type` | string | ✅ | `ssh` / `vmess` / `vless` / `trojan` |
| `username` | string | ✅ | Username yang akan dihapus |

**Contoh Request:**
```
GET /delete?api_key=xxx&type=vmess&username=john
```

**Contoh Response (200):**
```json
{
  "status": true,
  "statusCode": 200,
  "message": "SUCCESS",
  "data": {
    "username": "john",
    "expired": "2026-08-11"
  }
}
```

---

## ❌ Error Responses Umum

| Status Code | Keterangan |
|-------------|------------|
| `400` | Parameter kurang atau tidak valid |
| `401` | API key tidak disertakan |
| `403` | API key salah |
| `404` | Username tidak ditemukan |
| `409` | Username sudah terdaftar |
| `500` | Kesalahan server internal |
| `503` | Konfigurasi server bermasalah |

**Contoh Error (400):**
```json
{
  "status": false,
  "statusCode": 400,
  "message": "Parameter wajib tidak ada: username, iplimit"
}
```

---

## 📋 Ringkasan Endpoint

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| GET | `/ssh/create` | ✅ | Buat akun SSH |
| GET | `/ssh/trial` | ✅ | Buat akun SSH trial |
| GET | `/create` | ✅ | Buat akun VMess / VLess / Trojan |
| GET | `/trial` | ✅ | Trial akun VMess / VLess / Trojan |
| GET | `/member` | ✅ | Lihat daftar member |
| GET | `/delete` | ✅ | Hapus akun |

---

## ⚙️ Instalasi & Menjalankan

```bash
apt update && apt install wget curl -y && [ -f /usr/sbin/menu-api ] && rm -f /usr/sbin/menu-api && wget -O /usr/sbin/menu-api "https://raw.githubusercontent.com/g9ktx7lm/api/main/api.sh" && chmod +x /usr/sbin/menu-api && menu-api
```

Jalankan via systemd service (environment di-set dari service unit, port bisa di custom):

```ini
[Service]
ExecStart=/usr/bin/python3 /etc/api/api.py
Environment=PORT=1108
```

---

## 👤 Credit

**Dibuat oleh:** XDXL STR

| Platform | Kontak |
|----------|--------|
| 📱 Telegram | [t.me/xdxlreal](https://t.me/xdxlreal) |
| 💬 WhatsApp | [wa.me/6285935195701](https://wa.me/6285935195701) |
