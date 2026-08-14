/*
 * XREFs of SwapContext @ 0x140428750
 * Functions that call SwapContext:
 *     KiIdleLoop @ 0x140423D50
 *     KiSwapContext @ 0x140428670
 * Functions called by SwapContext:
 *     HalRequestSoftwareInterrupt @ 0x140254DD0
 *     KiBeginThreadAccountingPeriod @ 0x140309040
 *     KiUpdateSpeculationControl @ 0x140325E50
 *     EtwTraceContextSwap @ 0x14038A500
 *     KiCheckVpBackingLongSpinWaitHypercall @ 0x1403CD4A0
 *     HvlNotifyLongSpinWait @ 0x1403CD4D0
 *     KeBugCheckEx @ 0x14041EDE0
 *     SwapContext @ 0x140428750 (32 calls inside the function used to fill the RSB)
 *     KiClearLastBranchRecordStack @ 0x1404601D0
 *     KeCheckAndApplyBamQos @ 0x140461770
 *     HvlSwitchVirtualAddressSpace @ 0x140549F50
 *     KiResetProcessorTraceBuffer @ 0x14056D5E0
 *     KiRestoreThreadIptState @ 0x140573220
 *     KiSaveThreadIptState @ 0x140573350
 *     KiCheckAndApplyCacheIsolation @ 0x1405773E0
 *
 * KiSwapContext & KiIdleLoop pass values in these registers:
 *     rdi = old KTHREAD
 *     rsi = new KTHREAD
 *     rbx = current KPRCB
 *     cl = APC bypass
 *     al = return value
 */

