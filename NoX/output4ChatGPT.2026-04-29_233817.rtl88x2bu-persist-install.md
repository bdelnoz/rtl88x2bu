# rtl88x2bu persistent install report

- Generated at: 2026-04-29_233817
- Script version: 1.0.5
- Mode: --exec
- Hostname: koutoubia
- User: root
- SUDO_USER: nox
- EUID: 0
- Kernel: 6.19.11+kali-amd64
- Script path: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.sh
- Script directory: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX
- Repo: /mnt/data2_78g/Security/scripts/rtl88x2bu
- Requested module: auto
- Install path: /lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko
- Modprobe config: /etc/modprobe.d/rtl88x2bu-local.conf
- State file: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.state
- Report: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_233817.rtl88x2bu-persist-install.md
- Log: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.2026-04-29_233817.log
- AP interface checked by validation: wlan1

## Initial verdict

**STATUS: RUNNING**

## Safety statement

This script performs persistent module-file installation/reversal/validation only.

No DKMS action, make install, modprobe live-load, insmod, initramfs update, NetworkManager setting change, service restart, or reboot is performed.

All reports, logs, state files, and backup copies produced by this script are written directly into the same directory as this script. No report/backup/state subfolder is created by this script.

## Selected module
```text
-rw-rw-r-- 1 nox nox 8,0M 29 avr 22:04 /tmp/rtl88x2bu-buildtest-2026-04-29_220116/src/88x2bu.ko
filename:       /tmp/rtl88x2bu-buildtest-2026-04-29_220116/src/88x2bu.ko
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
parm:           rtw_power_mgnt:int
parm:           rtw_smart_ps:int
parm:           rtw_low_power:int
parm:           rtw_wifi_spec:int
parm:           rtw_full_ch_in_p2p_handshake:int
parm:           rtw_antdiv_cfg:int
parm:           rtw_antdiv_type:int
parm:           rtw_drv_ant_band_switch:int
parm:           rtw_single_ant_path:int
parm:           rtw_switch_usb_mode:int
parm:           rtw_enusbss:int
parm:           rtw_hwpdn_mode:int
parm:           rtw_hwpwrp_detect:int
parm:           rtw_hw_wps_pbc:int
parm:           rtw_check_hw_status:int
parm:           rtw_max_roaming_times:The max roaming times to try (uint)
parm:           rtw_mc2u_disable:int
parm:           rtw_advnace_ota:int
parm:           rtw_notch_filter:0:Disable, 1:Enable, 2:Enable only for P2P (uint)
parm:           rtw_hiq_filter:0:allow all, 1:allow special, 2:deny all (uint)
parm:           rtw_adaptivity_en:0:disable, 1:enable (uint)
parm:           rtw_adaptivity_mode:0:normal, 1:carrier sense (uint)
parm:           rtw_adaptivity_th_l2h_ini:th_l2h_ini for Adaptivity (int)
parm:           rtw_adaptivity_th_edcca_hl_diff:th_edcca_hl_diff for Adaptivity (int)
parm:           rtw_dfs_region_domain:0:UNKNOWN, 1:FCC, 2:MKK, 3:ETSI (uint)
parm:           rtw_amplifier_type_2g:BIT3:2G ext-PA, BIT4:2G ext-LNA (uint)
parm:           rtw_amplifier_type_5g:BIT6:5G ext-PA, BIT7:5G ext-LNA (uint)
parm:           rtw_RFE_type:default init value:64 (uint)
parm:           rtw_powertracking_type:default init value:64 (uint)
parm:           rtw_GLNA_type:default init value:0 (uint)
parm:           rtw_TxBBSwing_2G:default init value:0xFF (uint)
parm:           rtw_TxBBSwing_5G:default init value:0xFF (uint)
parm:           rtw_OffEfuseMask:default open Efuse Mask value:0 (uint)
parm:           rtw_FileMaskEfuse:default drv Mask Efuse value:0 (uint)
parm:           rtw_rxgain_offset_2g:default RF Gain 2G Offset value:0 (uint)
parm:           rtw_rxgain_offset_5gl:default RF Gain 5GL Offset value:0 (uint)
parm:           rtw_rxgain_offset_5gh:uint
parm:           rtw_rxgain_offset_5gm:default RF Gain 5GM Offset value:0 (uint)
parm:           rtw_pll_ref_clk_sel:force pll_ref_clk_sel, 0xF:use autoload value (uint)
parm:           rtw_tx_pwr_by_rate:0:Disable, 1:Enable, 2: Depend on efuse (int)
parm:           rtw_tx_pwr_lmt_enable:0:Disable, 1:Enable, 2: Depend on efuse (int)
parm:           rtw_target_tx_pwr_2g_a:2.4G target tx power (unit:dBm) of RF path A for each rate section, should match the real calibrate power, -1: undefined (array of int)
parm:           rtw_target_tx_pwr_2g_b:2.4G target tx power (unit:dBm) of RF path B for each rate section, should match the real calibrate power, -1: undefined (array of int)
parm:           rtw_target_tx_pwr_2g_c:2.4G target tx power (unit:dBm) of RF path C for each rate section, should match the real calibrate power, -1: undefined (array of int)
parm:           rtw_target_tx_pwr_2g_d:2.4G target tx power (unit:dBm) of RF path D for each rate section, should match the real calibrate power, -1: undefined (array of int)
parm:           rtw_target_tx_pwr_5g_a:5G target tx power (unit:dBm) of RF path A for each rate section, should match the real calibrate power, -1: undefined (array of int)
parm:           rtw_target_tx_pwr_5g_b:5G target tx power (unit:dBm) of RF path B for each rate section, should match the real calibrate power, -1: undefined (array of int)
parm:           rtw_target_tx_pwr_5g_c:5G target tx power (unit:dBm) of RF path C for each rate section, should match the real calibrate power, -1: undefined (array of int)
parm:           rtw_target_tx_pwr_5g_d:5G target tx power (unit:dBm) of RF path D for each rate section, should match the real calibrate power, -1: undefined (array of int)
parm:           rtw_tsf_update_pause_factor:num of bcn intervals to stay TSF update pause status (int)
parm:           rtw_tsf_update_restore_factor:num of bcn intervals to stay TSF update restore status (int)
parm:           rtw_phy_file_path:The path of phy parameter (charp)
parm:           rtw_load_phy_file:PHY File Bit Map (int)
parm:           rtw_decrypt_phy_file:Enable Decrypt PHY File (int)
parm:           rtw_phydm_ability:uint
parm:           rtw_halrf_ability:uint
parm:           rtw_vht_2g4:Allow VHT rate on 2.4G channel.(0 for deny and 1 for allow) (int)
parm:           rtw_en_napi:int
parm:           rtw_en_gro:int
parm:           rtw_iqk_fw_offload:int
parm:           rtw_ch_switch_offload:int
```

