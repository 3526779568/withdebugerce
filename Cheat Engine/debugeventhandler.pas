unit debugeventhandler;

//handles the debug events

{$MODE Delphi}

interface

uses
  jwawindows, Windows, Classes, SysUtils, syncobjs, GuiSafeCriticalSection,
  disassembler, cefuncproc, newkernelhandler,debuggertypedefinitions, frmTracerUnit,
  DebuggerInterfaceAPIWrapper, LuaHandler, lua, lauxlib, lualib, win32proc, tracerIgnore;

type
  TDebugEventHandler = class;

  TDebugThreadHandler = class
  private
    debuggerthread: TObject;
    debuggerCS: TGuiSafeCriticalSection;

    onAttachEvent: TEvent;
    onContinueEvent: TEvent;
    realcontextpointer: pointer;
    threadlist: TList;
    breakpointList: TList;
    continueOption: TContinueOption;

    setInt3Back: boolean;
    Int3setbackAddress: ptrUint;
    Int3SetBackBP: PBreakpoint;


    expectedUndefinedBreakpoint: ptruint; //ARM: When a breakpoint happens with this address handle it instead of ignoring it
    setInt1Back: boolean;
    Int1SetBackBP: PBreakpoint;

    singlestepping: boolean;

    //break and trace:
    isTracing: boolean;
    tracecount: integer;
    traceWindow: TfrmTracer;
    traceQuitCondition: string;
    traceStepOver: boolean; //perhaps also trace branches ?
    traceNoSystem: boolean;
    //------------------

    WaitingToContinue: boolean; //set to true when it's waiting for the user to continue

    DebugEventString: string; //for outputdebugstring event
    secondcreateprocessdebugevent: boolean;

    temporaryDisabledExceptionBreakpoints: Tlist;
    breakAddress: ptruint;


    currentBP: PBreakpoint;

    function CheckIfConditionIsMet(bp: PBreakpoint; script: string=''): boolean;
    function InNoBreakList: boolean;

    function HandleAccessViolationDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
    function HandleExceptionDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
    //even though it's private, it's accessible from this unit
    function CreateThreadDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
    function CreateProcessDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
    function ExitThreadDebugEvent(debugevent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
    function ExitProcessDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
    function LoadDLLDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
    function UnloadDLLDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
    function OutputDebugStringEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
    function RipEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
    function HandleUnknownEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;

    function DispatchBreakpoint(address: uint_ptr; debugreg: integer; var dwContinueStatus: dword): boolean;
    function singleStep(var dwContinueStatus: dword): boolean;

    procedure ModifyRegisters(bp: PBreakpoint);
    procedure TraceWindowAddRecord;
    procedure handleTrace;
    procedure HandleBreak(bp: PBreakpoint);
    procedure ContinueFromBreakpoint(bp: PBreakpoint; continueoption: TContinueOption);
    function EnableOriginalBreakpointAfterThisBreakpointForThisThread(bp: Pbreakpoint; OriginalBreakpoint: PBreakpoint): boolean;

    //sync functions
    procedure visualizeBreak;
    procedure AddDebugEventString;
    procedure foundCodeDialog_AddRecord;
    procedure frmchangedaddresses_AddRecord;
  public
    isHandled: boolean; //set to true if this thread is the current debug target
    needstocleanup: boolean;
    ProcessId: dword;
    ThreadId:  dword;
    handle: THandle;

    DebugRegistersUsedByCE: byte; //mask containing the bits for each DR used
    context: PContext;  //PContext but it does belong to this thread. It's due to alignment issues
    armcontext: TArmContext;



    procedure UpdateMemoryBrowserContext;

    procedure TracerQuit;
    procedure suspend;
    procedure resume;
    procedure fillContext;
    procedure setContext;
    procedure breakThread;
    procedure clearDebugRegisters;
    procedure continueDebugging(continueOption: TContinueOption);
    constructor Create(debuggerthread: TObject; attachEvent: Tevent; continueEvent: Tevent; breakpointlist: TList; threadlist: Tlist; debuggerCS: TGuiSafeCriticalSection);
    destructor destroy; override;

    property isSingleStepping: boolean read singlestepping;
    property isWaitingToContinue: boolean read WaitingToContinue;
  end;

  TDebugEventHandler = class
  private
    debuggerthread: TObject;
    debuggerCS: TGuiSafeCriticalSection;
    fOnAttachEvent: TEvent;
    fOnContinueEvent: TEvent;
    breakpointlist: TList;
    threadlist: TList;

    currentdebugEvent: TDEBUGEVENT;
    procedure updatethreadlist;
    procedure UpdateDebugEventWindow;
  public
    function HandleDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
    constructor Create(debuggerthread: TObject; OnAttachEvent: TEvent; OnContinueEvent: Tevent; breakpointlist: TList; threadlist: Tlist; debuggercs: TGuiSafeCriticalSection);
  end;

implementation

uses foundcodeunit, DebugHelper, MemoryBrowserFormUnit, frmThreadlistunit,
     WindowsDebugger, VEHDebugger, KernelDebuggerInterface, NetworkDebuggerInterface,
     frmDebugEventsUnit, formdebugstringsunit, symbolhandler,
     networkInterface, networkInterfaceApi, ProcessHandlerUnit;

resourcestring
  rsDebugHandleAccessViolationDebugEventNow = 'Debug HandleAccessViolationDebugEvent now';
  rsSpecialCase = 'Special case';

procedure TDebugThreadHandler.frmchangedaddresses_AddRecord;
begin
  TDebuggerthread(debuggerthread).execlocation:=44;

  if (((currentbp.breakpointMethod=bpmException) and not currentbp.markedfordeletion) or currentBP.active) and (currentBP.frmchangedaddresses<>nil) then
    currentbp.frmchangedaddresses.AddRecord;
end;

procedure TDebugThreadHandler.foundCodeDialog_AddRecord;
begin
  TDebuggerthread(debuggerthread).execlocation:=43;

  if (((currentbp.breakpointMethod=bpmException) and not currentbp.markedfordeletion) or currentBP.active) and (currentbp.FoundcodeDialog<>nil) then  //it could have been deactivated
  begin
    TDebuggerthread(debuggerthread).execlocation:=431;
    currentBP.FoundcodeDialog.usesdebugregs:=currentBP.breakpointMethod=bpmDebugRegister;
    currentBP.FoundcodeDialog.useexceptions:=currentBP.breakpointMethod=bpmException;

    TDebuggerthread(debuggerthread).execlocation:=432;
    currentBP.FoundcodeDialog.AddRecord;

    TDebuggerthread(debuggerthread).execlocation:=433;
  end
  else if (currentbp.breakpointMethod = bpInfBp) and (currentbp.FoundcodeDialog<>nil) then
  begin
    TDebuggerthread(debuggerthread).execlocation:=431;
    currentBP.FoundcodeDialog.usesdebugregs:=currentBP.breakpointMethod=bpmDebugRegister;
    currentBP.FoundcodeDialog.useexceptions:=currentBP.breakpointMethod=bpmException;

    TDebuggerthread(debuggerthread).execlocation:=432;
    currentBP.FoundcodeDialog.AddRecord;

    TDebuggerthread(debuggerthread).execlocation:=433;
  end
  else
  begin
   // beep;
  end;

  TDebuggerthread(debuggerthread).execlocation:=439;
end;

procedure TDebugThreadHandler.AddDebugEventString;
begin
  TDebuggerthread(debuggerthread).execlocation:=42;

  if formdebugstrings<>nil then
  begin
    formdebugstrings.ListBox1.Items.add(DebugEventString);
    if formdebugstrings.ListBox1.count>10000 then
      formdebugstrings.ListBox1.Items.Delete(0);
  end;
end;

procedure TDebugThreadHandler.UpdateMemoryBrowserContext;
begin
  if processhandler.SystemArchitecture=archx86 then
    MemoryBrowser.lastdebugcontext:=context^
  else
    MemoryBrowser.lastdebugcontextarm:=armcontext;
end;

procedure TDebugThreadHandler.VisualizeBreak;
begin
  TDebuggerthread(debuggerthread).execlocation:=41;
  UpdateMemoryBrowserContext;

  TDebuggerthread(debuggerthread).execlocation:=411;

  if (currentbp<>nil) and (assigned(currentbp.OnBreakpoint)) then
    WaitingToContinue:=currentbp.OnBreakpoint(currentbp, context)
  else
    WaitingToContinue:=not lua_onBreakpoint(context);

  TDebuggerthread(debuggerthread).execlocation:=412;


  if WaitingToContinue then //no lua script or it returned 0
  begin
    TDebuggerthread(debuggerthread).execlocation:=413;
    MemoryBrowser.UpdateDebugContext(self.Handle, self.ThreadId);
  end;
  TDebuggerthread(debuggerthread).execlocation:=414;

end;

procedure TDebugThreadHandler.fillContext;
var
  i: integer;
  c: pointer;
begin

  if handle<>0 then
  begin
    debuggercs.enter;

    if processhandler.SystemArchitecture=archArm then
    begin
      GetThreadContextArm(handle, armcontext, ishandled);
    end
    else
    begin
      context.ContextFlags := CONTEXT_ALL or CONTEXT_EXTENDED_REGISTERS;
      if not getthreadcontext(handle, context^,  isHandled) then
      begin
        i := getlasterror;
        //outputdebugstring(PChar('getthreadcontext error:' + IntToStr(getlasterror)));
      end;
    end;

    debuggercs.leave;
  end else i := getlasterror;//outputdebugstring('fillContext: handle=0');


end;

procedure TDebugThreadHandler.setContext;
var
  i: integer;
begin

  if handle<>0 then
  begin
    debuggercs.enter;
    context:=self.context;
    outputdebugstring(pchar(format('setThreadContext(%x, %x, %x). dr0=%x dr1=%x dr2=%x dr3=%x dr6=%x dr7=%x',[threadid, handle,context.EFlags, context.dr0, context.dr1, context.dr2, context.dr3,context.Dr6, context.dr7])));
    context.ContextFlags := CONTEXT_ALL or CONTEXT_EXTENDED_REGISTERS;

    //context.dr7:=context.dr7 or $300;

    if not setthreadcontext(self.handle, context^, isHandled) then
    begin
      i := getlasterror;
      outputdebugstring(PChar('setthreadcontext error:' + IntToStr(getlasterror)));
    end;
    debuggercs.leave;
  end else i := getlasterror;//outputdebugstring('fillContext: handle=0');
end;

procedure TDebugThreadHandler.suspend;
begin
  if handle<>0 then
    suspendthread(handle);
end;

procedure TDebugThreadHandler.resume;
begin
  if handle<>0 then
    resumethread(handle);
end;

procedure TDebugThreadHandler.breakThread;
begin
  debuggercs.enter;
  suspend;

  fillContext;
  context.eflags:=eflags_setTF(context.eflags,1);
  SingleStepping:=true;

  setContext;
  resume;
  debuggercs.leave;
end;

procedure TDebugThreadHandler.clearDebugRegisters;
begin
  debuggerCS.enter;
  suspend;
  fillContext;
  context.dr0:=0;
  context.dr1:=0;
  context.dr2:=0;
  context.dr3:=0;
  context.dr6:=0;
  context.dr7:=0;
  SingleStepping:=true;
  setContext;
  resume;
  debuggercs.leave;
end;

function booltoint(b: boolean):integer; inline;
begin
  if b then result:=1 else result:=0;
end;

procedure TDebugThreadHandler.ModifyRegisters(bp: PBreakpoint);
begin
  TDebuggerthread(debuggerthread).execlocation:=36;
  if bp.changereg.change_af then context.EFlags:=eflags_setAF(context.Eflags, booltoint(bp.changereg.new_af));
  if bp.changereg.change_cf then context.EFlags:=eflags_setCF(context.Eflags, booltoint(bp.changereg.new_cf));
  if bp.changereg.change_of then context.EFlags:=eflags_setOF(context.Eflags, booltoint(bp.changereg.new_of));
  if bp.changereg.change_pf then context.EFlags:=eflags_setPF(context.Eflags, booltoint(bp.changereg.new_pf));
  if bp.changereg.change_sf then context.EFlags:=eflags_setSF(context.Eflags, booltoint(bp.changereg.new_sf));
  if bp.changereg.change_zf then context.EFlags:=eflags_setZF(context.Eflags, booltoint(bp.changereg.new_zf));

  if bp.changereg.change_eax then context.{$ifdef cpu64}rax{$else}eax{$endif}:=bp.changereg.new_eax;
  if bp.changereg.change_ebx then context.{$ifdef cpu64}rbx{$else}ebx{$endif}:=bp.changereg.new_ebx;
  if bp.changereg.change_ecx then context.{$ifdef cpu64}rcx{$else}ecx{$endif}:=bp.changereg.new_ecx;
  if bp.changereg.change_edx then context.{$ifdef cpu64}rdx{$else}edx{$endif}:=bp.changereg.new_edx;
  if bp.changereg.change_esi then context.{$ifdef cpu64}rsi{$else}esi{$endif}:=bp.changereg.new_esi;
  if bp.changereg.change_edi then context.{$ifdef cpu64}rdi{$else}edi{$endif}:=bp.changereg.new_edi;
  if bp.changereg.change_esp then context.{$ifdef cpu64}rsp{$else}esp{$endif}:=bp.changereg.new_esp;
  if bp.changereg.change_eip then context.{$ifdef cpu64}rip{$else}eip{$endif}:=bp.changereg.new_eip;

  {$ifdef cpu64}
  if bp.changereg.change_r8 then context.r8:=bp.changereg.new_r8;
  if bp.changereg.change_r9 then context.r9:=bp.changereg.new_r9;
  if bp.changereg.change_r10 then context.r10:=bp.changereg.new_r10;
  if bp.changereg.change_r11 then context.r11:=bp.changereg.new_r11;
  if bp.changereg.change_r12 then context.r12:=bp.changereg.new_r12;
  if bp.changereg.change_r13 then context.r13:=bp.changereg.new_r13;
  if bp.changereg.change_r14 then context.r14:=bp.changereg.new_r14;
  if bp.changereg.change_r15 then context.r15:=bp.changereg.new_r15;
  {$endif}
end;

procedure TDebugThreadHandler.continueDebugging(continueOption: TContinueOption);
begin
  if WaitingToContinue then
  begin
    self.continueOption:=continueOption;
    onContinueEvent.SetEvent;
  end;

end;

function TDebugThreadHandler.EnableOriginalBreakpointAfterThisBreakpointForThisThread(bp: Pbreakpoint; OriginalBreakpoint: PBreakpoint): boolean;
begin
  result:=true;
  TDebuggerthread(debuggerthread).execlocation:=40;
  debuggercs.enter;
  if bp.active then
  begin
    dec(OriginalBreakpoint.referencecount);
    result:=TdebuggerThread(debuggerthread).SetBreakpoint(Originalbreakpoint, self);
  end;
  debuggercs.leave;
end;

procedure TDebugThreadHandler.ContinueFromBreakpoint(bp: PBreakpoint; continueoption: TContinueOption);
{
Continues the current thread from a debug event. Handles int3 breakpoints as well
BP can be nil if it's a single step breakpoint
这个函数是从断点根据continue类型 F7  F8 F9和断点类型继续判断继续执行的规则
}
var oldprotect: dword;
  bw: PtrUInt;
  d: TDisassembler=nil;
  nexteip: ptruint;
  t: string;

  b: PBreakpoint=nil;

  pc: ptruint;
  c: TCEConnection;

begin
  TDebuggerthread(debuggerthread).execlocation:=39;
  debuggercs.enter;
  context.EFlags:=eflags_setTF(context.EFlags,0);     //默认TF设置为0

  try
    if (bp<>nil) then
    begin


      if (bp.breakpointMethod=bpmInt3) then    //如果是INT3断点，恢复字节码，并设置TF为1
      begin
        //bp is set and it's an int3 breakpoint
        VirtualProtectEx(Processhandle, pointer(bp.address), 1, PAGE_EXECUTE_READWRITE, oldprotect);
        WriteProcessMemory(processhandle, pointer(bp.address), @bp.originalbyte, 1, bw);
        VirtualProtectEx(Processhandle, pointer(bp.address), 1, oldprotect, oldprotect);

        if (not bp.markedfordeletion) and (not bp.OneTimeOnly) then //if it's not a one time only breakpoint then set it back on next instruction
        begin
          context.EFlags:=eflags_setTF(context.EFlags,1); //set the trap flag so it'll break on next instruction
          setInt3Back:=true;
          Int3setbackAddress:=bp.address;
          Int3setBackbp:=bp;

        end;
      end
      else
      begin

        if (CurrentDebuggerInterface is TNetworkDebuggerInterface) and (processhandler.SystemArchitecture=archarm) then
        begin
          //if it is a network breakpoint delete it first. Not needed for x86 but arm can't continue if the breakpoint doesn't get removed (at least my transformer tablet does)
          //it's like windows XP where the RF flag is borked, and the added fun that is also affects read/write watchpoints and arm doesn't do single stepping


          TdebuggerThread(debuggerthread).UnsetBreakpoint(bp, nil, ThreadId); //remove the breakpoint just for this thread


          TNetworkDebuggerInterface(CurrentDebuggerInterface).SingleStepNextContinue:=true; //if possible. Not all builds support it and it's bad...

          //add a non persistent breakpoint using the last available debug register

          {
          //perhaps try to predict PC based on the instruction itself (e.g loading of R15 or a B/BL)
          d:=TDisassembler.create;
          pc:=armcontext.PC;
          d.disassemble(pc, t);
          }
             {
          pc:=armcontext.PC+4;


          c:=getConnection;

          if c.SetBreakpoint(processhandle, ThreadId, CurrentDebuggerInterface.maxInstructionBreakpointCount-1, pc,0, 1) then
            expectedUndefinedBreakpoint:=pc;
            }

          setInt1Back:=true;
          Int1SetBackBP:=bp;


        //  d.free;

         {
          if (bp.OneTimeOnly=false) and (bp.breakpointAction<>bo_OnBreakpoint) then
          begin

            //add a one time breakpoint for this thread on the next instruction that when executed, reenables the current breakpoint
            b:=TdebuggerThread(debuggerthread).SetOnExecuteBreakpoint(armcontext.PC+8, false, ThreadID);


            inc(bp.referencecount); //prevent it from getting deleted

            b.breakpointAction:=bo_OnBreakpoint;
            b.OnBreakpointContext:=bp;
            b.OnBreakpoint:=EnableOriginalBreakpointAfterThisBreakpointForThisThread; //hopefully this name is descriptive enough...
          end;   }

          exit;
        end;


{$ifdef cpu32}
        //----XP HACK----
        if (WindowsVersion=wvXP) then
        begin
          if not (CurrentDebuggerInterface is TKernelDebugInterface) then
          begin

            if (bp.breakpointTrigger=bptExecute) and (not bp.markedfordeletion) then //if windows xp, and it is a hw bp, and it's an execute hw bp, and it's not marked for deletion, only THEN set the bp back
            begin
              context.Dr6:=0;  //unset breakpoint relies on this being 0 of ffff0ff0
              setContext; //apply changes made by the user
              TdebuggerThread(debuggerthread).UnsetBreakpoint(bp);

              setInt1Back:=true;
              context.EFlags:=eflags_setTF(context.EFlags,1); //set the trap flag so it'll break on next instruction
              Int1SetBackBP:=bp;
            end;
          end;
        end;
{$endif}
      end;



      if (not singlestepping) and ((bp.ThreadID<>0) and (bp.threadid<>self.ThreadId)) then
      begin
        //not singlestepping and this breakpoint isn't set to break for this thread, so:

        context.EFlags:=eflags_setRF(context.EFlags,1);//don't break on the current instruction

        exit; //and exit
      end;
    end;


    case continueoption of
      co_run, co_runtill:
      begin
        //just continue
        singlestepping:=false;


        if (bp=nil) or (bp.breakpointMethod=bpmDebugRegister) then
        begin
          //it's a debug register breakpoint or single step, we can continue by just setting the RF flag so it won't break on next execution
          context.EFlags:=eflags_setRF(context.EFlags,1);
        end

      end;



      co_stepinto, co_stepover:
      begin
        //single step
        singlestepping:=true;         //正在单步调试中
        if (bp=nil) or (bp.breakpointMethod=bpmDebugRegister) then
          context.EFlags:=eflags_setRF(context.EFlags,1);//don't break on the current instruction

        if continueoption=co_stepinto then
          context.EFlags:=eflags_setTF(context.EFlags,1) //set the trap flag
        else
        begin
          //check if the current instruction is a call, if not, single step, else set a "run till" breakpoint (that doesn't cancel the stepping)
          d:=TDisassembler.Create;
          nexteip:=context.{$ifdef cpu64}rip{$else}eip{$endif};
          d.disassemble(nexteip, t);
          if d.LastDisassembleData.iscall then
          begin
            //set an execute breakpoint for this thread only at the next instruction and run till there
            b:=TDebuggerthread(debuggerthread).SetOnExecuteBreakpoint(nexteip , false, ThreadId);
            b.OneTimeOnly:=true;
          end
          else  //if not, single step
            context.EFlags:=eflags_setTF(context.EFlags,1);


        end;
      end;

      //the other event types are just setting of one time breakpoints

    end;
  finally
    {$ifdef cpu32}
    if not (CurrentDebuggerInterface is TKernelDebugInterface) then
    begin
      if setInt1Back then
      begin
        eflags_setTF(context.Eflags,1);
        eflags_setRF(context.Eflags,0);
      end;
    end;
    {$endif}

    if (bp<>nil) and (not bp.active) then
    begin
      //disable the breakpoint in the current context (in case it got disabled while the breakpoint was being handled)
      if bp.breakpointMethod=bpmDebugRegister then
      begin
        //context.Dr6:=0;  //unset breakpoint relies on this being 0 of ffff0ff0 is handled
        setContext;
        TdebuggerThread(debuggerthread).UnsetBreakpoint(bp, context, threadid);
      end;
    end;

    debuggercs.leave;
  end;
end;




procedure TDebugThreadHandler.TracerQuit;
begin
  tracewindow:=nil;

  if isTracing then
  begin
    fillContext;
    context^.EFlags:=eflags_setTF(context^.EFlags,0); //unsef TF
    setContext;
  end;

  TDebuggerthread(debuggerthread).execlocation:=45;
end;

procedure TDebugThreadHandler.TraceWindowAddRecord;
begin
  if traceWindow<>nil then
    tracewindow.addRecord;
end;

procedure TDebugThreadHandler.handleTrace;
var
  b: PBreakpoint;
  r: ptruint;
  x: PtrUInt;

  ignored: boolean;
begin
  if tracewindow=nil then
  begin
    isTracing:=false;
    ContinueFromBreakpoint(nil, co_run);
    exit;
  end;

  ignored:=false;

  TDebuggerthread(debuggerthread).execlocation:=37;

  if IgnoredModuleListHandler<>nil then
    ignored:=IgnoredModuleListHandler.InIgnoredModuleRange(context.{$ifdef cpu64}rip{$else}eip{$endif});

  if (not ignored) and traceNoSystem and symhandler.inSystemModule(context.{$ifdef cpu64}rip{$else}eip{$endif}) then
    ignored:=true;

  TDebuggerthread(debuggerthread).execlocation:=371;
  if (tracewindow<>nil) and (not ignored) then
  begin
    TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), TraceWindowAddRecord);
    TDebuggerthread(debuggerthread).guiupdate:=true;
  end;

  TDebuggerthread(debuggerthread).execlocation:=372;

  dec(tracecount);
  if tracecount>0 then
  begin
    if traceQuitCondition<>'' then
    begin
      if CheckIfConditionIsMet(nil, 'return '+traceQuitCondition) then
      begin
        TDebuggerthread(debuggerthread).execlocation:=373;
        //quit condition is met
        if tracewindow<>nil then
          TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), tracewindow.Finish);

        OutputDebugString('CheckIfConditionIsMet=true');
        ContinueFromBreakpoint(nil, co_run);
        isTracing:=false;

        exit;
      end;
    end;

    TDebuggerthread(debuggerthread).execlocation:=374;

    if ignored then
    begin
      TDebuggerthread(debuggerthread).execlocation:=375;
      tracewindow.returnfromignore:=true;
      ReadProcessMemory(processhandle, pointer(context.{$ifdef cpu64}rsp{$else}esp{$endif}), @r, sizeof(processhandler.pointersize), x);
      b:=TDebuggerthread(debuggerthread).SetOnExecuteBreakpoint(r , false, ThreadId);
      b.OneTimeOnly:=true;
      TDebuggerthread(debuggerthread).execlocation:=376;
      ContinueFromBreakpoint(nil, co_run);
    end
    else
    begin
      TDebuggerthread(debuggerthread).execlocation:=377;
      if tracestepover then
        ContinueFromBreakpoint(nil, co_stepover)
      else
        ContinueFromBreakpoint(nil, co_stepinto);
    end;
  end
  else
  begin
    TDebuggerthread(debuggerthread).execlocation:=378;
    //outputdebugstring('tracecount=0');
    if tracewindow<>nil then
    begin
      TDebuggerthread(debuggerthread).execlocation:=379;
      TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), tracewindow.Finish);
    end;

    TDebuggerthread(debuggerthread).execlocation:=380;

    ContinueFromBreakpoint(nil, co_run);
    isTracing:=false;
  end;