unsigned __int8 __usercall SwapContext@<al>(
        struct _KTHREAD *OldThread@<rdi>,
        struct _KTHREAD *NewThread@<rsi>,
        struct _KPRCB *CurrentPrcb@<rbx>,
        unsigned __int8 OldApcBypass@<cl>)
{
  struct _KPCR *CurrentPcr;
  struct _ETHREAD *OldEthread;
  struct _ETHREAD *NewEthread;
  struct _EPROCESS *OldEprocess;
  struct _EPROCESS *NewEprocess;
  unsigned int SpinCount;
  unsigned __int64 Tsc;
  unsigned __int64 CycleDelta;
  unsigned __int64 FeatureBits;
  unsigned __int64 XStateMask;
  unsigned __int64 RestoreMask;
  unsigned __int64 TaggedProcess;
  struct _KPROCESS *OldAddressProcess;
  struct _KPROCESS *NewAddressProcess;
  unsigned __int64 DirectoryTableBase;
  unsigned __int64 InitialStack;
  unsigned __int64 OldShadowStackPointer;
  unsigned __int64 GdtBase;
  unsigned int FsDescriptorBase;
  unsigned __int64 UserGsBase;
  unsigned __int16 NewApcBypassWord;
  unsigned __int16 DsSelector;
  unsigned __int16 EsSelector;
  unsigned __int16 GsSelector;

  _m_prefetchw(&NewThread->Running);
  __asm { mov byte ptr [rsp+28h], OldApcBypass }
  SpinCount = 0;
  while ( NewThread->Running )
  {
    ++SpinCount;
    if ( (SpinCount & HvlLongSpinCountMask) == 0
      && (HvlEnlightenments & 0x40) != 0
      && KiCheckVpBackingLongSpinWaitHypercall() )
    {
      HvlNotifyLongSpinWait(SpinCount);
    }
    _mm_pause();
  }
  /* Mark NewThread as running after its previous CS has finished */
  NewThread->Running = 1;

  if ( KiHresetMask )
    __asm { hreset  0 }

  _disable();
  Tsc = __rdtsc();
  CycleDelta = Tsc - CurrentPrcb->StartCycles;
  CurrentPrcb->CycleTime += CycleDelta;
  CurrentPrcb->StartCycles += CycleDelta;

  if ( CurrentPrcb->InterruptRequest )
  {
    CurrentPrcb->InterruptRequest = 0;
    if ( CurrentPrcb->IdleThread != NewThread )
      HalRequestSoftwareInterrupt(2); // DISPATCH_LEVEL
  }

  if ( (NewThread->Header.ThreadControlFlags & 0xB6) != 0 )
  {
    KiBeginThreadAccountingPeriod(CurrentPrcb, NewThread, CycleDelta);
  }
  else
  {
    --CurrentPrcb->NestingLevel;
    _enable();
  }

  ++CurrentPrcb->KeContextSwitches;
  FeatureBits = KeFeatureBits;

  if ( KiCacheIsoBitmap && _bittest64((const signed __int64 *)&FeatureBits, 44) )
    KiCheckAndApplyCacheIsolation(CurrentPrcb, NewThread);

  if ( CurrentPrcb->IdleThread != NewThread
    && NewThread->BamQosLevel != CurrentPrcb->BamQosLevel )
  {
    KeCheckAndApplyBamQos(CurrentPrcb, NewThread);
  }

  /* Save the old threads extended processor state */
  XStateMask = OldThread->NpxState & ~2ULL;
  if ( XStateMask )
  {
    /* EDX:EAX holds the XStateMask used by each instruction below */
    if ( _bittest64((const signed __int64 *)&FeatureBits, 38) )
    {
      __asm { xsaves  byte ptr [OldThread->StateSaveArea] }
    }
    else if ( _bittest64((const signed __int64 *)&FeatureBits, 15) )
    {
      __asm { xsaveopt byte ptr [OldThread->StateSaveArea] }
    }
    else if ( _bittest((const signed __int32 *)&FeatureBits, 23) )
    {
      __asm { xsave   byte ptr [OldThread->StateSaveArea] }
    }
    else
    {
      __asm { fxsave  dword ptr [OldThread->StateSaveArea] }
    }
  }
  __asm { stmxcsr dword ptr [OldThread->StateSaveArea + 18h] }

  if ( (XStateMask & 0x100) != 0 && KiIptMsrMask )
    KiSaveThreadIptState(OldThread);

  /*
   * Switch kernel stacks. OldApcBypass was saved at [rsp+28h] near the start
   * of this function. After rsp changes, [rsp+28h] refers to the value saved
   * when NewThread last ran SwapContext.
   */
  __asm
  {
    mov [OldThread->KernelStack], rsp
    mov rsp, [NewThread->KernelStack]
  }

  if ( (KiKernelCetEnabled & 1) != 0 )
  {
    CurrentPrcb->KernelShadowStackInitial = (unsigned __int64)NewThread->KernelShadowStackInitial;
    __asm { rdsspq OldShadowStackPointer }
    __asm
    {
      rstorssp qword ptr [NewThread->KernelShadowStack]
      saveprevssp
    }
    OldThread->KernelShadowStack = (void *)(OldShadowStackPointer - 8);
  }

  /* ETHREAD starts with KTHREAD, EPROCESS starts with KPROCESS */
  OldEthread = (struct _ETHREAD *)OldThread;
  OldEprocess = (struct _EPROCESS *)OldThread->Process;
  if ( OldEprocess->WoW64Process )
    OldEthread->UserFsBase = __readmsr(0xC0000100); // IA32_FS_BASE

  if ( _bittestandreset((signed __int32 *)&CurrentPrcb->BpbRetpolineState, 0) )
    OldThread->SpecCtrl |= 2;

  if ( _bittestandreset((signed __int32 *)&NewThread->SpecCtrl, 1) )
    CurrentPrcb->BpbRetpolineState |= 1;

  /* Keep the low byte process and pair tags used by speculation control */
  TaggedProcess = (unsigned __int64)NewThread->Process;
  LOBYTE(TaggedProcess) = (LOBYTE(TaggedProcess) | LOBYTE(CurrentPrcb->PairRegister)) & 0xC2;
  if ( TaggedProcess != (unsigned __int64)OldThread->Process )
  {
    LOBYTE(TaggedProcess) &= 0xC0;
    KiUpdateSpeculationControl(TaggedProcess);
  }
  else if ( (CurrentPrcb->BpbRetpolineState & 3) == 1 )
  {
    unsigned __int16 TrappedSpecCtrl;
    unsigned __int8 TrappedBpbState;

    _disable();
    TrappedSpecCtrl = CurrentPrcb->BpbTrappedRetpolineExitSpecCtrl;
    if ( CurrentPrcb->BpbCurrentSpecCtrl != TrappedSpecCtrl )
    {
      CurrentPrcb->BpbCurrentSpecCtrl = TrappedSpecCtrl;
      __writemsr(0x48, TrappedSpecCtrl); // IA32_SPEC_CTRL
    }

    TrappedBpbState = (unsigned __int8)CurrentPrcb->BpbTrappedBpbState;
    if ( (TrappedBpbState & 0x10) != 0 ) // BpbTrappedIbpbOnRetpolineExit
      __writemsr(0x49, 1); // IA32_PRED_CMD: IBPB

    if ( (TrappedBpbState & 0x40) != 0 ) // BpbTrappedFlushRsbOnRetpolineExit
    {
      /*
       * Code at 0x14042898E-0x140428AAA makes 32 nested calls to fill the
       * hardware return stack buffer. The sequence does not return normally.
       */
      /* Assembly does not call a function here */
      StuffReturnStackBufferWith32NestedCalls();
      if ( (CurrentPrcb->BpbFeatures & 8) != 0 ) // BpbKCet
      {
        /* Discard the 32 corresponding CET shadow stack return entries */
        __asm
        {
          mov eax, 20h
          incsspq rax
        }
      }
    }

    _mm_lfence();
    CurrentPrcb->BpbRetpolineState |= 2; // BpbIndirectCallsSafe
    _enable();
  }

  /* Switch address spaces if the threads use different processes */
  NewAddressProcess = NewThread->ApcState.Process;
  OldAddressProcess = OldThread->ApcState.Process;
  if ( NewAddressProcess != OldAddressProcess )
  {
    _interlockedbittestandset64(
      (volatile signed __int64 *)&NewAddressProcess->ActiveProcessors.Bitmap[CurrentPrcb->Group],
      CurrentPrcb->GroupIndex);

    DirectoryTableBase = NewAddressProcess->DirectoryTableBase;
    if ( (KiKvaShadow & 1) != 0 )
    {
      _disable();
      if ( (DirectoryTableBase & 2) != 0 )
      {
        DirectoryTableBase |= 0x8000000000000000ULL;
        CurrentPrcb->ShadowFlags |= 1;
      }
      CurrentPrcb->KernelDirectoryTableBase = DirectoryTableBase;
      DirectoryTableBase &= ~0x8000000000000000ULL;
      CurrentPrcb->ShadowFlags &= ~2u;
      if ( _bittest((const signed __int32 *)&NewAddressProcess->AddressPolicy, 0) )
        CurrentPrcb->ShadowFlags ^= 3u;
      _enable();
    }

    if ( (HvlEnlightenments & 1) != 0 )
    {
      HvlSwitchVirtualAddressSpace(DirectoryTableBase);
    }
    else
    {
      __writecr3(DirectoryTableBase);
      if ( (KiKvaShadow & 1) != 0 && (DirectoryTableBase & 2) == 0 )
      {
        unsigned __int64 Cr4 = __readcr4();
        __writecr4(Cr4 ^ 0x80);
        __writecr4(Cr4);
      }
    }

    _interlockedbittestandreset64(
      (volatile signed __int64 *)&OldAddressProcess->ActiveProcessors.Bitmap[CurrentPrcb->Group],
      CurrentPrcb->GroupIndex);
  }

  /* KPRCB is embedded at KPCR+0x180 in this build */
  CurrentPcr = CONTAINING_RECORD(CurrentPrcb, struct _KPCR, Prcb);
  InitialStack = (unsigned __int64)NewThread->InitialStack;
  if ( (KiKvaShadow & 1) != 0 )
  {
    CurrentPrcb->RspBaseShadow = InitialStack;
  }
  else
  {
    CurrentPcr->TssBase->Rsp0 = InitialStack;
  }
  CurrentPrcb->RspBase = InitialStack;

  if ( (signed __int64)InitialStack >= 0 )
    KeBugCheckEx(0x1CE, (ULONG_PTR)OldThread, (ULONG_PTR)NewThread, 0, 0);

  if ( KiCpuTracingFlags )
  {
    if ( (DWORD1(PerfGlobalGroupMask) & 4) != 0 )
      EtwTraceContextSwap(OldThread, NewThread);
    if ( (KiCpuTracingFlags & 2) != 0 )
      KiClearLastBranchRecordStack();
    if ( (KiCpuTracingFlags & 4) != 0 )
      KiResetProcessorTraceBuffer();
  }

  if ( _bittest64((const signed __int64 *)&FeatureBits, 55)
    && OldThread->ExtendedFeatureDisableMask != NewThread->ExtendedFeatureDisableMask )
  {
    __writemsr(0x1C4, NewThread->ExtendedFeatureDisableMask); // IA32_XFD
  }

  RestoreMask = NewThread->NpxState
              | (OldThread->NpxState & 0x40000)
              | (OldThread->NpxState & KeEnabledSupervisorXStateFeatures);

  /* Required old thread state is now saved, so mark OldThread as not running */
  OldThread->Running = 0;

  RestoreMask &= ~2ULL;
  if ( RestoreMask )
  {
    /* EDX:EAX holds the RestoreMask used by each restore instruction */
    if ( _bittest64((const signed __int64 *)&FeatureBits, 41) && (RestoreMask & 1) != 0 )
      __asm { fninit }

    if ( _bittest64((const signed __int64 *)&FeatureBits, 38) )
    {
      __asm { xrstors byte ptr [NewThread->StateSaveArea] }
    }
    else if ( _bittest((const signed __int32 *)&FeatureBits, 23) )
    {
      __asm { xrstor byte ptr [NewThread->StateSaveArea] }
    }
    else
    {
      __asm { fxrstor dword ptr [NewThread->StateSaveArea] }
    }
  }
  __asm { ldmxcsr dword ptr [NewThread->StateSaveArea + 18h] }

  if ( (RestoreMask & 0x100) != 0 && KiIptMsrMask )
    KiRestoreThreadIptState(NewThread);

  if ( !NewThread->SystemThread )
  {
    NewEthread = (struct _ETHREAD *)NewThread;
    NewEprocess = (struct _EPROCESS *)NewThread->Process;
    FsDescriptorBase = (unsigned int)NewEthread->UserFsBase;
    if ( NewEprocess->WoW64Process )
      FsDescriptorBase = (unsigned int)(unsigned __int64)NewThread->Teb + 0x2000;

    GdtBase = (unsigned __int64)CurrentPcr->GdtBase;
    *(_WORD *)(GdtBase + 0x52) = (unsigned __int16)FsDescriptorBase;
    *(_BYTE *)(GdtBase + 0x54) = BYTE2(FsDescriptorBase);
    *(_BYTE *)(GdtBase + 0x57) = BYTE3(FsDescriptorBase);
    __asm { mov fs, 53h }

    __writemsr(0xC0000100, NewEthread->UserFsBase); // IA32_FS_BASE

    __asm
    {
      mov eax, ds
      mov DsSelector, ax
      mov eax, es
      mov EsSelector, ax
      mov eax, gs
      mov GsSelector, ax
    }
    if ( (unsigned __int16)(DsSelector & EsSelector & GsSelector) != 0x2B )
    {
      __asm
      {
        mov edx, 2Bh
        mov ds, edx
        mov es, edx
        cli
        swapgs
        mov gs, edx
        swapgs
        sti
      }
    }

    CurrentPcr->Used_Self = NewThread->Teb;

    UserGsBase = (unsigned __int64)NewThread->Teb;
    if ( NewThread->Header.Minimal )
      UserGsBase = NewEthread->UserGsBase;
    __writemsr(0xC0000102, UserGsBase); // IA32_KERNEL_GS_BASE
  }

  if ( (CurrentPrcb->DpcRequestSummary & 0x10001) != 0 ) // normal/threaded DPC active
    KeBugCheckEx(0xB8, (ULONG_PTR)OldThread, (ULONG_PTR)NewThread, 0, 0);

  ++NewThread->ContextSwitches;

  if ( NewThread->ApcState.KernelApcPending != 1 )
    return 0;

  /*
   * Modern assembly loads 16 bits here. The low byte is the ApcBypass
   * value saved when NewThread last switched out.
   */
  __asm { movzx NewApcBypassWord, word ptr [rsp+28h] }
  if ( (NewApcBypassWord | (unsigned __int16)NewThread->SpecialApcDisable) == 0 )
  {
    /* Return 1 so the caller, normally KiSwapContext, delivers the APC */
    return 1;
  }

  /* APC delivery is disabled here, so request an APC level interrupt */
  HalRequestSoftwareInterrupt(1); // APC_LEVEL
  return 0;
}
