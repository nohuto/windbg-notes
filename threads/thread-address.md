# Thread Address

Windows represents a thread with an executive `_ETHREAD` object, with a `_KTHREAD` structure as it's first member (named `Tcb`):

```c
lkd> dt nt!_ETHREAD Tcb
   +0x000 Tcb : _KTHREAD
```

As `_KTHREAD` starts at offset `0`, the `_ETHREAD` and its embedded `_KTHREAD` have the same address, means commands such as `!thread` expect the `_ETHREAD` address (usually called the thread address).

List all active processes with minimal information:

```c
!process 0 0
```

The first argument selects the process, `0` lists all active processes,  `-1` displays only the current process.

```c
lkd> !process -1 0
PROCESS ffffd58e23f02080
    SessionId: none  Cid: 0004    Peb: 00000000  ParentCid: 0000
    DirBase: 001ae000  ObjectTable: ffffa98e5d657580  HandleCount: 2001.
    Image: System
```

Filter the list by the executable name:

```c
lkd> !process 0 0 CPUSTRES.exe
PROCESS ffffac819fc75080
    SessionId: 1  Cid: 20f4    Peb: 00ecd000  ParentCid: 0fd0
    DirBase: 201dbe000  ObjectTable: ffffc10724311c40  HandleCount: 190.
    Image: CPUSTRES.EXE
```

Use flag `4` to include one line for every thread owned by the matching process (affinity set to core 6 for active thread):

```c
lkd> !process 0 4 CPUSTRES.exe
PROCESS ffffac819fc75080
    SessionId: 1  Cid: 20f4    Peb: 00ecd000  ParentCid: 0fd0
    DirBase: 201dbe000  ObjectTable: ffffc10724311c40  HandleCount: 199.
    Image: CPUSTRES.EXE

        THREAD ffffac819fb18080  Cid 20f4.1e10  Teb: 0000000000ecf000 Win32Thread: ffffac81a2e6eed0 WAIT
        THREAD ffffac819f56a080  Cid 20f4.1374  Teb: 0000000000edb000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffac819f177080  Cid 20f4.13fc  Teb: 0000000000edf000 Win32Thread: 0000000000000000 RUNNING on processor 6
        THREAD ffffac81a1605080  Cid 20f4.0e60  Teb: 0000000000ee3000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffac81a0453080  Cid 20f4.0eec  Teb: 0000000000ee7000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffac819fa8d080  Cid 20f4.0a3c  Teb: 0000000000eeb000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffac81a087d040  Cid 20f4.0af4  Teb: 0000000000eef000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffac819f996080  Cid 20f4.11c8  Teb: 0000000000ef3000 Win32Thread: 0000000000000000 WAIT
```

The address after `THREAD` is that threads `_ETHREAD` address, e.g. `ffffac819fb18080` = `1e10` `_ETHREAD`. `Cid` includes the PID (process ID) & TID (thread ID) in hexadecimal (`20f4.1e10` = PID.TID). TEB = Thread Environment Block, you can dump it's structure using `!teb`/`dt _TEB <TEB address>`. A thread can also be found directly via its TID using `-t`:

```c
lkd> !thread -t 1e10
THREAD ffffac819fb18080  Cid 20f4.1e10  Teb: 0000000000ecf000 Win32Thread: ffffac81a2e6eed0 WAIT: (WrUserRequest) UserMode Non-Alertable
    ffffac81a2e6f9c0  QueueObject
Not impersonating
DeviceMap                 ffffc1071e31c830
Owning Process            ffffac819fc75080       Image:         CPUSTRES.EXE
Attached Process          N/A            Image:         N/A
Wait Start TickCount      64685          Ticks: 1451 (0:00:00:22.671)
Context Switch Count      33777          IdealProcessor: 7             
UserTime                  00:00:00.000
KernelTime                00:00:00.000
Win32 Start Address 0x0000000000c5e7db
Stack Init fffffb8cb40a2c30 Current fffffb8cb40a1be0
Base fffffb8cb40a3000 Limit fffffb8cb409c000 Call 0000000000000000
Priority 15  BasePriority 15  IoPriority 2  PagePriority 5
Child-SP          RetAddr               : Args to Child       
...
```

Without `-t`, `!thread` treats the value as an `_ETHREAD` address.

```c
lkd> !thread ffffac819fb18080
THREAD ffffac819fb18080  Cid 20f4.1e10  Teb: 0000000000ecf000 Win32Thread: ffffac81a2e6eed0 WAIT: (WrUserRequest) UserMode Non-Alertable
    ffffac81a2e6f9c0  QueueObject
Not impersonating
DeviceMap                 ffffc1071e31c830
Owning Process            ffffac819fc75080       Image:         CPUSTRES.EXE
Attached Process          N/A            Image:         N/A
Wait Start TickCount      64685          Ticks: 429 (0:00:00:06.703)
Context Switch Count      33777          IdealProcessor: 7             
UserTime                  00:00:00.000
KernelTime                00:00:00.000
Win32 Start Address 0x0000000000c5e7db
Stack Init fffffb8cb40a2c30 Current fffffb8cb40a1be0
Base fffffb8cb40a3000 Limit fffffb8cb409c000 Call 0000000000000000
Priority 15  BasePriority 15  IoPriority 2  PagePriority 5
Child-SP          RetAddr               : Args to Child   

// _ETHREAD & embedded _KTHREAD address
lkd> !thread ffffac819f177080
ffffac819f177080 is not a thread object, interpreting as stack value...
TYPE mismatch for thread object at ffffac819f177080
```

## `!process` Flags

Some useful `!process` flags:

| Flag | Information |
| --- | --- |
| `0` | Minimal process information |
| `1` | Time and priority statistics |
| `2` | Threads, waits, and associated events |
| `4` | One line for each thread |
| `6` | Threads, waits, and stack traces |
| `0x10` | Temporarily sets the process context when combined with flag `1` |
