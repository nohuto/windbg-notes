# Interrupts

An interrupt is an asynchronous event (can occur at any time) that causes a processor to stop its current execution so an event can be handled. Hardware interrupts can come from devices (printers, keyboards, network cards etc.)/timers/other processors.

### Interrupt Processing

Context for the sections below, see `Windows Internals: Trap Dispatching` for details.

![](https://github.com/nohuto/windbg-notes/blob/main/assets/interrupt-control-flow.png?raw=true)

Means the device interrupt goes through the IOAPIC & LAPIC (of selected processor), the processor uses the interrupt vector (in IOAPIC fields) to index the IDT, which reaches the kernel interrupt dispatcher and the interrupt object (`_KINTERRUPT`). Then the dispatcher raises IRQL, synchronizes with the ISR, and the driver ISR handles the device work (often by requesting a DPC).

## APIC

![](https://github.com/nohuto/windbg-notes/blob/main/assets/ioapic.png?raw=true)

There's one LAPIC per processor and one or more IOAPICs (for line based device interrupts), the LAPIC receives interrupts from the IOAPIC, while the IOAPIC receives interrupts from the device (and redirects them to the LAPIC) as shown above.

Use `!apic` displays the LAPIC state for the current processor:

```c
lkd> !apic
Apic @ c0009000  ID:d (80050010)  LogDesc:28000000  DestFmt:0fffffff  TPR 20
TimeCnt: 00000000clk  SpurVec:df  FaultVec:e2  error:0
Ipi Cmd: 22000000`0000082f  Vec:2F  FixedDel  Lg:22000000      edg high
Timer..: 00000000`000300d1  Vec:D1  FixedDel    Dest=Self      edg high      m
Linti0.: 00000000`000100d8  Vec:D8  FixedDel    Dest=Self      edg high      m
Linti1.: 00000000`00000400  Vec:00  NMI         Dest=Self      edg high
TMR:
IRR:
ISR:
```

## I/O APIC

`!ioapic` shows IOAPICs and their redirection table values:

```c
lkd> !ioapic
Controller at 0xfffff7dfc0007a70 I/O APIC at VA 0xfffff7dfc000a000
IoApic @ FEC00000  ID:D (21)  Arb:D000000
Inti06.: 2f000000`00000970  Vec:70  LowestDl  Lg:2f000000      edg high
Inti09.: 0f000000`0000a9b0  Vec:B0  LowestDl  Lg:0f000000      lvl low
```

Here the `Vec` (vector) field shows `0x70`, when looking at the IDT below we'll see that vector again.

## IDT

The IDT (interrupt descriptor table) assingns interrupt vectors to handlers.

```c
lkd> !idt

Dumping IDT: fffff8032f853000

00:	fffff8032ae2b400 nt!KiDivideErrorFault
01:	fffff8032ae2b780 nt!KiDebugTrapOrFault	Stack = 0xFFFFF8032F893000
02:	fffff8032ae2bd80 nt!KiNmiInterrupt	Stack = 0xFFFFF8032F885000
03:	fffff8032ae2c300 nt!KiBreakpointTrap
04:	fffff8032ae2c680 nt!KiOverflowTrap
05:	fffff8032ae2ca00 nt!KiBoundFault
06:	fffff8032ae2d100 nt!KiInvalidOpcodeFault
07:	fffff8032ae2d7c0 nt!KiNpxNotAvailableFault
08:	fffff8032ae2db80 nt!KiDoubleFaultAbort	Stack = 0xFFFFF8032F87E000
09:	fffff8032ae2df00 nt!KiNpxSegmentOverrunAbort
0a:	fffff8032ae2e280 nt!KiInvalidTssFault
0b:	fffff8032ae2e600 nt!KiSegmentNotPresentFault
0c:	fffff8032ae2ea00 nt!KiStackFault
0d:	fffff8032ae2ed80 nt!KiGeneralProtectionFault
0e:	fffff8032ae2f100 nt!KiPageFault
10:	fffff8032ae2f900 nt!KiFloatingErrorFault
11:	fffff8032ae2fd00 nt!KiAlignmentFault
12:	fffff8032ae30080 nt!KiMcheckAbort	Stack = 0xFFFFF8032F88C000
13:	fffff8032ae30e40 nt!KiXmmException
14:	fffff8032ae31240 nt!KiVirtualizationException
15:	fffff8032ae31940 nt!KiControlProtectionFault
1f:	fffff8032ae23f20 nt!KiApcInterrupt
20:	fffff8032ae26300 nt!KiSwInterrupt
29:	fffff8032ae32080 nt!KiRaiseSecurityCheckFailure
2c:	fffff8032ae32400 nt!KiRaiseAssertion
2d:	fffff8032ae32780 nt!KiDebugServiceTrap
2f:	fffff8032ae26af0 nt!KiDpcInterrupt
30:	fffff8032ae246e0 nt!KiHvInterrupt
31:	fffff8032ae24a40 nt!KiVmbusInterrupt0
32:	fffff8032ae24da0 nt!KiVmbusInterrupt1
33:	fffff8032ae25100 nt!KiVmbusInterrupt2
34:	fffff8032ae25460 nt!KiVmbusInterrupt3
35:	fffff8032ae21b68 nt!HalpInterruptCmciService (KINTERRUPT fffff8032b70cf10)

36:	fffff8032ae21b70 nt!HalpInterruptCmciService (KINTERRUPT fffff8032b70d150)

60:	fffff8032ae21cc0 0xfffff8032fea9100 (KINTERRUPT ffff9700229003c0)

70:	fffff8032ae21d40 0xfffff8032fea9100 (KINTERRUPT ffff970022900500)

80:	fffff8032ae21dc0 0xfffff8032fea9100 (KINTERRUPT ffff970022900a00)

	                 0xfffff8032fea9100 (KINTERRUPT ffff9700229008c0)

	                 0xfffff8032fea9100 (KINTERRUPT ffff970022900780)

	                 0xfffff8032fea9100 (KINTERRUPT ffff970022900640)

90:	fffff8032ae21e40 0xfffff8033050faf0 (KINTERRUPT ffff970022900b40)

a0:	fffff8032ae21ec0 0xfffff8033050faf0 (KINTERRUPT ffff970022900c80)

b0:	fffff8032ae21f40 0xfffff80330003d30 (KINTERRUPT ffff970022900dc0)

ce:	fffff8032ae22030 nt!HalpIommuInterruptRoutine (KINTERRUPT fffff8032b70da50)

d1:	fffff8032ae22048 nt!HalpTimerClockInterrupt (KINTERRUPT fffff8032b70d930)

d2:	fffff8032ae22050 nt!HalpTimerClockIpiRoutine (KINTERRUPT fffff8032b70d810)

d7:	fffff8032ae22078 nt!HalpInterruptRebootService (KINTERRUPT fffff8032b70d5d0)

d8:	fffff8032ae22080 nt!HalpInterruptStubService (KINTERRUPT fffff8032b70d390)

df:	fffff8032ae220b8 nt!HalpInterruptSpuriousService (KINTERRUPT fffff8032b70d270)

e1:	fffff8032ae27200 nt!KiIpiInterrupt
e2:	fffff8032ae220d0 nt!HalpInterruptLocalErrorService (KINTERRUPT fffff8032b70d4b0)

e3:	fffff8032ae220d8 nt!HalpInterruptDeferredRecoveryService (KINTERRUPT fffff8032b70d030)

fe:	fffff8032ae221b0 nt!HalpPerfInterrupt (KINTERRUPT fffff8032b70d6f0)
```

Here we can see that the previous vector `0x70` (from `!ioapic`) references a `_KINTERRUPT` object.

```c
lkd> dt nt!_KINTERRUPT ffff970022900500 Vector Irql SynchronizeIrql ServiceRoutine ServiceContext
   +0x018 ServiceRoutine  : 0xfffff803`2fea9100     unsigned char  +fffff8032fea9100 // ISR address
   +0x030 ServiceContext  : 0xffffe60b`68e89c00 Void // passed into ISR
   +0x058 Vector          : 0x70
   +0x05c Irql            : 0x7 '' // level used by interrupt
   +0x05d SynchronizeIrql : 0x7 ''
```

## Interrupt Service Routine

The ISR is the drivers routine for handling a hardware interrupt, which runs in interrupt context at the DIRQL (device IRQL, see [IRQLs]()). The ISR should only dismiss the interrupt, save volatile state and queue any remaining work as a [DPC](). The `ServiceRoutine` field in the `_KINTERRUPT` structure is the ISR address (`MessageServiceRoutine` address for MSI).

## _KINTERRUPT Structure

```c
lkd> dt nt!_KINTERRUPT
   +0x000 Type             : Int2B
   +0x002 Size             : Int2B
   +0x008 InterruptListEntry : _LIST_ENTRY
   +0x018 ServiceRoutine   : Ptr64     unsigned char
   +0x020 MessageServiceRoutine : Ptr64     unsigned char
   +0x028 MessageIndex     : Uint4B
   +0x030 ServiceContext   : Ptr64 Void
   +0x038 SpinLock         : Uint8B
   +0x040 TickCount        : Uint4B
   +0x048 ActualLock       : Ptr64 Uint8B
   +0x050 DispatchAddress  : Ptr64     void
   +0x058 Vector           : Uint4B
   +0x05c Irql             : UChar
   +0x05d SynchronizeIrql  : UChar
   +0x05e FloatingSave     : UChar
   +0x05f Connected        : UChar
   +0x060 Number           : Uint4B
   +0x064 ShareVector      : UChar
   +0x065 EmulateActiveBoth : UChar
   +0x066 ActiveCount      : Uint2B
   +0x068 InternalState    : Int4B
   +0x06c Mode             : _KINTERRUPT_MODE
   +0x070 Polarity         : _KINTERRUPT_POLARITY
   +0x074 ServiceCount     : Uint4B
   +0x078 DispatchCount    : Uint4B
   +0x080 PassiveEvent     : Ptr64 _KEVENT
   +0x088 TrapFrame        : Ptr64 _KTRAP_FRAME
   +0x090 DisconnectData   : Ptr64 Void
   +0x098 ServiceThread    : Ptr64 _KTHREAD
   +0x0a0 ConnectionData   : Ptr64 _INTERRUPT_CONNECTION_DATA
   +0x0a8 IntTrackEntry    : Ptr64 Void
   +0x0b0 IsrDpcStats      : _ISRDPCSTATS
   +0x110 RedirectObject   : Ptr64 Void
   +0x118 Padding          : [8] UChar
```
