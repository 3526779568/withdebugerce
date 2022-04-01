unit LuaCaller;
{
The luaCaller is a class which contains often defined Events and provides an
interface for gui objects to directly call the lua functions with proper parameters
and results
}

{$mode delphi}

interface

uses
  Classes, Controls, SysUtils, ceguicomponents, forms, lua, lualib, lauxlib,
  comctrls, StdCtrls, CEFuncProc, typinfo, Graphics, disassembler, LuaDisassembler,
  LastDisassembleData, Assemblerunit, commonTypeDefs, ExtCtrls, addresslist, MemoryRecordUnit;

type
  TLuaCaller=class
    private
      function canRun: boolean;

    public
      luaroutine: string;
      luaroutineindex: integer;
      owner: TPersistent;

      synchronizeparam: integer;
      synchronizeparamcount: integer;
      syncvm: Plua_State;
      procedure NotifyEvent(sender: TObject);
      procedure SelectionChangeEvent(Sender: TObject; User: boolean);
      procedure MouseEvent(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      procedure MouseMoveEvent(Sender: TObject; Shift: TShiftState; X, Y: Integer);
      procedure MouseWheelUpDownEvent(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var h: Boolean);
      procedure KeyPressEvent(Sender: TObject; var Key: char);
      procedure KeyEvent(Sender: TObject; var Key: Word; Shift: TShiftState);
      procedure TreeViewExpandOrCloseEvent(Sender: TObject; Node: TTreeNode; var Allow: Boolean);

      procedure LVCheckedItemEvent(Sender: TObject; Item: TListItem); //personal request to have this one added
      procedure LVColumnClickEvent(Sender: TObject; c: TListColumn);
      procedure LVSelectItemEvent(Sender: TObject; Item: TListItem; Selected: Boolean);
      procedure LVCompareEvent(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);

      procedure LVCustomDrawEvent(Sender: TCustomListView; const ARect: TRect;  var DefaultDraw: Boolean);
      procedure LVCustomDrawItemEvent(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
      procedure LVCustomDrawSubItemEvent(Sender: TCustomListView; Item: TListItem; SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);


      procedure CanResizeEvent(Sender: TObject; var NewSize: Integer; var Accept: Boolean);

      procedure CloseEvent(Sender: TObject; var CloseAction: TCloseAction);
      procedure CloseQueryEvent(Sender: TObject; var CanClose: boolean);
      function MemoryRecordActivateEvent(sender: TObject; before, currentstate: boolean): boolean;
      procedure DisassemblerSelectionChangeEvent(sender: TObject; address, address2: ptruint);
      function DisassemblerExtraLineRender(sender: TObject; Address: ptruint; AboveInstruction: boolean; selected: boolean; var x: integer; var y: integer): TRasterImage;

      procedure ByteSelectEvent(sender: TObject; address: ptruint; address2: ptruint);
      procedure AddressChangeEvent(sender: TObject; address: ptruint);
      procedure DropFilesEvent(sender: TObject; filenames: array of string);

      function AutoGuessEvent(address: ptruint; originalVariableType: TVariableType): TVariableType;
      procedure D3DClickEvent(renderobject: TObject; x,y: integer);
      function D3DKeyDownEvent(VirtualKey: dword; char: pchar): boolean;
      function DisassembleEvent(sender: TObject; address: ptruint; var ldd: TLastDisassembleData; var output: string; var description: string): boolean;

      function AutoAssemblerCallback(parameters: string; syntaxcheckonly: boolean): string;
      function StructureDissectEvent(structure: TObject; address: ptruint): boolean;

      function AddressLookupCallback(address: ptruint): string;
      function SymbolLookupCallback(s: string): ptruint;
      function StructureNameLookup(var address: ptruint; var name: string): boolean;
      procedure AssemblerEvent(address:qword; instruction: string; var bytes: TAssemblerBytes);
      procedure AutoAssemblerPrologueEvent(code: TStrings; syntaxcheckonly: boolean);
      procedure AutoAssemblerTemplateCallback(script: TStrings; sender: TObject);
      procedure ScreenFormEvent(Sender: TObject; Form: TCustomForm);

      function BreakpointEvent(bp: pointer; context: pointer):boolean;
      function MemRecChangeEvent(al: TObject; memrec: TMemoryRecord): boolean;
      function GetDisplayValueEvent(mr: TObject; var value: string): boolean;
      procedure MemScanGuiUpdateRoutine(sender: TObject; totaladdressestoscan: qword; currentlyscanned: qword; foundcount: qword);


      procedure synchronize;

      procedure pushFunction(L: PLua_state=nil);


      constructor create;
      destructor destroy; override;
  end;

procedure CleanupLuaCall(event: TMethod);   //cleans up a luacaller class if it was assigned if it was set

procedure setMethodProperty(O: TObject; propertyname: string; method: TMethod);

function LuaCaller_NotifyEvent(L: PLua_state): integer; cdecl;
function LuaCaller_SelectionChangeEvent(L: PLua_state): integer; cdecl;
function LuaCaller_CloseEvent(L: PLua_state): integer; cdecl;
function LuaCaller_MouseEvent(L: PLua_state): integer; cdecl;
function LuaCaller_MouseMoveEvent(L: PLua_state): integer; cdecl;
function LuaCaller_MouseWheelUpDownEvent(L: PLua_state): integer; cdecl;
function LuaCaller_KeyPressEvent(L: PLua_state): integer; cdecl;
function LuaCaller_KeyEvent(L: PLua_state): integer; cdecl;
function LuaCaller_TreeViewExpandOrCloseEvent(L: PLua_state): integer; cdecl;
function LuaCaller_LVCheckedItemEvent(L: PLua_state): integer; cdecl;
function LuaCaller_LVSelectItemEvent(L: PLua_state): integer; cdecl;

function LuaCaller_MemoryRecordActivateEvent(L: PLua_state): integer; cdecl;
function LuaCaller_DisassemblerSelectionChangeEvent(L: PLua_state): integer; cdecl;
function LuaCaller_ByteSelectEvent(L: PLua_state): integer; cdecl;  //(sender: TObject; address: ptruint; address2: ptruint);
function LuaCaller_AddressChangeEvent(L: PLua_state): integer; cdecl;  //(sender: TObject; address: ptruint);

function LuaCaller_D3DClickEvent(L: PLua_state): integer; cdecl; //(renderobject: TObject; x,y: integer);
function LuaCaller_D3DKeyDownEvent(L: PLua_state): integer; cdecl; //(VirtualKey: dword; char: pchar): boolean;



function LuaCaller_ScreenFormEvent(L: PLua_state): integer; cdecl; //(Form)
function LuaCaller_BreakpointEvent(L: PLua_state): integer; cdecl; //():boolean;



procedure LuaCaller_pushMethodProperty(L: PLua_state; m: TMethod; typename: string);
procedure LuaCaller_setMethodProperty(L: PLua_state; c: TObject; prop: string; typename: string; luafunctiononstack: integer);  overload;
procedure LuaCaller_setMethodProperty(L: PLua_state; var m: TMethod; typename: string; luafunctiononstack: integer); overload;

function luacaller_getFunctionHeaderAndMethodForType(typeinfo: PTypeInfo; lc: pointer; name: string; header: tstrings) : Tmethod;

implementation

uses
  luahandler, LuaByteTable, MainUnit, disassemblerviewunit,
  hexviewunit, d3dhookUnit, luaclass, debuggertypedefinitions, memscan;

resourcestring
  rsThisTypeOfMethod = 'This type of method:';
  rsIsNotYetSupported = ' is not yet supported';
  rsAutoAssemblerCallbackLuaFunctionError = 'AutoAssemblerCallback: Lua Function error(';
  rsStructureDissectEventLuaFunctionError = 'StructureDissectEvent: Lua Function error(';

type
  TLuaCallData=class(tobject)
    GetMethodProp: lua_CFunction; //used when lua wants a function to a class method/property  (GetMethodProp)
    SetMethodProp: pointer; //used when we want to set a method property to a lua function (SetMethodProp)
    luafunctionheader: string;
  end;
var LuaCallList: Tstringlist;


function luacaller_getFunctionHeaderAndMethodForType(typeinfo: PTypeInfo; lc: pointer; name: string; header: tstrings) : Tmethod;
var i: integer;
  lcd: TLuaCallData;

begin
  result.Code:=nil;
  result.data:=nil;


  i:=LuaCallList.IndexOf(typeinfo.Name);
  if i<>-1 then
  begin
    lcd:=TLuaCallData(LuaCallList.Objects[i]);
    result.Code:=lcd.SetMethodProp;
    result.data:=lc;

    if header<>nil then
      header.Text:=format(lcd.luafunctionheader, [name]);
  end;



end;

procedure LuaCaller_setMethodProperty(L: PLua_state; var m: TMethod; typename: string; luafunctiononstack: integer);
var
  lc: TLuaCaller;
  i,r: integer;

  newcode: pointer;
begin

  if lua_isnil(L, luafunctiononstack) then //nil, special case, always succeed
  begin
    CleanupLuaCall(m);
    m.code:=nil;
    m.data:=nil;
    exit;
  end;

  i:=LuaCallList.IndexOf(typename);
  if i=-1 then
    raise exception.create(rsThisTypeOfMethod+typename+rsIsNotYetSupported);

  newcode:=TLuaCallData(LuaCallList.Objects[i]).SetMethodProp;

  //proper type, let's clean it up
  CleanupLuaCall(m);
  lc:=nil;


  //create a TLuacaller for the given function
  if lua_isfunction(L, luafunctiononstack) then
  begin
    lua_pushvalue(L, luafunctiononstack);
    r:=luaL_ref(L,LUA_REGISTRYINDEX);

    lc:=TLuaCaller.create;
    lc.luaroutineIndex:=r;
  end
  else
  if lua_isstring(L, luafunctiononstack) then
  begin
    lc:=TLuaCaller.create;
    lc.luaroutine:=Lua_ToString(L, luafunctiononstack);
  end;

  if lc<>nil then
  begin
    m.Data:=lc;
    m.code:=newcode;
  end;
end;

procedure LuaCaller_setMethodProperty(L: PLua_state; c: TObject; prop: string; typename: string; luafunctiononstack: integer);
//note: This only works on published methods
var m: tmethod;
begin
  m:=GetMethodProp(c, prop);
  LuaCaller_setMethodProperty(L, m, typename, luafunctiononstack);
  setMethodProp(c, prop, m);
end;

procedure luaCaller_pushMethodProperty(L: PLua_state; m: TMethod; typename: string);
var
  f: lua_CFunction;
  i: integer;
begin
  i:=LuaCallList.IndexOf(typename);
  if i=-1 then
    raise exception.create(rsThisTypeOfMethod+typename+rsIsNotYetSupported);

  f:=TLuaCallData(LuaCallList.Objects[i]).GetMethodProp;


  if m.data=nil then
  begin
    lua_pushnil(L);
    exit;
  end;

  if tobject(m.Data) is TLuaCaller then
    TLuaCaller(m.data).pushFunction
  else
  begin
    //not a lua function

    //this can (and often is) a class specific thing

    lua_pushlightuserdata(L, m.code);
    lua_pushlightuserdata(L, m.data);
    lua_pushcclosure(L, f,2);
  end;
end;

procedure CleanupLuaCall(event: TMethod);
begin
  if (event.code<>nil) and (event.data<>nil) and (TObject(event.data) is TLuaCaller) then
    TLuaCaller(event.data).free;
end;

procedure setMethodProperty(O: TObject; propertyname: string; method: TMethod);
var orig: TMethod;
begin
  orig:=GetMethodProp(o, propertyname);
  CleanupLuaCall(orig);
  SetMethodProp(O, propertyname, method);
end;

constructor TLuaCaller.create;
begin
  luaroutineindex:=-1;
end;

destructor TLuaCaller.destroy;
var vmused: Plua_State;
begin
  vmused:=syncvm;
  if vmused=nil then
    vmused:=luavm;

  if luaroutineindex<>-1 then //deref
    luaL_unref(vmused, LUA_REGISTRYINDEX, luaroutineindex);
end;

function TLuaCaller.canRun: boolean;
var baseOwner: TComponent;
begin
  baseOwner:=Tcomponent(owner);
  if baseOwner<>nil then
  begin
    while (not (baseOwner is TCustomForm)) and (baseowner.Owner<>nil) do //as long as the current base is not a form and it still has a owner
      baseOwner:=baseowner.owner;
  end;

  result:=(baseowner=nil) or (not ((baseOwner is TCEform) and (TCEForm(baseowner).designsurface<>nil) and (TCEForm(baseowner).designsurface.active)));
end;

procedure TLuaCaller.pushFunction(L: PLua_state=nil);
begin
  if L=nil then
    L:=LuaVM;

  if luaroutineindex=-1 then //get the index of the given routine
    lua_getglobal(L, pchar(luaroutine))
  else
    lua_rawgeti(L, LUA_REGISTRYINDEX, luaroutineindex)
end;

procedure TLuaCaller.synchronize;
var
  paramcount: integer;
  i: integer;
begin
  //no locking here (should already be obtained by the caller)
  PushFunction(syncvm);
  if synchronizeparam>0 then
  begin
    if synchronizeparamcount=0 then
      synchronizeparamcount:=1;

    for i:=0 to synchronizeparamcount-1 do
      lua_pushvalue(syncvm, synchronizeparam+i);

    paramcount:=synchronizeparamcount;
  end
  else
  begin
    lua_pushnil(syncvm);
    paramcount:=1;
  end;

  lua_pcall(syncvm, paramcount,1,0);

  free;
end;

procedure TLuaCaller.SelectionChangeEvent(Sender: TObject; User: boolean);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);
  try

    if canRun then
    begin
      PushFunction;

      luaclass_newClass(Luavm, sender);
      lua_pushboolean(Luavm, User);

      lua_pcall(Luavm, 2,0,0); //procedure(sender)
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.NotifyEvent(sender: TObject);
var
  oldstack: integer;
  l: Plua_State;
begin
  try
    l:=GetLuaState;
    oldstack:=lua_gettop(L);

    if canRun then
    begin
      PushFunction(L);
      luaclass_newclass(L, sender);

      lua_pcall(L, 1,0,0); //procedure(sender)
    end;
  finally
    lua_settop(L, oldstack);
  end;
end;

procedure TLuaCaller.CloseEvent(Sender: TObject; var CloseAction: TCloseAction);
var
  oldstack: integer;
  ca: integer;
  l: Plua_state;
begin
  L:=GetLuaState;
  oldstack:=lua_gettop(L);

  try
    if canRun then
    begin
      PushFunction;
      luaclass_newClass(L, sender);


      if lua_pcall(L, 1,1,0)=0 then //procedure(sender)  lua_pcall returns 0 if success
      begin
        if lua_gettop(L)>0 then
        begin
          ca:=lua_tointeger(L,-1);
          CloseAction:=TCloseAction(ca);
        end;
      end
      else
        closeAction:=caHide; //not implemented by the user

      if mainform.mustclose then
        closeaction:=cahide;

    end
    else closeaction:=caHide;
  finally
    lua_settop(L, oldstack);
  end;
end;

procedure TLuaCaller.CloseQueryEvent(Sender: TObject; var CanClose: boolean);
var
  oldstack: integer;
  L: Plua_State;
begin
  L:=GetLuaState;
  oldstack:=lua_gettop(L);

  try
    if canRun then
    begin
      PushFunction;
      luaclass_newClass(L, sender);


      if lua_pcall(L, 1,1,0)=0 then
      begin
        if lua_gettop(L)>0 then
          canclose:=lua_toboolean(L,-1);
      end;
    end;
  finally
    lua_settop(L, oldstack);
  end;
end;

function TLuaCaller.MemoryRecordActivateEvent(sender: tobject; before, currentstate: boolean): boolean;
var
  oldstack: integer;
  l: Plua_State;
begin
  result:=true;
  l:=GetLuaState;
  oldstack:=lua_gettop(L);

  try
    if canRun then
    begin
      PushFunction;
      luaclass_newClass(L, sender);
      lua_pushboolean(L, before);
      lua_pushboolean(L, currentstate);


      lua_pcall(L, 3,1,0); //function(sender, before, currentstate):boolean

      if lua_gettop(L)>0 then
        result:=lua_toboolean(L,-1);

    end;
  finally
    lua_settop(L, oldstack);
  end;
end;

function TLuaCaller.DisassemblerExtraLineRender(sender: TObject; Address: ptruint; AboveInstruction: boolean; selected: boolean; var x: integer; var y: integer): TRasterImage;
var oldstack: integer;
begin
  result:=nil;
  oldstack:=lua_gettop(Luavm);

  try

    if canrun then
    begin
      PushFunction;
      luaclass_newClass(Luavm, sender);
      lua_pushinteger(luavm, address);
      lua_pushboolean(luavm, AboveInstruction);
      lua_pushboolean(luavm, selected);

      lua_pcall(Luavm, 4,3,0); //function(sender, Address, AboveInstruction, Selected): RasterImage OPTIONAL, x OPTIONAL, y OPTIONAL

      result:=lua_ToCEUserData(luavm, 1);
      if lua_isnil(luavm, 2)=false then
        x:=lua_tointeger(luavm, 2);

      if lua_isnil(luavm, 3)=false then
        y:=lua_tointeger(luavm, 3);

    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.DisassemblerSelectionChangeEvent(sender: tobject; address, address2: ptruint);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try

    if canRun then
    begin
      PushFunction;
      luaclass_newClass(Luavm, sender);
      lua_pushinteger(luavm, address);
      lua_pushinteger(luavm, address2);


      lua_pcall(Luavm, 3,0,0); //procedure(sender, address, address2)
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.ByteSelectEvent(sender: TObject; address: ptruint; address2: ptruint);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try

    if canRun then
    begin
      PushFunction;
      luaclass_newClass(Luavm, sender);
      lua_pushinteger(luavm, address);
      lua_pushinteger(luavm, address2);

      lua_pcall(Luavm, 3,0,0); //procedure(sender, address, address2)
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

function TLuaCaller.D3DKeyDownEvent(VirtualKey: dword; char: pchar): boolean;
var oldstack: integer;
begin
  result:=true;
  oldstack:=lua_gettop(Luavm);

  try

    if canRun then
    begin
      PushFunction;
      lua_pushinteger(luavm, VirtualKey);
      lua_pushstring(luavm, char);
      if lua_pcall(Luavm, 2,1,0)=0 then
        result:=lua_toboolean(luavm,-1);
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.D3DClickEvent(renderobject: TObject; x,y: integer);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try

    if canRun then
    begin
      PushFunction;
      luaclass_newClass(luavm, renderobject);
      lua_pushinteger(luavm, x);
      lua_pushinteger(luavm, y);
      lua_pcall(Luavm, 3,0,0)
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.AddressChangeEvent(sender: TObject; address: ptruint);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try

    if canRun then
    begin
      PushFunction;
      luaclass_newClass(Luavm, sender);
      lua_pushinteger(luavm, address);

      lua_pcall(Luavm, 2,0,0); //procedure(sender, address)
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.DropFilesEvent(sender: TObject; filenames: array of string);
var
  oldstack: integer;
  i: integer;
  t: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try

    if canRun then
    begin
      PushFunction;
      luaclass_newClass(Luavm, sender);
      lua_newtable(Luavm);

      t:=lua_gettop(Luavm);

      for i:=0 to length(filenames)-1 do
      begin
        lua_pushinteger(LuaVM, i+1);
        lua_pushstring(LuaVM, filenames[i]);
        lua_settable(LuaVM, t);
      end;

      lua_pcall(Luavm, 2,0,0); //procedure(sender, {filenames})
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;


function TLuaCaller.AutoGuessEvent(address: ptruint; originalVariableType: TVariableType): TVariableType;
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try

    PushFunction;
    lua_pushinteger(luavm, address);
    lua_pushinteger(luavm, integer(originalVariableType));
    if lua_pcall(LuaVM, 2, 1, 0)=0 then         // lua_pcall returns 0 if success
      result:=TVariableType(lua_tointeger(LuaVM,-1))
    else
      result:=originalVariableType;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.MouseWheelUpDownEvent(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var h: Boolean);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try
    pushFunction;
    luaclass_newClass(luavm, sender);
    lua_pushinteger(luavm, MousePos.x);
    lua_pushinteger(luavm, MousePos.y);

    lua_pcall(LuaVM, 3, 1, 0);
    if lua_isboolean(LuaVM,-1)=false then
      h:=lua_toboolean(LuaVM, -1);

  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.MouseMoveEvent(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try
    pushFunction;
    luaclass_newClass(luavm, sender);
    lua_pushinteger(luavm, x);
    lua_pushinteger(luavm, y);

    lua_pcall(LuaVM, 3, 0, 0);
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.MouseEvent(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try
    pushFunction;
    luaclass_newClass(luavm, sender);
    lua_pushinteger(luavm, integer(Button));
    lua_pushinteger(luavm, x);
    lua_pushinteger(luavm, y);

    lua_pcall(LuaVM, 4, 0, 0);
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.KeyPressEvent(Sender: TObject; var Key: char);
var oldstack: integer;
  s: string;
begin
  oldstack:=lua_gettop(Luavm);

  try
    pushFunction;
    luaclass_newClass(luavm, sender);
    lua_pushstring(luavm, key);
    if lua_pcall(LuaVM, 2, 1, 0)=0 then  //lua_pcall returns 0 if success
    begin
      if lua_isstring(LuaVM, -1) then
      begin
        s:=lua_tostring(LuaVM,-1);
        if length(s)>0 then
          key:=s[1]
        else
          key:=#0; //invalid string
      end
      else
      if lua_isnumber(LuaVM, -1) then
        key:=chr(lua_tointeger(LuaVM, -1))
      else
        key:=#0; //invalid type returned
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.KeyEvent(Sender: TObject; var Key: Word; Shift: TShiftState);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try
    pushFunction;
    luaclass_newClass(luavm, sender);
    lua_pushinteger(luavm, key);
    if lua_pcall(LuaVM, 2, 1, 0)=0 then
    begin
      if lua_isnumber(LuaVM, -1) then
        key:=lua_tointeger(LuaVM,-1); //else ignore
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.TreeViewExpandOrCloseEvent(Sender: TObject; Node: TTreeNode; var Allow: Boolean);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try
    pushFunction;
    luaclass_newClass(luavm, sender);
    luaclass_newClass(luavm, node);
    if lua_pcall(LuaVM, 2, 1, 0)=0 then
    begin
      if lua_isboolean(LuaVM, -1) then
        allow:=lua_toboolean(LuaVM,-1);
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.LVCheckedItemEvent(Sender: TObject; Item: TListItem);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try
    pushFunction;
    luaclass_newClass(luavm, sender);
    luaclass_newClass(luavm, item);
    lua_pcall(LuaVM, 2, 0, 0);
  finally
    lua_settop(Luavm, oldstack);
  end
end;


procedure TLuaCaller.LVColumnClickEvent(Sender: TObject; c: TListColumn);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try
    pushFunction;
    luaclass_newClass(luavm, sender);
    luaclass_newClass(luavm, c);
    lua_pcall(LuaVM, 2, 0, 0);
  finally
    lua_settop(Luavm, oldstack);
  end
end;

procedure TLuaCaller.LVSelectItemEvent(Sender: TObject; Item: TListItem; selected: boolean);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try
    pushFunction;
    luaclass_newClass(luavm, sender);
    luaclass_newClass(luavm, item);
    lua_pushboolean(luavm, selected);
    lua_pcall(LuaVM, 3, 0, 0);
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.LVCompareEvent(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try
    pushFunction;
    luaclass_newClass(luavm, sender);
    luaclass_newClass(luavm, item1);
    luaclass_newClass(luavm, item2);
    lua_pushinteger(luavm, data);
    if lua_pcall(LuaVM, 4, 1, 0)=0 then
      compare:=lua_tointeger(luavm,-1);
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.LVCustomDrawEvent(Sender: TCustomListView; const ARect: TRect;  var DefaultDraw: Boolean);
var
  oldstack: integer;
  l: Plua_State;
begin
  l:=GetLuaState;

  try
    oldstack:=lua_gettop(l);
    pushFunction(l);
    luaclass_newClass(l, sender);
    lua_pushrect(L,arect);
    lua_pushboolean(L,DefaultDraw);

    if lua_pcall(l, 3, 1, 0)=0 then
      DefaultDraw:=lua_toboolean(l,-1);
  finally
    lua_settop(l, oldstack);
  end;
end;

procedure TLuaCaller.LVCustomDrawItemEvent(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  oldstack: integer;
  l: Plua_State;
  i: integer;
begin
  l:=GetLuaState;

  try
    oldstack:=lua_gettop(l);
    pushFunction(l);
    luaclass_newClass(l, sender);
    luaclass_newClass(l, Item);
    lua_newtable(L);

    for i:=0 to 8 do
      if TCustomDrawStateFlag(i) in state then
      begin
        lua_pushinteger(L,i);
        lua_pushboolean(L,true);
        lua_settable(L,-3);
      end;

    lua_pushboolean(L,DefaultDraw);

    if lua_pcall(l, 4, 1, 0)=0 then
      DefaultDraw:=lua_toboolean(l,-1);
  finally
    lua_settop(l, oldstack);
  end;
end;

procedure TLuaCaller.LVCustomDrawSubItemEvent(Sender: TCustomListView; Item: TListItem; SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  oldstack: integer;
  l: Plua_State;
  i: integer;
begin
  l:=GetLuaState;

  try
    oldstack:=lua_gettop(l);
    pushFunction(l);
    luaclass_newClass(l, sender);
    luaclass_newClass(l, Item);
    lua_pushinteger(L,SubItem);
    lua_newtable(L);

    for i:=0 to 8 do
      if TCustomDrawStateFlag(i) in state then
      begin
        lua_pushinteger(L,i);
        lua_pushboolean(L,true);
        lua_settable(L,-3);
      end;

    lua_pushboolean(L,DefaultDraw);

    if lua_pcall(l, 5, 1, 0)=0 then
      DefaultDraw:=lua_toboolean(l,-1);
  finally
    lua_settop(l, oldstack);
  end;
end;


procedure TLuaCaller.CanResizeEvent(Sender: TObject; var NewSize: Integer; var Accept: Boolean);
var
  oldstack: integer;
  l: Plua_State;
begin
  try
    l:=GetLuaState;
    oldstack:=lua_gettop(L);
    pushFunction;
    luaclass_newClass(L, sender);
    lua_pushinteger(L, newsize);

    if lua_pcall(L, 2, 2, 0)=0 then
    begin
      newsize:=lua_tointeger(L, 1);
      accept:=lua_toboolean(L, 2);
    end;
  finally
    lua_settop(L, oldstack);
  end;
end;

function TLuaCaller.DisassembleEvent(sender: TObject; address: ptruint; var ldd: TLastDisassembleData; var output: string; var description: string): boolean;
var
  oldstack: integer;
  lddentry: integer;
  l: Plua_State;
begin
  result:=false;
  try
    L:=GetLuaState;
    oldstack:=lua_gettop(L);

    lua_newtable(L);
    lddentry:=lua_gettop(L);
    LastDisassemblerDataToTable(L, lddentry, ldd); //initialize it

    pushFunction;
    luaclass_newClass(l, sender);
    lua_pushinteger(L, address);
    lua_pushvalue(L, lddentry);
    if output<>'' then
      lua_pushstring(l,output)
    else
      lua_pushnil(l);

    if description<>'' then
      lua_pushstring(l,description)
    else
      lua_pushnil(l);

    if lua_pcall(L, 5, 2, 0)=0 then
    begin
      if not lua_isnil(L, -2) then
      begin
        result:=true;
        output:=Lua_ToString(L, -2);

        if not lua_isnil(L, -1) then
          description:=Lua_ToString(L, -1)
        else
          description:='';

        LastDisassemblerDataFromTable(L, lddentry, ldd);
      end;
    end;


  finally
    lua_settop(L, oldstack);
  end
end;

function TLuaCaller.AutoAssemblerCallback(parameters: string; syntaxcheckonly: boolean): string;
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try


    PushFunction;
    lua_pushstring(luavm, parameters);
    lua_pushboolean(luavm, syntaxcheckonly);
    if lua_pcall(Luavm, 2,2,0)=0 then
    begin
      if lua_isnil(luavm, -2) and lua_isstring(luavm, -1) then
        raise exception.create(Lua_ToString(luavm, -1));

      result:=Lua_ToString(luavm, -2);
    end
    else
      raise exception.create(rsAutoAssemblerCallbackLuaFunctionError+lua_tostring(luavm, -1)+')');

  finally
    lua_settop(Luavm, oldstack);
  end;
end;

function TLuaCaller.StructureDissectEvent(structure: TObject; address: ptruint): boolean;
var oldstack: integer;
begin
  result:=false;
  oldstack:=lua_gettop(Luavm);

  try


    PushFunction;
    luaclass_newClass(luavm, structure);
    lua_pushinteger(luavm, address);
    if lua_pcall(Luavm, 2,1,0)=0 then
      result:=lua_toboolean(luavm, -1)
    else
      raise exception.create(rsStructureDissectEventLuaFunctionError+lua_tostring(luavm, -1)+')');
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.ScreenFormEvent(Sender: TObject; Form: TCustomForm);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);

  try

    if canRun then
    begin
      PushFunction;
      luaclass_newClass(luavm, form);
      lua_pcall(Luavm, 1,0,0)
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

function TLuaCaller.BreakpointEvent(bp: Pointer; context: pointer):boolean;
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);
  try

    if canRun then
    begin
      if context<>nil then
      begin
        PushFunction;
        result:=LUA_onBreakpoint(context, true);
      end;
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

function TLuaCaller.MemRecChangeEvent(al: TObject; memrec: TMemoryRecord): boolean;
var oldstack: integer;
begin
  result:=false;

  oldstack:=lua_gettop(Luavm);
  try

    if canRun then
    begin
      PushFunction;
      luaclass_newClass(LuaVM, al);
      luaclass_newClass(LuaVM, memrec);

      if lua_pcall(Luavm, 2,1,0)=0 then
        if not lua_isnil(luavm, -1) then
          result:=lua_toboolean(luavm, -1);
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

function TLuaCaller.GetDisplayValueEvent(mr: TObject; var value: string): boolean;
var
  oldstack: integer;
begin
  result:=false;
  oldstack:=lua_gettop(Luavm);
  try
    if canRun then
    begin
      PushFunction;
      luaclass_newClass(LuaVM, mr);
      lua_pushstring(Luavm, value);
      if lua_pcall(Luavm, 2,2,0)=0 then
      begin
        result:=lua_toboolean(luavm, -2);
        if result then
          value:=Lua_ToString(luavm, -1);
      end;
    end;

  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.MemScanGuiUpdateRoutine(sender: TObject; totaladdressestoscan: qword; currentlyscanned: qword; foundcount: qword);
var
  oldstack: integer;
  l: Plua_State;
begin
  l:=luahandler.GetLuaState;

  try
    oldstack:=lua_gettop(l);
    if canRun then
    begin
      PushFunction(l);
      luaclass_newClass(l, sender);
      lua_pushinteger(l, totaladdressestoscan);
      lua_pushinteger(l, currentlyscanned);
      lua_pushinteger(l, foundcount);
      lua_pcall(l, 4,0,0);
    end;
  finally
    lua_settop(l, oldstack);
  end;
end;

function TLuaCaller.AddressLookupCallback(address: ptruint): string;
var oldstack: integer;
begin
  result:='';
  oldstack:=lua_gettop(Luavm);
  try
    PushFunction;
    lua_pushinteger(luavm, address);
    if lua_pcall(Luavm, 1,1,0)=0 then
      if not lua_isnil(luavm, -1) then
        result:=Lua_ToString(luavm,-1);


  finally
    lua_settop(Luavm, oldstack);
  end;
end;

function TLuaCaller.SymbolLookupCallback(s: string): ptruint;
var oldstack: integer;
begin
  result:=0;
  oldstack:=lua_gettop(Luavm);
  try
    PushFunction;
    lua_pushstring(luavm, s);
    if lua_pcall(Luavm, 1,1,0)=0 then
      if not lua_isnil(luavm, -1) then
        result:=lua_tointeger(luavm,-1);
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

function TLuaCaller.StructureNameLookup(var address: ptruint; var name: string): boolean;
var oldstack: integer;
begin
  result:=false;
  oldstack:=lua_gettop(Luavm);
  try

    PushFunction;
    lua_pushinteger(luavm, address);
    if lua_pcall(Luavm, 1,2,0)=0 then
    begin
      result:=lua_isnil(luavm, -2)=false;

      if result then
        name:=Lua_ToString(luavm, -2);

      if not lua_isnil(luavm, -1) then
        address:=lua_tointeger(luavm, -1);
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.AssemblerEvent(address:qword; instruction: string; var bytes: TAssemblerBytes);
var
  oldstack: integer;
  tableindex: integer;
  maxsize: integer;
begin
  setlength(bytes,0);

  oldstack:=lua_gettop(Luavm);
  try

    PushFunction;
    lua_pushinteger(luavm, address);
    lua_pushstring(luavm, instruction);

    if lua_pcall(Luavm, 2,1,0)=0 then
    begin
      if lua_istable(luavm, -1) then
      begin
        lua_pushvalue(luavm, -1);
        tableindex:=lua_gettop(luavm);

        maxsize:=lua_objlen(luavm, tableindex);
        setlength(bytes, maxsize);
        readBytesFromTable(luavm, tableindex, @bytes[0], maxsize);
      end;
    end;
  finally
    lua_settop(Luavm, oldstack);
  end;
end;


procedure TLuaCaller.AutoAssemblerPrologueEvent(code: TStrings; syntaxcheckonly: boolean);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);
  try

    PushFunction;
    luaclass_newClass(luavm, code);
    lua_pushboolean(luavm, syntaxcheckonly);
    lua_pcall(Luavm, 2,0,0);
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

procedure TLuaCaller.AutoAssemblerTemplateCallback(script: TStrings; sender: TObject);
var oldstack: integer;
begin
  oldstack:=lua_gettop(Luavm);
  try

    PushFunction;
    luaclass_newClass(luavm, script);
    luaclass_newClass(luavm, sender);
    lua_pcall(Luavm, 2,0,0);
  finally
    lua_settop(Luavm, oldstack);
  end;
end;

//----------------------------Lua implementation-----------------------------
function LuaCaller_NotifyEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
begin
  result:=0;
  parameters:=lua_gettop(L);

  if parameters=1 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));

    sender:=lua_toceuserdata(L, 1);
    lua_pop(L, lua_gettop(L));

    TNotifyEvent(m)(sender);
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_SelectionChangeEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  user: boolean;
begin
  result:=0;
  parameters:=lua_gettop(L);;

  if parameters=1 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));

    sender:=lua_toceuserdata(L, 1);
    user:=lua_toboolean(L, 2);

    lua_pop(L, lua_gettop(L));

    TSelectionChangeEvent(m)(sender, user);
  end
  else
    lua_pop(L, lua_gettop(L));
