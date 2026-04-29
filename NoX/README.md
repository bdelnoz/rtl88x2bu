# NoX rtl88x2bu operational scripts

This directory contains the local operational scripts used to investigate, build, test, persist, validate, and optionally finalize the `rtl88x2bu` driver workflow on Kali Linux.

The scripts are intended to be executed in numbered order after renaming them with the `01_`, `02_`, etc. prefixes.

## Execution order

| Order | Script | Purpose |
|---:|---|---|
| 01 | `01_rtl88x2bu_getinfo.sh` | Collects baseline system, kernel, USB, module, and driver information before touching anything. |
| 02 | `02_rtl88x2bu_wifi_netinfo.sh` | Collects Wi-Fi and network state: interfaces, wireless links, stations, routes, counters, and relevant logs. |
| 03 | `03_rtl88x2bu_buildtest_tmp.sh` | Builds the driver in a temporary test location without installing it persistently. |
| 04 | `04_rtl88x2bu_loadtest_tmp.sh` | Tests loading/binding behavior from the temporary build context. Used before persistent installation. |
| 05 | `05_rtl88x2bu_persist_install.sh` | Installs the compiled `88x2bu.ko` persistently for the active kernel under `/lib/modules/.../extra/rtl88x2bu/`, writes the local modprobe blacklist config, runs `depmod`, and validates the persistent setup. |
| 06 | `06_rtl88x2bu_dkms_manage.sh` | Registers/builds/installs the driver through DKMS so it can be rebuilt automatically for future kernels. This is the preferred long-term maintenance layer. |
| 07 | `07_rtl88x2bu_initramfs_finalize.sh` | Optional final initramfs synchronization script. It backs up the active initrd and runs `update-initramfs` only when explicitly called with `--exec`. |

## Recommended normal workflow

For a clean investigation and deployment flow:

```bash
./01_rtl88x2bu_getinfo.sh
./02_rtl88x2bu_wifi_netinfo.sh
./03_rtl88x2bu_buildtest_tmp.sh
./04_rtl88x2bu_loadtest_tmp.sh
sudo ./05_rtl88x2bu_persist_install.sh --exec
sudo ./05_rtl88x2bu_persist_install.sh --validation
sudo ./06_rtl88x2bu_dkms_manage.sh --exec
sudo ./06_rtl88x2bu_dkms_manage.sh --validation
```

The initramfs step is optional and separate:

```bash
./07_rtl88x2bu_initramfs_finalize.sh --status
./07_rtl88x2bu_initramfs_finalize.sh --validation
```

Only run the next command if you explicitly want to update the active initramfs:

```bash
sudo ./07_rtl88x2bu_initramfs_finalize.sh --exec
```

## Script modes

The main operational scripts generally use these modes:

- `--status`: read-only status report.
- `--validation`: read-only validation report.
- `--exec`: performs the requested installation or finalization.
- `--reverse`: attempts to reverse what the script previously changed.
- `--no-kate`: avoids opening the generated report in Kate.

## Generated report files

Generated Markdown reports follow this kind of pattern:

```text
output4ChatGPT.YYYY-MM-DD_HHMMSS.<topic>.md
```

Examples:

```text
output4ChatGPT.2026-04-30_010544.rtl88x2bu-dkms-manage.md
output4ChatGPT.2026-04-30_003217.rtl88x2bu-initramfs-finalize.md
```

These files are reports. They are not scripts. They document what the script observed or changed at a given time.

They can be kept as evidence/history while debugging, but they are not required to execute the workflow.

## `.state` files

State files record what a script changed or backed up so that `--reverse` can find the right artefacts later.

Current examples:

```text
rtl88x2bu_persist_install.state
rtl88x2bu_dkms_manage.state
rtl88x2bu_initramfs_finalize.state
```

These files are operational metadata. Do not rename or edit them manually unless you know exactly what you are doing.

They are useful because a later `--reverse` can use them to locate backup files and restore prior state.

## Backup files

Backup files are created before overwriting or replacing important existing files.

Examples:

```text
backup_rtl88x2bu_2026-04-29_233817_88x2bu.ko
backup_rtl88x2bu_2026-04-29_233817_rtl88x2bu-local.conf
backup_rtl88x2bu_modprobe_2026-04-30_010027_rtl88x2bu-local.conf
```

These are safety copies.

Typical meanings:

