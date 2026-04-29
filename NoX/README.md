# README_NOX.md — rtl88x2bu Nox Workflow

## Purpose

This file documents the Nox-specific workflow for collecting system information before building or installing the `rtl88x2bu` driver on Kali Linux systems.

The current repository is the user fork:

```text
https://github.com/bdelnoz/rtl88x2bu.git
```

The local working repository on Koutoubia is:

```text
/mnt/data2_78g/Security/scripts/rtl88x2bu
```

The personal working branch is:

```text
main
```

The original upstream driver branch remains available as:

```text
5.8.7.1_35809.20191129_COEX20191120-7777
```

---

## Safety policy

The workflow must stay conservative.

Before installing anything, first collect evidence and validate:

1. kernel version;
2. installed headers;
3. active driver used by the USB Wi-Fi interface;
4. Realtek/rtw modules currently loaded;
5. DKMS status;
6. modprobe blacklist/config state;
7. repository state;
8. compatibility-relevant source lines;
9. presence or absence of already built modules.

The script `rtl88x2bu_getinfo.sh` is intentionally read-only.

It does **not**:

- compile the driver;
- run `dkms add`;
- run `dkms build`;
- run `dkms install`;
- run `make install`;
- run `modprobe`;
- unload a module;
- blacklist a driver;
- edit `/etc`;
- edit `/lib/modules`;
- edit `/usr/src`;
- regenerate initramfs;
- reboot.

---

## Important rule about initramfs

The command below is considered sensitive and must never be hidden inside a large copy-paste block:

```text
update-initramfs
```

If it is ever needed, it must be isolated in its own separate command block and explicitly validated first.

---

## Main getinfo script

File:

```text
rtl88x2bu_getinfo.sh
```

Recommended use from the repository root:

```bash
cd /mnt/data2_78g/Security/scripts/rtl88x2bu
bash ./rtl88x2bu_getinfo.sh --iface wlan1 --repo "$PWD"
```

The script writes a Markdown report to `/tmp`, for example:

```text
/tmp/output4ChatGPT.YYYY-MM-DD_HHMMSS.rtl88x2bu-getinfo.md
```

Then display it with:

```bash
cat "$(ls -t /tmp/output4ChatGPT.*.rtl88x2bu-getinfo.md | head -n1)"
```

---

## Use on another Kali machine

Clone the fork:

```bash
git clone https://github.com/bdelnoz/rtl88x2bu.git
cd rtl88x2bu
git checkout main
```

Run the read-only inventory:

```bash
bash ./rtl88x2bu_getinfo.sh --iface wlan1 --repo "$PWD"
```

If the Wi-Fi interface name is different:

```bash
ip -br link
```

Then rerun with the real interface name:

```bash
bash ./rtl88x2bu_getinfo.sh --iface <real-interface> --repo "$PWD"
```

Example:

```bash
bash ./rtl88x2bu_getinfo.sh --iface wlx4822541c3baf --repo "$PWD"
```

---

## Build status validated on Koutoubia

A clean upstream build test was performed in `/tmp` after syncing the fork.

Validated commit:

```text
8bb20da docs: Mention successful builds for v6.19
```

Kernel:

```text
6.19.11+kali-amd64
```

Result:

```text
BUILD_RET=0
```

Generated module during test:

```text
/tmp/rtl88x2bu-upstream-buildtest-2026-04-29_210538/src/88x2bu.ko
```

No installation was performed during that test.

---

## Previous local patch status

Before the fork was synced, local temporary patches were tested in `/tmp` to fix:

- `from_timer` incompatibility;
- `cfg80211_ops` callback signature changes in kernel 6.19;
- `-Werror=date-time`.

After syncing the fork, the upstream/fork code compiled directly on Koutoubia without the local patch.

Current conclusion:

```text
Do not reapply the old temporary patch unless a fresh build proves it is needed again.
```

---

## Recommended next steps

1. Run `rtl88x2bu_getinfo.sh`.
2. Analyze the generated Markdown report.
3. Only after analysis, decide between:
   - temporary non-persistent module test;
   - DKMS registration;
   - keeping current kernel driver;
   - changing hostapd profile;
   - changing USB/power/radio setup.

No installation step should be performed blindly.

---

## Repository hygiene

Recommended files to keep in the `main` branch:

```text
AGENTS.md
CLAUDE.md -> AGENTS.md
README_NOX.md
rtl88x2bu_getinfo.sh
rtl88x2bu_koutoubia_nouveau_chat.md
historique_commandes_rtl88x2bu_koutoubia.md
```

Before committing:

```bash
git status
git diff -- rtl88x2bu_getinfo.sh README_NOX.md
```

Then commit if clean and intended:

```bash
git add rtl88x2bu_getinfo.sh README_NOX.md
git commit -m "Add Nox rtl88x2bu getinfo workflow"
git push
```
