#!/usr/bin/env bash
# Refresh this repo from what is already published on apps.vpavlin.xyz, keeping
# only Scala, Frequencies and the packages they need. Run it after a Scala or
# Frequencies release, commit, push; the site workflow rebuilds frequencies.vpavlin.xyz.
#
# Nothing large is stored here:
#   - basecamp/index.json lists the Scala chain from the apps catalog, with
#     each package's url still pointing at the catalog's GitHub release asset;
#   - fdroid/repo holds a signed F-Droid index for Scala only (same repo key
#     as apps.vpavlin.xyz), built locally with fdroid from $FREQ_FDROID; the
#     site workflow copies the APKs it names from apps.vpavlin.xyz and checks
#     them against the index's sha256.
#
#   FREQ_FDROID   local F-Droid repo dir (default ~/frequencies-fdroid)
#   APPS_FDROID   the apps.vpavlin.xyz F-Droid dir to take APKs from (default ~/logos-apps-fdroid)
#   KEEP          Scala APK versions to keep (default 2)
set -euo pipefail
cd "$(dirname "$0")/.."
FREQ_FDROID="${FREQ_FDROID:-$HOME/frequencies-fdroid}"
APPS_FDROID="${APPS_FDROID:-$HOME/logos-apps-fdroid}"
KEEP="${KEEP:-2}"
CATALOG_URL="https://github.com/vpavlin/logos-basecamp-modules/releases/download/index/index.json"

# ── Basecamp: the Scala chain, newest version of each, urls unchanged ──────
curl -fsSL "$CATALOG_URL" -o /tmp/freq-catalog.json
python3 - /tmp/freq-catalog.json basecamp/index.json <<'PY'
import json, sys
src, dst = sys.argv[1:]
CHAIN = ["frequencies_ui", "scala", "scala_ui", "kith", "kith_ui", "whisperbox_core",
         "loam_core", "loam_ui", "delivery_module", "ble_mesh", "keycard", "keycard-ui", "storage_module"]
cat = json.load(open(src))
pkgs = {p["name"]: p for p in cat["packages"]}
out = []
for name in CHAIN:
    if name not in pkgs:
        sys.exit(f"{name} is not in the apps catalog")
    p = dict(pkgs[name])
    p["versions"] = p["versions"][:1]          # newest only: nothing older can outrank it
    out.append(p)
names = {p["name"] for p in out}
for p in out:                                  # every dependency must be in this repo too
    for dep in p["versions"][0]["manifest"].get("dependencies") or []:
        if dep not in names:
            sys.exit(f"{p['name']} depends on {dep}, which is not in this repo's chain")
idx = {k: v for k, v in cat.items() if k != "packages"}
idx["repositoryName"] = "frequencies"
idx["packages"] = out
json.dump(idx, open(dst, "w"), indent=2)
for p in out:
    print(f"  basecamp: {p['name']} {p['versions'][0]['manifest']['version']}")
PY

# ── F-Droid: newest $KEEP APKs of each app, signed index, APKs not committed ─
# Frequencies and Scala, plus Loam (both need it on the phone) and Kith (the artists' address book).
for app in frequencies:xyz.vpavlin.frequencies scala:xyz.vpavlin.scala loam:xyz.vpavlin.loam kith:xyz.vpavlin.kith; do
  file=${app%%:*}; pkg=${app#*:}
  mapfile -t APKS < <(ls -t "$APPS_FDROID"/repo/"$file"-*.apk 2>/dev/null | head -n "$KEEP")
  [ "${#APKS[@]}" -gt 0 ] || { echo "no $file APK on apps.vpavlin.xyz" >&2; exit 1; }
  find "$FREQ_FDROID/repo" -maxdepth 1 -name "$file-*.apk" -delete
  cp "${APKS[@]}" "$FREQ_FDROID/repo/"
  cp "$APPS_FDROID/metadata/$pkg.yml" "$FREQ_FDROID/metadata/"
  [ -d "$APPS_FDROID/metadata/$pkg" ] && cp -r "$APPS_FDROID/metadata/$pkg" "$FREQ_FDROID/metadata/"
done
(cd "$FREQ_FDROID" && ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}" \
    "${FDROID_BIN:-$HOME/fdroid-venv/bin/fdroid}" update 2>&1 | grep -iE "error|critical" | grep -v repo_icon || true)
rm -rf fdroid/repo && mkdir -p fdroid
rsync -a --checksum --exclude '*.apk' --exclude 'status' "$FREQ_FDROID/repo/" fdroid/repo/
python3 -c '
import json
d = json.load(open("fdroid/repo/index-v2.json"))
for pkg, p in d["packages"].items():
    for v in p["versions"].values():
        print("  fdroid:", pkg, v["manifest"]["versionName"], v["file"]["name"])'