## Backup existing files into script directory
```text
Backup install module: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/backup_rtl88x2bu_2026-04-29_233817_88x2bu.ko
Backup modprobe config: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/backup_rtl88x2bu_2026-04-29_233817_rtl88x2bu-local.conf
```

## Install module file
```text
Installed module:
-rw-r--r-- 1 nox nox 8,0M 29 avr 22:04 /lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko
```

## Write modprobe config
```text
# Generated by /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.sh on 2026-04-29_233817
# Purpose: prefer local rtl88x2bu/88x2bu driver over in-kernel rtw88_8822bu for RTL8812BU/RTL8822BU testing.
# Reverse with: sudo /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.sh --reverse
blacklist rtw88_8822bu
blacklist rtw88_usb
blacklist rtw88_8822b
blacklist rtw88_core
```

## Run depmod for active kernel
```text

EXIT_CODE=0
```

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

## Installed module path
```text
$ ls -lh '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' 2>/dev/null || true; modinfo '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' 2>/dev/null | sed -n '1,100p' || true
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
parm:           rtw_power_mgnt:int
parm:           rtw_smart_ps:int
parm:           rtw_low_power:int
parm:           rtw_wifi_spec:int
parm:           rtw_full_ch_in_p2p_handshake:int
parm:           rtw_antdiv_cfg:int
parm:           rtw_antdiv_type:int
parm:           rtw_drv_ant_band_switch:int
parm:           rtw_single_ant_path:int
parm:           rtw_switch_usb_mode:int
parm:           rtw_enusbss:int
parm:           rtw_hwpdn_mode:int
parm:           rtw_hwpwrp_detect:int
parm:           rtw_hw_wps_pbc:int
parm:           rtw_check_hw_status:int
parm:           rtw_max_roaming_times:The max roaming times to try (uint)
parm:           rtw_mc2u_disable:int
parm:           rtw_advnace_ota:int
parm:           rtw_notch_filter:0:Disable, 1:Enable, 2:Enable only for P2P (uint)
parm:           rtw_hiq_filter:0:allow all, 1:allow special, 2:deny all (uint)

EXIT_CODE=0

## Modprobe config
```text
$ ls -lh '/etc/modprobe.d/rtl88x2bu-local.conf' 2>/dev/null || true; sed -n '1,200p' '/etc/modprobe.d/rtl88x2bu-local.conf' 2>/dev/null || true
-rw-r--r-- 1 root root 412 29 avr 23:38 /etc/modprobe.d/rtl88x2bu-local.conf
# Generated by /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.sh on 2026-04-29_233817
# Purpose: prefer local rtl88x2bu/88x2bu driver over in-kernel rtw88_8822bu for RTL8812BU/RTL8822BU testing.
# Reverse with: sudo /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.sh --reverse
blacklist rtw88_8822bu
blacklist rtw88_usb
blacklist rtw88_8822b
blacklist rtw88_core

