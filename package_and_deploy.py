import os
import shutil
import tarfile
import urllib.request
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

print("1. Copying flutter/build/web to server/public/app...")
src = os.path.abspath("flutter/build/web")
dst = os.path.abspath("server/public/app")

if not os.path.exists(src):
    print("Error: flutter/build/web does not exist!")
    sys.exit(1)

os.makedirs(dst, exist_ok=True)
for item in os.listdir(src):
    s = os.path.join(src, item)
    d = os.path.join(dst, item)
    if os.path.isdir(s):
        if os.path.exists(d):
            shutil.rmtree(d)
        shutil.copytree(s, d)
    else:
        shutil.copy2(s, d)

print("Copied web build successfully!")

print("\n2. Creating web.tar.gz...")
with tarfile.open("web.tar.gz", "w:gz") as tar:
    tar.add(src, arcname="")

size_mb = os.path.getsize("web.tar.gz") / 1024 / 1024
print(f"Created web.tar.gz ({size_mb:.2f} MB)")

print("\n3. Running deploy_web.py to sync to VPS...")
res = subprocess.run([sys.executable, "-u", "deploy_web.py"])
if res.returncode != 0:
    print(f"deploy_web.py failed with return code {res.returncode}")

print("\n4. Verifying HTTP response from VPS...")
try:
    req = urllib.request.Request(
        "http://213.133.97.141:3000/app/",
        headers={"User-Agent": "Mozilla/5.0"}
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        print(f"Status Code: {resp.status} (OK)")
        print(f"Content-Type: {resp.headers.get('Content-Type')}")
except Exception as e:
    print(f"Verification warning: {e}")

print("\n=== DEPLOYMENT AND VERIFICATION FINISHED ===")
