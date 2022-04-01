unit VEHDebugger;

{$mode delphi}

interface

uses
  jwaNtStatus, Windows, Classes, SysUtils,symbolhandler,VEHDebugSharedMem,cefuncproc,
  autoassembler,newkernelhandler,DebuggerInterface, Clipbrd;

type
  TVEHDebugInterface=class(TDebuggerInterface)
  private
    guid: TGUID; //to indentify this specific debugger
    guidstring: string;

    HasDebugEvent: THandle;
    HasHandledDebugEvent: THandle;

    ConfigFileMapping: THandle;
    VEHDebugView: PVEHDebugSharedMem;

    active: boolean;
    is64bit: boolean; //stored local so it doesn't have to evaluate the property (saves some time)
    hasPausedProcess: boolean;
    procedure SynchronizeNoBreakList;
  public
    function WaitForDebugEvent(var lpDebugEvent: TDebugEvent; dwMilliseconds: DWORD): BOOL; override;
    function ContinueDebugEvent(dwProcessId: DWORD; dwThreadId: DWORD; dwContinueStatus: DWORD): BOOL; override;
    function SetThreadContext(hThread: THandle; const lpContext: TContext; isFrozenThread: Boolean=false): BOOL; override;
    function GetThreadContext(hThread: THandle; var lpContext: TContext; isFrozenThread: Boolean=false):  BOOL; override;

    function DebugActiveProcess(dwProcessId: DWORD): WINBOOL; override;
    function DebugActiveProcessStop(dwProcessID: DWORD): WINBOOL; override;
    procedure AddToNoBreakList(threadid: integer); override;
    procedure RemoveFromNoBreakList(threadid: integer); override;
    destructor destroy; override;
    constructor create;
  end;


implementation

uses ProcessHandlerUnit, Globals;

resourcestring
  rsErrorWhileTryingToCreateTheConfigurationStructure = 'Error while trying '
    +'to create the configuration structure! (Which effectively renders this '
    +'whole feature useless) Errorcode=%s';
  rsCheatEngineFailedToGetIntoTheConfig = 'DDY Engine failed to get into '
    +'the config of the selected program. (Error=%s)';
  rsFailureDuplicatingTheEventHandlesToTheOtherProcess = 'Failure duplicating '
    +'the event handles to the other process';
  rsVEHDebugError = 'VEH Debug error';
  rsFailureDuplicatingTheFilemapping = 'Failure duplicating the filemapping';

constructor TVEHDebugInterface.create;
begin
  inherited create;
  fDebuggerCapabilities:=[dbcSoftwareBreakpoint,dbcHardwareBreakpoint, dbcExceptionBreakpoint];
  name:='VEH Debugger';

  fmaxSharedBreakpointCount:=4;
end;


destructor TVEHDebugInterface.destroy;
begin
  if HasDebugEvent<>0 then
    closehandle(HasDebugEvent);

  if HasHandledDebugEvent<>0 then
    closehandle(HasHandledDebugEvent);

  inherited destroy;
end;