- `backup_*_88x2bu.ko`: previous kernel module backup.
- `backup_*_rtl88x2bu-local.conf`: previous modprobe blacklist/config backup.
- `backup_rtl88x2bu_modprobe_*`: previous `/etc/modprobe.d/rtl88x2bu-local.conf` backup created by DKMS management script.

Do not delete these immediately after a successful run. Keep them until at least one reboot and validation cycle is completed.

## `.tar.gz` backup archives

The `.tar.gz` files are compressed backups of the DKMS source tree.

Examples:

```text
backup_rtl88x2bu_dkms_2026-04-30_005002_rtl88x2bu-5.8.7.1_35809.20191129_COEX20191120-7777.tar.gz
backup_rtl88x2bu_dkms_2026-04-30_010027_rtl88x2bu-5.8.7.1_35809.20191129_COEX20191120-7777.tar.gz
```

These are not scripts.

They preserve the previous `/usr/src/rtl88x2bu-...` DKMS source tree before it was replaced by the script.

Keep them until the DKMS setup has survived a reboot and at least one future kernel-related validation.

## `.conf` files

The relevant system configuration file is:

```text
/etc/modprobe.d/rtl88x2bu-local.conf
```

It blacklists the in-kernel `rtw88_*` driver family so the local `88x2bu` driver is preferred for the TP-Link RTL8812BU/RTL8822BU device.

Typical content:

```text
blacklist rtw88_8822bu
blacklist rtw88_usb
blacklist rtw88_8822b
blacklist rtw88_core
```

Inside this `NoX` directory, files ending in `.conf` are usually backups of that system config file. They are not active unless copied back to `/etc/modprobe.d/`.

## `.log` files

Log files follow this pattern:

```text
rtl88x2bu_<script-topic>.YYYY-MM-DD_HHMMSS.log
```

They are generated by scripts to capture execution details. Some logs may be empty when all useful output was written directly into the Markdown report.

They are not scripts and are not required for normal execution.

## DKMS notes

`06_rtl88x2bu_dkms_manage.sh` installs the driver through DKMS.

This means:

- the source is copied to `/usr/src/rtl88x2bu-<version>/`;
- DKMS registers the module/version;
- DKMS builds the module for the active kernel;
- DKMS installs the module under `/lib/modules/<kernel>/updates/dkms/`;
- future compatible kernel upgrades can trigger a DKMS rebuild.

The successful DKMS target module is typically:

```text
/lib/modules/$(uname -r)/updates/dkms/88x2bu.ko.xz
```

The expected validation result is:

```text
DKMS validation passed.
```

## Initramfs notes

`07_rtl88x2bu_initramfs_finalize.sh` is intentionally separate because it touches the active initramfs only with `--exec`.

The script backs up:

```text
/boot/initrd.img-$(uname -r)
```

into the script directory before running:

```text
update-initramfs -u -k $(uname -r)
```

This step is not required just to use the driver now. It is a final synchronization step for boot-time consistency.

## What is safe to rename

The seven executable scripts can be renamed with numeric prefixes.

Do not rename generated backup files, state files, logs, or Markdown reports unless you also accept that older reports and reverse operations may no longer point to the same file names.

## Rename commands

Use `git mv` because this directory is inside a Git repository.

```bash
git mv rtl88x2bu_getinfo.sh 01_rtl88x2bu_getinfo.sh
git mv rtl88x2bu_wifi_netinfo.sh 02_rtl88x2bu_wifi_netinfo.sh
git mv rtl88x2bu_buildtest_tmp.sh 03_rtl88x2bu_buildtest_tmp.sh
git mv rtl88x2bu_loadtest_tmp.sh 04_rtl88x2bu_loadtest_tmp.sh
git mv rtl88x2bu_persist_install.sh 05_rtl88x2bu_persist_install.sh
git mv rtl88x2bu_dkms_manage.sh 06_rtl88x2bu_dkms_manage.sh
git mv rtl88x2bu_initramfs_finalize.sh 07_rtl88x2bu_initramfs_finalize.sh
```

After renaming, check:

```bash
git status --short
ls -lh
```

## Current final state expected

After the current work session, the expected stable state is:

- persistent install completed;
- DKMS install completed;
- `wlan1` currently bound to `rtl88x2bu`;
- DKMS validation passed;
- reboot can wait;
- after reboot, run:

```bash
cd /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX
sudo ./06_rtl88x2bu_dkms_manage.sh --validation
```

If this passes after reboot, the DKMS/persistent driver setup is confirmed across boot.
