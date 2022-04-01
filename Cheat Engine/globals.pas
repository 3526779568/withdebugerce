unit Globals;

{
This unit will hold some global variables (previously cefuncproc.pas)
}

{$mode delphi}

interface

uses
  Classes, SysUtils, commonTypeDefs;

var
//  AllIncludesCustomType: boolean;
  ScanAllTypes: TVariableTypes=[vtDword, vtSingle, vtDouble];

  buffersize: dword=512*1024;

  Skip_PAGE_NOCACHE: boolean=false;
  Scan_MEM_PRIVATE: boolean=true;
  Scan_MEM_IMAGE: boolean=true;
  Scan_MEM_MAPPED: boolean=false;

  scan_dirtyonly: boolean=true;
  scan_pagedonly: boolean=true;
  fetchSymbols: boolean=true;   //set to false if you don't want the symbols to get enumerated

  networkRPMCacheTimeout: single=1.0;

  systemtype: integer;
  old8087CW: word;  //you never know...
  ProcessSelected: Boolean;
  //ProcessID: Dword; //deperecated
  //ProcessHandle: Thandle;





  TablesDir: string;
  CheatEngineDir: String;
  WindowsDir: string;

  username: string;

//scanhelpers
  nrofbits: integer;
  Bitscan: array of byte;
  tempbits: array of byte;

  bitoffsetchange: integer;


  foundaddressB: array of TBitAddress;
  foundaddressBswitch: array of TBitAddress;


  tempbytearray: array of byte;
  tempwordarray: array of word;
  tempdwordarray: array of dword;
  tempsinglearray: array of single;
  tempdoublearray: array of double;
  tempint64array: array of int64;


//--------
  previousmemory: array of byte;
{  SearchAddress: array of dword;
  searchaddressswitch: array of dword;

  SearchAddressB: array of TBitAddress;}

 // previousmemory1,previousmemory1switch: array of Byte;
  {previousmemory2,previousmemory2switch: array of word;
  previousmemory3,previousmemory3switch: array of dword;
  previousmemory4,previousmemory4switch: array of Single;
  previousmemory5,previousmemory5switch: array of Double;
  previousmemory6,previousmemory6switch: array of int64; //Byte;
  PreviousMemory7,previousmemory7switch: Array of Int64;
  PreviousMemory8,previousmemory8switch: array of byte; }

//---------
  helpstr,helpstr2: string;
  bytes: array of integer;  //-1=wildcard
  bytearray: array of byte;



//  MemoryRegion: array of TMemoryRegion;
//  MemoryRegions: Integer;

//  Memory: Array of Byte;
  Memory: ^Byte;
  memory2: ^byte;


  advanced: boolean;
  //global files, so when an exception happens I can close them
//  addressfile, memoryfile: File;
//  newAddressfile,newmemoryfile: File;

  savedStackSize: dword=4096;

  overridedebug: boolean;

  totalbytes: dword;
  currentbyte: dword;


  //hide/show windows
  windowlist: array of thandle;
  lastforeground,lastactive: thandle;
  donthidelist: array of string;
  onlyfront: boolean;
  allwindowsareback:boolean;

  //HyperscanFileMapping: THandle;
  //HyperscanView: ^TScanSettings;

  hookedin:boolean;
  keysfilemapping: THandle;

  //stealth globals
  le: dword;
  ownprocesshandle: THandle;
  stealthhook: thandle;

  //windows version data
  iswin2kplus: boolean;
  scanpriority: TThreadPriority;

  useAPCtoInjectDLL: boolean=false;


  tempdir: pchar;
  dontusetempdir: boolean;
  tempdiralternative: string;

  VEHRealContextOnThreadCreation: boolean;
  waitafterguiupdate: boolean;


  fontmultiplication: single=1.0; //for some gui stuff


implementation

end.