end;

procedure TDebugThreadHandler.HandleBreak(bp: PBreakpoint);
begin
  TDebuggerthread(debuggerthread).execlocation:=38;
  WaitingToContinue:=true;


  Outputdebugstring('HandleBreak()');
  //go to sleep and wait for an event that wakes it up. No need to worry about deleted breakpoints, since the cleanup will not be called untill this routine exits
  onContinueEvent.ResetEvent;


  TDebuggerthread(debuggerthread).synchronize(TDebuggerthread(debuggerthread), VisualizeBreak);

  if WaitingToContinue then
  begin
    //Outputdebugstring('updated gui');
    onContinueEvent.WaitFor(infinite);
    //Outputdebugstring('returned from gui');
  end;

  WaitingToContinue:=false;
  continueFromBreakpoint(bp, continueOption);
end;

function TDebugThreadHandler.singleStep(var dwContinueStatus: dword): boolean;
var
  {$ifdef cpu32}
  hasSetInt1Back: boolean;
  {$endif}
  hasSetInt3Back: boolean;
  oldprotect: dword;
  bw: PtrUInt;
begin
  TDebuggerthread(debuggerthread).execlocation:=35;
  OutputDebugString('Handling as a single step event');
  result:=true;


  {$ifdef cpu32}
  if not (CurrentDebuggerInterface is TKernelDebugInterface) then
  begin
    if setint1back then
    begin
      //set the breakpoint back
      TdebuggerThread(debuggerthread).SetBreakpoint(Int1SetBackBP);
      setInt1Back:=false;
      hasSetInt1Back:=true;
      dwContinueStatus:=DBG_CONTINUE;
    end
    else
      hasSetInt1Back:=false;
  end;

  {$endif}


  if setInt3Back then
  begin
    if Int3setBackbp.markedfordeletion=false then
    begin
      VirtualProtectEx(Processhandle, pointer(Int3setbackAddress), 1, PAGE_EXECUTE_READWRITE, oldprotect);
      WriteProcessMemory(processhandle, pointer(Int3setbackAddress), @int3byte, 1, bw);
      VirtualProtectEx(Processhandle, pointer(Int3setbackAddress), 1, oldprotect, oldprotect);
    end;

    setInt3Back:=false;
    hasSetInt3Back:=true;
    dwContinueStatus:=DBG_CONTINUE;
  end else hasSetInt3Back:=false;

  if isTracing then
  begin
    handleTrace;
  end
  else
  if singlestepping then
  begin
    handlebreak(nil);
  end
  else
  begin
    if (not (hasSetInt3Back {$ifdef cpu32} or hasSetInt1Back{$endif})) then
    begin
      OutputDebugString('Not handled');
      dwContinuestatus:=DBG_EXCEPTION_NOT_HANDLED; //if it wasn't a int3 set back or not expected single step, then raise an error
    end;
  end;
