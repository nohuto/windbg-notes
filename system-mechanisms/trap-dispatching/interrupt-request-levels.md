# Interrupt Request Levels

Interrupt request levels (IRQLs) are basically an interrupt source priority and a per processor priority state. Each interrupt source has such an IRQL, and each processor also has a current IRQL, which defines what source can interrupt that processor. I won't add `!irql` (displays `DebuggerSavedIRQL` of KPRCB) as the output within a debugger of it is meaningless.

Note that `PASSIVE_LEVEL`/`LOW_LEVEL` = IRQL `0`, where usually normal thread execution happens, means its not really a interrupt level.

![](https://github.com/nohuto/windbg-notes/blob/main/assets/irql-levels.png?raw=true)

```c
// wdm.h
//
// Interrupt Request Level definitions
//

#define PASSIVE_LEVEL 0                 // Passive release level
#define LOW_LEVEL 0                     // Lowest interrupt level
#define APC_LEVEL 1                     // APC interrupt level
#define DISPATCH_LEVEL 2                // Dispatcher level
#define CMCI_LEVEL 5                    // CMCI handler level

#define CLOCK_LEVEL 13                  // Interval clock level
#define IPI_LEVEL 14                    // Interprocessor interrupt level
#define DRS_LEVEL 14                    // Deferred Recovery Service level
#define POWER_LEVEL 14                  // Power failure level
#define PROFILE_LEVEL 15                // timer used for profiling.
#define HIGH_LEVEL 15                   // Highest interrupt level
```

At `DISPATCH_LEVEL` and above:

- Normal thread preemption cannot occur on that processor
- Code cannot wait for a dispatcher object
- Pageable memory cannot be accessed
- A page fault cannot be handled

This is also a reason why a DPC is used afterwards to keep the IRQL elevated for a short time (see [interrupt processing](https://noverse.dev/docs/windbg-notes/system-mechanisms/trap-dispatching/interrupt-dispatching/#interrupt-processing) for the full image).

![](https://github.com/nohuto/windbg-notes/blob/main/assets/driver-isr.png?raw=true)

## _KPCR Irql

You can display the `Irql` of a processor via its field in the kernel processor control region (`KPCR`) structure (see '[Processor Control Region](https://noverse.dev/docs/windbg-notes/system-mechanisms/processor-execution-model/processor-control-region/)' for context):

```c
lkd> dt nt!_KPCR @$pcr Irql
   +0x050 Irql             : 0 ''
```
