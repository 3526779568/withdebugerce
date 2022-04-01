unit NewKernelHandler;

{$MODE Delphi}

interface

{$ifdef JNI}
uses classes, sysutils, unixporthelper;
{$else}
uses jwawindows, windows,LCLIntf,sysutils, dialogs, classes, controls,
     dbk32functions, vmxfunctions,debug, multicpuexecution, contnrs, Clipbrd;
{$endif}

const dbkdll='DBK32.dll';


const
  VQE_PAGEDONLY=1;
  VQE_DIRTYONLY=2;
  VQE_NOSHARED=4 ;


type
PPROCESSENTRY32 = ^PROCESSENTRY32;

tagPROCESSENTRY32 = record
  dwSize: DWORD;
  cntUsage: DWORD;
  th32ProcessID: DWORD;          // this process
  th32DefaultHeapID: ULONG_PTR;
  th32ModuleID: DWORD;           // associated exe
  cntThreads: DWORD;
  th32ParentProcessID: DWORD;    // this process's parent process
  pcPriClassBase: LONG;          // Base priority of process's threads
  dwFlags: DWORD;
  szExeFile: array [0..MAX_PATH - 1] of Char;    // Path
end;
PROCESSENTRY32 = tagPROCESSENTRY32;
LPPROCESSENTRY32 = ^PROCESSENTRY32;
TProcessEntry32 = PROCESSENTRY32;


PMODULEENTRY32 = ^MODULEENTRY32;
tagMODULEENTRY32 = record
  dwSize: DWORD;
  th32ModuleID: DWORD;       // This module
  th32ProcessID: DWORD;      // owning process
  GlblcntUsage: DWORD;       // Global usage count on the module
  ProccntUsage: DWORD;       // Module usage count in th32ProcessID's context
  modBaseAddr: LPBYTE;       // Base address of module in th32ProcessID's context
  modBaseSize: DWORD;        // Size in bytes of module starting at modBaseAddr
  hModule: HMODULE;          // The hModule of this module in th32ProcessID's context
  szModule: array [0..MAX_MODULE_NAME32] of Char;
  szExePath: array [0..MAX_PATH - 1] of Char;
end;
MODULEENTRY32 = tagMODULEENTRY32;
LPMODULEENTRY32 = ^MODULEENTRY32;
TModuleEntry32 = MODULEENTRY32;


{$ifdef cpu32}
const
  CONTEXT_EXTENDED_REGISTERS = (CONTEXT_i386 or $00000020);
{$endif}

{$ifdef cpu64}
const
  CONTEXT_EXTENDED_REGISTERS = 0;


type
   XMM_SAVE_AREA32 = record
        ControlWord: WORD;
        StatusWord: WORD;
        TagWord: BYTE;
        Reserved1: BYTE;
        ErrorOpcode: WORD;
        ErrorOffset: DWORD;
        ErrorSelector: WORD;
        Reserved2: WORD;
        DataOffset: DWORD;
        DataSelector: WORD;
        Reserved3: WORD;
        MxCsr: DWORD;
        MxCsr_Mask: DWORD;
        FloatRegisters: array[0..7] of M128A;
        XmmRegisters: array[0..15] of M128A;
        Reserved4: array[0..95] of BYTE;
     end;
   _XMM_SAVE_AREA32 = XMM_SAVE_AREA32;
   TXmmSaveArea = XMM_SAVE_AREA32;
   PXmmSaveArea = ^TXmmSaveArea;

const
   LEGACY_SAVE_AREA_LENGTH = sizeof(XMM_SAVE_AREA32);

type
  CONTEXT = packed record

       //
       // Register parameter home addresses.
       //
       // N.B. These fields are for convience - they could be used to extend the
       //      context record in the future.
       //

       P1Home: DWORD64;
       P2Home: DWORD64;
       P3Home: DWORD64;
       P4Home: DWORD64;
       P5Home: DWORD64;
       P6Home: DWORD64;

       //
       // Control flags.
       //

       ContextFlags: DWORD;
       MxCsr: DWORD;

       //
       // Segment Registers and processor flags.
       //

       SegCs: WORD;
       SegDs: WORD;
       SegEs: WORD;
       SegFs: WORD;
       SegGs: WORD;
       SegSs: WORD;
       EFlags: DWORD;

       //
       // Debug registers
       //

       Dr0: DWORD64;
       Dr1: DWORD64;
       Dr2: DWORD64;
       Dr3: DWORD64;
       Dr6: DWORD64;
       Dr7: DWORD64;

       //
       // Integer registers.
       //

       Rax: DWORD64;
       Rcx: DWORD64;
       Rdx: DWORD64;
       Rbx: DWORD64;
       Rsp: DWORD64;
       Rbp: DWORD64;
       Rsi: DWORD64;
       Rdi: DWORD64;
       R8: DWORD64;
       R9: DWORD64;
       R10: DWORD64;
       R11: DWORD64;
       R12: DWORD64;
       R13: DWORD64;
       R14: DWORD64;
       R15: DWORD64;

       //
       // Program counter.
       //

       Rip: DWORD64;

       //
       // Floating point state.
       //

       FltSave: XMM_SAVE_AREA32; // MWE: only translated the FltSave part of the union
(*
       union  {
           XMM_SAVE_AREA32 FltSave;
           struct {
               M128A Header[2];
               M128A Legacy[8];
               M128A Xmm0;
               M128A Xmm1;
               M128A Xmm2;
               M128A Xmm3;
               M128A Xmm4;
               M128A Xmm5;
               M128A Xmm6;
               M128A Xmm7;
               M128A Xmm8;
               M128A Xmm9;
               M128A Xmm10;
               M128A Xmm11;
               M128A Xmm12;
               M128A Xmm13;
               M128A Xmm14;
               M128A Xmm15;
           };
       };
*)

       //
       // Vector registers.
       //

       VectorRegister: array[0..25] of M128A;
       VectorControl: DWORD64;

       //
       // Special debug control registers.
       //

       DebugControl: DWORD64;
       LastBranchToRip: DWORD64;
       LastBranchFromRip: DWORD64;
       LastExceptionToRip: DWORD64;
       LastExceptionFromRip: DWORD64;
   end;

  TCONTEXT=CONTEXT;
  PCONTEXT=^TCONTEXT;
  _CONTEXT=CONTEXT;

{$endif}
type
  TARMCONTEXT=packed record
     R0: DWORD;
     R1: DWORD;
     R2: DWORD;
     R3: DWORD;
     R4: DWORD;
     R5: DWORD;
     R6: DWORD;
     R7: DWORD;
     R8: DWORD;
     R9: DWORD;
     R10: DWORD;
     FP: DWORD;
     IP: DWORD;
     SP: DWORD;
     LR: DWORD;
     PC: DWORD;
     CPSR: DWORD;
     ORIG_R0: DWORD;
  end;

  PARMCONTEXT=^TARMCONTEXT;


