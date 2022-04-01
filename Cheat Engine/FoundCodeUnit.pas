unit FoundCodeUnit;

{$MODE Delphi}

interface

uses
  windows, LCLIntf, LResources, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, disassembler, ExtCtrls, Menus,
  NewKernelHandler, clipbrd, ComCtrls, fgl, formChangedAddresses, LastDisassembleData;

type
  Tcoderecord = class
  public
    address: ptrUint;
    size: integer;
    opcode: string;
    description: string;
   // eax,ebx,ecx,edx,esi,edi,ebp,esp,eip: dword;
    context: TContext;
    armcontext: TARMCONTEXT;
    stack: record
      savedsize: ptruint;
      stack: pbyte;
    end;
    hitcount: integer;
    diffcount: integer;
    LastDisassembleData: TLastDisassembleData;

    formChangedAddresses: TfrmChangedAddresses;
    procedure savestack;
    destructor destroy; override;
end;

type

  { TFoundCodeDialog }


  TFoundCodeDialog = class(TForm)
    FoundCodeList: TListView;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    miFindWhatAccesses: TMenuItem;
    miSaveTofile: TMenuItem;
    mInfo: TMemo;
    Panel1: TPanel;
    Description: TLabel;
    Panel4: TPanel;
    pmOptions: TPopupMenu;
    ReplacewithcodethatdoesnothingNOP1: TMenuItem;
    SaveDialog1: TSaveDialog;
    Showthisaddressinthedisassembler1: TMenuItem;
    Addtothecodelist1: TMenuItem;
    MoreInfo1: TMenuItem;
    Panel2: TPanel;
    btnOK: TButton;
    Panel3: TPanel;
    btnExtraInfo: TButton;
    btnAddToCodeList: TButton;
    btnOpenDisassembler: TButton;
    btnReplacewithnops: TButton;
    N1: TMenuItem;
    Copyselectiontoclipboard1: TMenuItem;
    Splitter1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FoundCodeListChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure FoundcodeListClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnReplacewithnopsClick(Sender: TObject);
    procedure btnOpenDisassemblerClick(Sender: TObject);
    procedure btnAddToCodeListClick(Sender: TObject);
    procedure FoundcodeListDblClick(Sender: TObject);
    procedure btnExtraInfoClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FoundCodeListSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure MenuItem1Click(Sender: TObject);
    procedure miFindWhatAccessesClick(Sender: TObject);
    procedure miSaveTofileClick(Sender: TObject);
    procedure pmOptionsPopup(Sender: TObject);
    procedure Copyselectiontoclipboard1Click(Sender: TObject);
  private
    { Private declarations }
    setcountwidth: boolean;
    procedure addInfo(Coderecord: TCoderecord);
    procedure moreinfo;
    function getSelection: string;
  public
    { Public declarations }

    addresswatched: ptruint;
    useexceptions: boolean;
    usesdebugregs: boolean;
    procedure AddRecord;
    procedure setChangedAddressCount(address :ptruint);

  end;


resourcestring
  strClose='Close';
  rsFCThesWillSetASiftwareBreakpointInt3OnEverySingleOpcodeEtc = 'This will set a Software Breakpoint (int3) on every single opcode that will be reported here. Are you sure ?';

//var
//  FoundCodeDialog: TFoundCodeDialog;

implementation

uses CEFuncProc, CEDebugger,debughelper, debugeventhandler, MemoryBrowserFormUnit,
     MainUnit,kerneldebugger, AdvancedOptionsUnit ,formFoundcodeListExtraUnit,
     MainUnit2, ProcessHandlerUnit, Globals, Parsers;

destructor TCodeRecord.Destroy;
begin
  if stack.stack<>nil then
  begin
    freemem(stack.stack);
    stack.stack:=nil;
  end;

  inherited destroy;
end;

procedure TCodeRecord.savestack;
var base: qword;
begin
  getmem(stack.stack, savedStackSize);
  if processhandler.SystemArchitecture=archarm then
    base:=armcontext.SP
  else
    base:=qword(context.{$ifdef cpu64}Rsp{$else}esp{$endif});

  if ReadProcessMemory(processhandle, pointer(base), stack.stack, savedStackSize, stack.savedsize)=false then
  begin
    //for some reason this sometimes returns 0 bytes read even if some of the bytes are readable.
    stack.savedsize:=4096-(base mod 4096);
    ReadProcessMemory(processhandle, pointer(base), stack.stack, stack.savedsize, stack.savedsize);
  end;
end;

procedure TFoundCodedialog.AddRecord;
{
Invoked by the debugger thread
It takes the data from the current thread and stores it in the processlist
}
var currentthread: TDebugThreadHandler;
  opcode: string;
  ldi: TLastDisassembleData;
  address,address2: ptrUint;
  desc: string;

  coderecord: TCodeRecord;
  i: integer;

  li: tlistitem;
  f: TfrmChangedAddresses;

  d: TDisassembler;
