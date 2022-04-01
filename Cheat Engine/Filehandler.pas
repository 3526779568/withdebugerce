unit Filehandler;

{$MODE Delphi}

{
implement replaced handlers for ReadProcssMemory and WriteProcessMemory so it
reads/writes to the file instead
}

interface

uses jwawindows, windows, LCLIntf, syncobjs, sysutils, Classes;

function ReadProcessMemoryFile(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer;  nSize: DWORD; var lpNumberOfBytesRead: DWORD): BOOL; stdcall;
function WriteProcessMemoryFile(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesWritten: DWORD): BOOL; stdcall;
function VirtualQueryExFile(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD): DWORD; stdcall;
procedure CommitChanges(fn: string='');

var filename: string;
    filedata: TMemorystream;
    //filehandle: thandle;
    bigendianfileaccess: boolean=false;

implementation

uses dialogs, controls;

procedure CommitChanges(fn: string='');
begin
  if filedata<>nil then
  begin
    if fn='' then
      fn:=filename;

    filedata.SaveToFile(fn);
  end;
end;

var filecs: tcriticalsection; //only 1 filehandle, so make sure rpm does not change the filepointer while another is still reading it
function ReadProcessMemoryFile(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer;  nSize: DWORD; var lpNumberOfBytesRead: DWORD): BOOL; stdcall;
var filesize,ignore:dword;

    i: integer;

    b: pdword;


    t: dword;

    ba: ptruint;

    s: integer;

begin
//ignore hprocess
  result:=false;
  ba:=ptruint(lpBaseAddress);
  inc(ba,ptruint(filedata.Memory));

  filesize:=filedata.Size;

  if ptrUint(lpbaseaddress)>=filesize then exit;

  s:=nsize;

  if ptrUint(lpbaseaddress)+s>=filesize then
  begin
    ZeroMemory(lpBuffer, nsize);
    dec(s, ((ptrUint(lpbaseaddress)+s)-filesize));
  end;

  if s<=0 then exit;

  nsize:=s;

  CopyMemory(lpbuffer,pointer(ba),nsize);
  lpNumberOfBytesRead:=nsize;

  result:=true;

  if bigendianfileaccess then
  begin
    i:=0;
    while i<nSize do
    begin
      if (nsize-i)>=4 then
      begin
        b:=@PByteArray(lpBuffer)[i];
        t:=b^;

        {$ifdef cpu64}
        asm
          push rax
          xor rax,rax
          mov eax,t
          bswap eax
          mov t,eax
          pop rax
        end;
        {$else}
        asm
          push eax
          xor eax,eax
          mov eax,t
          bswap eax
          mov t,eax
          pop eax
        end;

        {$endif}

        b^:=t;
      end;

      inc(i, 4);
    end;
  end;

end;

function WriteProcessMemoryFile(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesWritten: DWORD): BOOL; stdcall;
var filesize,ignore:dword;

    i: integer;

    b: pdword;


    t: dword;

    ba: ptruint;
    s: integer;

begin
//ignore hprocess
  result:=false;
  ba:=ptruint(lpBaseAddress);
  inc(ba,ptruint(filedata.Memory));

  filesize:=filedata.Size;


  s:=nsize;

  if ptrUint(lpbaseaddress)+s>filesize then
  begin
    if MainThreadID=GetCurrentThreadId then
    begin
      if MessageDlg('Change the file size to '+inttostr(ptrUint(lpbaseaddress)+s)+' bytes?',mtConfirmation,[mbyes,mbno],0)=mryes then
      begin
        i:=(ptrUint(lpbaseaddress)+s)-filesize;

        filedata.SetSize(ptrUint(lpbaseaddress)+s);
        ZeroMemory(pointer(ptruint(filedata.Memory)+filesize), i);
        filesize:=filedata.size;
      end
      else
        dec(s, ((ptrUint(lpbaseaddress)+s)-filesize));
    end
    else
      dec(s, ((ptrUint(lpbaseaddress)+s)-filesize));
  end;

  if s<=0 then exit;

  nsize:=s;

  CopyMemory(pointer(ba),lpbuffer,nsize);
  lpNumberOfBytesWritten:=nsize;

  result:=true;

  if bigendianfileaccess then
  begin
    i:=0;
    while i<nSize do
    begin
      if (nsize-i)>=4 then
      begin
        b:=@PByteArray(lpBuffer)[i];
        t:=b^;

        {$ifdef cpu64}
        asm
          push rax
          xor rax,rax
          mov eax,t
          bswap eax
          mov t,eax
          pop rax
        end;
        {$else}
        asm
          push eax
          xor eax,eax
          mov eax,t
          bswap eax
          mov t,eax
          pop eax
        end;

        {$endif}

        b^:=t;
      end;

      inc(i, 4);
    end;
  end;

end;

function VirtualQueryExFile(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD): DWORD; stdcall;
var ignore: dword;
    filesize: ptrUint;
begin
  filesize:=getfilesize(hprocess,@ignore);
  lpBuffer.BaseAddress:=pointer((ptrUint(lpAddress) div $1000)*$1000);
  lpbuffer.AllocationBase:=lpbuffer.BaseAddress;
  lpbuffer.AllocationProtect:=PAGE_EXECUTE_READWRITE;
  lpbuffer.RegionSize:=filesize-ptrUint(lpBuffer.BaseAddress);
  lpbuffer.RegionSize:=lpbuffer.RegionSize+($1000-lpbuffer.RegionSize mod $1000);


  lpbuffer.State:=mem_commit;
  lpbuffer.Protect:=PAGE_EXECUTE_READWRITE;
  lpbuffer._Type:=MEM_PRIVATE;

  if (ptrUint(lpAddress)>filesize) //bigger than the file
  then
  begin
    zeromemory(@lpbuffer,dwlength);
    result:=0
  end
  else
    result:=dwlength;

end;

initialization
  filecs:=tcriticalsection.create;

finalization
  filecs.free;


end.






