# rtl88x2bu initramfs finalize report

- Generated at: 2026-04-30_003217
- Script version: 1.0.0
- Mode: --validation
- Hostname: koutoubia
- User: nox
- SUDO_USER: 
- EUID: 1000
- Kernel: 6.19.11+kali-amd64
- Script path: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_initramfs_finalize.sh
- Script directory: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX
- Installed module: /lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko
- Modprobe config: /etc/modprobe.d/rtl88x2bu-local.conf
- Initrd: /boot/initrd.img-6.19.11+kali-amd64
- State file: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_initramfs_finalize.state
- Report: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-30_003217.rtl88x2bu-initramfs-finalize.md
- Log: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_initramfs_finalize.2026-04-30_003217.log
- AP interface checked by validation: wlan1

## Initial verdict

**STATUS: RUNNING**

## Safety statement

This script performs read-only checks unless --exec or --reverse is explicitly used.

--exec only backs up the active initrd and runs update-initramfs for the active kernel.

--reverse restores the initrd backup recorded by --exec or the newest matching backup in this script directory.

No DKMS action, make install, modprobe live-load, insmod, NetworkManager setting change, service restart, or reboot is performed.

All reports, logs, state files, and backup copies produced by this script are written directly into the same directory as this script. No report/backup/state subfolder is created by this script.

## Current module status
```text
$ bash -c lsmod | grep -Ei '(^88x2bu|^rtl88x2bu|rtw88|8822|rtl|cfg80211|mac80211|usbcore|usb_common)' || true
rtl8xxxu              299008  0
88x2bu               3596288  0
mac80211             1691648  6 mt76,mt76x02_lib,mt76x02_usb,rtl8xxxu,mt76x0_common,mt76x0u
cfg80211             1511424  7 mt76,88x2bu,mt76x02_lib,mac80211,mt76x02_usb,rtl8xxxu,mt76x0_common
libarc4                12288  1 mac80211
rfkill                 45056  6 cfg80211
usbcore               434176  11 xhci_hcd,ehci_pci,usbhid,mt76_usb,88x2bu,ehci_hcd,xhci_pci,mt76x02_usb,rtl8xxxu,mt76x0u,hid_logitech_hidpp
usb_common             20480  3 xhci_hcd,usbcore,ehci_hcd

EXIT_CODE=0
```

