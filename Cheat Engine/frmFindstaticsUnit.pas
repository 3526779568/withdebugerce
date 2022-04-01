unit frmFindstaticsUnit;

{$MODE Delphi}

interface

uses
  jwawindows, windows, LCLIntf, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls,disassembler,CEFuncProc,NewKernelHandler,
  {tlhelp32,}symbolhandler, LResources, commonTypeDefs;

type TStaticlist=record
  s: ptrUint;
  isstruct: boolean;
  referencecount: dword;
  //referals: array of dword;
end;

type TUpdateType= (AddEntry,UpdateEntry);

type TStaticscanner = class (TThread)
  private
    updatetype: TUpdateType;
    updateline: integer; //not used for addentry

    memoryregion: array of tmemoryregion;
    procedure UpdateList;
    procedure done;
  public
    filterstart:ptrUint;
    filterstop:ptrUint;
    startaddress: ptrUint;
    stopaddress: ptrUint;
    onlyexecutable: boolean;
    progressbar: TProgressbar;
    procedure execute; override;
  end;

type

  { TfrmFindStatics }

  TfrmFindStatics = class(TForm)
    ProgressBar1: TProgressBar;
    Panel1: TPanel;
    Button1: TButton;
    Panel2: TPanel;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Edit3: TEdit;
    Label6: TLabel;
    Edit4: TEdit;
    Panel3: TPanel;
    ListView1: TListView;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ListView1ColumnClick(Sender: TObject; Column: TListColumn);
    procedure FormShow(Sender: TObject);
    procedure ListView1Compare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure ListView1DblClick(Sender: TObject);
  private
    { Private declarations }
    Staticscanner:TStaticScanner;
  public
    { Public declarations }
  end;

var
  frmFindStatics: TfrmFindStatics;
  staticlist: array of TStaticlist;

  LastSortedColumn :integer;
  Ascending : boolean;


implementation

uses MemoryBrowserFormUnit, ProcessHandlerUnit, Parsers;


resourcestring
  strScan='Scan';
  strStop='Stop';
  strStopping='Stopping...';
  rsFSStructOrArray = 'struct or array';
  rsFSUnreadablePointer = 'Unreadable pointer';

procedure TStaticScanner.UpdateList;
var x: tlistitem;
    i:integer;
    point: ptrUint;
    ar: ptrUint;
begin
  if updatetype=Addentry then
  begin
    i:=length(staticlist)-1;
    //add latest line to the list
    x:=frmfindstatics.ListView1.Items.Add;
    x.Caption:=IntToHex(staticlist[i].s,8);
    if staticlist[i].isstruct then
      x.SubItems.Add(rsFSStructOrArray)
    else
    begin
      point:=0;
      if ReadProcessMemory(processhandle,pointer(staticlist[i].s),@point,processhandler.pointersize,ar) then
      begin
        x.SubItems.add(IntToHex(point,8));
      end
      else x.SubItems.add(rsFSUnreadablePointer);
    end;

    x.SubItems.Add('1');
  end
  else
  begin
    //update entry
    x:=frmfindstatics.ListView1.Items[updateline];
    if staticlist[updateline].isstruct then
      x.SubItems[0]:=rsFSStructOrArray;


    x.SubItems[1]:=IntToStR(staticlist[updateline].referencecount);
  end;
end;

procedure TStaticScanner.done;
begin
  progressbar.position:=0;
  frmfindstatics.Button1.Caption:=strScan;
  frmfindstatics.staticscanner:=nil;
end;


procedure TStaticScanner.execute;
var oldpos,currentpos: ptrUint;
    i,j,k: integer;
    x,opcode:string;

    hexcount,hexstart: integer;
    isstruct: boolean;
    isstatic: boolean;
    _static: ptrUint;
    found: boolean;

    mbi: _MEMORY_BASIC_INFORMATION;

    oldshowsymbols: boolean;
    oldshowmodules: boolean;
    d: TDisassembler;
    s: string;
begin
  freeonterminate:=true;

  currentpos:=startaddress;
  i:=0;

  try
    d:=TDisassembler.Create;
    d.showmodules:=false;
    d.showsymbols:=false;


    while (not terminated) and (currentpos<=stopaddress) do
    begin
      virtualqueryEx(processhandle,pointer(currentpos),mbi,sizeof(mbi));
      if (mbi.State<>mem_commit) or ( (onlyexecutable and ((mbi.AllocationProtect and (PAGE_EXECUTE or PAGE_EXECUTE_READ or PAGE_EXECUTE_READWRITE	or PAGE_EXECUTE_WRITECOPY))=0))
      or (not onlyexecutable))
      then
      begin
        inc(currentpos,mbi.RegionSize);

        inc(i);
        i:=i mod 40;
        if i=0 then progressbar.position:=(currentpos-startaddress);
        continue;
      end;

      oldpos:=currentpos;

      opcode:=d.disassemble(currentpos,x);

      j:=pos('[',opcode);
      if j>0 then
      begin
        //it's got a [xxxxx] part
        //check if it contains a 8 digit hex value
        x:=copy(opcode,j+1,pos(']',opcode)-j-1);

        hexcount:=0;
        hexstart:=-1;
        isstruct:=false;
        isstatic:=false;

        for j:=1 to length(x) do
          if x[j] in ['0'..'9','a'..'f','A'..'F'] then
          begin
            if hexstart=-1 then hexstart:=j;
            inc(hexcount);
            if hexcount>=8 then
            begin
              //found one
              s:='';
              for k:=j to length(x) do //find the length of this hexstring
                if not (x[k] in ['0'..'9','a'..'f','A'..'F']) then
                  s:=copy(x,hexstart,k-hexstart+1);

              if s='' then s:=copy(x,hexstart,length(x)-hexstart+1);


              _static:=StrToQWordEx('$'+s);
              isstatic:=true;
            end;
          end else
          begin
            hexcount:=0;
            hexstart:=-1;
            isstruct:=true;
          end;
      end;


      if isstatic and (_static>=filterstart) and (_static<=filterstop) then
      begin
        found:=false;
        for j:=0 to length(staticlist)-1 do
          if staticlist[j].s=_static then
          begin
            inc(staticlist[j].referencecount);
            updatetype:=updateEntry;
            updateline:=j;
            synchronize(updatelist);

            found:=true;
            break;
          end;

        if not found then
        begin
          //add it to the list.
          k:=length(staticlist);
          setlength(staticlist,k+1);
          staticlist[k].s:=_static;
          staticlist[k].isstruct:=isstruct;
          staticlist[k].referencecount:=1;



  //        setlength(staticlist[k].referals,1);
   //       staticlist[k].referals[0]:=oldpos;

          updatetype:=addentry;
          synchronize(updatelist);
        end;
      end;

      inc(i);
      i:=i mod 40;
      if i=0 then progressbar.position:=(currentpos-startaddress);
    end;

  finally
    synchronize(done);

    d.free;
  end;

