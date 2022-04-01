unit networkInterface;

{$mode objfpc}{$H+}

//playing arround with the objfpc notation. The pointer based arrays look interesting

interface

uses
  {$ifdef JNI}
  Classes, SysUtils, Sockets, resolve, ctypes,syncobjs, math, zstream,
  newkernelhandler, unixporthelper, processhandlerunit, gutil, gmap,VirtualQueryExCache;
  {$else}
  jwawindows, windows, Classes, SysUtils, Sockets, resolve, ctypes, networkconfig,
  cefuncproc, newkernelhandler, math, zstream, syncobjs, processhandlerunit,
  VirtualQueryExCache, gutil, gmap;
  {$endif}



{$ifdef jni}
const networkcompression=0;
{$endif}


type

  TNetworkDebugEvent=packed record
    signal: integer;
    threadid: qword;
    case integer of
      -2: (//create process
      createProcess: packed record
        maxBreakpointCount: uint8;
        maxWatchpointCount: uint8;
        maxSharedBreakpoints: uint8;
      end; );
      5: (address: qword;  );
  end;

  TNetworkEnumSymCallback=function(modulename: string; symbolname: string; address: ptruint; size: integer; secondary: boolean ): boolean of object;

  TVQEMapCmp = specialize TLess<PtrUInt>;
  TVQEMap = specialize TMap<PtrUInt, TVirtualQueryExCache, TVQEMapCmp>;

  TCEConnection=class
  private
    socket: cint;
    fConnected: boolean;

    //todo: change rpmcache to a map
    rpmcache: array [0..15] of record //every connection is thread specific, so each thread has it's own rpmcache
        lastupdate: TLargeInteger; //contains the last time this page was updated
        baseaddress: PtrUInt;
        memory: array [0..4095] of byte;
      end;

    WriteProcessMemoryBufferCount: integer; //to deal with recursive calls
    WriteProcessMemoryBuffer: array of record
        processhandle: thandle;
        baseaddress: PtrUInt;
        memory: array of byte;
    end;
    WriteProcessMemoryBufferCS: TCriticalSection;


    VirtualQueryExCacheMap: TVQEMap;
    VirtualQueryExCacheMapCS: TCriticalSection;


    function receive(buffer: pointer; size: integer): integer;
    function send(buffer: pointer; size: integer): integer;

    function CReadProcessMemory(hProcess: THandle; lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesRead: PTRUINT): BOOL;
    function NReadProcessMemory(hProcess: THandle; lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesRead: PTRUINT): BOOL;



  public
    function isNetworkHandle(handle: THandle): boolean;

    function Module32Next(hSnapshot: HANDLE; var lpme: MODULEENTRY32; isfirst: boolean=false): BOOL;
    function Module32First(hSnapshot: HANDLE; var lpme: MODULEENTRY32): BOOL;

    function Process32Next(hSnapshot: HANDLE; var lppe: PROCESSENTRY32; isfirst: boolean=false): BOOL;
    function Process32First(hSnapshot: HANDLE; var lppe: PROCESSENTRY32): BOOL;
    function CreateToolhelp32Snapshot(dwFlags, th32ProcessID: DWORD): HANDLE;
    function CloseHandle(handle: THandle):WINBOOL;
    function OpenProcess(dwDesiredAccess:DWORD; bInheritHandle:WINBOOL; dwProcessId:DWORD):HANDLE;
    function CreateRemoteThread(hProcess: THandle; lpThreadAttributes: Pointer; dwStackSize: DWORD; lpStartAddress: TFNThreadStartRoutine; lpParameter: Pointer;  dwCreationFlags: DWORD; var lpThreadId: DWORD): THandle;
    function VirtualAllocEx(hProcess: THandle; lpAddress: Pointer; dwSize, flAllocationType: DWORD; flProtect: DWORD): Pointer;
    function VirtualFreeEx(hProcess: HANDLE; lpAddress: LPVOID; dwSize: SIZE_T; dwFreeType: DWORD): BOOL;
    function VirtualQueryEx(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD): DWORD;
    function VirtualQueryEx_StartCache(hProcess: THandle; flags: DWORD): boolean;
    procedure VirtualQueryEx_EndCache(hProcess: THandle);

    function GetRegionInfo(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD; var mapsline: string): DWORD;

    function ReadProcessMemory(hProcess: THandle; lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesRead: PTRUINT): BOOL;
    function WriteProcessMemory(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesWritten: PTRUINT): BOOL;
    procedure beginWriteProcessMemory;
    function endWriteProcessMemory: boolean;

    function StartDebug(hProcess: THandle): BOOL;
    function WaitForDebugEvent(hProcess: THandle; timeout: integer; var devent: TNetworkDebugEvent):BOOL;
    function ContinueDebugEvent(hProcess: THandle; threadid: dword; continuemethod: integer): BOOL;
    function SetBreakpoint(hProcess: THandle; threadid: integer; debugregister: integer; address: PtrUInt; bptype: integer; bpsize: integer): boolean;
    function RemoveBreakpoint(hProcess: THandle; threadid: integer; debugregister: integer; wasWatchpoint: boolean): boolean;
    function AllocateAndGetContext(hProcess: Thandle; threadid: integer): pointer;
    function getVersion(var name: string): integer;
    function getArchitecture: integer;
    function enumSymbolsFromFile(modulepath: string; modulebase: ptruint; callback: TNetworkEnumSymCallback): boolean;
    function loadModule(hProcess: THandle; modulepath: string): boolean;
    function loadExtension(hProcess: Thandle): boolean;
    function speedhack_setSpeed(hProcess: THandle; speed: single): boolean;

    procedure TerminateServer;

    property connected: boolean read fConnected;

    constructor create;
    destructor destroy; override;
  end;


{$ifdef jni}
var
  host: THostAddr;
  port: integer;

{$endif}

implementation

uses elfsymbols, Globals;