EXIT_CODE=0

## depmod/module alias resolution
```text
$ modprobe -n -v 88x2bu 2>/dev/null || true; modprobe -n -v rtl88x2bu 2>/dev/null || true; modprobe -n -v rtw88_8822bu 2>/dev/null || true
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_core.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_8822b.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_usb.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_8822bu.ko.xz 

EXIT_CODE=0

## Current wlan1 binding
```text
$ ip -br link show 'wlan1' 2>/dev/null || true; readlink -f /sys/class/net/wlan1/device/driver 2>/dev/null || true; cat /sys/class/net/wlan1/device/uevent 2>/dev/null || true
wlan1            UP             48:22:54:1c:3b:af <BROADCAST,MULTICAST,UP,LOWER_UP> 
/sys/bus/usb/drivers/rtl88x2bu
DEVTYPE=usb_interface
DRIVER=rtl88x2bu
PRODUCT=2357/12d/210
TYPE=0/0/0
INTERFACE=255/255/255
MODALIAS=usb:v2357p012Dd0210dc00dsc00dp00icFFiscFFipFFin00

EXIT_CODE=0

## Script-local files
```text
$ ls -lh '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/output4ChatGPT.*.rtl88x2bu-persist-install.md '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/rtl88x2bu_persist_install.state '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/backup_rtl88x2bu_* 2>/dev/null || true
-rw-r--r-- 1 nox  nox  8,0M 29 avr 22:04 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/backup_rtl88x2bu_2026-04-29_233817_88x2bu.ko
-rw-r--r-- 1 root root  412 29 avr 23:28 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/backup_rtl88x2bu_2026-04-29_233817_rtl88x2bu-local.conf
-rw-r--r-- 1 nox  nox  4,5K 29 avr 23:27 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_232716.rtl88x2bu-persist-install.md
-rw-r--r-- 1 nox  nox   21K 29 avr 23:28 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_232817.rtl88x2bu-persist-install.md
-rw-r--r-- 1 root root  20K 29 avr 23:38 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_233817.rtl88x2bu-persist-install.md
-rw-r--r-- 1 nox  nox   407 29 avr 23:38 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.state

EXIT_CODE=0

## Important post-persist validation

This section is read-only. It proves what is installed, what is configured, and what is currently bound. It does not reload anything.

## Validation 1 - installed module exists and matches kernel
```text
$ test -f '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' && echo INSTALLED_MODULE_PRESENT=YES || echo INSTALLED_MODULE_PRESENT=NO; echo MODULE_VERMAGIC=$(modinfo -F vermagic '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' 2>/dev/null || true); echo KERNEL='6.19.11+kali-amd64'; vm=$(modinfo -F vermagic '/lib/modules/6.19.11+kali-amd64/extra/rtl88x2bu/88x2bu.ko' 2>/dev/null | awk '{print $1}'); [ "$vm" = '6.19.11+kali-amd64' ] && echo VERMAGIC_MATCH=YES || echo VERMAGIC_MATCH=NO
INSTALLED_MODULE_PRESENT=YES
MODULE_VERMAGIC=6.19.11+kali-amd64 SMP preempt mod_unload
KERNEL=6.19.11+kali-amd64
VERMAGIC_MATCH=YES