//credits to jedi code library for filling in the "extended registers"
type
  TJclMMContentType = (mt8Bytes, mt4Words, mt2DWords, mt1QWord, mt2Singles, mt1Double);

  TJclMMRegister = packed record
    case TJclMMContentType of
      mt8Bytes:
        (Bytes: array [0..7] of Byte;);
      mt4Words:
        (Words: array [0..3] of Word;);
      mt2DWords:
        (DWords: array [0..1] of Cardinal;);
      mt1QWord:
        (QWords: Int64;);
      mt2Singles:
        (Singles: array [0..1] of Single;);
      mt1Double:
        (Doubles: double;);
  end;

  TJclFPUContentType = (ftExtended, ftMM);

  TJclFPUData = packed record
    case TJclFPUContentType of
      ftExtended:
        (FloatValue: Extended;);
      ftMM:
        (MMRegister: TJclMMRegister;
         Reserved: Word;);
  end;

  TJclFPURegister = packed record
    Data: TJclFPUData;
    Reserved: array [0..5] of Byte;
  end;

  TJclFPURegisters = array [0..7] of TJclFPURegister;

  TJclXMMContentType = (xt16Bytes, xt8Words, xt4DWords, xt2QWords, xt4Singles, xt2Doubles);

  TJclXMMRegister = packed record
    case TJclXMMContentType of
      xt16Bytes:
        (Bytes: array [0..15] of Byte;);
      xt8Words:
        (Words: array [0..7] of Word;);
      xt4DWords:
        (DWords: array [0..3] of Cardinal;);
      xt2QWords:
        (QWords: array [0..1] of Int64;);
      xt4Singles:
        (Singles: array [0..3] of Single;);
      xt2Doubles:
        (Doubles: array [0..1] of Double;);
  end;

  TJclProcessorSize = (ps32Bits, ps64Bits);

  TJclXMMRegisters = packed record
    case TJclProcessorSize of
      ps32Bits:
        (LegacyXMM: array [0..7] of TJclXMMRegister;
         LegacyReserved: array [0..127] of Byte;);
      ps64Bits:
        (LongXMM: array [0..15] of TJclXMMRegister;);
  end;

  TextendedRegisters = packed record    //fxsave
    //extended registers
    FCW: Word;                           // bytes from 0   to 1
    FSW: Word;                           // bytes from 2   to 3
    FTW: Byte;                           // byte 4
    Reserved1: Byte;                     // byte 5
    FOP: Word;                           // bytes from 6   to 7
    FpuIp: Cardinal;                     // bytes from 8   to 11
    CS: Word;                            // bytes from 12  to 13
    Reserved2: Word;                     // bytes from 14  to 15
    FpuDp: Cardinal;                     // bytes from 16  to 19
    DS: Word;                            // bytes from 20  to 21
    Reserved3: Word;                     // bytes from 22  to 23
    MXCSR: Cardinal;                     // bytes from 24  to 27
    MXCSRMask: Cardinal;                 // bytes from 28  to 31
    FPURegisters: TJclFPURegisters;      // bytes from 32  to 159
    XMMRegisters: TJclXMMRegisters;      // bytes from 160 to 415
    Reserved4: array [416..511] of Byte; // bytes from 416 to 511
  end;


type
  {$ifdef cpu64}
  _CONTEXT32 = packed record
  {$else}
  _CONTEXT = packed record
  {$endif}
    ContextFlags: DWORD;
    Dr0: DWORD;
    Dr1: DWORD;
    Dr2: DWORD;
    Dr3: DWORD;
    Dr6: DWORD;
    Dr7: DWORD;

    FloatSave: TFloatingSaveArea;

    SegGs: DWORD;
    SegFs: DWORD;
    SegEs: DWORD;
    SegDs: DWORD;

    Edi: DWORD;
    Esi: DWORD;
    Ebx: DWORD;
    Edx: DWORD;
    Ecx: DWORD;
    Eax: DWORD;

    Ebp: DWORD;
    Eip: DWORD;
    SegCs: DWORD;
    EFlags: DWORD;
    Esp: DWORD;
    SegSs: DWORD;

    ext: TExtendedRegisters;
  end;
  {$ifdef cpu64}
  CONTEXT32=_CONTEXT32;
  TContext32=CONTEXT32;
  PContext32 = ^TContext32;
  {$else}
  CONTEXT=_CONTEXT;
  CONTEXT32=_CONTEXT;
  TContext=CONTEXT;
  PContext = ^TContext;
  {$endif}

type TDebuggerstate=packed record
  threadid: uint64;
	eflags : uint64;
	eax : uint64;
	ebx : uint64;
	ecx : uint64;
	edx : uint64;
	esi : uint64;
	edi : uint64;
	ebp : uint64;
	esp : uint64;
	eip : uint64;
	r8  : uint64;
	r9  : uint64;
	r10 : uint64;
	r11 : uint64;
	r12 : uint64;
	r13 : uint64;
	r14 : uint64;
	r15 : uint64;
	cs  : uint64;
	ds  : uint64;
	es  : uint64;
	fs  : uint64;
	gs  : uint64;
	ss  : uint64;
  dr0 : uint64;
  dr1 : uint64;
  dr2 : uint64;
  dr3 : uint64;
  dr6 : uint64;
  dr7 : uint64;
  fxstate: TextendedRegisters;
  LBR_Count: uint64;
  LBR: array [0..15] of UINT64;
end;
type PDebuggerstate=^TDebuggerstate;

type TBreakType=(bt_OnInstruction=0,bt_OnWrites=1, bt_OnIOAccess=2, bt_OnReadsAndWrites=3);
type TBreakLength=(bl_1byte=0, bl_2byte=1, bl_8byte=2{Only when in 64-bit}, bl_4byte=3);


type TEnumDeviceDrivers=function(lpImageBase: LPLPVOID; cb: DWORD; var lpcbNeeded: DWORD): BOOL; stdcall;
type TGetDeviceDriverBaseNameA=function(ImageBase: LPVOID; lpBaseName: LPSTR; nSize: DWORD): DWORD; stdcall;
type TGetDeviceDriverFileName=function(ImageBase: LPVOID; lpFilename: LPTSTR; nSize: DWORD): DWORD; stdcall;

type TGetLargePageMinimum=function: SIZE_T; stdcall;


type TReadProcessMemory=function(hProcess: THandle; lpBaseAddress, lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesRead: PTRUINT): BOOL; stdcall;
type TReadProcessMemory64=function(hProcess: THandle; lpBaseAddress: UINT64; lpBuffer: pointer; nSize: DWORD; var lpNumberOfBytesRead: PTRUINT): BOOL; stdcall;
type TWriteProcessMemory=function(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesWritten: PTRUINT): BOOL; stdcall;
type TWriteProcessMemory64=function(hProcess: THandle; BaseAddress: UINT64; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesWritten: ptruint): BOOL; stdcall;


type TGetThreadContext=function(hThread: THandle; var lpContext: TContext): BOOL; stdcall;
type TSetThreadContext=function(hThread: THandle; const lpContext: TContext): BOOL; stdcall;

type TWow64GetThreadContext=function(hThread: THandle; var lpContext: CONTEXT32): BOOL; stdcall;
type TWow64SetThreadContext=function(hThread: THandle; const lpContext: CONTEXT32): BOOL; stdcall;

{$ifdef cpu64}
type TGetThreadSelectorEntry=function(hThread: THandle; dwSelector: DWORD; var lpSelectorEntry: TLDTEntry): BOOL; stdcall;
{$endif}



type TSuspendThread=function(hThread: THandle): DWORD; stdcall;
type TResumeThread=function(hThread: THandle): DWORD; stdcall;
type TOpenProcess=function(dwDesiredAccess: DWORD; bInheritHandle: BOOL; dwProcessId: DWORD): THandle; stdcall;

type TCreateToolhelp32Snapshot=function(dwFlags, th32ProcessID: DWORD): THandle; stdcall;
type TProcess32First=function(hSnapshot: THandle; var lppe: TProcessEntry32): BOOL; stdcall;
type TProcess32Next=function(hSnapshot: THandle; var lppe: TProcessEntry32): BOOL; stdcall;
type TThread32First=function (hSnapshot: THandle; var lpte: TThreadEntry32): BOOL; stdcall;
type TThread32Next=function (hSnapshot: THandle; var lpte: TThreadENtry32): BOOL; stdcall;
type TModule32First=function (hSnapshot: THandle; var lpme: TModuleEntry32): BOOL; stdcall;
type TModule32Next=function (hSnapshot: THandle; var lpme: TModuleEntry32): BOOL; stdcall;
type THeap32ListFirst=function (hSnapshot: THandle; var lphl: THeapList32): BOOL; stdcall;
type THeap32ListNext=function (hSnapshot: THandle; var lphl: THeapList32): BOOL; stdcall;
type TIsWow64Process=function (processhandle: THandle; var isWow: BOOL): BOOL; stdcall;

