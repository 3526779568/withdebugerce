unit ddydebugapi;

{$mode delphi}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls, sockets,
  ctypes,strings,strutils,windows;
  //NewKernelHandler

const FILE_ANY_ACCESS=0;
const FILE_SPECIAL_ACCESS=FILE_ANY_ACCESS;
const FILE_READ_ACCESS=$0001;
const FILE_WRITE_ACCESS=$0002;
const FILE_RW_ACCESS=FILE_READ_ACCESS or FILE_WRITE_ACCESS;

const METHOD_BUFFERED=    0;
const METHOD_IN_DIRECT=   1;
const METHOD_OUT_DIRECT=  2;
const METHOD_NEITHER=     3;
const FILE_DEVICE_UNKNOWN=$00000022;
const IOCTL_UNKNOWN_BASE=FILE_DEVICE_UNKNOWN;

const DEVICE_LINK_NAME = '\\.\DDYIOLINK';
const PROCESS_DebugActiveProcess   = (IOCTL_UNKNOWN_BASE shl 16) or ($0384 shl 2) or (METHOD_BUFFERED ) or (FILE_ANY_ACCESS shl 14);
const PROCESS_WaitForDebugEvent = (IOCTL_UNKNOWN_BASE shl 16) or ($0484 shl 2) or (METHOD_BUFFERED ) or (FILE_ANY_ACCESS shl 14);
const PROCESS_ContinueDebugEvent = (IOCTL_UNKNOWN_BASE shl 16) or ($0584 shl 2) or (METHOD_BUFFERED ) or (FILE_ANY_ACCESS shl 14);
const DebugSetBreakPoint =   (IOCTL_UNKNOWN_BASE shl 16) or ($0684 shl 2) or (METHOD_BUFFERED ) or (FILE_ANY_ACCESS shl 14);
const DebugRemoveBreakPoint =   (IOCTL_UNKNOWN_BASE shl 16) or ($0594 shl 2) or (METHOD_BUFFERED ) or (FILE_ANY_ACCESS shl 14);

