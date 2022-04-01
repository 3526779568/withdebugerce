unit DebuggerInterface;
{
This unit contains the base class description for the debugger interface.
The other debugger interfaces are inherited from this
}

{$mode delphi}

interface

uses
  Classes, SysUtils{$ifdef windows},windows{$endif},NewKernelHandler, debuggertypedefinitions{$ifdef darwin}, macport{$endif};

type
  TDebuggerCapabilities=(dbcHardwareBreakpoint, dbcSoftwareBreakpoint, dbcExceptionBreakpoint, dbcBreakOnEntry);
  TDebuggerCapabilitiesSet=set of TDebuggerCapabilities;
  TDebuggerInterface=class
  protected
    fmaxInstructionBreakpointCount: integer;
    fmaxWatchpointBreakpointCount: integer;
    fmaxSharedBreakpointCount: integer;

    fDebuggerCapabilities: TDebuggerCapabilitiesSet;
    fErrorString: string;
    noBreakList: array of thandle;
  public
    name: string;
    function WaitForDebugEvent(var lpDebugEvent: TDebugEvent; dwMilliseconds: DWORD): BOOL; virtual; abstract;
    function ContinueDebugEvent(dwProcessId: DWORD; dwThreadId: DWORD; dwContinueStatus: DWORD): BOOL; virtual; abstract;
    function SetThreadContext(hThread: THandle; const lpContext: TContext; isFrozenThread: Boolean=false): BOOL; virtual;
    function SetThreadContextArm(hThread: THandle; const lpContext: TARMCONTEXT; isFrozenThread: Boolean=false): BOOL; virtual;
    function GetThreadContext(hThread: THandle; var lpContext: TContext; isFrozenThread: Boolean=false): BOOL; virtual;
    function GetThreadContextArm(hThread: THandle; var lpContext: TARMCONTEXT; isFrozenThread: Boolean=false): BOOL; virtual;
    function DebugActiveProcess(dwProcessId: DWORD): BOOL; virtual; abstract;
    function DebugActiveProcessStop(dwProcessID: DWORD): BOOL; virtual;
    function GetLastBranchRecords(lbr: pointer): integer; virtual;

    function inNoBreakList(threadid: integer): boolean; virtual;
    procedure AddToNoBreakList(threadid: integer); virtual;
    procedure RemoveFromNoBreakList(threadid: integer); virtual;

    function canReportExactDebugRegisterTrigger: boolean; virtual;

    property DebuggerCapabilities: TDebuggerCapabilitiesSet read fDebuggerCapabilities;
    property errorstring: string read ferrorstring;

    property maxInstructionBreakpointCount: integer read fmaxInstructionBreakpointCount;
    property maxWatchpointBreakpointCount: integer read fmaxWatchpointBreakpointCount;
    property maxSharedBreakpointCount: integer read fmaxSharedBreakpointCount;


end;

implementation

function TDebuggerInterface. SetThreadContext(hThread: THandle; const lpContext: TContext; isFrozenThread: Boolean=false): BOOL;
begin
  result:=false;
end;

function TDebuggerInterface.SetThreadContextArm(hThread: THandle; const lpContext: TARMCONTEXT; isFrozenThread: Boolean=false): BOOL;
begin
  result:=false;
end;

function TDebuggerInterface.GetThreadContextArm(hThread: THandle; var lpContext: TARMCONTEXT; isFrozenThread: Boolean=false): BOOL;
begin
  result:=false;
end;

function TDebuggerInterface.GetThreadContext(hThread: THandle; var lpContext: TContext; isFrozenThread: Boolean=false): BOOL;
begin
  result:=false;
end;



function TDebuggerInterface.DebugActiveProcessStop(dwProcessID: DWORD): BOOL;
begin
  //don't complain if not implemented
  result:=true;
end;

function TDebuggerInterface.GetLastBranchRecords(lbr: pointer): integer;
begin
  //if implemented fill in the lbr pointer with the lbr records (array of qwords) and return the count (max 16)
  result:=-1;
end;

function TDebuggerInterface.inNoBreakList(threadid: integer): boolean;
var i: integer;
begin
  result:=false;
  for i:=0 to length(nobreaklist)-1 do
    if nobreaklist[i]=threadid then
    begin
      result:=true;
      exit;
    end;
end;

procedure TDebuggerInterface.AddToNoBreakList(threadid: integer);
begin
  if inNoBreaklist(threadid) then exit;

  setlength(nobreaklist, length(nobreaklist)+1);
  nobreaklist[length(nobreaklist)-1]:=threadid;
end;

procedure TDebuggerInterface.RemoveFromNoBreakList(threadid: integer);
var i,j: integer;
begin
  for i:=0 to length(noBreakList)-1 do
  begin
    if nobreaklist[i]=threadid then
    begin
      for j:=i to length(nobreaklist)-2 do
        nobreaklist[j]:=nobreaklist[j+1];

      setlength(nobreaklist, length(nobreaklist)-1);
    end;
  end;
end;

function TDebuggerInterface.canReportExactDebugRegisterTrigger: boolean;
begin
  result:=true;
end;

end.

