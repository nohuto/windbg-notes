# Noisy Symbol Loading

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