type TWaitForDebugEvent=function(var lpDebugEvent: TDebugEvent; dwMilliseconds: DWORD): BOOL; stdcall;
type TContinueDebugEvent=function(dwProcessId, dwThreadId, dwContinueStatus: DWORD): BOOL; stdcall;
type TDebugActiveProcess=function(dwProcessId: DWORD): BOOL; stdcall;
type TVirtualFreeEx=function(hProcess: HANDLE; lpAddress: LPVOID; dwSize: SIZE_T; dwFreeType: DWORD): BOOL; stdcall;
type TVirtualProtect=function(lpAddress: Pointer; dwSize, flNewProtect: DWORD; var OldProtect: DWORD): BOOL; stdcall;
type TVirtualProtectEx=function(hProcess: THandle; lpAddress: Pointer; dwSize, flNewProtect: DWORD; var OldProtect: DWORD): BOOL; stdcall;
type TVirtualQueryEx=function(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD): DWORD; stdcall;
type TVirtualAllocEx=function(hProcess: THandle; lpAddress: Pointer; dwSize, flAllocationType: DWORD; flProtect: DWORD): Pointer; stdcall;
type TCreateRemoteThread=function(hProcess: THandle; lpThreadAttributes: Pointer; dwStackSize: DWORD; lpStartAddress: TFNThreadStartRoutine; lpParameter: Pointer;  dwCreationFlags: DWORD; var lpThreadId: DWORD): THandle; stdcall;
type TOpenThread=function(dwDesiredAccess:DWORD;bInheritHandle:BOOL;dwThreadId:DWORD):THANDLE; stdcall;
type TGetPEProcess=function(ProcessID:DWORD):UINT64; stdcall;
type TGetPEThread=function(Threadid: dword):UINT64; stdcall;
type TGetDebugportOffset=function:DWORD; stdcall;
type TGetThreadsProcessOffset=function: dword; stdcall;
type TGetThreadListEntryOffset=function: dword; stdcall;



type TGetPhysicalAddress=function(hProcess:THandle;lpBaseAddress:pointer;var Address:int64): BOOL; stdcall;
type TGetCR4=function:ptrUint; stdcall;
type TGetCR3=function(hProcess:THANDLE;var CR3: QWORD):BOOL; stdcall;
type TSetCR3=function(hProcess:THANDLE;CR3: ptrUint):BOOL; stdcall;
type TGetCR0=function:ptrUint; stdcall;
type TGetSDT=function:ptrUint; stdcall;
type TGetSDTShadow=function:ptrUint; stdcall;


type TCreateRemoteAPC=function(threadid: dword; lpStartAddress: pointer): THandle; stdcall;


//type TStopDebugging=function: BOOL; stdcall;
//type TStopRegisterChange=function(regnr:integer):BOOL; stdcall;

//type TSetGlobalDebugState=function(state: boolean): BOOL; stdcall;
//type TsetAlternateDebugMethod=function(var int1apihook:dword; var OriginalInt1handler:dword):BOOL; stdcall;
//type TgetAlternateDebugMethod=function:BOOL; stdcall;

//type TChangeRegOnBP=function(Processid:dword; address: dword; debugreg: integer; changeEAX,changeEBX,changeECX,changeEDX,changeESI,changeEDI,changeEBP,changeESP,changeEIP,changeCF,changePF,changeAF,changeZF,changeSF,changeOF:BOOLEAN; newEAX,newEBX,newECX,newEDX,newESI,newEDI,newEBP,newESP,newEIP:DWORD; newCF,newPF,newAF,newZF,newSF,newOF:BOOLEAN):BOOLEAN; stdcall;
//type TDebugProcess=function(processid:dword;address:DWORD;size: byte;debugtype:byte):BOOL; stdcall;
//type TRetrieveDebugData=function(Buffer: pointer):integer; stdcall;

type TGetProcessNameFromID=function(processid:dword; buffer:pchar;buffersize:dword):integer; stdcall;
type TGetProcessNameFromPEProcess=function(peprocess:uint64; buffer:pchar;buffersize:dword):integer; stdcall;

type TStartProcessWatch=function:BOOL;stdcall;
type TWaitForProcessListData=function(processpointer:pointer;threadpointer:pointer;timeout:dword):dword; stdcall;

type TIsValidHandle=function(hProcess:THandle):BOOL; stdcall;
type TGetIDTCurrentThread=function:dword; stdcall;
type TGetIDTs=function(idtstore: pointer; maxidts: integer):integer; stdcall;
type TMakeWritable=function(Address,Size:dword;copyonwrite:boolean): boolean; stdcall;
type TGetLoadedState=function : BOOLEAN; stdcall;

type TDBKSuspendThread=function(ThreadID:dword):boolean; stdcall;
type TDBKResumeThread=function(ThreadID:dword):boolean; stdcall;
type TDBKSuspendProcess=function(ProcessID:dword):boolean; stdcall;
type TDBKResumeProcess=function(ProcessID:dword):boolean; stdcall;

type TKernelAlloc=function(size: dword):pointer; stdcall;
type TKernelAlloc64=function(size: dword):UINT64; stdcall;
type TGetKProcAddress=function(s: pwidechar):pointer; stdcall;
type TGetKProcAddress64=function(s: pwidechar):UINT64; stdcall;

type TGetSDTEntry=function (nr: integer; address: PDWORD; paramcount: PBYTE):boolean; stdcall;
type TGetSSDTEntry=function (nr: integer; address: PDWORD; paramcount: PBYTE):boolean; stdcall;
type TGetGDT=function(var limit: word):dword; stdcall;

type TisDriverLoaded=function(SigningIsTheCause: PBOOL): BOOL; stdcall;
type TLaunchDBVM=procedure(cpuid: integer); stdcall;


type TDBKDebug_ContinueDebugEvent=function(handled: BOOL): boolean; stdcall;
type TDBKDebug_WaitForDebugEvent=function(timeout: dword): boolean; stdcall;
type TDBKDebug_GetDebuggerState=function(state: PDebuggerstate): boolean; stdcall;
type TDBKDebug_SetDebuggerState=function(state: PDebuggerstate): boolean; stdcall;
type TDBKDebug_SetGlobalDebugState=function(state: BOOL): BOOL; stdcall;
type TDBKDebug_SetAbilityToStepKernelCode=function(state: boolean):BOOL; stdcall;
type TDBKDebug_StartDebugging=function(processid:dword):BOOL; stdcall;
type TDBKDebug_StopDebugging=function:BOOL; stdcall;
type TDBKDebug_GD_SetBreakpoint=function(active: BOOL; debugregspot: integer; Address: ptruint; breakType: TBreakType; breakLength: TbreakLength): BOOL; stdcall;

//-----------------------------------DBVM-------------------------------------//
type Tdbvm_version=function: dword; stdcall;
type Tdbvm_changeselectors=function(cs,ss,ds,es,fs,gs: dword): DWORD; stdcall;
type Tdbvm_restore_interrupts=function: DWORD; stdcall;
type Tdbvm_block_interrupts=function: DWORD; stdcall;
type Tdbvm_raise_privilege=function: DWORD; stdcall;


type Tdbvm_read_physical_memory=function(PhysicalAddress: UINT64; destination: pointer; size: integer): dword; stdcall;
type Tdbvm_write_physical_memory=function(PhysicalAddress: UINT64; source: pointer; size: integer): dword; stdcall;


type TVirtualQueryEx_StartCache=function(hProcess: THandle; flags: DWORD): boolean;
type TVirtualQueryEx_EndCache=procedure(hProcess: THandle);


procedure DONTUseDBKQueryMemoryRegion;
procedure DONTUseDBKReadWriteMemory;
procedure DONTUseDBKOpenProcess;
procedure UseDBKQueryMemoryRegion;
procedure UseDBKReadWriteMemory;
procedure UseDBKOpenProcess;

procedure DBKFileAsMemory(fn:string); overload;
procedure DBKFileAsMemory; overload;
function VirtualQueryExPhysical(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD): DWORD; stdcall;
procedure DBKPhysicalMemory;
procedure DBKPhysicalMemoryDBVM;
procedure DBKProcessMemory;
procedure LoadDBK32; stdcall;

procedure OutputDebugString(msg: string);


procedure NeedsDBVM;
function loaddbvmifneeded: BOOL; stdcall;
function isRunningDBVM: boolean;
function isDBVMCapable: boolean;

function isIntel: boolean;
function isAMD: boolean;

function Is64bitOS: boolean;
function Is64BitProcess(processhandle: THandle): boolean;

//I could of course have made it a parameter thing, but I'm lazy


function WriteProcessMemory(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesWritten: PTRUINT): BOOL; stdcall;