function TVEHDebugInterface.SetThreadContext(hThread: THandle; const lpContext: TContext; isFrozenThread: Boolean=false): BOOL;
var c: PContext;
{$ifdef cpu64}
    c32: PContext32 absolute c;
{$endif}
begin


  if isFrozenThread then //use the VEHDebugView context
  begin
    result:=true;

    c:=@VEHDebugView.CurrentContext[0];
    {$ifdef cpu64}
    if not is64bit then
    begin
      //the given context needs to be converted to 32-bit

      //c32.ContextFlags:=lpcontext.ContextFlags;
      c32.Dr0:=lpcontext.Dr0;
      c32.Dr1:=lpcontext.Dr1;
      c32.Dr2:=lpcontext.Dr2;
      c32.Dr3:=lpcontext.Dr3;
      c32.Dr6:=lpcontext.Dr6;
      c32.Dr7:=lpcontext.Dr7;

      c32.SegGs:=lpcontext.SegGs;
      c32.SegFs:=lpcontext.SegFs;
      c32.SegEs:=lpcontext.SegEs;
      c32.SegDs:=lpcontext.SegDs;

      c32.edi:=lpcontext.rdi;
      c32.esi:=lpcontext.rsi;
      c32.ebx:=lpcontext.rbx;
      c32.edx:=lpcontext.rdx;
      c32.ecx:=lpcontext.rcx;
      c32.eax:=lpcontext.rax;
      c32.ebp:=lpcontext.rbp;
      c32.eip:=lpcontext.rip;
      c32.SegCs:=lpcontext.SegCs;
      c32.EFlags:=lpcontext.EFlags;
      c32.esp:=lpcontext.rsp;
      c32.SegSs:=lpcontext.SegSs;

      CopyMemory(@c32.ext, @lpContext.fltsave,sizeof(c32.ext));


    end else c^:=lpContext;

   // end;// else lpContext:=c^;
    {$else}
    c^:=lpContext;
    {$endif}

    //Interesting effect: result:=NewKernelHandler.SetThreadContext(hThread,lpContext);
  end
  else
    result:=NewKernelHandler.SetThreadContext(hThread,lpContext);
end;

function TVEHDebugInterface.GetThreadContext(hThread: THandle; var lpContext: TContext; isFrozenThread: Boolean=false):  BOOL;
var c: PContext;
{$ifdef cpu64}
    c32: PContext32 absolute c;
    i: integer;
{$endif}

begin
  if isFrozenThread then //use the VEHDebugView context
  begin
    result:=true;
    c:=@VEHDebugView.CurrentContext[0];
    {$ifdef cpu64}
    if not is64bit then
    begin
      ZeroMemory(@lpContext,sizeof(TContext));
      lpContext.ContextFlags:=c32.ContextFlags;
      lpContext.Dr0:=c32.Dr0;
      lpContext.Dr1:=c32.Dr1;
      lpContext.Dr2:=c32.Dr2;
      lpContext.Dr3:=c32.Dr3;
      lpContext.Dr6:=c32.Dr6;
      lpContext.Dr7:=c32.Dr7;


      lpContext.SegGs:=c32.SegGs;
      lpContext.SegFs:=c32.SegFs;
      lpContext.SegEs:=c32.SegEs;
      lpContext.SegDs:=c32.SegDs;

      lpContext.Rdi:=c32.Edi;
      lpContext.Rsi:=c32.Esi;
      lpContext.Rbx:=c32.Ebx;
      lpContext.Rdx:=c32.Edx;
      lpContext.Rcx:=c32.Ecx;
      lpContext.Rax:=c32.Eax;
      lpContext.Rbp:=c32.Ebp;
      lpContext.Rip:=c32.Eip;
      lpContext.SegCs:=c32.SegCs;
      lpContext.EFlags:=c32.EFlags;
      lpContext.Rsp:=c32.Esp;
      lpContext.SegSs:=c32.SegSs;

      CopyMemory(@lpcontext.FltSave, @c32.ext,sizeof(c32.ext));
    end else lpContext:=c^;
    {$else}
    lpContext:=c^;
    {$endif}


  end
  else
    result:=NewKernelHandler.GetThreadContext(hThread,lpContext);
end;

