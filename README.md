# MiniDos
**A simple 16 bit OS that performs basic file system functions, like coping, deleting &amp; loading.**
## Features
**1)** general interrupt number : `0x21`

**2)** supports `FAT16`

**3)** supports multiple drivers, not only the `C` driver
## Functions
`loading`, `wirting`, `deleting`, `renaming files`, `saving changes`,as well as `copying files` from any driver to any driver & `alternating between drivers`

## Ram Structure
#### All addresses are physical addresses
**1)** `0x0500-0x06FF` = Bios parameter block

**2)** `0x0700-0x46FF` = Kernel file

**3)** `0x4700-0x8709` = Command prompt file

**4)** `0x8710-0x6FFEF` = Program segment for programs to run

**5)** `0x6FFF0-0X7FFFF` = reserved segment for temporary portions of data to be loaded at

*Reserved segment is used while deleting, copying, or even loading*
## Limitaions
**1)** doesn't support any file system other than `FAT16`

**2)** doesn't save changes that takes place in a file

**3)** only boots on `BIOS`, & doesn't boot on `UEFI`