EXIT_CODE=0

## Validation 2 - modprobe blacklist config
```text
$ test -f '/etc/modprobe.d/rtl88x2bu-local.conf' && echo MODPROBE_CONF_PRESENT=YES || echo MODPROBE_CONF_PRESENT=NO; grep -nE 'blacklist +(rtw88_8822bu|rtw88_usb|rtw88_8822b|rtw88_core)' '/etc/modprobe.d/rtl88x2bu-local.conf' 2>/dev/null || true; for m in rtw88_8822bu rtw88_usb rtw88_8822b rtw88_core; do grep -qE "^blacklist +$m( |$)" '/etc/modprobe.d/rtl88x2bu-local.conf' 2>/dev/null && echo BLACKLIST_$m=YES || echo BLACKLIST_$m=NO; done
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

## Validation 3 - depmod database contains 88x2bu aliases
```text
$ grep -E 'usb:v2357p012D|usb:v2357p012E|usb:v0BDApB812|usb:v0BDApB82C' '/lib/modules/6.19.11+kali-amd64/modules.alias' 2>/dev/null | grep -E '88x2bu|rtl88x2bu|rtw88_8822bu' || true; echo; grep -E 'usb:v2357p012D' '/lib/modules/6.19.11+kali-amd64/modules.alias' 2>/dev/null || true
alias usb:v2357p012Ed*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v2357p012Dd*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v0BDApB82Cd*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v0BDApB812d*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v2357p012Ed*dc*dsc*dp*icFFiscFFipFFin* 88x2bu
alias usb:v2357p012Dd*dc*dsc*dp*icFFiscFFipFFin* 88x2bu
alias usb:v0BDApB812d*dc*dsc*dp*icFFiscFFipFFin* 88x2bu
alias usb:v0BDApB82Cd*dc*dsc*dp*icFFiscFFipFFin* 88x2bu

alias usb:v2357p012Dd*dc*dsc*dp*icFFiscFFipFFin* rtw88_8822bu
alias usb:v2357p012Dd*dc*dsc*dp*icFFiscFFipFFin* 88x2bu

EXIT_CODE=0