end;

function TDebugThreadHandler.InNoBreakList: boolean;
begin
  result:=CurrentDebuggerInterface.InNoBreakList(threadid);
end;

function TDebugThreadHandler.CheckIfConditionIsMet(bp: PBreakpoint; script: string=''): boolean;
var
  i:integer;
begin
  TDebuggerthread(debuggerthread).execlocation:=14;



  result:=true;
  if (script<>'') or (bp<>nil) then
  begin
    if (script<>'') or (bp.conditonalbreakpoint.script<>nil) then
    begin
      if script='' then
      begin
        script:=bp.conditonalbreakpoint.script;
        if bp.conditonalbreakpoint.easymode then script:='return ('+script+')';
      end;


      result:=CheckIfConditionIsMetContext(context, script);
    end;
  end;
end;

function TDebugThreadHandler.DispatchBreakpoint(address: uint_ptr; debugreg: integer; var dwContinueStatus: dword): boolean;
var
  found:  boolean;
  i:      integer;

  c: PContext;

  bpp,bpp2: PBreakpoint;

  active: boolean;
  oldprotect: dword;
  bw: PtrUInt;

  connection: TCEConnection;
begin
  TDebuggerthread(debuggerthread).execlocation:=26;
  //outputdebugstring(format('DispatchBreakpoint(%x)',[address]));
  found := False;

  //check if it's an expected breakpoint
  //if not, DBG_EXCEPTION_NOT_HANDLED

  bpp2:=nil;

  debuggercs.enter;

  for i := 0 to breakpointlist.Count - 1 do      //判断断点是否存在
  begin
    bpp:=PBreakpoint(breakpointlist.Items[i]);

    if InRangeX(address, bpp.address, bpp.address+bpp.size-1) then
    begin
      if (CurrentDebuggerInterface.canReportExactDebugRegisterTrigger) and (debugreg in [0..4]) and (bpp.breakpointMethod=bpmDebugRegister) and (bpp.debugRegister<>debugreg) then
        continue; //this is not the correct breakpoint. Skip it


      found:=true;
      bpp2:=bpp;
      active:=bpp^.active;

      if bpp^.OneTimeOnly then //delete it
        TdebuggerThread(debuggerthread).RemoveBreakpoint(bpp);

      if ((bpp.breakpointMethod=bpmException) and (not bpp.markedfordeletion)) or active then
        break;

      //else continue looking for one that IS active and not deleted
    end;
  end;

  debuggercs.leave;

  TDebuggerthread(debuggerthread).execlocation:=27;


  if found then
  begin
    currentBP:=bpp;


    bpp:=bpp2;
    outputdebugstring('Handling breakpoint');

    //to handle a debug register being handled before the single step (since xp sucks and doesn't do rf)
    if setInt3Back then //on a failt this will set the state to as it was expected, on a trap this will set the breakpoint back. Both valid
    begin //在代码段设置int3 单步执行的时候设置了TF位
      VirtualProtectEx(Processhandle, pointer(Int3setbackAddress), 1, PAGE_EXECUTE_READWRITE, oldprotect);
      WriteProcessMemory(processhandle, pointer(Int3setbackAddress), @int3byte, 1, bw);
      VirtualProtectEx(Processhandle, pointer(Int3setbackAddress), 1, oldprotect, oldprotect);

      setInt3Back:=false;
    end;


    if isTracing then                    //跟踪
    begin
      handleTrace;
      dwContinueStatus:=DBG_CONTINUE;
      Result:=true;
      exit;
    end;



    //不在断点列表，且下段模式不是Exception,再次关闭这个断点
    //不在断点列表 或者 (非一次性断点 且 (BP不等于异常且非激活态  或者  条件不符或者等待删除))
    if  preferedBreakpointMethod <> bpInfBp then
    begin
            if (InNoBreakList) or ((bpp.OneTimeOnly=false) and (((bpp.breakpointMethod<>bpmException) and (not active)) or (not CheckIfConditionIsMet(bpp) or (bpp.markedfordeletion) ))) then
            begin
              TDebuggerthread(debuggerthread).execlocation:=28;
              OutputDebugString('bp was disabled or Condition was not met');
              debuggercs.enter;

              if bpp.markedfordeletion then
              begin
                bpp.deletecountdown:=10; //reset
                bpp.active:=false; //this should NEVER be needed, but just to be sure...
              end;

              if bpp.active=false then
              begin
                TdebuggerThread(debuggerthread).UnsetBreakpoint(bpp, context);  //make sure it's disabled
                setcontext;
              end;

              needstocleanup:=true;

              continueFromBreakpoint(bpp, co_run);
              dwContinueStatus:=DBG_CONTINUE;
              Result:=true;

              debuggercs.leave;
              exit;
            end;
    end;



    case bpp.breakpointAction of      //调试器捕获后的行为
      bo_Break:                        //内存视图中断
      begin
        TDebuggerthread(debuggerthread).execlocation:=29;
        //check if there is a step over breakpoint and remove it
        //只有不是无痕断点的时候才执行下面的代码
        if preferedBreakpointMethod <> bpInfBp then
        begin
          debuggercs.enter;
          for i:=0 to breakpointlist.count-1 do
          begin
            bpp2:=PBreakpoint(breakpointlist.Items[i]);
            if (((bpp2.breakpointMethod=bpmException) and not bpp2.markedfordeletion) or bpp2.active) and (bpp2.StepOverBp) and (bpp2.markedfordeletion=false) then
              TdebuggerThread(debuggerthread).RemoveBreakpoint(bpp2);
          end;

          debuggercs.leave;
        end;


        HandleBreak(bpp); //cause break in memory browser at address
      end;

      bo_BreakAndTrace:
      begin
        TDebuggerthread(debuggerthread).execlocation:=30;

        //remove the breakpoint and start tracing this thread X times
        if not isTracing then //don't handle it if already tracing
        begin
          debuggercs.enter;

          if bpp.active then
          begin
            isTracing:=true;
            tracecount:=bpp.TraceCount;
            traceWindow:=bpp.frmTracer;
            traceStepOver:=bpp.tracestepOver;
            traceNoSystem:=bpp.traceNoSystem;
            if bpp.traceendcondition<>nil then
              traceQuitCondition:=bpp.traceendcondition
            else
              traceQuitCondition:='';
          end;

          debuggercs.leave;
        end;

        TdebuggerThread(debuggerthread).RemoveBreakpoint(bpp); //there can be only one

        if istracing then
          handleTrace;
      end;


      bo_ChangeRegister:
      begin
        TDebuggerthread(debuggerthread).execlocation:=31;
        //modify accordingly
        //outputdebugstring('Handling bo_ChangeRegister breakpoint');

        ModifyRegisters(bpp);

        //and
        continueFromBreakpoint(bpp, co_run); //just continue running
      end;

      bo_FindCode:
      begin
        TDebuggerthread(debuggerthread).execlocation:=32;
        //outputdebugstring('Save registers and continue');

        if ((bpp.breakpointMethod=bpmException) and (not bpp.markedfordeletion)) or bpp.active then   //普通断点
        begin
          TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), foundCodeDialog_AddRecord);
          TDebuggerthread(debuggerthread).guiupdate:=true;

          if CurrentDebuggerInterface is TNetworkDebuggerInterface then
            continueFromBreakpoint(bpp, co_run);  //explicitly continue from this breakpoint
        end
        else if (bpp.breakpointMethod = bpInfBp) and bpp.active then //如果是无痕硬断
        begin
           TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), foundCodeDialog_AddRecord);
           TDebuggerthread(debuggerthread).guiupdate:=true;
        end;

        //nothing special is needed to continue
      end;

      bo_FindWhatCodeAccesses:
      begin
        TDebuggerthread(debuggerthread).execlocation:=33;
        TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), frmchangedaddresses_AddRecord);
        TDebuggerthread(debuggerthread).guiupdate:=true;

        continueFromBreakpoint(bpp, co_run); //just continue running
      end;


    end;

    dwContinueStatus:=DBG_CONTINUE;
  end
  else  //未找到调试器的断点
  begin
    TDebuggerthread(debuggerthread).execlocation:=34;
    if (setint1back) and (address<>0) then
    begin
      connection:=getConnection;
      if connection<>nil then
      begin
        TdebuggerThread(debuggerthread).setBreakpoint(Int1SetBackBP, self);

        setint1back:=false;
        dwContinueStatus:=DBG_CONTINUE;
        result:=true;
        exit;
      end;
    end;


    OutputDebugString('Unexpected breakpoint');
    if not (CurrentDebuggerInterface is TKernelDebugInterface) then
    begin
      onAttachEvent.SetEvent;

      if TDebuggerthread(debuggerthread).InitialBreakpointTriggered then
        dwContinueStatus:=DBG_EXCEPTION_NOT_HANDLED
      else
      begin
        dwContinueStatus:=DBG_EXCEPTION_NOT_HANDLED;
        TDebuggerthread(debuggerthread).InitialBreakpointTriggered:=true;  //附加系统断点

        result:=false;
        exit;
      end;


    end
    else dwContinueStatus:=DBG_EXCEPTION_NOT_HANDLED; //not an expected breakpoint
  end;


  if dwContinueStatus=DBG_EXCEPTION_NOT_HANDLED then
  asm
    nop
  end;

  Result := True;