const
  CMD_GETVERSION =0;
  CMD_CLOSECONNECTION= 1;
  CMD_TERMINATESERVER= 2;
  CMD_OPENPROCESS= 3;
  CMD_CREATETOOLHELP32SNAPSHOT =4;
  CMD_PROCESS32FIRST= 5;
  CMD_PROCESS32NEXT= 6;
  CMD_CLOSEHANDLE=7;
  CMD_VIRTUALQUERYEX=8;
  CMD_READPROCESSMEMORY=9;
  CMD_WRITEPROCESSMEMORY=10;
  CMD_STARTDEBUG=11;
  CMD_STOPDEBUG=12;
  CMD_WAITFORDEBUGEVENT=13;
  CMD_CONTINUEFROMDEBUGEVENT=14;
  CMD_SETBREAKPOINT=15;
  CMD_REMOVEBREAKPOINT=16;
  CMD_SUSPENDTHREAD=17;
  CMD_RESUMETHREAD=18;
  CMD_GETTHREADCONTEXT=19;
  CMD_SETTHREADCONTEXT=20;
  CMD_GETARCHITECTURE=21;
  CMD_MODULE32FIRST=22;
  CMD_MODULE32NEXT=23;

  CMD_GETSYMBOLLISTFROMFILE=24;

  CMD_LOADEXTENSION=25;
  CMD_ALLOC=26;
  CMD_FREE=27;
  CMD_CREATETHREAD=28;
  CMD_LOADMODULE=29;
  CMD_SPEEDHACK_SETSPEED=30;

  //
  CMD_VIRTUALQUERYEXFULL=31;
  CMD_GETREGIONINFO=32; //extended version of VirtualQueryEx which also get the full string


procedure TCEConnection.TerminateServer;
var command: byte;
begin
  command:=CMD_TERMINATESERVER;
  send(@command, sizeof(command));
end;




function TCEConnection.CloseHandle(handle: THandle):WINBOOL;
var CloseHandleCommand: packed record
    command: byte;
    handle: dword;
  end;

  r: integer;
begin


  if ((handle shr 24) and $ff)= $ce then
  begin
    CloseHandleCommand.command:=CMD_CLOSEHANDLE;
    CloseHandleCommand.handle:=handle and $ffffff;
    send(@CloseHandleCommand, sizeof(CloseHandleCommand));

    receive(@r,sizeof(r));
    result:=true;
  end
  {$ifdef windows}
  else //not a network handle
    result:=windows.CloseHandle(handle)
  {$endif};
end;

function TCEConnection.Module32Next(hSnapshot: HANDLE; var lpme: MODULEENTRY32; isfirst: boolean=false): BOOL;
var ModulelistCommand: packed record
    command: byte;
    handle: dword;
  end;

  r: packed record
    result: integer;
    modulebase: qword;
    modulesize: dword;
    stringlength: dword;
  end;

  mname: pchar;

begin

  result:=false;

  if ((hSnapshot shr 24) and $ff)= $ce then
  begin
    if isfirst then
      ModulelistCommand.command:=CMD_MODULE32FIRST
    else
      ModulelistCommand.command:=CMD_MODULE32NEXT;

    ModulelistCommand.handle:=hSnapshot and $ffffff;
    if send(@ModulelistCommand, sizeof(ModulelistCommand)) > 0 then
    begin
      if receive(@r, sizeof(r))>0 then
      begin
        result:=r.result<>0;

        if result then
        begin //it has a string
          getmem(mname, r.stringlength+1);
          receive(mname, r.stringlength);
          mname[r.stringlength]:=#0;

          ZeroMemory(@lpme, sizeof(lpme));
          lpme.hModule:=r.modulebase;
          lpme.modBaseAddr:=pointer(r.modulebase);
          lpme.modBaseSize:=r.modulesize;
          copymemory(@lpme.szExePath[0], mname, min(r.stringlength+1, MAX_PATH));
          lpme.szExePath[MAX_PATH-1]:=#0;

          copymemory(@lpme.szModule[0], mname, min(r.stringlength+1, MAX_MODULE_NAME32));
          lpme.szModule[MAX_MODULE_NAME32-1]:=#0;

          freemem(mname);
        end;

      end;
    end;
  end;

end;

function TCEConnection.Module32First(hSnapshot: HANDLE; var lpme: MODULEENTRY32): BOOL;
begin
  result:=module32next(hSnapshot, lpme, true);
end;

function TCEConnection.Process32Next(hSnapshot: HANDLE; var lppe: PROCESSENTRY32; isfirst: boolean=false): BOOL;
var ProcesslistCommand: packed record
    command: byte;
    handle: dword;
  end;

  r: packed record
    result: integer;
    pid: dword;
    stringlength: dword;
  end;

  pname: pchar;

begin
  result:=false;

  //OutputDebugString('TCEConnection.Process32Next');
  if ((hSnapshot shr 24) and $ff)= $ce then
  begin
    //OutputDebugString('Valid network handle');

    if isfirst then
      ProcesslistCommand.command:=CMD_PROCESS32FIRST
    else
      ProcesslistCommand.command:=CMD_PROCESS32NEXT;

    ProcesslistCommand.handle:=hSnapshot and $ffffff;
    if send(@ProcesslistCommand, sizeof(ProcesslistCommand)) > 0 then
    begin
      if receive(@r, sizeof(r))>0 then
      begin
        result:=r.result<>0;

        if result then
        begin //it has a string
          getmem(pname, r.stringlength+1);
          receive(pname, r.stringlength);
          pname[r.stringlength]:=#0;

          ZeroMemory(@lppe, sizeof(lppe));
          lppe.th32ProcessID:=r.pid;


          CopyMemory(@lppe.szExeFile[0], pname, min(r.stringlength+1, MAX_PATH));
          lppe.szExeFile[MAX_PATH-1]:=#0;

          freemem(pname);
        end;

      end;
    end;
  end;
end;

function TCEConnection.Process32First(hSnapshot: HANDLE; var lppe: PROCESSENTRY32): BOOL;
begin
  OutputDebugString('TCEConnection.Process32First');
  result:=process32next(hSnapshot, lppe, true);
end;

function TCEConnection.CreateToolhelp32Snapshot(dwFlags, th32ProcessID: DWORD): HANDLE;
var CTSCommand: packed record
    command: byte;
    dwFlags: dword;
    th32ProcessID: dword;
  end;

var r: integer;
begin
  result:=0;

  OutputDebugString('TCEConnection.CreateToolhelp32Snapshot()');
  CTSCommand.command:=CMD_CREATETOOLHELP32SNAPSHOT;
  CTSCommand.dwFlags:=dwFlags;
  CTSCommand.th32ProcessID:=th32ProcessID;

  r:=0;
  if send(@CTSCommand, sizeof(CTSCommand))>0 then
    if receive(@r, sizeof(r))>0 then
    begin
      if (r>0) then
        r:=r or $ce000000;

      result:=r;
    end;
end;

function TCEConnection.CReadProcessMemory(hProcess: THandle; lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesRead: PTRUINT): BOOL;
//cached read process memory. Split up into pagechunks and check which pages need to be cached, and then read from the caches
type TPageInfo=record
    startaddress: ptruint;
    memory: pbyte;
  end;

