# Deferred Procedure Calls

An ordinary DPC runs at `DISPATCH_LEVEL` IRQL, and can interrupt every thread regardless of its priority.

## _KDPC Structure

```c
lkd> dt nt!_KDPC
   +0x000 TargetInfoAsUlong : Uint4B
   +0x000 Type             : UChar
   +0x001 Importance       : UChar
   +0x002 Number           : Uint2B
   +0x008 DpcListEntry     : _SINGLE_LIST_ENTRY
   +0x010 ProcessorHistory : Uint8B
   +0x018 DeferredRoutine  : Ptr64     void // callback address
   +0x020 DeferredContext  : Ptr64 Void // passed into DeferredRoutine
   +0x028 SystemArgument1  : Ptr64 Void // ^
   +0x030 SystemArgument2  : Ptr64 Void // ^
   +0x038 DpcData          : Ptr64 Void
```

## _KDPC_DATA Structure

Each `_KPRCB` includes `DpcData[2]`, and its `_KDPC_DATA` fields show the processors ordinary & threaded DPC queues (see [DpcCount](https://noverse.dev/docs/win-config/system/kernel-values/#dpccount)):

```c
lkd> dt nt!_KDPC_DATA
   +0x000 DpcList          : _KDPC_LIST
   +0x010 DpcLock          : Uint8B
   +0x018 DpcQueueDepth    : Int4B // waiting in queue
   +0x01c DpcCount         : Uint4B // ordinary/threaded
   +0x020 ActiveDpc        : Ptr64 _KDPC // currently executing
   +0x028 LongDpcPresent   : Uint4B
   +0x02c Padding          : Uint4B
```
