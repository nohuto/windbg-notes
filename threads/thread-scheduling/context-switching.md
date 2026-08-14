# Context Switching

A (logical) processor can execute one thread at a time, a CS (context switch) happens when the dispatcher stops executing one thread on a (logical) processor and starts executing another thread there.

Whether for example an ISR/DPC interrupt a thread and run at a higher [IRQL](https://noverse.dev/docs/windbg-notes/system-mechanisms/trap-dispatching/interrupt-request-levels/) without the scheduler selecting a new `_KTHREAD`, then this doesn't cause a CS. Or when a system call causes a KM switch from UM, but continues executing the same thread, then this also wouldn't cause a CS.

Some common reasons for a CS are:

- Running thread waits/blocks
- Running thread terminates or yields execution
- Its quantum expires and another thread is ready
- Higher priority thread becomes ready and preempts the running thread

## Thread Selection

At a high level, imagine thread *A* switching from `Running` to `Ready`/`Waiting`/`Terminated` while thread *B* switches from `Ready` to `Standby` to `Running` (see '[*Thread States*](https://noverse.dev/docs/windbg-notes/threads/thread-scheduling/thread-states/)' for more details on state transitions).

![](https://github.com/nohuto/windbg-notes/blob/main/images/thread-states.png?raw=true)

The steps depend on why *A* stopped (and the processor architecture), but the important ones are:

1. Dispatcher selects the highest priority ready thread for that processor
2. Old thread is placed into its next scheduler state (preempted/quantum ended threads usually remain runnable, so they return to a ready queue of their priority, while blocking threads enter `Waiting` state)
3. New thread becomes the standby thread selected for that processor
4. Kernel saves state of the old thread to resume it later & restores the new threads state
5. Processors current thread becomes the new thread, which enters `Running` and executes

Per processor pointers are stored in [`_KPRCB`](https://noverse.dev/docs/windbg-notes/system-mechanisms/processor-execution-model/processor-control-region/):

```c
lkd> dt nt!_KPRCB CurrentThread NextThread IdleThread KeContextSwitches
   +0x008 CurrentThread      : Ptr64 _KTHREAD // currently executing
   +0x010 NextThread         : Ptr64 _KTHREAD // pointer to the next thread
   +0x018 IdleThread         : Ptr64 _KTHREAD // used when theres no thread executing
   +0x2d3c KeContextSwitches : Uint4B // cumulative switch counter

lkd> !prcb 5
PRCB for Processor 5 at ffffb90110b74180:
Current IRQL -- 0
Threads--  Current ffffe28142547080 Next 0000000000000000 Idle ffffe28142547080
Processor Index 5 Number (0, 5) GroupSetMember 20
Interrupt Count -- 006740a8
Times -- Dpc    00000007 Interrupt 00000000 
         Kernel 00048caa User      00000000 

lkd> dt nt!_KPRCB CurrentThread NextThread IdleThread KeContextSwitches ffffb90110b74180
   +0x008 CurrentThread     : 0xffffe281`42547080 _KTHREAD // same as IdleThread so it currently runs no thread
   +0x010 NextThread        : (null) 
   +0x018 IdleThread        : 0xffffe281`42547080 _KTHREAD
   +0x2d3c KeContextSwitches : 0x726627
```

## What Is Switched

As mentioned above, a thread context is architecture specific, it includes the state required to continue execution.

> "*A typical context switch requires saving and reloading the following data:*  
> *- Instruction pointer*  
> *- Kernel stack pointer*  
> *- A pointer to the address space in which the thread runs (the process’s page table directory)*
>
> — Windows Internals, [E7, P1: 'Context switching'](https://github.com/nohuto/Windows-Books/releases/download/7th-Edition/Windows-Internals-E7-P1.pdf)

Each thread has its own kernel stack, `_KTHREAD.KernelStack` stores the saved kernel stack position while the thread isn't running:

```c
lkd> dt nt!_KTHREAD KernelStack ContextSwitches Process State
   +0x058 KernelStack     : Ptr64 Void
   +0x154 ContextSwitches : Uint4B
   +0x184 State           : UChar
   +0x220 Process         : Ptr64 _KPROCESS
```

IDA wasn't able to decompile `SwapContext`, so I've to use the disassembly instead. These instructions save the old threads kernel stack pointer and load the new threads kernel stack pointer (`rdi` = old `_KTHREAD`, `rsi` = new `_KTHREAD`):

![](https://github.com/nohuto/windbg-notes/blob/main/images/ida-error.png?raw=true)

```c
// SwapContext

/*
 * 0000000140427E24: mov     [rdi+58h], rsp
 * 0000000140427E28: mov     rsp, [rsi+58h]
 */
```

One important note is that when both threads belong to the same process, their user address space is already the same, but when they're from different processes, the switch must also use the new processs address space context. This can cause higher TLB (translation lookaside buffer) costs & reduce cache locality, so depending on that a context switch might be more expensive.

## CS Counters

`SwapContext` increments both current processors cumulative counters & the new threads `_KTHREAD.ContextSwitches` counter, means that value shows how many times it has been switched in.

```c
/*
 * 0000000140427D7D: inc     dword ptr [rbx+2D3Ch]
 */
```

```c
/*
 * 00000001404282E2: inc     dword ptr [rsi+154h]
 */
```

Example of a CPUStress thread:

```c
lkd> !process F60 4
Searching for Process with Cid == f60
PROCESS ffffe2814f8c6080
    SessionId: 1  Cid: 0f60    Peb: 242119a000  ParentCid: 10cc
    DirBase: 37f17d000  ObjectTable: ffff978e5faa9c80  HandleCount: 166.
    Image: CPUStress.exe

        THREAD ffffe2814c7cd080  Cid 0f60.08d8  Teb: 000000242119b000 Win32Thread: ffffe2814faa3ad0 WAIT // GUI thread
        THREAD ffffe2814d8de080  Cid 0f60.1870  Teb: 00000024211a3000 Win32Thread: 0000000000000000 RUNNING on processor 5 // TID 6256
        THREAD ffffe2814f3ce080  Cid 0f60.26d4  Teb: 00000024211a5000 Win32Thread: 0000000000000000 READY on processor 5 // TID 9940

lkd> dt nt!_KTHREAD ffffe2814d8de080 ContextSwitches
   +0x154 ContextSwitches : 0x335
```

### System Informer

You can see two different columns named `Context switches` & `Context switches delta` (per process or per thread).

![](https://github.com/nohuto/windbg-notes/blob/main/images/si-context-switches-process.png?raw=true)
![](https://github.com/nohuto/windbg-notes/blob/main/images/si-context-switches-thread.png?raw=true)

- `Context switches` = cumulative context switch value currently stored for the process/thread
- `Context switches delta` = increase since previous refresh

I've set both CPUStress threads to use the same CPU & be on the same priority, so they've to switch, this is equivalent to the single CPU example in '[Thread States, PerfMon Example](https://noverse.dev/docs/windbg-notes/threads/thread-scheduling/thread-states/#perfmon-example)':

![](https://github.com/nohuto/windbg-notes/blob/main/images/perfmon-2-threads.png?raw=true)

## CPUStress Example

CPUStress uses two threads, both use `THREAD_PRIORITY_TIME_CRITICAL` (priority `15`, see '[Relative Thread Priority](https://noverse.dev/docs/windbg-notes/threads/thread-scheduling/priority-levels/#relative-thread-priority)') as described under [Relative Thread Priority](https://noverse.dev/docs/windbg-notes/threads/thread-scheduling/priority-levels/#relative-thread-priority), and both are forced to run on processor 5 (affinity). As only one thread can execute on that logical processor at a time, they're switching between `Running`/`Ready` (see image above).

![](https://github.com/nohuto/windbg-notes/blob/main/images/CPUStress-context-switches.png?raw=true)

```c
lkd> !process F60 4
Searching for Process with Cid == f60
PROCESS ffffe2814f8c6080
    SessionId: 1  Cid: 0f60    Peb: 242119a000  ParentCid: 10cc
    DirBase: 37f17d000  ObjectTable: ffff978e5faa9c80  HandleCount: 160.
    Image: CPUStress.exe

        THREAD ffffe2814c7cd080  Cid 0f60.08d8  Teb: 000000242119b000 Win32Thread: ffffe2814faa3ad0 WAIT // GUI thread
        THREAD ffffe2814d8de080  Cid 0f60.1870  Teb: 00000024211a3000 Win32Thread: 0000000000000000 RUNNING on processor 5 // TID 6256
        THREAD ffffe2814f3ce080  Cid 0f60.26d4  Teb: 00000024211a5000 Win32Thread: 0000000000000000 READY on processor 5 // TID 9940

lkd> dt nt!_KTHREAD ffffe2814d8de080 ContextSwitches State Priority BasePriority NextProcessor
   +0x0c3 Priority        : 8 ''
   +0x154 ContextSwitches : 0x5e5
   +0x184 State           : 0x2 '' // Running
   +0x218 NextProcessor   : 5
   +0x233 BasePriority    : 8 ''

lkd> dt nt!_KTHREAD ffffe2814f3ce080 ContextSwitches State Priority BasePriority NextProcessor
   +0x0c3 Priority        : 8 ''
   +0x154 ContextSwitches : 0x494
   +0x184 State           : 0x1 '' // Ready
   +0x218 NextProcessor   : 5
   +0x233 BasePriority    : 8 ''

// from a different process so addresses are different

lkd> dt nt!_KTHREAD ffffe28227f13580 Affinity UserAffinity // first CPUStress thread
   +0x228 UserAffinity : 0xffffe282`27f13ea0 _KAFFINITY_EX
   +0x240 Affinity     : 0xffffe282`27f13e90 _KAFFINITY_EX

lkd> dt nt!_KTHREAD ffffe281e8978080 Affinity UserAffinity // second
   +0x228 UserAffinity : 0xffffe281`e89789a0 _KAFFINITY_EX
   +0x240 Affinity     : 0xffffe281`e8978990 _KAFFINITY_EX

lkd> dt nt!_KAFFINITY_EX ffffe28227f13e90 Count Size Bitmap
   +0x000 Count  : 1
   +0x002 Size   : 1
   +0x008 Bitmap : [1] 0x20 // bit 5

lkd> dt nt!_KAFFINITY_EX ffffe281e8978990 Count Size Bitmap
   +0x000 Count  : 1
   +0x002 Size   : 1
   +0x008 Bitmap : [1] 0x20 // bit 5
```

## CS Reasons

See [_KWAIT_REASON](https://noverse.dev/docs/windbg-notes/threads/thread-scheduling/thread-states/#_kwait_reason) for more wait reasons, as written in that section, not all fields in the type are CS reasons.

![](https://github.com/nohuto/win-config/blob/main/system/images/WrQuantumEnd.png?raw=true)

Note that MXA shows `OldThreadWaitReason` values from CSwitch events.

### WrPreempted

A lower priority thread here gets preempted caused by, for example a higher priority thread becoming ready to run (wait completes, priority increased). Note that threads running in UM can preempt threads running in KM. Example of a thread with priority 16 getting preepmted from a thread with priority 18 which got ready, causing the lower priority thread to get sorted into the top of the r eady queue here. When the higher priority threads finished running, the lower priority thread can finish its quantum.

![](https://github.com/nohuto/windbg-notes/blob/main/images/WrPreempted.png?raw=true)

### WrQuantumEnd

Happens whenever a threads exhausts its quantum (`CycleTime >= QuantumTarget`), see '[Priority Seperation, Quantum](https://noverse.dev/docs/win-config/system/priority-separation/#quantum)' for details on modifying the quantum of FG/BG threads. If a thread uses its entire quantum, it depends on whenever there's another thread with the same priority (which would select that thread to run) for example, if not the thread gets another quantum.

`WrQuantumEnd` (`30`) is used as the context switch reason when [`KiQuantumEnd`](https://github.com/nohuto/decompiled-pseudocode/tree/main/11-23H2/ntoskrnl/KiQuantumEnd.c) switches the running thread for another thread (old thread is placed back into a ready queue). [`KiUpdateRunTime`](https://github.com/nohuto/decompiled-pseudocode/tree/main/11-23H2/ntoskrnl/KiUpdateRunTime.c) requests `KiQuantumEnd` when the running threads cycle based `QuantumTarget` is reached:

```c
// KiUpdateRunTime

result = CurrentThread->CycleTime;
if ( result >= CurrentThread->QuantumTarget )
  goto LABEL_23;
```

```c
// KiUpdateRunTime

LABEL_23:
CurrentPrcb->QuantumEnd = 1;
if ( !CurrentPrcb->NestingLevel )
  return HalRequestSoftwareInterrupt(2);
```

For an expired quantum, `KiQuantumEnd` adds the next `QuantumTarget`, then sets `WaitReason` to `30` before returning the old thread to a ready queue and switching context:

```c
// KiQuantumEnd

*(_QWORD *)(CurrentThread + 32) = v2 + KiCyclesPerClockQuantum * v3; // QuantumTarget = CycleTime + next quantum cycles
```

```c
// KiQuantumEnd

*(_BYTE *)(v72 + 643) = 30; // _KTHREAD.WaitReason = WrQuantumEnd
KiQueueReadyThread((__int64)CurrentPrcb, (__int64 *)&v120, v72);
KiAbProcessContextSwitch(v72, 1LL);
IsUserVaAccessAllowed = KeIsUserVaAccessAllowed(0LL);
if ( KeSmapEnabled )
  __asm { stac }
LOBYTE(v103) = 1;
result = KiSwapContext(v72, NextThread, v103);
```

Note that `KiUpdateRunTime` also seems to request the same function for preferred heterogeneous processor changes (`KiCheckPreferredHeteroProcessor`), means `WrQuantumEnd` doesn't always (but usually) mean `CycleTime >= QuantumTarget`.

![](https://github.com/nohuto/windbg-notes/blob/main/images/WrQuantumEnd.png?raw=true)

### WrTerminated

`WrTerminated` (`22`) = context switch reason when the running thread terminates. [`KeTerminateThread`](https://github.com/nohuto/decompiled-pseudocode/blob/main/11-23H2/ntoskrnl/KeTerminateThread.c) sets the threads `WaitReason` to `22`, and later changes its state to `Terminated` (`4`), and calls `KiSwapThread` (obviously the previously running thread isn't moved into a queue here).

```c
// KeTerminateThread

*(_BYTE *)(BugCheckParameter1 + 643) = 22; // _KTHREAD.WaitReason = WrTerminated
```

```c
// KeTerminateThread

*(_BYTE *)(BugCheckParameter1 + 388) = 4; // _KTHREAD.State = Terminated
```

```c
// KeTerminateThread

return KiSwapThread(BugCheckParameter1, (ULONG_PTR)CurrentPrcb, 0LL, v11);
```

### WrDispatchInt

`WrDispatchInt` (`31`) is used when a pending thread switch is made from `KiDispatchInterrupt`, which first checks whether the quantum expired (would get `WrQuantumEnd`), otherwise, if `_KPRCB.NextThread` is set, [`KiDispatchInterrupt`](https://github.com/nohuto/decompiled-pseudocode/blob/main/11-23H2/ntoskrnl/KiDispatchInterrupt.c) makes it the new thread, moves the old thread to a ready queue with `WaitReason = 31`, and switches context.

```c
// KiDispatchInterrupt

result = *(unsigned __int8 *)(CurrentPrcb + 13241);
if ( (_BYTE)result )
{
  *(_BYTE *)(CurrentPrcb + 13241) = 0;
  return KiQuantumEnd();
}
if ( *(_QWORD *)(CurrentPrcb + 16) )
```

```c
// KiDispatchInterrupt

v45 = *(_QWORD *)(CurrentPrcb + 16); // _KPRCB.NextThread
*(_QWORD *)(CurrentPrcb + 16) = 0LL;
*(_QWORD *)(CurrentPrcb + 8) = v45; // _KPRCB.CurrentThread = NextThread
```

```c
// KiDispatchInterrupt

*(_BYTE *)(v6 + 643) = 31; // Old _KTHREAD.WaitReason = WrDispatchInt
KiQueueReadyThread(CurrentPrcb, (__int64 *)&v54, v6);
IsUserVaAccessAllowed = KeIsUserVaAccessAllowed(0LL);
if ( KeSmapEnabled )
  __asm { stac }
LOBYTE(v47) = 1;
result = KiSwapContext(v6, v45, v47);
```

### WrYieldExecution

Shown whenever the running thread voluntarily yields execution and another thread is selected (`33`), [`NtYieldExecution`](https://github.com/nohuto/decompiled-pseudocode/blob/main/11-23H2/ntoskrnl/NtYieldExecution.c) directly calls [`KeYieldExecution`](https://github.com/nohuto/decompiled-pseudocode/blob/main/11-23H2/ntoskrnl/KeYieldExecution.c):

```c
// NtYieldExecution

NTSTATUS __noreturn NtYieldExecution(void)
{
  return KeYieldExecution(0);
}
```

```c
// KeYieldExecution

*(_BYTE *)(v52 + 388) = 2;
CurrentThread->WaitIrql = CurrentIrql;
CurrentThread->WaitReason = 33;
KiQueueReadyThread(v8, (__int64 *)&v138, (ULONG_PTR)CurrentThread);
LOBYTE(v132) = 1;
KiSwapContext(CurrentThread, v52, v132);
```

If there're no ready threads, `KeYieldExecution` returns `STATUS_NO_YIELD_PERFORMED` (`0x40000024`) without switching.

```c
// KeYieldExecution

CurrentPrcb = KeGetCurrentPrcb();
if ( !CurrentPrcb->ReadySummary && !CurrentPrcb->SharedReadyQueue->ReadySummary )
  return 1073741860;
```