var pages: array of TPageInfo;
  pagecount: ptruint;
  i,j: integer;

  oldest: integer;

  freq: tlargeinteger;
  currenttime: tlargeinteger;

  x: ptruint;
  blockoffset, blocksize: dword;
  currentbase: ptruint;
  currenttarget: ptruint;

  m: PByte;
begin
  //log(format('TCEConnection.CReadProcessMemory: Read %d bytes from %p into %p',[nsize, lpBaseAddress, lpBuffer]));


  result:=false;
  lpNumberOfBytesRead:=0;

  currenttarget:=ptruint(lpBaseAddress)+nsize-1;
  if currenttarget<ptruint(lpBaseAddress) then //overflow
  begin
    pagecount:=2+(currenttarget shr 12);
  end
  else
    pagecount:=1+((ptruint(lpBaseAddress)+nSize-1) shr 12) - (ptruint(lpBaseAddress) shr 12);

  setlength(pages, pagecount);

  QueryPerformanceFrequency(freq);
  QueryPerformanceCounter(currenttime);

  //if ptruint(lpBaseAddress)=$40000c then


  for i:=0 to pagecount-1 do
  begin
    pages[i].startaddress:=(ptruint(lpBaseAddress) and ptruint(not $fff)) + (i*4096);
    pages[i].memory:=nil;
    //find the mapped page, if not found, map it

    oldest:=0;




    for j:=0 to 15 do
    begin
      if rpmcache[j].baseaddress=pages[i].startaddress then
      begin
        //check if the page is too old
        if ((currenttime-rpmcache[j].lastupdate) / freq) > networkRPMCacheTimeout then //too old, refetch
          oldest:=i //so it gets reused
        else //not too old, can still be used
          pages[i].memory:=@rpmcache[j].memory[0];

        break;
      end;

      if (rpmcache[j].lastupdate<rpmcache[oldest].lastupdate) then
        oldest:=j;
    end;

    if pages[i].memory=nil then
    begin
      //map this page to the oldest entry
      pages[i].memory:=@(rpmcache[oldest].memory[0]);
      if not NReadProcessMemory(hProcess, pointer(pages[i].startaddress), pages[i].memory, 4096, x) then
      begin
        if i=0 then exit; //no need to continue, the start is unreadable
        pages[i].memory:=nil; //mark as unreadable, perhaps a few bytes can still be read
      end
      else
      begin
        rpmcache[oldest].lastupdate:=currenttime; //successful read
        rpmcache[oldest].baseaddress:=pages[i].startaddress;
      end;
    end;
  end;

  //all pages should be mapped now, so start copying till the end or till a nil map is encountered

  currentbase:=ptruint(lpbaseaddress);
  currenttarget:=ptruint(lpBuffer);
  for i:=0 to pagecount-1 do
  begin
    if pages[i].memory=nil then exit; //done

    m:=pbyte(pages[i].memory);

    //check what part of this page can be copied
    blockoffset:=currentbase and $fff; //start in this block
    blocksize:=min(nsize, 4096-blockoffset);

    CopyMemory(pointer(currenttarget), @m[blockoffset], blocksize);

    currentbase:=currentbase+blocksize; //next page
    currenttarget:=currenttarget+blocksize;
    lpNumberOfBytesRead:=lpNumberOfBytesRead+blocksize;

    nsize:=nsize-blocksize;
  end;

  result:=true; //everything got copied
end;

function TCEConnection.NReadProcessMemory(hProcess: THandle; lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesRead: PTRUINT): BOOL;
//Network read process memory
var
  input: packed record
    command: byte;
    handle: UINT32;
    baseaddress: UINT64;
    size: UINT32;
    compressed: UINT8;
  end;

  output: packed record
    bytesread: integer;
    //followed by the bytes
  end;

  compressedresult: packed record
    uncompressedsize: uint32;
    compressedsize: uint32;
  end;

  compressedbuffer: tmemorystream;
  d: Tdecompressionstream;
begin
  result:=false;
  lpNumberOfBytesRead:=0;

  //still here so not everything was cached
  input.command:=CMD_READPROCESSMEMORY;
  input.handle:=hProcess;
  input.baseaddress:=ptruint(lpBaseAddress);
  input.size:=nSize;
  if nsize>128 then
    input.compressed:=networkcompression
  else
    input.compressed:=0;

  if send(@input, sizeof(input))>0 then
  begin
    if input.compressed<>0 then
    begin
      if receive(@compressedresult, sizeof(compressedresult))>0 then
      begin
        compressedbuffer:=tmemorystream.create;
        try
          compressedbuffer.Size:=compressedresult.compressedsize;
          if receive(compressedbuffer.Memory, compressedresult.compressedsize)>0 then
          begin
            //decompress this
            d:=Tdecompressionstream.create(compressedbuffer, false);
            try
              d.ReadBuffer(lpbuffer^, compressedresult.uncompressedsize);
              result:=compressedresult.uncompressedsize>0;
              lpNumberOfBytesRead:=compressedresult.uncompressedsize;
            finally
              d.free;
            end;

          end;


        finally
          compressedbuffer.free;
        end;
      end;
    end
    else
    begin
      //not compressed
      if receive(@output, sizeof(output))>0 then
      begin
        if output.bytesread>0 then
        begin
          if receive(lpBuffer, output.bytesread)>0 then
          begin
            result:=true;
            lpNumberOfBytesRead:=output.bytesread;
          end;

        end;
      end;//else connection error
    end;
  end;
end;

function TCEConnection.ReadProcessMemory(hProcess: THandle; lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesRead: PTRUINT): BOOL;
begin
 // log(format('TCEConnection.ReadProcessMemory: Read %d bytes from %p into %p',[nsize, lpBaseAddress, lpBuffer]));


  if ((hProcess shr 24) and $ff)= $ce then
  begin
   // Log('hProcess is valid');

    result:=false;
    lpNumberOfBytesRead:=0;

    hProcess:=hProcess and $ffffff;

    if nsize=0 then exit;

    if (nsize<=8192) then
    begin
      //log('nsize<=8192. Calling CReadProcessMemory');
      result:=CReadProcessMemory(hProcess, lpBaseAddress, lpBuffer, nsize, lpNumberOfBytesRead);
    end
    else //just fetch it all from the net , ce usually does not fetch more than 8KB for random accesses, so would be a waste of time
    begin
     // log('nsize>8192. Calling NReadProcessMemory');
      result:=NReadProcessMemory(hProcess, lpBaseaddress, lpbuffer, nsize, lpNumberOfBytesRead);
    end;



  end
  {$ifdef windows}
  else
    result:=windows.ReadProcessMemory(hProcess, lpBaseAddress, lpBuffer, nSize, lpNumberOfBytesRead)
  {$endif};
end;

