# Thread Structures

`_ETHREAD` (E = executive) is the executive thread object and extends the embedded `_KTHREAD` (K = kernel) with executive thread management state,`_KTHREAD` is the kernel thread control block used by the dispatcher and scheduler.

- *Executive* = upper layer of ntoskrnl including components like CM, process/power/I/O/PnP/memory/cache manager etc.
- *Kernel* = lower layer of ntoskrnl used for e.g. thread scheduling, synchronization services (used by executive components)

See Windows Interals [Chapter 2, System architecture](https://github.com/nohuto/windows-books/releases/download/7th-Edition/Windows-Internals-E7-P1.pdf) for more details on them.

Whenever you only want to see specific fields, you can add them behind the address, e.g.:

```c
dt nt!_KTHREAD <thread address> QuantumReset QuantumTarget
```

## _ETHREAD Structure

See the structure via WinDbg using `dt nt!_ETHREAD`.

```c
struct _ETHREAD// Size=0x910 (Id=124)
{
    struct _KTHREAD Tcb;// Offset=0x0 Size=0x480
    union _LARGE_INTEGER CreateTime;// Offset=0x480 Size=0x8
    union // Size=0x8 (Id=0)
    {
        union _LARGE_INTEGER ExitTime;// Offset=0x488 Size=0x8
        struct _LIST_ENTRY KeyedWaitChain;// Offset=0x488 Size=0x10
    };
    union // Size=0x10 (Id=0)
    {
        struct _LIST_ENTRY PostBlockList;// Offset=0x498 Size=0x10
        void * ForwardLinkShadow;// Offset=0x498 Size=0x8
    };
    void * StartAddress;// Offset=0x4a0 Size=0x8
    union // Size=0x4b0 (Id=0)
    {
        struct _TERMINATION_PORT * TerminationPort;// Offset=0x4a8 Size=0x8
        struct _ETHREAD * ReaperLink;// Offset=0x4a8 Size=0x8
        void * KeyedWaitValue;// Offset=0x4a8 Size=0x8
    };
    unsigned int ActiveTimerListLock;// Offset=0x4b0 Size=0x8
    struct _LIST_ENTRY ActiveTimerListHead;// Offset=0x4b8 Size=0x10
    struct _CLIENT_ID Cid;// Offset=0x4c8 Size=0x10
    union // Size=0x20 (Id=0)
    {
        struct _KSEMAPHORE KeyedWaitSemaphore;// Offset=0x4d8 Size=0x20
        struct _KSEMAPHORE AlpcWaitSemaphore;// Offset=0x4d8 Size=0x20
    };
    union _PS_CLIENT_SECURITY_CONTEXT ClientSecurity;// Offset=0x4f8 Size=0x8
    struct _LIST_ENTRY IrpList;// Offset=0x500 Size=0x10
    unsigned int TopLevelIrp;// Offset=0x510 Size=0x8
    struct _DEVICE_OBJECT * DeviceToVerify;// Offset=0x518 Size=0x8
    void * Win32StartAddress;// Offset=0x520 Size=0x8
    void * ChargeOnlySession;// Offset=0x528 Size=0x8
    void * LegacyPowerObject;// Offset=0x530 Size=0x8
    struct _LIST_ENTRY ThreadListEntry;// Offset=0x538 Size=0x10
    struct _EX_RUNDOWN_REF RundownProtect;// Offset=0x548 Size=0x8
    struct _EX_PUSH_LOCK ThreadLock;// Offset=0x550 Size=0x8
    unsigned long ReadClusterSize;// Offset=0x558 Size=0x4
    long MmLockOrdering;// Offset=0x55c Size=0x4
    union // Size=0x4 (Id=0)
    {
        unsigned long CrossThreadFlags;// Offset=0x560 Size=0x4
        struct // Size=0x4 (Id=0)
        {
            unsigned long Terminated:1;// Offset=0x560 Size=0x4 BitOffset=0x0 BitSize=0x1
            unsigned long ThreadInserted:1;// Offset=0x560 Size=0x4 BitOffset=0x1 BitSize=0x1
            unsigned long HideFromDebugger:1;// Offset=0x560 Size=0x4 BitOffset=0x2 BitSize=0x1
            unsigned long ActiveImpersonationInfo:1;// Offset=0x560 Size=0x4 BitOffset=0x3 BitSize=0x1
            unsigned long HardErrorsAreDisabled:1;// Offset=0x560 Size=0x4 BitOffset=0x4 BitSize=0x1
            unsigned long BreakOnTermination:1;// Offset=0x560 Size=0x4 BitOffset=0x5 BitSize=0x1
            unsigned long SkipCreationMsg:1;// Offset=0x560 Size=0x4 BitOffset=0x6 BitSize=0x1
            unsigned long SkipTerminationMsg:1;// Offset=0x560 Size=0x4 BitOffset=0x7 BitSize=0x1
            unsigned long CopyTokenOnOpen:1;// Offset=0x560 Size=0x4 BitOffset=0x8 BitSize=0x1
            unsigned long ThreadIoPriority:3;// Offset=0x560 Size=0x4 BitOffset=0x9 BitSize=0x3
            unsigned long ThreadPagePriority:3;// Offset=0x560 Size=0x4 BitOffset=0xc BitSize=0x3
            unsigned long RundownFail:1;// Offset=0x560 Size=0x4 BitOffset=0xf BitSize=0x1
            unsigned long UmsForceQueueTermination:1;// Offset=0x560 Size=0x4 BitOffset=0x10 BitSize=0x1
            unsigned long IndirectCpuSets:1;// Offset=0x560 Size=0x4 BitOffset=0x11 BitSize=0x1
            unsigned long DisableDynamicCodeOptOut:1;// Offset=0x560 Size=0x4 BitOffset=0x12 BitSize=0x1
            unsigned long ExplicitCaseSensitivity:1;// Offset=0x560 Size=0x4 BitOffset=0x13 BitSize=0x1
            unsigned long PicoNotifyExit:1;// Offset=0x560 Size=0x4 BitOffset=0x14 BitSize=0x1
            unsigned long DbgWerUserReportActive:1;// Offset=0x560 Size=0x4 BitOffset=0x15 BitSize=0x1
            unsigned long ForcedSelfTrimActive:1;// Offset=0x560 Size=0x4 BitOffset=0x16 BitSize=0x1
            unsigned long SamplingCoverage:1;// Offset=0x560 Size=0x4 BitOffset=0x17 BitSize=0x1
            unsigned long ReservedCrossThreadFlags:8;// Offset=0x560 Size=0x4 BitOffset=0x18 BitSize=0x8
        };
    };
    union // Size=0x4 (Id=0)
    {
        unsigned long SameThreadPassiveFlags;// Offset=0x564 Size=0x4
        struct // Size=0x4 (Id=0)
        {
            unsigned long ActiveExWorker:1;// Offset=0x564 Size=0x4 BitOffset=0x0 BitSize=0x1
            unsigned long MemoryMaker:1;// Offset=0x564 Size=0x4 BitOffset=0x1 BitSize=0x1
            unsigned long StoreLockThread:2;// Offset=0x564 Size=0x4 BitOffset=0x2 BitSize=0x2
            unsigned long ClonedThread:1;// Offset=0x564 Size=0x4 BitOffset=0x4 BitSize=0x1
            unsigned long KeyedEventInUse:1;// Offset=0x564 Size=0x4 BitOffset=0x5 BitSize=0x1
            unsigned long SelfTerminate:1;// Offset=0x564 Size=0x4 BitOffset=0x6 BitSize=0x1
            unsigned long RespectIoPriority:1;// Offset=0x564 Size=0x4 BitOffset=0x7 BitSize=0x1
            unsigned long ActivePageLists:1;// Offset=0x564 Size=0x4 BitOffset=0x8 BitSize=0x1
            unsigned long SecureContext:1;// Offset=0x564 Size=0x4 BitOffset=0x9 BitSize=0x1
            unsigned long ZeroPageThread:1;// Offset=0x564 Size=0x4 BitOffset=0xa BitSize=0x1
            unsigned long WorkloadClass:1;// Offset=0x564 Size=0x4 BitOffset=0xb BitSize=0x1
            unsigned long GenerateDumpOnBadHandleAccess:1;// Offset=0x564 Size=0x4 BitOffset=0xc BitSize=0x1
            unsigned long ReservedSameThreadPassiveFlags:19;// Offset=0x564 Size=0x4 BitOffset=0xd BitSize=0x13
        };
    };
    union // Size=0x4 (Id=0)
    {
        unsigned long SameThreadApcFlags;// Offset=0x568 Size=0x4
        struct // Size=0x3 (Id=0)
        {
            unsigned int OwnsProcessAddressSpaceExclusive:1;// Offset=0x568 Size=0x1 BitOffset=0x0 BitSize=0x1
            unsigned int OwnsProcessAddressSpaceShared:1;// Offset=0x568 Size=0x1 BitOffset=0x1 BitSize=0x1
            unsigned int HardFaultBehavior:1;// Offset=0x568 Size=0x1 BitOffset=0x2 BitSize=0x1
            unsigned int StartAddressInvalid:1;// Offset=0x568 Size=0x1 BitOffset=0x3 BitSize=0x1
            unsigned int EtwCalloutActive:1;// Offset=0x568 Size=0x1 BitOffset=0x4 BitSize=0x1
            unsigned int SuppressSymbolLoad:1;// Offset=0x568 Size=0x1 BitOffset=0x5 BitSize=0x1
            unsigned int Prefetching:1;// Offset=0x568 Size=0x1 BitOffset=0x6 BitSize=0x1
            unsigned int OwnsVadExclusive:1;// Offset=0x568 Size=0x1 BitOffset=0x7 BitSize=0x1
            unsigned int SystemPagePriorityActive:1;// Offset=0x569 Size=0x1 BitOffset=0x0 BitSize=0x1
            unsigned int SystemPagePriority:3;// Offset=0x569 Size=0x1 BitOffset=0x1 BitSize=0x3
            unsigned int AllowUserWritesToExecutableMemory:1;// Offset=0x569 Size=0x1 BitOffset=0x4 BitSize=0x1
            unsigned int AllowKernelWritesToExecutableMemory:1;// Offset=0x569 Size=0x1 BitOffset=0x5 BitSize=0x1
            unsigned int OwnsVadShared:1;// Offset=0x569 Size=0x1 BitOffset=0x6 BitSize=0x1
            unsigned int SessionAttachActive:1;// Offset=0x569 Size=0x1 BitOffset=0x7 BitSize=0x1
            unsigned int PasidMsrValid:1;// Offset=0x56a Size=0x1 BitOffset=0x0 BitSize=0x1
        };
    };
    unsigned int CacheManagerActive;// Offset=0x56c Size=0x1
    unsigned int DisablePageFaultClustering;// Offset=0x56d Size=0x1
    unsigned int ActiveFaultCount;// Offset=0x56e Size=0x1
    unsigned int LockOrderState;// Offset=0x56f Size=0x1
    unsigned long PerformanceCountLowReserved;// Offset=0x570 Size=0x4
    long PerformanceCountHighReserved;// Offset=0x574 Size=0x4
    unsigned int AlpcMessageId;// Offset=0x578 Size=0x8
    union // Size=0x8 (Id=0)
    {
        void * AlpcMessage;// Offset=0x580 Size=0x8
        unsigned long AlpcReceiveAttributeSet;// Offset=0x580 Size=0x4
    };
    struct _LIST_ENTRY AlpcWaitListEntry;// Offset=0x588 Size=0x10
    long ExitStatus;// Offset=0x598 Size=0x4
    unsigned long CacheManagerCount;// Offset=0x59c Size=0x4
    unsigned long IoBoostCount;// Offset=0x5a0 Size=0x4
    unsigned long IoQoSBoostCount;// Offset=0x5a4 Size=0x4
    unsigned long IoQoSThrottleCount;// Offset=0x5a8 Size=0x4
    unsigned long KernelStackReference;// Offset=0x5ac Size=0x4
    struct _LIST_ENTRY BoostList;// Offset=0x5b0 Size=0x10
    struct _LIST_ENTRY DeboostList;// Offset=0x5c0 Size=0x10
    unsigned int BoostListLock;// Offset=0x5d0 Size=0x8
    unsigned int IrpListLock;// Offset=0x5d8 Size=0x8
    void * ReservedForSynchTracking;// Offset=0x5e0 Size=0x8
    struct _SINGLE_LIST_ENTRY CmCallbackListHead;// Offset=0x5e8 Size=0x8
    struct _GUID * ActivityId;// Offset=0x5f0 Size=0x8
    struct _SINGLE_LIST_ENTRY SeLearningModeListHead;// Offset=0x5f8 Size=0x8
    void * VerifierContext;// Offset=0x600 Size=0x8
    void * AdjustedClientToken;// Offset=0x608 Size=0x8
    void * WorkOnBehalfThread;// Offset=0x610 Size=0x8
    struct _PS_PROPERTY_SET PropertySet;// Offset=0x618 Size=0x18
    void * PicoContext;// Offset=0x630 Size=0x8
    unsigned int UserFsBase;// Offset=0x638 Size=0x8
    unsigned int UserGsBase;// Offset=0x640 Size=0x8
    struct _THREAD_ENERGY_VALUES * EnergyValues;// Offset=0x648 Size=0x8
    union // Size=0x8 (Id=0)
    {
        unsigned int SelectedCpuSets;// Offset=0x650 Size=0x8
        unsigned int * SelectedCpuSetsIndirect;// Offset=0x650 Size=0x8
    };
    struct _EJOB * Silo;// Offset=0x658 Size=0x8
    struct _UNICODE_STRING * ThreadName;// Offset=0x660 Size=0x8
    struct _CONTEXT * SetContextState;// Offset=0x668 Size=0x8
    unsigned int LastSoftParkElectionQos;// Offset=0x670 Size=0x1
    unsigned int LastSoftParkElectionWorkloadType;// Offset=0x671 Size=0x1
    unsigned int LastSoftParkElectionRunningType;// Offset=0x672 Size=0x1
    unsigned int Spare1;// Offset=0x673 Size=0x1
    unsigned long HeapData;// Offset=0x674 Size=0x4
    struct _LIST_ENTRY OwnerEntryListHead;// Offset=0x678 Size=0x10
    unsigned int DisownedOwnerEntryListLock;// Offset=0x688 Size=0x8
    struct _LIST_ENTRY DisownedOwnerEntryListHead;// Offset=0x690 Size=0x10
    struct _KLOCK_ENTRY LockEntries[6];// Offset=0x6a0 Size=0x240
    void * CmThreadInfo;// Offset=0x8e0 Size=0x8
    void * FlsData;// Offset=0x8e8 Size=0x8
    unsigned long LastExpectedRunTime;// Offset=0x8f0 Size=0x4
    unsigned long LastSoftParkElectionRunTime;// Offset=0x8f4 Size=0x4
    unsigned int LastSoftParkElectionGeneration;// Offset=0x8f8 Size=0x8
    struct _GROUP_AFFINITY LastSoftParkElectionGroupAffinity;// Offset=0x900 Size=0x10
};
```

## _KTHREAD Structure

See the structure via WinDbg using `dt nt!_KTHREAD`.

```c
struct _KTHREAD// Size=0x480 (Id=90)
{
    struct _DISPATCHER_HEADER Header;// Offset=0x0 Size=0x18
    void * SListFaultAddress;// Offset=0x18 Size=0x8
    unsigned int QuantumTarget;// Offset=0x20 Size=0x8
    void * InitialStack;// Offset=0x28 Size=0x8
    void * StackLimit;// Offset=0x30 Size=0x8
    void * StackBase;// Offset=0x38 Size=0x8
    unsigned int ThreadLock;// Offset=0x40 Size=0x8
    unsigned int CycleTime;// Offset=0x48 Size=0x8
    unsigned long CurrentRunTime;// Offset=0x50 Size=0x4
    unsigned long ExpectedRunTime;// Offset=0x54 Size=0x4
    void * KernelStack;// Offset=0x58 Size=0x8
    struct _XSAVE_FORMAT * StateSaveArea;// Offset=0x60 Size=0x8
    struct _KSCHEDULING_GROUP * SchedulingGroup;// Offset=0x68 Size=0x8
    union _KWAIT_STATUS_REGISTER WaitRegister;// Offset=0x70 Size=0x1
    unsigned int Running;// Offset=0x71 Size=0x1
    unsigned int Alerted[2];// Offset=0x72 Size=0x2
    union // Size=0x4 (Id=0)
    {
        struct // Size=0x4 (Id=0)
        {
            unsigned long AutoBoostActive:1;// Offset=0x74 Size=0x4 BitOffset=0x0 BitSize=0x1
            unsigned long ReadyTransition:1;// Offset=0x74 Size=0x4 BitOffset=0x1 BitSize=0x1
            unsigned long WaitNext:1;// Offset=0x74 Size=0x4 BitOffset=0x2 BitSize=0x1
            unsigned long SystemAffinityActive:1;// Offset=0x74 Size=0x4 BitOffset=0x3 BitSize=0x1
            unsigned long Alertable:1;// Offset=0x74 Size=0x4 BitOffset=0x4 BitSize=0x1
            unsigned long UserStackWalkActive:1;// Offset=0x74 Size=0x4 BitOffset=0x5 BitSize=0x1
            unsigned long ApcInterruptRequest:1;// Offset=0x74 Size=0x4 BitOffset=0x6 BitSize=0x1
            unsigned long QuantumEndMigrate:1;// Offset=0x74 Size=0x4 BitOffset=0x7 BitSize=0x1
            unsigned long SecureThread:1;// Offset=0x74 Size=0x4 BitOffset=0x8 BitSize=0x1
            unsigned long TimerActive:1;// Offset=0x74 Size=0x4 BitOffset=0x9 BitSize=0x1
            unsigned long SystemThread:1;// Offset=0x74 Size=0x4 BitOffset=0xa BitSize=0x1
            unsigned long ProcessDetachActive:1;// Offset=0x74 Size=0x4 BitOffset=0xb BitSize=0x1
            unsigned long CalloutActive:1;// Offset=0x74 Size=0x4 BitOffset=0xc BitSize=0x1
            unsigned long ScbReadyQueue:1;// Offset=0x74 Size=0x4 BitOffset=0xd BitSize=0x1
            unsigned long ApcQueueable:1;// Offset=0x74 Size=0x4 BitOffset=0xe BitSize=0x1
            unsigned long ReservedStackInUse:1;// Offset=0x74 Size=0x4 BitOffset=0xf BitSize=0x1
            unsigned long Spare:1;// Offset=0x74 Size=0x4 BitOffset=0x10 BitSize=0x1
            unsigned long TimerSuspended:1;// Offset=0x74 Size=0x4 BitOffset=0x11 BitSize=0x1
            unsigned long SuspendedWaitMode:1;// Offset=0x74 Size=0x4 BitOffset=0x12 BitSize=0x1
            unsigned long SuspendSchedulerApcWait:1;// Offset=0x74 Size=0x4 BitOffset=0x13 BitSize=0x1
            unsigned long CetUserShadowStack:1;// Offset=0x74 Size=0x4 BitOffset=0x14 BitSize=0x1
            unsigned long BypassProcessFreeze:1;// Offset=0x74 Size=0x4 BitOffset=0x15 BitSize=0x1
            unsigned long CetKernelShadowStack:1;// Offset=0x74 Size=0x4 BitOffset=0x16 BitSize=0x1
            unsigned long StateSaveAreaDecoupled:1;// Offset=0x74 Size=0x4 BitOffset=0x17 BitSize=0x1
            unsigned long Reserved:8;// Offset=0x74 Size=0x4 BitOffset=0x18 BitSize=0x8
        };
        long MiscFlags;// Offset=0x74 Size=0x4
    };
    union // Size=0x4 (Id=0)
    {
        struct // Size=0x4 (Id=0)
        {
            unsigned long UserIdealProcessorFixed:1;// Offset=0x78 Size=0x4 BitOffset=0x0 BitSize=0x1
            unsigned long IsolationWidth:1;// Offset=0x78 Size=0x4 BitOffset=0x1 BitSize=0x1
            unsigned long AutoAlignment:1;// Offset=0x78 Size=0x4 BitOffset=0x2 BitSize=0x1
            unsigned long DisableBoost:1;// Offset=0x78 Size=0x4 BitOffset=0x3 BitSize=0x1
            unsigned long AlertedByThreadId:1;// Offset=0x78 Size=0x4 BitOffset=0x4 BitSize=0x1
            unsigned long QuantumDonation:1;// Offset=0x78 Size=0x4 BitOffset=0x5 BitSize=0x1
            unsigned long EnableStackSwap:1;// Offset=0x78 Size=0x4 BitOffset=0x6 BitSize=0x1
            unsigned long GuiThread:1;// Offset=0x78 Size=0x4 BitOffset=0x7 BitSize=0x1
            unsigned long DisableQuantum:1;// Offset=0x78 Size=0x4 BitOffset=0x8 BitSize=0x1
            unsigned long ChargeOnlySchedulingGroup:1;// Offset=0x78 Size=0x4 BitOffset=0x9 BitSize=0x1
            unsigned long DeferPreemption:1;// Offset=0x78 Size=0x4 BitOffset=0xa BitSize=0x1
            unsigned long QueueDeferPreemption:1;// Offset=0x78 Size=0x4 BitOffset=0xb BitSize=0x1
            unsigned long ForceDeferSchedule:1;// Offset=0x78 Size=0x4 BitOffset=0xc BitSize=0x1
            unsigned long SharedReadyQueueAffinity:1;// Offset=0x78 Size=0x4 BitOffset=0xd BitSize=0x1
            unsigned long FreezeCount:1;// Offset=0x78 Size=0x4 BitOffset=0xe BitSize=0x1
            unsigned long TerminationApcRequest:1;// Offset=0x78 Size=0x4 BitOffset=0xf BitSize=0x1
            unsigned long AutoBoostEntriesExhausted:1;// Offset=0x78 Size=0x4 BitOffset=0x10 BitSize=0x1
            unsigned long KernelStackResident:1;// Offset=0x78 Size=0x4 BitOffset=0x11 BitSize=0x1
            unsigned long TerminateRequestReason:2;// Offset=0x78 Size=0x4 BitOffset=0x12 BitSize=0x2
            unsigned long ProcessStackCountDecremented:1;// Offset=0x78 Size=0x4 BitOffset=0x14 BitSize=0x1
            unsigned long RestrictedGuiThread:1;// Offset=0x78 Size=0x4 BitOffset=0x15 BitSize=0x1
            unsigned long VpBackingThread:1;// Offset=0x78 Size=0x4 BitOffset=0x16 BitSize=0x1
            unsigned long EtwStackTraceCrimsonApcDisabled:1;// Offset=0x78 Size=0x4 BitOffset=0x17 BitSize=0x1
            unsigned long EtwStackTraceApcInserted:8;// Offset=0x78 Size=0x4 BitOffset=0x18 BitSize=0x8
        };
        long ThreadFlags;// Offset=0x78 Size=0x4
    };
    unsigned int Tag;// Offset=0x7c Size=0x1
    unsigned int SystemHeteroCpuPolicy;// Offset=0x7d Size=0x1
    struct // Size=0x1 (Id=0)
    {
        unsigned int UserHeteroCpuPolicy:7;// Offset=0x7e Size=0x1 BitOffset=0x0 BitSize=0x7
        unsigned int ExplicitSystemHeteroCpuPolicy:1;// Offset=0x7e Size=0x1 BitOffset=0x7 BitSize=0x1
    };
    unsigned int Spare0;// Offset=0x7f Size=0x1
    unsigned long SystemCallNumber;// Offset=0x80 Size=0x4
    unsigned long ReadyTime;// Offset=0x84 Size=0x4
    void * FirstArgument;// Offset=0x88 Size=0x8
    struct _KTRAP_FRAME * TrapFrame;// Offset=0x90 Size=0x8
    union // Size=0x30 (Id=0)
    {
        struct _KAPC_STATE ApcState;// Offset=0x98 Size=0x30
        unsigned int ApcStateFill[43];// Offset=0x98 Size=0x2b
    };
    char Priority;// Offset=0xc3 Size=0x1
    unsigned long UserIdealProcessor;// Offset=0xc4 Size=0x4
    int WaitStatus;// Offset=0xc8 Size=0x8
    struct _KWAIT_BLOCK * WaitBlockList;// Offset=0xd0 Size=0x8
    union // Size=0x10 (Id=0)
    {
        struct _LIST_ENTRY WaitListEntry;// Offset=0xd8 Size=0x10
        struct _SINGLE_LIST_ENTRY SwapListEntry;// Offset=0xd8 Size=0x8
    };
    struct _DISPATCHER_HEADER * Queue;// Offset=0xe8 Size=0x8
    void * Teb;// Offset=0xf0 Size=0x8
    unsigned int RelativeTimerBias;// Offset=0xf8 Size=0x8
    struct _KTIMER Timer;// Offset=0x100 Size=0x40
    union // Size=0x1e8 (Id=0)
    {
        struct _KWAIT_BLOCK WaitBlock[4];// Offset=0x140 Size=0xc0
        unsigned int WaitBlockFill4[20];// Offset=0x140 Size=0x14
        unsigned long ContextSwitches;// Offset=0x154 Size=0x4
        unsigned int WaitBlockFill5[68];// Offset=0x140 Size=0x44
        unsigned int State;// Offset=0x184 Size=0x1
        char Spare13;// Offset=0x185 Size=0x1
        unsigned int WaitIrql;// Offset=0x186 Size=0x1
        char WaitMode;// Offset=0x187 Size=0x1
        unsigned int WaitBlockFill6[116];// Offset=0x140 Size=0x74
        unsigned long WaitTime;// Offset=0x1b4 Size=0x4
        unsigned int WaitBlockFill7[164];// Offset=0x140 Size=0xa4
        int KernelApcDisable;// Offset=0x1e4 Size=0x2
        int SpecialApcDisable;// Offset=0x1e6 Size=0x2
        unsigned long CombinedApcDisable;// Offset=0x1e4 Size=0x4
        unsigned int WaitBlockFill8[40];// Offset=0x140 Size=0x28
        struct _KTHREAD_COUNTERS * ThreadCounters;// Offset=0x168 Size=0x8
        unsigned int WaitBlockFill9[88];// Offset=0x140 Size=0x58
        struct _XSTATE_SAVE * XStateSave;// Offset=0x198 Size=0x8
        unsigned int WaitBlockFill10[136];// Offset=0x140 Size=0x88
        void * Win32Thread;// Offset=0x1c8 Size=0x8
        unsigned int WaitBlockFill11[176];// Offset=0x140 Size=0xb0
    };
    unsigned int Spare18;// Offset=0x1f0 Size=0x8
    unsigned int Spare19;// Offset=0x1f8 Size=0x8
    union // Size=0x4 (Id=0)
    {
        long ThreadFlags2;// Offset=0x200 Size=0x4
        struct // Size=0x4 (Id=0)
        {
            unsigned long BamQosLevel:8;// Offset=0x200 Size=0x4 BitOffset=0x0 BitSize=0x8
            unsigned long ThreadFlags2Reserved:24;// Offset=0x200 Size=0x4 BitOffset=0x8 BitSize=0x18
        };
    };
    unsigned int HgsFeedbackClass;// Offset=0x204 Size=0x1
    unsigned int Spare23[3];// Offset=0x205 Size=0x3
    struct _LIST_ENTRY QueueListEntry;// Offset=0x208 Size=0x10
    union // Size=0x4 (Id=0)
    {
        unsigned long NextProcessor;// Offset=0x218 Size=0x4
        struct // Size=0x4 (Id=0)
        {
            unsigned long NextProcessorNumber:31;// Offset=0x218 Size=0x4 BitOffset=0x0 BitSize=0x1f
            unsigned long SharedReadyQueue:1;// Offset=0x218 Size=0x4 BitOffset=0x1f BitSize=0x1
        };
    };
    long QueuePriority;// Offset=0x21c Size=0x4
    struct _KPROCESS * Process;// Offset=0x220 Size=0x8
    struct _KAFFINITY_EX * UserAffinity;// Offset=0x228 Size=0x8
    unsigned int UserAffinityPrimaryGroup;// Offset=0x230 Size=0x2
    char PreviousMode;// Offset=0x232 Size=0x1
    char BasePriority;// Offset=0x233 Size=0x1
    union // Size=0x1 (Id=0)
    {
        char PriorityDecrement;// Offset=0x234 Size=0x1
        struct // Size=0x1 (Id=0)
        {
            unsigned int ForegroundBoost:4;// Offset=0x234 Size=0x1 BitOffset=0x0 BitSize=0x4
            unsigned int UnusualBoost:4;// Offset=0x234 Size=0x1 BitOffset=0x4 BitSize=0x4
        };
    };
    unsigned int Preempted;// Offset=0x235 Size=0x1
    unsigned int AdjustReason;// Offset=0x236 Size=0x1
    char AdjustIncrement;// Offset=0x237 Size=0x1
    unsigned int AffinityVersion;// Offset=0x238 Size=0x8
    struct _KAFFINITY_EX * Affinity;// Offset=0x240 Size=0x8
    unsigned int AffinityPrimaryGroup;// Offset=0x248 Size=0x2
    unsigned int ApcStateIndex;// Offset=0x24a Size=0x1
    unsigned int WaitBlockCount;// Offset=0x24b Size=0x1
    unsigned long IdealProcessor;// Offset=0x24c Size=0x4
    unsigned int NpxState;// Offset=0x250 Size=0x8
    union // Size=0x30 (Id=0)
    {
        struct _KAPC_STATE SavedApcState;// Offset=0x258 Size=0x30
        unsigned int SavedApcStateFill[43];// Offset=0x258 Size=0x2b
    };
    unsigned int WaitReason;// Offset=0x283 Size=0x1
    char SuspendCount;// Offset=0x284 Size=0x1
    char Saturation;// Offset=0x285 Size=0x1
    unsigned int SListFaultCount;// Offset=0x286 Size=0x2
    union // Size=0x2d8 (Id=0)
    {
        struct _KAPC SchedulerApc;// Offset=0x288 Size=0x58
        unsigned int SchedulerApcFill1[3];// Offset=0x288 Size=0x3
        unsigned int QuantumReset;// Offset=0x28b Size=0x1
        unsigned int SchedulerApcFill2[4];// Offset=0x288 Size=0x4
        unsigned long KernelTime;// Offset=0x28c Size=0x4
        unsigned int SchedulerApcFill3[64];// Offset=0x288 Size=0x40
        struct _KPRCB * WaitPrcb;// Offset=0x2c8 Size=0x8
        unsigned int SchedulerApcFill4[72];// Offset=0x288 Size=0x48
        void * LegoData;// Offset=0x2d0 Size=0x8
        unsigned int SchedulerApcFill5[83];// Offset=0x288 Size=0x53
    };
    unsigned int CallbackNestingLevel;// Offset=0x2db Size=0x1
    unsigned long UserTime;// Offset=0x2dc Size=0x4
    struct _KEVENT SuspendEvent;// Offset=0x2e0 Size=0x18
    struct _LIST_ENTRY ThreadListEntry;// Offset=0x2f8 Size=0x10
    struct _LIST_ENTRY MutantListHead;// Offset=0x308 Size=0x10
    unsigned int AbEntrySummary;// Offset=0x318 Size=0x1
    unsigned int AbWaitEntryCount;// Offset=0x319 Size=0x1
    union // Size=0x1 (Id=0)
    {
        unsigned int FreezeFlags;// Offset=0x31a Size=0x1
        struct // Size=0x1 (Id=0)
        {
            unsigned int FreezeCount2:1;// Offset=0x31a Size=0x1 BitOffset=0x0 BitSize=0x1
            unsigned int FreezeNormal:1;// Offset=0x31a Size=0x1 BitOffset=0x1 BitSize=0x1
            unsigned int FreezeDeep:1;// Offset=0x31a Size=0x1 BitOffset=0x2 BitSize=0x1
        };
    };
    char SystemPriority;// Offset=0x31b Size=0x1
    unsigned long SecureThreadCookie;// Offset=0x31c Size=0x4
    void * Spare22;// Offset=0x320 Size=0x8
    struct _SINGLE_LIST_ENTRY PropagateBoostsEntry;// Offset=0x328 Size=0x8
    struct _SINGLE_LIST_ENTRY IoSelfBoostsEntry;// Offset=0x330 Size=0x8
    unsigned int PriorityFloorCounts[32];// Offset=0x338 Size=0x20
    unsigned long PriorityFloorSummary;// Offset=0x358 Size=0x4
    long AbCompletedIoBoostCount;// Offset=0x35c Size=0x4
    long AbCompletedIoQoSBoostCount;// Offset=0x360 Size=0x4
    int KeReferenceCount;// Offset=0x364 Size=0x2
    unsigned int AbOrphanedEntrySummary;// Offset=0x366 Size=0x1
    unsigned int AbOwnedEntryCount;// Offset=0x367 Size=0x1
    unsigned long ForegroundLossTime;// Offset=0x368 Size=0x4
    union // Size=0x10 (Id=0)
    {
        struct _LIST_ENTRY GlobalForegroundListEntry;// Offset=0x370 Size=0x10
        struct _SINGLE_LIST_ENTRY ForegroundDpcStackListEntry;// Offset=0x370 Size=0x8
    };
    unsigned int InGlobalForegroundList;// Offset=0x378 Size=0x8
    int ReadOperationCount;// Offset=0x380 Size=0x8
    int WriteOperationCount;// Offset=0x388 Size=0x8
    int OtherOperationCount;// Offset=0x390 Size=0x8
    int ReadTransferCount;// Offset=0x398 Size=0x8
    int WriteTransferCount;// Offset=0x3a0 Size=0x8
    int OtherTransferCount;// Offset=0x3a8 Size=0x8
    struct _KSCB * QueuedScb;// Offset=0x3b0 Size=0x8
    unsigned long ThreadTimerDelay;// Offset=0x3b8 Size=0x4
    union // Size=0x4 (Id=0)
    {
        long ThreadFlags3;// Offset=0x3bc Size=0x4
        struct // Size=0x4 (Id=0)
        {
            unsigned long ThreadFlags3Reserved:8;// Offset=0x3bc Size=0x4 BitOffset=0x0 BitSize=0x8
            unsigned long PpmPolicy:3;// Offset=0x3bc Size=0x4 BitOffset=0x8 BitSize=0x3
            unsigned long ThreadFlags3Reserved2:21;// Offset=0x3bc Size=0x4 BitOffset=0xb BitSize=0x15
        };
    };
    unsigned int TracingPrivate[1];// Offset=0x3c0 Size=0x8
    void * SchedulerAssist;// Offset=0x3c8 Size=0x8
    void * AbWaitObject;// Offset=0x3d0 Size=0x8
    unsigned long ReservedPreviousReadyTimeValue;// Offset=0x3d8 Size=0x4
    unsigned int KernelWaitTime;// Offset=0x3e0 Size=0x8
    unsigned int UserWaitTime;// Offset=0x3e8 Size=0x8
    union // Size=0x10 (Id=0)
    {
        struct _LIST_ENTRY GlobalUpdateVpThreadPriorityListEntry;// Offset=0x3f0 Size=0x10
        struct _SINGLE_LIST_ENTRY UpdateVpThreadPriorityDpcStackListEntry;// Offset=0x3f0 Size=0x8
    };
    unsigned int InGlobalUpdateVpThreadPriorityList;// Offset=0x3f8 Size=0x8
    long SchedulerAssistPriorityFloor;// Offset=0x400 Size=0x4
    long RealtimePriorityFloor;// Offset=0x404 Size=0x4
    void * KernelShadowStack;// Offset=0x408 Size=0x8
    void * KernelShadowStackInitial;// Offset=0x410 Size=0x8
    void * KernelShadowStackBase;// Offset=0x418 Size=0x8
    union _KERNEL_SHADOW_STACK_LIMIT KernelShadowStackLimit;// Offset=0x420 Size=0x8
    unsigned int ExtendedFeatureDisableMask;// Offset=0x428 Size=0x8
    unsigned int HgsFeedbackStartTime;// Offset=0x430 Size=0x8
    unsigned int HgsFeedbackCycles;// Offset=0x438 Size=0x8
    unsigned long HgsInvalidFeedbackCount;// Offset=0x440 Size=0x4
    unsigned long HgsLowerPerfClassFeedbackCount;// Offset=0x444 Size=0x4
    unsigned long HgsHigherPerfClassFeedbackCount;// Offset=0x448 Size=0x4
    unsigned long Spare27;// Offset=0x44c Size=0x4
    struct _SINGLE_LIST_ENTRY SystemAffinityTokenListHead;// Offset=0x450 Size=0x8
    void * IptSaveArea;// Offset=0x458 Size=0x8
    unsigned int ResourceIndex;// Offset=0x460 Size=0x1
    unsigned int CoreIsolationReasons;// Offset=0x461 Size=0x1
    unsigned int BamQosLevelFromAssistPage;// Offset=0x462 Size=0x1
    unsigned int Spare31[1];// Offset=0x463 Size=0x1
    unsigned long Spare32;// Offset=0x464 Size=0x4
    unsigned int EndPadding[3];// Offset=0x468 Size=0x18
};
```

### [QuantumReset Example](https://noverse.dev/docs/win-config/system/priority-separation/#threads-quantumreset)

Example of looking at the `QuantumReset` field.

```c
// 0x18
lkd> db PspForegroundQuantum L3
fffff805`45954bec  24 24 24                                         $$$

lkd> !process 0 4 CPUSTRES.exe
PROCESS ffff8084c5d5f080
    SessionId: 1  Cid: 1644    Peb: 00f27000  ParentCid: 0b8c
    DirBase: 73a73e000  ObjectTable: ffffdb8a6c01fc40  HandleCount: 201.
    Image: CPUSTRES.EXE

        THREAD ffff8084c125d080  Cid 1644.1694  Teb: 0000000000f29000 Win32Thread: ffff8084c4f9ec90 WAIT
        THREAD ffff8084c0ced080  Cid 1644.272c  Teb: 0000000000f2d000 Win32Thread: 0000000000000000 WAIT
        THREAD ffff8084c23ba300  Cid 1644.1630  Teb: 0000000000f31000 Win32Thread: 0000000000000000 WAIT
        THREAD ffff8084be291080  Cid 1644.0e10  Teb: 0000000000f35000 Win32Thread: 0000000000000000 WAIT
        THREAD ffff8084c293e080  Cid 1644.15d4  Teb: 0000000000f39000 Win32Thread: 0000000000000000 WAIT
        THREAD ffff8084be31f080  Cid 1644.0d28  Teb: 0000000000f3d000 Win32Thread: 0000000000000000 WAIT
        THREAD ffff8084c06c1080  Cid 1644.14e0  Teb: 0000000000f41000 Win32Thread: 0000000000000000 WAIT
        THREAD ffff8084bf5be080  Cid 1644.14bc  Teb: 0000000000f45000 Win32Thread: 0000000000000000 WAIT

lkd> dt _KTHREAD ffff8084c125d080 QuantumReset
   +0x28b QuantumReset : 0x24 '$'

// 0x2 (default)
lkd> db PspForegroundQuantum L3
fffff800`56354bec  06 0c 12                                         ...

lkd> !process 0 4 CPUSTRES.exe
PROCESS ffffd687c63fb380
    SessionId: 1  Cid: 09d4    Peb: 011dd000  ParentCid: 0fd0
    DirBase: 7862de000  ObjectTable: ffffe6886846cc40  HandleCount: 197.
    Image: CPUSTRES.EXE

        THREAD ffffd687c48a8080  Cid 09d4.1ad4  Teb: 00000000011df000 Win32Thread: ffffd687c6c95ed0 WAIT
        THREAD ffffd687c5949080  Cid 09d4.195c  Teb: 00000000011e3000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd687c2269140  Cid 09d4.19a4  Teb: 00000000011e7000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd687c43460c0  Cid 09d4.1a28  Teb: 00000000011eb000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd687c43350c0  Cid 09d4.13d0  Teb: 00000000011ef000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd687c70020c0  Cid 09d4.1018  Teb: 00000000011f3000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd687c6e75080  Cid 09d4.1b18  Teb: 00000000011f7000 Win32Thread: 0000000000000000 WAIT
        THREAD ffffd687c4f8f080  Cid 09d4.1b34  Teb: 00000000011fb000 Win32Thread: 0000000000000000 WAIT

lkd> dt _KTHREAD ffffd687c48a8080 QuantumReset
nt!_KTHREAD
   +0x28b QuantumReset : 0x6 '' // BG

lkd> .sleep 0n3000; dt _KTHREAD ffffd687c48a8080 QuantumReset
nt!_KTHREAD
   +0x28b QuantumReset : 0x12 '' // FG
```