begin
  //the debuggerthread is idle at this point
  currentThread:=debuggerthread.CurrentThread;
  if currentthread<>nil then
  begin
    if processhandler.SystemArchitecture=archARM then
    begin
      address:=currentthread.armcontext.PC;
    end
    else
    begin
      address:=currentThread.context.{$ifdef cpu64}Rip{$else}eip{$endif};
      if usesdebugregs or useexceptions then //find out the previous opcode
      begin
        address2:=address;
        d:=TDisassembler.Create;
        d.disassemble(address2,desc);
        if copy(d.LastDisassembleData.opcode,1,3)<>'REP' then
          address:=previousopcode(address);

        d.free;
      end;
    end;



    //disassemble to get the opcode and size
    address2:=address;
    d:=TDisassembler.Create;
    opcode:=d.disassemble(address2,desc);
    ldi:=d.LastDisassembleData;


    d.free;

    //check if address is inside the list
    for i:=0 to foundcodelist.Items.Count-1 do
      if TCodeRecord(foundcodelist.Items[i].data).address=address then
      begin
        //it's already in the list
        inc(TCodeRecord(foundcodelist.Items[i].data).hitcount);
        if miFindWhatAccesses.checked then
          FoundcodeList.items[i].caption:=inttostr(TCodeRecord(foundcodelist.Items[i].data).hitcount)+' ('+inttostr(TCodeRecord(foundcodelist.Items[i].data).diffcount)+')'
        else
          FoundcodeList.items[i].caption:=inttostr(TCodeRecord(foundcodelist.Items[i].data).hitcount);

        exit;
      end;



    coderecord:=TCoderecord.create;
    coderecord.address:=address;
    coderecord.size:=address2-address;
    coderecord.opcode:=opcode;
    coderecord.description:=desc;
    coderecord.context:=currentthread.context^;
    coderecord.armcontext:=currentthread.armcontext;
    coderecord.LastDisassembleData:=ldi;
    coderecord.savestack;
    coderecord.hitcount:=1;


    li:=FoundCodeList.Items.Add;
    li.caption:='1';
    li.SubItems.add(opcode);
    li.data:=coderecord;

    if miFindWhatAccesses.Checked then //add it
      coderecord.formChangedAddresses:=debuggerthread.FindWhatCodeAccesses(address, self);  //ffffffuuuuuuuuuu. Rebuild again
  end;
end;


procedure TFoundCodedialog.setChangedAddressCount(address :ptruint);
var i: integer;
begin
  for i:=0 to foundcodelist.Items.Count-1 do
    if TCodeRecord(foundcodelist.Items[i].data).address=address then
    begin
      //increase the counter
      inc(TCodeRecord(foundcodelist.Items[i].data).diffcount);
      FoundcodeList.items[i].caption:=inttostr(TCodeRecord(foundcodelist.Items[i].data).hitcount)+' ('+inttostr(TCodeRecord(foundcodelist.Items[i].data).diffcount)+')';
      exit;
    end;
end;

procedure TFoundCodedialog.addInfo(Coderecord: TCoderecord);
var
  address: ptruint;
  disassembled: array[1..5] of string;
  firstchar: char;
  hexcount: integer;
  temp: string;
begin
  if processhandler.is64Bit then
    hexcount:=16
  else
    hexcount:=8;

  address:=Coderecord.address;
  address:=previousopcode(address);
  address:=previousopcode(address);

  disassembled[1]:=disassemble(address,temp);
  disassembled[2]:=disassemble(address,temp);

  if address<>coderecord.address then
  begin
    disassembled[1]:='';
    disassembled[2]:='';
    disassembled[3]:=coderecord.opcode;
    disassembled[4]:='';
    disassembled[5]:='';
  end
  else
  begin
    disassembled[3]:=disassemble(address,temp);
    disassembled[4]:=disassemble(address,temp);
    disassembled[5]:=disassemble(address,temp);
  end;

  minfo.Lines.BeginUpdate;
  try
    minfo.Lines.Add(disassembled[1]);
    minfo.Lines.Add(disassembled[2]);
    minfo.Lines.Add(disassembled[3]+' <<');
    minfo.Lines.Add(disassembled[4]);
    minfo.Lines.Add(disassembled[5]);
    minfo.Lines.Add('');

    if processhandler.SystemArchitecture=archarm then
    begin
      minfo.Lines.Add('R10='+inttohex(coderecord.armcontext.R0,8));
      minfo.Lines.Add('R11='+inttohex(coderecord.armcontext.R1,8));
      minfo.Lines.Add('R12='+inttohex(coderecord.armcontext.R2,8));
      minfo.Lines.Add('R13='+inttohex(coderecord.armcontext.R3,8));
      minfo.Lines.Add('R14='+inttohex(coderecord.armcontext.R4,8));
      minfo.Lines.Add('R15='+inttohex(coderecord.armcontext.R5,8));
      minfo.Lines.Add('R16='+inttohex(coderecord.armcontext.R6,8));
      minfo.Lines.Add('R17='+inttohex(coderecord.armcontext.R7,8));
      minfo.Lines.Add('R18='+inttohex(coderecord.armcontext.R8,8));
      minfo.Lines.Add('R19='+inttohex(coderecord.armcontext.R9,8));
      minfo.Lines.Add('R10='+inttohex(coderecord.armcontext.R10,8));
      minfo.Lines.Add('FP='+inttohex(coderecord.armcontext.FP,8));
      minfo.Lines.Add('IP='+inttohex(coderecord.armcontext.IP,8));
      minfo.Lines.Add('SP='+inttohex(coderecord.armcontext.SP,8));
      minfo.Lines.Add('LR='+inttohex(coderecord.armcontext.LR,8));
      minfo.Lines.Add('PC='+inttohex(coderecord.armcontext.PC,8));
      minfo.Lines.Add('CPSR='+inttohex(coderecord.armcontext.CPSR,8));
      minfo.Lines.Add('ORIG_R0='+inttohex(coderecord.armcontext.ORIG_R0,8));
    end
    else
    begin
      if processhandler.is64bit then
        firstchar:='R' else firstchar:='E';

      minfo.Lines.Add(firstchar+'AX='+IntToHex(coderecord.context.{$ifdef cpu64}Rax{$else}Eax{$endif},hexcount));
      minfo.Lines.Add(firstchar+'BX='+IntToHex(coderecord.context.{$ifdef cpu64}Rbx{$else}Ebx{$endif},hexcount));
      minfo.Lines.Add(firstchar+'CX='+IntToHex(coderecord.context.{$ifdef cpu64}Rcx{$else}Ecx{$endif},hexcount));
      minfo.Lines.Add(firstchar+'DX='+IntToHex(coderecord.context.{$ifdef cpu64}Rdx{$else}Edx{$endif},hexcount));
      minfo.Lines.Add(firstchar+'SI='+IntToHex(coderecord.context.{$ifdef cpu64}Rsi{$else}Esi{$endif},hexcount));
      minfo.Lines.Add(firstchar+'DI='+IntToHex(coderecord.context.{$ifdef cpu64}Rdi{$else}Edi{$endif},hexcount));
      minfo.Lines.Add(firstchar+'SP='+IntToHex(coderecord.context.{$ifdef cpu64}Rsp{$else}Esp{$endif},hexcount));
      minfo.Lines.Add(firstchar+'BP='+IntToHex(coderecord.context.{$ifdef cpu64}Rbp{$else}Ebp{$endif},hexcount));
      minfo.Lines.Add(firstchar+'IP='+IntToHex(coderecord.context.{$ifdef cpu64}Rip{$else}Eip{$endif},hexcount));

      {$ifdef cpu64}
      if processhandler.is64bit then
      begin
        minfo.Lines.Add('R8='+IntToHex(coderecord.context.r8,16));
        minfo.Lines.Add('R9='+IntToHex(coderecord.context.r9,16));
        minfo.Lines.Add('R10='+IntToHex(coderecord.context.r10,16));
        minfo.Lines.Add('R11='+IntToHex(coderecord.context.r11,16));
        minfo.Lines.Add('R12='+IntToHex(coderecord.context.r12,16));
        minfo.Lines.Add('R13='+IntToHex(coderecord.context.r13,16));
        minfo.Lines.Add('R14='+IntToHex(coderecord.context.r14,16));
        minfo.Lines.Add('R15='+IntToHex(coderecord.context.r15,16));
      end;
      {$endif}

    end;

    minfo.lines.add('');
    minfo.lines.add('');


  finally
    minfo.lines.EndUpdate;
  end;