end;

function TDebugThreadHandler.HandleAccessViolationDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
var address: ptruint;

  bp: PBreakpoint;
  i: integer;
begin
  TDebuggerthread(debuggerthread).execlocation:=15;
  //check if the address that triggered it is in one of the active exception breakpoints and if so make the protection what it should be

  //thing to note:
  //if 0x2000 and 0x3000 are set to readonly, and 0x2fff is written to using a 4 byte write  accesses, then first unrptorect 0x2000 and execute.
  //that will cause the next exception at 0x3000 to trigger

  //solution: Disable ALL protections arround the given address

  //p2:
  //t1 writes address1
  //t1 gets an exception
  //t1 goes in the exception handler, makes it writable and continues with a single step
  //t2 runs and writes to the address
  //t1 runs and triggers the single step bp
  //s: freeze ALL other threads


  //s2:
  //freeze t2 and set it to continue normally, after t1 has been handled, resume t2, causing it to retrigger

  result:=true;
  dwContinueStatus:=DBG_EXCEPTION_NOT_HANDLED;

  if debugevent.Exception.ExceptionRecord.NumberParameters>=2 then
  begin
    //get the address
    address:=debugevent.Exception.ExceptionRecord.ExceptionInformation[1];

    //check if this thread was waiting for an int1 but got a pagefault instead
    if temporaryDisabledExceptionBreakpoints<>nil then
    begin
      //pagefault while waiting for single step
      {$ifdef DEBUG}
      Messagebox(0,rsDebugHandleAccessViolationDebugEventNow,rsSpecialCase,0);
      {$endif}
      for i:=0 to temporaryDisabledExceptionBreakpoints.Count-1 do
      begin

        bp:=PBreakpoint(temporaryDisabledExceptionBreakpoints[i]);
        if not bp^.markedfordeletion then
          TdebuggerThread(debuggerthread).setBreakpoint(bp);

        dec(bp^.referencecount); //decrease referencecount so they can be deleted
      end;

      freeandnil(temporaryDisabledExceptionBreakpoints);
      exit;   //raise the exception in the game and let it crash
    end
    else
      temporaryDisabledExceptionBreakpoints:=Tlist.create;

    //now remove the protections

    debuggercs.enter;
    for i:=0 to breakpointlist.count-1 do
    begin
      bp:=breakpointList[i];
      if (bp.breakpointMethod=bpmException) then  //don't check for active, as some breakpoint events might be stacked
      begin
        //check if the address is in this breakpoint range
        if inrangex(address, GetPageBase(bp.address), GetPageBase(bp.address+bp.size)+$fff) or
           inrangex(address+$1000, GetPageBase(bp.address), GetPageBase(bp.address+bp.size)+$fff)
        then
        begin
          TdebuggerThread(debuggerthread).UnsetBreakpoint(bp);    //设置断点非激活态，并根据所选下断点的模式 恢复内存保护模式
          inc(bp.referencecount);                                 //非激活态的断点，需要累加引用计数防止断点被删除
          temporaryDisabledExceptionBreakpoints.Add(bp);          //增加到临时非激活态断点列表
        end;
      end;
    end;

    debuggercs.leave;


    if temporaryDisabledExceptionBreakpoints.count=0 then
    begin
      //not caused by my pagechanges
      freeandnil(temporaryDisabledExceptionBreakpoints);
      exit; //continue unhandled
    end;



    breakAddress:=address;

    //freeze all threads except this one and do a single step

    context.EFlags:=eflags_setTF(context.EFlags,1);
    setContext;


    NtSuspendProcess(processhandle);

    ResumeThread(self.Handle);


   // suspendthread(self.Handle);

    //handled, continue till the next int1
    dwContinueStatus:=DBG_CONTINUE;

  end
  else
    dwContinueStatus:=DBG_EXCEPTION_NOT_HANDLED;