end;


function LuaCaller_CloseEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  closeaction: TCloseAction;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=1 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    lua_pop(L, lua_gettop(L));

    closeaction:=caHide;
    TCloseEvent(m)(sender, closeaction);

    lua_pushinteger(L, integer(closeaction));
    result:=1;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_CloseQueryEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  canClose: Boolean;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=1 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    lua_pop(L, lua_gettop(L));

    canClose:=true;
    TCloseQueryEvent(m)(sender, canClose);

    lua_pushboolean(L, canClose);
    result:=1;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_MouseEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  button: TMouseButton;
  shift: TShiftState;
  x,y: integer;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=4 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    button:=TMouseButton(lua_tointeger(L, 2));

    x:=lua_tointeger(L, 3);
    y:=lua_tointeger(L, 4);

    lua_pop(L, lua_gettop(L));

    TMouseEvent(m)(sender, button, [], x,y);
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_MouseMoveEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  x,y: integer;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=3 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    x:=lua_tointeger(L, 2);
    y:=lua_tointeger(L, 3);
    lua_pop(L, lua_gettop(L));

    TMouseMoveEvent(m)(sender, [],x,y);
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_MouseWheelUpDownEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  p: TPoint;
  b: Boolean;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=3 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    p.x:=lua_tointeger(L, 2);
    p.y:=lua_tointeger(L, 3);
    lua_pop(L, lua_gettop(L));
    TMouseWheelUpDownEvent(m)(sender, [], p, b);
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_KeyPressEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  key: char;
  s: string;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=2 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    s:=Lua_ToString(L,2);
    if length(s)>0 then
      key:=s[1]
    else
      key:=' ';

    lua_pop(L, lua_gettop(L));

    TKeyPressEvent(m)(sender, key);
    lua_pushstring(L, key);
    result:=1;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_KeyEvent(L: PLua_state): integer; cdecl;
