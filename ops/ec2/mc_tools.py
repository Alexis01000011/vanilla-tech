#!/usr/bin/env python3
"""Helpers for the EC2 deploy scripts. Python 3.9 (Amazon Linux 2023), stdlib only.

  mc_tools.py mrpack-info MRPACK [--expect-version V] [--expect-neoforge X]
  mc_tools.py prefetch MRPACK CACHE_DIR [DATA]    download + verify every server file not already
                                                  installed in DATA with the same sha512
  mc_tools.py verify-mods MRPACK DATA_DIR         installed mods == release server mods
  mc_tools.py wait-ready LOG SINCE_EPOCH TIMEOUT  wait for "Done (" in a log newer than SINCE
  mc_tools.py slp HOST PORT                       Server List Ping (JSON)
  mc_tools.py rcon HOST PORT PASSWORD CMD...      minimal RCON client (local tests)
  mc_tools.py players TEXT                        parse `list` output -> count
  mc_tools.py quiescent DIR SECONDS               nobody holds files open in DIR, mtimes stable
  mc_tools.py vercmp A B                          prints -1, 0 or 1
  mc_tools.py snapshot-meta OUT key=value...      write a JSON file (values JSON or strings)
"""
import concurrent.futures, hashlib, json, os, pathlib, re, socket, struct, sys, time, urllib.request, zipfile

ALLOWED_HOSTS = ("cdn.modrinth.com", "edge.forgecdn.net", "mediafilez.forgecdn.net", "github.com")
VERSION_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(-(alpha|beta|rc)\.[0-9]+)?$")
CRASH_RE = re.compile(r"Crash report saved to|Failed to start the minecraft server|Mod loading has failed|"
                      r"Missing or unsupported mandatory dependencies|Exception in server tick loop|"
                      r"Encountered an unexpected exception|ModLoadingException")


def die(msg, code=1):
    print("ERROR: " + msg, file=sys.stderr)
    sys.exit(code)


def safe_rel(path):
    p = pathlib.PurePosixPath(path)
    if p.is_absolute() or ".." in p.parts or "\\" in path or not path:
        die("unsafe path in mrpack: %r" % path)
    return p


def mrpack_info(mrpack):
    """Parse and validate a release .mrpack. Returns its index plus the server-side file list."""
    try:
        z = zipfile.ZipFile(mrpack)
        idx = json.loads(z.read("modrinth.index.json"))
    except (zipfile.BadZipFile, KeyError, ValueError) as e:
        die("invalid mrpack %s: %s" % (mrpack, e))
    names = z.namelist()
    if any(n.lower().endswith(".jar") for n in names):
        die("mrpack embeds .jar files")
    overrides = {}
    for n in names:
        if n.endswith("/"):
            continue
        for prefix in ("overrides/", "server-overrides/"):
            if n.startswith(prefix):
                rel = str(safe_rel(n[len(prefix):]))
                overrides[rel] = hashlib.sha256(z.read(n)).hexdigest()
    files = []
    for f in idx.get("files", []):
        safe_rel(f["path"])
        if f.get("env", {}).get("server") == "unsupported":
            continue
        url = f["downloads"][0]
        host = re.match(r"^https://([^/]+)/", url)
        if not host or host.group(1) not in ALLOWED_HOSTS:
            die("download host not allowed: %s" % url)
        files.append({"path": f["path"], "url": url, "sha512": f["hashes"]["sha512"], "sha1": f["hashes"].get("sha1"),
                      "size": f.get("fileSize")})
    return {"versionId": idx.get("versionId"), "name": idx.get("name"), "dependencies": idx.get("dependencies", {}),
            "server_files": sorted(files, key=lambda f: f["path"]), "overrides": overrides}


def fetch(url, dest, sha512, tries=4):
    dest = pathlib.Path(dest)
    if dest.exists() and hashlib.sha512(dest.read_bytes()).hexdigest() == sha512:
        return "cached"
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "VanillaTech-CD/1 (+packwiz)"})
            with urllib.request.urlopen(req, timeout=120) as r:
                data = r.read()
            if hashlib.sha512(data).hexdigest() != sha512:
                raise ValueError("sha512 mismatch")
            dest.parent.mkdir(parents=True, exist_ok=True)
            tmp = dest.with_name(dest.name + ".part")
            tmp.write_bytes(data)
            tmp.replace(dest)
            return "downloaded"
        except Exception as e:  # network errors and bad hashes are retried
            last = e
            time.sleep(2 * (i + 1))
    raise RuntimeError("%s: %s" % (url, last))


