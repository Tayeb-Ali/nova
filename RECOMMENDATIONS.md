# Nova Recommendations (for the future)

> Living document: package/repo policy, slimming rules, and the multi-tier
> bundle plan. Updated 2026-09-30. All sizes are per-arch unless noted.

## 1. Golden invariants (never break)

1. **Installed ∪ Repo must satisfy every dependency.** Before removing any
   deb from the repo or bootstrap, run the dependency audit
   (resolve every `Depends` against installed-status ∪ repo index).
   Target: `TOTAL BROKEN: 0`. The `apt` on device refuses ALL installs
   when a single installed package has unmet deps.
2. **Bootstrap-registered packages stay satisfiable.** The bootstrap's
   `var/lib/dpkg/status` lists everything extracted. A package may be
   dropped from the *repo* only if nothing installed or installable
   needs it (perl precedent: present in bootstrap, needed by nothing at
   runtime → repo removal is safe, no rebuild required).
3. **Subpackage names resolve via parent dirs.** `buildorder.py` prints
   parents; our tooling must add `*.subpackage.sh` names explicitly
   (lesson from the missing `apt`/`bzip2` incident).
4. **Custom package name ⇒ everything builds from source** (`-i`
   disabled). Never depend on prebuilt Termux debs (wrong prefix).
5. **Upstream recipes are patched minimally and marked `# NOVA:`**
   (current patches: `openjdk-25` dropped `alsa-plugins`;
   `build-bootstraps.sh` `bzip2→libbz2`; pruned `apt-transport-tor`,
   `git-svn`). Re-apply + re-validate after every `termux-packages`
   ref bump.
6. **GitHub limits shape distribution:** 100 MB/file (no big zips in
   git), ~1 GB Pages site, 2 GB release assets. Big pushes go out in
   ~70–100 MB chunks (they survive slow uplinks; a 500 MB push dies).

## 2. Slimming policy (approved 2026-09-30)

Remove from the **repo** (fast: delete debs, re-sign, push metadata only):

| Target | Why | Saving |
|---|---|---|
| All `*-static` (~40 pkgs) | static linking unused on-device | ~30–60 MB repo |
| `perl` (+ `perl` modules) | zero reverse-deps; stays in bootstrap, runtime-unused | ~15 MB ×2 + slow build skipped henceforth |
| `doxygen`, `swig`, `texinfo`, `docbook-xsl` | doc/build tools, zero reverse-deps | ~13 MB + slow C++ builds skipped |
| `git-gui`, `git-gitk`, `python-tkinter`, `libsqlite-tcl`, `tcl`, `tk` | GUI/X11 chain, useless on phone | moderate |
| `sqlite` CLI, `unbound` CLI, `ncurses-utils`? | orphans (libs stay) | small |
| `glib-cross`, `icu-devtools`, `g-ir-scanner`, `python-xcbgen` | host tools | ~13 MB |
| `php-fpm`, `php-apache*`, `php-pgsql`, `php-gd`, `php-ldap`, `php-sodium`? | see PHP row | ~8 MB + kills subtrees below |

Drop **subtrees** (needs recipe patch + recompile of the parent only):

| Subtree | Patch | Saving | Notes |
|---|---|---|---|
| `apache2` (httpd) | `php/build.sh`: remove `--with-apxs` + delete `php-apache*` subpackages | ~15 MB + ~8 min build | CLI/FPM unaffected... FPM also dropped (serverside) |
| `postgresql` (+libpq) | remove `--with-pgsql/--with-pdo-pgsql` + delete `php-pgsql` | ~25 MB + ~15 min | Laravel-on-phone uses sqlite; Postgres users keep full-php (see bundles) |
| `libgd/libheif/rav1e/aom/dav1d/x264/x265/libvpx` | remove `--enable-gd/--with-external-gd` + delete `php-gd` | ~30 MB + ~30 min (rav1e is Rust-slow) | only matters for image-manipulation code (WordPress thumbnails) |
| `openldap/cyrus-sasl` | remove `--with-ldap/--with-ldap-sasl` + delete `php-ldap` | ~8 MB + ~8 min | enterprise-auth only |
| X11-for-JDK (`libX*/xorgproto`) | attempt `--with-x=no` (headless) in `openjdk-25` | ~10 MB | MEDIUM RISK: full JDK recompile (~hours) to verify; console Java/Kotlin need no AWT/Swing on a phone. Rollback = revert one line |