//function KeyEvent(Sender, Key)
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  key: word;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=2 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    key:=lua_tointeger(L,2);

    lua_pop(L, lua_gettop(L));

    TKeyEvent(m)(sender, key, []);
    lua_pushinteger(L, key);
    result:=1;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_TreeViewExpandOrCloseEvent(L: PLua_state): integer; cdecl;
//function (sender, node) : boolean
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  node: TTreenode;
  allow: boolean;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=2 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    node:=lua_toceuserdata(L,2);

    lua_pop(L, lua_gettop(L));

    allow:=true;
    TTVExpandingEvent(m)(sender, node, allow);
    lua_pushboolean(L, allow);
    result:=1;
  end
  else
    lua_pop(L, lua_gettop(L));
end;



function LuaCaller_LVCheckedItemEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  item: TListItem;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=2 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    item:=lua_ToCEUserData(L, 2);
    lua_pop(L, lua_gettop(L));

    TLVCheckedItemEvent(m)(sender,item);
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_LVColumnClickEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  c: TListColumn;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=2 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    c:=lua_ToCEUserData(L, 2);
    lua_pop(L, lua_gettop(L));

    TLVColumnClickEvent(m)(sender,c);
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_LVSelectItemEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  item: TListItem;
  selected: boolean;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=3 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    item:=lua_ToCEUserData(L, 2);
    selected:=lua_toboolean(L, 3);
    lua_pop(L, lua_gettop(L));

    TLVSelectItemEvent(m)(sender,item, selected);
  end
  else
    lua_pop(L, lua_gettop(L));