def prefetch(mrpack, cache, data=None):
    """itzg skips files that already exist, so only new or changed files must be reachable and valid."""
    info = mrpack_info(mrpack)
    cache = pathlib.Path(cache)
    stats = {"installed": 0, "cached": 0, "downloaded": 0}
    todo = []
    for f in info["server_files"]:
        live = pathlib.Path(data) / f["path"] if data else None
        if live and live.exists() and hashlib.sha512(live.read_bytes()).hexdigest() == f["sha512"]:
            stats["installed"] += 1
        else:
            todo.append(f)
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:
        futs = {ex.submit(fetch, f["url"], cache / f["sha512"][:2] / f["sha512"], f["sha512"]): f for f in todo}
        errors = []
        for fut in concurrent.futures.as_completed(futs):
            try:
                stats[fut.result()] += 1
            except Exception as e:
                errors.append(str(e))
    if errors:
        die("prefetch failed:\n  " + "\n  ".join(errors))
    print(json.dumps({"server_files": len(info["server_files"]), **stats}))


def verify_mods(mrpack, data):
    info = mrpack_info(mrpack)
    data = pathlib.Path(data)
    want = {f["path"]: f["sha512"] for f in info["server_files"]}
    have = {"mods/" + p.name for p in (data / "mods").glob("*.jar")}
    missing = sorted(set(p for p in want if p.startswith("mods/")) - have)
    extra = sorted(have - set(want))
    bad = sorted(p for p in want if (data / p).exists() and hashlib.sha512((data / p).read_bytes()).hexdigest() != want[p])
    absent = sorted(p for p in want if not p.startswith("mods/") and not (data / p).exists())
    drift = sorted(p for p, h in info["overrides"].items()
                   if not (data / p).exists() or hashlib.sha256((data / p).read_bytes()).hexdigest() != h)
    out = {"ok": not (missing or extra or bad or absent), "expected": len(want), "missing": missing, "unexpected": extra,
           "hash_mismatch": bad, "absent_non_mod_files": absent,
           "config_drift": drift}  # informational: mods may legitimately rewrite their configs
    print(json.dumps(out))
    sys.exit(0 if out["ok"] else 1)


def wait_ready(log, since, timeout):
    """Ready when a log written after SINCE contains 'Done ('; fail fast on crash markers."""
    log = pathlib.Path(log)
    since, deadline, t0 = float(since), time.time() + float(timeout), time.time()
    pos = 0
    ino = None
    while time.time() < deadline:
        try:
            st = log.stat()
            if st.st_mtime >= since:
                if st.st_ino != ino or st.st_size < pos:
                    ino, pos = st.st_ino, 0
                with open(log, "r", errors="replace") as f:
                    f.seek(pos)
                    chunk = f.read()
                    pos = f.tell()
                m = CRASH_RE.search(chunk)
                if m:
                    print(json.dumps({"ready": False, "error": m.group(0), "seconds": round(time.time() - t0, 1)}))
                    sys.exit(1)
                d = re.search(r"Done \(([0-9.]+)s\)!", chunk)
                if d:
                    print(json.dumps({"ready": True, "server_reported_seconds": float(d.group(1)),
                                      "seconds": round(time.time() - t0, 1)}))
                    return
        except FileNotFoundError:
            pass
        time.sleep(2)
    print(json.dumps({"ready": False, "error": "timeout", "seconds": round(time.time() - t0, 1)}))
    sys.exit(1)


def _varint(n):
    out = b""
    while True:
        b = n & 0x7F
        n >>= 7
        out += struct.pack("B", b | (0x80 if n else 0))
        if not n:
            return out


def _read_varint(s):
    n = shift = 0
    while True:
        b = s.recv(1)
        if not b:
            raise ConnectionError("closed")
        n |= (b[0] & 0x7F) << shift
        if not b[0] & 0x80:
            return n
        shift += 7
        if shift > 35:
            raise ValueError("varint too long")


def slp(host, port):
    try:
        with socket.create_connection((host, int(port)), timeout=5) as s:
            s.settimeout(5)
            h = host.encode()
            hs = _varint(0) + _varint(767) + _varint(len(h)) + h + struct.pack(">H", int(port)) + _varint(1)
            s.sendall(_varint(len(hs)) + hs + _varint(1) + _varint(0))
            _read_varint(s)
            if _read_varint(s) != 0:
                raise ValueError("unexpected packet")
            n = _read_varint(s)
            data = b""
            while len(data) < n:
                c = s.recv(n - len(data))
                if not c:
                    break
                data += c
        j = json.loads(data.decode("utf-8", "replace"))
        p = j.get("players", {})
        print(json.dumps({"ok": True, "online": p.get("online"), "max": p.get("max"), "version": j.get("version", {}).get("name")}))
    except Exception as e:
        print(json.dumps({"ok": False, "error": "%s: %s" % (type(e).__name__, e)}))
        sys.exit(1)


