# Symbol Server

You can either set it via WinDbg, or as environment variable.

```powershell
$env:_NT_SYMBOL_PATH = 'srv*C:\Symbols*https://msdl.microsoft.com/download/symbols'
```

```c
.sympath srv*C:\Symbols*https://msdl.microsoft.com/download/symbols
```
