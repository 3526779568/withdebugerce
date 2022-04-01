unit networkInterfaceApi;

{$mode objfpc}{$H+}

interface

uses
  {$ifdef JNI}
    Classes, SysUtils, networkinterface, unixporthelper, newkernelhandler;
  {$else}
  {jwawindows,} windows, Classes, SysUtils, networkinterface, newkernelhandler, CEFuncProc;
  {$endif}


procedure InitializeNetworkInterface;
function getConnection: TCEConnection;
procedure disconnect;

function NetworkVersion(var name: string): integer;

function NetworkReadProcessMemory(hProcess: THandle; lpBaseAddress, lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesRead: ptruint): BOOL; stdcall;
function NetworkWriteProcessMemory(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesWritten: ptruint): BOOL; stdcall;

function NetworkVirtualQueryEx(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD): DWORD; stdcall;
function NetworkOpenProcess(dwDesiredAccess:DWORD; bInheritHandle:WINBOOL; dwProcessId:DWORD):HANDLE; stdcall;
function NetworkCreateToolhelp32Snapshot(dwFlags, th32ProcessID: DWORD): HANDLE; stdcall;
function NetworkProcess32First(hSnapshot: HANDLE; var lppe: PROCESSENTRY32): BOOL; stdcall;
function NetworkProcess32Next(hSnapshot: HANDLE; var lppe: PROCESSENTRY32): BOOL; stdcall;

function NetworkModule32First(hSnapshot: HANDLE; var lpme: MODULEENTRY32): BOOL; stdcall;
function NetworkModule32Next(hSnapshot: HANDLE; var lpme: MODULEENTRY32): BOOL; stdcall;

function NetworkCloseHandle(handle: THandle):WINBOOL; stdcall;
function NetworkSetBreakpoint(handle: THandle; threadid: integer; debugregister: integer; address: PtrUInt; bptype: integer; bpsize: integer): boolean;
function NetworkRemoveBreakpoint(handle: THandle; threadid: integer; debugregister: integer; wasWatchpoint: boolean): boolean;

function NetworkGetRegionInfo(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD; var mapsline: string): DWORD; stdcall;

implementation

{$ifndef jni}
uses networkConfig;
{$endif}

resourcestring
  rsNoConnection = 'No connection';

threadvar connection: TCEConnection;


var threadManagerIsHooked: boolean=false;
    oldendthread: TEndThreadHandler;

function getConnection: TCEConnection;
begin
  //OutputDebugString('getConnection');
  result:=nil;

  if {$ifndef jni}networkconfig.{$endif}host.s_addr<>0 then
  begin
    //OutputDebugString('Valid host');
    if (connection=nil) or (not connection.connected) then
    begin
      OutputDebugString('connection=nil. creating');
      disconnect;

      connection:=TCEConnection.create;
      if connection.connected then
        result:=connection
      else
        OutputDebugString('connection.connected=false');

    end
    else
    begin
      //OutputDebugString('Already connected');
      result:=connection;
    end;

  end;
end;

procedure disconnect;
begin
  if connection<>nil then
    freeandnil(connection);
end;

function NetworkCloseHandle(handle: THandle):WINBOOL; stdcall;
begin
  if getConnection<>nil then
    result:=connection.CloseHandle(handle)
  else
    result:=false;
end;

function NetworkVirtualQueryEx_StartCache(hProcess: THandle; flags: dword): boolean;
begin
  if getConnection<>nil then
    result:=connection.VirtualQueryEx_StartCache(hProcess, flags)
  else
    result:=false;
end;

procedure NetworkVirtualQueryEx_EndCache(hProcess: THandle);
begin
  if getConnection<>nil then
    connection.VirtualQueryEx_EndCache(hProcess);
end;

function NetworkProcess32Next(hSnapshot: HANDLE; var lppe: PROCESSENTRY32): BOOL; stdcall;
begin
  if getConnection<>nil then
    result:=connection.Process32Next(hSnapshot, lppe)
  else
    result:=FALSE;
end;

