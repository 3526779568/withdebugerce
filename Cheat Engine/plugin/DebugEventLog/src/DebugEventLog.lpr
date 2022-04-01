library DebugEventLog;

{$MODE Delphi}

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  interfaces,
  SysUtils,
  Classes,
  exportimplementation in 'exportimplementation.pas',
  frmEventLogUnit in 'frmEventLogUnit.pas' {frmEventLog},
  cepluginsdk in '..\..\cepluginsdk.pas';

//i'm just reusing this unit (i'm lazy)

{$R *.res}

exports GetVersion;
exports InitializePlugin;
exports DisablePlugin;

begin
end.
