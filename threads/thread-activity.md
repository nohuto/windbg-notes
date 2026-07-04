# Thread Activity

Thread activity = what a thread is currently doing and how much execution time (UM/KM) it has used. Rather use cycles (delta) than UM/KM time, that time gets calculated via `KeMaximumIncrement`, e.g.:

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

There's no actual need to see the activity via WinDbg, use [System Informer](https://github.com/winsiderss/systeminformer/releases), open the properties of a process, go into the *Threads* section, choose columns *Kernel time*, *User time*, *State* (this can show [`_KTHREAD_STATE`](https://noverse.dev/docs/windbg-notes/threads/thread-activity/#_kthread_state)/[`_KWAIT_REASON`](https://noverse.dev/docs/windbg-notes/threads/thread-activity/#_kwait_reason) depending on whenever the thread is waiting). Note that processes don't run, they just provide resources and a context in which their threads would run.

![](https://github.com/nohuto/windbg-notes/blob/main/assets/si-activity.png?raw=true)

## CPU Time & Cycles

`User time` & `Kernel time` (see above to understand how they're getting calculated) are cumulative clock intervals counted to a thread in UM/KM (they don't include time spent waiting). [`CycleTime`](https://learn.microsoft.com/en-us/windows/win32/api/realtimeapiset/nf-realtimeapiset-querythreadcycletime) is the cumulative number of CPU clock cycles used by the thread in UM/KM, you can't really see the "live" delta via WinDbg (unless substracting cycles from two different times).

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

### System Idle Process

The *System Idle Process* (`PID 0`) is a fake process used account for idle CPU cycle. It has one idle thread per logical processor, each processors `_KPRCB` (shown by `!pcr`) points to its idle thread, which runs only when that processor has no other thread to execute.

![](https://github.com/nohuto/windbg-notes/blob/main/assets/idle-process-cycles.png?raw=true)

```c
lkd> !pcr 8
KPCR for Processor 8 at ffffd400306d3000:
	               Prcb: ffffd400306d3180

lkd> dt nt!_KPRCB ffffd400306d3180 CurrentThread NextThread IdleThread
   +0x008 CurrentThread : 0xffffc184`0b805080 _KTHREAD
   +0x010 NextThread    : (null)
   +0x018 IdleThread    : 0xffffc184`ff755040 _KTHREAD

lkd> dt nt!_KTHREAD ffffc184ff755040 Process CycleTime UserTime KernelTime Priority
   +0x048 CycleTime  : 0x000009dc`fdbdeb0b // 10,844,754,537,227
   +0x0c3 Priority   : 0
   +0x220 Process    : 0xfffff800`0b349f40 _KPROCESS
   +0x28c KernelTime : 0x31173 // 201,075 * 156,250 * 100ns = 3,141.796875sec = 00:52:21.796875
   +0x2dc UserTime   : 0

lkd> dt nt!_EPROCESS fffff8000b349f40 UniqueProcessId ImageFileName ActiveThreads
   +0x440 UniqueProcessId : (null) 
   +0x5a8 ImageFileName   : [15]  "Idle"
   +0x5f0 ActiveThreads   : 0
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

`!process <EPROCESS> 4` shows one line per thread, use `!process <EPROCESS> 2` whenever you also want to see waits and dispatcher objects. Via [`!thread <ETHREAD> 6`](https://learn.microsoft.com/en-us/windows-hardware/drivers/debuggercmds/-thread) we can see `UserTime` & `KernelTime`. I'll use ETHREAD `ffffd88863435080` here, as that's thread address of the thread thats active in CPUSTRES.

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

| Flag | Meaning |
| --- | --- |
| `0` | Minimal thread information |
| `2` | Wait state |
| `6` | Wait state and stack |

## State & Wait Reason

### _KTHREAD_STATE

The state shows the threads scheduler state, the wait reason shows why a waiting thread entered its wait (the descriptions were taken from [Windows Internals](https://github.com/nohuto/windows-books/releases/download/7th-Edition/Windows-Internals-E7-P1.pdf)).

![](https://github.com/nohuto/windbg-notes/blob/main/assets/thread-states.png?raw=true)

```c
lkd> dt nt!_KTHREAD_STATE
   Initialized = 0n0 // This state is used internally while a thread is being created
   Ready = 0n1 // A thread in the ready state is waiting to execute or to be in-swapped after completing a wait. When looking for a thread to execute, the dispatcher considers only the threads in the ready state
   Running = 0n2 // After the dispatcher performs a context switch to a thread, the thread enters the running state and executes. The thread’s execution continues until its quantum ends (and an other thread at the same priority is ready to run), it is preempted by a higher-priority thread, it terminates, it yields execution, or it voluntarily enters the waiting state.
   Standby = 0n3 // A thread in this state has been selected to run next on a particular processor. When the correct conditions exist, the dispatcher performs a context switch to this thread. Only one thread can be in the standby state for each processor on the system. Note that a thread can be preempted out of the standby state before it ever executes (if, for example, a higher-priority thread becomes runnable before the standby thread begins execution)
   Terminated = 0n4 // When a thread finishes executing, it enters this state. After the thread is terminated, the executive thread object (the data structure in system memory that describes the thread) might or might not be deallocated. The object manager sets the policy regarding when to delete the object. For example, the object remains if there are any open handles to the thread. A thread can also enter the terminated state from other states if it’s killed explicitly by some other thread, for example, by calling the TerminateThread Windows API
   Waiting = 0n5 // A thread can enter the waiting state in several ways: A thread can voluntarily wait for an object to synchronize its execution, the OS can wait on the thread’s behalf (such as to resolve a paging I/O), or an environment subsystem can direct the thread to suspend itself. When the thread’s wait ends, depending on its priority, the thread either begins running immediately or is moved back to the ready state
   Transition = 0n6 // A thread enters the transition state if it is ready for execution but its kernel stack is paged out of memory. After its kernel stack is brought back into memory, the thread enters the ready state
   DeferredReady = 0n7 // This state is used for threads that have been selected to run on a specific processor but have not actually started running there. This state exists so that the kernel can minimize the amount of time the per-processor lock on the scheduling database is held
   GateWaitObsolete = 0n8
   WaitingForProcessInSwap = 0n9
```

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

The wait reason is useful whenever a thread is waiting (comments were taken from [ntdoc](https://ntdoc.m417z.com/kwait_reason) for comments on each reason):

```c
lkd> dt nt!_KWAIT_REASON
   Executive = 0n0 // Waiting for an executive event
   FreePage = 0n1 // Waiting for a free page
   PageIn = 0n2 // Waiting for a page to be read in
   PoolAllocation = 0n3 // Waiting for a pool allocation
   DelayExecution = 0n4 // Waiting due to a delay execution
   Suspended = 0n5 // Waiting because the thread is suspended
   UserRequest = 0n6 // Waiting due to a user request
   WrExecutive = 0n7 // Waiting for an executive event
   WrFreePage = 0n8 // Waiting for a free page
   WrPageIn = 0n9 // Waiting for a page to be read in
   WrPoolAllocation = 0n10 // Waiting for a pool allocation
   WrDelayExecution = 0n11 // Waiting due to a delay execution
   WrSuspended = 0n12 // Waiting because the thread is suspended
   WrUserRequest = 0n13 // Waiting due to a user request
   WrSpare0 = 0n14
   WrQueue = 0n15 // Waiting for a queue
   WrLpcReceive = 0n16 // Waiting for an LPC receive
   WrLpcReply = 0n17 // Waiting for an LPC reply
   WrVirtualMemory = 0n18 // Waiting for virtual memory
   WrPageOut = 0n19 // Waiting for a page to be written out
   WrRendezvous = 0n20 // Waiting for a rendezvous
   WrKeyedEvent = 0n21 // Waiting for a keyed event
   WrTerminated = 0n22 // Waiting for thread termination
   WrProcessInSwap = 0n23 // Waiting for a process to be swapped in
   WrCpuRateControl = 0n24 // Waiting for CPU rate control
   WrCalloutStack = 0n25 // Waiting for a callout stack
   WrKernel = 0n26 // Waiting for a kernel event
   WrResource = 0n27 // Waiting for a resource
   WrPushLock = 0n28 // Waiting for a push lock
   WrMutex = 0n29 // Waiting for a mutex
   WrQuantumEnd = 0n30 // Waiting for the end of a quantum
   WrDispatchInt = 0n31 // Waiting for a dispatch interrupt
   WrPreempted = 0n32 // Waiting because the thread was preempted
   WrYieldExecution = 0n33 // Waiting to yield execution
   WrFastMutex = 0n34 // Waiting for a fast mutex
   WrGuardedMutex = 0n35 // Waiting for a guarded mutex
   WrRundown = 0n36 // Waiting for a rundown
   WrAlertByThreadId = 0n37 // Waiting for an alert by thread ID
   WrDeferredPreempt = 0n38 // Waiting for a deferred preemption
   WrPhysicalFault = 0n39 // Waiting for a physical fault
   WrIoRing = 0n40 // Waiting for an I/O ring
   WrMdlCache = 0n41 // Waiting for an MDL cache
   MaximumWaitReason = 0n42
```

See the current `WaitReason` of a thread via:

```c
lkd> dt nt!_KTHREAD ffffd88863435080 WaitReason
   +0x283 WaitReason : 0x6 '' // UserRequest
```

#### WrPreempted

A lower priority thread here gets preempted caused by for example a higher priority thread becomes ready to run (wait completes, priority increased). Note that threads running in UM can preempt threads running in KM. Example of a thread with priority 16 getting preepmted from a thread with priority 18 which got ready, causing the lower priority thread to get sorted into the top of the ready queue here, and when the higher priority threads finished running, the lower priority thread can finish its quantum.

![](https://github.com/nohuto/windbg-notes/blob/main/assets/WrPreempted.png?raw=true)

#### WrQuantumEnd

Happens whenever a threads exhausts its quantum, see '[Priority Seperation, Quantum](https://noverse.dev/docs/win-config/system/priority-separation/#quantum)' for details on modifying the quantum of FG/BG threads. If a thread uses its entire quantum, it depends on whenever there's another thread with the same priority (which would select that thread to run) for example, if not the thread gets another quantum.

![](https://github.com/nohuto/windbg-notes/blob/main/assets/WrQuantumEnd.png?raw=true)