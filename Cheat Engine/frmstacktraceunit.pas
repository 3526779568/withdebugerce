unit frmstacktraceunit;

{$MODE Delphi}

interface

uses
  windows, LCLIntf, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs,NewKernelHandler, CEFuncProc, ComCtrls,imagehlp,CEDebugger, KernelDebugger,
  Menus, LResources, debughelper, symbolhandler;

type

  { TfrmStacktrace }

  TfrmStacktrace = class(TForm)
    ListView1: TListView;
    miManualStackwalk: TMenuItem;
    PopupMenu1: TPopupMenu;
    Refresh1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ListView1DblClick(Sender: TObject);
    procedure miManualStackwalkClick(Sender: TObject);
    procedure Refresh1Click(Sender: TObject);
  private
    { Private declarations }
    procedure refreshtrace;
  public
    { Public declarations }
    procedure shadowstacktrace(context: _context; stackcopy: pointer; stackcopysize: integer);
    procedure stacktrace(threadhandle:thandle;context:_context);
  end;

var
  frmStacktrace: TfrmStacktrace;

implementation

uses MemoryBrowserFormUnit, frmManualStacktraceConfigUnit, ProcessHandlerUnit, DBK32functions;

var
  useShadow: boolean;
  shadowOrig: ptruint;
  shadowNew: ptruint;
  shadowSize: integer;



function rpm64(hProcess:THANDLE; qwBaseAddress:dword64; lpBuffer:pointer; nSize:dword; lpNumberOfBytesRead:lpdword):bool;stdcall; //should be lpptruint but the header file isn't correct
var
    br: ptruint;
begin
  result:=false;
  {$ifndef cpu64}
  if qwBaseAddress>$FFFFFFFF then exit;
  {$endif}

  if useShadow and InRangeQ(qwBaseAddress, shadowOrig, shadoworig+shadowSize) then
    qwBaseAddress:=shadowNew+(qwBaseAddress-shadowOrig); //adjust the base address to the copy location

  result:=DBK32functions.ReadProcessMemory64(hProcess, qwBaseAddress, lpBuffer, nSize, br);

  if lpNumberOfBytesRead<>nil then
    lpNumberOfBytesRead^:=br;
end;






procedure TfrmStacktrace.stacktrace(threadhandle:thandle;context:_context);
{
}

var
    stackframe: TSTACKFRAME_EX;
    cxt:_context;
    wow64ctx: CONTEXT32;
    a,b,c,d: dword;
    sa,sb,sc,sd:string;
    machinetype: dword;

    cp: pointer;

    found: boolean;
begin

  cxt:=context;
  cp:=@cxt;

 // getmem(stackframe,sizeof(TSTACKFRAME_EX));
  zeromemory(@stackframe,sizeof(TSTACKFRAME_EX));

  stackframe.StackFrameSize:=sizeof(TSTACKFRAME_EX);

  try
    stackframe.AddrPC.Offset:=context.{$ifdef cpu64}rip{$else}eip{$endif};
    stackframe.AddrPC.mode:=AddrModeFlat;

    stackframe.AddrStack.Offset:=context.{$ifdef cpu64}rsp{$else}esp{$endif};
    stackframe.AddrStack.Mode:=addrmodeflat;

    stackframe.AddrFrame.Offset:=context.{$ifdef cpu64}rbp{$else}ebp{$endif};
    stackframe.AddrFrame.Mode:=addrmodeflat;

    listview1.items.clear;


  //function StackWalk64(MachineType:dword; hProcess:THANDLE; hThread:THANDLE; StackFrame:LPSTACKFRAME64; ContextRecord:pointer;  ReadMemoryRoutine:TREAD_PROCESS_MEMORY_ROUTINE64; FunctionTableAccessRoutine:TFUNCTION_TABLE_ACCESS_ROUTINE64; GetModuleBaseRoutine:TGET_MODULE_BASE_ROUTINE64; TranslateAddress:TTRANSLATE_ADDRESS_ROUTINE64):bool;stdcall;external External_library name 'StackWalk64';
  {$ifdef cpu32}
    machinetype:=IMAGE_FILE_MACHINE_I386;
  {$else}

    if processhandler.is64Bit then
      machinetype:=IMAGE_FILE_MACHINE_AMD64
    else
    begin
      //   if (debuggerthread<>nil) and (debuggerthread.CurrentThread<>nil) then

      ZeroMemory(@wow64ctx, sizeof (wow64ctx));
      wow64ctx.Eip:=cxt.Rip;       //shouldn't be needed though
      wow64ctx.Ebp:=cxt.Rbp;
      wow64ctx.Esp:=cxt.Rsp;
      machinetype:=IMAGE_FILE_MACHINE_I386;


      cp:=@wow64ctx;

    end;
  {$endif}

    //because I provide a readprocessmemory the threadhandle just needs to be the unique for each thread. e.g threadid instead of threadhandle
    while stackwalkex(machinetype,processhandle,threadhandle,@stackframe,cp, rpm64 ,SymFunctionTableAccess64,SymGetModuleBase64,nil,1) do
    begin


      listview1.Items.Add.Caption:=symhandler.getNameFromAddress(stackframe.AddrPC.Offset, true, true);
      listview1.items[listview1.Items.Count-1].SubItems.add(inttohex(stackframe.AddrStack.Offset,8));
      listview1.items[listview1.Items.Count-1].SubItems.add(inttohex(stackframe.AddrFrame.Offset,8));
      listview1.items[listview1.Items.Count-1].SubItems.add(inttohex(stackframe.AddrReturn.Offset,8));

      a:=stackframe.Params[0];
      b:=stackframe.Params[1];
      c:=stackframe.Params[2];
      d:=stackframe.Params[3];

      sa:=symhandler.getNameFromAddress(a, found);
      sb:=symhandler.getNameFromAddress(b, found);
      sc:=symhandler.getNameFromAddress(c, found);
      sd:=symhandler.getNameFromAddress(d, found);

      listview1.items[listview1.Items.Count-1].SubItems.add(sa+','+sb+','+sc+','+sd+',...');
    end;
  finally
   // freemem(stackframe);
  end;
