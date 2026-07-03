# Thread Activity

Thread activity = what a thread is currently doing and how much execution time (UM/KM) it has used. Rather use cycles (delta) than UM/KM. That time gets calculated via `KeMaximumIncrement`, e.g.:

```c
lkd> !thread ffffd8886cbd2080 6
THREAD ffffd8886cbd2080  Cid 23cc.108c  Teb: 0000000000ff2000 Win32Thread: 0000000000000000 RUNNING on processor 5
Not impersonating
DeviceMap                 ffff8900a79f99f0
Owning Process            ffffd888733f4080       Image:         CPUSTRES.EXE
Attached Process          N/A            Image:         N/A
Wait Start TickCount      910845         Ticks: 20 (0:00:00:00.312)
Context Switch Count      6948           IdealProcessor: 5             
UserTime                  00:00:00.015 // 1 * 15.625
KernelTime                00:00:00.031 // 2 * 15.625 = 31.25

lkd> dd KeMaximumIncrement L1
fffff801`3c51ea54  0002625a // 15.625
lkd> dt nt!_KTHREAD ffffd8886cbd2080 UserTime
   +0x2dc UserTime : 1
lkd> dt nt!_KTHREAD ffffd8886cbd2080 KernelTime
   +0x28c KernelTime : 2
```

There's no actual need to see the activity via WinDbg, use [System Informer](), open the properties of a process, go into the *Threads* section, choose columns *Kernel time*, *User time*, *State* (this can show [`_KTHREAD_STATE`](https://noverse.dev/docs/windbg-notes/threads/thread-activity/#_kthread_state)/[`_KWAIT_REASON`](https://noverse.dev/docs/windbg-notes/threads/thread-activity/#_kwait_reason) depending on whenever the thread is waiting).

![](https://github.com/nohuto/windbg-notes/blob/main/assets/si-activity.png?raw=true)

## CPU Time & Cycles

`User time` & `Kernel time` (see above to understand how they're getting calculated) are cumulative clock intervals counted to a thread in UM/KM (they don't include time spent waiting). On a tickless system clock interrupts can be suppressed, so these values may remain at `0` while a thread is running. [`CycleTime`](https://learn.microsoft.com/en-us/windows/win32/api/realtimeapiset/nf-realtimeapiset-querythreadcycletime) is the cumulative number of CPU clock cycles used by the thread in UM/KM, you can't really see the "live" delta via WinDbg.

| System Informer | Meaning |
| --- | --- |
| `User time` | Cumulative clock intervals counted in UM |
| `Kernel time` | Cumulative clock intervals counted in KM |
| `Cycles` | Cumulative CPU cycles in UM/KM |
| `Cycles delta` | Cycles accumulated since previous refresh (you can just hold `F5` to see the changes) |
| `CPU` | `thread cycle delta / system cycle delta` |

A waiting thread can have a large `Cycles` value with a current delta of `0`:

![](https://github.com/nohuto/windbg-notes/blob/main/assets/cycles-compare.png?raw=true)

Therefore use `Cycles` for the amount since thread creation & `Cycles delta` for amount since the latest refresh.

![](https://github.com/nohuto/windbg-notes/blob/main/assets/active-cycles.png?raw=true)
![](https://github.com/nohuto/windbg-notes/blob/main/assets/inactive-cycles.png?raw=true)

```c
lkd> !process 0 4 CPUSTRES.exe
PROCESS ffffd88864c33080
    SessionId: 1  Cid: 19a0    Peb: 00889000  ParentCid: 0ff0
    DirBase: 7551fe000  ObjectTable: 00000000  HandleCount:   0.
    Image: CPUSTRES.EXE

No active threads

PROCESS ffffd88871aee080
    SessionId: 1  Cid: 22c8    Peb: 00887000  ParentCid: 0ff0
    DirBase: 4cfeb6000  ObjectTable: 00000000  HandleCount:   0.
    Image: CPUSTRES.EXE

No active threads

PROCESS ffffd888666f1080
    SessionId: 1  Cid: 1cb0    Peb: 009ed000  ParentCid: 0ff0
    DirBase: 725da3000  ObjectTable: 00000000  HandleCount:   0.
    Image: CPUSTRES.EXE

No active threads

PROCESS ffffd888733f4080
    SessionId: 1  Cid: 23cc    Peb: 00fe0000  ParentCid: 0ff0
    DirBase: 268f19000  ObjectTable: ffff8900b916ec00  HandleCount: 196.
    Image: CPUSTRES.EXE

        THREAD ffffd88866ab0080  Cid 23cc.10cc  Teb: 0000000000fe2000 Win32Thread: ffffd88864a28330 WAIT
        THREAD ffffd8886cbd2080  Cid 23cc.108c  Teb: 0000000000ff2000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd88863850080  Cid 23cc.1fc0  Teb: 0000000000ff6000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd88867fde080  Cid 23cc.1c80  Teb: 0000000000ffa000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd88861b45080  Cid 23cc.1454  Teb: 0000000000e00000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd88864432080  Cid 23cc.1434  Teb: 0000000000e10000 Win32Thread: 0000000000000000 WAIT