function TCEConnection.WriteProcessMemory(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesWritten: PTRUINT): BOOL;
type TWPMrecord=packed record
      command: byte;
      handle: integer;
      baseaddress: qword;
      size: integer;
      //buffer
    end;
    PWPMRecord=^TWPMRecord;
var
  input: PWPMrecord;
  i: pbyte;

  output: packed record
    byteswritten: integer;
    //followed by the bytes
  end;

  j,k: integer;

  b: ptruint;

begin
  WriteProcessMemoryBufferCS.enter;
  try

    if WriteProcessMemoryBufferCount=0 then
    begin
      if ((hProcess shr 24) and $ff)= $ce then
      begin
        result:=false;
        lpNumberOfBytesWritten:=0;

        input:=getmem(sizeof(TWPMRecord)+nSize);

        input^.command:=CMD_WRITEPROCESSMEMORY;
        input^.handle:=hProcess and $ffffff;
        input^.baseaddress:=ptruint(lpBaseAddress);
        input^.size:=nSize;

        CopyMemory(@input[1], lpBuffer, nSize);


        if send(input, sizeof(TWPMRecord)+nSize)>0 then
        begin
          if receive(@output, sizeof(output))>0 then
          begin
            if output.byteswritten>0 then
            begin
              result:=true;
              lpNumberOfBytesWritten:=output.byteswritten;

              if (lpNumberOfBytesWritten>0) then //for 1 byte changes
              begin
                //clear rpm cache for this entry if there is one

                b:=ptruint(lpBaseAddress) and (not $fff);
                for j:=0 to 15 do
                  if rpmcache[j].baseaddress=b then
                    rpmcache[j].lastupdate:=0; //set to outdated
              end;
            end;
          end;
        end;

        freemem(input);
      end
      {$ifdef windows}
      else
        result:=windows.WriteProcessMemory(hProcess, lpBaseAddress, lpBuffer, nSize, lpNumberOfBytesWritten)
      {$endif};

    end
    else
    begin
      //add it to the buffer
      result:=true;
      lpNumberOfBytesWritten:=nsize;

      k:=length(WriteProcessMemoryBuffer);
      setlength(WriteProcessMemoryBuffer, k+1);

      WriteProcessMemoryBuffer[k].processhandle:=ProcessHandle;
      WriteProcessMemoryBuffer[k].baseaddress:=ptruint(lpBaseAddress);
      setlength(WriteProcessMemoryBuffer[k].memory, nsize);
      CopyMemory(@WriteProcessMemoryBuffer[k].memory[0], lpBuffer, nsize);
    end;

  finally
    WriteProcessMemoryBufferCS.leave;
  end;
end;

procedure TCEConnection.beginWriteProcessMemory;
begin
  WriteProcessMemoryBufferCS.Enter;
  inc(WriteProcessMemoryBufferCount);

  //todo: Change the network interface to actually send ALL writes in one command
end;

function TCEConnection.endWriteProcessMemory: boolean;
var
  i,j,k: integer;
  x: ptruint;

  grouped: boolean;
begin
  result:=true;
  dec(WriteProcessMemoryBufferCount);

  if WriteProcessMemoryBufferCount=0 then
  begin
    //group the blocks
    i:=0;

    while i<length(WriteProcessMemoryBuffer)-1 do
    begin
      grouped:=false;
      //find a block that overlaps

      j:=i+1;

      while j<=length(WriteProcessMemoryBuffer)-1 do
      begin
        if InRangeX(WriteProcessMemoryBuffer[i].baseaddress, WriteProcessMemoryBuffer[j].baseaddress, WriteProcessMemoryBuffer[j].baseaddress+length(WriteProcessMemoryBuffer[j].memory)) or
           InRangeX(WriteProcessMemoryBuffer[j].baseaddress, WriteProcessMemoryBuffer[i].baseaddress, WriteProcessMemoryBuffer[i].baseaddress+length(WriteProcessMemoryBuffer[i].memory)) then
        begin
          k:=WriteProcessMemoryBuffer[i].baseaddress-WriteProcessMemoryBuffer[j].baseaddress;
          if k>0 then
          begin
            setlength(WriteProcessMemoryBuffer[i].memory, length(WriteProcessMemoryBuffer[i].memory)+k);
            MoveMemory(@WriteProcessMemoryBuffer[i].memory[k], @WriteProcessMemoryBuffer[i].memory[0], k );

            WriteProcessMemoryBuffer[i].baseaddress:=WriteProcessMemoryBuffer[j].baseaddress;
          end;

          //set the end
          k:=(WriteProcessMemoryBuffer[j].baseaddress+length(WriteProcessMemoryBuffer[j].memory))-(WriteProcessMemoryBuffer[i].baseaddress+length(WriteProcessMemoryBuffer[i].memory));  //get rhe bytes that need to be added
          if k>0 then //increase the size
            setlength(WriteProcessMemoryBuffer[i].memory, length(WriteProcessMemoryBuffer[i].memory)+k);

          //copy the bytes
          k:=WriteProcessMemoryBuffer[j].baseaddress-WriteProcessMemoryBuffer[i].baseaddress;
          copymemory(@WriteProcessMemoryBuffer[i].memory[k], @WriteProcessMemoryBuffer[j].memory[0], length(WriteProcessMemoryBuffer[j].memory));


          grouped:=true;

          //delete this from the list
          for k:=j to length(WriteProcessMemoryBuffer)-2 do
            WriteProcessMemoryBuffer[k]:=WriteProcessMemoryBuffer[k+1];

          setlength(WriteProcessMemoryBuffer, length(WriteProcessMemoryBuffer)-1);
        end
        else
          inc(j);
      end;

      if not grouped then //next one
        inc(i);
    end;

    //write
    for i:=0 to length(WriteProcessMemoryBuffer)-1 do
    begin
      if not WriteProcessMemory(WriteProcessMemoryBuffer[i].processhandle, pointer(WriteProcessMemoryBuffer[i].baseaddress), @WriteProcessMemoryBuffer[i].memory[0], length(WriteProcessMemoryBuffer[i].memory), x) then
        result:=false;
    end;


  end;

  WriteProcessMemoryBufferCS.Leave;
end;

function TCEConnection.CreateRemoteThread(hProcess: THandle; lpThreadAttributes: Pointer; dwStackSize: DWORD; lpStartAddress: TFNThreadStartRoutine; lpParameter: Pointer;  dwCreationFlags: DWORD; var lpThreadId: DWORD): THandle;
var
  input: packed record
    command: byte;
    hProcess: integer;
    startaddress: qword;
    parameter: qword;
  end;
  output: integer;