end;

procedure TFoundCodedialog.moreinfo;
var
  disassembled: array[1..5] of record
    s: string;
    a: ptruint;
  end;

    address: ptrUint;
    itemindex: integer;
    temp,temp2: string;
    maxregistervalue: ptrUint;
    p: ptrUint;
    i: integer;
    coderecord: TCodeRecord;
    firstchar: string;



    w: integer;

    FormFoundCodeListExtra: TFormFoundCodeListExtra;

    ew: trect; //extra window rect
    cw: trect; //changed address window rect

    offset: integer;
begin
  itemindex:=foundcodelist.ItemIndex;
  if itemindex<>-1 then
  begin
    FormFoundCodeListExtra:=TFormFoundCodeListExtra.Create(application);
    if useexceptions then
      FormFoundCodeListExtra.Label18.Visible:=false
    else
      FormFoundCodeListExtra.Label18.Visible:=true;

    coderecord:=TCodeRecord(foundcodelist.items[itemindex].data);
    if coderecord.formChangedAddresses<>nil then
    begin
      if not coderecord.formChangedAddresses.visible then //override userdefined positioning
      begin
        LCLIntf.GetWindowRect(coderecord.formChangedAddresses.handle, cw);
        LCLIntf.GetWindowRect(FormFoundCodeListExtra.handle, ew);

        coderecord.formChangedAddresses.left:=(ew.Left-(cw.Right-cw.left));
        coderecord.formChangedAddresses.top:=FormFoundCodeListExtra.top;

      end;

      coderecord.formChangedAddresses.show;
    end;

    address:=coderecord.address;
    address:=previousopcode(address);
    address:=previousopcode(address);

    disassembled[1].a:=address;
    disassembled[1].s:=disassemble(address,temp);

    disassembled[2].a:=address;
    disassembled[2].s:=disassemble(address,temp);

    if address<>coderecord.address then
    begin
      disassembled[1].s:='';
      disassembled[2].s:='';
      disassembled[3].s:=coderecord.opcode;
      disassembled[4].s:='';
      disassembled[5].s:='';
    end
    else
    begin
      disassembled[3].a:=address;
      disassembled[3].s:=disassemble(address,temp);

      disassembled[4].a:=address;
      disassembled[4].s:=disassemble(address,temp);

      disassembled[5].a:=address;
      disassembled[5].s:=disassemble(address,temp);
    end;




    //convert disassembled strings to address+opcode only (no bytes)
    //xxxxxxxx - xx xx xx - opcode
    temp:=copy(disassembled[1].s,pos('-',disassembled[1].s)+2,length(disassembled[1].s));
    temp:=copy(temp,pos('-',temp)+2,length(temp));
    disassembled[1].s:=copy(disassembled[1].s,1,pos('-',disassembled[1].s))+' '+temp;

    temp:=copy(disassembled[2].s,pos('-',disassembled[2].s)+2,length(disassembled[2].s));
    temp:=copy(temp,pos('-',temp)+2,length(temp));
    disassembled[2].s:=copy(disassembled[2].s,1,pos('-',disassembled[2].s))+' '+temp;

    temp:=copy(disassembled[3].s,pos('-',disassembled[3].s)+2,length(disassembled[3].s));
    temp:=copy(temp,pos('-',temp)+2,length(temp));
    disassembled[3].s:=copy(disassembled[3].s,1,pos('-',disassembled[3].s))+' '+temp;

    temp:=copy(disassembled[4].s,pos('-',disassembled[4].s)+2,length(disassembled[4].s));
    temp:=copy(temp,pos('-',temp)+2,length(temp));
    disassembled[4].s:=copy(disassembled[4].s,1,pos('-',disassembled[4].s))+' '+temp;

    temp:=copy(disassembled[5].s,pos('-',disassembled[5].s)+2,length(disassembled[5].s));
    temp:=copy(temp,pos('-',temp)+2,length(temp));
    disassembled[5].s:=copy(disassembled[5].s,1,pos('-',disassembled[5].s))+' '+temp;



    with FormFoundCodeListExtra do
    begin
      Label1.Caption:=disassembled[1].s;
      Label1.tag:=disassembled[1].a;

      Label2.Caption:=disassembled[2].s;
      Label2.tag:=disassembled[2].a;

      Label3.Caption:=disassembled[3].s;
      Label3.tag:=disassembled[3].a;

      Label4.Caption:=disassembled[4].s;
      Label4.tag:=disassembled[4].a;

      Label5.Caption:=disassembled[5].s;
      Label5.tag:=disassembled[5].a;

      if processhandler.SystemArchitecture=archarm then
      begin
        //repurpose the x86 32-bit labels
        lblRAX.caption:=' R0='+IntToHex(coderecord.armcontext.R0,8);
        lblRDX.caption:=' R1='+IntToHex(coderecord.armcontext.R1,8);
        lblRBP.caption:=' R2='+IntToHex(coderecord.armcontext.R2,8);
        lblRBX.caption:=' R3='+IntToHex(coderecord.armcontext.R3,8);
        lblRSI.caption:=' R4='+IntToHex(coderecord.armcontext.R4,8);
        lblRSP.caption:=' R5='+IntToHex(coderecord.armcontext.R5,8);
        lblRCX.caption:=' R6='+IntToHex(coderecord.armcontext.R6,8);
        lblRDI.caption:=' R7='+IntToHex(coderecord.armcontext.R7,8);
        lblRIP.caption:=' R8='+IntToHex(coderecord.armcontext.R8,8);

        lblR9:=tlabel.Create(FormFoundCodeListExtra);
        lblR9.Top:=lblRCX.top+(lblRCX.top-lblRBX.top);
        lblR9.left:=lblRCX.left;
        lblR9.caption:=' R9='+IntToHex(coderecord.armcontext.R9,8);
        lblR9.parent:=FormFoundCodeListExtra.panel6;
        lblR9.OnMouseDown:=registerMouseDown;
        lblR9.OnDblClick:=RegisterDblClick;
        lblR9.Align:=lblrcx.Align;

        lblR10:=tlabel.Create(FormFoundCodeListExtra);
        lblR10.Top:=lblRCX.top+(lblRCX.top-lblRBX.top);
        lblR10.left:=lblRDI.left;
        lblR10.caption:='R10='+IntToHex(coderecord.armcontext.R10,8);
        lblR10.parent:=FormFoundCodeListExtra.panel6;
        lblR10.OnMouseDown:=registerMouseDown;
        lblR10.OnDblClick:=RegisterDblClick;
        lblR10.Align:=lblrcx.Align;

        lblR11:=tlabel.Create(FormFoundCodeListExtra);
        lblR11.Top:=lblRCX.top+(lblRCX.top-lblRBX.top);
        lblR11.left:=lblRIP.left;
        lblR11.caption:=' FP='+IntToHex(coderecord.armcontext.FP,8);
        lblR11.parent:=FormFoundCodeListExtra.panel6;
        lblR11.OnMouseDown:=registerMouseDown;
        lblR11.OnDblClick:=RegisterDblClick;
        lblR11.Align:=lblrcx.Align;
                //new row
        lblR12:=tlabel.Create(FormFoundCodeListExtra);
        lblR12.Top:=lblR9.top+(lblRCX.top-lblRBX.top);
        lblR12.left:=lblRCX.left;
        lblR12.caption:=' IP='+IntToHex(coderecord.armcontext.IP,8);
        lblR12.parent:=FormFoundCodeListExtra.panel6;
        lblR12.OnMouseDown:=registerMouseDown;
        lblR12.OnDblClick:=RegisterDblClick;
        lblR12.Align:=lblrcx.Align;

        lblR13:=tlabel.Create(FormFoundCodeListExtra);
        lblR13.Top:=lblR9.top+(lblRCX.top-lblRBX.top);
        lblR13.left:=lblRDI.left;
        lblR13.caption:=' SP='+IntToHex(coderecord.armcontext.SP,8);
        lblR13.parent:=FormFoundCodeListExtra.panel6;
        lblR13.OnMouseDown:=registerMouseDown;
        lblR13.OnDblClick:=RegisterDblClick;
        lblR13.Align:=lblrcx.Align;

        lblR14:=tlabel.Create(FormFoundCodeListExtra);
        lblR14.Top:=lblR9.top+(lblRCX.top-lblRBX.top);
        lblR14.left:=lblRIP.left;
        lblR14.caption:=' LR='+IntToHex(coderecord.armcontext.LR,8);
        lblR14.parent:=FormFoundCodeListExtra.panel6;
        lblR14.OnMouseDown:=registerMouseDown;
        lblR14.OnDblClick:=RegisterDblClick;
        lblR14.Align:=lblrcx.Align;
        //new line

        lblR15:=tlabel.Create(FormFoundCodeListExtra);
        lblR15.Top:=lblR12.top+(lblRCX.top-lblRBX.top);
        lblR15.left:=lblRCX.left;
        lblR15.caption:=' PC='+IntToHex(coderecord.armcontext.PC,8);
        lblR15.parent:=FormFoundCodeListExtra.panel6;
        lblR15.OnMouseDown:=registerMouseDown;
        lblR15.OnDblClick:=RegisterDblClick;
        lblR15.Align:=lblrcx.Align;

        lblR16:=tlabel.Create(FormFoundCodeListExtra);
        lblR16.Top:=lblR12.top+(lblRCX.top-lblRBX.top);
        lblR16.left:=lblRDI.left;
        lblR16.caption:=' CPSR='+IntToHex(coderecord.armcontext.CPSR,8);
        lblR16.parent:=FormFoundCodeListExtra.panel6;
        lblR16.OnMouseDown:=registerMouseDown;
        lblR16.OnDblClick:=RegisterDblClick;
        lblR16.Align:=lblrcx.Align;

        lblR17:=tlabel.Create(FormFoundCodeListExtra);
        lblR17.Top:=lblR12.top+(lblRCX.top-lblRBX.top);
        lblR17.left:=lblRIP.left;
        lblR17.caption:=' ORIG_R0='+IntToHex(coderecord.armcontext.ORIG_R0,8);
        lblR17.parent:=FormFoundCodeListExtra.panel6;
        lblR17.OnMouseDown:=registerMouseDown;
        lblR17.OnDblClick:=RegisterDblClick;
        lblR17.Align:=lblrcx.Align;

        {Constraints.MinHeight:=panel6.top+(lblR17.top+lblR17.height)+16+panel5.height;
        if height<Constraints.MinHeight then
          height:=Constraints.MinHeight;   }
      end
      else
      begin

        if processhandler.is64bit then
          firstchar:='R' else firstchar:='E';

        lblRAX.caption:=firstchar+'AX='+IntToHex(coderecord.context.{$ifdef cpu64}Rax{$else}Eax{$endif},8);
        lblRBX.caption:=firstchar+'BX='+IntToHex(coderecord.context.{$ifdef cpu64}Rbx{$else}Ebx{$endif},8);
        lblRCX.caption:=firstchar+'CX='+IntToHex(coderecord.context.{$ifdef cpu64}Rcx{$else}Ecx{$endif},8);
        lblRDX.caption:=firstchar+'DX='+IntToHex(coderecord.context.{$ifdef cpu64}Rdx{$else}Edx{$endif},8);
        lblRSI.caption:=firstchar+'SI='+IntToHex(coderecord.context.{$ifdef cpu64}Rsi{$else}Esi{$endif},8);
        lblRDI.caption:=firstchar+'DI='+IntToHex(coderecord.context.{$ifdef cpu64}Rdi{$else}Edi{$endif},8);
        lblRSP.caption:=firstchar+'SP='+IntToHex(coderecord.context.{$ifdef cpu64}Rsp{$else}Esp{$endif},8);
        lblRBP.caption:=firstchar+'BP='+IntToHex(coderecord.context.{$ifdef cpu64}Rbp{$else}Ebp{$endif},8);
        lblRIP.caption:=firstchar+'IP='+IntToHex(coderecord.context.{$ifdef cpu64}Rip{$else}Eip{$endif},8);

        {$ifdef cpu64}
        if processhandler.is64bit then
        begin
          pnlRegisters.ChildSizing.ControlsPerLine:=5;

          lblR8:=tlabel.Create(FormFoundCodeListExtra);
          lblR8.caption:=' R8='+IntToHex(coderecord.context.r8,8);
          lblR8.parent:=FormFoundCodeListExtra.pnlRegisters;
          lblR8.OnMouseDown:=registerMouseDown;
          lblR8.OnDblClick:=RegisterDblClick;
          lblR8.Align:=lblrcx.Align;


          lblR9:=tlabel.Create(FormFoundCodeListExtra);
          lblR9.caption:=' R9='+IntToHex(coderecord.context.r9,8);
          lblR9.parent:=FormFoundCodeListExtra.pnlRegisters;
          lblR9.OnMouseDown:=registerMouseDown;
          lblR9.OnDblClick:=RegisterDblClick;
          lblR9.Align:=lblrcx.Align;

          lblR10:=tlabel.Create(FormFoundCodeListExtra);
          lblR10.caption:='R10='+IntToHex(coderecord.context.r10,8);
          lblR10.parent:=FormFoundCodeListExtra.pnlRegisters;
          lblR10.OnMouseDown:=registerMouseDown;
          lblR10.OnDblClick:=RegisterDblClick;
          lblR10.Align:=lblrcx.Align;

          lblR11:=tlabel.Create(FormFoundCodeListExtra);
          lblR11.caption:='R11='+IntToHex(coderecord.context.r11,8);
          lblR11.parent:=FormFoundCodeListExtra.pnlRegisters;
          lblR11.OnMouseDown:=registerMouseDown;
          lblR11.OnDblClick:=RegisterDblClick;
          lblR11.Align:=lblrcx.Align;

          lblR12:=tlabel.Create(FormFoundCodeListExtra);
          lblR12.caption:='R12='+IntToHex(coderecord.context.r12,8);
          lblR12.parent:=FormFoundCodeListExtra.pnlRegisters;
          lblR12.OnMouseDown:=registerMouseDown;
          lblR12.OnDblClick:=RegisterDblClick;
          lblR12.Align:=lblrcx.Align;

          lblR13:=tlabel.Create(FormFoundCodeListExtra);
          lblR13.caption:='R13='+IntToHex(coderecord.context.r13,8);
          lblR13.parent:=FormFoundCodeListExtra.pnlRegisters;
          lblR13.OnMouseDown:=registerMouseDown;
          lblR13.OnDblClick:=RegisterDblClick;
          lblR13.Align:=lblrcx.Align;

          lblR14:=tlabel.Create(FormFoundCodeListExtra);
          lblR14.caption:='R14='+IntToHex(coderecord.context.r14,8);
          lblR14.parent:=FormFoundCodeListExtra.pnlRegisters;
          lblR14.OnMouseDown:=registerMouseDown;
          lblR14.OnDblClick:=RegisterDblClick;
          lblR14.Align:=lblrcx.Align;

          lblR15:=tlabel.Create(FormFoundCodeListExtra);
          lblR15.caption:='R15='+IntToHex(coderecord.context.r15,8);
          lblR15.parent:=FormFoundCodeListExtra.pnlRegisters;
          lblR15.OnMouseDown:=registerMouseDown;
          lblR15.OnDblClick:=RegisterDblClick;
          lblR15.Align:=lblrcx.Align;

          lblRBP.BringToFront;
          lblRSP.BringToFront;
          lblRIP.BringToFront;


     {     Constraints.MinHeight:=panel6.top+(lblR15.top+lblR15.height)+16+panel5.height;
          if height<Constraints.MinHeight then
            height:=Constraints.MinHeight;     }
  //        if panel6.clientheight<lblR15.top+lblR15.height then //make room
  //          height:=height+(lblR15.top+lblR15.height)-(lblRDI.top+lblRDI.height);
        end;
        {$endif}
      end;
      label6.Caption:=coderecord.description;
    end;

    //parse the disassembled[3] string to help the user find the pointer
    //first find the [xxx]

    temp:=lowercase(copy(disassembled[3].s,pos('[',disassembled[3].s)+1,(pos(']',disassembled[3].s)-1)-(pos('[',disassembled[3].s))));
    firstchar:=lowercase(firstchar);

    maxregistervalue:=0;

    if temp<>'' then
    begin
      //parse
      //find the biggest value, registers or exact value

      if ((coderecord.LastDisassembleData.modrmValueType=dvtValue) and (coderecord.LastDisassembleData.hasSib=false)) then
      begin
        //only a value and no sib (the sib part can get messed up if it's a read)

        offset:=integer(coderecord.LastDisassembleData.modrmValue);

        (*
        if coderecord.LastDisassembleData.hasSib then
        begin
          case coderecord.LastDisassembleData.sibIndex of
            0: inc(offset, coderecord.context.{$ifdef cpu64}Rax{$else}Eax{$endif}*coderecord.LastDisassembleData.sibScaler);
            1: inc(offset, coderecord.context.{$ifdef cpu64}Rcx{$else}Ecx{$endif}*coderecord.LastDisassembleData.sibScaler);
            2: inc(offset, coderecord.context.{$ifdef cpu64}Rdx{$else}Edx{$endif}*coderecord.LastDisassembleData.sibScaler);
            3: inc(offset, coderecord.context.{$ifdef cpu64}Rbx{$else}Ebx{$endif}*coderecord.LastDisassembleData.sibScaler);
            5: inc(offset, coderecord.context.{$ifdef cpu64}Rbp{$else}Ebp{$endif}*coderecord.LastDisassembleData.sibScaler);
            6: inc(offset, coderecord.context.{$ifdef cpu64}Rsi{$else}Esi{$endif}*coderecord.LastDisassembleData.sibScaler);
            7: inc(offset, coderecord.context.{$ifdef cpu64}Rdi{$else}Edi{$endif}*coderecord.LastDisassembleData.sibScaler);
            {$ifdef cpu64}
            8: inc(offset, coderecord.context.R8*coderecord.LastDisassembleData.sibScaler);
            9: inc(offset, coderecord.context.R9*coderecord.LastDisassembleData.sibScaler);
            10: inc(offset, coderecord.context.R10*coderecord.LastDisassembleData.sibScaler);
            11: inc(offset, coderecord.context.R11*coderecord.LastDisassembleData.sibScaler);
            12: inc(offset, coderecord.context.R12*coderecord.LastDisassembleData.sibScaler);
            13: inc(offset, coderecord.context.R13*coderecord.LastDisassembleData.sibScaler);
            14: inc(offset, coderecord.context.R14*coderecord.LastDisassembleData.sibScaler);
            15: inc(offset, coderecord.context.R15*coderecord.LastDisassembleData.sibScaler);
            {$endif}
          end;
        end; *)

        formfoundcodelistextra.probably:=addresswatched-offset;
      end
      else
      begin
        //try the old code
        if pos(firstchar+'ax',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.{$ifdef cpu64}Rax{$else}Eax{$endif});
        if pos(firstchar+'bx',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.{$ifdef cpu64}Rbx{$else}Ebx{$endif});
        if pos(firstchar+'cx',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.{$ifdef cpu64}Rcx{$else}Ecx{$endif});
        if pos(firstchar+'dx',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.{$ifdef cpu64}Rdx{$else}Edx{$endif});
        if pos(firstchar+'di',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.{$ifdef cpu64}Rdi{$else}Edi{$endif});
        if pos(firstchar+'si',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.{$ifdef cpu64}Rsi{$else}Esi{$endif});
        if pos(firstchar+'bp',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.{$ifdef cpu64}Rbp{$else}Ebp{$endif});
        if pos(firstchar+'sp',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.{$ifdef cpu64}Rsp{$else}Esp{$endif});
        {$ifdef cpu64}
        if processhandler.is64Bit then
        begin
          if pos('r8',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.r8);
          if pos('r9',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.r9);
          if pos('r0',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.r10);
          if pos('r1',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.r11);
          if pos('r2',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.r12);
          if pos('r3',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.r13);
          if pos('r4',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.r14);
          if pos('r5',temp)>0 then maxregistervalue:=MaxX(maxregistervalue, coderecord.context.r15);
        end;
        {$endif}

        //the offset is always at the end, so read from back to front
        //todo: use addresswatched



        temp2:='';
        for i:=length(temp) downto 1 do
          if temp[i] in ['0'..'9','a'..'f'] then temp2:=temp[i]+temp2 else break;

        if temp2<>'' then //I know this isn't completely correct e.g: [eax*4] but even then the 4 will NEVER be bigger than eax (unless it's to cause a crash)
        begin
          p:=StrToQWordEx('$'+temp2);
          if p>maxregistervalue then maxregistervalue:=p;
        end;

        formfoundcodelistextra.probably:=maxregistervalue;

      end;
    end else formfoundcodelistextra.label17.caption:='';


    w:=formfoundcodelistextra.width;
    w:=max(w,formfoundcodelistextra.label1.width);
    w:=max(w,formfoundcodelistextra.label2.width);
    w:=max(w,formfoundcodelistextra.label3.width);
    w:=max(w,formfoundcodelistextra.label4.width);
    w:=max(w,formfoundcodelistextra.label5.width);

    if w<>formfoundcodelistextra.Width then
      formfoundcodelistextra.Width:=w+5;


    //copy the context and the stack to the more info window. the foundcode unit might get destroyed
    formfoundcodelistextra.context:=coderecord.context;
    if coderecord.stack.stack<>nil then
    begin
      getmem(formfoundcodelistextra.stack.stack, coderecord.stack.savedsize);
      formfoundcodelistextra.stack.savedsize:=coderecord.stack.savedsize;
      CopyMemory(formfoundcodelistextra.stack.stack, coderecord.stack.stack, coderecord.stack.savedsize);
    end;

    FormFoundCodeListExtra.Show;
  //  FormFoundCodeListExtra.free;
  end;