end;


function TDebugThreadHandler.HandleExceptionDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
var
  exceptionAddress: ptrUint;
  i: integer;
  bp: PBreakpoint;
begin
  TDebuggerthread(debuggerthread).execlocation:=16;
  bp:=nil;

  //OutputDebugString(inttohex(ThreadId,1)+'('+inttohex(context.{$ifdef cpu64}Rip{$else}Eip{$endif},8)+')'+':HandleExceptionDebugEvent:'+inttohex(debugEvent.Exception.ExceptionRecord.ExceptionCode,8));
  exceptionAddress := ptrUint(debugEvent.Exception.ExceptionRecord.ExceptionAddress);



  case debugEvent.Exception.ExceptionRecord.ExceptionCode of  //Int3 中断
    EXCEPTION_BREAKPOINT, STATUS_WX86_BREAKPOINT: //SW bp
    begin
      OutputDebugString('EXCEPTION_BREAKPOINT:'+inttohex(context.{$ifdef cpu64}rip{$else}eip{$endif},8));


      //if this is the first breakpoint exception check if it needs to set the entry point bp

      if TDebuggerThread(debuggerthread).NeedsToSetEntryPointBreakpoint then
      begin
        OutputDebugString('Calling SetEntryPointBreakpoint');
        TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), TDebuggerthread(debuggerthread).SetEntryPointBreakpoint);
        OutputDebugString('After synchronize for SetEntryPointBreakpoint');
      end;

      //it's a software breakpoint, adjust eip to go back by 1
      dec(context.{$ifdef cpu64}rip{$else}eip{$endif});
      setContext;


      Result := DispatchBreakpoint(context.{$ifdef cpu64}Rip{$else}eip{$endif}, -1, dwContinueStatus);

      if dwContinueStatus=DBG_CONTINUE then
      begin
        if result=false then
        begin
          //initial breakpoint
          inc(context.{$ifdef cpu64}rip{$else}eip{$endif});
          result:=true;
        end;
        context.dr6:=0; //handled
        setContext;



      end
      else
      begin
        {if CurrentDebuggerInterface.name='Windows Debugger' then
        begin
          //emulate a call to the unhandled exception handler


        end;  }


       // context.dr6:=0; //unhandled
        inc(context.{$ifdef cpu64}rip{$else}eip{$endif}); //undo the -1
        setContext;
      end;
    end;

    EXCEPTION_SINGLE_STEP, STATUS_WX86_SINGLE_STEP:
    begin
      //OutputDebugString('EXCEPTION_SINGLE_STEP. Dr6='+inttohex(context.dr6,8));
      //Int1 异常包括了TF DR，现在加入了无痕硬断，需要优先处理
      if debugEvent.Exception.ExceptionRecord.ExceptionInformation[8]=8 then //无痕硬断标志
      begin
        result:=DispatchBreakpoint(exceptionAddress, -1, dwContinueStatus);
        dwContinueStatus:= DBG_CONTINUE;//这个无痕硬断是我自己制造的，必须无条件返回Continue;
        exit;
        end;

      if temporaryDisabledExceptionBreakpoints<>nil then
      begin
        //OutputDebugString('After the single step of an exception caused by my page');

        context.EFlags:=eflags_setTF(context.EFlags,0); //not needed in windows, but let's clear it anyhow
        //context.Dr6:=context.Dr6 and $FFFFFFFFFFFFBFFF; //清除DR6的BS标志   其实TF位为0 BS位也为0
        setContext;
        //这里处理断点，调试器并作出相应的反应，比如断下或者跟踪
        result:=DispatchBreakpoint(breakAddress, -1, dwContinueStatus);

        //reprotect the memory


        for i:=0 to temporaryDisabledExceptionBreakpoints.Count-1 do
        begin

          bp:=PBreakpoint(temporaryDisabledExceptionBreakpoints[i]);
          if not bp^.markedfordeletion then
            TdebuggerThread(debuggerthread).setBreakpoint(bp);

          dec(bp^.referencecount); //decrease referencecount so they can be deleted
        end;


        SuspendThread(handle);
        NtResumeProcess(processhandle);//恢复缺页异常造成的暂停
        dwContinueStatus:=DBG_CONTINUE;//这是缺页后设置TF位产生的异常，不管DispatchBreakpoint是否处理了，都继续执行
        freeandnil(temporaryDisabledExceptionBreakpoints);
        exit;//直接返回
      end;


      if (CurrentDebuggerInterface is TNetworkDebuggerInterface) then  //网络调试相关
      begin
        //the address that caused the break is stored in ExceptionRecord.exceptionaddress
        if uint_ptr(debugEvent.Exception.ExceptionRecord.ExceptionAddress)=1 then
          Result := SingleStep(dwContinueStatus) //only x86 returns this (on a rare occasion)
        else
          DispatchBreakpoint(uint_ptr(debugEvent.Exception.ExceptionRecord.ExceptionAddress), -1, dwContinueStatus);
      end
      else
      begin
        //find out what caused the breakpoint.
        //inspect DR6
        //Problem: if the last breakpoint was unset dr7 is 0. Meaning that DR6 will read out 0 as well...
        //Solution: DeleteBreakpoint must NOT call unsetBreakpoint. Only call it from the breakpoint handler and the breakpoint cleanup


        if (context.Dr6 and 1) = 1 then
        begin
          log('caused by DR0: Context.DR0='+inttohex(context.DR0,8));
          Result := DispatchBreakpoint(context.dr0, 0, dwContinueStatus)
        end
        else
        if ((context.Dr6 shr 1) and 1) = 1 then
        begin
          log('caused by DR1: Context.DR1='+inttohex(context.DR1,8));
          Result := DispatchBreakpoint(context.dr1, 1, dwContinueStatus)
        end
        else
        if ((context.Dr6 shr 2) and 1) = 1 then
        begin
          log('caused by DR2: Context.DR2='+inttohex(context.DR2,8));
          Result := DispatchBreakpoint(context.dr2, 2, dwContinueStatus)
        end
        else
        if ((context.Dr6 shr 3) and 1) = 1 then
        begin
          log('caused by DR3: Context.DR3='+inttohex(context.DR3,8));
          Result := DispatchBreakpoint(context.dr3, 3, dwContinueStatus)
        end
        else
        begin
          log('Not caused by a debugreg');
          Result := SingleStep(dwContinueStatus);
        end;
        if dwContinueStatus=DBG_CONTINUE then
        begin
          context.dr6:=0; //handled

          setContext;
        end;
      end;
    end;

    EXCEPTION_ACCESS_VIOLATION:
    begin
      //exception
      result:=HandleAccessViolationDebugEvent(debugEvent, dwContinueStatus);

    end

    else
      dwContinueStatus:=DBG_EXCEPTION_NOT_HANDLED;
  end;


  if dwContinueStatus=DBG_EXCEPTION_NOT_HANDLED then
  asm
    nop
  end;


  result:=true;