end;


function LuaCaller_LVCompareEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  item1, item2: TListItem;
  data: integer;
  compare: integer;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters=4 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    item1:=lua_ToCEUserData(L, 2);
    item2:=lua_ToCEUserData(L, 3);
    data:=lua_tointeger(L, 4);
    lua_pop(L, lua_gettop(L));

    compare:=0;
    TLVCompareEvent(m)(sender,item1, item2, data, compare);

    lua_pushinteger(L,compare);
    result:=1;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_LVCustomDrawEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TCustomListView;
  rect: TRect;
  defaultdraw: boolean;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters>=2 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    rect:=lua_torect(L, 2);

    if parameters>=3 then
      defaultdraw:=lua_toboolean(L,3)
    else
      defaultdraw:=true;
    lua_pop(L, lua_gettop(L));

    TLVCustomDrawEvent(m)(sender,rect, defaultdraw);
    lua_pushboolean(L,defaultdraw);
    result:=1;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

//(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean) of object;
function LuaCaller_LVCustomDrawItemEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TCustomListView;
  item: TListItem;
  state: TCustomDrawState;
  defaultdraw: boolean;
  i: integer;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters>=3 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    item:=lua_toceuserdata(L,2);
    state:=[];
    if lua_istable(L,3) then
    begin
      for i:=0 to 8 do
      begin
        lua_pushinteger(L,i);
        lua_gettable(L,3);
        if lua_toboolean(L,-1) then
          state:=state+[TCustomDrawStateFlag(i)];
      end;
    end;

    if parameters>=4 then
      defaultdraw:=lua_toboolean(L,4)
    else
      defaultdraw:=true;
    lua_pop(L, lua_gettop(L));

    TLVCustomDrawItemEvent(m)(sender,item, state, defaultdraw);
    lua_pushboolean(L,defaultdraw);
    result:=1;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