end;

procedure TFoundCodeDialog.FoundcodeListClick(Sender: TObject);
begin
end;

procedure TFoundCodeDialog.FormCreate(Sender: TObject);
var x: array of integer;
begin
  btnOk.caption:=strStop;

  setlength(x,0);
  loadformposition(self,x);

  if length(x)>=1 then
  begin
    foundcodelist.Columns[0].Width:=x[0];
    setcountwidth:=true;
  end;
end;

procedure TFoundCodeDialog.FormDeactivate(Sender: TObject);
begin

end;

procedure TFoundCodeDialog.FormDestroy(Sender: TObject);
var i: integer;
    cr: Tcoderecord;
begin
  for i:=0 to FoundCodeList.Items.count-1 do
  begin
    cr:=Tcoderecord(FoundCodeList.Items[i].data);

    if cr.formChangedAddresses<>nil then
    begin
      cr.formChangedAddresses.Close;
      cr.formChangedAddresses.Free;
      cr.formChangedAddresses:=nil;
    end;

    cr.free;
  end;


  saveformposition(self,[FoundCodeList.Columns[0].Width]);
end;

procedure TFoundCodeDialog.FormResize(Sender: TObject);
begin

end;

procedure TFoundCodeDialog.FormShow(Sender: TObject);
begin
  if not setcountwidth then
  begin
    FoundCodeList.Column[0].Width:=max(FoundCodeList.Column[0].Width, FoundCodeList.Canvas.TextWidth('9999'));
    setcountwidth:=true;
  end;