type
   _EXCEPTION_DEBUG_INFO64 = record
      ExceptionRecord: EXCEPTION_RECORD64;
      dwFirstChance: DWORD;
    end;
   EXCEPTION_DEBUG_INFO64 = _EXCEPTION_DEBUG_INFO64;
   LPEXCEPTION_DEBUG_INFO64 = ^EXCEPTION_DEBUG_INFO64;

   _CREATE_THREAD_DEBUG_INFO64 = record
        hThread: DWORD64;
        lpThreadLocalBase: DWORD64;
        lpStartAddress: DWORD64;
      end;
   CREATE_THREAD_DEBUG_INFO64 = _CREATE_THREAD_DEBUG_INFO64;
   LPCREATE_THREAD_DEBUG_INFO64 = ^_CREATE_THREAD_DEBUG_INFO64;

  _CREATE_PROCESS_DEBUG_INFO64 = record
      hFile:   DWORD64;
      hProcess:     DWORD64;
      hThread:    DWORD64;
      lpBaseOfImage:  DWORD64;
      dwDebugInfoFileOffset: DWORD;
      nDebugInfoSize:    DWORD;
      lpThreadLocalBase: DWORD64;
      lpStartAddress:  DWORD64;
      lpImageName:  DWORD64;
      fUnicode:  WORD;

  end;

  CREATE_PROCESS_DEBUG_INFO64 = _CREATE_PROCESS_DEBUG_INFO64;
  LPCREATE_PROCESS_DEBUG_INFO64 = ^_CREATE_PROCESS_DEBUG_INFO64;

  _EXIT_THREAD_DEBUG_INFO64 = record
      dwExitCode:   DWORD;
  end;
  EXIT_THREAD_DEBUG_INFO64 = _EXIT_THREAD_DEBUG_INFO64;
  LPEXIT_THREAD_DEBUG_INFO64 = ^_EXIT_THREAD_DEBUG_INFO64;

  _EXIT_PROCESS_DEBUG_INFO64 = record
      dwExitCode:    DWORD;
  end;
  EXIT_PROCESS_DEBUG_INFO64 = _EXIT_PROCESS_DEBUG_INFO64;
  LPEXIT_PROCESS_DEBUG_INFO64 = ^_EXIT_PROCESS_DEBUG_INFO64;

  _LOAD_DLL_DEBUG_INFO64 = record
      hFile:  DWORD64;
      lpBaseOfDll:  DWORD64;
      dwDebugInfoFileOffset: DWORD;
      nDebugInfoSize:   DWORD;
      lpImageName:  DWORD64;
      fUnicode:   WORD;
  end;
  LOAD_DLL_DEBUG_INFO64 = _LOAD_DLL_DEBUG_INFO64;
  LPLOAD_DLL_DEBUG_INFO64 = ^_LOAD_DLL_DEBUG_INFO64;

  _UNLOAD_DLL_DEBUG_INFO64 = record
       lpBaseOfDll:     DWORD64;
  end;
  UNLOAD_DLL_DEBUG_INFO64 = _UNLOAD_DLL_DEBUG_INFO64;
  LPUNLOAD_DLL_DEBUG_INFO64 = ^_UNLOAD_DLL_DEBUG_INFO64;

  _OUTPUT_DEBUG_STRING_INFO64 = record
      lpDebugStringData:    DWORD64;
      fUnicode:    WORD;
      nDebugStringLength:  WORD;
  end;
  OUTPUT_DEBUG_STRING_INFO64 = _OUTPUT_DEBUG_STRING_INFO64;
  LPOUTPUT_DEBUG_STRING_INFO64 = ^_OUTPUT_DEBUG_STRING_INFO64;

  _RIP_INFO64 = record
      dwError: DWORD;
      dwType:  DWORD;
  end;
  RIP_INFO64 = _RIP_INFO64;
  LPRIP_INFO64 = ^_RIP_INFO64;


  _DEBUG_EVENT64 = record
      dwDebugEventCode:  DWORD;
      dwProcessId:    DWORD;
      dwThreadId:     DWORD;
      case longint of
                 0 : ( Exception : EXCEPTION_DEBUG_INFO64 );
                 1 : ( CreateThread : CREATE_THREAD_DEBUG_INFO64 );
                 2 : ( CreateProcessInfo : CREATE_PROCESS_DEBUG_INFO64 );
                 3 : ( ExitThread : EXIT_THREAD_DEBUG_INFO64 );
                 4 : ( ExitProcess : EXIT_PROCESS_DEBUG_INFO64 );
                 5 : ( LoadDll : LOAD_DLL_DEBUG_INFO64 );
                 6 : ( UnloadDll : UNLOAD_DLL_DEBUG_INFO64 );
                 7 : ( DebugString : OUTPUT_DEBUG_STRING_INFO64 );
                 8 : ( RipInfo : RIP_INFO64 );
  end;
  DEBUG_EVENT64 = _DEBUG_EVENT64;
  LPDEBUG_EVENT64 = ^_DEBUG_EVENT64;

  ParamDebugActiveProcess = record
    dwProcessId: DWORD;
    flags: dword;
  end;
  ParamWaitForDebugEvent = record
    DebugEvent: DEBUG_EVENT64;
    dwMilliseconds: DWORD;
    dwProcessId: DWORD;
    flags: dword;
    OK:	boolean;
  end;
  ParamContinueDebugEvent = record
    dwProcessId: DWORD ;
    dwThreadId: DWORD ;
    dwContinueStatus: DWORD;
    flags: dword;
    OK: BOOLEAN;
  end;

  ParamBreakPoint = record
    processid: DWORD;
    address: ULONG64;
    size: DWORD;
    active: bool;
  end;

  InputOutputData64 = record
      case longint of
      0: (DebugActiveProcessParams: ParamDebugActiveProcess);
      1: (WaitForDebugEventParams: ParamWaitForDebugEvent);
      2: (ContinueDebugEventParams: ParamContinueDebugEvent);
      3: (BreakPoint: ParamBreakPoint);
      4: (all: array[0..($1000)-1] of char);
  end;