Keep, do NOT touch: `krb5` (openssh needs it), `libsqlite` (node/python/php/gnupg), `cups` (openjdk build-dep), `icu`/`libicu` (node/python/php runtime), `perl` **in bootstrap** (harmless, avoids rebuild), `ca-certificates`, `dpkg`/`apt`/`gnupg` core.

## 3. Multi-tier bundles (the "satisfy everyone" plan)

Problem: one `full` (283 MB) forces everyone to download everything.
Solution: **metapackages** — tiny arch-all debs containing only
`Depends:`, installed with one tap. No new bootstraps, no rebuilds of
languages; only metapackage recipes + repo index + UI grouping.

| Pack (metapackage id) | Contents | Installed size* | For whom |
|---|---|---|---|
| `slim` (bootstrap) | base + apt | ~70 MB download | everyone (setup default) |
| `full` (bootstrap) | slim + every language preinstalled | ~283 MB download | offline users |
| `nova-web` | php, composer, ruby, nodejs, npm | ~150 MB | web devs (Laravel/Rails/Node) |
| `nova-systems` | rust, golang, make, cmake, binutils | ~250 MB | systems/compiled langs |
| `nova-jvm` | openjdk-25, kotlin | ~300 MB | Java/Kotlin devs |
| `nova-python` | python, python-pip | ~100 MB | Python/data scripts |
| `nova-dart` | dart | ~80 MB | Dart CLI tools |
| _(individual)_ | any single runtime via apt | varies | à la carte (already works) |

\* installed footprint, order-of-magnitude; measure on device after publish.

Implementation (when approved):

1. **Metapackage recipes** in our clone, e.g. `packages/nova-web/build.sh`
   (`TERMUX_PKG_METAPACKAGE=true`-style: no sources, only `DEPENDS`;
   follow the `command-not-found` metapackage pattern in-tree).
   Build = seconds per pack per arch (arch-all where possible).
2. **Registry**: `RuntimeRegistry` gains pack entries with
   `packageName = nova-web` etc. (install/update/remove flow unchanged —
   apt resolves the group). Display names: "Web Pack", "Systems Pack"…,
   category = pack (new `RuntimeType` values or a `isPack` flag).
3. **SDK screen**: "Packs" section on top (one-tap install + total size),
   individual runtimes below (unchanged).
4. **New-project dialog**: unchanged (reads installed runtimes; packs
   surface automatically once installed).
5. **Detection**: unchanged (per-language markers already cover packs'
   languages).
6. Sign → push (tiny) → on-device verify per pack (`--version` each).

Rules for future packs: a pack may only depend on repo packages with
satisfiable closures (run the audit after adding); never include
bootstrap-base packages (already present); keep display size honest
(measure `apt-get install --print-uris` + installed-size, don't guess).

## 4. Build hygiene (lessons, don't repeat)

- Never `pkill -9` a compiling package (corrupts cargo/meson trees;
  stop between packages only). Logs append (`>>`), never truncate.
- Pre-seed flaky hosts (IPv4-first test: broken IPv6 stalls curl
  forever; resume with `curl -4 -C -`, verify SHA before use).
- WSL limits for heavy builds: 9 GB + 8 GB swap + `-j2/3`
  (OOM killed `cc1plus` twice at 7 GB/-j3). Keep Windows awake,
  pause updates.
- Fresh VM + fresh clone ⇒ `build-bootstraps.sh` must run WITHOUT `-f`
  (its `-f` wipe expands to `rm -f /*` when vars are unset).
- Pin `termux-packages` ref per release; re-validate renames
  (`bzip2→libbz2` precedent) and subpackage coverage before building.
- Keep `/tmp/base-names.txt`-style closure tooling next to the build
  (parents + `*.subpackage.sh` names + explicit tops; beware
  column-aligned `cut` — use `awk`).

## 5. Deferred / parked

- `proot` (never built; needed only for proot-distro/fakeroot).
- `tcc` (cannot parse NDK r29/clang-21 headers) ⇒ C/C++ on-device
  compiling unavailable until upstream fixes or another compiler ships.
- `C#` (no dotnet for Android; mono exists but deferred by decision).
- `openjdk headless attempt` (see §2, medium risk, hours).
- `gdb` (source host `android.googlesource.com` persistently 503 from
  here; debugger optional).
- Full `perl` removal from bootstrap (needs slim rebuild; repo removal
  suffices for now).