function NetworkProcess32First(hSnapshot: HANDLE; var lppe: PROCESSENTRY32): BOOL; stdcall;
begin
  OutputDebugString('NetworkProcess32First');
  if getConnection<>nil then
    result:=connection.Process32First(hSnapshot, lppe)
  else
    result:=FALSE;
end;

function NetworkModule32Next(hSnapshot: HANDLE; var lpme: MODULEENTRY32): BOOL; stdcall;
begin
  if getConnection<>nil then
    result:=connection.Module32Next(hSnapshot, lpme)
  else
    result:=FALSE;
end;

function NetworkModule32First(hSnapshot: HANDLE; var lpme: MODULEENTRY32): BOOL; stdcall;
begin
  if getConnection<>nil then
    result:=connection.Module32First(hSnapshot, lpme)
  else
    result:=FALSE;
end;

function NetworkCreateToolhelp32Snapshot(dwFlags, th32ProcessID: DWORD): HANDLE; stdcall;
begin
  if getConnection<>nil then
    result:=connection.CreateToolhelp32Snapshot(dwflags, th32ProcessId)
  else
    result:=INVALID_HANDLE_VALUE;
end;

function NetworkSetBreakpoint(handle: THandle; threadid: integer; debugregister: integer; address: PtrUInt; bptype: integer; bpsize: integer): boolean;
begin
  if getConnection<>nil then
    result:=connection.SetBreakpoint(handle, threadid, debugregister, address, bptype, bpsize)
  else
    result:=FALSE;
end;

function NetworkRemoveBreakpoint(handle: THandle; threadid: integer; debugregister: integer; wasWatchpoint: boolean): boolean;
begin
  if getConnection<>nil then
    result:=connection.RemoveBreakpoint(handle, threadid, debugregister, wasWatchpoint)
  else
    result:=FALSE;
end;

function NetworkReadProcessMemory(hProcess: THandle; lpBaseAddress, lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesRead: ptruint): BOOL; stdcall;
var a,b: dword;
    c,d: ptruint;
begin
  //log('NetworkReadProcessMemory');
  //log(format('Read %d bytes from %p into %p',[nsize, lpBaseAddress, lpBuffer]));

  if getConnection<>nil then
  begin
   // log('Has connection');

    result:=connection.readProcessMemory(hProcess, lpBaseAddress, lpBuffer, nSize, lpNumberOfBytesRead);
    if (result=false) and (connection.connected=false) and (getConnection<>nil) then //try again one more time
    begin
    //  log('read fail1. Try smaller chunk');

      //try a smaller chunk
      a:=nsize div 2;
      b:=nsize-a;
      c:=0;
      d:=0;

      //log('a='+inttostr(a));
     // log('b='+inttostr(b));

      result:=connection.readProcessMemory(hProcess, lpBaseAddress, lpBuffer, a, c);

     // log('after read 1/2');

      if result and (b>0) and (c>0) then //first read succesful, there is something else to read, and it actually has read
      begin
        result:=connection.readProcessMemory(hProcess, pointer(ptruint(lpBaseAddress)+a), pointer(ptruint(lpBuffer)+a), b, d);
       // log('after read 2/2');
      end;

      if @lpNumberOfBytesRead<>nil then
        lpNumberOfBytesRead:=c+d;
    end;


  end
  else
    result:=false;

  //log('Returning from rpm');
end;

function NetworkWriteProcessMemory(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesWritten: ptruint): BOOL; stdcall;
begin
  if getConnection<>nil then
    result:=connection.writeProcessMemory(hProcess, lpBaseAddress, lpBuffer, nSize, lpNumberOfBytesWritten)
  else
    result:=false;
end;


function NetworkGetRegionInfo(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD; var mapsline: string): DWORD; stdcall;
begin
  if getConnection<>nil then
    result:=connection.GetRegionInfo(hProcess, lpAddress, lpBuffer, dwLength, mapsline)
  else
    result:=0;
end;

function NetworkVirtualQueryEx(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD): DWORD; stdcall;
begin
  if getConnection<>nil then
    result:=connection.VirtualQueryEx(hProcess, lpAddress, lpBuffer, dwLength)
  else
    result:=0;
end;

