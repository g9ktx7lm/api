import asyncio
import json
import shlex
import os

from quart import Quart, jsonify, request

app = Quart(__name__)
app.json.ensure_ascii = False

ALLOWED_ALL_TYPES = {"ssh", "vmess", "vless", "trojan"}
ALLOWED_XRAY_TYPES = {"vmess", "vless", "trojan"}
API_DB_PATH = "/etc/api/.api.db"

async def run_m_api(*args: str):
    cmd = ["m_api", *args]
    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await proc.communicate()
    return (
        proc.returncode,
        stdout.decode("utf-8", errors="replace").strip(),
        stderr.decode("utf-8", errors="replace").strip(),
        shlex.join(cmd),
    )


def build_response(returncode, stdout, stderr, cmd):
    """
    Output sbot sudah JSON lengkap dari style_api_* (status, statusCode,
    message, format_text, data) — langsung parse dan kembalikan apa adanya.
    """
    if returncode == 0:
        try:
            data = json.loads(stdout)
            return jsonify(data), data.get("statusCode", 200)
        except (json.JSONDecodeError, ValueError):
            return jsonify({
                "status":     True,
                "statusCode": 200,
                "message": "FAILED",
                "output":     stdout,
            }), 200
    else:
        try:
            data = json.loads(stdout)
            return jsonify(data), data.get("statusCode", 500)
        except (json.JSONDecodeError, ValueError):
            return jsonify({
                "status":     False,
                "statusCode": 500,
                "message":    stderr or stdout,
            }), 500

def missing_params(**kwargs):
    """Kembalikan list nama parameter yang nilainya None."""
    return [k for k, v in kwargs.items() if v is None]

def check_api_key(incoming_key: str | None):
    try:
        with open(API_DB_PATH, "r") as f:
            parts = f.read().strip().split()
            api_key = parts[1] if len(parts) >= 2 else None
    except FileNotFoundError:
        return {"status": False, "statusCode": 503, "message": "File konfigurasi API tidak ditemukan."}, 503
    except Exception:
        return {"status": False, "statusCode": 503, "message": "Gagal membaca file konfigurasi API."}, 503

    if not api_key:
        return {"status": False, "statusCode": 503, "message": "API key belum dikonfigurasi di server."}, 503

    if not incoming_key:
        return {"status": False, "statusCode": 401, "message": "API key wajib disertakan via header 'X-API-Key' atau query param '?key='."}, 401

    if incoming_key != api_key:
        return {"status": False, "statusCode": 403, "message": "API key tidak valid."}, 403

    return None

@app.route("/ssh/create", methods=["GET"])
async def create_ssh():
    incoming_key = request.headers.get("X-API-Key") or request.args.get("api_key")
    
    err = check_api_key(incoming_key)
    if err:
        body, code = err
        return jsonify(body), code
    
    username  = request.args.get("username")
    password  = request.args.get("password")
    iplimit   = request.args.get("iplimit")
    masaaktif = request.args.get("masaaktif")

    miss = missing_params(username=username, password=password, iplimit=iplimit, masaaktif=masaaktif)
    if miss:
        return jsonify({"status": False, "statusCode": 400, "message": f"Parameter wajib tidak ada: {', '.join(miss)}"}), 400

    try:
        rc, out, err, cmd = await run_m_api("create", "ssh", username, password, iplimit, masaaktif)
        return build_response(rc, out, err, cmd)
    except FileNotFoundError:
        return jsonify({"status": False, "statusCode": 500, "message": "Perintah 'm_api' tidak ditemukan."}), 500
    except Exception as e:
        return jsonify({"status": False, "statusCode": 500, "message": str(e)}), 500


@app.route("/ssh/trial", methods=["GET"])
async def trial_ssh():
    incoming_key = request.headers.get("X-API-Key") or request.args.get("api_key")

    err = check_api_key(incoming_key)
    if err:
        body, code = err
        return jsonify(body), code
    
    iplimit = request.args.get("iplimit")
    waktu   = request.args.get("waktu")

    miss = missing_params(iplimit=iplimit, waktu=waktu)
    if miss:
        return jsonify({"status": False, "statusCode": 400, "message": f"Parameter wajib tidak ada: {', '.join(miss)}"}), 400

    try:
        rc, out, err, cmd = await run_m_api("trial", "ssh", iplimit, waktu)
        return build_response(rc, out, err, cmd)
    except FileNotFoundError:
        return jsonify({"status": False, "statusCode": 500, "message": "Perintah 'm_api' tidak ditemukan."}), 500
    except Exception as e:
        return jsonify({"status": False, "statusCode": 500, "message": str(e)}), 500