lkd> dt nt!_KTHREAD ffffd8886cbd2080 CycleTime
   +0x048 CycleTime : 0x00000018`031c8e7c // 103,131,418,236
```

## User Mode

Attach WinDbg to the process, then list its threads using `~`:

![](https://github.com/nohuto/windbg-notes/blob/main/assets/attach-process.png?raw=true)

```c
0:006> ~
   0  Id: 2064.22a0 Suspend: 1 Teb: 00eaf000 Unfrozen
   1  Id: 2064.1a00 Suspend: 1 Teb: 00ebf000 Unfrozen
   2  Id: 2064.2710 Suspend: 2 Teb: 00ec3000 Unfrozen
   3  Id: 2064.25c4 Suspend: 2 Teb: 00ec7000 Unfrozen
   4  Id: 2064.bb8 Suspend: 2 Teb: 00ecb000 Unfrozen
   5  Id: 2064.2638 Suspend: 1 Teb: 00eeb000 Unfrozen
.  6  Id: 2064.1eb4 Suspend: 1 Teb: 00eef000 Unfrozen
```

Each line shows the thread index (assigned by debugger), `PID.TID`, suspend count, TEB address & debugger freeze state. See '[Cheat Sheet](https://noverse.dev/docs/windbg-notes/cheat-sheet/)' for more related commands.

[`!runaway 7`](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-runaway) is useful for seeing a CPU consuming thread (values are cumulative).

```c
0:006> !runaway 7
 User Mode Time
  Thread       Time
    1:1a00     0 days 0:00:00.531
    6:1eb4     0 days 0:00:00.000
    5:2638     0 days 0:00:00.000
    4:bb8      0 days 0:00:00.000
    3:25c4     0 days 0:00:00.000
    2:2710     0 days 0:00:00.000
    0:22a0     0 days 0:00:00.000
 Kernel Mode Time
  Thread       Time
    1:1a00     0 days 0:00:00.015
    6:1eb4     0 days 0:00:00.000
    5:2638     0 days 0:00:00.000
    4:bb8      0 days 0:00:00.000
    3:25c4     0 days 0:00:00.000
    2:2710     0 days 0:00:00.000
    0:22a0     0 days 0:00:00.000
 Elapsed Time
  Thread       Time
    0:22a0     0 days 0:32:07.384
    1:1a00     0 days 0:32:07.369
    2:2710     0 days 0:32:07.368
    3:25c4     0 days 0:32:07.367
    4:bb8      0 days 0:32:07.367
    5:2638     0 days 0:00:12.731
    6:1eb4     0 days 0:00:12.666
```

`~` selects threads only in UM debugging, in KM debugging the same selects processors.

## Kernel Mode

See '[Thread Address](https://noverse.dev/docs/windbg-notes/threads/thread-address/)' for understanding how to get the `_ETHREAD` address.

```c
lkd> !process 0 0 CPUSTRES.exe
PROCESS ffffd888702d3080
    SessionId: 1  Cid: 2064    Peb: 00eab000  ParentCid: 0ff0
    DirBase: 41b56f000  ObjectTable: ffff8900b1b2a040  HandleCount: 196.
    Image: CPUSTRES.EXE

lkd> !process ffffd888702d3080 4
PROCESS ffffd888702d3080
    SessionId: 1  Cid: 2064    Peb: 00eab000  ParentCid: 0ff0
    DirBase: 41b56f000  ObjectTable: ffff8900b1b2a040  HandleCount: 196.
    Image: CPUSTRES.EXE

        THREAD ffffd88867cb5080  Cid 2064.22a0  Teb: 0000000000ead000 Win32Thread: ffffd88867f10110 WAIT
        THREAD ffffd88863435080  Cid 2064.1a00  Teb: 0000000000ebd000 Win32Thread: 0000000000000000 RUNNING on processor 5
        THREAD ffffd88861d74080  Cid 2064.2710  Teb: 0000000000ec1000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd88861fa7080  Cid 2064.25c4  Teb: 0000000000ec5000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd888653f5080  Cid 2064.0bb8  Teb: 0000000000ec9000 Win32Thread: 0000000000000000 WAIT
```

`!process <EPROCESS> 4` shows one line per thread, use `!process <EPROCESS> 2` whenever you also want to see waits and dispatcher objects. Via [`!thread <ETHREAD> 6`](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-thread) we can see `UserTime` & `KernelTime`. I'll use ETHREAD `ffffd88863435080` because it is running in this snapshot. Waiting threads can still have accumulated CPU time, but aren't executing at that instant.

```c
lkd> !thread ffffd88863435080 6
THREAD ffffd88863435080  Cid 2064.1a00  Teb: 0000000000ebd000 Win32Thread: 0000000000000000 RUNNING on processor 5
Not impersonating
DeviceMap                 ffff8900a79f99f0
Owning Process            ffffd888702d3080       Image:         CPUSTRES.EXE
Attached Process          N/A            Image:         N/A
Wait Start TickCount      319710         Ticks: 20 (0:00:00:00.312)
Context Switch Count      21216          IdealProcessor: 5             
UserTime                  00:00:00.531
KernelTime                00:00:00.015
Win32 Start Address 0x0000000000446be0
Stack Init fffff90660357c30 Current fffff90660357570
Base fffff90660358000 Limit fffff90660351000 Call 0000000000000000
Priority 8  BasePriority 8  IoPriority 2  PagePriority 5
Unable to get context for thread running on processor 5, HRESULT 0x80004001
```

| Flags | Meaning |
| ---: | --- |
| `0` | Minimal thread information |
| `2` | Wait state |
| `6` | Wait state and stack |

## State & Wait Reason

### _KTHREAD_STATE

The state shows the threads scheduler state, the wait reason shows why a waiting thread entered its wait.

```c
lkd> dt nt!_KTHREAD_STATE
   Initialized = 0n0
   Ready = 0n1
   Running = 0n2
   Standby = 0n3
   Terminated = 0n4
   Waiting = 0n5
   Transition = 0n6
   DeferredReady = 0n7
   GateWaitObsolete = 0n8
   WaitingForProcessInSwap = 0n9
```

| State | Meaning |
| --- | --- |
| `Initialized` | Thread is being created |
| `Ready` | Waiting for a processor |
| `Running` | Executing on a processor |
| `Standby` | Selected to execute next on a processor |
| `Terminated` | Finished execution |
| `Waiting` | Waiting for an object, delay, I/O, suspension |
| `Transition` | Ready, but its kernel stack is paged out |
| `DeferredReady` | Ready processing has been deferred for a selected processor |

`!thread` shows that state on the top (`RUNNING` here):

```c
lkd> !thread ffffd88863435080 2
THREAD ffffd88863435080  Cid 2064.1a00  Teb: 0000000000ebd000 Win32Thread: 0000000000000000 RUNNING on processor 5
```

Or see the current `State` of a thread via:

```c
lkd> dt nt!_KTHREAD ffffd88863435080 State
   +0x184 State : 0x2 '' // Running
```

### _KWAIT_REASON

The wait reason is useful whenever a thread is waiting (see [ntdoc](https://ntdoc.m417z.com/kwait_reason) for comments on each reason):

```c
lkd> dt nt!_KWAIT_REASON
   Executive = 0n0
   FreePage = 0n1
   PageIn = 0n2
   PoolAllocation = 0n3
   DelayExecution = 0n4
   Suspended = 0n5
   UserRequest = 0n6
   WrExecutive = 0n7
   WrFreePage = 0n8
   WrPageIn = 0n9
   WrPoolAllocation = 0n10
   WrDelayExecution = 0n11
   WrSuspended = 0n12
   WrUserRequest = 0n13
   WrSpare0 = 0n14
   WrQueue = 0n15
   WrLpcReceive = 0n16
   WrLpcReply = 0n17
   WrVirtualMemory = 0n18
   WrPageOut = 0n19
   WrRendezvous = 0n20
   WrKeyedEvent = 0n21
   WrTerminated = 0n22
   WrProcessInSwap = 0n23
   WrCpuRateControl = 0n24
   WrCalloutStack = 0n25
   WrKernel = 0n26
   WrResource = 0n27
   WrPushLock = 0n28
   WrMutex = 0n29
   WrQuantumEnd = 0n30
   WrDispatchInt = 0n31
   WrPreempted = 0n32
   WrYieldExecution = 0n33
   WrFastMutex = 0n34
   WrGuardedMutex = 0n35
   WrRundown = 0n36
   WrAlertByThreadId = 0n37
   WrDeferredPreempt = 0n38
   WrPhysicalFault = 0n39
   WrIoRing = 0n40
   WrMdlCache = 0n41
   MaximumWaitReason = 0n42
```

See the current `WaitReason` of a thread via:

```c
lkd> dt nt!_KTHREAD ffffd88863435080 WaitReason
   +0x283 WaitReason : 0x6 '' // UserRequest
```