end;

function TDebugThreadHandler.CreateThreadDebugEvent(debugevent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
var i: integer;
begin
  TDebuggerthread(debuggerthread).execlocation:=17;
  OutputDebugString(pchar(format('CreateThreadDebugEvent %x',[debugevent.dwThreadId])));
  processid := debugevent.dwProcessId;
  threadid  := debugevent.dwThreadId;

  if currentdebuggerinterface is TNetworkDebuggerInterface then
    handle  := debugevent.CreateThread.hThread
  else
    handle  := OpenThread(THREAD_ALL_ACCESS, false, threadid );

  Result    := true;

  //set all the debugregister breakpoints for this thread
  //TDebuggerThread(debuggerthread).UpdateDebugRegisterBreakpointsForThread(self);   (now done on cleanup)

  dwContinueStatus:=DBG_CONTINUE;
end;

function TDebugThreadHandler.CreateProcessDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
var
  i: integer;
begin
  TDebuggerthread(debuggerthread).execlocation:=18;
  OutputDebugString('CreateProcessDebugEvent');

  if not secondcreateprocessdebugevent then
  begin

    handle    := debugevent.CreateProcessInfo.hThread;

    processid := debugevent.dwProcessId;
    threadid  := debugevent.dwThreadId;



    if ProcessHandler.processid<>debugevent.dwProcessId then
    begin
      ProcessHandler.ProcessHandle := debugEvent.CreateProcessInfo.hProcess;
      ProcessHandler.processid     := debugEvent.dwProcessId;

      Open_Process;
      symhandler.reinitialize(true);
    end;


    if (CurrentDebuggerInterface is TKernelDebugInterface) or
       (CurrentDebuggerInterface is TNetworkDebuggerInterface) then //the kerneldebuginterface and networkdebuginterface do not give a breakpoint as init so use create as attachevent
      onAttachEvent.SetEvent;

    secondcreateprocessdebugevent:=true;
  end;
  Result := true;
  dwContinueStatus:=DBG_CONTINUE;
end;

function TDebugThreadHandler.ExitThreadDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
var
  i: integer;
begin
  TDebuggerthread(debuggerthread).execlocation:=19;
  Outputdebugstring('ExitThreadDebugEvent');
  TDebuggerThread(debuggerthread).CurrentThread:=nil;
  Result := true;
  dwContinueStatus:=DBG_CONTINUE;
end;

function TDebugThreadHandler.ExitProcessDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
begin
  TDebuggerthread(debuggerthread).execlocation:=20;
  outputdebugstring('ExitProcessDebugEvent');
  dwContinueStatus:=DBG_CONTINUE;
  Result := False;
end;

function TDebugThreadHandler.LoadDLLDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
var m: string;
    mw: widestring;
    x: pchar;
    xw: pwidechar absolute x;
    br: PtrUInt;

    p: pointer;
begin
  TDebuggerthread(debuggerthread).execlocation:=21;
  outputdebugstring('LoadDLLDebugEvent');

  getmem(x,512);
  br:=0;

  m:='';
  p:=nil;
  readprocessmemory(processhandle, debugEvent.LoadDll.lpImageName, @p, processhandler.pointersize, br);
  if br>0 then
  begin
    br:=0;
    readprocessmemory(processhandle, p, x, 512, br);
    if br>0 then
    begin
      x[511]:=#0;
      x[510]:=#0;

      if debugEvent.LoadDll.fUnicode<>0 then
      begin
        mw:=xw;
        m:=mw;
      end
      else
        m:=x;

      if LUA_functioncall('debugger_onModuleLoad',[m, ptruint(debugevent.LoadDll.lpBaseOfDll)])=1 then
      begin
        //do a break
        HandleBreak(nil);

      end;

    end;
  end;

  Result := true;
  dwContinueStatus:=DBG_CONTINUE;
end;

function TDebugThreadHandler.UnloadDLLDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
begin
  TDebuggerthread(debuggerthread).execlocation:=22;
  outputdebugstring('UnloadDLLDebugEvent');
  Result := true;
  dwContinueStatus:=DBG_CONTINUE;
end;

function TDebugThreadHandler.OutputDebugStringEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
var s: pchar;
    ws: pwidechar;
    x: PtrUInt;
begin
  TDebuggerthread(debuggerthread).execlocation:=23;
  outputdebugstring('OutputDebugStringEvent');

  if FormDebugStrings<>nil then
  begin
    if debugEvent.DebugString.fUnicode>0 then
    begin
      ws:=getmem(debugEvent.DebugString.nDebugStringLength+2);
      try
        ReadProcessMemory(processhandle, debugEvent.DebugString.lpDebugStringData, ws, debugEvent.DebugString.nDebugStringLength,x);
        ws[debugEvent.DebugString.nDebugStringLength div 2]:=#0;
        ws[x div 2]:=#0;

        DebugEventString:=ws;

        TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), AddDebugEventString);
      finally
        freemem(ws);
      end;
    end
    else
    begin
      s:=getmem(debugEvent.DebugString.nDebugStringLength+1);
      try
        ReadProcessMemory(processhandle, debugEvent.DebugString.lpDebugStringData, s, debugEvent.DebugString.nDebugStringLength,x);
        s[debugEvent.DebugString.nDebugStringLength]:=#0;
        s[x]:=#0;

        DebugEventString:=s;

        TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), AddDebugEventString);
      finally
        freemem(s);
      end;
    end;


  end;

  Result := true;
  dwContinueStatus:=DBG_EXCEPTION_NOT_HANDLED;