type Stowaway = class
  StowawayProcessId: DWORD;
  hdevice: HANDLE;
  public
  function DebugActiveProcess(ProcessId: DWORD): BOOL;
  function ContinueDebugEvent(dwProcessId: DWORD; dwThreadId: DWORD; dwContinueStatus: DWORD): BOOL;
  function WaitForDebugEvent(var lpDebugEvent: DEBUG_EVENT; dwMilliseconds: DWORD): BOOL;
  function DDYDebugEvent64ToTargetPlatform(var lpDebugEvent: DEBUG_EVENT; data: InputOutputData64): BOOL;
  function initdebug():BOOL;

  function SetBreakPoint(address: DWORD64;size: DWORD; processid:DWORD): BOOL;
  function UnSetBreakPoint(address: DWORD64;size: DWORD; processid:DWORD): BOOL;
  end;

var
  stw: Stowaway;




implementation

{ TLogin }
function Stowaway.SetBreakPoint(address: DWORD64;size: DWORD; processid:DWORD): BOOL;
var
data:  InputOutputData64;
retsize: dword;
begin
     ZeroMemory(@data,sizeof(InputOutputData64));
     data.BreakPoint.processid :=processid;
     data.BreakPoint.address := address;
     data.BreakPoint.size := size;
     DeviceIoControl(hdevice,DebugSetBreakPoint, @data,sizeof(InputOutputData64), @data , sizeof(InputOutputData64),retsize,nil);
     result:= true;
end;
function Stowaway.UnSetBreakPoint(address: DWORD64;size: DWORD; processid:DWORD): BOOL;
var
data:  InputOutputData64;
retsize: dword;
begin
     ZeroMemory(@data,sizeof(InputOutputData64));
     data.BreakPoint.processid :=processid;
     data.BreakPoint.address := address;
     data.BreakPoint.size := size;
     DeviceIoControl(hdevice,DebugRemoveBreakPoint, @data,sizeof(InputOutputData64), @data , sizeof(InputOutputData64),retsize,nil);
     result:= true;
end;

function Stowaway.initdebug():BOOL;
begin
    if   hdevice=0 then
    begin
         hdevice := CreateFile(pchar(DEVICE_LINK_NAME),
          GENERIC_READ or GENERIC_WRITE,
          FILE_SHARE_READ or FILE_SHARE_WRITE,
          nil,
          OPEN_EXISTING,
          FILE_FLAG_OVERLAPPED,
          0);
         //outputdebugstring(pchar(format('error: %d',[getlasterror])));
    end;
    result:= true;
end;

function Stowaway.DebugActiveProcess(ProcessId: DWORD): BOOL;
var
  data:  InputOutputData64;
  retsize: dword;
begin
     ZeroMemory(@data,sizeof(InputOutputData64));
     StowawayProcessId:=ProcessId;
     data.DebugActiveProcessParams.dwProcessId:=ProcessId;
     data.DebugActiveProcessParams.flags := 0;
     DeviceIoControl(hdevice,PROCESS_DebugActiveProcess, @data,sizeof(InputOutputData64), @data , sizeof(InputOutputData64),retsize,nil);
     result:= true;
end;

function Stowaway.ContinueDebugEvent(dwProcessId: DWORD; dwThreadId: DWORD; dwContinueStatus: DWORD): BOOL;
var
  data:   InputOutputData64;
  retsize: dword;
begin
  ZeroMemory(@data,sizeof(InputOutputData64));
  data.ContinueDebugEventParams.dwProcessId:= dwProcessId;
  data.ContinueDebugEventParams.dwThreadId:= dwThreadId;
  data.ContinueDebugEventParams.dwContinueStatus:= dwContinueStatus;
  data.ContinueDebugEventParams.flags := 0;
  DeviceIoControl(hdevice,PROCESS_ContinueDebugEvent, @data,sizeof(InputOutputData64), @data , sizeof(InputOutputData64),retsize,nil);
  result:= data.ContinueDebugEventParams.OK;
end;

function Stowaway.WaitForDebugEvent(var lpDebugEvent: DEBUG_EVENT; dwMilliseconds: DWORD): BOOL;
var
  data:  InputOutputData64;
  retsize: dword;