def rcon(host, port, password, cmd):
    def pkt(i, t, body):
        b = struct.pack("<ii", i, t) + body.encode() + b"\0\0"
        return struct.pack("<i", len(b)) + b

    def recv(s):
        n = struct.unpack("<i", s.recv(4))[0]
        b = b""
        while len(b) < n:
            b += s.recv(n - len(b))
        return struct.unpack("<ii", b[:8]) + (b[8:-2].decode("utf-8", "replace"),)

    with socket.create_connection((host, int(port)), timeout=10) as s:
        s.sendall(pkt(1, 3, password))
        if recv(s)[0] == -1:
            die("rcon auth failed")
        s.sendall(pkt(2, 2, cmd))
        print(recv(s)[2])


def players(text):
    m = re.search(r"There are (\d+)", text)
    if not m:
        die("cannot parse player list: %r" % text[:200])
    print(m.group(1))


def quiescent(d, seconds):
    d = pathlib.Path(d).resolve()
    me = os.getpid()
    holders = set()
    for proc in pathlib.Path("/proc").iterdir():
        if not proc.name.isdigit() or int(proc.name) == me:
            continue
        try:
            for fd in (proc / "fd").iterdir():
                try:
                    if os.readlink(fd).startswith(str(d) + "/"):
                        holders.add(int(proc.name))
                except OSError:
                    pass
        except OSError:
            continue
    if holders:
        die("processes still hold files under %s: %s" % (d, sorted(holders)))

    def newest():
        return max((p.stat().st_mtime for p in d.rglob("*") if p.is_file()), default=0)

    a = newest()
    time.sleep(float(seconds))
    if newest() != a:
        die("files under %s are still being written" % d)
    print("quiescent")


def vkey(v):
    if not VERSION_RE.match(v):
        die("invalid version %r" % v)
    core, _, pre = v.partition("-")
    rank = {"alpha": 0, "beta": 1, "rc": 2}
    return tuple(map(int, core.split("."))) + ((rank[pre.split(".")[0]], int(pre.split(".")[1])) if pre else (3, 0))


def main(a):
    if not a:
        die(__doc__)
    cmd = a[0]
    if cmd == "mrpack-info":
        info = mrpack_info(a[1])
        opts = dict(zip(a[2::2], a[3::2]))
        if "--expect-version" in opts and info["versionId"] != opts["--expect-version"]:
            die("mrpack versionId %s != %s" % (info["versionId"], opts["--expect-version"]))
        if "--expect-neoforge" in opts and info["dependencies"].get("neoforge") != opts["--expect-neoforge"]:
            die("NeoForge change %s -> %s needs explicit authorization (--allow-loader-change)"
                % (opts["--expect-neoforge"], info["dependencies"].get("neoforge")), 12)
        if info["dependencies"].get("minecraft") != "1.21.1":
            die("Minecraft version %s is not 1.21.1" % info["dependencies"].get("minecraft"), 12)
        print(json.dumps({k: info[k] for k in ("versionId", "name", "dependencies")} |
                         {"server_files": len(info["server_files"]), "overrides": len(info["overrides"])}))
    elif cmd == "prefetch":
        prefetch(a[1], a[2], a[3] if len(a) > 3 else None)
    elif cmd == "verify-mods":
        verify_mods(a[1], a[2])
    elif cmd == "wait-ready":
        wait_ready(a[1], a[2], a[3])
    elif cmd == "slp":
        slp(a[1], a[2])
    elif cmd == "rcon":
        rcon(a[1], a[2], a[3], " ".join(a[4:]))
    elif cmd == "players":
        players(a[1])
    elif cmd == "quiescent":
        quiescent(a[1], a[2])
    elif cmd == "vercmp":
        x, y = vkey(a[1]), vkey(a[2])
        print((x > y) - (x < y))
    elif cmd == "snapshot-meta":
        out = {}
        for kv in a[2:]:
            k, _, v = kv.partition("=")
            try:
                out[k] = json.loads(v)
            except ValueError:
                out[k] = v
        pathlib.Path(a[1]).write_text(json.dumps(out, indent=1, sort_keys=True) + "\n")
    else:
        die("unknown command %s" % cmd)


if __name__ == "__main__":
    main(sys.argv[1:])