var
  EnumDeviceDrivers       :TEnumDeviceDrivers;
  GetDeviceDriverBaseNameA:TGetDeviceDriverBaseNameA;
  GetDeviceDriverFileName :TGetDeviceDriverFileName;


  ReadProcessMemory     :TReadProcessMemory;
  ReadProcessMemory64   :TReadProcessMemory64;  
  WriteProcessMemoryActual  :TWriteProcessMemory;
  //WriteProcessMemory64  :TWriteProcessMemory64;
  GetThreadContext      :TGetThreadContext;
  SetThreadContext      :TSetThreadContext;
  Wow64GetThreadContext      :TWow64GetThreadContext;
  Wow64SetThreadContext      :TWow64SetThreadContext;

  {$ifdef cpu64}
  GetThreadSelectorEntry: TGetThreadSelectorEntry;
  {$endif}

  SuspendThread         :TSuspendThread;
  ResumeThread          :TResumeThread;
  OpenProcess           :TOpenProcess;

  CreateToolhelp32Snapshot: TCreateToolhelp32Snapshot;
  Process32First        :TProcess32First;
  Process32Next         :TProcess32Next;
  Thread32First         :TThread32First;
  Thread32Next          :TThread32Next;
  Module32First         :TModule32First;
  Module32Next          :TModule32Next;
  Heap32ListFirst       :THeap32ListFirst;
  Heap32ListNext        :THeap32ListNext;
  IsWow64Process        :TIsWow64Process;


  WaitForDebugEvent     :TWaitForDebugEvent;
  ContinueDebugEvent    :TContinueDebugEvent;
  DebugActiveProcess    :TDebugActiveProcess;


  GetLargePageMinimum   :TGetLargePageMinimum;
  VirtualProtect        :TVirtualProtect;
  VirtualProtectEx      :TVirtualProtectEx;
  VirtualQueryEx        :TVirtualQueryEx;
  VirtualAllocEx        :TVirtualAllocEx;
  VirtualFreeEx         :TVirtualFreeEx;
  CreateRemoteThread    :TCreateRemoteThread;
  OpenThread            :TOpenThread;
//  GetPEProcess          :TGetPEProcess;
//  GetPEThread           :TGetPEThread;
  GetThreadsProcessOffset:TGetThreadsProcessOffset;
  GetThreadListEntryOffset:TGetThreadListEntryOffset;

  GetDebugportOffset    :TGetDebugportOffset;
  GetPhysicalAddress    :TGetPhysicalAddress;
  GetCR4                :TGetCR4;
  GetCR3                :TGetCR3;
  //SetCR3                :TSetCR3;
  GetCR0                :TGetCR0;
  GetSDT                :TGetSDT;
  GetSDTShadow          :TGetSDTShadow;

//  setAlternateDebugMethod: TsetAlternateDebugMethod;
//  getAlternateDebugMethod: TgetAlternateDebugMethod;

//  SetGlobalDebugState   :TSetGlobalDebugState;
//  DebugProcess          :TDebugProcess;
//  ChangeRegOnBP         :TChangeRegOnBP;
//  RetrieveDebugData     :TRetrieveDebugData;
//  StopDebugging         :TStopDebugging;
//  StopRegisterChange    :TStopRegisterChange;
  StartProcessWatch     :TStartProcessWatch;
  WaitForProcessListData:TWaitForProcessListData;
  GetProcessNameFromID  :TGetProcessNameFromID;
  GetProcessNameFromPEProcess:TGetProcessNameFromPEProcess;


  //KernelOpenProcess       :TOpenProcess;
//  KernelReadProcessMemory :TReadProcessMemory;
//  KernelReadProcessMemory64 :TReadProcessMemory64;
//  KernelWriteProcessMemory:TWriteProcessMemory;
//  KernelVirtualAllocEx    :TVirtualAllocEx;

  IsValidHandle           :TIsValidHandle;
  GetIDTCurrentThread     :TGetIDTCurrentThread;
  GetIDTs                 :TGetIDTs;
  MakeWritable            :TMakeWritable;
  GetLoadedState          :TGetLoadedState;

  DBKSuspendThread        :TDBKSuspendThread;
  DBKResumeThread         :TDBKResumeThread;
  DBKSuspendProcess       :TDBKSuspendProcess;
  DBKResumeProcess        :TDBKResumeProcess;

  KernelAlloc             :TKernelAlloc;
  KernelAlloc64           :TKernelAlloc64;  
  GetKProcAddress         :TGetKProcAddress;
  GetKProcAddress64       :TGetKProcAddress64;

  GetSDTEntry             :TGetSDTEntry;
  GetSSDTEntry            :TGetSSDTEntry;

  isDriverLoaded          :TisDriverLoaded;
  LaunchDBVM              :TLaunchDBVM;

  ReadPhysicalMemory      :TReadProcessMemory;
  WritePhysicalMemory     :TWriteProcessMemory;


  CreateRemoteAPC         :TCreateRemoteAPC;
  GetGDT                  :TGetGDT;


  DBKDebug_ContinueDebugEvent : TDBKDebug_ContinueDebugEvent;
  DBKDebug_WaitForDebugEvent  : TDBKDebug_WaitForDebugEvent;
  DBKDebug_GetDebuggerState   : TDBKDebug_GetDebuggerState;
  DBKDebug_SetDebuggerState   : TDBKDebug_SetDebuggerState;
  DBKDebug_SetGlobalDebugState: TDBKDebug_SetGlobalDebugState;
  DBKDebug_SetAbilityToStepKernelCode: TDBKDebug_SetAbilityToStepKernelCode;
  DBKDebug_StartDebugging     : TDBKDebug_StartDebugging;
  DBKDebug_StopDebugging      : TDBKDebug_StopDebugging;
  DBKDebug_GD_SetBreakpoint   : TDBKDebug_GD_SetBreakpoint;


  closeHandle                 : function (hObject:HANDLE):WINBOOL; stdcall;

  GetLogicalProcessorInformation: function(Buffer: PSYSTEM_LOGICAL_PROCESSOR_INFORMATION; ReturnedLength: PDWORD): BOOL; stdcall;
  PrintWindow                 : function (hwnd: HWND; hdcBlt: HDC; nFlags: UINT): BOOL; stdcall;
  ChangeWindowMessageFilter   : function (msg: Cardinal; Action: Dword): BOOL; stdcall;

  VirtualQueryEx_StartCache: TVirtualQueryEx_StartCache;
  VirtualQueryEx_EndCache: TVirtualQueryEx_EndCache;

  GetRegionInfo: function (hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD; var mapsline: string): DWORD;  stdcall;



 {    just include vmxfunctions
  //dbvm ce000000+
  dbvm_changeselectors    :Tdbvm_changeselectors;
  dbvm_block_interrupts   :Tdbvm_block_interrupts;
  dbvm_restore_interrupts :Tdbvm_restore_interrupts;
  dbvm_raise_privilege    :Tdbvm_raise_privilege;
  //dbvm ce000004+
  dbvm_read_physical_memory: Tdbvm_read_physical_memory;
  dbvm_write_physical_memory: Tdbvm_write_physical_memory; }

var
    WindowsKernel: Thandle;
    NTDLLHandle: THandle;

    //DarkByteKernel: Thandle;
    DBKLoaded: boolean;

    Usephysical: boolean;
    UseFileAsMemory: boolean;
    usephysicaldbvm: boolean;
    usedbkquery:boolean;
    DBKReadWrite: boolean;

    DenyList:boolean;
    DenyListGlobal: boolean;
    ModuleListSize: integer;
    ModuleList: pointer;



implementation

{$ifndef JNI}
uses
     {$ifdef cemain}
     plugin,
     dbvmPhysicalMemoryHandler, //'' for physical mem
     {$endif}
     filehandler,  //so I can let readprocessmemory point to ReadProcessMemoryFile in filehandler
     autoassembler, frmEditHistoryUnit, frmautoinjectunit;
{$endif}



resourcestring
  rsToUseThisFunctionYouWillNeedToRunDBVM = 'To use this function you will need to run DBVM. There is a high chance running DBVM can crash your system and make '
    +'you lose your data(So don''t forget to save first). Do you want to run DBVM?';
  rsDidNotLoadDBVM = 'I don''t know what you did, you didn''t crash, but you also didn''t load DBVM';
  rsPleaseRebootAndPressF8BeforeWindowsBoots = 'Please reboot and press f8 before windows boots. Then enable unsigned drivers. Alternatively, you could buy yourself a business '
    +'class certificate and sign the driver yourself (or try debug signing)';
  rsTheDriverNeedsToBeLoadedToBeAbleToUseThisFunction = 'The driver needs to be loaded to be able to use this function.';
  rsYourCpuMustBeAbleToRunDbvmToUseThisFunction = 'Your cpu must be able to run dbvm to use this function';
  rsCouldnTBeOpened = '%s couldn''t be opened';
  rsDBVMIsNotLoadedThisFeatureIsNotUsable = 'DBVM is not loaded. This feature is not usable';