end;

procedure TFoundCodeDialog.FoundCodeListChange(Sender: TObject;
  Item: TListItem; Change: TItemChange);
begin

end;

procedure TFoundCodeDialog.btnOKClick(Sender: TObject);
var original: dword;
    i: integer;
begin
  if btnOK.caption=strStop then
  begin
    if debuggerthread<>nil then
      debuggerthread.CodeFinderStop(self);

    btnOK.caption:=strClose;
  end
  else close;


end;

procedure TFoundCodeDialog.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if btnOK.caption=strStop then
    if debuggerthread<>nil then
      debuggerthread.CodeFinderStop(self);

  action:=caFree;
end;

procedure TFoundCodeDialog.btnReplacewithnopsClick(Sender: TObject);
var codelength: dword;
    written: dword;
    i,j: integer;
    nops: array of byte;
    a: dword;
    original: dword;

    mbi : _MEMORY_BASIC_INFORMATION;

    coderecord: TCodeRecord;
begin

  with foundcodelist do
  begin
    for j:=0 to foundcodelist.items.Count-1 do
    begin
      if foundcodelist.items[j].Selected then
      begin
        coderecord:=TcodeRecord(foundcodelist.items[j].data);
        codelength:=coderecord.size;
        //add it to the codelist
        if advancedoptions.AddToCodeList(coderecord.address,coderecord.size,true, foundcodelist.SelCount>1) then
        begin
          setlength(nops,codelength);
          for i:=0 to codelength-1 do
            nops[i]:=$90;  // $90=nop


          zeromemory(@mbi,sizeof(mbi));


          RewriteCode(processhandle,coderecord.address,@nops[0],codelength);


        end;
      end;
    end;
  end;