end;

function TDebugThreadHandler.RipEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
begin
  TDebuggerthread(debuggerthread).execlocation:=24;
  outputdebugstring('RipEvent');
  Result := true;
  dwContinueStatus:=DBG_CONTINUE;

end;

function TDebugThreadHandler.HandleUnknownEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
begin
  TDebuggerthread(debuggerthread).execlocation:=25;
  //OutputDebugString('Unknown event');
  Result := true;
  dwContinueStatus:=DBG_CONTINUE;
end;

destructor TDebugThreadHandler.destroy;
begin
  freemem(realcontextpointer);
  inherited destroy;
end;

constructor TDebugThreadHandler.Create(debuggerthread: TObject; attachEvent: Tevent; continueEvent: TEvent; breakpointlist: TList; threadlist: Tlist; debuggerCS: TGuiSafeCriticalSection);
begin
  //because fpc's structure is not alligned on a 16 byte base I have to allocate more memory and byteshift the structure if needed
  getmem(realcontextpointer,sizeof(TCONTEXT)+15);
  context:=pointer((ptrUint(realcontextpointer)+15) and ptrUint($fffffffffffffff0));

  self.debuggerthread := debuggerthread;
  onAttachEvent := attachEvent;
  onContinueEvent := continueEvent;
  self.breakpointList:=breakpointlist;
  self.threadlist:=threadlist;
  self.debuggerCS:=debuggerCS;
end;


function TDebugEventHandler.HandleDebugEvent(debugEvent: TDEBUGEVENT; var dwContinueStatus: dword): boolean;
var
  currentThread: TDebugThreadHandler;

  newthread: boolean;
  i: integer;
  ActiveBPList: TList;