end;

procedure TfrmFindStatics.FormClose(Sender: TObject;
  var Action: TCloseAction);
var i: integer;
begin
  if staticscanner<>nil then
  begin
    staticscanner.Terminate;
    staticscanner:=nil;
  end else
  begin
  //  for i:=0 to length(staticlist)-1 do
 //     setlength(staticlist[i].referals,0);

    setlength(staticlist,0);
  end;
end;

procedure TfrmFindStatics.FormCreate(Sender: TObject);
var ths: thandle;
    me32: MODULEENTRY32;
    x: pchar;
    first:boolean;
    diff: integer;
begin
  if processhandler.is64bit then
  begin
    diff:=edit1.width;
    edit1.MaxLength:=16;
    edit2.MaxLength:=16;
    edit3.MaxLength:=16;
    edit4.MaxLength:=16;


    edit1.width:=edit1.width*2;
    edit2.width:=edit1.width;
    Edit3.width:=edit1.width;
    Edit4.width:=edit1.width;

    Edit3.text:='0000000000000000';
    Edit4.text:='7fffffffffffffff';


    width:=width+diff;
    panel1.width:=panel1.width+diff;
    button1.left:=(panel1.clientwidth div 2) - (button1.width div 2)
  end;

  ths:=CreateToolhelp32Snapshot(TH32CS_SNAPMODULE,processid);
  if ths<>0 then
  begin
    try
      first:=true;
      zeromemory(@me32,sizeof(me32));
      me32.dwSize:=sizeof(me32);
      if module32first(ths,me32) then
      begin
        edit1.text:=inttohex(ptrUint(me32.modBaseAddr),8);
        edit2.text:=inttohex(ptrUint(me32.modBaseAddr)+me32.modBaseSize,8);
      end;
    finally
      closehandle(ths);
    end;
  end;

  LastSortedColumn := -1;
  Ascending := True;
  button1.Caption:=strScan;



end;

procedure TfrmFindStatics.Button1Click(Sender: TObject);
begin
  if button1.Caption=strstopping then exit;

  if button1.Caption=strstop then
  begin
    button1.caption:=strStopping;
    staticscanner.Terminate;
    staticscanner:=nil;
  end
  else
  begin
    listview1.Clear;
    setlength(staticlist,0);
    
    staticscanner:=TStaticscanner.Create(true);
    staticscanner.startaddress:=StrToQWordEx('$'+edit1.Text);
    staticscanner.stopaddress:=StrToQWordEx('$'+edit2.Text);
    staticscanner.filterstart:=StrToQWordEx('$'+edit3.Text);
    staticscanner.filterstop:=StrToQWordEx('$'+edit4.Text);

    staticscanner.progressbar:=progressbar1;
    button1.Caption:=strStop;

    progressbar1.Max:=staticscanner.stopaddress-staticscanner.startaddress;

    staticscanner.onlyexecutable:=checkbox1.checked;

    staticscanner.start;
  end;

end;

procedure TfrmFindStatics.ListView1ColumnClick(Sender: TObject;
  Column: TListColumn);
var i: integer;
begin

  if staticscanner<>nil then exit;
  
  if Column.Index = LastSortedColumn then
    Ascending := not Ascending
  else
    LastSortedColumn := Column.Index;

  TListView(Sender).SortColumn:=column.index;
end;

procedure TfrmFindStatics.FormShow(Sender: TObject);
var diff: integer;
begin
  listview1.clear;

  if processhandler.is64Bit then
  begin
    edit1.Constraints.MinWidth:=canvas.TextWidth('DDDDDDDDDDDDDDDD')+4;
  end;

end;

procedure TfrmFindStatics.ListView1Compare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  case data of
    0: Compare := AnsiCompareText(Item1.Caption, Item2.Caption);
    1: Compare := AnsiCompareText(Item1.SubItems[0],Item2.SubItems[0]);
    2: Compare := StrToQWordEx(Item1.SubItems[1])-StrToQWordEx(Item2.SubItems[1]);
  end;

  if not Ascending then
    Compare := -Compare;
end;

procedure TfrmFindStatics.ListView1DblClick(Sender: TObject);
begin
  if listview1.Selected<>nil then
    memorybrowser.memoryaddress:=StrToQWordEx('$'+listview1.selected.caption);
end;

initialization
  {$i frmFindstaticsUnit.lrs}

end.