end;

procedure TFoundCodeDialog.btnOpenDisassemblerClick(Sender: TObject);
var coderecord: TCodeRecord;
begin
  if foundcodelist.itemindex<>-1 then
  begin
    coderecord:=TcodeRecord(foundcodelist.items[foundcodelist.itemindex].data);
    memorybrowser.disassemblerview.SelectedAddress:=coderecord.address;
    memorybrowser.panel1.visible:=true;
    memorybrowser.show;
  end;
end;

procedure TFoundCodeDialog.btnAddToCodeListClick(Sender: TObject);
var i: integer;
    coderecord: TCodeRecord;
begin

  for i:=0 to foundcodelist.items.count-1 do
  begin
    if foundcodelist.items[i].Selected then
    begin
      coderecord:=TcodeRecord(foundcodelist.items[i].data);
      advancedoptions.AddToCodeList(coderecord.address,coderecord.size,false, foundcodelist.SelCount>1);
    end;
  end;
  advancedoptions.Show;
end;

procedure TFoundCodeDialog.FoundcodeListDblClick(Sender: TObject);
begin
  MoreInfo;
end;

procedure TFoundCodeDialog.btnExtraInfoClick(Sender: TObject);
begin
  moreinfo;
end;

procedure TFoundCodeDialog.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  if btnOK.caption=strStop then btnOK.Click;
  CanClose:=true;