//(Sender: TCustomListView; Item: TListItem; SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean) of object;
function LuaCaller_LVCustomDrawSubItemEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TCustomListView;
  item: TListItem;
  subitem: integer;
  state: TCustomDrawState;
  defaultdraw: boolean;
  i: integer;
begin
  result:=0;
  parameters:=lua_gettop(L);
  if parameters>=4 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    item:=lua_toceuserdata(L,2);
    subitem:=lua_tointeger(L,3);
    state:=[];
    if lua_istable(L,4) then
    begin
      for i:=0 to 8 do
      begin
        lua_pushinteger(L,i);
        lua_gettable(L,3);
        if lua_toboolean(L,-1) then
          state:=state+[TCustomDrawStateFlag(i)];
      end;
    end;

    if parameters>=5 then
      defaultdraw:=lua_toboolean(L,5)
    else
      defaultdraw:=true;
    lua_pop(L, lua_gettop(L));

    TLVCustomDrawItemEvent(m)(sender,item, state, defaultdraw);
    lua_pushboolean(L,defaultdraw);
    result:=1;
  end
  else
    lua_pop(L, lua_gettop(L));
end;



function LuaCaller_CanResizeEvent(L: PLua_state): integer; cdecl;
var
  parameters: integer;
  m: TMethod;
  sender: TObject;
  newsize: integer;
  accept: boolean;