{$ifndef JNI}
function WriteProcessMemory(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesWritten: PTRUINT): BOOL; stdcall;
var
  wle: PWriteLogEntry;
  x: PTRUINT;

begin
  wle:=nil;
  if logWrites then
  begin
    if nsize<64*1024*1024 then
    begin
      getmem(wle, sizeof(TWriteLogEntry));
      zeromemory(wle, sizeof(TWriteLogEntry));

      wle^.address:=ptruint(lpBaseAddress);

      getmem(wle.originalbytes, nsize);
      ReadProcessMemory(hProcess, lpBaseaddress,wle.originalbytes, nsize, x);
      wle^.originalsize:=x;
    end;
  end;

  result:=WriteProcessMemoryActual(hProcess, lpBaseAddress, lpbuffer, nSize, lpNumberOfBytesWritten);
  if result and logwrites and (wle<>nil) then
  begin
    getmem(wle^.newbytes, lpNumberOfBytesWritten);
    ReadProcessMemory(hProcess, lpBaseaddress,wle^.newbytes, lpNumberOfBytesWritten, x);
    wle^.newsize:=x;
    addWriteLogEntryToList(wle);
  end;

end;
{$else}

function WriteProcessMemory(hProcess: THandle; const lpBaseAddress: Pointer; lpBuffer: Pointer; nSize: DWORD; var lpNumberOfBytesWritten: PTRUINT): BOOL; stdcall;
begin
  result:=WriteProcessMemoryActual(hProcess, lpBaseAddress, lpbuffer, nSize, lpNumberOfBytesWritten);
end;

{$endif}

function VirtualQueryEx_StartCache_stub(hProcess: THandle; flags: dword): boolean;
begin
  result:=false;  //don't use it in windows
end;

procedure VirtualQueryEx_EndCache_stub(hProcess: THandle);
begin
end;

function Is64bitOS: boolean;
{$ifndef CPU64 }
var iswow64: BOOL;
{$endif}
begin
  {$ifndef CPU64 }

  result:=false;
  {$ifdef windows}
  if assigned(IsWow64Process) then
  begin
    iswow64:=false;
    if IsWow64Process(GetCurrentProcess,iswow64) and iswow64 then
      result:=true;
  end;
  {$endif}
  {$else}
  result:=true; //only a 64-bit os can run 64-bit apps
  {$endif}
end;

function Is64BitProcess(processhandle: THandle): boolean;
var iswow64: BOOL;
begin
{$ifdef windows}
  result:=true;
  if Is64bitOS then
  begin
    iswow64:=false;
    if IsWow64Process(processhandle,iswow64) then
    begin
      if iswow64 then
        result:=false; //running in 32-bit mode

    end
    else
      result:=false; //IsWo64Process failed, happens on OS'es that don't have this api implemented

  end else result:=false; //32-bit can't run 64
{$else}
  {$ifdef cpu64}
    result:=true;
  {$else}
    result:=false;
  {$endif}
{$endif}
end;

procedure NeedsDBVM;
begin
{$ifndef JNI}
  if (not isRunningDBVM) then
  begin
    if isDBVMCapable and (MessageDlg(rsToUseThisFunctionYouWillNeedToRunDBVM, mtWarning, [mbyes, mbno], 0)=mryes) then
    begin
      LaunchDBVM(-1);
      if not isRunningDBVM then raise exception.Create(rsDidNotLoadDBVM);
    end;

    if not isRunningDBVM then
      raise exception.create(rsDBVMIsNotLoadedThisFeatureIsNotUsable);
  end;
{$endif}

end;

function loaddbvmifneeded: BOOL;  stdcall;
var signed: BOOL;
begin
  result:=false;

{$ifndef JNI}
  loaddbk32;
  if assigned(isDriverLoaded) then
  begin
    result:=false;
    if is64bitos and (not isRunningDBVM) then
    begin
      if isDBVMCapable then
      begin
        signed:=false;
        if isDriverLoaded(@signed) then
        begin
          if MessageDlg(rsToUseThisFunctionYouWillNeedToRunDBVM, mtWarning, [mbyes, mbno], 0)=mryes then
          begin
            LaunchDBVM(-1);
            if not isRunningDBVM then raise exception.Create(rsDidNotLoadDBVM);
            result:=true;
          end;
        end else
        begin
          //the driver isn't loaded
          if signed then
          begin
            raise exception.Create(rsPleaseRebootAndPressF8BeforeWindowsBoots);
          end
          else
          begin
            raise exception.Create(rsTheDriverNeedsToBeLoadedToBeAbleToUseThisFunction);
          end;
        end;
      end else raise exception.Create(rsYourCpuMustBeAbleToRunDbvmToUseThisFunction);
    end
    else result:=true;

  end;
{$endif}
end;

function isRunningDBVM: boolean;
begin
{$ifdef windows}
  result:=dbvm_version>0;
{$else}
  result:=false;
{$endif}
end;

{$ifndef CPUX86_64 and ifndef CPUi386}
function isIntel: boolean;
begin
  result:=false;
end;

function isAMD: boolean;
begin
  result:=false;
end;

function isDBVMCapable: boolean;
begin
  result:=false;
end;

{$else}
function isIntel: boolean;
var a,b,c,d: dword;
begin
  asm

    push {$ifdef cpu64}rax{$else}eax{$endif}
    push {$ifdef cpu64}rbx{$else}ebx{$endif}
    push {$ifdef cpu64}rcx{$else}ecx{$endif}
    push {$ifdef cpu64}rdx{$else}edx{$endif}
    mov eax,0
    cpuid
    mov a,eax
    mov b,ebx
    mov c,ecx
    mov d,edx
    pop {$ifdef cpu64}rdx{$else}edx{$endif}
    pop {$ifdef cpu64}rcx{$else}ecx{$endif}
    pop {$ifdef cpu64}rbx{$else}ebx{$endif}
    pop {$ifdef cpu64}rax{$else}eax{$endif}
  end;

  //GenuineIntel check
  result:=(b=$756e6547) and (d=$49656e69) and (c=$6c65746e);
end;

function isAMD: boolean;
var a,b,c,d: dword;
begin
  asm

    push {$ifdef cpu64}rax{$else}eax{$endif}
    push {$ifdef cpu64}rbx{$else}ebx{$endif}
    push {$ifdef cpu64}rcx{$else}ecx{$endif}
    push {$ifdef cpu64}rdx{$else}edx{$endif}
    mov eax,0
    cpuid
    mov a,eax
    mov b,ebx
    mov c,ecx
    mov d,edx
    pop {$ifdef cpu64}rdx{$else}edx{$endif}
    pop {$ifdef cpu64}rcx{$else}ecx{$endif}
    pop {$ifdef cpu64}rbx{$else}ebx{$endif}
    pop {$ifdef cpu64}rax{$else}eax{$endif}
  end;

  result:=(b=$68747541) and (d=$69746e65) and (c=$444d4163);
end;