begin
  if isNetworkHandle(hProcess) then
  begin
    result:=0;
    input.command:=CMD_CREATETHREAD;
    input.hProcess:=hProcess and $ffffff;
    input.startaddress:=ptruint(lpStartAddress);
    input.parameter:=ptruint(lpParameter);

    if send(@input, sizeof(input))>0 then
    begin
      output:=0;
      receive(@output, sizeof(output));
      result:=output;

      if (result>0) then //mark it as a network handle
        result:=result or $ce000000;

      lpThreadId:=result; //for now
    end;

  end
  {$ifdef windows}
  else
    result:=windows.CreateRemoteThread(hProcess, lpThreadAttributes, dwStackSize, lpStartAddress, lpParameter, dwCreationFlags, lpThreadId);
  {$endif}
end;

function TCEConnection.VirtualAllocEx(hProcess: THandle; lpAddress: Pointer; dwSize, flAllocationType: DWORD; flProtect: DWORD): pointer;
var
  input: packed record
    command: byte;
    hProcess: integer;
    preferedBase: qword;
    size: integer;
  end;

  output: UINT64;
begin
  result:=nil;

  if isNetworkHandle(hProcess) then
  begin
    input.command:=CMD_ALLOC;
    input.hProcess:=hProcess and $ffffff;
    input.preferedBase:=ptruint(lpAddress);
    input.size:=dwsize;

    if send(@input, sizeof(input))>0 then
    begin
      output:=0;
      receive(@output, sizeof(output));
      result:=pointer(output);
    end;

  end
  {$ifdef windows}
  else
    result:=windows.VirtualAllocEx(hProcess, lpAddress, dwSize, flAllocationType, flProtect);
  {$endif}
end;

function TCEConnection.VirtualFreeEx(hProcess: HANDLE; lpAddress: LPVOID; dwSize: SIZE_T; dwFreeType: DWORD): BOOL;
var
  input: packed record
    command: byte;
    hProcess: integer;
    address: qword;
    size: integer;
  end;

  r: UINT32;
begin
  r:=0;

  if isNetworkHandle(hProcess) then
  begin
    result:=false;
    input.command:=CMD_FREE;
    input.hProcess:=hProcess and $ffffff;
    input.address:=ptruint(lpAddress);
    input.size:=dwsize;

    if send(@input, sizeof(input))>0 then
    begin
      r:=0;
      receive(@r, sizeof(r));
      result:=r<>0;
    end;

  end
  {$ifdef windows}
  else
    result:=windows.VirtualFreeEx(hProcess, lpAddress, dwSize, dwFreeType);
  {$endif}
end;

function TCEConnection.VirtualQueryEx_StartCache(hProcess: THandle; flags: DWORD): boolean;
var
  vqec: TVirtualQueryExCache;
  input: packed record
    command: byte;
    handle: integer;
    flags: byte;
  end;

  vqe_entry: packed record
    baseaddress: qword;
    size: qword;
    protection: dword;
    _type: dword;
  end;

  mbi: TMEMORYBASICINFORMATION;

  count: UINT32;
  i: UINT32;

  nextAddress: qword;
begin
  result:=false;

  //check if this processhandle is already cached, and if so, first call endcache on it
  VirtualQueryEx_EndCache(hProcess); //clean up if there is already one

  if isNetworkHandle(hProcess) then
  begin
    vqec:=TVirtualQueryExCache.create(hProcess);

    //fill it

    input.command:=CMD_VIRTUALQUERYEXFULL;
    input.handle:=hProcess and $ffffff;
    input.flags:=flags;

    if send(@input, sizeof(input))>0 then
    begin
      //
      //ceserver will now send the number of entries followed by the entries themself
      nextAddress:=0;

      receive(@count, sizeof(count));

      for i:=0 to count-1 do
      begin
        receive(@vqe_entry, sizeof(vqe_entry));

        if (vqe_entry.baseaddress<>nextAddress) then
        begin
          mbi.baseaddress:=pointer(nextAddress);
          mbi.allocationbase:=mbi.BaseAddress;
          mbi.AllocationProtect:=PAGE_NOACCESS;
          mbi.protect:=PAGE_NOACCESS;
          mbi.State:=MEM_FREE;
          mbi._Type:=0;
          mbi.RegionSize:=vqe_entry.baseaddress-nextaddress;
          vqec.AddRegion(mbi);
        end;

        mbi.BaseAddress:=pointer(vqe_entry.baseaddress);
        mbi.AllocationBase:=mbi.BaseAddress;
        mbi.AllocationProtect:=PAGE_EXECUTE_READWRITE;
        mbi.Protect:=vqe_entry.protection;

        if vqe_entry.protection=PAGE_NOACCESS then
        begin
          mbi.State:=MEM_FREE;
          mbi._Type:=0;
        end
        else
        begin
          mbi.State:=MEM_COMMIT;
          mbi._Type:=vqe_entry._type;
        end;

        mbi.RegionSize:=vqe_entry.size;
        vqec.AddRegion(mbi);

        nextaddress:=vqe_entry.baseaddress+vqe_entry.size;
      end;


    end
    else
      exit; //fail to cache

    //and add it to the map
    VirtualQueryExCacheMapCS.enter;
    try
      VirtualQueryExCacheMap.insert(hProcess, vqec);
    finally
      VirtualQueryExCacheMapCS.Leave;
    end;
  end; //don't do anything

end;

procedure TCEConnection.VirtualQueryEx_EndCache(hProcess: THandle);
var vqecache: TVirtualQueryExCache;
begin
  //find the current cache of this hProcess
  VirtualQueryExCacheMapCS.enter;
  try
    if VirtualQueryExCacheMap.TryGetValue(hProcess, vqecache) then
    begin
      //cleanup
      VirtualQueryExCacheMap.Delete(hProcess);
      vqecache.free;
    end;
  finally
    VirtualQueryExCacheMapCS.leave;
  end;
end;

function TCEConnection.VirtualQueryEx(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD): DWORD;
var
  input: packed record
    command: byte;
    handle: integer;
    baseaddress: qword;
  end;

  output: packed record
    result: byte;
    protection: dword;
    _type: dword;
    baseaddress: qword;
    size: qword;
  end;

  vqecache: TVirtualQueryExCache;