begin
  result:=0;

  if lua_gettop(L)=2 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    newsize:=lua_tointeger(L, 2);
    lua_pop(L, lua_gettop(L));

    accept:=true;
    TCanResizeEvent(m)(sender,newsize, accept);

    lua_pushinteger(L,newsize);
    lua_pushboolean(L,accept);
    result:=2;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_MemoryRecordActivateEvent(L: PLua_state): integer; cdecl;
var
  m: TMethod;
  sender: TObject;
  before, currentstate: boolean;
  r: boolean;
begin
  result:=0;
  if lua_gettop(L)=3 then
  begin
    //(sender: TObject; before, currentstate: boolean):
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    before:=lua_toboolean(L, 2);
    currentstate:=lua_toboolean(L,3);
    lua_pop(L, lua_gettop(L));

    r:=TMemoryRecordActivateEvent(m)(sender,before, currentstate);
    lua_pushboolean(L, r);
    result:=1;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_DisassemblerExtraLineRender(L: PLua_state): integer; cdecl;
//function(sender, Address, AboveInstruction, Selected): Bitmap OPTIONAL, x OPTIONAL, y OPTIONAL
var
  m: TMethod;
  sender: TObject;
  address: ptruint;
  AboveInstruction, selected: boolean;
  x,y: integer;
  r: TRasterimage;
begin
  result:=0;
  if lua_gettop(L)=4 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    address:=lua_tointeger(L, 2);
    AboveInstruction:=lua_toboolean(L, 3);
    selected:=lua_toboolean(L, 4);
    x:=-1000;
    y:=-1000;
    lua_pop(L, lua_gettop(L));
    r:=TDisassemblerExtraLineRender(m)(sender, address, AboveInstruction, selected, x, y);

    luaclass_newClass(L, r);
    if x=-1000 then
      lua_pushnil(L)
    else
      lua_pushinteger(L, x);

    if y=-1000 then
      lua_pushnil(L)
    else
      lua_pushinteger(L, y);

    result:=3;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_DisassemblerSelectionChangeEvent(L: PLua_state): integer; cdecl;
//function(sender, address, address2)
var
  m: TMethod;
  sender: TObject;
  a,a2: ptruint;
begin
  result:=0;
  if lua_gettop(L)=3 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    a:=lua_tointeger(L, 2);
    a2:=lua_tointeger(L,3);
    lua_pop(L, lua_gettop(L));

    TDisassemblerSelectionChangeEvent(m)(sender,a, a2);
  end
  else
    lua_pop(L, lua_gettop(L));
end;

//I could reuse LuaCaller_DisassemblerSelectionChangeEvent with   LuaCaller_ByteSelectEvent
function LuaCaller_ByteSelectEvent(L: PLua_state): integer; cdecl;  //(sender: TObject; address: ptruint; address2: ptruint);
var
  m: TMethod;
  sender: TObject;
  a,a2: ptruint;
begin
  result:=0;
  if lua_gettop(L)=3 then
  begin
    //(sender: TObject; before, currentstate: boolean):
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    a:=lua_tointeger(L, 2);
    a2:=lua_tointeger(L,3);
    lua_pop(L, lua_gettop(L));

    TByteSelectEvent(m)(sender,a, a2);
  end
  else
    lua_pop(L, lua_gettop(L));

end;

function LuaCaller_AddressChangeEvent(L: PLua_state): integer; cdecl;  //(sender: TObject; address: ptruint);
var
  m: TMethod;
  sender: TObject;
  a: ptruint;