function TVEHDebugInterface.WaitForDebugEvent(var lpDebugEvent: TDebugEvent; dwMilliseconds: DWORD): BOOL;
var i: integer;
    c: PContext;
{$ifdef cpu64}
    c32: PContext32 absolute c;
{$endif}
begin


  result:=waitforsingleobject(HasDebugEvent, dwMilliseconds)=WAIT_OBJECT_0;

  if result then
  begin
    ZeroMemory(@lpDebugEvent, sizeof(TdebugEvent));
    //fetch the data from the debugged app



   // lpDebugEvent.dwDebugEventCode:=EXCEPTION_DEBUG_EVENT; //exception
    lpDebugEvent.dwProcessId:=VEHDebugView.ProcessID;
    lpDebugEvent.dwThreadId:=VEHDebugView.ThreadID;
    lpDebugEvent.Exception.dwFirstChance:=1;

    case VEHDebugView.Exception64.ExceptionCode of
      $ce000000: //create process
      begin
        lpDebugEvent.dwDebugEventCode:=CREATE_PROCESS_DEBUG_EVENT;
        lpDebugEvent.CreateProcessInfo.hFile:=0;
        lpDebugEvent.CreateProcessInfo.hProcess:=processhandle;
        lpDebugEvent.CreateProcessInfo.hThread:=OpenThread(THREAD_ALL_ACCESS,false, lpDebugEvent.dwThreadId);
      end;

      $ce000001: //create thread
      begin
        lpDebugEvent.dwDebugEventCode:=CREATE_THREAD_DEBUG_EVENT;
        lpDebugEvent.CreateThread.hThread:=OpenThread(THREAD_ALL_ACCESS,false, lpDebugEvent.dwThreadId);

        lpDebugEvent.CreateThread.lpStartAddress:=nil;
        lpDebugEvent.CreateThread.lpThreadLocalBase:=nil;
      end;

      $ce000002: //destroy thread
      begin
        lpDebugEvent.dwDebugEventCode:=EXIT_THREAD_DEBUG_EVENT;
        lpDebugEvent.ExitThread.dwExitCode:=0;
      end;


      DBG_PRINTEXCEPTION_C:
      begin
        lpDebugEvent.dwDebugEventCode:=OUTPUT_DEBUG_STRING_EVENT;
        lpDebugEvent.DebugString.fUnicode:=0;
        if is64bit then
        begin
          lpDebugEvent.DebugString.nDebugStringLength:=VEHDebugView.Exception64.ExceptionInformation[0];
          lpDebugEvent.DebugString.lpDebugStringData:=pointer(ptrUint(VEHDebugView.Exception64.ExceptionInformation[1]));
        end
        else
        begin
          lpDebugEvent.DebugString.nDebugStringLength:=VEHDebugView.Exception32.ExceptionInformation[0];
          lpDebugEvent.DebugString.lpDebugStringData:=pointer(ptrUint(VEHDebugView.Exception32.ExceptionInformation[1]));
        end;
      end;

      else
      begin
        //unknown event, standard exception
        lpDebugEvent.dwDebugEventCode:=EXCEPTION_DEBUG_EVENT;
        lpDebugEvent.Exception.ExceptionRecord.ExceptionRecord:=nil;
        {$ifdef cpu64}
        if is64bit then
        begin
          lpDebugEvent.Exception.ExceptionRecord.ExceptionCode:=VEHDebugView.Exception64.ExceptionCode;
          lpDebugEvent.Exception.ExceptionRecord.ExceptionFlags:=VEHDebugView.Exception64.ExceptionFlags;
          lpDebugEvent.Exception.ExceptionRecord.ExceptionRecord:=pointer(VEHDebugView.Exception64.ExceptionRecord);
          lpDebugEvent.Exception.ExceptionRecord.ExceptionAddress:=pointer(VEHDebugView.Exception64.ExceptionAddress);
          lpDebugEvent.Exception.ExceptionRecord.NumberParameters:=VEHDebugView.Exception64.NumberParameters;

          for i:=0 to VEHDebugView.Exception64.NumberParameters-1 do
            lpDebugEvent.Exception.ExceptionRecord.ExceptionInformation[i]:=VEHDebugView.Exception64.ExceptionInformation[i];
        end
        else
        {$endif}
        begin
          lpDebugEvent.Exception.ExceptionRecord.ExceptionCode:=VEHDebugView.Exception32.ExceptionCode;
          lpDebugEvent.Exception.ExceptionRecord.ExceptionFlags:=VEHDebugView.Exception32.ExceptionFlags;
          lpDebugEvent.Exception.ExceptionRecord.ExceptionRecord:=pointer(ptrUint(VEHDebugView.Exception32.ExceptionRecord));
          lpDebugEvent.Exception.ExceptionRecord.ExceptionAddress:=pointer(ptrUint(VEHDebugView.Exception32.ExceptionAddress));
          lpDebugEvent.Exception.ExceptionRecord.NumberParameters:=VEHDebugView.Exception32.NumberParameters;

          for i:=0 to VEHDebugView.Exception32.NumberParameters-1 do
            lpDebugEvent.Exception.ExceptionRecord.ExceptionInformation[i]:=VEHDebugView.Exception32.ExceptionInformation[i];
        end;

        if lpdebugEvent.Exception.ExceptionRecord.ExceptionCode=EXCEPTION_BREAKPOINT then
        begin
          c:=@VEHDebugView.CurrentContext[0];
          {$ifdef cpu64}
          if is64bit then
            c.Rip:=c.rip+1
          else
            c32.Eip:=c32.eip+1;
          {$else}
            c.eip:=c.eip+1
          {$endif}



        end;

      end;
    end;

    hasPausedProcess:=true;

  end;
