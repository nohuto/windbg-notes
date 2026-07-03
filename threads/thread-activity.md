# Thread Activity

Thread activity = what a thread is currently doing and how much execution time (UM/KM) it has used.

There's no actual need to see the activity via WinDbg, use [System Informer](), open the properties of a process, go into the *Threads* section, choose columns *Kernel time*, *User time*, *State* (this can show [`_KTHREAD_STATE`](https://noverse.dev/docs/windbg-notes/threads/thread-activity/#_kthread_state)/[_KWAIT_REASON`](https://noverse.dev/docs/windbg-notes/threads/thread-activity/#_kwait_reason) depending on whenever the thread is waiting).

![](https://github.com/nohuto/windbg-notes/blob/main/assets/si-activity.png?raw=true)

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

`!process <EPROCESS> 4` shows one line per thread, use `!process <EPROCESS> 2` whenever you also want to see waits and dispatcher objects.  Via [`!thread <ETHREAD> 6`](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-thread) we can see `UserTime` & `KernelTime`. I'll use ETHREAD `ffffd88863435080` here as the other threads are waiting and don't consume any CPU time.

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