begin
  result:=0;
  if lua_gettop(L)=2 then
  begin
    //(sender: TObject; before, currentstate: boolean):
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    a:=lua_tointeger(L, 2);
    lua_pop(L, lua_gettop(L));

    TAddressChangeEvent(m)(sender,a);
  end
  else
    lua_pop(L, lua_gettop(L));

end;

function LuaCaller_DropFilesEvent(L: PLua_state): integer; cdecl;  //(sender: TObject; filenames: array of string);
var
  m: TMethod;
  sender: TObject;
  filenames: array of string;
  i: integer;
  f: string;

begin
  result:=0;
  if lua_gettop(L)=2 then
  begin
    //(sender: TObject; before, currentstate: boolean):
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);

    setlength(filenames,0);
    if lua_istable(L,2) then
    begin
      i:=1;
      while true do
      begin
        lua_pushinteger(L, i);
        lua_gettable(L, 2);
        if lua_isnil(L,-1) then
          break;

        f:=Lua_ToString(L,-1);
        lua_pop(L,1);

        setlength(filenames, length(filenames)+1);
        filenames[length(filenames)-1]:=f;

        inc(i);
      end;
    end;
    lua_pop(L, lua_gettop(L));

    TDropFilesEvent(m)(sender,filenames);
  end
  else
    lua_pop(L, lua_gettop(L));

end;

function LuaCaller_D3DClickEvent(L: PLua_state): integer; cdecl;
var
  m: TMethod;
  renderobject: TObject;
  x,y: integer;
begin
  result:=0;
  if lua_gettop(L)=3 then
  begin
    //(renderobject: TObject; x,y: integer);
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    renderobject:=lua_toceuserdata(L, 1);
    x:=lua_tointeger(L, 2);
    y:=lua_tointeger(L, 3);
    lua_pop(L, lua_gettop(L));

    TD3DClickEvent(m)(renderobject,x,y);
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_D3DKeyDownEvent(L: PLua_state): integer; cdecl;
var
  m: TMethod;
  VirtualKey: dword;
  c: string;
  x,y: integer;
  r: boolean;
begin
  result:=0;
  if lua_gettop(L)=2 then
  begin
    //(VirtualKey: dword; char: pchar): boolean;
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    virtualkey:=lua_tointeger(L, 1);
    c:=Lua_ToString(L,2);
    lua_pop(L, lua_gettop(L));

    if c<>'' then
    begin
      r:=TD3DKeyDownEvent(m)(VirtualKey,@c[1]);
      lua_pushboolean(L, r);
      result:=1;
    end;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_DisassembleEvent(L: PLua_state): integer; cdecl;
//function(sender: Disassembler, address: integer, LastDisassembleData: Table): boolean
var
  m: TMethod;
  sender: TObject;
  address: ptruint;
  r,d: string;
  ldd: TLastDisassembleData;
  b: boolean;
begin
  result:=0;
  if lua_gettop(L)=3 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=lua_toceuserdata(L, 1);
    address:=lua_tointeger(L, 2);
    LastDisassemblerDataFromTable(L, 3, ldd); //initialize it

    b:=TDisassembleEvent(m)(sender, address, ldd, r, d);
    if b then //returned true
    begin
      lua_pushstring(L, r);
      lua_pushstring(L, d);
      LastDisassemblerDataToTable(L, 3, ldd); //fill in the result
    end
    else
    begin
      lua_pushnil(L);
      lua_pushnil(L);
    end;

    result:=2;

  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_ScreenFormEvent(L: PLua_state): integer; cdecl;  //(form: TCustomForm);
var
  m: TMethod;
  sender: TObject;
  form: TCustomForm;
  a: ptruint;
begin
  result:=0;
  if lua_gettop(L)=1 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    sender:=screen;
    form:=lua_ToCEUserData(L, 1);
    lua_pop(L, lua_gettop(L));

    TScreenFormEvent(m)(sender, form);
  end
  else
    lua_pop(L, lua_gettop(L));

end;

function LuaCaller_BreakpointEvent(L: PLua_state): integer; cdecl; //():boolean;  //the state has already been set global
var
  m: TMethod;
  sender: TObject;
begin
  result:=0;
  if lua_gettop(L)=1 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));

    lua_pop(L, lua_gettop(L));


    TBreakpointEvent(m)(nil,nil);
  end
  else
    lua_pop(L, lua_gettop(L));

end;


function LuaCaller_MemRecChangeEvent(L: PLua_state): integer; cdecl;  //(al: TObject; memrec: TMemoryRecord)
var
  m: TMethod;
  al: TObject;
  mr: TMemoryRecord;
begin
  result:=0;
  if lua_gettop(L)=2 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    al:=lua_ToCEUserData(L, 1);
    mr:=lua_ToCEUserData(L, 2);
    lua_pop(L, lua_gettop(L));

    lua_pushboolean(L, TMemRecChangeEvent(m)(al, mr));
    result:=1;
  end
  else
    lua_pop(L, lua_gettop(L));
end;



function LuaCaller_GetDisplayValueEvent(L: PLua_state): integer; cdecl;  //(mr: TObject; value:string):true/newvalue
var
  m: TMethod;
  mr: TObject;
  value: string;
  r: boolean;
begin
  result:=0;
  if lua_gettop(L)=2 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    mr:=lua_ToCEUserData(L, 1);
    value:=Lua_ToString(L, 2);
    lua_pop(L, lua_gettop(L));

    lua_pushboolean(L, TGetDisplayValueEvent(m)(mr, value));
    lua_pushstring(L, value);
    result:=2;
  end
  else
    lua_pop(L, lua_gettop(L));
end;

function LuaCaller_MemScanGuiUpdateRoutine(L: PLua_state): integer; cdecl; //(sender, TotalAddressesToScan, CurrentlyScanned, ResultsFound)
var
  m: TMethod;
  ms: TObject;
  TotalAddressesToScan, CurrentlyScanned, ResultsFound: qword;
begin
  result:=0;
  if lua_gettop(L)=5 then
  begin
    m.code:=lua_touserdata(L, lua_upvalueindex(1));
    m.data:=lua_touserdata(L, lua_upvalueindex(2));
    ms:=lua_ToCEUserData(L, 1);
    TotalAddressesToScan:=lua_tointeger(L, 2);
    CurrentlyScanned:=lua_tointeger(L, 3);
    ResultsFound:=lua_tointeger(L, 4);

    TMemScanGuiUpdateRoutine(m)(ms, TotalAddressesToScan, CurrentlyScanned, ResultsFound);
    result:=0;
  end;
end;

procedure registerLuaCall(typename: string; getmethodprop: lua_CFunction; setmethodprop: pointer; luafunctionheader: string);
var t: TLuaCallData;
begin
  t:=TLuaCallData.Create;
  t.getmethodprop:=getmethodprop;
  t.setmethodprop:=setmethodprop;
  t.luafunctionheader:=luafunctionheader;
  LuaCallList.AddObject(typename, t);
end;