begin
  //OutputDebugString('HandleDebugEvent:'+inttostr(debugEvent.dwDebugEventCode));
  //find the TDebugThreadHandler class that belongs to this thread
  debuggercs.enter;

  TDebuggerthread(debuggerthread).execlocation:=10;

  currentThread := nil;

  for i := 0 to ThreadList.Count - 1 do
  begin
    if TDebugThreadHandler(ThreadList.Items[i]).threadid = debugEvent.dwThreadId then
    begin
      currentThread := ThreadList.Items[i];
      break;
    end;
  end;


  if currentThread = nil then //not found
  begin
    //so create and add it
    newthread:=true;
    currentThread := TDebugThreadHandler.Create(debuggerthread, fonattachEvent, fOnContinueEvent, breakpointlist, threadlist, debuggerCS);
    currentThread.processid := debugevent.dwProcessId;
    currentThread.threadid := debugevent.dwThreadId;

    ThreadList.Add(currentThread);
  end
  else
    newthread:=false;

  currentthread.isHandled:=true;
  currentthread.FillContext;
  TDebuggerthread(debuggerthread).currentThread:=currentThread;

  debuggercs.leave;

  //The most important data has been gathered (DR6 of the thread). it's safe from this point to occasionally release the lock

  if newthread and (frmthreadlist<>nil) then
  begin
    currentdebugEvent:=debugEvent;
    TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), updatethreadlist);
  end;

  if frmDebugEvents<>nil then
  begin
    currentdebugEvent:=debugEvent;
    TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), UpdateDebugEventWindow);
  end;


  TDebuggerthread(debuggerthread).execlocation:=11;

  case debugEvent.dwDebugEventCode of
    EXCEPTION_DEBUG_EVENT:      Result := currentThread.HandleExceptionDebugEvent(debugevent, dwContinueStatus);
    CREATE_THREAD_DEBUG_EVENT:  Result := currentThread.CreateThreadDebugEvent(debugEvent, dwContinueStatus);
    CREATE_PROCESS_DEBUG_EVENT: Result := currentThread.CreateProcessDebugEvent(debugEvent, dwContinueStatus);
    EXIT_THREAD_DEBUG_EVENT:
    begin
      debuggercs.enter;
      try
        Result := currentThread.ExitThreadDebugEvent(debugEvent, dwContinueStatus);
        ThreadList.Remove(currentThread);
        currentThread.Free;
        currentthread:=nil;

      finally
        debuggercs.leave;
      end;

      if frmthreadlist<>nil then
        TDebuggerthread(debuggerthread).Synchronize(TDebuggerthread(debuggerthread), updatethreadlist);
    end;
    EXIT_PROCESS_DEBUG_EVENT:   Result := currentThread.ExitProcessDebugEvent(debugEvent, dwContinueStatus);
    LOAD_DLL_DEBUG_EVENT:       Result := currentThread.LoadDLLDebugEvent(debugEvent, dwContinueStatus);
    UNLOAD_DLL_DEBUG_EVENT:     Result := currentThread.UnloadDLLDebugEvent(debugEvent, dwContinueStatus);
    OUTPUT_DEBUG_STRING_EVENT:  Result := currentThread.OutputDebugStringEvent(debugEvent, dwContinueStatus);
    RIP_EVENT:                  Result := currentThread.RipEvent(debugEvent, dwContinueStatus);

    else
                                Result := currentThread.HandleUnknownEvent(debugEvent, dwContinueStatus);
  end;


  TDebuggerthread(debuggerthread).execlocation:=12;


  //cleanup time for this thread
  {
   //只有当线程事件存在且，该线程的异常代码是  EXCEPTION_DEBUG_EVENT才调用
  if ((currentthread<>nil) and (debugEvent.dwDebugEventCode = EXCEPTION_DEBUG_EVENT)) then //if it wasn't a thread destruction tell this thread it isn't being handled anymore
  begin
    debuggercs.enter; //wait till other threads are done with this

    //if this was a thread that caused a breakpoint unset problem last time call the breakpoint cleanup routine now
    //if currentthread.needstocleanup then
    currentthread.fillContext;

    if (not TDebuggerthread(debuggerthread).usesGlobalDebug) and (processhandler.SystemArchitecture=archX86) and ((dwContinueStatus=DBG_CONTINUE) or (currentThread.context.Dr6=0) or (word(currentThread.context.dr6)=$0ff0)) then
    begin
      //continued or not an unhandled debug register exception
      currentthread.context.dr6:=0;

      //get the active bp list for this thread  (unsetting the breakpoint in safe mode sets active to false, which would break setting them again otherwise)
      ActiveBPList:=TList.create;
      for i:=0 to breakpointlist.count-1 do
      begin
        if PBreakpoint(breakpointlist[i])^.active and          //active
           (PBreakpoint(breakpointlist[i])^.breakpointMethod=bpmDebugRegister) and //it's a debug register bp
           ((PBreakpoint(breakpointlist[i])^.ThreadID=0) or (PBreakpoint(breakpointlist[i])^.ThreadID=currentthread.ThreadId)) and //this isn't a thread specific breakpoint, or this breakpoint affects this thread
           (not (currentthread.setInt1Back and (currentthread.Int1SetBackBP=PBreakpoint(breakpointlist[i])))) //this isn't an XP/Network hack that just disabled the bp for this thread so it can do a single step and re-enable next step
        then
          ActiveBPList.add(breakpointlist[i]);

      end;

      //remove all current breakpoints
      if BPOverride then
      begin
        //override, the debugregs are mine
        currentthread.context.dr0:=0;
        currentthread.context.dr1:=0;
        currentthread.context.dr2:=0;
        currentthread.context.dr3:=0;
        currentthread.context.dr7:=$400;
        currentThread.setContext;
      end
      else
      begin
        //no override, let's be kind and only unset those that are actually used
        for i:=0 to ActiveBPList.count-1 do
          TDebuggerthread(debuggerthread).UnsetBreakpoint(breakpointlist[i], currentthread.context);
        currentthread.setContext;
      end;

      for i:=0 to ActiveBPList.count-1 do
        TDebuggerthread(debuggerthread).SetBreakpoint(ActiveBPList[i], currentthread);

      ActiveBPList.free;



      currentthread.needstocleanup:=false;
      TDebuggerthread(debuggerthread).cleanupDeletedBreakpoints(false);
    end;

    currentthread.isHandled:=false;
    debuggercs.leave;
  end;
  }
  TDebuggerthread(debuggerthread).execlocation:=13;


  //OutputDebugString('Returned from HandleDebugEvent');



end;

procedure TDebugEventHandler.updatethreadlist;
{synchronize routine that updates the threadlist when a change has happened}
begin

  if frmthreadlist<>nil then
    frmThreadlist.FillThreadlist;
end;

procedure TDebugEventHandler.UpdateDebugEventWindow;
{synchronize routine that updates the debug event window}
var eventtext: string;

  eventdata: PDebugEventData;
begin
  if frmDebugEvents<>nil then //check if it's still here
  begin
    eventtext:=inttohex(currentdebugevent.dwDebugEventCode,1);
    case currentdebugevent.dwDebugEventCode of
      CREATE_PROCESS_DEBUG_EVENT: eventtext:='CREATE_PROCESS_DEBUG_EVENT';
      CREATE_THREAD_DEBUG_EVENT: eventtext:='CREATE_THREAD_DEBUG_EVENT';
      EXCEPTION_DEBUG_EVENT: eventtext:='EXCEPTION_DEBUG_EVENT';
      EXIT_PROCESS_DEBUG_EVENT: eventtext:='EXIT_PROCESS_DEBUG_EVENT';
      EXIT_THREAD_DEBUG_EVENT: eventtext:='EXIT_THREAD_DEBUG_EVENT';
      LOAD_DLL_DEBUG_EVENT: eventtext:='LOAD_DLL_DEBUG_EVENT';
      OUTPUT_DEBUG_STRING_EVENT: eventtext:='OUTPUT_DEBUG_STRING_EVENT';
      RIP_EVENT: eventtext:='RIP_EVENT';
      UNLOAD_DLL_DEBUG_EVENT: eventtext:='UNLOAD_DLL_DEBUG_EVENT';
    end;

    eventtext:=format('pid:%x tid:%x - %s (eip:%x)',[currentdebugEvent.dwProcessId, currentdebugevent.dwThreadId, eventtext, TDebuggerthread(debuggerthread).currentThread.context.{$ifdef cpu64}Rip{$else}eip{$endif}]);

    getmem(eventdata, sizeof(TDebugEventData));
    eventdata.context:=TDebuggerthread(debuggerthread).currentThread.context^;
    frmDebugEvents.lbDebugEvents.Items.AddObject(eventtext, tobject(eventdata));

    frmDebugEvents.lbDebugEvents.TopIndex:=frmDebugEvents.lbDebugEvents.items.count-1
  end;


end;

constructor TDebugEventHandler.Create(debuggerthread: TObject; OnAttachEvent: TEvent; OnContinueEvent: TEvent; breakpointlist: TList; threadlist: Tlist; debuggerCS: TGuiSafeCriticalSection);
begin
  self.debuggerthread := debuggerthread;
  fOnAttachEvent      := OnAttachEvent;
  fOnContinueEvent    := OnContinueEvent;
  self.breakpointlist := breakpointlist;
  self.threadlist     := threadlist;
  self.debuggerCS     := debuggercs;
  inherited Create;
end;


end.

