unit aboutunit;

{$MODE Delphi}

interface

uses
  windows, LCLIntf, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, LResources,shellapi, vmxfunctions, NewKernelHandler;

type

  { TAbout }

  TAbout = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label5: TLabel;
    Image1: TImage;
    Button1: TButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Button2: TButton;
    Label10: TLabel;
    lblDBVM: TLabel;
    Panel3: TPanel;
    Panel4: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Label8Click(Sender: TObject);
    procedure Label9Click(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lblDBVMClick(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure UpdateDBVMStatus;
  end;

var
  About: TAbout;

implementation

uses tlgUnit,MainUnit2, MainUnit, dbvmLoadManual;


resourcestring
  rsYourSystemDOESNOTSupportDBVM = 'Your system DOES NOT support DBVM';
  rsThisMeansThatYouWillNeedANewCpuIntelToBeAbleToUseT = 'This means that you will need a new cpu (intel) to be able to use the advanced dbvm options';
  rsYourSystemIsRunningDBVMVersion = 'Your system is running DBVM version %s';
  rsThisMeansThatYourSystemIsRunningDbvm = 'This means that your system is running dbvm. This means ce will make use of some advanced tools that are otherwise unavailable';
  rsYourSystemSupportsDBVM = 'Your system supports DBVM';
  rsThisMeansThatYouReCurrentlyNotRunningDbvm = 'This means that you''re currently not running dbvm, but that your system is capable of running it';
  rsDidYouReallyThinkYouDFindAnEasterEggByDoingThisWel = 'Did you really think you''d find an easter egg by doing this? Well, you know what? You where right!';
  rsAreYouSureYouWantToLaunchDBVM = 'Are you sure you want to launch DBVM? You seem to be running in 32-bit, so don''t really need it that badly (Except for ultimap and cloaked operations)';
  rsLaunchdbvmWasNotAssigned = 'launchdbvm was not assigned';

procedure TAbout.Button1Click(Sender: TObject);
begin
  Close;
end;

procedure TAbout.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  About:=nil;
  action:=caFree;
end;

procedure TAbout.Button2Click(Sender: TObject);
begin

  shellexecute(0,'open','https://www.paypal.com/xclick/business=dark_byte%40hotmail.com&no_note=1&tax=0&lc=US',nil,nil,sw_maximize);
end;

procedure TAbout.FormShow(Sender: TObject);
var
    a,b,c,d: dword;
    i: integer;
begin
  {$ifdef net}
    groupbox1.Caption:=unit2.CEnorm;
  {$else}
    groupbox1.Caption:=mainunit2.CEnorm;
  {$endif}


  i:=GetFontData(font.Handle).Height;
  //Label8.Font.Height:=i;
  //Label9.Font.Height:=i;


  if panel4.top<label1.top+label1.height then
  begin
    panel4.AnchorSideTop.control:=label1;
    panel4.AnchorSideTop.side:=asrBottom;
  end;

  if panel4.top+panel4.height>image1.Top+image1.height then
    label10.AnchorSideTop.Control:=panel4;

  UpdateDBVMStatus;
end;

procedure TAbout.Label8Click(Sender: TObject);
begin
  ShellExecute(0, pchar('open'),pchar('http://cheatengine.org/'), pchar(''),pchar(''), SW_MAXIMIZE	);
end;

procedure TAbout.Label9Click(Sender: TObject);
begin
  ShellExecute(0, pchar('open'),pchar('http://forum.cheatengine.org/'), pchar(''),pchar(''), SW_MAXIMIZE	);
end;

procedure TAbout.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (ssCtrl in Shift) and (ssAlt in Shift) and (ssShift in Shift) then
  begin
    ShowMessage(rsDidYouReallyThinkYouDFindAnEasterEggByDoingThisWel);
    with TTlg.create(self) do show;
  end;
end;


procedure TAbout.lblDBVMClick(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  //if not isRunningDBVM then
  begin
    //if not isDBVMCapable then exit;

    if button=mbLeft then
    begin


      if not Is64bitOS then
      begin
        if messagedlg(rsAreYouSureYouWantToLaunchDBVM, mtWarning, [mbno, mbyes], 0)=mryes then
        begin
          loaddbk32;
          if assigned(launchdbvm) then
            launchdbvm(-1)
          else
            raise exception.create(rsLaunchdbvmWasNotAssigned);

          formshow(self);
        end;
      end
      else
      begin
        if loaddbvmifneeded then
        begin
          formshow(self);
        end;
      end;
    end
    else
      if frmDBVMLoadManual<>nil then frmDBVMLoadManual.SetFocus
      else tfrmDBVMLoadManual.create(Application).Show;
  end;
end;

procedure TAbout.UpdateDBVMStatus;
var
  supportsdbvm: boolean;
begin
  if (vmx_password1=0) and (vmx_password2=0) then
  begin
    vmx_password1:=$76543210;
    vmx_password2:=$fedcba98;
  end;

  if not isDBVMCapable then
  begin
    //force the default password


    vmx_password1:=$76543210;
    vmx_password2:=$fedcba98;
  end;

  if not isDBVMCapable then
  begin
    lblDBVM.Font.Color:=clRed;
    lbldbvm.caption:=rsYourSystemDOESNOTSupportDBVM;
    lbldbvm.Hint:=rsThisMeansThatYouWillNeedANewCpuIntelToBeAbleToUseT;
    lbldbvm.ShowHint:=true;
  end
  else
  begin

//{$ifdef cpu32}
//    Loaddbk32;
//{$endif}

    if (dbvm_version>0) then
    begin
      lblDBVM.Font.Color:=clLime;
      lbldbvm.caption:=Format(rsYourSystemIsRunningDBVMVersion, [inttostr(dbvm_version and $00ffffff)]);
      lbldbvm.Hint:=rsThisMeansThatYourSystemIsRunningDbvm;
      lbldbvm.ShowHint:=true;
    end
    else
    begin
      lblDBVM.Font.Color:=clGreen;
      lbldbvm.caption:=rsYourSystemSupportsDBVM;
      lbldbvm.Hint:=rsThisMeansThatYouReCurrentlyNotRunningDbvm;
      lbldbvm.ShowHint:=true;
    end;
  end;


  if (dbvm_version=0) then
  begin
    supportsdbvm:=isDBVMCapable;

    if supportsdbvm then
    begin
      lblDBVM.Font.Color:=clGreen;
      lbldbvm.caption:=rsYourSystemSupportsDBVM;
      lbldbvm.Hint:=rsThisMeansThatYouReCurrentlyNotRunningDbvm;
      lbldbvm.ShowHint:=true;
      lbldbvm.Cursor:=crHandPoint;
    end
    else
    begin
      lblDBVM.Font.Color:=clRed;
      lbldbvm.caption:=rsYourSystemDOESNOTSupportDBVM;
      lbldbvm.Hint:=rsThisMeansThatYouWillNeedANewCpuIntelToBeAbleToUseT;
      lbldbvm.ShowHint:=true;
      lbldbvm.Cursor:=crNo;
    end;
  end
  else
  begin
    lblDBVM.Font.Color:=clLime;
    lbldbvm.caption:=Format(rsYourSystemIsRunningDBVMVersion, [inttostr(dbvm_version and $00ffffff)]);
    lbldbvm.Hint:=rsThisMeansThatYourSystemIsRunningDbvm;
    lbldbvm.ShowHint:=true;
    lbldbvm.Cursor:=crDefault;
  end;
end;


initialization
  {$i aboutunit.lrs}

end.