function NetworkVirtualAllocEx(hProcess: THandle; lpAddress: Pointer; dwSize, flAllocationType: DWORD; flProtect: DWORD): Pointer; stdcall;
begin
  if getconnection<>nil then
    result:=connection.VirtualAllocEx(hProcess, lpAddress, dwSize, flAllocationType, flProtect)
  else
    result:=nil;
end;

function NetworkVirtualFreeEx(hProcess: HANDLE; lpAddress: LPVOID; dwSize: SIZE_T; dwFreeType: DWORD): BOOL; stdcall;
begin
  if getconnection<>nil then
    result:=connection.VirtualFreeEx(hProcess, lpAddress, dwSize, dwFreeType)
  else
    result:=FALSE;
end;

function NetworkCreateRemoteThread(hProcess: THandle; lpThreadAttributes: Pointer; dwStackSize: DWORD; lpStartAddress: TFNThreadStartRoutine; lpParameter: Pointer;  dwCreationFlags: DWORD; var lpThreadId: DWORD): THandle; stdcall;
begin
  if getconnection<>nil then
    result:=connection.CreateRemoteThread(hProcess, lpThreadAttributes, dwStackSize, lpStartAddress, lpParameter, dwCreationFlags, lpThreadId)
  else
    result:=0;
end;

function NetworkOpenProcess(dwDesiredAccess:DWORD; bInheritHandle:WINBOOL; dwProcessId:DWORD):HANDLE; stdcall;
begin
  if getConnection<>nil then
    result:=connection.OpenProcess(dwDesiredAccess, bInheritHandle, dwProcessId)
  else
    result:=0;
end;

function NetworkVersion(var name: string): integer;
begin
  if getConnection<>nil then
    result:=connection.getVersion(name)
  else
  begin
    result:=-1;
    name:=rsNoConnection;
  end;
end;

Procedure EndThread(ExitCode : DWord); //called when a thread is terminated
begin
  if connection<>nil then
    freeandnil(connection);

  oldendthread(ExitCode);
end;

function NetworkVirtualProtectEx(hProcess: THandle; lpAddress: Pointer; dwSize, flNewProtect: DWORD; var OldProtect: DWORD): BOOL; stdcall;
begin
  //for now don't bother with this
  //todo: implement this someday
  result:=true;
end;

procedure InitializeNetworkInterface;
var tm: TThreadManager;
begin
  //hook the threadmanager if it hasn't been hooked yet
  OutputDebugString('InitializeNetworkInterface');

  if not threadManagerIsHooked then
  begin
    GetThreadManager(tm);

    oldendthread:=tm.EndThread;
    tm.EndThread:=@EndThread;

    SetThreadManager(tm);

    threadManagerIsHooked:=true;
  end;

  newkernelhandler.OpenProcess:=@NetworkOpenProcess;
  newkernelhandler.ReadProcessMemory:=@NetworkReadProcessMemory;
  newkernelhandler.WriteProcessMemoryActual:=@NetworkWriteProcessMemory;
  newkernelhandler.VirtualProtectEx:=@NetworkVirtualProtectEx;
  newkernelhandler.VirtualQueryEx:=@NetworkVirtualQueryEx;
  newkernelhandler.CreateToolhelp32Snapshot:=@NetworkCreateToolhelp32Snapshot;
  newkernelhandler.Process32First:=@NetworkProcess32First;
  newkernelhandler.Process32Next:=@NetworkProcess32Next;
  newkernelhandler.Module32First:=@NetworkModule32First;
  newkernelhandler.Module32Next:=@NetworkModule32Next;
  newkernelhandler.closehandle:=@networkclosehandle;

  newkernelhandler.VirtualAllocEx:=@networkVirtualAllocEx;
  newkernelhandler.VirtualFreeEx:=@networkVirtualFreeEx;
  newkernelhandler.CreateRemoteThread:=@networkCreateRemoteThread;

  newkernelhandler.GetRegionInfo:=@NetworkGetRegionInfo;



  newkernelhandler.VirtualQueryEx_StartCache:=@NetworkVirtualQueryEx_StartCache;
  newkernelhandler.VirtualQueryEx_EndCache:=@NetworkVirtualQueryEx_EndCache;


end;

end.