initialization
  LuaCallList:=TStringList.create;
  registerLuaCall('TNotifyEvent',  LuaCaller_NotifyEvent, pointer(TLuaCaller.NotifyEvent),'function %s(sender)'#13#10#13#10'end'#13#10);
  registerLuaCall('TSelectionChangeEvent', LuaCaller_SelectionChangeEvent, pointer(TLuaCaller.SelectionChangeEvent),'function %s(sender, user)'#13#10#13#10'end'#13#10);
  registerLuaCall('TCloseEvent', LuaCaller_CloseEvent, pointer(TLuaCaller.CloseEvent),'function %s(sender)'#13#10#13#10'return caHide --Possible options: caHide, caFree, caMinimize, caNone'#13#10'end'#13#10);
  registerLuaCall('TCloseQueryEvent', LuaCaller_CloseQueryEvent, pointer(TLuaCaller.CloseQueryEvent),'function %s(sender)'#13#10#13#10'return true --return false if you wish to block closing this form'#13#10'end'#13#10);
  registerLuaCall('TMouseEvent', LuaCaller_MouseEvent, pointer(TLuaCaller.MouseEvent),'function %s(sender, button, x, y)'#13#10#13#10'end'#13#10);
  registerLuaCall('TMouseMoveEvent', LuaCaller_MouseMoveEvent, pointer(TLuaCaller.MouseMoveEvent),'function %s(sender, x, y)'#13#10#13#10'end'#13#10);
  registerLuaCall('TMouseWheelUpDownEvent', LuaCaller_MouseWheelUpDownEvent, pointer(TLuaCaller.MouseWheelUpDownEvent),'function %s(sender, x, y)'#13#10#13#10'end'#13#10);
  registerLuaCall('TKeyPressEvent', LuaCaller_KeyPressEvent, pointer(TLuaCaller.KeyPressEvent),'function %s(sender, key)'#13#10#13#10'  return key'#13#10'end'#13#10);
  registerLuaCall('TKeyEvent', LuaCaller_KeyEvent, pointer(TLuaCaller.KeyEvent),'function %s(sender, key)'#13#10#13#10'  return key'#13#10'end'#13#10);
  registerLuaCall('TTVExpandingEvent', LuaCaller_TreeViewExpandOrCloseEvent, pointer(TLuaCaller.TreeViewExpandOrCloseEvent),'function %s(sender, node)'#13#10'  local allow=true'#13#10#13#10'  return allow'#13#10'end'#13#10);
  registerLuaCall('TTVCollapsingEvent', LuaCaller_TreeViewExpandOrCloseEvent, pointer(TLuaCaller.TreeViewExpandOrCloseEvent),'function %s(sender, node)'#13#10'  local allow=true'#13#10#13#10'  return allow'#13#10'end'#13#10);
  registerLuaCall('TLVCheckedItemEvent', LuaCaller_LVCheckedItemEvent, pointer(TLuaCaller.LVCheckedItemEvent),'function %s(sender, listitem)'#13#10#13#10'end'#13#10);
  registerLuaCall('TLVDeletedEvent', LuaCaller_LVCheckedItemEvent, pointer(TLuaCaller.LVCheckedItemEvent),'function %s(sender, listitem)'#13#10#13#10'end'#13#10);
  registerLuaCall('TLVColumnClickEvent', LuaCaller_LVColumnClickEvent, pointer(TLuaCaller.LVColumnClickEvent),'function %s(sender, listcolumn)'#13#10#13#10'end'#13#10);
  registerLuaCall('TLVCompareEvent', LuaCaller_LVCompareEvent, pointer(TLuaCaller.LVCompareEvent),'function %s(sender, listitem1, listitem2, data)'#13#10#13#10'  return 0 --0=equal -1=smaller 1=bigger'#13#10'end'#13#10);
  registerLuaCall('TCanResizeEvent', LuaCaller_CanResizeEvent, pointer(TLuaCaller.CanResizeEvent),'function %s(sender, newsize)'#13#10#13#10' local accept=true'#13#10'return newsize, accept'#13#10'end'#13#10);
  registerLuaCall('TLVSelectItemEvent', LuaCaller_LVSelectItemEvent, pointer(TLuaCaller.LVSelectItemEvent),'function %s(sender, listitem, selected)'#13#10#13#10'end'#13#10);

  //(Sender: TCustomListView; const ARect: TRect;  var DefaultDraw: Boolean
  registerLuaCall('TLVCustomDrawEvent', LuaCaller_LVCustomDrawEvent, pointer(TLuaCaller.LVCustomDrawEvent),'function %s(Sender, Rect)'#13#10#13#10'  return true --return true for DefaultDraw'#13#10'end'#13#10);

  //(Sender: TCustomListView; Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean) of object;
  registerLuaCall('TLVCustomDrawItemEvent', LuaCaller_LVCustomDrawItemEvent, pointer(TLuaCaller.LVCustomDrawItemEvent),'function %s(Sender, Item, State)'#13#10#13#10'  return true --return true for DefaultDraw'#13#10'end'#13#10);

  //(Sender: TCustomListView; Item: TListItem; SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean) of object;
  registerLuaCall('TLVCustomDrawSubItemEvent', LuaCaller_LVCustomDrawSubItemEvent, pointer(TLuaCaller.LVCustomDrawSubItemEvent),'function %s(Sender, Item, SubItem, State)'#13#10#13#10'  return true --return true for DefaultDraw'#13#10'end'#13#10);




  registerLuaCall('TMemoryRecordActivateEvent', LuaCaller_MemoryRecordActivateEvent, pointer(TLuaCaller.MemoryRecordActivateEvent),'function %s(sender, before, current)'#13#10#13#10'end'#13#10);

  registerLuaCall('TDisassemblerSelectionChangeEvent', LuaCaller_DisassemblerSelectionChangeEvent, pointer(TLuaCaller.DisassemblerSelectionChangeEvent),'function %s(sender, address, address2)'#13#10#13#10'end'#13#10);
  registerLuaCall('TDisassemblerExtraLineRender', LuaCaller_DisassemblerExtraLineRender, pointer(TLuaCaller.DisassemblerExtraLineRender),'function %s(sender, Address, AboveInstruction, Selected)'#13#10#13#10'return nil,0,0'#13#10#13#10'end'#13#10);
  registerLuaCall('TByteSelectEvent', LuaCaller_ByteSelectEvent, pointer(TLuaCaller.ByteSelectEvent),'function %s(sender, address, address2)'#13#10#13#10'end'#13#10);
  registerLuaCall('TAddressChangeEvent', LuaCaller_AddressChangeEvent, pointer(TLuaCaller.AddressChangeEvent),'function %s(sender, address)'#13#10#13#10'end'#13#10);

  registerLuaCall('TD3DClickEvent', LuaCaller_D3DClickEvent, pointer(TLuaCaller.D3DClickEvent),'function %s(renderobject, x, y)'#13#10#13#10'end'#13#10);
  registerLuaCall('TD3DKeyDownEvent', LuaCaller_D3DKeyDownEvent, pointer(TLuaCaller.D3DKeyDownEvent),'function %s(virtualkeycode, char)'#13#10#13#10'  return false'#13#10'end'#13#10);

  registerLuaCall('TDisassembleEvent', LuaCaller_DisassembleEvent, pointer(TLuaCaller.DisassembleEvent),'function %s(sender, address, ldd)'#13#10#13#10'  return disassembledstring, description'#13#10'end'#13#10);
  registerLuaCall('TDropFilesEvent', LuaCaller_DropFilesEvent, pointer(TLuaCaller.DropFilesEvent),'function %s(sender, filename)'#13#10#13#10'end'#13#10);

  registerLuaCall('TMemRecChangeEvent', LuaCaller_MemRecChangeEvent, pointer(TLuaCaller.MemRecChangeEvent),'function %s(al, memrec)'#13#10#13#10'  return false'#13#10'end'#13#10);
  registerLuaCall('TGetDisplayValueEvent', LuaCaller_GetDisplayValueEvent, pointer(TLuaCaller.GetDisplayValueEvent),'function %s(memrec, value)'#13#10#13#10'  return false,value'#13#10'end'#13#10);
  registerLuaCall('TMemScanGuiUpdateRoutine', LuaCaller_MemScanGuiUpdateRoutine, pointer(TLuaCaller.MemScanGuiUpdateRoutine),'function %s(Sender, TotalAddressesToScan, CurrentlyScanned, ResultsFound)'#13#10#13#10'end'#13#10);
end.

