# Initialization

## Loading Modules

Use [`lm l`](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/lm--list-loaded-modules-) to lists modules whose symbols are currently loaded, if you're in a LKD session `nt` will be already loaded.

```c
lkd> lm l
start             end                 module name
fffff805`15c00000 fffff805`16c47000   nt         (pdb symbols)          c:\symbols\ntkrnlmp.pdb\7D91B8E878B8A42A1B9BFAB4FDC727BD1\ntkrnlmp.pdb
```

Without `/f`, [`.reload`](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-reload--reload-module-) updates the debuggers module info, discards existing symbol info for the selected module and leaves its symbols deferred:

```c
lkd> .reload mmcss.sys
lkd> lm m mmcss
Browse full module list
start             end                 module name
fffff805`28440000 fffff805`28456000   mmcss      (deferred)
```

`/f` overrides deferred loading ("*lazy symbol loading*") and forces the symbols to be read immediately (which can take longer as it may have to download many PDBs):

```c
lkd> .reload /f mmcss.sys
lkd> lm m mmcss
Browse full module list
start             end                 module name
fffff805`28440000 fffff805`28456000   mmcss      (pdb symbols)          c:\symbols\mmcss.pdb\9E36707273FDF82AB362DBA6ACCC09671\mmcss.pdb
```

Unload the symbols for a module:

```c
.reload /u mmcss.sys
```

## Noisy Symbol Loading

See your current noisy loading settings via:

```c
lkd> !sym
!sym <noisy/quiet - prompts/prompts off> - quiet mode - symbol prompts on
```

[`!sym noisy`](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-sym) is used for enabling noisy symbol loading, which is useful whenever loading fails.

```c
!sym noisy
.reload /f <module>

!sym quiet // normal output
```

## Symbol Server

You can either set it via WinDbg, or as environment variable.

```powershell
$env:_NT_SYMBOL_PATH = 'srv*C:\Symbols*https://msdl.microsoft.com/download/symbols'
```

```c
.sympath srv*C:\Symbols*https://msdl.microsoft.com/download/symbols
```