@app.route("/create", methods=["GET"])
async def create_xray():
    incoming_key = request.headers.get("X-API-Key") or request.args.get("api_key")
    err = check_api_key(incoming_key)
    if err:
        body, code = err
        return jsonify(body), code

    service = request.args.get("type")

    if not service:
        return jsonify({"status": False, "statusCode": 400, "message": "Parameter 'type' wajib disertakan. Pilihan: vmess, vless, trojan."}), 400

    if service not in ALLOWED_XRAY_TYPES:
        return jsonify({"status": False, "statusCode": 400, "message": f"Type '{service}' tidak valid. Pilihan: {', '.join(sorted(ALLOWED_XRAY_TYPES))}."}), 400

    username  = request.args.get("username")
    quota     = request.args.get("quota")
    iplimit   = request.args.get("iplimit")
    masaaktif = request.args.get("masaaktif")

    miss = missing_params(username=username, quota=quota, iplimit=iplimit, masaaktif=masaaktif)
    if miss:
        return jsonify({"status": False, "statusCode": 400, "message": f"Parameter wajib tidak ada: {', '.join(miss)}"}), 400

    try:
        rc, out, err, cmd = await run_m_api("create", service, username, quota, iplimit, masaaktif)
        return build_response(rc, out, err, cmd)
    except FileNotFoundError:
        return jsonify({"status": False, "statusCode": 500, "message": "Perintah 'm_api' tidak ditemukan."}), 500
    except Exception as e:
        return jsonify({"status": False, "statusCode": 500, "message": str(e)}), 500


@app.route("/trial", methods=["GET"])
async def trial_xray():
    incoming_key = request.headers.get("X-API-Key") or request.args.get("api_key")
    err = check_api_key(incoming_key)
    if err:
        body, code = err
        return jsonify(body), code

    service = request.args.get("type")

    if not service:
        return jsonify({"status": False, "statusCode": 400, "message": "Parameter 'type' wajib disertakan. Pilihan: vmess, vless, trojan."}), 400

    if service not in ALLOWED_XRAY_TYPES:
        return jsonify({"status": False, "statusCode": 400, "message": f"Type '{service}' tidak valid. Pilihan: {', '.join(sorted(ALLOWED_XRAY_TYPES))}."}), 400

    quota   = request.args.get("quota")
    iplimit = request.args.get("iplimit")
    waktu   = request.args.get("waktu")

    miss = missing_params(quota=quota, iplimit=iplimit, waktu=waktu)
    if miss:
        return jsonify({"status": False, "statusCode": 400, "message": f"Parameter wajib tidak ada: {', '.join(miss)}"}), 400

    try:
        rc, out, err, cmd = await run_m_api("trial", service, quota, iplimit, waktu)
        return build_response(rc, out, err, cmd)
    except FileNotFoundError:
        return jsonify({"status": False, "statusCode": 500, "message": "Perintah 'm_api' tidak ditemukan."}), 500
    except Exception as e:
        return jsonify({"status": False, "statusCode": 500, "message": str(e)}), 500

@app.route("/member", methods=["GET"])
async def member():
    incoming_key = request.headers.get("X-API-Key") or request.args.get("api_key")
    err = check_api_key(incoming_key)
    if err:
        body, code = err
        return jsonify(body), code

    service = request.args.get("type")

    if not service:
        return jsonify({
            "status": False,
            "statusCode": 400,
            "message": "Parameter 'type' wajib disertakan. Pilihan: ssh, vmess, vless, trojan.",
        }), 400

    if service not in ALLOWED_ALL_TYPES:
        return jsonify({
            "status":     False,
            "statusCode": 400,
            "message":    f"Type '{service}' tidak valid. Pilihan: {', '.join(sorted(ALLOWED_ALL_TYPES))}.",
        }), 400

    try:
        rc, out, err, cmd = await run_m_api("member", service)
        return build_response(rc, out, err, cmd)
    except FileNotFoundError:
        return jsonify({"status": False, "statusCode": 500, "message": "Perintah 'sbot' tidak ditemukan."}), 500
    except Exception as e:
        return jsonify({"status": False, "statusCode": 500, "message": str(e)}), 500

@app.route("/delete", methods=["GET"])
async def delete_account():
    incoming_key = request.headers.get("X-API-Key") or request.args.get("api_key")
    err = check_api_key(incoming_key)
    if err:
        body, code = err
        return jsonify(body), code

    service  = request.args.get("type")
    username = request.args.get("username")

    if not service:
        return jsonify({"status": False, "statusCode": 400, "message": "Parameter 'type' wajib disertakan. Pilihan: ssh, vmess, vless, trojan."}), 400

    if service not in ALLOWED_ALL_TYPES:
        return jsonify({"status": False, "statusCode": 400, "message": f"Type '{service}' tidak valid. Pilihan: {', '.join(sorted(ALLOWED_ALL_TYPES))}."}), 400

    if not username:
        return jsonify({"status": False, "statusCode": 400, "message": "Parameter 'username' wajib disertakan."}), 400

    try:
        rc, out, err, cmd = await run_m_api("delete", service, username)
        return build_response(rc, out, err, cmd)
    except FileNotFoundError:
        return jsonify({"status": False, "statusCode": 500, "message": "Perintah 'm_api' tidak ditemukan."}), 500
    except Exception as e:
        return jsonify({"status": False, "statusCode": 500, "message": str(e)}), 500

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.getenv("PORT", 2010)),
        debug=False
    )