## Validation 4 - dry-run module commands only
```text
$ echo 'modprobe -n -v 88x2bu:'; modprobe -n -v 88x2bu 2>/dev/null || true; echo; echo 'modprobe -n -v rtw88_8822bu direct command still shows direct load even when blacklisted; blacklist affects autoload by alias, not necessarily manual modprobe:'; modprobe -n -v rtw88_8822bu 2>/dev/null || true
modprobe -n -v 88x2bu:

modprobe -n -v rtw88_8822bu direct command still shows direct load even when blacklisted; blacklist affects autoload by alias, not necessarily manual modprobe:
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_core.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_8822b.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_usb.ko.xz 
insmod /lib/modules/6.19.11+kali-amd64/kernel/drivers/net/wireless/realtek/rtw88/rtw88_8822bu.ko.xz 

EXIT_CODE=0

## Validation 5 - live wlan1 driver binding
```text
$ if [ -e /sys/class/net/wlan1/device/driver ]; then echo AP_IF_PRESENT=YES; drv=$(basename $(readlink -f /sys/class/net/wlan1/device/driver 2>/dev/null)); echo AP_IF_DRIVER=$drv; [ "$drv" = 'rtl88x2bu' ] && echo AP_IF_DRIVER_EXPECTED=YES || echo AP_IF_DRIVER_EXPECTED=NO; cat /sys/class/net/wlan1/device/uevent 2>/dev/null || true; else echo AP_IF_PRESENT=NO; fi
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

## Validation 6 - no initramfs artefact touched by this script
```text
$ grep -R 'rtl88x2bu_persist_install' /etc/initramfs-tools /boot 2>/dev/null || true; echo 'EXPECTED: no output or unrelated output only.'
EXPECTED: no output or unrelated output only.

EXIT_CODE=0

## Validation 7 - script-local artifact location
```text
$ echo SCRIPT_DIR='/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'; echo REPORT='/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_233817.rtl88x2bu-persist-install.md'; echo LOG='/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.2026-04-29_233817.log'; echo STATE_FILE='/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.state'; case '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_233817.rtl88x2bu-persist-install.md' in '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/*) echo REPORT_IN_SCRIPT_DIR=YES ;; *) echo REPORT_IN_SCRIPT_DIR=NO ;; esac; case '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.2026-04-29_233817.log' in '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/*) echo LOG_IN_SCRIPT_DIR=YES ;; *) echo LOG_IN_SCRIPT_DIR=NO ;; esac; ls -lh '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/output4ChatGPT.*.rtl88x2bu-persist-install.md '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/rtl88x2bu_persist_install.*.log '/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX'/rtl88x2bu_persist_install.state 2>/dev/null || true
SCRIPT_DIR=/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX
REPORT=/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_233817.rtl88x2bu-persist-install.md
LOG=/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.2026-04-29_233817.log
STATE_FILE=/mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.state
REPORT_IN_SCRIPT_DIR=YES
LOG_IN_SCRIPT_DIR=YES
-rw-r--r-- 1 nox  nox  4,5K 29 avr 23:27 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_232716.rtl88x2bu-persist-install.md
-rw-r--r-- 1 nox  nox   21K 29 avr 23:28 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_232817.rtl88x2bu-persist-install.md
-rw-r--r-- 1 root root  27K 29 avr 23:38 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/output4ChatGPT.2026-04-29_233817.rtl88x2bu-persist-install.md
-rw-r--r-- 1 nox  nox    10 29 avr 23:28 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.2026-04-29_232817.log
-rw-r--r-- 1 root root    0 29 avr 23:38 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.2026-04-29_233817.log
-rw-r--r-- 1 nox  nox   407 29 avr 23:38 /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX/rtl88x2bu_persist_install.state

EXIT_CODE=0

## Final verdict

**STATUS: OK**

Persistent file install completed. Reboot or a controlled unload/reload is still needed to validate auto-binding after boot.

## Final safety confirmation
```text
No DKMS action was performed.
No make install was performed.
No modprobe live-load was performed.
No insmod was performed.
No initramfs was changed.
No NetworkManager setting was changed.
No service was restarted.
No reboot was requested.
Report/log/state/backups produced by this script are directly in: /mnt/data2_78g/Security/scripts/rtl88x2bu/NoX
```