## Installed module path
```text
$ bash -c ls -lh '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' 2>/dev/null || true; modinfo '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' 2>/dev/null | sed -n '1,80p' || true
-rw-r--r-- 1 nox nox 8,0M 29 avr 22:04 /lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko
filename:       /lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko
version:        v5.8.7.1_35809.20191129_COEX20191120-7777
author:         Realtek Semiconductor Corp.
description:    Realtek Wireless Lan Driver
license:        GPL
srcversion:     BDC0909641562A09FF5F1F6
alias:          usb:v13B1p0045d*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v20F4p808Ad*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v7392pC822d*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v7392pB822d*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v2357p0138d*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v2357p012Ed*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v2357p012Dd*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v2357p0115d*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v2001p331Fd*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v2001p331Ed*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v2001p331Cd*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v13B1p0043d*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v0B05p184Cd*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v0B05p1841d*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v0846p9055d*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v0BDApB812d*dc*dsc*dp*icFFiscFFipFFin*
alias:          usb:v0BDApB82Cd*dc*dsc*dp*icFFiscFFipFFin*
depends:        usbcore,cfg80211
name:           88x2bu
retpoline:      Y
vermagic:       6.19.11+kali-amd64 SMP preempt mod_unload 
parm:           rtw_wireless_mode:int
parm:           rtw_ips_mode:The default IPS mode (int)
parm:           rtw_lps_level:The default LPS level (int)
parm:           rtw_lps_chk_by_tp:int
parm:           rtw_max_bss_cnt:int
parm:           rtw_usb_rxagg_mode:int
parm:           rtw_dynamic_agg_enable:int
parm:           rtw_tx_aclt_flags:device TX AC queue packet lifetime control flags (uint)
parm:           rtw_tx_aclt_conf_default:device TX AC queue lifetime config for default status (array of uint)
parm:           rtw_tx_aclt_conf_ap_m2u:device TX AC queue lifetime config for AP mode M2U status (array of uint)
parm:           rtw_tx_bw_mode:The max tx bw for 2.4G and 5G. format is the same as rtw_bw_mode (uint)
parm:           rtw_rx_ampdu_sz_limit_1ss:RX AMPDU size limit for 1SS link of each BW, 0xFF: no limitation (array of uint)
parm:           rtw_rx_ampdu_sz_limit_2ss:RX AMPDU size limit for 2SS link of each BW, 0xFF: no limitation (array of uint)
parm:           rtw_rx_ampdu_sz_limit_3ss:RX AMPDU size limit for 3SS link of each BW, 0xFF: no limitation (array of uint)
parm:           rtw_rx_ampdu_sz_limit_4ss:RX AMPDU size limit for 4SS link of each BW, 0xFF: no limitation (array of uint)
parm:           rtw_vht_enable:int
parm:           rtw_vht_rx_mcs_map:VHT RX MCS map (uint)
parm:           rtw_rf_path:int
parm:           rtw_tx_nss:int
parm:           rtw_rx_nss:int
parm:           rtw_country_code:The default country code (in alpha2) (charp)
parm:           rtw_channel_plan:The default chplan ID when rtw_alpha2 is not specified or valid (int)
parm:           rtw_excl_chs:exclusive channel array (array of uint)
parm:           rtw_btcoex_enable:BT co-existence on/off, 0:off, 1:on, 2:by efuse (int)
parm:           rtw_ant_num:Antenna number setting, 0:by efuse (int)
parm:           rtw_pci_dynamic_aspm_linkctrl:int
parm:           rtw_qos_opt_enable:int
parm:           ifname:The default name to allocate for first interface (charp)
parm:           if2name:The default name to allocate for second interface (charp)
parm:           rtw_wowlan_sta_mix_mode:int
parm:           rtw_pwrtrim_enable:int
parm:           rtw_initmac:charp
parm:           rtw_chip_version:int
parm:           rtw_rfintfs:int
parm:           rtw_lbkmode:int
parm:           rtw_network_mode:int
parm:           rtw_channel:int
parm:           rtw_mp_mode:int
parm:           rtw_wmm_enable:int
parm:           rtw_uapsd_max_sp:int
parm:           rtw_uapsd_ac_enable:int
parm:           rtw_wmm_smart_ps:int
parm:           rtw_vrtl_carrier_sense:int
parm:           rtw_vcs_type:int
parm:           rtw_busy_thresh:int
parm:           rtw_ht_enable:int
parm:           rtw_bw_mode:int
parm:           rtw_ampdu_enable:int
parm:           rtw_rx_stbc:int
parm:           rtw_rx_ampdu_amsdu:int
parm:           rtw_tx_ampdu_amsdu:int
parm:           rtw_beamform_cap:int
parm:           rtw_lowrate_two_xmit:int

EXIT_CODE=0
```

## Modprobe config
```text
$ bash -c ls -lh '/etc/modprobe.d/rtl88x2bu-local.conf' 2>/dev/null || true; sed -n '1,200p' '/etc/modprobe.d/rtl88x2bu-local.conf' 2>/dev/null || true
-rw-r--r-- 1 root root 412 29 avr 23:38 /etc/modprobe.d/rtl88x2bu-local.conf
# Generated by /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.sh on 2026-04-29_233817
# Purpose: prefer local rtl88x2bu/88x2bu driver over in-kernel rtw88_8822bu for RTL8812BU/RTL8822BU testing.
# Reverse with: sudo /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.sh --reverse
blacklist rtw88_8822bu
blacklist rtw88_usb
blacklist rtw88_8822b
blacklist rtw88_core

EXIT_CODE=0
```

## depmod/module alias resolution
```text
$ bash -c grep -E 'usb:v2357p012D|usb:v2357p012E|usb:v0BDApB812|usb:v0BDApB82C' '/lib/modules/6.19.11+kali-amd64/modules.alias' 2>/dev/null | grep -E '88x2bu|rtl88x2bu|rtw88_8822bu' || true; echo; modprobe -n -v 88x2bu 2>/dev/null || true; echo; modprobe -n -v rtw88_8822bu 2>/dev/null || true
alias usb:v2357p012Ed*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v2357p012Dd*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v0BDApB82Cd*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v0BDApB812d*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v2357p012Ed*dc*dsc*dp*icFFiscFFipFFin* 88x2bu
alias usb:v2357p012Dd*dc*dsc*dp*icFFiscFFipFFin* 88x2bu
alias usb:v0BDApB812d*dc*dsc*dp*icFFiscFFipFFin* 88x2bu
alias usb:v0BDApB82Cd*dc*dsc*dp*icFFiscFFipFFin* 88x2bu


insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_core.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_8822b.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_usb.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_8822bu.ko.xz 

EXIT_CODE=0
```