end;


procedure TFoundCodeDialog.FoundCodeListSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
var coderecord: TCodeRecord;
  selectedRecord: integer;
  i: integer;
begin
  minfo.clear;

  if foundcodelist.Selected<>nil then
  begin
    btnReplacewithnops.enabled:=true;
    btnOpenDisassembler.enabled:=true;
    btnAddToCodeList.enabled:=true;
    btnExtraInfo.Enabled:=true;

    coderecord:=TCodeRecord(foundcodelist.Selected.data);
    description.Caption:=coderecord.description;

    addinfo(coderecord);

    {
    for i:=0 to FoundCodeList.Items.Count-1 do
    begin
      if foundcodelist.items[i].Selected then
      begin
        coderecord:=TCodeRecord(foundcodelist.items[i].data);
        addinfo(coderecord);
      end;
    end;   }

    //minfo.VertScrollBar.Position:=0;
    minfo.SelStart:=0;
    minfo.SelLength:=0;
  end
  else
  begin
    btnReplacewithnops.enabled:=false;
    btnOpenDisassembler.enabled:=false;
    btnAddToCodeList.enabled:=false;
    btnExtraInfo.Enabled:=false;
    if foundcodelist.Items.Count=0 then
      description.caption:=rsUseTheGameApplicationForAWhile
    else
      description.caption:=rsSelectAnItemFromTheListForASmallDescription;


  end;
