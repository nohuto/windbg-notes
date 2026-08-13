# Priority Levels

> "*Windows schedules threads, not processes.*" 

Every thread has a (numeric) scheduling priority from `0` (lowest) up to `31` (highest). When a processor must choose the next thread, it selects a ready thread at the highest available priority (ready threads at the same priority are usually scheduled in round robin order, means that when a thread exhausts its quantum, its moved to the end of its priorities ready queue and the next thread gets a turn, as shown in [WrQuantumEnd](https://noverse.dev/docs/windbg-notes/threads/thread-scheduling/thread-states/#wrquantumend)). Also note that threads run at `PASSIVE_LEVEL`, while code running at `DISPATCH_LEVEL` (see [IRQLs](https://noverse.dev/docs/windbg-notes/system-mechanisms/trap-dispatching/interrupt-request-levels/)) or above prevents normal thread dispatch on that processor no matter what priority it has.

![](https://github.com/nohuto/windbg-notes/blob/main/images/thread-priority-levels.png?raw=true)

- `0` = reserved for the memory managers zero page thread(s) ([`MiZeroNodePages`](https://github.com/nohuto/decompiled-pseudocode/blob/main/11-23H2/ntoskrnl/MiZeroNodePages.c)), which runs when no other thread needs the processor (thread inside '*System*' process):

```c
lkd> dx -g @$cursession.Processes[4].Threads.Where(t => t.KernelObject.Tcb.Priority == 0)
Unable to get context for thread running on processor 6, HRESULT 0x80004001
==============================================================================================================================================
=                                                     = (+) KernelObject = (+) Id  = (+) Index = (+) Stack = (+) Registers = (+) Environment =
==============================================================================================================================================
= [0xa8] : nt!KiSwapContext+0x76 (fffff801`53627b36)  - {...}            - 0xa8    - 0x0       - {...}     - {...}         - {...}           =
= [0xac] : <Unable to get stack trace>                - {...}            - 0xac    - 0x0       - {...}     - {...}         - {...}           =
==============================================================================================================================================
lkd> !thread -t a8
THREAD ffffcf86a20df080  Cid 0004.00a8  Teb: 0000000000000000 Win32Thread: 0000000000000000 WAIT: (WrFreePage) KernelMode Non-Alertable
    fffff80153e6b568  NotificationEvent
    ffffcf86a0ed1aa0  SynchronizationEvent
Not impersonating
DeviceMap                 ffffe08ff6275c80
Owning Process            ffffcf86a0f02080       Image:         System
Attached Process          N/A            Image:         N/A
Wait Start TickCount      135627         Ticks: 35 (0:00:00:00.546)
Context Switch Count      9209           IdealProcessor: 0             
UserTime                  00:00:00.000
KernelTime                00:00:06.187
Win32 Start Address nt!MiZeroNodePages (0xfffff80153591f70)
Stack Init ffffdf8f3f9c7c30 Current ffffdf8f3f9c7390
Base ffffdf8f3f9c8000 Limit ffffdf8f3f9c1000 Call 0000000000000000
Priority 0  BasePriority 0  IoPriority 2  PagePriority 5 // Priority/BasePriority 0

lkd> !thread -t ac
THREAD ffffcf86a20d4040  Cid 0004.00ac  Teb: 0000000000000000 Win32Thread: 0000000000000000 WAIT: (WrFreePage) KernelMode Non-Alertable
    fffff80153e6b568  NotificationEvent
    ffffcf86a0ed1280  SynchronizationEvent
Not impersonating
DeviceMap                 ffffe08ff6275c80
Owning Process            ffffcf86a0f02080       Image:         System
Attached Process          N/A            Image:         N/A
Wait Start TickCount      135947         Ticks: 63 (0:00:00:00.984)
Context Switch Count      23841          IdealProcessor: 6             
UserTime                  00:00:00.000
KernelTime                00:00:00.703
Win32 Start Address nt!MiZeroNodePages (0xfffff80153591f70)
Stack Init ffffdf8f3fa07c30 Current ffffdf8f3fa07390
Base ffffdf8f3fa08000 Limit ffffdf8f3fa01000 Call 0000000000000000
Priority 0  BasePriority 0  IoPriority 2  PagePriority 5 // Priority/BasePriority 0
```

- `1-15` = variable (dynamic) priorities, a thread has a base priority in this range, while its current priority can (temporarily) be boosted above that
- `16-31` = RT (real-time) priorities, they take priority over all threads with variable priority and are unaffected by the dynamic priority boosts

Most application/service threads use the variable range, normally starting at priority `8`. The RT range is used by several kernel/system threads and by applications that  request it (using that range requires `SeIncreaseBasePriorityPrivilege`), note that a for example a RT thread can prevent important work at variable range from running, so it that should be only used for short work that actually requires priority.

## Process & Thread Priorities

As written at the beginning, a process doesn't run and doesn't compete with other processes for a processor, its priority class is used as the starting base priority for its threads.

![](https://github.com/nohuto/windbg-notes/blob/main/images/si-process-prio.png?raw=true)

| Process priority class | `_EPROCESS.PriorityClass` | Process base priority |
| --- | ---: | ---: |
| `IDLE_PRIORITY_CLASS` | `1` | `4` |
| `BELOW_NORMAL_PRIORITY_CLASS` | `5` | `6` |
| `NORMAL_PRIORITY_CLASS` | `2` | `8` |
| `ABOVE_NORMAL_PRIORITY_CLASS` | `6` | `10` |
| `HIGH_PRIORITY_CLASS` | `3` | `13` |
| `REALTIME_PRIORITY_CLASS` | `4` | `24` |

Note that `_EPROCESS.PriorityClass` & `_KPROCESS.BasePriority` are separate fields, CSRSS (and Session Manager, SCM, LSASS) for example doesn't get its base `13` from the `PriorityClass`, it directly sets its current `ProcessBasePriority` to `13`, without changing `PriorityClass`. In that case the `ProcessBasePriority` is used by the threads (while normally the class selects its base). This is done before `CsrServerInitialization`, in [`csrss!main`](https://github.com/nohuto/decompiled-pseudocode/blob/main/11-22H2/csrss/main.c):

```c
// main

RtlSetUnhandledExceptionFilter(CsrUnhandledExceptionFilter);
v11 = 13;
NtSetInformationProcess((HANDLE)0xFFFFFFFFFFFFFFFFLL, ProcessBasePriority, &v11, 4u);
RtlSetHeapInformation(0LL, HeapEnableTerminationOnCorruption, 0LL, 0LL);
```

```c
lkd> dx @$cursession.Processes[0x2e0].KernelObject.Pcb.BasePriority // 736 (0x2e0) PID of CSRSS
@$cursession.Processes[0x2e0].KernelObject.Pcb.BasePriority : 13 '\r' [Type: char]

lkd> dx @$cursession.Processes[0x2e0].KernelObject.PriorityClass
@$cursession.Processes[0x2e0].KernelObject.PriorityClass : 0x2 [Type: unsigned char] // Normal
```

> "*Use HIGH_PRIORITY_CLASS with care. If a thread runs at the highest priority level for extended periods, other threads in the system will not get processor time. If several threads are set at high priority at the same time, the threads lose their effectiveness. The high-priority class should be reserved for threads that must respond to time-critical events. If your application performs one task that requires the high-priority class while the rest of its tasks are normal priority, use SetPriorityClass to raise the priority class of the application temporarily; then reduce it after the time-critical task has been completed. Another strategy is to create a high-priority process that has all of its threads blocked most of the time, awakening threads only when critical tasks are needed. The important point is that a high-priority thread should execute for a brief time, and only when it has time-critical work to perform.*
>
> *You should almost never use REALTIME_PRIORITY_CLASS, because this interrupts system threads that manage mouse input, keyboard input, and background disk flushing. This class can be appropriate for applications that "talk" directly to hardware or that perform brief tasks that should have limited interruptions.*
>
> — Microsoft, [Scheduling Priorities](https://learn.microsoft.com/en-us/windows/win32/procthread/scheduling-priorities)

[`PspComputeQuantumAndPriority`](https://github.com/nohuto/decompiled-pseudocode/tree/main/11-23H2/ntoskrnl/PspComputeQuantumAndPriority.c) indexes `PspPriorityTable` with the processs `PriorityClass`, [`PspSetProcessPriorityByClass`](https://github.com/nohuto/decompiled-pseudocode/tree/main/11-23H2/ntoskrnl/PspSetProcessPriorityByClass.c) passes that result to [`KeSetPriorityAndQuantumProcess`](https://github.com/nohuto/decompiled-pseudocode/tree/main/11-23H2/ntoskrnl/KeSetPriorityAndQuantumProcess.c), which applies the change to the process & its threads.

```c
// PspComputeQuantumAndPriority
return *(unsigned int *)&PspPriorityTable[2 * *(unsigned __int8 *)(a1 + 1463)]; // PriorityClass selects its base priority
```

```c
lkd> dd nt!PspPriorityTable L7
fffff801`53c78670  00000008 00000004 00000008 0000000d // default 8, Idle 4, Normal 8, High 13
fffff801`53c78680  00000018 00000006 0000000a // Real-Time 24, Below Normal 6, Above Normal 10
```

### Relative Thread Priority

Each thread has a relative priority within its process class, ordinary values are `Highest` (`+2`), `Above normal` (`+1`), `Normal` (`0`), `Below normal` (`-1`), `Lowest` (`-2`) and `Time critical`/`Idle` which are saturation values, means they select the top or bottom of the variable/RT range (which you can see below as there are always blocks on the far left/right in the range):

![](https://github.com/nohuto/windbg-notes/blob/main/images/api-thread-priorities.png?raw=true)

> "*A typical strategy is to use THREAD_PRIORITY_ABOVE_NORMAL or THREAD_PRIORITY_HIGHEST for the process's input thread, to ensure that the application is responsive to the user. Background threads, particularly those that are processor intensive, can be set to THREAD_PRIORITY_BELOW_NORMAL or THREAD_PRIORITY_LOWEST, to ensure that they can be preempted when necessary. However, if you have a thread waiting for another thread with a lower priority to complete some task, be sure to block the execution of the waiting high-priority thread.*"
>
> — Microsoft, [Scheduling Priorities](https://learn.microsoft.com/en-us/windows/win32/procthread/scheduling-priorities)

| Relative thread priority | `REALTIME_PRIORITY_CLASS` (`24`) | `HIGH_PRIORITY_CLASS` (`13`) | `ABOVE_NORMAL_PRIORITY_CLASS` (`10`) | `NORMAL_PRIORITY_CLASS` (`8`) | `BELOW_NORMAL_PRIORITY_CLASS` (`6`) | `IDLE_PRIORITY_CLASS` (`4`) |
| --- | --- | --- | --- | --- | --- | --- |
| `THREAD_PRIORITY_TIME_CRITICAL` | `31` | `15` | `15` | `15` | `15` | `15` |
| `THREAD_PRIORITY_HIGHEST` (`+2`) | `26` | `15` | `12` | `10` | `8` | `6` |
| `THREAD_PRIORITY_ABOVE_NORMAL` (`+1`) | `25` | `14` | `11` | `9` | `7` | `5` |
| `THREAD_PRIORITY_NORMAL` (`0`) | `24` | `13` | `10` | `8` | `6` | `4` |
| `THREAD_PRIORITY_BELOW_NORMAL` (`-1`) | `23` | `12` | `9` | `7` | `5` | `3` |
| `THREAD_PRIORITY_LOWEST` (`-2`) | `22` | `11` | `8` | `6` | `4` | `2` |
| `THREAD_PRIORITY_IDLE` | `16` | `1` | `1` | `1` | `1` | `1` |

![](https://github.com/nohuto/windbg-notes/blob/main/images/si-thread-prio.png?raw=true)

- `Base priority` = `_KPROCESS.BasePriority` + relative priority (excluding `THREAD_PRIORITY_IDLE`/`THREAD_PRIORITY_TIME_CRITICAL`)
- `Priority (symbolic)` = shows the relative thread setting (can be a name or number)
- `Priority` = its current scheduling priority (whenever that is different to the base theres a boost happening via for example [`PsPrioritySeparation`](https://noverse.dev/docs/win-config/system/priority-separation/#pspriorityseparation-10)) as you can see below

## WinDbg CPUStress Example

Use `!process <PID> 4` to get the `_ETHREAD` addresses, in the example below I've set CPUStress to have four (excluding GUI thread) threads with different priorities:

![](https://github.com/nohuto/windbg-notes/blob/main/images/CPUStress-prio-levels.png?raw=true)

```c
lkd> !process 27f0 4
Searching for Process with Cid == 27f0
PROCESS ffffcf86af8870c0
    SessionId: 1  Cid: 27f0    Peb: 1cf60e1000  ParentCid: 1078
    DirBase: 2aa1f7000  ObjectTable: ffffe08050dc0b40  HandleCount: 163.
    Image: CPUStress.exe

        THREAD ffffcf86c35e5540  Cid 27f0.27f4  Teb: 0000001cf60e2000 Win32Thread: ffffcf86aad3db40 WAIT // GUI thread
        THREAD ffffcf86de0eb540  Cid 27f0.07dc  Teb: 0000001cf60ea000 Win32Thread: 0000000000000000 RUNNING on processor 5 // Normal BasePriority
        THREAD ffffcf86ddff1540  Cid 27f0.21b0  Teb: 0000001cf60ec000 Win32Thread: 0000000000000000 RUNNING on processor 5 // Highest (+2) BasePriority
        THREAD ffffcf86ddff4540  Cid 27f0.08f4  Teb: 0000001cf60ee000 Win32Thread: 0000000000000000 WAIT // Time Critical (+SAT) BasePriority
        THREAD ffffcf86de0b3540  Cid 27f0.0b54  Teb: 0000001cf60f0000 Win32Thread: 0000000000000000 WAIT // Idle (-SAT) BasePriority

lkd> dt nt!_KPROCESS ffffcf86af8870c0 BasePriority
   +0x280 BasePriority : 8 ''

lkd> dt nt!_EPROCESS ffffcf86af8870c0 PriorityClass
   +0x5b7 PriorityClass : 0x2 '' // Normal
```

Reading the current/base priorities of the four threads shows what I've set them to as shown in the image above:

```c
lkd> dt nt!_KTHREAD ffffcf86de0eb540 Priority BasePriority PriorityDecrement
   +0x0c3 Priority          : 8 ''
   +0x233 BasePriority      : 8 '' // Normal
   +0x234 PriorityDecrement : 0 ''

lkd> dt nt!_KTHREAD ffffcf86ddff1540 Priority BasePriority PriorityDecrement
   +0x0c3 Priority          : 10 ''
   +0x233 BasePriority      : 10 '' // Highest = 8 + 2
   +0x234 PriorityDecrement : 0 ''

lkd> dt nt!_KTHREAD ffffcf86ddff4540 Priority BasePriority PriorityDecrement
   +0x0c3 Priority          : 15 ''
   +0x233 BasePriority      : 15 '' // Time Critical (variable range)
   +0x234 PriorityDecrement : 0 ''

lkd> dt nt!_KTHREAD ffffcf86de0b3540 Priority BasePriority PriorityDecrement
   +0x0c3 Priority          : 1 ''
   +0x233 BasePriority      : 1 '' // Idle (variable range)
   +0x234 PriorityDecrement : 0 ''

// with GUI in FG (while PsPrioritySeparation = 2)

lkd> dt nt!_KTHREAD ffffcf86de0eb540 Priority BasePriority PriorityDecrement
   +0x0c3 Priority          : 10 ''
   +0x233 BasePriority      : 8 '' // Normal
   +0x234 PriorityDecrement : 2 ''

lkd> dt nt!_KTHREAD ffffcf86ddff1540 Priority BasePriority PriorityDecrement
   +0x0c3 Priority          : 12 ''
   +0x233 BasePriority      : 10 '' // Highest = 8 + 2
   +0x234 PriorityDecrement : 2 ''

lkd> dt nt!_KTHREAD ffffcf86ddff4540 Priority BasePriority PriorityDecrement
   +0x0c3 Priority          : 15 ''
   +0x233 BasePriority      : 15 '' // Time Critical (variable range)
   +0x234 PriorityDecrement : 0 ''

lkd> dt nt!_KTHREAD ffffcf86de0b3540 Priority BasePriority PriorityDecrement
   +0x0c3 Priority          : 3 ''
   +0x233 BasePriority      : 1 '' // Idle (variable range)
   +0x234 PriorityDecrement : 2 ''
```