## Current AP interface binding
```text
$ bash -c ip -br link show 'wlan1' 2>/dev/null || true; readlink -f /sys/class/net/wlan1/device/driver 2>/dev/null || true; cat /sys/class/net/wlan1/device/uevent 2>/dev/null || true
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

## Initrd file and initramfs content markers
```text
$ bash -c ls -lh '/boot/initrd.img-6.19.11+kali-amd64' 2>/dev/null || true; if command -v lsinitramfs >/dev/null 2>&1 && [ -f '/boot/initrd.img-6.19.11+kali-amd64' ]; then lsinitramfs '/boot/initrd.img-6.19.11+kali-amd64' 2>/dev/null | grep -E 'rtl88x2bu-local.conf|88x2bu|rtw88_8822bu|modprobe.d' || true; else echo 'lsinitramfs unavailable or initrd missing'; fi
-rw-r--r-- 1 root root 210M 29 avr 19:51 /boot/initrd.img-6.19.11+kali-amd64
etc/modprobe.d
etc/modprobe.d/amd64-microcode-blacklist.conf
etc/modprobe.d/ath9k_htc.conf
etc/modprobe.d/dkms.conf
etc/modprobe.d/intel-microcode-blacklist.conf
etc/modprobe.d/kali-defaults.conf
usr/lib/modprobe.d
usr/lib/modprobe.d/aliases.conf
usr/lib/modprobe.d/fbdev-blacklist.conf
usr/lib/modprobe.d/systemd.conf
usr/lib/modprobe.d/virtualbox-dkms.conf

EXIT_CODE=0
```

## Script-local files
```text
$ bash -c ls -lh '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/output4ChatGPT.*.rtl88x2bu-initramfs-finalize.md '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/rtl88x2bu_initramfs_finalize.*.log '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/rtl88x2bu_initramfs_finalize.state '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/backup_rtl88x2bu_initramfs_* 2>/dev/null || true
-rw-rw-r-- 1 nox nox 11K 30 avr 00:32 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-30_003206.rtl88x2bu-initramfs-finalize.md
-rw-rw-r-- 1 nox nox 11K 30 avr 00:32 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-30_003217.rtl88x2bu-initramfs-finalize.md
-rw-rw-r-- 1 nox nox   0 30 avr 00:32 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_initramfs_finalize.2026-04-30_003206.log
-rw-rw-r-- 1 nox nox   0 30 avr 00:32 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_initramfs_finalize.2026-04-30_003217.log

EXIT_CODE=0
```

## Important validation

This section is read-only. It does not reload anything.

## Validation 1 - installed module exists and matches kernel
```text
$ bash -c test -f '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' && echo INSTALLED_MODULE_PRESENT=YES || echo INSTALLED_MODULE_PRESENT=NO; echo MODULE_VERMAGIC=$(modinfo -F vermagic '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' 2>/dev/null || true); echo KERNEL='6.19.11+kali-amd64'; vm=$(modinfo -F vermagic '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' 2>/dev/null | awk '{print $1}'); [ "$vm" = '6.19.11+kali-amd64' ] && echo VERMAGIC_MATCH=YES || echo VERMAGIC_MATCH=NO
INSTALLED_MODULE_PRESENT=YES
MODULE_VERMAGIC=6.19.11+kali-amd64 SMP preempt mod_unload
KERNEL=6.19.11+kali-amd64
VERMAGIC_MATCH=YES

