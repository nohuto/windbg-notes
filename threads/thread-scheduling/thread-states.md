# Thread States

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

The wait reason is useful whenever a thread is waiting (comments were taken from [ntdoc](https://ntdoc.m417z.com/kwait_reason)). It's possible to see CS/wait reasons via e.g. MXA:

![](https://github.com/nohuto/win-config/blob/main/system/images/WrQuantumEnd.png?raw=true)

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

A lower priority thread here gets preempted caused by, for example a higher priority thread becoming ready to run (wait completes, priority increased). Note that threads running in UM can preempt threads running in KM. Example of a thread with priority 16 getting preepmted from a thread with priority 18 which got ready, causing the lower priority thread to get sorted into the top of the ready queue here. When the higher priority threads finished running, the lower priority thread can finish its quantum.

![](https://github.com/nohuto/windbg-notes/blob/main/assets/WrPreempted.png?raw=true)

#### WrQuantumEnd

Happens whenever a threads exhausts its quantum, see '[Priority Seperation, Quantum](https://noverse.dev/docs/win-config/system/priority-separation/#quantum)' for details on modifying the quantum of FG/BG threads. If a thread uses its entire quantum, it depends on whenever there's another thread with the same priority (which would select that thread to run) for example, if not the thread gets another quantum.

![](https://github.com/nohuto/windbg-notes/blob/main/assets/WrQuantumEnd.png?raw=true)