begin
  result:=0;

  if VirtualQueryExCacheMap.TryGetValue(hProcess, vqecache) then  //check if there is a cache going on for this handle
  begin
    //yes, get it from the cache
    if vqecache.getRegion(ptruint(lpAddress), lpBuffer) then
      result:=sizeof(lpBuffer)
    else
      result:=0;
  end
  else
  begin
    //no, use the slow method instead
    if isNetworkHandle(hProcess) then
    begin
      result:=0;
      input.command:=CMD_VIRTUALQUERYEX;
      input.handle:=hProcess and $ffffff;
      input.baseaddress:=qword(lpAddress);
      if send(@input, sizeof(input))>0 then
      begin
        if receive(@output, sizeof(output))>0 then
        begin
          if output.result>0 then
          begin
            lpBuffer.BaseAddress:=pointer(output.baseaddress);
            lpBuffer.AllocationBase:=lpBuffer.BaseAddress;
            lpbuffer.AllocationProtect:=PAGE_NOACCESS;
            lpbuffer.Protect:=output.protection;

            if output.protection=PAGE_NOACCESS then
            begin
              lpbuffer.State:=MEM_FREE;
              lpbuffer._Type:=0;
            end
            else
            begin
              lpbuffer.State:=MEM_COMMIT;
              lpbuffer._Type:=output._type;
            end;



            lpbuffer.RegionSize:=output.size;

            result:=dwlength;
          end
          else
            result:=0;
        end;
      end;

    end
    {$ifdef windows}
    else
      result:=windows.VirtualQueryEx(hProcess, lpAddress, lpBuffer, dwLength)
    {$endif};

  end;
end;

function TCEConnection.GetRegionInfo(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD; var mapsline: string): DWORD;
var
  input: packed record
    command: byte;
    handle: integer;
    baseaddress: qword;
  end;

  output: packed record
    result: byte;
    protection: dword;
    _type: dword;
    baseaddress: qword;
    size: qword;
  end;

  mapslinesize: byte;

  ml: pchar;
begin
  result:=0;

  log('TCEConnection.GetRegionInfo');

  if isNetworkHandle(hProcess) then
  begin
    log('valid handle');
    result:=0;
    input.command:=CMD_GETREGIONINFO;
    input.handle:=hProcess and $ffffff;
    input.baseaddress:=qword(lpAddress);
    if send(@input, sizeof(input))>0 then
    begin
      if receive(@output, sizeof(output))>0 then
      begin
        if output.result>0 then
        begin
          lpBuffer.BaseAddress:=pointer(output.baseaddress);
          lpBuffer.AllocationBase:=lpBuffer.BaseAddress;
          lpbuffer.AllocationProtect:=PAGE_NOACCESS;
          lpbuffer.Protect:=output.protection;

          if output.protection=PAGE_NOACCESS then
          begin
            lpbuffer.State:=MEM_FREE;
            lpbuffer._Type:=0;
          end
          else
          begin
            lpbuffer.State:=MEM_COMMIT;
            lpbuffer._Type:=output._type;
          end;



          lpbuffer.RegionSize:=output.size;

          result:=dwlength;
        end
        else
          result:=0;
      end;

      //extended part of CMD_GETREGIONINFO;
      log('receiving extended state');
      if receive(@mapslinesize, sizeof(mapslinesize))>0 then
      begin
        log('received extended state');
        log('mapelinesize='+inttostr(mapslinesize));

        getmem(ml, mapslinesize+1);
        if (ml<>nil) then
        begin
          receive(ml, mapslinesize);
          ml[mapslinesize]:=#0;

          mapsline:=ml;
          freemem(ml);
        end;
      end;


    end;

  end;
end;

function TCEConnection.OpenProcess(dwDesiredAccess:DWORD; bInheritHandle:WINBOOL; dwProcessId:DWORD):HANDLE;
var OpenProcessCommand: packed record
    command: byte;
    pid: integer;
  end;

  var h: integer;
begin
  result:=0;
  h:=0;
  OpenProcessCommand.command:=CMD_OPENPROCESS;
  OpenProcessCommand.pid:=dwProcessID;
  if send(@OpenProcessCommand, sizeof(OpenProcessCommand))>0 then
    if receive(@h, sizeof(h))>0 then
    begin
      if (h>0) then
        h:=h or $ce000000;
      result:=h;
    end;
end;

function TCEConnection.StartDebug(hProcess: THandle): BOOL;
var Input: packed record
    command: byte;
    handle: integer;
  end;

var Output: packed record
    result: integer;
  end;
begin
  result:=false;
  if ((hProcess shr 24) and $ff)= $ce then
  begin
    input.command:=CMD_STARTDEBUG;
    input.handle:=hProcess and $ffffff;
    if send(@input, sizeof(input))>0 then
    begin
      if receive(@output, sizeof(output))>0 then
      begin
        result:=output.result<>0;
      end;
    end;
  end;

end;

function TCEConnection.ContinueDebugEvent(hProcess: THandle; threadid: dword; continuemethod: integer): BOOL;
var
  input: packed record
    command: byte;
    handle: integer;
    threadid: dword;
    continuemethod: integer;
  end;
  r: integer;
begin

  result:=false;

  if ((hProcess shr 24) and $ff)= $ce then
  begin
    input.command:=CMD_CONTINUEFROMDEBUGEVENT;
    input.handle:=hProcess and $ffffff;
    input.threadid:=threadid;
    input.continuemethod:=continuemethod;
    if send(@input, sizeof(input))>0 then
    begin
      if receive(@r, sizeof(r))>0 then
        result:=r<>0;
    end;

  end;



end;

function TCEConnection.WaitForDebugEvent(hProcess: THandle; timeout: integer; var devent: TNetworkDebugEvent):BOOL;
var
  Input: packed record
    command: byte;
    handle: integer;
    timeout: integer;
  end;

  r: integer;

begin
  result:=false;

  if ((hProcess shr 24) and $ff)= $ce then
  begin
    input.command:=CMD_WAITFORDEBUGEVENT;
    input.handle:=hProcess and $ffffff;
    input.timeout:=timeout;
    if send(@input, sizeof(input))>0 then
    begin
      if receive(@r, sizeof(r))>0 then
      begin
        result:=r<>0;
        if result then
          result:=receive(@devent, sizeof(TNetworkDebugEvent))>0;

      end;



    end;
  end;




end;


function TCEConnection.SetBreakpoint(hProcess: THandle; threadid: integer; debugregister: integer; address: PtrUInt; bptype: integer; bpsize: integer): boolean;
var
  input: packed record
    command: byte;
    handle: integer;
    tid: integer;
    debugregister: integer;
    address: qword;
    bptype: integer;
    bpsize: integer;
  end;

  r: integer;

begin
  result:=false;

  if ((hProcess shr 24) and $ff)= $ce then
  begin
    input.command:=CMD_SETBREAKPOINT;
    input.handle:=hProcess and $ffffff;
    input.tid:=threadid;
    input.debugregister:=debugregister;
    input.address:=address;
    input.bptype:=bptype;
    input.bpsize:=bpsize;

    if send(@input, sizeof(input))>0 then
    begin
      if receive(@r, sizeof(r))>0 then
        result:=r<>0;
    end;
  end;