EXIT_CODE=0
```

## Validation 2 - modprobe blacklist config
```text
$ bash -c test -f '/etc/modprobe.d/rtl88x2bu-local.conf' && echo MODPROBE_CONF_PRESENT=YES || echo MODPROBE_CONF_PRESENT=NO; grep -nE 'blacklist +(rtw88_8822bu|rtw88_usb|rtw88_8822b|rtw88_core)' '/etc/modprobe.d/rtl88x2bu-local.conf' 2>/dev/null || true; for m in rtw88_8822bu rtw88_usb rtw88_8822b rtw88_core; do grep -qE "^blacklist +$m( |$)" '/etc/modprobe.d/rtl88x2bu-local.conf' 2>/dev/null && echo BLACKLIST_$m=YES || echo BLACKLIST_$m=NO; done
MODPROBE_CONF_PRESENT=YES
4:blacklist rtw88_8822bu
5:blacklist rtw88_usb
6:blacklist rtw88_8822b
7:blacklist rtw88_core
BLACKLIST_rtw88_8822bu=YES
BLACKLIST_rtw88_usb=YES
BLACKLIST_rtw88_8822b=YES
BLACKLIST_rtw88_core=YES

EXIT_CODE=0
```

## Validation 3 - depmod database contains local 88x2bu alias
```text
$ bash -c grep -E 'usb:v2357p012D|usb:v2357p012E|usb:v0BDApB812|usb:v0BDApB82C' '/lib/modules/6.19.11+kali-amd64/modules.alias' 2>/dev/null | grep -E '88x2bu|rtl88x2bu|rtw88_8822bu' || true; echo; grep -E 'usb:v2357p012D.* 88x2bu' '/lib/modules/6.19.11+kali-amd64/modules.alias' 2>/dev/null && echo LOCAL_ALIAS_FOR_TPLINK_012D=YES || echo LOCAL_ALIAS_FOR_TPLINK_012D=NO
alias usb:v2357p012Ed*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v2357p012Dd*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v0BDApB82Cd*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v0BDApB812d*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v2357p012Ed*dc*dsc*dp*icFFiscFFipFFin* 88x2bu
alias usb:v2357p012Dd*dc*dsc*dp*icFFiscFFipFFin* 88x2bu
alias usb:v0BDApB812d*dc*dsc*dp*icFFiscFFipFFin* 88x2bu
alias usb:v0BDApB82Cd*dc*dsc*dp*icFFiscFFipFFin* 88x2bu

alias usb:v2357p012Dd*dc*dsc*dp*icFFiscFFipFFin* 88x2bu
LOCAL_ALIAS_FOR_TPLINK_012D=YES

EXIT_CODE=0
```

## Validation 4 - live AP driver binding if AP interface exists
```text
$ bash -c if [ -e /sys/class/net/wlan1/device/driver ]; then echo AP_IF_PRESENT=YES; drv=$(basename $(readlink -f /sys/class/net/wlan1/device/driver 2>/dev/null)); echo AP_IF_DRIVER=$drv; [ "$drv" = 'rtl88x2bu' ] && echo AP_IF_DRIVER_EXPECTED=YES || echo AP_IF_DRIVER_EXPECTED=NO; cat /sys/class/net/wlan1/device/uevent 2>/dev/null || true; else echo AP_IF_PRESENT=NO; fi
AP_IF_PRESENT=YES
AP_IF_DRIVER=rtl88x2bu
AP_IF_DRIVER_EXPECTED=YES
DEVTYPE=usb_interface
DRIVER=rtl88x2bu
PRODUCT=2357/12d/210
TYPE=0/0/0
INTERFACE=255/255/255
MODALIAS=usb:v2357p012Dd0210dc00dsc00dp00icFFiscFFipFFin00

EXIT_CODE=0
```

## Validation 5 - initramfs contains modprobe config marker if lsinitramfs is available
```text
$ bash -c if command -v lsinitramfs >/dev/null 2>&1 && [ -f '/boot/initrd.img-6.19.11+kali-amd64' ]; then lsinitramfs '/boot/initrd.img-6.19.11+kali-amd64' 2>/dev/null | grep -F 'etc/modprobe.d/rtl88x2bu-local.conf' && echo INITRAMFS_MODPROBE_CONF_PRESENT=YES || echo INITRAMFS_MODPROBE_CONF_PRESENT=NO; else echo INITRAMFS_CHECK_SKIPPED=YES; fi
INITRAMFS_MODPROBE_CONF_PRESENT=NO

EXIT_CODE=0
```

## Final verdict

**STATUS: OK**

Validation passed for installed module, vermagic, blacklist config, depmod local alias, and live AP binding when present.

