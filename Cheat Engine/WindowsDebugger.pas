unit WindowsDebugger;
{
Debugger interface for the default windows api.
It's basically just a forward for everything
}

{$mode delphi}

interface

uses
  Classes, SysUtils, DebuggerInterface, windows, cefuncproc,newkernelhandler,
  symbolhandler, dialogs,ddydebugapi;

type TWindowsDebuggerInterface=class(TDebuggerInterface)
  public

    function WaitForDebugEvent(var lpDebugEvent: TDebugEvent; dwMilliseconds: DWORD): BOOL; override;
    function ContinueDebugEvent(dwProcessId: DWORD; dwThreadId: DWORD; dwContinueStatus: DWORD): BOOL; override;
    function SetThreadContext(hThread: THandle; const lpContext: TContext; isFrozenThread: Boolean=false): BOOL; override;
    function GetThreadContext(hThread: THandle; var lpContext: TContext; isFrozenThread: Boolean=false): BOOL; override;
    function DebugActiveProcess(dwProcessId: DWORD): WINBOOL; override;
    function DebugActiveProcessStop(dwProcessID: DWORD): BOOL; override;
    constructor create;
end;


implementation

uses autoassembler, pluginexports, CEDebugger, DebugHelper, processhandlerunit;

resourcestring
  rsErrorAttachingTheWindowsDebugger = 'Error attaching the windows debugger: '
    +'%s';

constructor TWindowsDebuggerInterface.create;
begin
  inherited create;
  fDebuggerCapabilities:=[dbcSoftwareBreakpoint, dbcHardwareBreakpoint, dbcExceptionBreakpoint, dbcBreakOnEntry];
  name:='Windows Debugger';

  fmaxSharedBreakpointCount:=4;
end;

function TWindowsDebuggerInterface.WaitForDebugEvent(var lpDebugEvent: TDebugEvent; dwMilliseconds: DWORD): BOOL;
begin
  //result:=newkernelhandler.WaitForDebugEvent(lpDebugEvent, dwMilliseconds);
  result:= stw.WaitForDebugEvent(lpDebugEvent, dwMilliseconds);
end;

function TWindowsDebuggerInterface.ContinueDebugEvent(dwProcessId: DWORD; dwThreadId: DWORD; dwContinueStatus: DWORD): BOOL;
begin
  //result:=newkernelhandler.ContinueDebugEvent(dwProcessId, dwThreadId, dwContinueStatus);
  result:= stw.ContinueDebugEvent(dwProcessId, dwThreadId, dwContinueStatus);
end;

function TWindowsDebuggerInterface.SetThreadContext(hThread: THandle; const lpContext: TContext; isFrozenThread: Boolean=false): BOOL;
begin
  result:=newkernelhandler.SetThreadContext(hThread, lpContext);
end;

function TWindowsDebuggerInterface.GetThreadContext(hThread: THandle; var lpContext: TContext; isFrozenThread: Boolean=false):BOOL;
begin
  result:=newkernelhandler.GetThreadContext(hThread, lpContext);
end;

function TWindowsDebuggerInterface.DebugActiveProcessStop(dwProcessID: DWORD): BOOL;
begin
  if assigned(CEDebugger.DebugActiveProcessStop) then
    result:=CEDebugger.DebugActiveProcessStop(dwProcessID)
  else
    result:=false;
end;

function TWindowsDebuggerInterface.DebugActiveProcess(dwProcessId: DWORD): WINBOOL;
var d: tstringlist;
begin
 // OutputDebugString('Windows Debug Active Process');
  processhandler.processid:=dwProcessID;

//  OutputDebugString('Before calling Open_Process');
  Open_Process;

 // OutputDebugString('After calling Open_Process');
  symhandler.reinitialize;
  symhandler.waitforsymbolsloaded(true);

  //???????????????????????????????????????
  PreventDebuggerDetection := false;
  if PreventDebuggerDetection then
  begin
    d:=tstringlist.create;
    try
      d.Add('IsDebuggerPresent:');
      d.add('xor eax,eax');
      d.add('ret');
      try
        autoassemble(d,false);
      except
      end;

    finally
      d.free;
    end;
  end;

  //result:=newkernelhandler.DebugActiveProcess(dwProcessId);
  result:=stw.DebugActiveProcess(dwProcessId);

  if result=false then
    ferrorstring:=Format(rsErrorAttachingTheWindowsDebugger, [inttostr(
      getlasterror)])
  else
    symhandler.reinitialize;
  //processhandler.processid:=dwProcessID;
  //Open_Process;

end;


end.