end;

function TVEHDebugInterface.ContinueDebugEvent(dwProcessId: DWORD; dwThreadId: DWORD; dwContinueStatus: DWORD): BOOL;
begin
  hasPausedProcess:=false;
  VEHDebugView.ContinueMethod:=dwContinueStatus;
  SetEvent(HasHandledDebugEvent);

  result:=true;
end;

function TVEHDebugInterface.DebugActiveProcess(dwProcessId: DWORD): WINBOOL;
var s: tstringlist;
e: integer;
prefix: string;
testptr: ptruint;
mi: tmoduleinfo;

cfm: THandle;
begin
  try
    processhandler.processid:=dwProcessID;
    Open_Process;
    symhandler.reinitialize;

    is64bit:=processhandler.is64Bit;
    if is64bit then
      prefix:='-x86_64'
    else
      prefix:='-i386';


    result:=false;

   { if symhandler.getmodulebyname('vehdebug'+prefix+'.dll',mi) then
      exit; //no reattach supported right now     }




    CreateGUID(guid);
    guidstring:='"'+GUIDToString(guid)+'"';

    //guidstring:='Global\'+GUIDToString(guid);
    OutputDebugString('Creating filemap with name '+pchar(guidstring));

    ConfigFileMapping:=CreateFileMapping(INVALID_HANDLE_VALUE,nil,PAGE_READWRITE,0,sizeof(TVEHDebugSharedMem),pchar(guidstring));

    if ConfigFileMapping=0 then
    begin
      e:=getlasterror;
      OutPutDebugString('Failed:'+inttostr(e));
      raise exception.Create(Format(
        rsErrorWhileTryingToCreateTheConfigurationStructure, [inttostr(e)]));
    end;

    OutPutDebugString('Created the filemap');

    VEHDebugView:=MapViewOfFile(ConfigFileMapping,FILE_MAP_READ or FILE_MAP_WRITE,0,0,sizeof(TVEHDebugSharedMem));
    if (VEHDebugView=nil) then
    begin
      e:=GetLastError;
      closehandle(ConfigFileMapping);

      OutputDebugString('MapViewOfFile failed: '+inttostr(e));

      raise exception.Create(Format(rsCheatEngineFailedToGetIntoTheConfig, [
        inttostr(e)]));
    end;

    ZeroMemory(VEHDebugView,sizeof(TVEHDebugSharedMem));

    VEHDebugView.ThreadWatchMethod:=0; //vehthreadwatchmethod;
    if VEHRealContextOnThreadCreation then
      VEHDebugView.ThreadWatchMethodConfig:=TPOLL_TCREATEREALCONTEXT
    else
      VEHDebugView.ThreadWatchMethodConfig:=0;;



    HasDebugEvent:=CreateEvent(nil, false, false, nil);
    HasHandledDebugEvent:=CreateEvent(nil, false, false, nil);


    if not DuplicateHandle(GetCurrentProcess, HasDebugEvent, processhandle, @VEHDebugView^.HasDebugEvent, 0, false, DUPLICATE_SAME_ACCESS	) then
      raise exception.Create(
        rsFailureDuplicatingTheEventHandlesToTheOtherProcess);

    if not DuplicateHandle(GetCurrentProcess, HasHandledDebugEvent, processhandle, @VEHDebugView^.HasHandledDebugEvent, 0, false, DUPLICATE_SAME_ACCESS	) then
      raise exception.Create(
        rsFailureDuplicatingTheEventHandlesToTheOtherProcess);

    if not DuplicateHandle(GetCurrentProcess, ConfigFileMapping, processhandle, @cfm, 0, false, DUPLICATE_SAME_ACCESS	) then
      raise exception.Create(rsFailureDuplicatingTheFilemapping);



    symhandler.waitforsymbolsloaded(true,'kernel32.dll');

    try
      InjectDll(cheatenginedir+'vehdebug'+prefix+'.dll');
    except
    end;
    symhandler.reinitialize;
    symhandler.waitforsymbolsloaded(true,'vehdebug'+prefix+'.dll');

    testptr:=symhandler.getAddressFromName('"vehdebug'+prefix+'.InitializeVEH"');

    s:=tstringlist.Create;
    try
      s.Clear;
      s.Add('"vehdebug'+prefix+'.ConfigName":');
      s.add('db '''+guidstring+''',0');

      s.Add('"vehdebug'+prefix+'.fm":');
      if processhandler.is64Bit then
        s.add('dq '+inttohex(cfm,8))
      else
        s.add('dd '+inttohex(cfm,8));

      s.Add('CreateThread("vehdebug'+prefix+'.InitializeVEH")');

      //Clipboard.SetTextBuf(pchar(s.text));

      if autoassemble(s,false) then
      begin
        //debugger is attached and ready to go
        active:=true;

      end
      else
      begin

//        showmessage(s.text);
      end;

      result:=true;
    finally
      s.free;
    end;

  except
    on e: exception do
    begin
      messagebox(0, pchar(e.message), pchar(utf8toansi(rsVEHDebugError)), MB_OK or MB_ICONERROR);
      result:=false;
    end;
  end;
end;

function TVEHDebugInterface.DebugActiveProcessStop(dwProcessID: DWORD): WINBOOL;
var prefix: string;
s: Tstringlist;
begin
  result:=false;

  if active and (processhandler.processid=processhandler.processid) then
  begin
    try
      if is64Bit then
        prefix:='-x86_64'
      else
        prefix:='-i386';

      s:=tstringlist.Create;
      try
        s.Add('CreateThread("vehdebug'+prefix+'.UnloadVEH")');
        if autoassemble(s,false) then
        begin
          active:=false;
          result:=true;
        end;
      finally
        s.free;
      end;
    except
    end;


  end;
end;

procedure TVEHDebugInterface.SynchronizeNoBreakList;
var i: integer;
begin
  for i:=0 to min(63, length(noBreakList)-1) do
    VEHDebugView.NoBreakList[i]:=noBreakList[i];

  VEHDebugView.NoBreakListSize:=min(63, length(noBreakList)-1);
end;

procedure TVEHDebugInterface.AddToNoBreakList(threadid: integer);
begin
  inherited AddToNoBreakList(threadid);
  SynchronizeNoBreakList;
end;

procedure TVEHDebugInterface.RemoveFromNoBreakList(threadid: integer);
begin
  inherited RemoveFromNoBreakList(threadid);
  SynchronizeNoBreakList;
end;


end.