function isDBVMCapable: boolean;
var a,b,c,d: dword;
begin
  result:=false;
  if not isRunningDBVM then
  begin
    if isIntel then
    begin
      asm
        push {$ifdef cpu64}rax{$else}eax{$endif}
        push {$ifdef cpu64}rbx{$else}ebx{$endif}
        push {$ifdef cpu64}rcx{$else}ecx{$endif}
        push {$ifdef cpu64}rdx{$else}edx{$endif}
        mov eax,1
        cpuid
        mov a,eax
        mov b,ebx
        mov c,ecx
        mov d,edx
        pop {$ifdef cpu64}rdx{$else}edx{$endif}
        pop {$ifdef cpu64}rcx{$else}ecx{$endif}
        pop {$ifdef cpu64}rbx{$else}ebx{$endif}
        pop {$ifdef cpu64}rax{$else}eax{$endif}
      end;

      if ((c shr 5) and 1)=1 then //check for the intel-vt flag
        result:=true;
    end
    else
    if isAMD then
    begin
      //check if it supports SVM
      asm
        push {$ifdef cpu64}rax{$else}eax{$endif}
        push {$ifdef cpu64}rbx{$else}ebx{$endif}
        push {$ifdef cpu64}rcx{$else}ecx{$endif}
        push {$ifdef cpu64}rdx{$else}edx{$endif}
        mov eax,$80000001
        cpuid
        mov a,eax
        mov b,ebx
        mov c,ecx
        mov d,edx
        pop {$ifdef cpu64}rdx{$else}edx{$endif}
        pop {$ifdef cpu64}rcx{$else}ecx{$endif}
        pop {$ifdef cpu64}rbx{$else}ebx{$endif}
        pop {$ifdef cpu64}rax{$else}eax{$endif}
      end;

      if ((c shr 2) and 1)=1 then
        result:=true; //SVM is possible
    end;

  end;

end;

{$endif}


procedure LoadDBK32; stdcall;
begin
{$ifdef windows}
  if not DBKLoaded then
  begin
    outputdebugstring('LoadDBK32');



    DBK32Initialize;
    DBKLoaded:=(dbk32functions.hdevice<>0) and (dbk32functions.hdevice<>INVALID_HANDLE_VALUE);

    //DarkByteKernel:= LoadLibrary(dbkdll);
//    if DarkByteKernel=0 then exit; //raise exception.Create('Failed to open DBK32.dll');

    //the driver is loaded (I hope)

    //KernelVirtualAllocEx:=@dbk32functions.VAE; //GetProcAddress(darkbytekernel,'VAE');
   // KernelOpenProcess:=@dbk32functions.OP; //GetProcAddress(darkbytekernel,'OP');
   // KernelReadProcessMemory:=@dbk32functions.RPM; //GetProcAddresS(darkbytekernel,'RPM');
  //  KernelReadProcessMemory64:=@dbk32functions.RPM64; //GetProcAddresS(darkbytekernel,'RPM64');
  //  KernelWriteProcessMemory:=@dbk32functions.WPM; //GetProcAddress(darkbytekernel,'WPM');
  //  ReadProcessMemory64:=@dbk32functions.RPM64; //GetProcAddress(DarkByteKernel,'RPM64');
//    WriteProcessMemory64:=@dbk32functions.WPM64; //GetProcAddress(DarkByteKernel,'WPM64');

//    GetPEProcess:=@dbk32functions.GetPEProcess; //GetProcAddress(DarkByteKernel,'GetPEProcess');
//    GetPEThread:=@dbk32functions.GetPEThread; //GetProcAddress(DarkByteKernel,'GetPEThread');
    GetThreadsProcessOffset:=@dbk32functions.GetThreadsProcessOffset; //GetProcAddress(DarkByteKernel,'GetThreadsProcessOffset');
    GetThreadListEntryOffset:=@dbk32functions.GetThreadListEntryOffset; //GetProcAddress(DarkByteKernel,'GetThreadListEntryOffset');
    GetDebugportOffset:=@dbk32functions.GetDebugportOffset; //GetProcAddresS(DarkByteKernel,'GetDebugportOffset');
    GetPhysicalAddress:=@dbk32functions.GetPhysicalAddress; //GetProcAddresS(DarkByteKernel,'GetPhysicalAddress');
    GetCR4:=@dbk32functions.GetCR4; //GetProcAddress(DarkByteKernel,'GetCR4');
    GetCR3:=@dbk32functions.GetCR3;
//    SetCR3:=@dbk32functions.SetCR3;
    GetCR0:=@dbk32functions.GetCR0;
    GetSDT:=@dbk32functions.GetSDT;
    GetSDTShadow:=@dbk32functions.GetSDTShadow;

//    setAlternateDebugMethod:=@setAlternateDebugMethod;
//    getAlternateDebugMethod:=@getAlternateDebugMethod;
//    DebugProcess:=@DebugProcess;
//    StopDebugging:=@StopDebugging;
//    StopRegisterChange:=@StopRegisterChange;
//    RetrieveDebugData:=@RetrieveDebugData;
//    ChangeRegOnBP:=@ChangeRegOnBP;
    StartProcessWatch:=@dbk32functions.StartProcessWatch;
    WaitForProcessListData:=@dbk32functions.WaitForProcessListData;
    GetProcessNameFromID:=@dbk32functions.GetProcessNameFromID;
    GetProcessNameFromPEProcess:=@dbk32functions.GetProcessNameFromPEProcess;

    IsValidHandle:=@dbk32functions.IsValidHandle;


    GetIDTs:=@dbk32functions.GetIDTs;

    GetIDTCurrentThread:=@dbk32functions.GetIDTCurrentThread;
    GetGDT:=@dbk32functions.GetGDT;
    MakeWritable:=@dbk32functions.MakeWritable;
    GetLoadedState:=@dbk32functions.GetLoadedState;

    DBKResumeThread:=@dbk32functions.DBKResumeThread;
    DBKSuspendThread:=@dbk32functions.DBKSuspendThread;

    DBKResumeProcess:=@dbk32functions.DBKResumeProcess;
    DBKSuspendProcess:=@dbk32functions.DBKSuspendProcess;

    KernelAlloc:=@dbk32functions.KernelAlloc;
    KernelAlloc64:=@dbk32functions.KernelAlloc64;
    GetKProcAddress:=@dbk32functions.GetKProcAddress;
    GetKProcAddress64:=@dbk32functions.GetKProcAddress64;

    GetSDTEntry:= @dbk32functions.GetSDTEntry;
    GetSSDTEntry:=@dbk32functions.GetSSDTEntry;

    isDriverLoaded:=@dbk32functions.isDriverLoaded;
    LaunchDBVM:=@dbk32functions.LaunchDBVM;

    ReadPhysicalMemory:=@dbk32functions.ReadPhysicalMemory;
    WritePhysicalMemory:=@dbk32functions.WritePhysicalMemory;

    CreateRemoteAPC:=@dbk32functions.CreateRemoteAPC;
//    SetGlobalDebugState:=@SetGlobalDebugState;

    DBKDebug_ContinueDebugEvent:=@debug.DBKDebug_ContinueDebugEvent;
    DBKDebug_WaitForDebugEvent:=@debug.DBKDebug_WaitForDebugEvent;
    DBKDebug_GetDebuggerState:=@debug.DBKDebug_GetDebuggerState;
    DBKDebug_SetDebuggerState:=@debug.DBKDebug_SetDebuggerState;

    DBKDebug_SetGlobalDebugState:=@debug.DBKDebug_SetGlobalDebugState;
    DBKDebug_SetAbilityToStepKernelCode:=@debug.DBKDebug_SetAbilityToStepKernelCode;
    DBKDebug_StartDebugging:=@debug.DBKDebug_StartDebugging;
    DBKDebug_StopDebugging:=@debug.DBKDebug_StopDebugging;
    DBKDebug_GD_SetBreakpoint:=@debug.DBKDebug_GD_SetBreakpoint;




    {$ifdef cemain}
    if pluginhandler<>nil then
      pluginhandler.handlechangedpointers(0);
    {$endif}

  end;
{$endif}
end;