end;

function TCEConnection.RemoveBreakpoint(hProcess: THandle; threadid: integer; debugregister: integer; wasWatchpoint: boolean): boolean;
var
  input: packed record
    command: byte;
    handle: integer;
    tid: integer;
    debugregister: integer;
    wasWatchpoint: integer;
  end;

  r: integer;

begin
  result:=false;

  if ((hProcess shr 24) and $ff)= $ce then
  begin
    input.command:=CMD_REMOVEBREAKPOINT;
    input.handle:=hProcess and $ffffff;
    input.tid:=threadid;
    input.debugregister:=debugregister;
    if wasWatchpoint then
      input.wasWatchpoint:=1
    else
      input.wasWatchpoint:=0;


    if send(@input, sizeof(input))>0 then
    begin
      if receive(@r, sizeof(r))>0 then
        result:=r<>0;
    end;
  end;

end;

function TCEConnection.AllocateAndGetContext(hProcess: Thandle; threadid: integer): pointer;
//get he context and save it in an allocated memory block of variable size. The caller is responsible for freeing this block
var
  Input: packed record
    command: UINT8;
    hprocess: uint32;
    threadid: uint32;
    ctype: uint32;  //ignored for now
  end;

  contextsize: UINT32;
  r: integer;
begin
  result:=nil;
  input.command:=CMD_GETTHREADCONTEXT;
  input.hprocess:=hProcess and $ffffff;
  input.threadid:=threadid;
  input.ctype:=0;

  if send(@input, sizeof(input))>0 then
  begin
    if receive(@r, sizeof(r))>0 then
    begin

      if (r<>0) and (receive(@contextsize, sizeof(contextsize))>0) then
      begin
        getmem(result,  contextsize);
        if receive(result, contextsize)=0 then
        begin
          freemem(result);
          result:=nil;
        end;
      end;

    end;
  end;

end;

function TCEConnection.getVersion(var name: string): integer;
var CeVersion: packed record
  version: integer;
  stringsize: byte;
end;
  _name: pchar;

  command: byte;
begin
  result:=0;
  command:=CMD_GETVERSION;
  if send(@command, 1)>0 then
  begin
    if receive(@CeVersion, sizeof(CeVersion))>0 then
    begin
      getmem(_name, CeVersion.stringsize);
      receive(_name, CeVersion.stringsize);

      name:=_name;
      freemem(_name);

      result:=length(name);
    end;
  end;
end;

function TCEConnection.getArchitecture: integer;
var command: byte;
  r: byte;
begin
  result:=0;
  command:=CMD_GETARCHITECTURE;
  if send(@command, 1)>0 then
    if receive(@r, 1)>0 then
      result:=r;
end;


function ShortenLinuxModuleName(modulename: string): string;
var i: integer;
begin
  //build the shortenedmodulename
  //parse the modulepath and strip the version and .so part and everything after it
  //formats: libxxx-#.#.so.#.#.#
  //keep in mind names like :libdbusmenu-gtk.so.4.0.12 and libdbusmenu-glib.so.4.0.12 should become libdbusmenu-gtk and libdbusmenu-glib respectively



  for i:=1 to length(modulename)-1 do
  begin
    case modulename[i] of
      '-':
      begin
        //check if modulename[i+1] is a number, if so, cut from here
        if (length(modulename)>=i+1) and (modulename[i+1] in ['0'..'9']) then
        begin
          result:=copy(modulename, 1, i-1);
          exit;
        end;


      end;

      '.':
      begin
        //check if it is .so
        if (length(modulename)>=i+2) and (uppercase(modulename[i+1])='S') and (uppercase(modulename[i+2])='O') then
        begin
          result:=copy(modulename, 1, i-1);
          exit;
        end;
      end;
    end;
  end;

  //still here
  result:=modulename;


end;

function TCEConnection.enumSymbolsFromFile(modulepath: string; modulebase: ptruint; callback: TNetworkEnumSymCallback): boolean;
type
  TCeGetSymbolList=packed record
    command: byte;
    symbolpathsize: uint32;
    path: array [0..0] of char;
  end;

  PCeGetSymbolList=^TCeGetSymbolList;

  TNetworkSymbolInfo=packed record
    address: uint64;
    size: int32;
    _type: int32;
    namelength: uint8;
  end;

  PNetworkSymbolInfo=^TNetworkSymbolInfo;



var
  msg: PCeGetSymbolList;
  msgsize: integer;

  compressedsize: uint32;
  decompressedsize: uint32;

  d: Tdecompressionstream;
  compressedbuffer: TMemorystream;

  decompressed: PByte;

  currentsymbol: PNetworkSymbolInfo;


  modulename: string;
  pos: integer;

  symname: pchar;
  maxsymname: integer;

  isexe: uint32;
  shortenedmodulename: string; //the name of the module with nothing after .so
  i: integer;
begin
  result:=true;

  if modulepath='[vdso]' then
  begin
    //special module with no clear filepath
    result:=EnumElfSymbols('vdso', modulebase, callback);
    exit;
  end;



  msgsize:=5+length(modulepath);
  getmem(msg, msgsize);

  msg^.command:=CMD_GETSYMBOLLISTFROMFILE;
  msg^.symbolpathsize:=length(modulepath);
  CopyMemory(@msg^.path, @modulepath[1], length(modulepath));


  if send(msg,  msgsize)>0 then
  begin
    if receive(@isexe, sizeof(isexe))>0 then
    begin
      if receive(@compressedsize, sizeof(compressedsize))>0 then
      begin
        if compressedsize>0 then
        begin
          if receive(@decompressedsize, sizeof(decompressedsize))>0 then
          begin
            compressedbuffer:=tmemorystream.create;
            compressedbuffer.Size:=compressedsize-3*sizeof(uint32);

            if receive(compressedbuffer.Memory, compressedbuffer.size)>0 then
            begin
              //decompress it
              d:=Tdecompressionstream.Create(compressedbuffer, false);
              getmem(decompressed, decompressedsize);
              d.ReadBuffer(decompressed^, decompressedsize);
              d.free;

              //parse through the decompressed block and fill in the results

              if copy(modulepath,1,1)<>'[' then
              begin
                modulename:=extractfilename(modulepath);

                shortenedmodulename:=ShortenLinuxModuleName(modulename);

              end
              else
                modulename:=modulepath;

              pos:=0;

              maxsymname:=256;
              getmem(symname, maxsymname);


              while pos<decompressedsize do
              begin
                currentsymbol:=@decompressed[pos];
                inc(pos, sizeof(TNetworkSymbolInfo));

                if currentsymbol^.namelength>=maxsymname then
                begin
                  //need more memory
                  maxsymname:=currentsymbol^.namelength+1;

                  freemem(symname);
                  getmem(symname, maxsymname);
                end;

                CopyMemory(symname, @decompressed[pos], currentsymbol^.namelength);
                symname[currentsymbol^.namelength]:=#0;

                inc(pos, currentsymbol^.namelength);


                if currentsymbol^.namelength>0 then
                begin
                  if isexe<>0 then
                  begin
                    if callback(modulename, symname, currentsymbol^.address, currentsymbol^.size,false)=false then
                      break;
                  end
                  else
                  begin
                    if (callback(shortenedmodulename, symname, modulebase+currentsymbol^.address, currentsymbol^.size, false) and
                        callback(modulename, symname, modulebase+currentsymbol^.address, currentsymbol^.size, true))=false then
                      break;
                  end;
                end;
              end;


              freemem(symname);

              freemem(decompressed);

            end;

            compressedbuffer.free;
          end;
        end;
      end;

    end;
  end;

