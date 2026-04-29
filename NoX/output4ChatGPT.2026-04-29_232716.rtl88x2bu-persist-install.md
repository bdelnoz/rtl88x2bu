# rtl88x2bu persistent install report

- Generated at: 2026-04-29_232716
- Script version: 1.0.4
- Mode: --status
- Hostname: koutoubia
- User: nox
- SUDO_USER: 
- EUID: 1000
- Kernel: 6.19.11+kali-amd64
- Script path: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.sh
- Script directory: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX
- Repo: /mnt/data2_78g/Security/scripts/rtl88x2bu
- Requested module: auto
- Install path: /lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko
- Modprobe config: /etc/modprobe.d/rtl88x2bu-local.conf
- State file: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.state
- Report: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_232716.rtl88x2bu-persist-install.md
- Log: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.2026-04-29_232716.log

## Initial verdict

**STATUS: OK**

## Safety statement

This script performs persistent module-file installation/reversal only.

No DKMS action, make install, modprobe, insmod, initramfs update, NetworkManager setting change, service restart, or reboot is performed.

All reports, logs, state files, and backup copies produced by this script are written directly into the same directory as this script. No report/backup/state subfolder is created by this script.

## Current module status
```text
$ lsmod | grep -Ei '(^88x2bu|^rtl88x2bu|rtw88|8822|rtl|cfg80211|mac80211|usbcore|usb_common)' || true
88x2bu               3596288  0
rtl8xxxu              299008  0
mac80211             1691648  6 mt76,mt76x02_lib,mt76x02_usb,rtl8xxxu,mt76x0_common,mt76x0u
cfg80211             1511424  7 mt76,88x2bu,mt76x02_lib,mac80211,mt76x02_usb,rtl8xxxu,mt76x0_common
rfkill                 45056  7 bluetooth,cfg80211
libarc4                12288  1 mac80211
usbcore               434176  22 ipheth,xhci_hcd,ehci_pci,usbnet,snd_usb_audio,usbhid,snd_usbmidi_lib,mt76_usb,88x2bu,apple_mfi_fastcharge,cdc_ncm,ehci_hcd,xhci_pci,cdc_ether,mt76x02_usb,rtl8xxxu,mt76x0u,hid_logitech_hidpp
usb_common             20480  3 xhci_hcd,usbcore,ehci_hcd

EXIT_CODE=0
```

## Installed module path
```text
$ ls -lh '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' 2>/dev/null || true; modinfo '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' 2>/dev/null | sed -n '1,100p' || true

EXIT_CODE=0
```

## Modprobe config
```text
$ ls -lh '/etc/modprobe.d/rtl88x2bu-local.conf' 2>/dev/null || true; sed -n '1,200p' '/etc/modprobe.d/rtl88x2bu-local.conf' 2>/dev/null || true

EXIT_CODE=0
```

## depmod/module alias resolution
```text
$ modprobe -n -v 88x2bu 2>/dev/null || true; modprobe -n -v rtl88x2bu 2>/dev/null || true; modprobe -n -v rtw88_8822bu 2>/dev/null || true
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_core.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_8822b.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_usb.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_8822bu.ko.xz 

EXIT_CODE=0
```

## Current wlan1 binding
```text
$ ip -br link show wlan1 2>/dev/null || true; readlink -f /sys/class/net/wlan1/device/driver 2>/dev/null || true; cat /sys/class/net/wlan1/device/uevent 2>/dev/null || true
wlan1            UP             48:22:54:1c:3b:af <BROADCAST,MULTICAST,UP,LOWER_UP> 
/sys/bus/usb/drivers/rtl88x2bu
DEVTYPE=usb_interface
DRIVER=rtl88x2bu
PRODUCT=2357/12d/210
TYPE=0/0/0
INTERFACE=255/255/255
MODALIAS=usb:v2357p012Dd0210dc00dsc00dp00icFFiscFFipFFin00

EXIT_CODE=0
```

## Script-local files
```text
$ ls -lh '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/output4ChatGPT.*.rtl88x2bu-persist-install.md '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/rtl88x2bu_persist_install.state '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/backup_rtl88x2bu_* 2>/dev/null || true
-rw-rw-r-- 1 nox nox 3,9K 29 avr 23:27 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_232716.rtl88x2bu-persist-install.md

EXIT_CODE=0
```

## Final verdict

**STATUS: OK**

Read-only status report generated.

## Final safety confirmation

```text
No DKMS action was performed.
No make install was performed.
No modprobe was performed.
No insmod was performed.
No initramfs was changed.
No NetworkManager setting was changed.
No service was restarted.
No reboot was requested.
Report/log/state/backups produced by this script are directly in: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX
```