end;

procedure TfrmstackTrace.refreshtrace;
{
Called when the debugger is paused on a breakpoint
}
var c: _CONTEXT;
begin

  if (debuggerthread<>nil) and (debuggerthread.CurrentThread<>nil) then
    stacktrace(debuggerthread.CurrentThread.handle,MemoryBrowser.lastdebugcontext);
end;


procedure TfrmStacktrace.FormCreate(Sender: TObject);
begin
  refreshtrace;
end;

procedure TfrmStacktrace.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if frmstacktrace=self then  //it can be something else as well
    frmstacktrace:=nil;

  action:=cafree;
end;

procedure TfrmStacktrace.ListView1DblClick(Sender: TObject);
begin
  if listview1.Selected<>nil then
    memorybrowser.disassemblerview.TopAddress:=symhandler.getAddressFromName(listview1.Selected.Caption);
end;

procedure TfrmStacktrace.shadowstacktrace(context: _context; stackcopy: pointer; stackcopysize: integer);
begin
  useshadow:=true;
  shadowOrig:=context.{$ifdef cpu64}rsp{$else}esp{$endif};
  shadowNew:=ptruint(stackcopy);
  shadowSize:=stackcopysize;
  stacktrace(GetCurrentThread, context);
end;


procedure TfrmStacktrace.miManualStackwalkClick(Sender: TObject);
var c: _CONTEXT;
    frmManualStacktraceConfig: TfrmManualStacktraceConfig;
begin
  zeromemory(@c, sizeof(_CONTEXT));

  frmManualStacktraceConfig:=tfrmManualStacktraceConfig.create(self);
  if frmManualStacktraceConfig.showmodal=mrok then
  begin
    c.{$ifdef cpu64}Rip{$else}eip{$endif}:=frmManualStacktraceConfig.eip;
    c.{$ifdef cpu64}Rbp{$else}ebp{$endif}:=frmManualStacktraceConfig.ebp;
    c.{$ifdef cpu64}Rsp{$else}esp{$endif}:=frmManualStacktraceConfig.esp;

    if frmManualStacktraceConfig.useshadow then
    begin
      useshadow:=true;
      shadowOrig:=frmManualStacktraceConfig.shadoworig;
      shadowNew:=frmManualStacktraceConfig.shadownew;
      shadowSize:=frmManualStacktraceConfig.shadowsize;
    end;
    stacktrace(GetCurrentThreadId, c);

    useShadow:=false;
  end;
  frmManualStacktraceConfig.free;


end;

procedure TfrmStacktrace.Refresh1Click(Sender: TObject);
begin
  refreshtrace;
end;


initialization
  {$i frmstacktraceunit.lrs}



end.
