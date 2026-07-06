# RVA + DriverStart

An RVA (*Relative Virtual Address*) is an offset from a module's image base, it stays the same when ASLR relocates the image, while the absolute virtual address changes.

```c
RVA = IDA address - IDA image base
runtime address = DriverStart + RVA
```

This is useful whenever you want to read the current state of a global variable that is not available by name in WinDbg. See the [MMCSS values RVA calculation](https://noverse.dev/docs/win-config/system/mmcss-values/#driverstart--rvas) as a practical example.

## RVA in IDA

For example, IDA shows `CiSystemResponsiveness` at:

```asm
.data:00000001C00082F8 CiSystemResponsiveness dd 0
```

The IDA database image base is `0x1C0000000` (shown under `Edit > Segments > Rebase program`):

```c
RVA = 0x1C00082F8 - 0x1C0000000 = 0x82F8
```

## DriverStart

`DriverStart` ("*Points to the base virtual address where the driver image is loaded in system memory. This address represents the beginning of the driver's code section in the kernel address space. The I/O manager sets this value when the driver is loaded.*") is the address at which the image is loaded in the current system. The simplest way to get it is the via module start address shown by `lm`:

```c
lkd> lm m mmcss
Browse full module list
start             end                 module name
fffff800`50950000 fffff800`50966000   mmcss      (pdb symbols)          C:\ProgramData\Dbg\sym\mmcss.pdb\9E36707273FDF82AB362DBA6ACCC09671\mmcss.pdb
```

It can also be read from the driver's `_DRIVER_OBJECT`:

```c
lkd> !drvobj \Driver\MMCSS
Driver object (ffffac819f21fe30) is for:
 \Driver\MMCSS

Driver Extension List: (id , addr)

Device Object list:
ffffac819f7e9df0  

lkd> dt nt!_DRIVER_OBJECT ffffac819f21fe30 DriverStart
   +0x018 DriverStart : 0xfffff800`50950000 Void
```

### _DRIVER_OBJECT Structure

```c
lkd> dt nt!_DRIVER_OBJECT
   +0x000 Type             : Int2B
   +0x002 Size             : Int2B
   +0x008 DeviceObject     : Ptr64 _DEVICE_OBJECT
   +0x010 Flags            : Uint4B
   +0x018 DriverStart      : Ptr64 Void
   +0x020 DriverSize       : Uint4B
   +0x028 DriverSection    : Ptr64 Void
   +0x030 DriverExtension  : Ptr64 _DRIVER_EXTENSION
   +0x038 DriverName       : _UNICODE_STRING
   +0x048 HardwareDatabase : Ptr64 _UNICODE_STRING
   +0x050 FastIoDispatch   : Ptr64 _FAST_IO_DISPATCH
   +0x058 DriverInit       : Ptr64     long 
   +0x060 DriverStartIo    : Ptr64     void 
   +0x068 DriverUnload     : Ptr64     void 
   +0x070 MajorFunction    : [28] Ptr64     long 
```

## Calculate Runtime Address

Add the RVA from IDA to `DriverStart`:

```c
runtime address = 0xfffff801`80740000 + 0x82F8 = 0xfffff801`807482F8
```

You can do the calculation via WinDbg:

```c
lkd> ? 0xfffff801`80740000+0x82f8
Evaluate expression: -8789642935560 = fffff801`807482f8
```

Read the address using the command that matches the variable's size. For the `CiSystemResponsiveness` example it is `dd`, so it is a 4-byte value.

```c
lkd> dd 0xfffff801`80740000+0x82f8 L1
fffff801`807482f8  0000000a // 10 dec
```
