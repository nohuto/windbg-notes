# Symbols

Symbols include variable names (local/global), functions, and any entry point into a module.

## Reading Symbols

A global variable can be read directly through `module!symbol`, if the PDB doesn't include symbol, then the same can be read using its RVA + `DriverStart`. Examples from '[MMCSS Values](https://noverse.dev/docs/win-config/system/mmcss-values/)' section:

```c
lkd> dd mmcss!CiSystemResponsiveness L1
fffff801`890e82f8  00000014

lkd> db mmcss!CiSchedulerDisallowLazyMode L1
fffff801`890e82d5  00                                               .
```

### Mass Display Symbols

My old [`disp-sym.ps1`](https://github.com/nohuto/windbg-notes/blob/main/assets/disp-sym.ps1) script can be used to mass read symbols from a module, but its use is very limited as it reads every symbol with the same size, the only actual useful case for it would be to read `nt` symbols, as almost all symbols within [CmControlVector](https://noverse.dev/docs/win-config/system/kernel-values/#cmcontrolvector) have the same size (4 bytes).

| Button | Description |
| --- | --- |
| `New KD Session` | Starts a new Kernel Debugging (KD) session with `-kl` param |
| `Remove Dumps` | Removes all folders in `$env:localappdata\Noverse\Symbols` |
| `Reload Modules` | Reloads all modules using `.reload /f`, then lists the loaded modules with `lm` |
| `Phase Folder` | Opens `$env:localappdata\Noverse\Symbols`<br>Each `.txt` file is saved in its module folder using such a structure:<br> - `<module>-Symbols.txt`<br> - `<module>-Filtered.txt`<br> - `<module>-KD.txt`<br> - `<module>-Dump.txt` |
| `Dump` | Reads all symbols of the current selected module and writes them to the files |
| `1` | Length size, default is `1`, it might not work properly with a length of `8 <` |
| `dd` | Type of how the data should be displayed |

![](https://github.com/nohuto/windbg-notes/blob/main/assets/disp-sym.png?raw=true)

### Data Sizes

| Size | WinDbg |
| --- | --- |
| 1 byte | `db <symbol/address> L1` |
| 2 bytes |`dw <symbol/address> L1` |
| 4 bytes | `dd <symbol/address> L1` |
| 8 bytes | `dq <symbol/address> L1` |

First see whether the PDB shows type information:

```c
x /t <module>!<symbol>
?? sizeof(<module>!<symbol>)
```

Public symbols often show a globals name without its type, when that happens use the data definition in IDA, e.g. `KiSerializeTimerExpiration` is a 4 byte value, so read it with `dd`.

```c
lkd> x /t mmcss!CiSystemResponsiveness
fffff805`284482f8 <NoType> mmcss!CiSystemResponsiveness = <no type information>
```

```c
ALMOSTRO:0000000140D1D03C KiSerializeTimerExpiration dd 1
```