begin
  ZeroMemory(@data,sizeof(InputOutputData64));
  data.WaitForDebugEventParams.dwProcessId:= StowawayProcessId;
  data.WaitForDebugEventParams.dwMilliseconds:=dwMilliseconds;
  data.WaitForDebugEventParams.flags := 0;
  DeviceIoControl(hdevice,PROCESS_WaitForDebugEvent, @data,sizeof(InputOutputData64), @data , sizeof(InputOutputData64),retsize,nil);
  DDYDebugEvent64ToTargetPlatform(lpDebugEvent,data);
  Sleep(50);
  result:= data.WaitForDebugEventParams.OK;
end;

function Stowaway.DDYDebugEvent64ToTargetPlatform(var lpDebugEvent: DEBUG_EVENT; data: InputOutputData64): BOOL;
var
  i: integer;
begin
        lpDebugEvent.dwDebugEventCode := data.WaitForDebugEventParams.DebugEvent.dwDebugEventCode;
        //outputdebugstring(pchar(format('lpDebugEvent.dwDebugEventCode = %d',[lpDebugEvent.dwDebugEventCode])));
	lpDebugEvent.dwProcessId := data.WaitForDebugEventParams.DebugEvent.dwProcessId;
        //outputdebugstring(pchar(format('lpDebugEvent.dwProcessId = %d',[lpDebugEvent.dwProcessId])));
	lpDebugEvent.dwThreadId := data.WaitForDebugEventParams.DebugEvent.dwThreadId;
        //outputdebugstring(pchar(format('lpDebugEvent.dwThreadId = %d',[lpDebugEvent.dwThreadId])));
        case lpDebugEvent.dwDebugEventCode of
          EXCEPTION_DEBUG_EVENT:
          begin
                lpDebugEvent.Exception.dwFirstChance := data.WaitForDebugEventParams.DebugEvent.Exception.dwFirstChance;
		lpDebugEvent.Exception.ExceptionRecord.ExceptionAddress  :=  pointer(data.WaitForDebugEventParams.DebugEvent.Exception.ExceptionRecord.ExceptionAddress);
		lpDebugEvent.Exception.ExceptionRecord.ExceptionCode := data.WaitForDebugEventParams.DebugEvent.Exception.ExceptionRecord.ExceptionCode;
		lpDebugEvent.Exception.ExceptionRecord.ExceptionFlags := data.WaitForDebugEventParams.DebugEvent.Exception.ExceptionRecord.ExceptionFlags;
                for i:= 0 to EXCEPTION_MAXIMUM_PARAMETERS-1 do
                begin
                    lpDebugEvent.Exception.ExceptionRecord.ExceptionInformation[i]  := data.WaitForDebugEventParams.DebugEvent.Exception.ExceptionRecord.ExceptionInformation[i];
                end;
                lpDebugEvent.Exception.ExceptionRecord.ExceptionRecord  :=  pointer(data.WaitForDebugEventParams.DebugEvent.Exception.ExceptionRecord.ExceptionRecord);
		lpDebugEvent.Exception.ExceptionRecord.NumberParameters  :=  data.WaitForDebugEventParams.DebugEvent.Exception.ExceptionRecord.NumberParameters;
          end;

	  CREATE_THREAD_DEBUG_EVENT:
          begin
		lpDebugEvent.CreateThread.hThread  :=  HANDLE(data.WaitForDebugEventParams.DebugEvent.CreateThread.hThread);
		lpDebugEvent.CreateThread.lpStartAddress  :=  LPTHREAD_START_ROUTINE(data.WaitForDebugEventParams.DebugEvent.CreateThread.lpStartAddress);
		lpDebugEvent.CreateThread.lpThreadLocalBase  := LPVOID(data.WaitForDebugEventParams.DebugEvent.CreateThread.lpThreadLocalBase);
          end;
	 CREATE_PROCESS_DEBUG_EVENT:
	 begin

		lpDebugEvent.CreateProcessInfo.dwDebugInfoFileOffset  :=  data.WaitForDebugEventParams.DebugEvent.CreateProcessInfo.dwDebugInfoFileOffset;
		lpDebugEvent.CreateProcessInfo.fUnicode  :=  data.WaitForDebugEventParams.DebugEvent.CreateProcessInfo.fUnicode;
		lpDebugEvent.CreateProcessInfo.hFile  :=  HANDLE(data.WaitForDebugEventParams.DebugEvent.CreateProcessInfo.hFile);
		lpDebugEvent.CreateProcessInfo.hProcess  :=  HANDLE(data.WaitForDebugEventParams.DebugEvent.CreateProcessInfo.hProcess);
		lpDebugEvent.CreateProcessInfo.hThread  :=  HANDLE(data.WaitForDebugEventParams.DebugEvent.CreateProcessInfo.hThread);
		lpDebugEvent.CreateProcessInfo.lpBaseOfImage  :=  LPVOID(data.WaitForDebugEventParams.DebugEvent.CreateProcessInfo.lpBaseOfImage);
		lpDebugEvent.CreateProcessInfo.lpStartAddress  :=  LPTHREAD_START_ROUTINE(data.WaitForDebugEventParams.DebugEvent.CreateProcessInfo.lpStartAddress);
		lpDebugEvent.CreateProcessInfo.lpThreadLocalBase  :=  LPVOID(data.WaitForDebugEventParams.DebugEvent.CreateProcessInfo.lpThreadLocalBase);
		lpDebugEvent.CreateProcessInfo.nDebugInfoSize  :=  data.WaitForDebugEventParams.DebugEvent.CreateProcessInfo.nDebugInfoSize;
	end;
	EXIT_THREAD_DEBUG_EVENT:
        begin
		lpDebugEvent.ExitThread.dwExitCode  :=  data.WaitForDebugEventParams.DebugEvent.ExitThread.dwExitCode;
	end;
	EXIT_PROCESS_DEBUG_EVENT:
        begin
		lpDebugEvent.ExitProcess.dwExitCode  :=  data.WaitForDebugEventParams.DebugEvent.ExitProcess.dwExitCode;
	end;
	LOAD_DLL_DEBUG_EVENT:
        begin
		lpDebugEvent.LoadDll.dwDebugInfoFileOffset  :=  data.WaitForDebugEventParams.DebugEvent.LoadDll.dwDebugInfoFileOffset;
		lpDebugEvent.LoadDll.fUnicode  :=  data.WaitForDebugEventParams.DebugEvent.LoadDll.fUnicode;
		lpDebugEvent.LoadDll.hFile  :=  HANDLE(data.WaitForDebugEventParams.DebugEvent.LoadDll.hFile);
		lpDebugEvent.LoadDll.lpBaseOfDll  :=  LPVOID(data.WaitForDebugEventParams.DebugEvent.LoadDll.lpBaseOfDll);
		lpDebugEvent.LoadDll.lpImageName  :=  LPVOID(data.WaitForDebugEventParams.DebugEvent.LoadDll.lpImageName);
		lpDebugEvent.LoadDll.nDebugInfoSize  :=  data.WaitForDebugEventParams.DebugEvent.LoadDll.nDebugInfoSize;
        end;
	UNLOAD_DLL_DEBUG_EVENT:
        begin
             lpDebugEvent.UnloadDll.lpBaseOfDll   :=  LPVOID(data.WaitForDebugEventParams.DebugEvent.unloadDll.lpBaseOfDll);
        end;
	OUTPUT_DEBUG_STRING_EVENT:
        begin
		lpDebugEvent.DebugString.fUnicode  :=  data.WaitForDebugEventParams.DebugEvent.DebugString.fUnicode;
		lpDebugEvent.DebugString.lpDebugStringData  :=  LPSTR(data.WaitForDebugEventParams.DebugEvent.DebugString.lpDebugStringData);
		lpDebugEvent.DebugString.nDebugStringLength  :=  data.WaitForDebugEventParams.DebugEvent.DebugString.nDebugStringLength;
        end;
	 RIP_EVENT:
         begin
		lpDebugEvent.RipInfo.dwError  :=  data.WaitForDebugEventParams.DebugEvent.RipInfo.dwError;
		lpDebugEvent.RipInfo.dwType  := data.WaitForDebugEventParams.DebugEvent.RipInfo.dwType;
         end;

         end;
end;

initialization


end.




