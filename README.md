# Dracut module fido2-nosystemd

⚠️ **Use at own risk and consider this plugin to be experimental right now.** ⚠️

THE PROBLEM: the [dracut fido2](https://github.com/dracutdevs/dracut/blob/master/modules.d/91fido2/module-setup.sh) depends on 2 modules that are [incompatible with ZBM](https://github.com/zbm-dev/zfsbootmenu/blob/master/etc/zfsbootmenu/dracut.conf.d/zfsbootmenu.conf#L3):

- module 'fido2' depends on 'systemd-udevd'
- module 'systemd-udevd' depends on 'systemd'

This module adds the required libraries/files without the systemd full dependencies.

⚠️ **Known issues (WIP):** ⚠️

- the recovery image containing the SSH server does not start automatically ([Github issue](https://github.com/dracutdevs/dracut/issues/2620)), it requires manual intervention:
  - enter LUKS password during ZBM boot
  - press `ESC` at the ZBM menu & enter shell (press `CTRL` + `R`)
    - Initialize network: `dhclient eth0`
    - See assigned IP: `ip a`

## Requirements

- [libfido2](https://developers.yubico.com/libfido2/) - on Debian: `apt install fido2-tools`
- cryptsetup (or if on testing branch: systemd-cryptsetup)

```bash
# On Debian testing, you MUST install the systemd-cryptsetup pkg
# Without it, you might see the following:
# dracut-initqueue[625]: Failed to start cryptsetup.target: Unit cryptsetup.target not found.

# On Debian Bookworm
# Version that is known to work with FIDO2 token support
apt list cryptsetup
cryptsetup/stable,now 2:2.6.1-4~deb12u2 amd64 [installed]
```

- A compatible fido2 token (e.g. Yubikey, Nitrokey) that supports the **hmac-secret** extension

## Installation

Copy the `91fido2-nosystemd` module into the Dracut module directory:

```bash
cp -ri 91fido2-nosystemd /usr/lib/dracut/modules.d
```

The module is NOT enabled by default. Add it to your config: `add_dracutmodules+=" fido2-nosystemd "`.

### Via Taskfile

You can [install Task](https://taskfile.dev/installation) to automate the commands:

```bash
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

mkdir -p /usr/local/src/fido2-nosystemd
cd /usr/local/src/fido2-nosystemd && git clone https://github.com/Adito5393/fido2-nosystemd.git .

task --list-all
```

## Troubleshoot commands

To unlock LUKS with FIDO2 only:

```bash
# nano /etc/zfsbootmenu/open-luks-fido2.sh
# ADD it via dracut config: install_items+=" /etc/zfsbootmenu/open-luks-fido2.sh "

cryptsetup open --token-only --debug /dev/disk/by-label/KEYSTORE KEYSTORE

# To close:
# cryptsetup close KEYSTORE
```

Plug in the FIDO2 key and check that it's correctly detected:

```bash
fido2-token -L
/dev/hidraw1: vendor=0x1050, product=0x0407 (Yubico YubiKey OTP+FIDO+CCID)
```

You can check whether or not your token is suitable by executing `fido2-token -I /dev/hidraw0 | grep hmac-secret` (use `fido2-token -L` to get the correct `/dev/hidrawX` path). For valid authenticators it will match a line like "extension strings: credProtect, hmac-secret".

Use ldd to determine the library's dependencies, for example:

```bash
ldd /usr/lib/x86_64-linux-gnu/cryptsetup/libcryptsetup-token-systemd-fido2.so
        linux-vdso.so.1 (0x00007ffdab7bc000)
        libsystemd-shared-252.so => /usr/lib/x86_64-linux-gnu/systemd/libsystemd-shared-252.so (0x00007f2a58d82000)
        libcryptsetup.so.12 => /lib/x86_64-linux-gnu/libcryptsetup.so.12 (0x00007f2a58cfc000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f2a58b1b000)
        libacl.so.1 => /lib/x86_64-linux-gnu/libacl.so.1 (0x00007f2a58b10000)
        libblkid.so.1 => /lib/x86_64-linux-gnu/libblkid.so.1 (0x00007f2a58ab9000)
        libcap.so.2 => /lib/x86_64-linux-gnu/libcap.so.2 (0x00007f2a58aab000)
        libcrypt.so.1 => /lib/x86_64-linux-gnu/libcrypt.so.1 (0x00007f2a58a6f000)
        libgcrypt.so.20 => /lib/x86_64-linux-gnu/libgcrypt.so.20 (0x00007f2a58928000)
        libip4tc.so.2 => /lib/x86_64-linux-gnu/libip4tc.so.2 (0x00007f2a5891e000)
        libkmod.so.2 => /lib/x86_64-linux-gnu/libkmod.so.2 (0x00007f2a58901000)
        liblz4.so.1 => /lib/x86_64-linux-gnu/liblz4.so.1 (0x00007f2a588db000)
        libmount.so.1 => /lib/x86_64-linux-gnu/libmount.so.1 (0x00007f2a58876000)
        libcrypto.so.3 => /lib/x86_64-linux-gnu/libcrypto.so.3 (0x00007f2a583f0000)
        libpam.so.0 => /lib/x86_64-linux-gnu/libpam.so.0 (0x00007f2a583de000)
        libseccomp.so.2 => /lib/x86_64-linux-gnu/libseccomp.so.2 (0x00007f2a583be000)
        libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007f2a58390000)
        libzstd.so.1 => /lib/x86_64-linux-gnu/libzstd.so.1 (0x00007f2a582d4000)
        liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007f2a582a3000)
        libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f2a581c4000)
        /lib64/ld-linux-x86-64.so.2 (0x00007f2a590bc000)
        libuuid.so.1 => /lib/x86_64-linux-gnu/libuuid.so.1 (0x00007f2a581ba000)
        libdevmapper.so.1.02.1 => /lib/x86_64-linux-gnu/libdevmapper.so.1.02.1 (0x00007f2a5814d000)
        libargon2.so.1 => /lib/x86_64-linux-gnu/libargon2.so.1 (0x00007f2a58143000)
        libjson-c.so.5 
```

### Dracut Diagnostics

```bash
lsinitrd /boot/efi/EFI/ZBM/vmlinuz-2.3.0_3.EFI
lsinitrd /boot/initrd.img-6.9.9-amd64 -f etc/crypttab
```

Inside the initramfs, inspect the system logs:

```bash
less /run/initramfs/rdsosreport.txt
journalctl -a
dmesg
less /run/initramfs/init.log
```

### Check Existing Key Slots

```bash
systemd-cryptenroll /dev/nvme2n1p3
```

## ZBM

Build it from source as [the docs](https://docs.zfsbootmenu.org/en/v2.3.x/guides/debian/bookworm-uefi.html#install-zfsbootmenu) recommend it.

Following the [ZBM binaries releases](https://docs.zfsbootmenu.org/en/v2.3.x/general/binary-releases.html), both contain the FIDO2 module to unlock a LUKS partition:

- release
- recovery
  - [Remote SSH Access](https://docs.zfsbootmenu.org/en/v2.3.x/general/remote-access.html)

To install `crypt-ssh`, see the [official repo](https://github.com/dracut-crypt-ssh/dracut-crypt-ssh) or use the version here (`task initial-setup:install-crypt-ssh-nohelpers`).
If you use dracut on the host also, add:

```bash
nano /etc/dracut.conf.d/ssh.conf
omit_dracutmodules+=" crypt-ssh "
```

Inform dracut-network that it must bring up a network interface:

```bash
mkdir -p /etc/cmdline.d
echo "ip=dhcp rd.neednet=1 loglevel=7 zbm.timeout=60" > /etc/cmdline.d/dracut-network.conf
```

Or if you use refind:

```bash
refind-install
rm /boot/refind_linux.conf

cat << EOF > /boot/efi/EFI/ZBM/refind_linux.conf
"Boot with network"  "ip=dhcp rd.neednet=1 loglevel=7 zbm.timeout=60"
"Boot to menu"  "quiet loglevel=0 zbm.show"
EOF
```

Configuring Dropbear

```bash
apt install dropbear

mkdir -p /etc/dropbear
for keytype in rsa ecdsa ed25519; do
    dropbearkey -t "${keytype}" -f "/etc/dropbear/dropbear_${keytype}_host_zbm_key"
done

ln -s "${HOME}/.ssh/authorized_keys" /etc/dropbear/root_key
```

Build it:

```bash
# Clean up old configs:
rm -rf /etc/zfsbootmenu/dracut.conf.d
mkdir -p /etc/zfsbootmenu/dracut.conf.d
# For release build:
cp zfsbootmenu/release.conf.d/*.conf /etc/zfsbootmenu/dracut.conf.d/
# For recovery with remote access:
cp zfsbootmenu/recovery.conf.d/*.conf /etc/zfsbootmenu/dracut.conf.d/

generate-zbm --debug
```

After testing it, rename it to avoid future builds pruning it:

```bash
cd /boot/efi/EFI/ZBM
mv vmlinuz-2.3.0_BUILD_NUMBER.EFI vmlinuz-recovery.EFI
# Or for release:
mv vmlinuz-2.3.0_BUILD_NUMBER.EFI vmlinuz-release.EFI
```

## Resources

- Sithuk's [Ubuntu zfsbootmenu install script](https://github.com/Sithuk/ubuntu-server-zfsbootmenu)
- [How to debug Dracut problems](https://fedoraproject.org/wiki/How_to_debug_Dracut_problems)
