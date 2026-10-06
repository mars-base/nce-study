#!/usr/bin/env python3
"""镜像 nce.mleo.site 四册课本资源到本地 books/ 目录。"""
import concurrent.futures
import json
import os
import urllib.parse
import urllib.request

BASE = "https://nce.mleo.site"
PROXY = "http://127.0.0.1:18799"
DEST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "books")
WORKERS = 8

opener = urllib.request.build_opener(
    urllib.request.ProxyHandler({"http": PROXY, "https": PROXY})
)
urllib.request.install_opener(opener)


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    return opener.open(req, timeout=60)


def fetch(url, out):
    if os.path.exists(out) and os.path.getsize(out) > 0:
        return (out, "skip")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    tmp = out + ".part"
    with get(url) as r, open(tmp, "wb") as f:
        f.write(r.read())
    os.rename(tmp, out)
    return (out, "ok")


def main():
    tasks = []
    for n in (1, 2, 3, 4):
        book = f"NCE{n}"
        d = os.path.join(DEST, book)
        url = f"{BASE}/{book}"
        bj = os.path.join(d, "book.json")
        tasks.append((f"{url}/book.json", bj))
        meta = json.loads(get(f"{url}/book.json").read())
        if meta.get("cover"):
            tasks.append((f"{url}/{meta['cover']}", os.path.join(d, meta["cover"])))
        for u in meta["units"]:
            q = urllib.parse.quote(u["filename"])
            for ext in ("mp3", "lrc"):
                tasks.append((f"{url}/{q}.{ext}", os.path.join(d, f"{u['filename']}.{ext}")))

    print(f"{len(tasks)} files to fetch")
    done = 0
    with concurrent.futures.ThreadPoolExecutor(WORKERS) as ex:
        futs = {ex.submit(fetch, u, o): (u, o) for u, o in tasks}
        for fut in concurrent.futures.as_completed(futs):
            u, o = futs[fut]
            try:
                fut.result()
            except Exception as e:
                print(f"FAIL {u}: {e}")
            done += 1
            if done % 50 == 0:
                print(f"{done}/{len(tasks)}")
    print("done")


if __name__ == "__main__":
    main()