end;

function TCEConnection.loadModule(hProcess: THandle; modulepath: string): boolean;
type
  TInput=packed record
    command: uint8;
    handle: uint32;
    modulepathlength: uint32;
    modulename: packed record end;
  end;
  PInput=^TInput;

var
  input: Pinput;
  r:uint32;
begin
  result:=false;
  if isNetworkHandle(hProcess) then
  begin
    getmem(input, sizeof(TInput)+length(modulepath));

    input^.command:=CMD_LOADMODULE;
    input^.handle:=hProcess and $ffffff;
    input^.modulepathlength:=Length(modulepath);
    CopyMemory(@input^.modulename, @modulepath[1], length(modulepath));

    if send(@input,  sizeof(TInput)+length(modulepath))>0 then
    begin
      receive(@r, sizeof(r));
      result:=r<>0;
    end;

    freemem(input);

  end;
end;

function TCEConnection.loadExtension(hProcess: THandle): boolean;
var
  loadExtensionCommand: packed record
    command: byte;
    handle: uint32;
  end;

  r:uint32;
begin
  result:=false;

  if isNetworkHandle(hProcess) then
  begin
    loadExtensionCommand.command:=CMD_LOADEXTENSION;
    loadExtensionCommand.handle:=hProcess and $ffffff;

    if send(@loadExtensionCommand,  sizeof(loadExtensionCommand))>0 then
    begin
      receive(@r, sizeof(r));
      result:=r<>0;
    end;
  end;

end;

function TCEConnection.speedhack_setSpeed(hProcess: THandle; speed: single): boolean;
var
  speedhackSetSpeedCommand: packed record
    command: byte;
    handle: uint32;
    speed: single;
  end;

  r:uint32;
begin
  result:=false;

  if isNetworkHandle(hProcess) then
  begin
    speedhackSetSpeedCommand.command:=CMD_SPEEDHACK_SETSPEED;
    speedhackSetSpeedCommand.handle:=hProcess and $ffffff;
    speedhackSetSpeedCommand.speed:=speed;

    if send(@speedhackSetSpeedCommand,  sizeof(speedhackSetSpeedCommand))>0 then
    begin
      receive(@r, sizeof(r));
      result:=r<>0;
    end;
  end;
end;

function TCEConnection.isNetworkHandle(handle: THandle): boolean;
begin
  result:=((handle shr 24) and $ff)= $ce;
end;

function TCEConnection.send(buffer: pointer; size: integer): integer;
var i: integer;
begin
  result:=0;
  while (result<size) do
  begin
    i:=fpsend(socket, pointer(ptruint(buffer)+result), size, 0);
    if i<=0 then
    begin
      OutputDebugString('Error during send');
      fConnected:=false;
      if socket<>0 then
        CloseSocket(socket);

      socket:=0;
      result:=i; //error
      exit;
    end;

    inc(result, i);
  end;
end;

function TCEConnection.receive(buffer: pointer; size: integer): integer;
var
  i: integer;
begin
  //{$ifdef windows}
    //xp doesn't support MSG_WAITALL

    result:=0;
    while (result<size) do
    begin
      i:=fprecv(socket, pointer(ptruint(buffer)+result), size-result, 0);
      if i<=0 then
      begin
        fConnected:=false;
        if socket<>0 then
          CloseSocket(socket);

        socket:=0;
        result:=i; //error

        OutputDebugString('Error during receive');
        exit;
      end;

      inc(result, i);

    end;

 // {$else}
  //  result:=fprecv(socket, buffer, size, MSG_WAITALL);
  //{$endif}
end;

constructor TCEConnection.create;
var SockAddr: TInetSockAddr;
  retry: integer;
  B: BOOL;
begin
  OutputDebugString('Inside TCEConnection.create');
  WriteProcessMemoryBufferCS:=TCriticalSection.create;

  VirtualQueryExCacheMapCS:=TCriticalSection.create;
  VirtualQueryExCacheMap:=TVQEMap.Create;

  socket:=cint(INVALID_SOCKET);

  if (host.s_addr=0) or (port=0) then exit;

  //connect
  socket:=FPSocket(AF_INET, SOCK_STREAM, 0);
  if (socket=cint(INVALID_SOCKET)) then
  begin
    OutputDebugString('Socket creation failed. Check permissions');
    exit;
  end;



  OutputDebugString('socket='+inttostr(socket));

  SockAddr.sin_family := AF_INET;
  SockAddr.sin_port := port;
  SockAddr.sin_addr.s_addr := host.s_addr;

  B:=TRUE;

  fpsetsockopt(socket, IPPROTO_TCP, TCP_NODELAY, @B, sizeof(B));

  retry:=0;
  while not (fConnected) and (retry<5) do
  begin
    if fpconnect(socket, @SockAddr, sizeof(SockAddr)) >=0 then
      fConnected:=true
    else
    begin
      inc(retry);
     // OutputDebugString('fail '+inttostr(retry));
    end;
  end;

  if not fconnected then
    OutputDebugString('Connection failure');
end;

destructor TCEConnection.destroy;
begin
  if socket<>cint(INVALID_SOCKET) then
    CloseSocket(socket);

  if VirtualQueryExCacheMap<>nil then
    VirtualQueryExCacheMap.free;

  if VirtualQueryExCacheMapCS<>nil then
    VirtualQueryExCacheMapCS.free;

  if WriteProcessMemoryBufferCS<>nil then
    WriteProcessMemoryBufferCS.free;

end;

end.