end;

procedure TFoundCodeDialog.MenuItem1Click(Sender: TObject);
var i: integer;
begin
  FoundCodeList.OnSelectItem:=nil;
  for i:=0 to foundcodelist.items.count-1 do
    FoundCodeList.Items[i].Selected:=true;

  FoundCodeList.OnSelectItem:=FoundCodeListSelectItem;
end;

procedure TFoundCodeDialog.miFindWhatAccessesClick(Sender: TObject);
var i: integer;
  coderecord: Tcoderecord;
  f: TfrmChangedAddresses;

begin
  if miFindWhatAccesses.checked then
  begin
    if MessageDlg(rsFCThesWillSetASiftwareBreakpointInt3OnEverySingleOpcodeEtc,mtWarning, [mbyes,mbno],0)=mryes then
    begin
      //go through all existing entries and set a FindWhatCodeAccesses bp
      for i:=0 to FoundCodeList.Items.Count-1 do
      begin
        coderecord:=TCodeRecord(foundcodelist.items[i].data);
        coderecord.diffcount:=0;
        coderecord.formChangedAddresses:=debuggerthread.FindWhatCodeAccesses(coderecord.address, self);
      end;

      if FoundCodeList.Column[0].Width<FoundCodeList.Canvas.TextWidth('9999 (8)') then //make sure it's displayed
        FoundCodeList.Column[0].Width:=FoundCodeList.Canvas.TextWidth('9999 (8)');
    end
    else
      miFindWhatAccesses.checked:=false;
  end
  else
  begin
    //deactivate all bp's
    //go through bplist and remove all bp's
    for i:=0 to FoundCodeList.Items.Count-1 do
    begin
      coderecord:=TCodeRecord(foundcodelist.items[i].data);
      if coderecord.formChangedAddresses<>nil then
      begin

        coderecord.formChangedAddresses.free;
        coderecord.formChangedAddresses:=nil;
      end;
    end;

  end;
end;

function TFoundCodeDialog.getSelection:string;
var
  i: integer;
begin
  result:='';
  for i:=0 to FoundcodeList.Items.count-1 do
    if FoundcodeList.items[i].selected then
      result:=result+FoundcodeList.Items[i].subitems[0]+#13#10;
end;

procedure TFoundCodeDialog.miSaveTofileClick(Sender: TObject);
var
  s: TStringList;

begin
  if savedialog1.execute then
  begin
    s:=tstringlist.create;
    s.text:=getSelection;
    s.SaveToFile(savedialog1.filename);
    s.free;
  end;
end;

procedure TFoundCodeDialog.pmOptionsPopup(Sender: TObject);
begin
  ReplacewithcodethatdoesnothingNOP1.Enabled:=foundcodelist.selcount>0;
  Showthisaddressinthedisassembler1.enabled:=foundcodelist.itemindex<>-1;
  Addtothecodelist1.enabled:=foundcodelist.selcount>0;
  MoreInfo1.Enabled:=foundcodelist.itemindex<>-1;

  Copyselectiontoclipboard1.enabled:=foundcodelist.selcount>0;
  miSaveTofile.enabled:=Copyselectiontoclipboard1.Enabled;
end;

procedure TFoundCodeDialog.Copyselectiontoclipboard1Click(Sender: TObject);
begin
  clipboard.AsText:=getSelection;
end;

initialization
  {$i FoundCodeUnit.lrs}

end.
