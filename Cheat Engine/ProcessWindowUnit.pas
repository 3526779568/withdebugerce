unit ProcessWindowUnit;

{$MODE Delphi}

interface

uses
  jwawindows, windows, LCLIntf, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, CEFuncProc,CEDebugger, ComCtrls, ImgList,
  filehandler, Menus, LResources,{tlhelp32,}vmxfunctions, NewKernelHandler,
  debugHelper{, KIcon}, commonTypeDefs, math;

type tprocesslistlong = class(tthread)
private
  processcount: integer;
  process: array[0..9] of string;
  procedure drawprocesses;
public
  processlist: tlistbox;
  procedure execute; override;
end;

type

  { TProcessWindow }

  TProcessWindow = class(TForm)
    btnNetwork: TButton;
    Button4: TButton;
    CancelButton: TButton;
    FontDialog1: TFontDialog;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    miCreateProcess: TMenuItem;
    miOpenFile: TMenuItem;
    N2: TMenuItem;
    miChangeFont: TMenuItem;
    miSkipSystemProcesses: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    N1: TMenuItem;
    miProcessListLong: TMenuItem;
    miOwnProcessesOnly: TMenuItem;
    OKButton: TButton;
    Panel1: TPanel;
    OpenDialog1: TOpenDialog;
    OpenDialog2: TOpenDialog;
    Panel3: TPanel;
    Panel5: TPanel;
    PopupMenu1: TPopupMenu;
    InputPIDmanually1: TMenuItem;
    Filter1: TMenuItem;
    ProcessList: TListBox;
    miShowInvisibleItems: TMenuItem;
    TabControl1: TTabControl;
    Timer1: TTimer;
    procedure btnNetworkClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure miProcessListLongClick(Sender: TObject);
    procedure miChangeFontClick(Sender: TObject);
    procedure miOwnProcessesOnlyClick(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure btnProcesslistClick(Sender: TObject);
    procedure btnWindowListClick(Sender: TObject);
    procedure btnCreateThreadClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure btnOpenFileClick(Sender: TObject);
    procedure InputPIDmanually1Click(Sender: TObject);
    procedure Filter1Click(Sender: TObject);
    procedure btnProcessWatchClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnProcessListLongClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure ProcessListDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure FormShow(Sender: TObject);
    procedure ProcessListKeyPress(Sender: TObject; var Key: char);
    procedure miShowInvisibleItemsClick(Sender: TObject);
    procedure TabControl1Change(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
    currentchar: integer;
    wantedheight: integer;

    ffilter: string;
    processlistlong: tprocesslistlong;
    procedure refreshlist;
    procedure setbuttons;
    procedure SetFilter(filter:string);
    property filter:string read ffilter write setfilter;
    procedure filterlist;

  public
    { Public declarations }
    procedure PWOP(ProcessIDString:string);
  end;

var
  ProcessWindow: TProcessWindow;
  commonProcessesList: tstringlist;

implementation


uses MainUnit, formsettingsunit, advancedoptionsunit,frmProcessWatcherUnit,
  memorybrowserformunit, networkConfig, ProcessHandlerUnit, processlist, globals,
  registry, fontSaveLoadRegistry;

resourcestring
  rsIsnTAValidProcessID = '%s isn''t a valid processID';
  rsPhysicalMemory = 'Physical Memory';
  rsYouCanOnlyLoadEXEFiles = 'You can only load EXE files';
  rsCreateProcess = 'Create Process';
  rsOptionalLaunchParameters = 'Optional launch parameters';
  rsAttachdebuggerornot = 'Are you sure you want to attach the debugger and not just open this process? (You can later on always attach the debugger)';
  rsPleaseSelectAnotherProcess = 'Please select another process';
  rsFirstSelectAProcess = 'First select a process!';
  rsManualPID = 'Manual PID';
  rsEnterTheProcessID = 'Enter the ProcessID';
  rsFilter = 'Filter';
  rsWhatAreYouLookingFor = 'What are you looking for?';
  rsScanningClickToStop = 'Scanning (Click to stop)';
  rsProcessListLong = 'Process List(long)';
  rsProcessList = 'Process List';

var errortrace: integer;

procedure TProcessListLong.drawprocesses;
var i: integer;
begin
  if not terminated then
  begin
    processlist.Items.BeginUpdate;
    for i:=0 to processcount-1 do
      processlist.Items.Add(process[i]);
    processlist.Items.EndUpdate;
    processcount:=0;
  end;
end;

procedure TProcessListLong.execute;
var i: dword;
    h: thandle;

    x: pchar;
    modulename:string;
begin
  i:=0;






  while not terminated and (i<$FFFFFFFF) do
  begin
    h:=windows.OpenProcess(PROCESS_ALL_ACCESS,false,i);
    if h<>0 then
    begin
      modulename:=getProcessnameFromProcessID(i);
      process[processcount]:=inttohex(i,8)+'-'+modulename;

      inc(processcount);
      if processcount>=10 then
        synchronize(drawprocesses);

      closehandle(h);
    end;

    if ((i mod 4096)=0) then
      if processcount>0 then synchronize(drawprocesses);

    inc(i);
  end;

  if processcount>0 then synchronize(drawprocesses);
end;

procedure loadCommonProcessesList;
var
  s: string;
  i,j: integer;
begin
  s:=cheatenginedir+'commonProcessesList.txt';
  if FileExists(s) then //if the list exists
  begin
    if commonProcessesList=nil then commonProcessesList:=tstringlist.create;
    try
      commonProcessesList.LoadFromFile(s);
      for i:=commonProcessesList.Count-1 downto 0 do
      begin
        j:=pos('#', commonProcessesList[i]);
        if j>0 then commonProcessesList[i]:=copy(commonProcessesList[i], 1, j-1);
        commonProcessesList[i]:=uppercase(trim(commonProcessesList[i]));
        if commonProcessesList[i]='' then commonProcessesList.Delete(i);
      end;
    except
    end;
  end;
end;

function isInCommonProcessesList(processname: string): boolean;
var
  i:integer;
begin
  if commonProcessesList=nil then exit(false);
  for i:=0 to commonProcessesList.Count-1 do
    if commonProcessesList[i]=uppercase(copy(processname,10)) then exit(true);
  result:=false;
end;

procedure TProcessWindow.filterlist;
var
    i:integer;
    pli: PProcessListInfo;
    s: string;
begin
  if (filter='') and (miSkipSystemProcesses.checked=false) and (commonProcessesList=nil) then exit;

  ffilter:=uppercase(ffilter);

  i:=0;
  while i<processlist.Items.Count do
  begin
    pli:=PProcessListInfo(processlist.items.Objects[i]);

    if ((ffilter<>'') and (pos(ffilter,uppercase(processlist.Items[i]))=0)) or ((pli<>nil) and miSkipSystemProcesses.checked and pli^.issystemprocess) or
       isInCommonProcessesList(processlist.Items[i]) then
    begin
      if pli<>nil then
      begin
        if pli^.processIcon>0 then
        begin
          if pli^.processID<>GetCurrentProcessId then
            DestroyIcon(pli^.processIcon);

          pli^.processIcon:=0;
        end;

        freemem(pli);
      end;

      processlist.Items.Delete(i);
    end
    else
      inc(i);
  end;
end;

procedure TProcesswindow.SetFilter(filter:string);
begin
  ffilter:=filter;
  refreshlist;
end;

procedure TProcessWindow.CancelButtonClick(Sender: TObject);
begin
  mainform.canceled:=true;

  //ProcessWindow.close;
  ModalResult:=mrCancel;
end;


procedure TProcessWindow.FormCreate(Sender: TObject);
var
  x: array of integer;
  reg: tregistry;
begin
  setlength(x,0);
  if LoadFormPosition(self,x) then
  begin
    autosize:=false;
    if length(x)>0 then
      tabcontrol1.TabIndex:=x[0];

    if length(x)>1 then
      miOwnProcessesOnly.checked:=x[1]<>0;

    if length(x)>2 then
      miSkipSystemProcesses.checked:=x[2]<>0;
  end
  else
    refreshlist;

  reg:=tregistry.create;
  try
    if reg.OpenKey('\Software\DDY Engine\Process Window\Font',false) then
      LoadFontFromRegistry(processlist.Font, reg);


  finally
    reg.free;
  end;

end;

procedure TProcessWindow.FormDestroy(Sender: TObject);
begin
  SaveFormPosition(self,[tabcontrol1.TabIndex, ifthen(miOwnProcessesOnly.checked,1,0), ifthen(miSkipSystemProcesses.checked,1,0)]);
end;

procedure TProcessWindow.MenuItem5Click(Sender: TObject);
begin


end;

procedure TProcessWindow.miProcessListLongClick(Sender: TObject);
begin
  btnProcessListLongClick(nil);
end;

procedure TProcessWindow.miChangeFontClick(Sender: TObject);
var reg: tregistry;
begin
  fontdialog1.font.assign(processlist.font);
  if fontdialog1.execute then
  begin
    //apply settings
    processlist.font.assign(FontDialog1.Font);
    //processlist.Canvas.Refresh;

    Timer1Timer(timer1);

    processlist.Repaint;

    reg:=tregistry.create;
    try
      if reg.OpenKey('\Software\DDY Engine\Process Window\Font',true) then
        SaveFontToRegistry(FontDialog1.Font, reg);


    finally
      reg.free;
    end;
  end;
end;

procedure TProcessWindow.miOwnProcessesOnlyClick(Sender: TObject);
begin
  ProcessesCurrentUserOnly:=miOwnProcessesOnly.checked;
  refreshlist;
end;

procedure TProcessWindow.btnNetworkClick(Sender: TObject);
begin
  if frmNetworkConfig=nil then
    frmNetworkConfig:=tfrmNetworkConfig.create(self);

  if frmNetworkConfig.ShowModal=mrok then
  begin
    if TabControl1.TabIndex=1 then
      refreshlist
    else
      TabControl1.Tabindex:=1;
  end;
end;

procedure TProcessWindow.Button1Click(Sender: TObject);
begin

end;

procedure TProcessWindow.setbuttons;
begin

end;

procedure TProcessWindow.PWOP(ProcessIDString:string);
var i:integer;
begin

  val('$'+ProcessIDString,ProcessHandler.processid,i);
  if i<>0 then raise exception.Create(Format(rsIsnTAValidProcessID, [processidstring]));
  if Processhandle<>0 then
  begin
    CloseHandle(ProcessHandle);
    ProcessHandler.ProcessHandle:=0;
  end;

  with mainform do
  begin
    if GetSystemType>=4 then
    begin
      cbSpeedhack.checked:=false;
      cbSpeedhack.Enabled:=true;
      cbunrandomizer.Checked:=false;
      cbunrandomizer.Enabled:=true;
    end;
  end;

  Open_Process;

  ProcessSelected:=true;


  if (processid=0) and ((formsettings.cbKernelReadWriteProcessMemory.checked) or (dbvm_version>=$ce000004)) then
  begin
    ProcessHandler.processid:=$FFFFFFFF;

    if dbvm_version>=$ce000004 then
      DBKPhysicalMemoryDBVM
    else
      DBKPhysicalMemory;
    ProcessHandler.ProcessHandle:=$FFFFFFFF;
  end
  else
  begin
    if usephysical or usephysicaldbvm then
      DBKProcessMemory;
  end;

end;

procedure TProcessWindow.OKButtonClick(Sender: TObject);
var ProcessIDString: String; 
begin
  //Outputdebugstring('OK button click');
  if Processlist.ItemIndex>-1 then
  begin
    unpause;
    DetachIfPossible;

    ProcessIDString:=copy(ProcessList.Items[Processlist.ItemIndex], 1, pos('-',ProcessList.Items[Processlist.ItemIndex])-1);

    PWOP(ProcessIDString);

    if tabcontrol1.TabIndex=0 then
      MainForm.ProcessLabel.caption:=ProcessIDString+'-'+extractfilename(getProcessPathFromProcessID(processid))
    else
      MainForm.ProcessLabel.caption:=ProcessList.Items[Processlist.ItemIndex];
    Modalresult:=MROK;
    //ProcessWindow.close;
  end;

  //outputdebugstring('After ok click handler');
end;



//button1click specific:
procedure TProcessWindow.btnProcesslistClick(Sender: TObject);
begin




end;

procedure TProcessWindow.btnWindowListClick(Sender: TObject);
begin
  //miSkipSystemProcesses.visible:=false;


end;

procedure TProcessWindow.btnCreateThreadClick(Sender: TObject);
var parameters: string;
begin
  if Opendialog1.Execute then
  begin
    if Uppercase(extractfileext(opendialog1.FileName))<>'.EXE' then raise Exception.Create(rsYouCanOnlyLoadEXEFiles);
    parameters:='';
    if not InputQuery(rsCreateProcess, rsOptionalLaunchParameters, parameters) then exit;


    unpause;
    detachIfPossible;


    Debuggerthread:=TDebuggerThread.MyCreate2(opendialog1.FileName, parameters);
    if not Debuggerthread.running then exit;

    mainForm.ProcessLabel.caption:=IntToHex(processid,8)+'-'+ExtractFileName(opendialog1.FileName);


    mainform.debugproc:=true;


    memorybrowser.show;
    modalresult:=mrOk;
  end;
end;

procedure TProcessWindow.Button4Click(Sender: TObject);
var ProcessIDString: String;
    i:               Integer;
begin

  if Processlist.ItemIndex>-1 then
  begin
    if MessageDlg(rsAttachdebuggerornot, mtConfirmation, [mbyes, mbno], 0)=mryes then
    begin
      unpause;
      DetachIfPossible;

      ProcessIDString:='';
      i:=1;
      while ProcessList.Items[Processlist.ItemIndex][i]<>'-' do
      begin
        ProcessIDString:=ProcessIDString+ProcessList.Items[Processlist.ItemIndex][i];
        inc(i);
      end;

      val('$'+ProcessIDString,ProcessHandler.processid,i);

      if Processhandle<>0 then
      begin
        CloseHandle(ProcessHandle);
        ProcessHandler.ProcessHandle:=0;
      end;

      if processid=GetCurrentProcessId then raise exception.create(rsPleaseSelectAnotherProcess);

      Debuggerthread:=TDebuggerThread.MyCreate2(processid);

      mainform.ProcessLabel.Caption:=ProcessList.Items[Processlist.ItemIndex];

      ProcessSelected:=true;
      mainform.debugproc:=true;

      modalresult:=mrOK;
    end
  end else showmessage(rsFirstSelectAProcess);

end;

procedure TProcessWindow.btnOpenFileClick(Sender: TObject);
begin

  if opendialog2.execute then
  begin
    DBKFileAsMemory(opendialog2.filename);
    processselected:=true;
    ProcessHandler.ProcessHandle:=-1;
    MainForm.ProcessLabel.caption:=extractfilename(opendialog2.FileName);
    MainForm.miSaveFile.visible:=true;
    ProcessHandler.processid:=$FFFFFFFF;

    modalresult:=mrok;
  end;

end;

procedure TProcessWindow.InputPIDmanually1Click(Sender: TObject);
var pid: string;
begin
  pid:='0';
  if InputQuery(rsManualPID, rsEnterTheProcessID+':', pid) then
  begin
    unpause;
    DetachIfPossible;

    pwop(pid);
    MainForm.ProcessLabel.caption:=pid;
    modalresult:=mrok;
  end;

end;

procedure TProcessWindow.Filter1Click(Sender: TObject);
var fltr: string;
begin
  if inputquery(rsFilter, rsWhatAreYouLookingFor, fltr) then
    filter:=fltr;
end;

procedure TProcessWindow.btnProcessWatchClick(Sender: TObject);
begin

  if frmprocesswatcher=nil then
    frmprocesswatcher:=tfrmprocesswatcher.Create(mainform);
  frmprocesswatcher.show;
  modalresult:=mrcancel;
end;

procedure TProcessWindow.FormResize(Sender: TObject);
begin
//reset the button positions
//  setbuttons;
end;

procedure TProcessWindow.btnProcessListLongClick(Sender: TObject);
begin
  if processlistlong=nil then
  begin
    processlist.Clear;
    miProcessListLong.Caption:=rsScanningClickToStop;
    processlistlong:=tprocesslistlong.create(true);
    processlistlong.processlist:=processlist;
    processlistlong.start;
  end
  else
  begin
    miProcessListLong.Caption:=rsProcessListLong;
    processlistlong.terminate;
    processlistlong.WaitFor;
    processlistlong.Free;
    processlistlong:=nil;    
  end;
end;

procedure TProcessWindow.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if processlistlong<>nil then
  begin
    processlistlong.terminate;
    processlistlong.WaitFor;
    processlistlong.Free;
    processlistlong:=nil;
    miProcessListLong.Caption:=rsProcessListLong;
  end;
end;

procedure TProcessWindow.PopupMenu1Popup(Sender: TObject);
begin

end;

procedure TProcessWindow.ProcessListDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var i: integer;
begin
  wantedheight:=ProcessList.canvas.TextHeight('QqJjWwSs')+3;
  {i:=ProcessList.canvas.TextHeight('QqJjWwSs')+3;
  if processlist.itemheight<i then ProcessList.ItemHeight:=i;   }

  processlist.Canvas.FillRect(rect);
  {
  i:=ProcessList.canvas.TextHeight('QqJjWwSs')+3;
  if processlist.itemheight<i then ProcessList.ItemHeight:=i;}



  processlist.Canvas.TextOut(rect.Left+rect.Bottom-rect.Top+3,rect.Top,processlist.Items[index]);

  if (processlist.Items.Objects[index]<>nil) and (PProcessListInfo(processlist.Items.Objects[index])^.processIcon>0) then
    DrawIconEx(processlist.Canvas.Handle, rect.left, rect.Top, PProcessListInfo(processlist.Items.Objects[index])^.processIcon, rect.Bottom-rect.Top,rect.Bottom-rect.Top,0,0,DI_NORMAL);

end;

procedure TProcessWindow.FormShow(Sender: TObject);
begin
  loadCommonProcessesList;
  errortrace:=100;
  try
    errortrace:=101;
    processlist.canvas.Refresh;

    errortrace:=102;
    ProcessList.ItemHeight:=max(processlist.canvas.TextHeight('QqJjWwSs')+3, canvas.TextHeight('QqJjWwSs')+3);
    errortrace:=103;
    currentchar:=1;
    errortrace:=104;
    refreshlist;
    errortrace:=105;

    if autosize then
    begin
      autosize:=false;
      if height<350 then
        height:=350; //initial show
    end;
    errortrace:=106;
  except
    on e:exception do
      raise exception.create('FormShow exception ('+e.message+') at section '+inttostr(errortrace));

  end;
end;

procedure TProcessWindow.ProcessListKeyPress(Sender: TObject; var Key: char);
begin
  if key=#8 then
    filter:=copy(filter, 1, length(filter)-1)
  else
  if key in [chr(32)..chr(128)] then
    filter:=filter+key;

  if filter<>'' then
    caption:=rsProcessList+' : *'+filter+'*'
  else
    caption:=rsProcessList;
end;

procedure TProcessWindow.RefreshList;
var
    i: integer;
    oldselectionindex: integer;
    oldselection: string;
    found: boolean;

begin
  processlist.Items.BeginUpdate;
  try
    oldselectionindex:=processlist.ItemIndex;

    if oldselectionindex<>-1 then
      oldselection:=processlist.Items[oldselectionIndex];

    case tabcontrol1.TabIndex of
      0:
      begin
        getwindowlist2(processlist.Items);
        miSkipSystemProcesses.enabled:=true;
      end;

      1:
      begin
        getprocesslist(processlist.items);

        miSkipSystemProcesses.enabled:=true;
      end;

      2:
      begin
        GetWindowList(processlist.Items, miShowInvisibleItems.Checked);
        miSkipSystemProcesses.enabled:=false;
        processlist.ItemIndex:=processlist.Items.Count-1;
      end;
    end;

    filterlist;

    if oldselectionindex=-1 then
    begin
      processlist.ItemIndex:=processlist.Items.Count-1; //go to the end
    end
    else
    begin
      i:=processlist.Items.IndexOf(oldselection);
      if i>=0 then
      begin
        processlist.ItemIndex:=i;
      end
      else
      begin
        //strip out the processid part and search for a entry with the appropriate processname (e.g restarted game)
        oldselection:=copy(oldselection,pos('-',oldselection)+1,length(oldselection));

        found:=false;
        for i:=0 to processlist.Items.Count-1 do
          if pos(oldselection, processlist.items[i])>0 then
          begin
            processlist.ItemIndex:=i;
            found:=true;

            break;
          end;

        if not found then
          processlist.ItemIndex:=processlist.Items.Count-1;
      end;
    end;


    if formsettings.cbKernelReadWriteProcessMemory.checked or (dbvm_version>=$ce000004) then //driver is active
    begin
      processlist.Items.Insert(0, '00000000-['+rsPhysicalMemory+']');
    end;

  finally
    processlist.items.EndUpdate;
  end;
end;

procedure TProcessWindow.miShowInvisibleItemsClick(Sender: TObject);
begin
  refreshList;
end;

procedure TProcessWindow.TabControl1Change(Sender: TObject);
begin
  refreshList;
end;

procedure TProcessWindow.Timer1Timer(Sender: TObject);
begin
  try
    if processlist.itemheight<>wantedheight then
    begin
      ProcessList.ItemHeight:=wantedheight;
      processlist.canvas.Refresh;
      processlist.Repaint;
    end;
  except
    timer1.enabled:=false;
    showmessage('timer issue');
  end;
end;


initialization
  {$i ProcessWindowUnit.lrs}

end.

