unit LuaSymbolListHandler;

{$mode delphi}

interface

uses
  Classes, SysUtils, lua, lualib, LuaClass, SymbolListHandler;

procedure initializeLuaSymbolListHandler;

procedure pushSymbol(L: PLua_state; si: PCESymbolInfo);

implementation

uses LuaHandler, LuaObject, symbolhandler;

function createSymbolList(L: Plua_State): integer; cdecl;
begin
  result:=1;
  luaclass_newClass(L, TSymbolListHandler.create);
end;

function SymbolList_clear(L: Plua_State): integer; cdecl;
var
  sl: TSymbolListHandler;
begin
  sl:=luaclass_getClassObject(L);
  sl.clear;
  result:=0;
end;

function SymbolList_register(L: Plua_State): integer; cdecl;
var
  sl: TSymbolListHandler;
begin
  sl:=luaclass_getClassObject(L);
  symhandler.AddSymbolList(sl);
  result:=0;
end;

function SymbolList_unregister(L: Plua_State): integer; cdecl;
var
  sl: TSymbolListHandler;
begin
  sl:=luaclass_getClassObject(L);
  symhandler.RemoveSymbolList(sl);
  result:=0;
end;

procedure pushSymbol(L: PLua_state; si: PCESymbolInfo);
var tableindex: integer;
begin
  lua_newtable(L);
  tableindex:=lua_gettop(L);

  lua_pushstring(L,'modulename');
  lua_pushstring(L,si.module);
  lua_settable(L, tableindex);

  lua_pushstring(L,'searchkey');
  lua_pushstring(L,si.originalstring);
  lua_settable(L, tableindex);

  lua_pushstring(L,'address');
  lua_pushinteger(L,si.address);
  lua_settable(L, tableindex);

  lua_pushstring(L,'symbolsize');
  lua_pushinteger(L,si.size);
  lua_settable(L, tableindex);
end;

function SymbolList_GetSymbolFromAddress(L: Plua_State): integer; cdecl;
var
  sl: TSymbolListHandler;
  si: PCESymbolInfo;
begin
  result:=0;
  sl:=luaclass_getClassObject(L);

  si:=sl.FindAddress(lua_tointeger(L, 1));
  if si<>nil then
  begin
    pushSymbol(L, si);
    result:=1;
  end;
end;

function SymbolList_getSymbolFromString(L: Plua_State): integer; cdecl;
var
  sl: TSymbolListHandler;
  si: PCESymbolInfo;
begin
  result:=0;
  sl:=luaclass_getClassObject(L);

  si:=sl.FindSymbol(lua_tostring(L, 1));
  if si<>nil then
  begin
    pushSymbol(L, si);
    result:=1;
  end;
end;

function SymbolList_addSymbol(L: Plua_State): integer; cdecl;
var
  sl: TSymbolListHandler;
  si: PCESymbolInfo;

  modulename: string;
  searchkey: string;
  address: qword;
  size: integer;
  skipAddressToSymbol: boolean;

  esd: TExtraSymbolData;
  returntype: string;
  parameters: string;
begin
  result:=0;
  sl:=luaclass_getClassObject(L);
  esd:=nil;

  if lua_gettop(L)>=4 then //modulename, searchkey, address, symbolsize, skipAddressToSymbol
  begin
    modulename:=lua_tostring(L, 1);
    searchkey:=lua_tostring(L, 2);
    address:=lua_tointeger(L, 3);
    size:=lua_tointeger(L, 4);

    if lua_gettop(L)>=5 then
      skipAddressToSymbol:=lua_toboolean(L, 5)
    else
      skipAddressToSymbol:=false;

    if lua_gettop(L)>=6 then
    begin
      if lua_istable(L, 6) then
      begin
        lua_pushstring(L, 'returntype');
        lua_gettable(L, 6);

        returntype:=Lua_ToString(L, -1);
        lua_pop(L,1);

        lua_pushstring(L, 'parameters');
        lua_gettable(L, 6);

        parameters:=Lua_ToString(L, -1);
        lua_pop(L,1);

        if (returntype<>'') or (parameters<>'') then
        begin
          esd:=TExtraSymbolData.create;
          esd.return:=returntype;
          esd.simpleparameters:=parameters;

          esd.filledin:=true;

          sl.AddExtraSymbolData(esd);
        end;

      end;

    end
    else
      parameters:='';


    si:=sl.AddSymbol(modulename, searchkey, address, size, skipAddressToSymbol, esd);

    if esd<>nil then
      esd.free;

    pushSymbol(L, si);
    result:=1;
  end;
end;

function SymbolList_deleteSymbol(L: Plua_State): integer; cdecl;
var
  sl: TSymbolListHandler;
  si: PCESymbolInfo;
begin
  result:=0;
  sl:=luaclass_getClassObject(L);


  if lua_type(L,1)=LUA_TNUMBER then
  begin
    si:=sl.FindAddress(lua_tointeger(L, 1));
    if si<>nil then
    begin
      if si.extra<>nil then
      begin
        sl.RemoveExtraSymbolData(si.extra);
        si.extra.free;
      end;

      sl.DeleteSymbol(lua_tointeger(L, 1))
    end;
  end
  else
  begin
    si:=sl.FindSymbol(lua_tostring(L, 1));
    if si<>nil then
    begin
      if si.extra<>nil then
      begin
        sl.RemoveExtraSymbolData(si.extra);
        si.extra.free;
      end;

      sl.DeleteSymbol(lua_tostring(L, 1))
    end;

  end;
end;

procedure SymbolList_addMetaData(L: PLua_state; metatable: integer; userdata: integer );
begin
  object_addMetaData(L, metatable, userdata);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'clear', SymbolList_clear);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'getSymbolFromAddress', SymbolList_GetSymbolFromAddress);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'getSymbolFromString', SymbolList_getSymbolFromString);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'addSymbol', SymbolList_addSymbol);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'deleteSymbol', SymbolList_deleteSymbol);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'register', SymbolList_register);
  luaclass_addClassFunctionToTable(L, metatable, userdata, 'unregister', SymbolList_unregister);
end;

procedure initializeLuaSymbolListHandler;
begin
  lua_register(LuaVM, 'createSymbolList', createSymbolList);
end;

initialization
  luaclass_register(TSymbolListHandler, SymbolList_addMetaData);

end.