procedure DBKFileAsMemory; overload;
{Changes the redirection of ReadProcessMemory, WriteProcessMemory and VirtualQueryEx to FileHandler.pas's ReadProcessMemoryFile, WriteProcessMemoryFile and VirtualQueryExFile }
begin
{$ifdef windows}
  UseFileAsMemory:=true;
  usephysical:=false;
  Usephysicaldbvm:=false;
  ReadProcessMemory:=@ReadProcessMemoryFile;
  WriteProcessMemoryActual:=@WriteProcessMemoryFile;
  VirtualQueryEx:=@VirtualQueryExFile;


  {$ifdef cemain}
  if pluginhandler<>nil then
    pluginhandler.handlechangedpointers(3);
  {$endif}
{$endif}
end;

procedure DBKFileAsMemory(fn:string); overload;
begin
{$ifdef windows}
  filehandler.filename:=filename;
  filehandler.filedata:=tmemorystream.create;
  filehandler.filedata.LoadFromFile(fn);
  DBKFileAsMemory;
{$endif}
end;

function VirtualQueryExPhysical(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD): DWORD; stdcall;
var buf:_MEMORYSTATUS;
begin
{$ifdef windows}

  if dbk32functions.hdevice<>INVALID_HANDLE_VALUE then
  begin
    result:=dbk32functions.VirtualQueryExPhysical(hProcess, lpAddress, lpBuffer, dwLength);
  end
  else
  begin
    GlobalMemoryStatus(buf);

    lpBuffer.BaseAddress:=pointer((ptrUint(lpAddress) div $1000)*$1000);
    lpbuffer.AllocationBase:=lpbuffer.BaseAddress;
    lpbuffer.AllocationProtect:=PAGE_EXECUTE_READWRITE;
    lpbuffer.RegionSize:=buf.dwTotalPhys-ptrUint(lpBuffer.BaseAddress);
    lpbuffer.RegionSize:=lpbuffer.RegionSize+($1000-lpbuffer.RegionSize mod $1000);

    lpbuffer.State:=mem_commit;
    lpbuffer.Protect:=PAGE_EXECUTE_READWRITE;
    lpbuffer._Type:=MEM_PRIVATE;

    if (ptrUint(lpAddress)>buf.dwTotalPhys) //bigger than the total ammount of memory
    then
    begin
      zeromemory(@lpbuffer,dwlength);
      result:=0
    end
    else
      result:=dwlength;

  end;
{$endif}
end;

procedure DBKPhysicalMemoryDBVM;
{Changes the redirection of ReadProcessMemory, WriteProcessMemory and VirtualQueryEx to dbvm's read/write physical memory}
begin
{$ifdef cemain}
  UseFileAsMemory:=false;
  usephysical:=false;
  usephysicaldbvm:=true;
  ReadProcessMemory:=@ReadProcessMemoryPhys;
  WriteProcessMemoryActual:=@WriteProcessMemoryPhys;
  VirtualQueryEx:=@VirtualQueryExPhys;


  if pluginhandler<>nil then
    pluginhandler.handlechangedpointers(3);

{$endif}
end;

procedure DBKPhysicalMemory;
begin
{$ifdef windows}
  LoadDBK32;
  If DBKLoaded=false then exit;

  UsePhysical:=true;
  Usephysicaldbvm:=false;
  if usefileasmemory then
  begin
    if filedata<>nil then
      freeandnil(filedata);
  end;
  usefileasmemory:=false;
  ReadProcessMemory:=@ReadPhysicalMemory;
  WriteProcessMemoryActual:=@WritePhysicalMemory;
  VirtualQueryEx:=@VirtualQueryExPhysical;


  {$ifdef cemain}
  if pluginhandler<>nil then
    pluginhandler.handlechangedpointers(4);
  {$endif}
{$endif}
end;

procedure DBKProcessMemory;
begin
{$ifdef windows}
  if dbkreadwrite then
    UseDBKReadWriteMemory
  else
    dontUseDBKReadWriteMemory;

  if usedbkquery then
    Usedbkquerymemoryregion
  else
    dontusedbkquerymemoryregion;

  usephysical:=false;
  Usephysicaldbvm:=false;

  if filedata<>nil then
    freeandnil(filedata);

  usefileasmemory:=false;
{$endif}
end;



procedure DontUseDBKQueryMemoryRegion;
{Changes the redirection of VirtualQueryEx back to the windows API virtualQueryEx}
begin
{$ifdef windows}
  VirtualQueryEx:=GetProcAddress(WindowsKernel,'VirtualQueryEx');
  usedbkquery:=false;
  if usephysicaldbvm then DbkPhysicalMemoryDBVM;
  if usephysical then DbkPhysicalMemory;
  if usefileasmemory then dbkfileasmemory;

  {$ifdef cemain}
  if pluginhandler<>nil then
    pluginhandler.handlechangedpointers(5);
  {$endif}
{$endif}
end;

procedure UseDBKQueryMemoryRegion;
{Changes the redirection of VirtualQueryEx to the DBK32 equivalent}
begin
{$ifdef windows}
  LoadDBK32;
  If DBKLoaded=false then exit;
  UseDBKOpenProcess;
  VirtualQueryEx:=@VQE;
  usedbkquery:=true;

  if usephysical then DbkPhysicalMemory;
  if usephysicaldbvm then DBKPhysicalMemoryDBVM;
  if usefileasmemory then dbkfileasmemory;


  {$ifdef cemain}
  if pluginhandler<>nil then
    pluginhandler.handlechangedpointers(6);
  {$endif}
{$endif}
end;

procedure DontUseDBKReadWriteMemory;
{Changes the redirection of ReadProcessMemory and WriteProcessMemory back to the windows API ReadProcessMemory and WriteProcessMemory }
begin
{$ifdef windows}
  DBKReadWrite:=false;
  ReadProcessMemory:=GetProcAddress(WindowsKernel,'ReadProcessMemory');
  WriteProcessMemoryActual:=GetProcAddress(WindowsKernel,'WriteProcessMemory');
  VirtualAllocEx:=GetProcAddress(WindowsKernel,'VirtualAllocEx');
  if usephysical then DbkPhysicalMemory;
  if usephysicaldbvm then DBKPhysicalMemoryDBVM;
  if usefileasmemory then dbkfileasmemory;

  {$ifdef cemain}
  if pluginhandler<>nil then
    pluginhandler.handlechangedpointers(7);
  {$endif}
{$endif}
end;

procedure UseDBKReadWriteMemory;
{Changes the redirection of ReadProcessMemory, WriteProcessMemory and VirtualQueryEx to the DBK32 equiv: RPM, WPM and VAE }
var
  nthookscript: Tstringlist;
  func: pointer;
  old: pointer;
  olds: string;
begin
{$ifdef windows}
  LoadDBK32;
  If DBKLoaded=false then exit;
  UseDBKOpenProcess;
  ReadProcessMemory:=@RPM;
  WriteProcessMemoryActual:=@WPM;
  VirtualAllocEx:=@VAE;
  DBKReadWrite:=true;
  if usephysical then DbkPhysicalMemory;
  if usephysicaldbvm then DBKPhysicalMemoryDBVM;
  if usefileasmemory then dbkfileasmemory;

  {$ifdef cemain}
  if pluginhandler<>nil then
    pluginhandler.handlechangedpointers(8);
  {$endif}
{$endif}

{$ifdef privatebuild}
  if not assigned(OldNtQueryInformationProcess) then
  begin
    nthookscript:=tstringlist.create;

    func:=GetProcAddress(NTDLLHandle,'NtQueryInformationProcess');
    generateAPIHookScript(nthookscript,IntToHex(ptruint(func),8),IntToHex(ptruint(@dbk_NtQueryInformationProcess),8),inttohex(ptruint(@@oldNtQueryInformationProcess),8),'0',true);
    autoassemble(nthookscript, false, true, false, true);

    nthookscript.clear;

    func:=GetProcAddress(NTDLLHandle,'NtReadVirtualMemory');
    generateAPIHookScript(nthookscript,IntToHex(ptruint(func),8),IntToHex(ptruint(@dbk_NtReadVirtualMemory),8),inttohex(ptruint(@@oldNtReadVirtualMemory),8),'0',true);
    autoassemble(nthookscript, false, true, false, true);

    nthookscript.free;
  end;
{$endif}

end;

procedure DontUseDBKOpenProcess;
{Changes the redirection of OpenProcess and VirtualAllocEx  back to the windows API OpenProcess and VirtualAllocEx }
begin
{$ifdef windows}
  OpenProcess:=GetProcAddress(WindowsKernel,'OpenProcess');
  OpenThread:=GetProcAddress(WindowsKernel,'OpenThread');

  {$ifdef cemain}
  pluginhandler.handlechangedpointers(9);
  {$endif}
{$endif}
end;

procedure UseDBKOpenProcess;
var
  nthookscript: Tstringlist;
  zwc: pointer;
  func: pointer;
begin
{$ifdef windows}
  LoadDBK32;
  If DBKLoaded=false then exit;
  OpenProcess:=@OP; //gives back the real handle, or if it fails it gives back a value only valid for the dll
  OpenThread:=@OT;

  {$ifdef privatebuild}
  nthookscript:=tstringlist.create;

  if not assigned(oldNtOpenProcess) then
  begin
    nthookscript.clear;
    func:=GetProcAddress(NTDLLHandle,'NtOpenProcess');
    generateAPIHookScript(nthookscript,IntToHex(ptruint(func),8),IntToHex(ptruint(@NOP),8),IntToHex(ptruint(@@oldNtOpenProcess),8),'0',true);
    autoassemble(nthookscript, false, true, false, true);
  end;



  //nthookscript.add('NtOpenProcess:');
  //nthookscript.add('jmp '+IntToHex(ptruint(@NOP),8));
  //autoassemble(nthookscript, false, true, false, true);


  if not assigned(oldZwClose) then
  begin
    nthookscript.clear;
    func:=GetProcAddress(NTDLLHandle,'NtClose');
    generateAPIHookScript(nthookscript,IntToHex(ptruint(func),8),IntToHex(ptruint(@ZC),8),IntToHex(ptruint(@@oldZwClose),8),'0',true);
    autoassemble(nthookscript, false, true, false, true);
  end;


  nthookscript.free;
  {$endif}  //bypass

  {$ifdef cemain}
  pluginhandler.handlechangedpointers(10);
  {$endif}
{$endif}  //windows
end;

function GetLargePageMinimumStub: SIZE_T; stdcall;
begin
  result:=0;
end;

procedure OutputDebugString(msg: string);
begin
{$ifdef windows}
  windows.outputdebugstring(pchar(msg));
{$endif}

{$ifdef android}
  log(msg);
{$endif}
end;

procedure getLBROffset;
var x: TDebuggerState;
begin
  OutputDebugString('Offset of LBR_Count='+inttostr(ptruint(@x.LBR_Count)-ptruint(@x)));
  OutputDebugString('sizeof fxstate = '+inttostr(sizeof(x.fxstate)));
end;

function NoGetLogicalProcessorInformation(Buffer: PSYSTEM_LOGICAL_PROCESSOR_INFORMATION; ReturnedLength: PDWORD): BOOL; stdcall;
begin
  ReturnedLength^:=0;
  result:=false;
end;


{$ifdef windows}
function GetRegionInfo_Windows(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD; var mapsline: string): DWORD;  stdcall;
var
  i: integer;
  mappedfilename: pchar;

begin
  result:=VirtualQueryEx(hProcess, lpAddress, lpBuffer, dwLength);

  if (result=sizeof(lpbuffer)) then
  begin
    getmem(mappedfilename,256);
    i:=GetMappedFileName(hProcess,lpBuffer.BaseAddress, mappedfilename, 255);
    mappedfilename[i]:=#0;
    mapsline:=mappedfilename;

    freemem(mappedfilename);
    mappedfilename:=nil;
  end;
end;
{$endif}


function GetRegionInfo_Stub(hProcess: THandle; lpAddress: Pointer; var lpBuffer: TMemoryBasicInformation; dwLength: DWORD; var mapsline: string): DWORD;  stdcall;
begin
  result:=VirtualQueryEx(hProcess, lpAddress, lpBuffer, dwLength);
  mapsline:='';
end;

var
  psa: thandle;
  u32: thandle;


resourcestring
  rsfucked='Something is really messed up on your computer! You don''t seem to have a kernel!!!!';

initialization
  DBKLoaded:=false;

  usephysical:=false;
  Usephysicaldbvm:=false;
  usefileasmemory:=false;
  usedbkquery:=false;

  DenyList:=true;
  DenyListGlobal:= false;
  ModuleListSize:= 0;
  ModuleList:= nil;
  Denylist:= false;
  //globaldenylist:= false;

  VirtualQueryEx_StartCache:=VirtualQueryEx_StartCache_stub;
  VirtualQueryEx_EndCache:=VirtualQueryEx_EndCache_stub;

{$ifndef jni}
  WindowsKernel:=LoadLibrary('Kernel32.dll'); //there is no kernel33.dll
  if WindowsKernel=0 then Raise Exception.create(rsFucked);

  NTDLLHandle:=LoadLibrary('ntdll.dll');



  //by default point to these exports:
  ReadProcessMemory:=GetProcAddress(WindowsKernel,'ReadProcessMemory');
  WriteProcessMemoryActual:=GetProcAddress(WindowsKernel,'WriteProcessMemory');

  OpenProcess:=GetProcAddress(WindowsKernel,'OpenProcess');

  VirtualQueryEx:=GetProcAddress(WindowsKernel,'VirtualQueryEx');
  VirtualAllocEx:=GetProcAddress(WindowsKernel,'VirtualAllocEx');
  VirtualFreeEx:=GetProcAddress(WindowsKernel,'VirtualFreeEx');


  GetThreadContext:=GetProcAddress(WindowsKernel,'GetThreadContext');
  SetThreadContext:=GetProcAddress(WindowsKernel,'SetThreadContext');

  Wow64GetThreadContext:=GetProcAddress(WindowsKernel,'Wow64GetThreadContext');
  Wow64SetThreadContext:=GetProcAddress(WindowsKernel,'Wow64SetThreadContext');

  {$ifdef cpu64}
  GetThreadSelectorEntry:=GetProcAddress(WindowsKernel,'Wow64GetThreadSelectorEntry');
  {$endif}


  SuspendThread:=GetProcAddress(WindowsKernel,'SuspendThread');
  ResumeThread:=GetProcAddress(WindowsKernel,'ResumeThread');
  WaitForDebugEvent:=GetProcAddress(WindowsKernel,'WaitForDebugEvent');
  ContinueDebugEvent:=GetProcAddress(WindowsKernel,'ContinueDebugEvent');
  DebugActiveProcess:=GetProcAddress(WindowsKernel,'DebugActiveProcess');
  VirtualProtect:=GetProcAddress(WindowsKernel,'VirtualProtect');
  VirtualProtectEx:=GetProcAddress(WindowsKernel,'VirtualProtectEx');
  CreateRemoteThread:=GetProcAddress(WindowsKernel,'CreateRemoteThread');
  OpenThread:=GetProcAddress(WindowsKernel,'OpenThread');

  CreateToolhelp32Snapshot:=GetProcAddress(WindowsKernel, 'CreateToolhelp32Snapshot');

  Process32First:=   GetProcAddress(WindowsKernel, 'Process32First');
  Process32Next:=    GetProcAddress(WindowsKernel, 'Process32Next');
  Thread32First:=    GetProcAddress(WindowsKernel, 'Thread32First');
  Thread32Next:=     GetProcAddress(WindowsKernel, 'Thread32Next');
  Module32First:=    GetProcAddress(WindowsKernel, 'Module32First');
  Module32Next:=     GetProcAddress(WindowsKernel, 'Module32Next');
  Heap32ListFirst:=  GetProcAddress(WindowsKernel, 'Heap32ListFirst');
  Heap32ListNext:=   GetProcAddress(WindowsKernel, 'Heap32ListNext');

  IsWow64Process:=   GetProcAddress(WindowsKernel, 'IsWow64Process');

  CloseHandle:=GetProcAddress(Windowskernel, 'CloseHandle');
  GetLogicalProcessorInformation:=GetProcAddress(Windowskernel, 'GetLogicalProcessorInformation');
  if not assigned(GetLogicalProcessorInformation) then
    GetLogicalProcessorInformation:=@NoGetLogicalProcessorInformation;


  GetLargePageMinimum:=GetProcAddress(WindowsKernel, 'GetLargePageMinimum');
  if not assigned(GetLargePageMinimum) then
    GetLargePageMinimum:=@GetLargePageMinimumStub;



  psa:=loadlibrary('Psapi.dll');
  EnumDeviceDrivers:=GetProcAddress(psa,'EnumDeviceDrivers');
  GetDevicedriverBaseNameA:=GetProcAddress(psa,'GetDeviceDriverBaseNameA');

  u32:=loadlibrary('user32.dll');
  PrintWindow:=GetProcAddress(u32,'PrintWindow');
  ChangeWindowMessageFilter:=GetProcAddress(u32,'ChangeWindowMessageFilter');

  {$ifdef windows}
  GetRegionInfo:=GetRegionInfo_Windows;
  {$else}
  GetRegionInfo:=GetRegionInfo_Stub;
  {$endif}



  getLBROffset;
{$else}


{$endif}


finalization

end.
