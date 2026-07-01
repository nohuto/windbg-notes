# Initialization

Force WinDbg to load the symbols for the module:

```c
.reload /f <module>

// example
.reload /f mmcss.sys
```

`/f` forces symbol loading immediately, without a module name, `.reload /f` reloads every loaded module. You can then use `lm` to see whenever the module is loaded.

```c
lkd> lm m mmcss
Browse full module list
start             end                 module name
fffff800`50950000 fffff800`50966000   mmcss      (pdb symbols)          C:\ProgramData\Dbg\sym\mmcss.pdb\9E36707273FDF82AB362DBA6ACCC09671\mmcss.pdb
```