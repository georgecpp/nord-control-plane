# OnePlus Nord device inventory

## Identity

- Manufacturer: OnePlus
- Model: AC2003
- Product codename: `avicii`
- Architecture: ARM64
- Serial number: intentionally omitted

## Installed platform

- Operating system: CherishOS 14
- Android version: 14
- Android build: `UP1A.231105.003`
- Android security patch: `2023-11-01`
- Active slot: A
- Kernel: `4.19.275-PSM-Kernel-v1.1-ga323f202d04b-dirty`
- Root: Magisk 29.0
- SELinux: enforcing
- Bootloader: unlocked
- Recovery ADB: working
- Bootloader fastboot: working
- Fastbootd: accessible

## Recovery preparation

Checksummed backups exist outside this repository for `boot`, `recovery`,
`dtbo` and `vbmeta` on both slots, plus `persist`, `modemst1`, `modemst2`,
`fsg` and `fsc`.

## Custom-kernel status

- Build version: `0.1.0`
- Successful CI run: `35522034398`
- Kernel source commit: `c43a2a9e1c9e67c814910286f3e6b77c80a8050d`
- Compiler: `clang-r530567`
- Build result: successful
- Temporarily boot-tested: no
- Permanently installed: no
