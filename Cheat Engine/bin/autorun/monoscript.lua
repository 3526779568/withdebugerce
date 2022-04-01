if getTranslationFolder()~='' then
  loadPOFile(getTranslationFolder()..'monoscript.po')
end

MONOCMD_INITMONO=0
MONOCMD_OBJECT_GETCLASS=1
MONOCMD_ENUMDOMAINS=2
MONOCMD_SETCURRENTDOMAIN=3
MONOCMD_ENUMASSEMBLIES=4
MONOCMD_GETIMAGEFROMASSEMBLY=5
MONOCMD_GETIMAGENAME=6
MONOCMD_ENUMCLASSESINIMAGE=7
MONOCMD_ENUMFIELDSINCLASS=8
MONOCMD_ENUMMETHODSINCLASS=9
MONOCMD_COMPILEMETHOD=10
MONOCMD_GETMETHODHEADER=11
MONOCMD_GETMETHODHEADER_CODE=12
MONOCMD_LOOKUPRVA=13
MONOCMD_GETJITINFO=14
MONOCMD_FINDCLASS=15
MONOCMD_FINDMETHOD=16
MONOCMD_GETMETHODNAME=17
MONOCMD_GETMETHODCLASS=18
MONOCMD_GETCLASSNAME=19
MONOCMD_GETCLASSNAMESPACE=20
MONOCMD_FREEMETHOD=21
MONOCMD_TERMINATE=22
MONOCMD_DISASSEMBLE=23
MONOCMD_GETMETHODSIGNATURE=24
MONOCMD_GETPARENTCLASS=25
MONOCMD_GETSTATICFIELDADDRESSFROMCLASS=26
MONOCMD_GETTYPECLASS=27
MONOCMD_GETARRAYELEMENTCLASS=28
MONOCMD_FINDMETHODBYDESC=29
MONOCMD_INVOKEMETHOD=30
MONOCMD_LOADASSEMBLY=31
MONOCMD_GETFULLTYPENAME=32

MONOCMD_OBJECT_NEW=33
MONOCMD_OBJECT_INIT=34
MONOCMD_GETVTABLEFROMCLASS=35
MONOCMD_GETMETHODPARAMETERS=36



MONO_TYPE_END        = 0x00       -- End of List
MONO_TYPE_VOID       = 0x01
MONO_TYPE_BOOLEAN    = 0x02
MONO_TYPE_CHAR       = 0x03
MONO_TYPE_I1         = 0x04
MONO_TYPE_U1         = 0x05
MONO_TYPE_I2         = 0x06
MONO_TYPE_U2         = 0x07
MONO_TYPE_I4         = 0x08
MONO_TYPE_U4         = 0x09
MONO_TYPE_I8         = 0x0a
MONO_TYPE_U8         = 0x0b
MONO_TYPE_R4         = 0x0c
MONO_TYPE_R8         = 0x0d
MONO_TYPE_STRING     = 0x0e
MONO_TYPE_PTR        = 0x0f       -- arg: <type> token
MONO_TYPE_BYREF      = 0x10       -- arg: <type> token
MONO_TYPE_VALUETYPE  = 0x11       -- arg: <type> token
MONO_TYPE_CLASS      = 0x12       -- arg: <type> token
MONO_TYPE_VAR         = 0x13          -- number
MONO_TYPE_ARRAY      = 0x14       -- type, rank, boundsCount, bound1, loCount, lo1
MONO_TYPE_GENERICINST= 0x15          -- <type> <type-arg-count> <type-1> \x{2026} <type-n> */
MONO_TYPE_TYPEDBYREF = 0x16
MONO_TYPE_I          = 0x18
MONO_TYPE_U          = 0x19
MONO_TYPE_FNPTR      = 0x1b          -- arg: full method signature */
MONO_TYPE_OBJECT     = 0x1c
MONO_TYPE_SZARRAY    = 0x1d       -- 0-based one-dim-array */
MONO_TYPE_MVAR       = 0x1e       -- number */
MONO_TYPE_CMOD_REQD  = 0x1f       -- arg: typedef or typeref token */
MONO_TYPE_CMOD_OPT   = 0x20       -- optional arg: typedef or typref token */
MONO_TYPE_INTERNAL   = 0x21       -- CLR internal type */

MONO_TYPE_MODIFIER   = 0x40       -- Or with the following types */
MONO_TYPE_SENTINEL   = 0x41       -- Sentinel for varargs method signature */
MONO_TYPE_PINNED     = 0x45       -- Local var that points to pinned object */

MONO_TYPE_ENUM       = 0x55        -- an enumeration */

monoTypeToVartypeLookup={}
monoTypeToVartypeLookup[MONO_TYPE_BOOLEAN]=vtByte
monoTypeToVartypeLookup[MONO_TYPE_CHAR]=vtString
monoTypeToVartypeLookup[MONO_TYPE_I1]=vtByte
monoTypeToVartypeLookup[MONO_TYPE_U1]=vtByte
monoTypeToVartypeLookup[MONO_TYPE_I2]=vtWord
monoTypeToVartypeLookup[MONO_TYPE_U2]=vtWord
monoTypeToVartypeLookup[MONO_TYPE_I4]=vtDword
monoTypeToVartypeLookup[MONO_TYPE_U4]=vtDword
monoTypeToVartypeLookup[MONO_TYPE_I8]=vtQword
monoTypeToVartypeLookup[MONO_TYPE_U8]=vtQword
monoTypeToVartypeLookup[MONO_TYPE_R4]=vtSingle
monoTypeToVartypeLookup[MONO_TYPE_R8]=vtDouble
monoTypeToVartypeLookup[MONO_TYPE_STRING]=vtPointer --pointer to a string object
monoTypeToVartypeLookup[MONO_TYPE_PTR]=vtPointer
monoTypeToVartypeLookup[MONO_TYPE_BYREF]=vtPointer
monoTypeToVartypeLookup[MONO_TYPE_CLASS]=vtPointer
monoTypeToVartypeLookup[MONO_TYPE_FNPTR]=vtPointer
monoTypeToVartypeLookup[MONO_TYPE_GENERICINST]=vtPointer
monoTypeToVartypeLookup[MONO_TYPE_ARRAY]=vtPointer
monoTypeToVartypeLookup[MONO_TYPE_SZARRAY]=vtPointer


FIELD_ATTRIBUTE_FIELD_ACCESS_MASK=0x0007
FIELD_ATTRIBUTE_COMPILER_CONTROLLED=0x0000
FIELD_ATTRIBUTE_PRIVATE=0x0001
FIELD_ATTRIBUTE_FAM_AND_ASSEM=0x0002
FIELD_ATTRIBUTE_ASSEMBLY=0x0003
FIELD_ATTRIBUTE_FAMILY=0x0004
FIELD_ATTRIBUTE_FAM_OR_ASSEM=0x0005
FIELD_ATTRIBUTE_PUBLIC=0x0006
FIELD_ATTRIBUTE_STATIC=0x0010
FIELD_ATTRIBUTE_INIT_ONLY=0x0020
FIELD_ATTRIBUTE_LITERAL=0x0040
FIELD_ATTRIBUTE_NOT_SERIALIZED=0x0080
FIELD_ATTRIBUTE_SPECIAL_NAME=0x0200
FIELD_ATTRIBUTE_PINVOKE_IMPL=0x2000
FIELD_ATTRIBUTE_RESERVED_MASK=0x9500
FIELD_ATTRIBUTE_RT_SPECIAL_NAME=0x0400
FIELD_ATTRIBUTE_HAS_FIELD_MARSHAL=0x1000
FIELD_ATTRIBUTE_HAS_DEFAULT=0x8000
FIELD_ATTRIBUTE_HAS_FIELD_RVA=0x0100

MONO_TYPE_NAME_FORMAT_IL=0
MONO_TYPE_NAME_FORMAT_REFLECTION=1
MONO_TYPE_NAME_FORMAT_FULL_NAME=2
MONO_TYPE_NAME_FORMAT_ASSEMBLY_QUALIFIED=3



function monoTypeToVarType(monoType)
--MonoTypeEnum
  local result=monoTypeToVartypeLookup[monoType]

  if result==nil then
    result=vtDword --just give it something
  end

  return result
end


function LaunchMonoDataCollector()
  --if debug_canBreak() then return 0 end

  if (monopipe~=nil) then
    if (mono_AttachedProcess==getOpenedProcessID()) then
      return monoBase --already attached to this process
    end
    monopipe.destroy()
    monopipe=nil
  end


  if (monoeventpipe~=nil) then
    monoeventpipe.destroy()
    monoeventpipe=nil
  end

  local dllname="MonoDataCollector"
  if targetIs64Bit() then
    dllname=dllname.."64.dll"    
  else
    dllname=dllname.."32.dll"
  end

  if injectDLL(getCheatEngineDir()..[[\autorun\dlls\]]..dllname)==false then
    print(translate("Failure injecting the MonoDatacollector dll"))
    return 0
  end

  --wait till attached
  local timeout=getTickCount()+5000;
  while (monopipe==nil) and (getTickCount()<timeout) do
    monopipe=connectToPipe('cemonodc_pid'..getOpenedProcessID(),5000)
  end

  if (monopipe==nil) then
    return 0 --failure
  end

  monopipe.OnTimeout=function(self)
    monopipe.destroy()
    monopipe=nil
    mono_AttachedProcess=0
    monoBase=0     
  end

  --in case you implement the profiling tools use a secondary pipe to receive profiler events
 -- while (monoeventpipe==nil) do
 --   monoeventpipe=connectToPipe('cemonodc_pid'..getOpenedProcessID()..'_events')
 -- end

  mono_AttachedProcess=getOpenedProcessID()

  monopipe.writeByte(CMD_INITMONO)
  monopipe.ProcessID=getOpenedProcessID()
  monoBase=monopipe.readQword()

  if (monoBase~=0) then
    if mono_AddressLookupID==nil then
      mono_AddressLookupID=registerAddressLookupCallback(mono_addressLookupCallback)
    end

    if mono_SymbolLookupID==nil then
      mono_SymbolLookupID=registerSymbolLookupCallback(mono_symbolLookupCallback, slNotSymbol)
    end

    if mono_StructureNameLookupID==nil then
      mono_StructureNameLookupID=registerStructureNameLookup(mono_structureNameLookupCallback)
    end

    if mono_StructureDissectOverrideID==nil then
      mono_StructureDissectOverrideID=registerStructureDissectOverride(mono_structureDissectOverrideCallback)
    end

  end

  if (monoSettings==nil) then
    monoSettings=getSettings("MonoExtension")  
  end

  return monoBase
end

function mono_structureDissectOverrideCallback(structure, baseaddress)
--  print("oc")
  if monopipe==nil then return nil end
  
  local realaddress, classaddress=mono_object_findRealStartOfObject(baseaddress)
  if (realaddress==baseaddress) then
    local smap = {}
    local s = monoform_exportStructInternal(structure, classaddress, true, false, smap, false)
    return s~=nil
  else
    return nil
  end
end


function mono_structureNameLookupCallback(address)
  local currentaddress, classaddress, classname

  if monopipe==nil then return nil end
  
  local always=monoSettings.Value["AlwaysUseForDissect"]
  local r
  if (always==nil) or (always=="") then
    r=messageDialog(translate("Do you wish to let the mono extention figure out the name and start address? If it's not a proper object this may crash the target."), mtConfirmation, mbYes, mbNo, mbYesToAll, mbNoToAll)    
  else
    if (always=="1") then
      r=mrYes
    else
      r=mrNo
    end
  end
  
  
  if (r==mrYes) or (r==mbYesToAll) then
    currentaddress, classaddress, classname=mono_object_findRealStartOfObject(address)

    if (currentaddress~=nil) then
      -- print("currentaddress~=nil : "..currentaddress)
      return classname,currentaddress
    else
      --  print("currentaddress==nil")
      return nil
    end
  end

  --still alive, so the user made a good choice
  if (r==mrYesToAll) then
    monoSettings.Value["AlwaysUseForDissect"]="1"
  elseif (r==mrNoToAll) then
    monoSettings.Value["AlwaysUseForDissect"]="0"
  end
end


function mono_symbolLookupCallback(symbol)
  --if debug_canBreak() then return nil end

  local parts={}
  local x
  for x in string.gmatch(symbol, "[^:]+") do
    table.insert(parts, x)
  end

  local methodname=''
  local classname=''
  local namespace=''

  if (#parts>0) then
    methodname=parts[#parts]
    if (#parts>1) then
      classname=parts[#parts-1]
      if (#parts>2) then
        namespace=parts[#parts-2]
      end
    end
  end

  if (methodname~='') and (classname~='') then
    local method=mono_findMethod(namespace, classname, methodname)
    if (method==0) then
      return nil
    end

    local methodaddress=mono_compile_method(method)
    if (methodaddress~=0) then
      return methodaddress
    end

  end

  --still here,
  return nil

end


function mono_addressLookupCallback(address)
  --if (inMainThread()==false) or (debug_canBreak()) then --the debugger thread might call this
  --  return nil
  --end



  local ji=mono_getJitInfo(address)
  local result=''
  if ji~=nil then
--[[
        ji.jitinfo;
        ji.method
        ji.code_start
        ji.code_size
--]]
    if (ji.method~=0) then
      local class=mono_method_getClass(ji.method)

      if class==nil then return nil end


      local classname=mono_class_getName(class)
      local namespace=mono_class_getNamespace(class)
      if (classname==nil) or (namespace==nil) then return nil end

      if namespace~='' then
        namespace=namespace..':'
      end

      result=namespace..classname..":"..mono_method_getName(ji.method)
      if address~=ji.code_start then
        result=result..string.format("+%x",address-ji.code_start)
      end
    end

  end

  return result
end

function mono_object_getClass(address)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_OBJECT_GETCLASS)
  monopipe.writeQword(address)

  local classaddress=monopipe.readQword()
  if (classaddress~=nil) and (classaddress~=0) then
    local stringlength=monopipe.readWord()
    local classname

    if stringlength>0 then
      classname=monopipe.readString(stringlength)
    end
    monopipe.unlock()

    return classaddress, classname
  else
    monopipe.unlock()
    return nil
  end
end

function mono_enumDomains()
  --if debug_canBreak() then return nil end

  if monopipe==nil then return nil end


  monopipe.lock()
  monopipe.writeByte(MONOCMD_ENUMDOMAINS)
  local count=monopipe.readDword()
  local result={}
  local i
  if (count~=nil) then
    for i=1, count do
      result[i]=monopipe.readQword()
    end
  end

  monopipe.unlock()

  return result
end

function mono_setCurrentDomain(domain)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_SETCURRENTDOMAIN)
  monopipe.writeQword(domain)

  local result=monopipe.readDword()
  monopipe.unlock()
  return result;
end

function mono_enumAssemblies()
  local result=nil
  --if debug_canBreak() then return nil end
  if monopipe then
    monopipe.lock()
    monopipe.writeByte(MONOCMD_ENUMASSEMBLIES)
    local count=monopipe.readDword()
    if count~=nil then
      result={}
      local i
      for i=1, count do
        result[i]=monopipe.readQword()
      end
    end

    monopipe.unlock()
  end
  return result
end

function mono_getImageFromAssembly(assembly)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETIMAGEFROMASSEMBLY)
  monopipe.writeQword(assembly)
  monopipe.unlock()
  return monopipe.readQword()
end

function mono_image_get_name(image)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETIMAGENAME)
  monopipe.writeQword(image)
  local namelength=monopipe.readWord()
  local name=monopipe.readString(namelength)

  monopipe.unlock()
  return name
end

function mono_image_enumClasses(image)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_ENUMCLASSESINIMAGE)
  monopipe.writeQword(image)
  local classcount=monopipe.readDword()
  if classcount==nil then return nil end

  local classes={}
  local i,j
  j=1
  for i=1, classcount do
    local c=monopipe.readQword()

    if (c==nil) then break end

    if (c~=0) then
      classes[j]={}
      classes[j].class=c 
      local classnamelength=monopipe.readWord()
      if classnamelength>0 then
        classes[j].classname=monopipe.readString(classnamelength)
      else
        classes[j].classname=''
      end

      local namespacelength=monopipe.readWord()
      if namespacelength>0 then
        classes[j].namespace=monopipe.readString(namespacelength)
      else
        classes[j].namespace=''
      end
      j=j+1
    end
    
  end

  monopipe.unlock()

  return classes;
end

function mono_class_getName(class)
  --if debug_canBreak() then return nil end

  local result=''
  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETCLASSNAME)
  monopipe.writeQword(class)

  local namelength=monopipe.readWord();
  result=monopipe.readString(namelength);

  monopipe.unlock()
  return result;
end


function mono_class_getNamespace(clasS)
  --if debug_canBreak() then return nil end

  local result=''
  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETCLASSNAMESPACE)
  monopipe.writeQword(clasS)

  local namelength=monopipe.readWord();
  result=monopipe.readString(namelength);

  monopipe.unlock()
  return result;
end


function mono_class_getFullName(typeptr, isclass, nameformat)
  --if debug_canBreak() then return nil end
  if isclass==nil then isclass=1 end
  if nameformat==nil then nameformat=MONO_TYPE_NAME_FORMAT_REFLECTION end

  local result=''
  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETFULLTYPENAME)
  monopipe.writeQword(typeptr)
  monopipe.writeByte(isclass)
  monopipe.writeDword(nameformat)

  local namelength=monopipe.readWord();
  result=monopipe.readString(namelength);

  monopipe.unlock()
  return result;
end


function mono_class_getParent(class)
  --if debug_canBreak() then return nil end

  local result=0
  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETPARENTCLASS)
  monopipe.writeQword(class)  

  result=monopipe.readQword()

  monopipe.unlock()
  return result;
end

function mono_type_getClass(monotype)
  --if debug_canBreak() then return nil end

  local result=0
  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETTYPECLASS)
  monopipe.writeQword(monotype)  

  result=monopipe.readQword()

  monopipe.unlock()
  return result;
end

function mono_class_getArrayElementClass(klass)
  --if debug_canBreak() then return nil end

  local result=0
  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETARRAYELEMENTCLASS)
  monopipe.writeQword(klass)

  result=monopipe.readQword()

  monopipe.unlock()
  return result;
end

function mono_class_getVTable(domain, klass)
  --if debug_canBreak() then return nil end
  local result=0
  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETVTABLEFROMCLASS)
  monopipe.writeQword(domain)
  monopipe.writeQword(klass)
  
  result=monopipe.readQword()
  
  monopipe.unlock()
  return result  
end


--todo for the instance scanner: Get the fields and check that pointers are either nil or point to a valid address
function mono_class_findInstancesOfClassListOnly(domain, klass)
  local vtable=mono_class_getVTable(domain, klass)
  if (vtable) and (vtable~=0) then
    local ms=createMemScan()  
    local scantype=vtDword
    if targetIs64Bit() then
      scantype=vtQword
    end
    
    ms.firstScan(soExactValue,scantype,rtRounded,string.format('%x',vtable),'', 0,0x7ffffffffffffffff, '', fsmAligned, "8",true, true,false,false)

    ms.waitTillDone()  
    
    local fl=createFoundList(ms)
    fl.initialize()
    
    local result={}
    local i
    for i=0,fl.Count-1 do
      result[i+1]=tonumber('0x'..fl[i])
    end
    
    fl.destroy()    
    ms.destroy()    
    
    return result
  end
end


function mono_class_findInstancesOfClass(domain, klass, OnScanDone, ProgressBar)
  --find all instances of this class
  local vtable=mono_class_getVTable(domain, klass)
  if (vtable) and (vtable~=0) then
    --do a memory scan for this vtable, align on ending with 8/0 (fastscan 8) (64-bit can probably do fastscan 10)    
    
    local ms
    
    
    
    if OnScanDone~=nil then
      ms=createMemScan(ProgressBar)      
      ms.OnScanDone=OnScanDone
    else
      ms=createMemScan(MainForm.Progressbar)  
      ms.OnScanDone=function(m)
        local fl=createFoundList(m)
        MainForm.Progressbar.Position=0

        fl.initialize()

        local r=createForm(false)
        r.caption=translate('Instances of ')..mono_class_getName(klass)

        local lb=createListBox(r)
        local w=createLabel(r)
        w.Caption=translate('Warning: These are just guesses. Validate them yourself')
        w.Align=alTop
        lb.align=alClient
        lb.OnDblClick=function(sender)
          if sender.itemIndex>=0 then
            getMemoryViewForm().HexadecimalView.Address='0x'..sender.Items[sender.itemIndex]
            getMemoryViewForm().show()
          end
        end

        r.OnClose=function(f)
          return caFree
        end

        r.OnDestroy=function(f)
          lb.OnDblClick=nil
        end

        local i
        for i=0, fl.Count-1 do
          lb.Items.Add(fl[i])
        end

        r.position=poScreenCenter
        r.borderStyle=bsSizeable
        r.show()

        fl.destroy()
        m.destroy()
      end
    end
    
    local scantype=vtDword
    if targetIs64Bit() then
      scantype=vtQword
    end
    
    ms.firstScan(soExactValue,scantype,rtRounded,string.format('%x',vtable),'', 0,0x7ffffffffffffffff, '', fsmAligned, "8",true, true,false,false)
  end
  
end




function mono_class_getStaticFieldAddress(domain, class)
  --if debug_canBreak() then return nil end

  local result=0
  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETSTATICFIELDADDRESSFROMCLASS)
  monopipe.writeQword(domain)  
  monopipe.writeQword(class)  

  result=monopipe.readQword()

  monopipe.unlock()
  return result;
end

function mono_class_enumFields(class)
  --if debug_canBreak() then return nil end

  local classfield;
  local index=1;
  local fields={}

  monopipe.lock()

  monopipe.writeByte(MONOCMD_ENUMFIELDSINCLASS)
  monopipe.writeQword(class)

  repeat
    classfield=monopipe.readQword()
    if (classfield~=nil) and (classfield~=0) then
      local namelength;
      fields[index]={}
      fields[index].field=classfield
      fields[index].type=monopipe.readQword()
      fields[index].monotype=monopipe.readDword()

      fields[index].parent=monopipe.readQword()
      fields[index].offset=monopipe.readDword()
      fields[index].flags=monopipe.readDword()
     
      fields[index].isStatic=(bAnd(fields[index].flags, bOr(FIELD_ATTRIBUTE_STATIC, FIELD_ATTRIBUTE_HAS_FIELD_RVA))) ~= 0 --check mono for other fields you'd like to test
      fields[index].isConst=(bAnd(fields[index].flags, FIELD_ATTRIBUTE_LITERAL)) ~= 0

      namelength=monopipe.readWord();
      fields[index].name=monopipe.readString(namelength);

      namelength=monopipe.readWord();
      fields[index].typename=monopipe.readString(namelength);
      index=index+1
    end

  until (classfield==nil) or (classfield==0)

  monopipe.unlock()

  return fields

end

function mono_class_enumMethods(class)
  --if debug_canBreak() then return nil end

  local method
  local index=1
  local methods={}

  monopipe.lock()

  monopipe.writeByte(MONOCMD_ENUMMETHODSINCLASS)
  monopipe.writeQword(class)

  repeat
    method=monopipe.readQword()
    if (method~=nil) and (method~=0) then
      local namelength;
      methods[index]={}
      methods[index].method=method
      namelength=monopipe.readWord();
      methods[index].name=monopipe.readString(namelength);
      index=index+1
    end

  until (method==nil) or (method==0)

  monopipe.unlock()

  return methods
end

function mono_getJitInfo(address)
  --if debug_canBreak() then return nil end

  local d=mono_enumDomains()
  if (d~=nil) then
    monopipe.lock()

    for i=1, #d do
      monopipe.writeByte(MONOCMD_GETJITINFO)
      monopipe.writeQword(d[i])
      monopipe.writeQword(address)

      local jitinfo=monopipe.readQword()

      if (jitinfo~=nil) and (jitinfo~=0) then
        local result={}
        result.jitinfo=jitinfo;
        result.method=monopipe.readQword();
        result.code_start=monopipe.readQword();
        result.code_size=monopipe.readDword();

        monopipe.unlock() --found something
        return result
      end

    end

    monopipe.unlock()
  end
  return nil
end



function mono_object_findRealStartOfObject(address, maxsize)
  --if debug_canBreak() then return nil end

  if maxsize==nil then
    maxsize=4096
  end

  if address==nil then
    error(translate("address==nil"))
  end

  local currentaddress=bAnd(address, 0xfffffffffffffffc)


  while (currentaddress>address-maxsize) do
    local classaddress,classname=mono_object_getClass(currentaddress)

    if (classaddress~=nil) and (classname~=nil) then
      classname=classname:match "^%s*(.-)%s*$" --trim
      if (classname~='') then
        local r=string.find(classname, "[^%a%d_.]", 1)  --scan for characters that are not decimal or characters, or have a _ or . in the name


        if (r==nil) or (r>=5) then
          return currentaddress, classaddress, classname --good enough
        end
      end
    end

    currentaddress=currentaddress-4
  end

  --still here
  return nil

end



--function mono_findReferencesToObject(class) --scan the memory for objects with a vtable to a specific class
--end

function mono_image_findClass(image, namespace, classname)
  --if debug_canBreak() then return nil end

--find a class in a specific image
  monopipe.lock()

  monopipe.writeByte(MONOCMD_FINDCLASS)
  monopipe.writeQword(image)
  monopipe.writeWord(#classname)
  monopipe.writeString(classname)
  if (namespace~=nil) then
    monopipe.writeWord(#namespace)
    monopipe.writeString(namespace)
  else
    monopipe.writeWord(0)
  end

  result=monopipe.readQword()
  monopipe.unlock()

  return result
end

function mono_image_findClassSlow(image, namespace, classname)
  --if debug_canBreak() then return nil end

--find a class in a specific image
  local result=0

  monopipe.lock()

  local c=mono_image_enumClasses(image)
  if c then
    local i
    for i=1, #c do
      --check that classname is in c[i].classname
      if c[i].classname==classname then
        result=c[i].class
        break;
      end
    end

  end
  monopipe.unlock()

  return result
end

function mono_findClass(namespace, classname)
  --if debug_canBreak() then return nil end

--searches all images for a specific class
  local ass=mono_enumAssemblies()
  local result
  
  if ass==nil then return nil end

  for i=1, #ass do

    result=mono_image_findClass(mono_getImageFromAssembly(ass[i]), namespace, classname)
    if (result~=0) then
      return result;
    end


  end

  --still here:

  for i=1, #ass do
    result=mono_image_findClassSlow(mono_getImageFromAssembly(ass[i]), namespace, classname)
    if (result~=0) then
      return result;
    end
  end  


  return nil
end

function mono_class_findMethod(class, methodname)
  --if debug_canBreak() then return nil end

  if methodname==nil then return nil end
  if monopipe==nil then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_FINDMETHOD)
  monopipe.writeQword(class)

  monopipe.writeWord(#methodname)
  monopipe.writeString(methodname)

  local result=monopipe.readQword()


  monopipe.unlock()

  return result
end

function mono_findMethod(namespace, classname, methodname)
  --if debug_canBreak() then return nil end

  local class=mono_findClass(namespace, classname)
  local result=0
  if class and (class~=0) then
    result=mono_class_findMethod(class, methodname)
  end

  return result
end


function mono_class_findMethodByDesc(image, methoddesc)
  --if debug_canBreak() then return nil end

  if image==nil then return 0 end
  if methoddesc==nil then return 0 end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_FINDMETHODBYDESC)
  monopipe.writeQword(image)

  monopipe.writeWord(#methoddesc)
  monopipe.writeString(methoddesc)

  local result=monopipe.readQword()

  monopipe.unlock()

  return result
end

function mono_findMethodByDesc(assemblyname, methoddesc)
  --if debug_canBreak() then return nil end
  local assemblies = mono_enumAssemblies()
  for i=1, #assemblies do
      local image = mono_getImageFromAssembly(assemblies[i])
      local imagename = mono_image_get_name(image)
      if imagename == 'UnityEngine' then
        return mono_class_findMethodByDesc(image, methoddesc)
      end
  end
  return nil
end



--idea for the future:
--function mono_invokeMethod()
--  print("Not yet implemented")
--end

function mono_method_getName(method)
  --if debug_canBreak() then return nil end

  local result=''
  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETMETHODNAME)
  monopipe.writeQword(method)

  local namelength=monopipe.readWord();
  result=monopipe.readString(namelength);

  monopipe.unlock()
  return result;
end

function mono_method_getHeader(method)
  --if debug_canBreak() then return nil end
  if method==nil then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETMETHODHEADER)
  monopipe.writeQword(method)
  local result=monopipe.readQword()

  monopipe.unlock()

  return result;
end

function mono_method_get_parameters(method)
--like mono_method_getSignature but returns it in a more raw format (no need to string parse)
  --if debug_canBreak() then return nil end
  if monopipe==nil then return nil end
  
  if method==nil then return nil end
  local result={}
  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETMETHODPARAMETERS)
  monopipe.writeQword(method)  
  
  local paramcount=monopipe.readByte()
  if paramcount==nil then return nil end
  
  local i
  
  result.parameters={}
  
  --names
  for i=1, paramcount do  
    local namelength=monopipe.readByte()
    
    if namelength==nil then return nil end
    
    result.parameters[i]={}
    
    if namelength>0 then
      result.parameters[i].name=monopipe.readString(namelength)
    else
      result.parameters[i].name='param '..i
    end
  end
  
  --types
  for i=1, paramcount do  
    result.parameters[i].type=monopipe.readDword(); 
  end
  
  --result  
  result.returntype=monopipe.readDword()  
  
  monopipe.unlock()
  return result  
end

function mono_method_getSignature(method)
--Gets the method 'signature', the corresponding parameter names, and the returntype
  --if debug_canBreak() then return nil end
  
  if method==nil then return nil end
  if monopipe==nil then return nil end

  local result=''
  local parameternames={}
  local returntype=''
  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETMETHODSIGNATURE)
  monopipe.writeQword(method)

  local paramcount=monopipe.readByte()
  local i
  
  for i=1, paramcount do
    local namelength=monopipe.readByte()
    if namelength>0 then
      parameternames[i]=monopipe.readString(namelength)
    else
      parameternames[i]='param'..i
    end
  end


  local resultlength=monopipe.readWord();
  result=monopipe.readString(resultlength);

  local returntypelength=monopipe.readByte()
  returntype=monopipe.readString(returntypelength)  
  

  monopipe.unlock()
  return result, parameternames, returntype;
end

function mono_method_disassemble(method)
  --if debug_canBreak() then return nil end

  local result=''
  monopipe.lock()
  monopipe.writeByte(MONOCMD_DISASSEMBLE)
  monopipe.writeQword(method)

  local resultlength=monopipe.readWord();
  result=monopipe.readString(resultlength);

  monopipe.unlock()
  return result;
end

function mono_method_getClass(method)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETMETHODCLASS)
  monopipe.writeQword(method)
  local result=monopipe.readQword()

  monopipe.unlock()

  return result;
end


function mono_compile_method(method) --Jit a method if it wasn't jitted yet
  --if debug_canBreak() then return nil end

  monopipe.lock()

  monopipe.writeByte(MONOCMD_COMPILEMETHOD)
  monopipe.writeQword(method)
  local result=monopipe.readQword()
  monopipe.unlock()
  return result
end

--note: does not work while the profiler is active (Current implementation doesn't use the profiler, so we're good to go)
function mono_free_method(method) --unjit the method. Only works on dynamic methods. (most are not)
  --if debug_canBreak() then return nil end

  monopipe.lock()

  monopipe.writeByte(MONOCMD_FREEMETHOD)
  monopipe.writeQword(method)
  monopipe.unlock()
end

function mono_methodheader_getILCode(methodheader)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_GETMETHODHEADER_CODE)
  monopipe.writeQword(methodheader)
  local address=monopipe.readQword()
  local size=monopipe.readDword()

  monopipe.unlock()

  return address, size;
end

function mono_getILCodeFromMethod(method)
  local hdr=mono_method_getHeader(method)
  return mono_methodheader_getILCode(hdr)
end


function mono_image_rva_map(image, offset)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_LOOKUPRVA)
  monopipe.writeQword(image)
  monopipe.writeDword(offset)
  local address=monopipe.readQword()
  monopipe.unlock()
  return address;
end

function mono_readObject()
  local vtype = monopipe.readByte()
  if vtype == MONO_TYPE_VOID then
    return nil
  elseif vtype == MONO_TYPE_STRING then
    local resultlength=monopipe.readWord();
    return monopipe.readString(resultlength);
  end
  
  local vartype = monoTypeToVartypeLookup[vtype]
  if vartype == vtByte then
    return monopipe.readByte()
  elseif vartype == vtWord then
    return monopipe.readWord()
  elseif vartype == vtDword then
    return monopipe.readDword()
  elseif vartype == vtQword then
    return monopipe.readQword()
  elseif vartype == vtSingle then
    return monopipe.readFloat()
  elseif vartype == vtDouble then
    return monopipe.readDouble()
  elseif vartype == vtPointer then
    return monopipe.readQword()
  end  
  return nil
end

function mono_writeObject(vartype, value)
  if vartype == vtString then
    -- monopipe.writeByte(MONO_TYPE_STRING)
    monopipe.writeWord(#value);
    monopipe.writeString(value);
  elseif vartype == vtByte then
    -- monopipe.writeByte(MONO_TYPE_I1)
    monopipe.writeByte(value)
  elseif vartype == vtWord then
    -- monopipe.writeByte(MONO_TYPE_I2)
    monopipe.writeWord(value)
  elseif vartype == vtDword then
    -- monopipe.writeByte(MONO_TYPE_I4)
    monopipe.writeDword(value)
  elseif vartype == vtPointer then
    -- monopipe.writeByte(MONO_TYPE_PTR)
    monopipe.writeQword(value)
  elseif vartype == vtQword then
    -- monopipe.writeByte(MONO_TYPE_I8)
    monopipe.writeQword(value)
  elseif vartype == vtSingle then
    -- monopipe.writeByte(MONO_TYPE_R4)
    monopipe.writeFloat(value)
  elseif vartype == vtDouble then
    -- monopipe.writeByte(MONO_TYPE_R8)
    monopipe.writeDouble(value)
  else
    -- monopipe.writeByte(MONO_TYPE_VOID)
  end
  return nil
  
end

function mono_writeVarType(vartype)
  if vartype == vtString then
    monopipe.writeByte(MONO_TYPE_STRING)
  elseif vartype == vtByte then
    monopipe.writeByte(MONO_TYPE_I1)
  elseif vartype == vtWord then
    monopipe.writeByte(MONO_TYPE_I2)
  elseif vartype == vtDword then
    monopipe.writeByte(MONO_TYPE_I4)
  elseif vartype == vtPointer then
    monopipe.writeByte(MONO_TYPE_PTR)
  elseif vartype == vtQword then
    monopipe.writeByte(MONO_TYPE_I8)
  elseif vartype == vtSingle then
    monopipe.writeByte(MONO_TYPE_R4)
  elseif vartype == vtDouble then
    monopipe.writeByte(MONO_TYPE_R8)
  else
    monopipe.writeByte(MONO_TYPE_VOID)
  end
end


function mono_invoke_method_dialog(domain, method)
  --spawn a dialog where the user can fill in fields like: instance and parameter values
  --parameter fields will be of the proper type

  --the instance field may be a dropdown dialog which gets populated by mono_class_findInstancesOfClass* or a <new instance> button where the user can choose which constructor etc...
  if method==nil then return nil,'Method==nil' end
  
  local types, paramnames, returntype=mono_method_getSignature(method)

  if types==nil then return nil,'types==nil' end

  local mifinfo={}

  local typenames={}
  local tn
  for tn in string.gmatch(types, '([^,]+)') do
    table.insert(typenames, tn)
  end

  if #typenames~=#paramnames then return nil end

  mifinfo.mif=createForm(false)
  mifinfo.mif.position='poScreenCenter'
  mifinfo.mif.borderStyle='bsSizeable'

  local c=mono_method_getClass(method)
  local classname=''
  if c and (c~=0) then
    classname=mono_class_getName(c)..'.'
  end



  mifinfo.mif.Caption=translate('Invoke ')..classname..mono_method_getName(method)
  mifinfo.lblInstanceAddress=createLabel(mifinfo.mif)
  mifinfo.lblInstanceAddress.Caption=translate('Instance address')

  mifinfo.cbInstance=createComboBox(mifinfo.mif)
  
  --start a scan to fill the combobox with results
  mifinfo.cbInstance.Items.add(translate('<Please wait...>'))
  mono_class_findInstancesOfClass(nil,c,function(m)      
      --print("Scan done")

      if mifinfo.cbInstance then  --not destroyed yet
        mifinfo.cbInstance.Items.clear()
      
        local fl=createFoundList(m) 
        fl.initialize()
        local i
        for i=0, fl.Count-1 do
          mifinfo.cbInstance.Items.Add(fl[i])
        end
        
        fl.destroy()
      end      
      
      m.destroy()
    end
  )
  
  
  
  --[[ alternatively, fill it on DropDown
  mifinfo.cbInstance.OnDropDown=function(cb)
    --fill the combobox with instances
  end
  ]]
  
  mifinfo.gbParams=createGroupBox(mifinfo.mif)
  mifinfo.gbParams.Caption=translate('Parameters')


  mifinfo.gbParams.ChildSizing.ControlsPerLine=2
  mifinfo.gbParams.ChildSizing.Layout='cclLeftToRightThenTopToBottom'
  mifinfo.gbParams.ChildSizing.HorizontalSpacing=8
  mifinfo.gbParams.AutoSize=true

  mifinfo.pnlButtons=createPanel(mifinfo.mif)
  mifinfo.pnlButtons.ChildSizing.ControlsPerLine=2
  mifinfo.pnlButtons.ChildSizing.Layout='cclLeftToRightThenTopToBottom'

  mifinfo.pnlButtons.BevelOuter='bvNone'
  mifinfo.pnlButtons.BorderSpacing.Top=5
  mifinfo.pnlButtons.BorderSpacing.Bottom=5
  mifinfo.pnlButtons.ChildSizing.HorizontalSpacing=8


  mifinfo.btnOk=createButton(mifinfo.mif)
  mifinfo.btnCancel=createButton(mifinfo.mif)

  mifinfo.btnOk.Parent=mifinfo.pnlButtons
  mifinfo.btnCancel.Parent=mifinfo.pnlButtons

  mifinfo.pnlButtons.AutoSize=true

  mifinfo.btnOk.caption=translate('OK')
  mifinfo.btnCancel.caption=translate('Cancel')
  mifinfo.btnCancel.Cancel=true


  mifinfo.pnlButtons.AnchorSideBottom.Control=mifinfo.mif
  mifinfo.pnlButtons.AnchorSideBottom.Side=asrBottom
  mifinfo.pnlButtons.AnchorSideLeft.Control=mifinfo.mif
  mifinfo.pnlButtons.AnchorSideLeft.Side=asrCenter
  mifinfo.pnlButtons.Anchors='[akLeft, akBottom]'
 -- mifinfo.pnlButtons.Color=clRed



  mifinfo.lblInstanceAddress.AnchorSideTop.Control=mifinfo.mif
  mifinfo.lblInstanceAddress.AnchorSideTop.Side=asrTop
  mifinfo.lblInstanceAddress.AnchorSideTop.Left=mifinfo.mif
  mifinfo.lblInstanceAddress.AnchorSideTop.Side=asrLeft

  mifinfo.cbInstance.AnchorSideTop.Control=mifinfo.lblInstanceAddress
  mifinfo.cbInstance.AnchorSideTop.Side=asrBottom
  mifinfo.cbInstance.AnchorSideLeft.Control=mifinfo.mif
  mifinfo.cbInstance.AnchorSideLeft.Side=asrLeft
  mifinfo.cbInstance.AnchorSideRight.Control=mifinfo.mif
  mifinfo.cbInstance.AnchorSideRight.Side=asrRight
  mifinfo.cbInstance.Anchors='[akLeft, akRight, akTop]'





  mifinfo.gbParams.AnchorSideTop.Control=mifinfo.cbInstance
  mifinfo.gbParams.AnchorSideTop.Side=asrBottom
  mifinfo.gbParams.AnchorSideLeft.Control=mifinfo.mif
  mifinfo.gbParams.AnchorSideLeft.Side=asrLeft
  mifinfo.gbParams.AnchorSideRight.Control=mifinfo.mif
  mifinfo.gbParams.AnchorSideRight.Side=asrRight
  mifinfo.gbParams.AnchorSideBottom.Control=mifinfo.pnlButtons
  mifinfo.gbParams.AnchorSideBottom.Side=asrTop

  mifinfo.gbParams.Anchors='[akLeft, akRight, akTop, akBottom]'

  mifinfo.mif.AutoSize=true

  mifinfo.parameters={}
  local i
  for i=1, #typenames do
    local lblVarName=createLabel(mifinfo.mif)
    local edtVarText=createEdit(mifinfo.mif)

    lblVarName.Parent=mifinfo.gbParams
    edtVarText.Parent=mifinfo.gbParams

    lblVarName.Caption=paramnames[i]..': '..typenames[i]

    mifinfo.parameters[i]={}
    mifinfo.parameters[i].lblVarName=lblVarName
    mifinfo.parameters[i].edtVarText=edtVarText

    lblVarName.BorderSpacing.CellAlignVertical='ccaCenter'
  end

  mifinfo.btnOk.OnClick=function(b)
    local instance=getAddressSafe(mifinfo.cbInstance.Text)
    
    if instance==nil then
      instance=tonumber(mifinfo.cbInstance.Text)
    end

    if instance==nil then
      messageDialog(mifinfo.cbInstance.Text..translate(' is not a valid address'), mtError, mbOK)
      return
    end

    local params=mono_method_get_parameters(method)

    --use monoTypeToVartypeLookup to convert it to the type mono_method_invole likes it
    local args={}
    for i=1, #params.parameters do
      args[i]={}
      args[i].type=monoTypeToVartypeLookup[params.parameters[i].type]
      if args[i].type==vtString then
        args[i].value=mifinfo.parameters[i].edtVarText.Text
      else
        args[i].value=tonumber(mifinfo.parameters[i].edtVarText.Text)
      end

      if args[i].value==nil then
        messageDialog(translate('parameter ')..i..': "'..mifinfo.parameters[i].edtVarText.Text..'" '..translate('is not a valid value'), mtError, mbOK)
        return
      end
    end
    
    _G.args=args
    _G.instance=instance
    _G.method=method
    _G.bla=123
    
    local r=mono_invoke_method(domain, method, instance, args)
    if r then
      print(r)
    end

  end

  mifinfo.btnCancel.OnClick=function(b) mifinfo.mif.close() end



  mifinfo.mif.onClose=function(f)
    return caFree
  end

  mifinfo.mif.onDestroy=function(f)
    --destroy all objects
    mifinfo.btnOk.destroy()
    mifinfo.btnOk=nil
    
    mifinfo.btnCancel.destroy()
    mifinfo.btnCancel=nil

    mifinfo.cbInstance.destroy()
    mifinfo.cbInstance=nil
    
    mifinfo.gbParams.destroy()
    mifinfo.gbParams=nil

    mifinfo=nil
  end
  mifinfo.mif.show()
end


function mono_invoke_method(domain, method, object, args)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_INVOKEMETHOD)
  monopipe.writeQword(domain)
  monopipe.writeQword(method)
  monopipe.writeQword(object)
  monopipe.writeWord(#args)
  for i=1, #args do
    mono_writeVarType(args[i].type)
  end
  for i=1, #args do
    mono_writeObject(args[i].type, args[i].value)
  end
  
  local result=mono_readObject()
  monopipe.unlock()
  return result;
  
end

function mono_loadAssemblyFromFile(fname)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_LOADASSEMBLY)
  monopipe.writeWord(#fname)
  monopipe.writeString(fname)
  local result = monopipe.readQword()
  monopipe.unlock()
  return result;  
end

function mono_object_new(klass)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_OBJECT_NEW)
  monopipe.writeQword(klass)
  local result = monopipe.readQword()
  monopipe.unlock()
  return result;  
end

function mono_object_init(object)
  --if debug_canBreak() then return nil end

  monopipe.lock()
  monopipe.writeByte(MONOCMD_OBJECT_INIT)
  monopipe.writeQword(object)
  local result = monopipe.readByte()==1
  monopipe.unlock()
  return result;  
end

--[[

--------code belonging to the mono dissector form---------

--]]

function monoform_killform(sender)
  return caFree
end

function monoform_miShowMethodParametersClick(sender)  
  monoSettings.Value["ShowMethodParameters"]=sender.checked  
end


function monoform_miShowILDisassemblyClick(sender)
  if (monoForm.TV.Selected~=nil) then
    local node=monoForm.TV.Selected
    if (node~=nil) and (node.Level==4) and (node.Parent.Text=='methods') then
      local f=createForm()
      f.BorderStyle=bsSizeable
      f.centerScreen()
      f.Caption=node.Text
      f.OnClose=function(sender) return caFree end
      local m=createMemo(f)
      m.Align=alClient
      m.ScrollBars=ssBoth

      m.Lines.Text=mono_method_disassemble(node.Data)
    end
  end

end

function monoform_miInvokeMethodClick(sender)
  local node=monoForm.TV.Selected

  if (node~=nil) and (node.Level==4) and (node.Parent.Text=='methods') then
    mono_invoke_method_dialog(nil, node.data)
  end

  
end

function monoform_miRejitClick(sender)
  if (monoForm.TV.Selected~=nil) then
    local node=monoForm.TV.Selected
    if (node~=nil) and (node.Level==4) and (node.Parent.Text=='methods') then
      local r=mono_compile_method(node.Data)
      getMemoryViewForm().DisassemblerView.SelectedAddress=r
      getMemoryViewForm().show()
--      print(string.format("Method at %x", r))
    end
  end
end

function monoform_miGetILCodeClick(sender)
  if (monoForm.TV.Selected~=nil) then
    local node=monoForm.TV.Selected
    if (node~=nil) and (node.Level==4) and (node.Parent.Text=='methods') then
      local r,s=mono_getILCodeFromMethod(node.Data)
      if r~=nil then
        print(string.format(translate("ILCode from %x to %x"), r,r+s))
      end
    end
  end
end

function monoform_miDissectStaticStructureClick(sender)
  -- combine adding static to dissect and to table
  if (monoForm.TV.Selected~=nil) then
    local node=monoForm.TV.Selected
    if (node~=nil) and (node.Data~=nil) and (node.Level==2) then
      monoform_miAddStaticFieldAddressClick(sender) 
      local smap = monoform_getStructMap()
      local s = monoform_exportStruct(node.Data, nil, true, true, smap, true, false)
    end
  end
end

function monoform_miAddStructureClick(sender)
  if (monoForm.TV.Selected~=nil) then
    local node=monoForm.TV.Selected
    if (node~=nil) and (node.Data~=nil) and (node.Level==2) then
      local smap = monoform_getStructMap()
      local s = monoform_exportStruct(node.Data, nil, false, false, smap, true, false)
      s = monoform_exportStruct(node.Data, nil, false, true, smap, true, false)
    end
  end
end

function monoform_miAddStructureRecursiveClick(sender)
  if (monoForm.TV.Selected~=nil) then
    local node=monoForm.TV.Selected
    if (node~=nil) and (node.Data~=nil) and (node.Level==2) then
      local smap = monoform_getStructMap()
      local s = monoform_exportStruct(node.Data, nil, true, false, smap, true, false)
      s = monoform_exportStruct(node.Data, nil, true, true, smap, true, false)
    end
  end
end

function monoform_miFindInstancesOfClass(sender)
  local node=monoForm.TV.Selected
  if (node~=nil) then    
    if (node.Data~=nil) and (node.Level==2) then     
      mono_class_findInstancesOfClass(nil, node.data) 
    end
  end
end




--[[
function monoform_miCreateObject(sender)
  if (monoForm.TV.Selected~=nil) then
    local node=monoForm.TV.Selected
    if (node~=nil) and (node.Data~=nil) and (node.Level==2) then
      --create this class object and call the .ctor if it has one
      --todo: implement this 
      
    end
  end
end
--]]


-- Add the script for locating static data pointer for a class and adding records
function monoform_AddStaticClass(domain, image, class)
  if domain==nil or image==nil or class==nil then
    return
  end
  
  local addrs = getAddressList()
  local classname=mono_class_getName(class)
  local namespace=mono_class_getNamespace(class)
  local assemblyname=mono_image_get_name(image)

  local prefix, rootmr, mr
  prefix = ''
  rootmr=addresslist_createMemoryRecord(addrs)
  rootmr.Description = translate("Resolve ")..classname
  rootmr.Type = vtAutoAssembler

  local symclassname = classname:gsub("([^A-Za-z0-9%.,_$`<>%[%]])", "")
  local script = {}
  script[#script+1] = '[ENABLE]'
  script[#script+1] = monoAA_GETMONOSTATICDATA(assemblyname, namespace, classname, symclassname, true)
  script[#script+1] = '[DISABLE]'
  script[#script+1] = monoAA_GETMONOSTATICDATA(assemblyname, namespace, classname, symclassname, false)
  rootmr.Script = table.concat(script,"\n")
  memoryrecord_setColor(rootmr, 0xFF0000)
  --local data = mono_class_getStaticFieldAddress(domain, class)
  --rootmr.Address = string.format("%08X",data)
  --rootmr.Type = vtPointer
  mr=addresslist_createMemoryRecord(addrs)
  mr.Description=classname..'.Static'
  mr.Address='['..symclassname..".Static]"
  mr.Type=vtPointer
  mr.appendToEntry(rootmr)

  mr=addresslist_createMemoryRecord(addrs)
  mr.Description=classname..'.Class'
  mr.Address='['..symclassname..".Class]"
  mr.Type=vtPointer
  mr.appendToEntry(rootmr)

  local i
  local fields=mono_class_enumFields(class)
  for i=1, #fields do
    if fields[i].isStatic and not fields[i].isConst and (field==nil or fields[i].field==field) then
      local fieldName = fields[i].name:gsub("([^A-Za-z0-9%.,_$`<>%[%]])", "")
      local offset = fields[i].offset
      if fieldName==nil or fieldName:len()==0 then
        fieldName = string.format(translate("Offset %x"), offset)
      end
      mr=addresslist_createMemoryRecord(addrs)
      mr.Description=prefix..fieldName

      if fields[i].monotype==MONO_TYPE_STRING then
        -- mr.Address=string.format("[[%s.Static]+%X]+C",symclassname,offset)
        mr.Address=symclassname..'.Static'
        mr.OffsetCount=2
        mr.Offset[0]=0xC
        mr.Offset[1]=offset
        mr.Type=vtString
        memoryrecord_string_setUnicode(mr, true)
        memoryrecord_string_setSize(mr, 80)
      else
        mr.Address=symclassname..'.Static'
        mr.OffsetCount=1
        mr.Offset[0]=offset
        mr.Type=monoTypeToVarType(fields[i].monotype)
      end
      if rootmr~=nil then
         mr.appendToEntry(rootmr)
      else
          break
      end
    end
  end
end

function monoform_AddStaticClassField(domain, image, class, fieldclass, field)
  if domain==nil or image==nil or class==nil or fieldclass==nil or field==nil then
    return
  end
  local i
  local fields=mono_class_enumFields(fieldclass)
  for i=1, #fields do
    if fields[i].field==field then
      local fieldname = fields[i].name
      local offset = fields[i].offset
      if fieldname==nil or fieldname:len()==0 then
        fieldname = string.format(translate("Offset %x"), offset)
      end
      
      local addrs = getAddressList()
      local classname=mono_class_getName(class)
      local namespace=mono_class_getNamespace(class)
      local assemblyname=mono_image_get_name(image)

      local rootmr, mr
      rootmr=addresslist_createMemoryRecord(addrs)
      rootmr.Description = translate("Resolve ")..classname.."."..fieldname
      rootmr.Type = vtAutoAssembler

      local symclassname = classname:gsub("[^A-Za-z0-9._]", "")
      local symfieldname = fieldname:gsub("[^A-Za-z0-9._]", "")
      local script = {}
      script[#script+1] = '[ENABLE]'
      script[#script+1] = monoAA_GETMONOSTATICFIELDDATA(assemblyname, namespace, classname, fieldname, symclassname, true)
      script[#script+1] = '[DISABLE]'
      script[#script+1] = monoAA_GETMONOSTATICFIELDDATA(assemblyname, namespace, classname, fieldname, symclassname, false)
      rootmr.Script = table.concat(script,"\n")
      memoryrecord_setColor(rootmr, 0xFF0000)
      
      mr=addresslist_createMemoryRecord(addrs)
      mr.Description=classname..'.'..fieldname
      mr.appendToEntry(rootmr)

      if fields[i].monotype==MONO_TYPE_STRING then
        mr.Address=symclassname..'.'..symfieldname
        mr.OffsetCount=1
        mr.Offset[0]=0xC
        mr.Type=vtString
        memoryrecord_string_setUnicode(mr, true)
        memoryrecord_string_setSize(mr, 80)
      else
        mr.Address="["..symclassname..'.'..symfieldname.."]"
        mr.Type=monoTypeToVarType(fields[i].monotype)
      end      
      break
    end
  end
end

function monoform_miAddStaticFieldAddressClick(sender)
  if (monoForm.TV.Selected~=nil) then
    local node=monoForm.TV.Selected
    local domain, image, class, field
    if (node~=nil) and (node.Data~=nil) then
      if (node.Level>=4) and (node.Parent.Text=='static fields') then
        local inode = node.Parent.Parent.Parent
        local cnode = node.Parent.Parent
        local fieldclass = cnode.Data
        while inode.Text == 'base class' do
          cnode = inode.Parent
          inode = cnode.Parent
        end        
        domain = inode.Parent.Data
        image = inode.Data
        class = cnode.Data
        field = node.Data
        monoform_AddStaticClassField(domain, image, class, fieldclass, field)
      elseif (node~=nil) and (node.Data~=nil) and (node.Level==2) then
        domain = node.Parent.Parent.Data
        image = node.Parent.Data
        class = node.Data
        monoform_AddStaticClass(domain, image, class)
      elseif (node~=nil) and (node.Data~=nil) and (node.Level==3) then
        domain = node.Parent.Parent.Parent.Data
        image = node.Parent.Parent.Data
        class = node.Parent.Data
        monoform_AddStaticClass(domain, image, class)
      end
    end

  end
end


function monoform_context_onpopup(sender)
  local node=monoForm.TV.Selected

  local methodsEnabled = (node~=nil) and (node.Level==4) and (node.Parent.Text=='methods')
  monoForm.miRejit.Enabled = methodsEnabled
  monoForm.miInvokeMethod.Enabled = methodsEnabled
  monoForm.miGetILCode.Enabled = methodsEnabled
  monoForm.miShowILDisassembly.Enabled = methodsEnabled
  local structuresEnabled = (node~=nil) and (node.Data~=nil) and (node.Level==2)
  monoForm.miExportStructure.Enabled = structuresEnabled
  local fieldsEnabled = (node~=nil) and (node.Data~=nil)
    and ( (node.Level==2)
      or ((node.Level>=3) and (node.Text=='static fields'))
      or ((node.Level>=4) and (node.Parent.Text=='static fields')))
  monoForm.miFieldsMenu.Enabled = fieldsEnabled
  monoForm.miAddStaticFieldAddress.Enabled = fieldsEnabled
  
  monoForm.miFindInstancesOfClass.Enabled=structuresEnabled
end

function monoform_EnumImages(node)
  --print("monoform_EnumImages")
  local i
  local domain=node.Data
  --mono_setCurrentDomain(domain)
  local assemblies=mono_enumAssemblies()

  for i=1, #assemblies do
    local image=mono_getImageFromAssembly(assemblies[i])
    local imagename=mono_image_get_name(image)
    local n=node.add(string.format("%x : %s", image, imagename))
    n.HasChildren=true;
    n.Data=image

  end
end

function monoform_AddClass(node, klass, namespace, classname, fqname)
  local desc=string.format("%x : %s", klass, fqname)
  local n=node.add(desc)
  n.Data=klass
  
  local nf=n.add("static fields")
  nf.Data=klass
  nf.HasChildren=true
  
  local nf=n.add("fields")
  nf.Data=klass
  nf.HasChildren=true

  local nm=n.add("methods")
  nm.Data=klass
  nm.HasChildren=true
  
  local p = mono_class_getParent(klass)
  if p~=nil then
    local np=n.add("base class")
    np.Data=p
    np.HasChildren=true
  end
end

function monoform_EnumClasses(node)
  --print("monoform_EnumClasses")
  local image=node.Data
  local classes=mono_image_enumClasses(image)
  local i
  if classes~=nil then
    for i=1, #classes do
      classes[i].fqname = mono_class_getFullName(classes[i].class)
    end
  
    local monoform_class_compare = function (a,b)
      if a.namespace < b.namespace then
        return true
      elseif b.namespace < a.namespace then
        return false
      end
      if a.fqname < b.fqname then
        return true
      elseif b.fqname < a.fqname then
        return false
      end
      return a.class < b.class
    end
  
    table.sort(classes, monoform_class_compare)

    for i=1, #classes do
      monoform_AddClass(node, classes[i].class, classes[i].namespace, classes[i].classname, classes[i].fqname)
    end
  end

end;

function monoform_EnumFields(node, static)
 -- print("monoform_EnumFields")
  local i
  local class=node.Data;
  local fields=mono_class_enumFields(class)
  for i=1, #fields do
    if fields[i].isStatic == static and not fields[i].isConst then
      local n=node.add(string.format(translate("%x : %s (type: %s)"), fields[i].offset, fields[i].name,  fields[i].typename))
      n.Data=fields[i].field
    end
  end
end

function getParameterFromMethod(method)
  if method==nil then return ' ERR:method==nil' end
  
  local types,paramnames,returntype=mono_method_getSignature(method)
  
  if types==nil then return ' ERR:types==nil' end

  local typenames={}
  local tn
  for tn in string.gmatch(types, '([^,]+)') do
    table.insert(typenames, tn)
  end

  if #typenames==#paramnames then
    local r='('
    local i
    local c=#paramnames

    for i=1,c do
      r=r..paramnames[i]..': '..typenames[i]
      if i<c then
        r=r..'; '
      end
    end

    r=r..'):'..returntype
    return r

  else
    return '? - ('..types..'):'..returntype
  end
end


function monoform_EnumMethods(node)
  --print("monoform_EnumMethods")
  local i
  local class=node.Data;


  local methods=mono_class_enumMethods(class)
  for i=1, #methods do
    local parameters=''
    if monoForm.miShowMethodParameters.Checked then
      parameters=getParameterFromMethod(methods[i].method)
      if parameters==nil then parameters='' end
    end
    
    local n=node.add(string.format("%x : %s %s", methods[i].method, methods[i].name, parameters))
    n.Data=methods[i].method
  end
end


function mono_TVExpanding(sender, node)
  --print("mono_TVExpanding")
  --print("node.Count="..node.Count)
  --print("node.Level="..node.Level)

  local allow=true
  if (node.Count==0) then
    if (node.Level==0) then  --images
      monoform_EnumImages(node)
    elseif (node.Level==1) then --classes
      monoform_EnumClasses(node)
    elseif (node.Level>=3) and (node.Text=='static fields') then --static fields
      monoform_EnumFields(node, true)
    elseif (node.Level>=3) and (node.Text=='fields') then --fields
      monoform_EnumFields(node, false)
    elseif (node.Level>=3) and (node.Text=='methods') then --methods
      monoform_EnumMethods(node)
    elseif (node.Level>=3) and (node.Text=='base class') then 
      if (monoForm.autoExpanding==nil) or (monoForm.autoExpanding==false) then
        local klass = node.Data
        if (klass ~= 0) then
          local classname=mono_class_getName(klass)
          local namespace=mono_class_getNamespace(klass)
          local fqname=mono_class_getFullName(klass)
          monoform_AddClass(node, klass, namespace, classname, fqname)
        end
      else
        allow=false --don't auto expand the base classes
      end
    end

  end

  return allow
end


function mono_TVCollapsing(sender, node)
  local allow=true

  return allow
end

function monoform_FindDialogFind(sender)
  local texttofind=string.lower(monoForm.FindDialog.FindText)
  local tv=monoForm.TV
  local startindex=0

  if tv.Selected~=nil then
    startindex=tv.Selected.AbsoluteIndex+1
  end


  local i


  if string.find(monoForm.FindDialog.Options, 'frEntireScope') then
    --deep scan
    tv.beginUpdate()
    i=startindex
    while i<tv.Items.Count do
      local node=monoForm.TV.items[i]
      local text=string.lower(node.Text)

      if string.find(text, texttofind)~=nil then
          --found it
        tv.Selected=node
        break
      end



      if node.HasChildren then
          node.Expand(false)
        end

      i=i+1
    end

    tv.endUpdate()
  else
    --just the already scanned stuff
    for i=startindex, tv.Items.Count-1 do
      local node=monoForm.TV.items[i]
      local text=string.lower(node.Text)

      if string.find(text, texttofind)~=nil then
          --found it
        tv.Selected=node
        return
      end
    end
  end



end

function monoform_miFindClick(sender)
  monoForm.FindDialog.execute()
end


function monoform_miExpandAllClick(sender)
  if messageDialog(translate("Are you sure you wish to expand the whole tree? This can take a while and Cheat Engine may look like it has crashed (It has not)"), mtConfirmation, mbYes, mbNo)==mrYes then
    monoForm.TV.beginUpdate()
    monoForm.autoExpanding=true --special feature where a base object can contain extra lua variables
    monoForm.TV.fullExpand()
    monoForm.autoExpanding=false
    monoForm.TV.endUpdate()
  end
end

function monoform_miSaveClick(sender)
  if monoForm.SaveDialog.execute() then
    monoForm.TV.saveToFile(monoForm.SaveDialog.Filename)
  end
end



function mono_dissect()
  --shows a form with a treeview that holds all the data nicely formatted.
  --only fetches the data when requested
  if (monopipe==nil)  then
    LaunchMonoDataCollector()
  end

  if (monoForm==nil) then
    monoForm=createFormFromFile(getCheatEngineDir()..[[\autorun\forms\MonoDataCollector.frm]])
    if monoSettings.Value["ShowMethodParameters"]~=nil then
      monoForm.miShowMethodParameters.Checked=monoSettings.Value["ShowMethodParameters"]=='1'
    end
  end

  monoForm.show()

  monoForm.TV.Items.clear()

  local domains=mono_enumDomains()
  local i

  if (domains~=nil) then
    for i=1, #domains do
      n=monoForm.TV.Items.add(string.format("%x", domains[i]))
      n.Data=domains[i]
      monoForm.TV.Items[i-1].HasChildren=true
    end
  end

end

function miMonoActivateClick(sender)
  if LaunchMonoDataCollector()==0 then
    showMessage(translate("Failure to launch"))
  end
end

function miMonoDissectClick(sender)
  mono_dissect()
end




function mono_OpenProcessMT(t)
  if t~=nil then
    t.destroy()
  end

  --enumModules is faster than getAddress at OpenProcess time (No waiting for all symbols to be loaded first)
  local usesmono=false
  local m=enumModules()
  local i
  for i=1, #m do
    if (m[i].Name=='mono.dll') or (string.sub(m[i].Name,1,5)=='mono-') then
      usesmono=true
      break
    end
  end



  if usesmono then
    --create a menu item if needed
    if (miMonoTopMenuItem==nil) then
      local mfm=getMainForm().Menu
      
	    if (mfm) then
        local mi
        miMonoTopMenuItem=createMenuItem(mfm)
        miMonoTopMenuItem.Caption=translate("Mono")
        mfm.Items.insert(mfm.Items.Count-1, miMonoTopMenuItem) --add it before help

        mi=createMenuItem(miMonoTopMenuItem)
        mi.Caption=translate("Activate mono features")
        mi.OnClick=miMonoActivateClick        
        mi.Name='miMonoActivate'
        miMonoTopMenuItem.Add(mi)

        mi=createMenuItem(miMonoTopMenuItem)
        mi.Caption=translate("Dissect mono")
        mi.Shortcut="Ctrl+Alt+M"
        mi.OnClick=miMonoDissectClick
        mi.Name='miMonoDissect'
        miMonoTopMenuItem.Add(mi)
        
        
        miMonoTopMenuItem.OnClick=function(s)
          miMonoTopMenuItem.miMonoActivate.Checked=monopipe~=nil          
        end
        
        
      end
    end
  else
    --destroy the menu item if needed
    if miMonoTopMenuItem~=nil then
      miMonoTopMenuItem.miMonoDissect.destroy() --clean up the onclick handler
      miMonoTopMenuItem.miMonoActivate.destroy()  --clean up the onclick handler
      
      miMonoTopMenuItem.destroy() --also destroys the subitems as they are owned by this menuitem
      miMonoTopMenuItem=nil
    end

    if monopipe~=nil then
      monopipe.destroy()
      monopipe=nil

      if mono_AddressLookupID~=nil then
        unregisterAddressLookupCallback(mono_AddressLookupID)
        mono_AddressLookupID=nil
      end


      if mono_SymbolLookupID~=nil then
        unregisterSymbolLookupCallback(mono_SymbolLookupID)
        mono_SymbolLookupID=nil
      end

    end
  end

  if (monopipe~=nil) and (monopipe.ProcessID~=getOpenedProcessID()) then
    --different process
    monopipe.destroy()
    monopipe=nil

    if mono_AddressLookupID~=nil then
      unregisterAddressLookupCallback(mono_AddressLookupID)
      mono_AddressLookupID=nil
    end


    if mono_SymbolLookupID~=nil then
      unregisterSymbolLookupCallback(mono_SymbolLookupID)
      mono_SymbolLookupID=nil
    end

    if mono_StructureNameLookupID~=nil then
      unregisterStructureNameLookup(mono_StructureNameLookupID)
      mono_StructureNameLookupID=nil
    end

    if mono_StructureDissectOverrideID~=nil then
      unregisterStructureDissectOverride(mono_StructureDissectOverrideID)
      mono_StructureDissectOverrideID=nil
    end
  end

end

function mono_OpenProcess(processid)
  --call the original onOpenProcess if there was one
  if mono_oldOnOpenProcess~=nil then
    mono_oldOnOpenProcess(processid)
  end

  synchronize("mono_OpenProcessMT")




  --t=createTimer()
  --t.Interval=1000
  --t.OnTimer="mono_OpenProcessEpilogue"
  --t.Enabled=true
end

function monoAA_USEMONO(parameters, syntaxcheckonly)
  --called whenever an auto assembler script encounters the USEMONO() line
  --the value you return will be placed instead of the given line
  --In this case, returning a empty string is fine
  --Special behaviour: Returning nil, with a secondary parameter being a string, will raise an exception on the auto assembler with that string

  --another example:
  --return parameters..":\nnop\nnop\nnop\n"
  --you'd then call it using usemono(00400500) for example

  if (syntaxcheckonly==false) and (LaunchMonoDataCollector()==0) then
    return nil,translate("The mono handler failed to initialize")
  end

  return "" --return an empty string (removes it from the internal aa assemble list)
end

function monoAA_FINDMONOMETHOD(parameters, syntaxcheckonly)
  --called whenever an auto assembler script encounters the MONOMETHOD() line

  --parameters: name, fullmethodnamestring
  --turns into a define that sets up name as an address to this method

  local name, fullmethodnamestring, namespace, classname, methodname, methodaddress
  local c,d,e

  --parse the parameters
  c=string.find(parameters,",")
  if c~=nil then
    name=string.sub(parameters, 1,c-1)

    fullmethodnamestring=string.sub(parameters, c+1, #parameters)
    c=string.find(fullmethodnamestring,":")
    if (c~=nil) then
      namespace=string.sub(fullmethodnamestring, 1,c-1)
    else
      namespace='';
    end

    d=string.find(fullmethodnamestring,":",c)
    if (d~=nil) then
      e=string.find(fullmethodnamestring,":",d+1)
      if e~=nil then
        classname=string.sub(fullmethodnamestring, c+1, e-1)
        methodname=string.sub(fullmethodnamestring, e+1, #fullmethodnamestring)
      else
        return nil,translate("Invalid parameters (Methodname could not be determined)")
      end
    else
      return nil,translate("Invalid parameters (Classname could not be determined)")
    end
  else
    return nil,translate("Invalid parameters (name could not be determined)")
  end


  classname=classname:match "^%s*(.-)%s*$" --trim
  methodname=methodname:match "^%s*(.-)%s*$" --trim


  if syntaxcheckonly then
    return "define("..name..",00000000)"
  end

  if (monopipe==nil) or (monopipe.Connected==false) then
    LaunchMonoDataCollector()
  end

  if (monopipe==nil) or (monopipe.Connected==false) then
    return nil,translate("The mono handler failed to initialize")
  end


  local method=mono_findMethod(namespace, classname, methodname)
  if (method==0) then
    return nil,fullmethodnamestring..translate(" could not be found")
  end

  methodaddress=mono_compile_method(method)
  if (methodaddress==0) then
    return nil,fullmethodnamestring..translate(" could not be jitted")
  end


  local result="define("..name..","..string.format("%x", methodaddress)..")"

 -- showMessage(result)

  return result
end

function monoform_getStructMap()
  -- TODO: bug check for getStructureCount which does not return value correctly in older CE
  local structmap={}
  local n=getStructureCount()
  if n==nil then
    showMessage(translate("Sorry this feature does not work yet.  getStructureCount needs patching first."))
    return nil
  end
  local fillChildStruct = function (struct, structmap) 
    local i, e, s
    if struct==nil then return end
    for i=0, struct.Count-1 do
      e = struct.Element
      if e.Vartype == vtPointer then
        s = e.ChildStruct
        if s~=nil then fillChildStruct(s, structmap) end
      end      
    end
  end
  for i=0, n-1 do
    local s = getStructure(i)
    structmap[s.Name]=s
    fillChildStruct(s, structmap)
  end
  return structmap
end

function mono_purgeDuplicateGlobalStructures()
  local smap = monoform_getStructMap()
  local n=getStructureCount()
  local slist = {}
  for i=0, n-1 do
    local s1 = getStructure(i)
    local s2 = smap[s1.Name]
    if s1 ~= s2 then
       slist[s1.Name] = s1
    end
  end
  local name
  local s
  for name, s in pairs(slist) do
    print(translate("Removing ")..name)
    structure_removeFromGlobalStructureList(s)
  end
end

function mono_reloadGlobalStructures(imagename)
  local smap = monoform_getStructMap()
  local classmap = {}
  local staticmap = {}
  local arraymap = {}
  local imageclasses = {}
  
  local i, j
  local fqclass, caddr
  local assemblies=mono_enumAssemblies()
  for i=1, #assemblies do
    local image=mono_getImageFromAssembly(assemblies[i])
    local iname=mono_image_get_name(image)
    if imagename==nil or imagename==iname then
      local classes=mono_image_enumClasses(image)
      
      -- purge classes
      for j=1, #classes do
        local fqclass = monoform_getfqclassname(classes[j].class, false)
        local s = smap[fqclass]
        if s ~= nil then
          structure_removeFromGlobalStructureList(s)
          classmap[fqclass] = classes[j].class
        end
        s = smap[fqclass..'[]']
        if s ~= nil then
          structure_removeFromGlobalStructureList(s)
          arraymap[fqclass..'[]'] = classes[j].class
        end
        -- check for static section
        fqclass = fqclass..'.Static'
        s = smap[fqclass]
        if s ~= nil then
          structure_removeFromGlobalStructureList(s)
          staticmap[fqclass] = classes[j].class
        end
      end
      
      -- if order function given, sort by it by passing the table and keys a, b, otherwise just sort the keys 
      local spairs = function(t, order)
          local keys = {}
          for k in pairs(t) do keys[#keys+1] = k end
          if order then
              table.sort(keys, function(a,b) return order(t, a, b) end)
          else
              table.sort(keys)
          end
          local i = 0
          return function() -- return the iterator function
              i = i + 1
              if keys[i] then
                  return keys[i], t[keys[i]]
              end
          end
      end
      local merge=function(...)
          local i,k,v
          local result={}
          i=1
          while true do
              local args = select(i,...)
              if args==nil then break end
              for k,v in pairs(args) do result[k]=v end
              i=i+1
          end
          return result
      end
      for fqclass, caddr in spairs(merge(classmap, arraymap, staticmap)) do
        s = createStructure(fqclass)
        structure_addToGlobalStructureList(s)
        smap[fqclass] = s
      end
    end
  end
  for fqclass, caddr in pairs(classmap) do
    print(translate("Reloading Structure ")..fqclass)
    monoform_exportStruct(caddr, fqclass, true, false, smap, false, true)
  end
  for fqclass, caddr in pairs(arraymap) do
    print(translate("Reloading Structure ")..fqclass)
    monoform_exportArrayStruct(nil, caddr, fqclass, true, false, smap, false, true)
  end
  for fqclass, caddr in pairs(staticmap) do
    print(translate("Reloading Structure ")..fqclass)
    monoform_exportStruct(caddr, fqclass, true, true, smap, false, true)
  end
end


function monoform_escapename(value)
  if value~=nil then
    return value:gsub("([^A-Za-z0-9%+%.,_$`<>%[%]])", "")
  end
  return nil
end

function monoform_getfqclassname(caddr, static)
  if (caddr==nil or caddr==0) then return nil end
  --local classname=mono_class_getName(caddr)
  --local namespace=mono_class_getNamespace(caddr)
  local classname=mono_class_getFullName(caddr)
  local namespace=nil
  local fqclass = monoform_escapename(classname)
  if fqclass==nil or string.len(fqclass) == 0 then
    return nil
  end
  if namespace~=nil and string.len(namespace) ~= 0 then
    fqclass = namespace.."."..fqclass
  end
  if static then
     fqclass = fqclass..".Static"
  end
  return fqclass
end

function monoform_exportStruct(caddr, typename, recursive, static, structmap, makeglobal, reload)
  local fqclass = monoform_getfqclassname(caddr, static)
  if typename==nil then
    typename = fqclass
  end
  if typename == nil then
    return nil
  end
  -- check if existing. exit early if already present
  local s = structmap[typename]
  if s == nil then
    -- print("Creating Structure "..typename)
    s = createStructure(typename)
    structmap[typename] = s  
    if makeglobal then 
      structure_addToGlobalStructureList(s)
    end
  else
    if not reload==true then 
      return s
    end
    -- TODO: cannot clear fields here but would like to
  end
  makeglobal = false
  return monoform_exportStructInternal(s, caddr, recursive, static, structmap, makeglobal)
end

mono_StringStruct=nil
  
function monoform_exportStructInternal(s, caddr, recursive, static, structmap, makeglobal)
  --print("a")
  if caddr==0 or caddr==nil then return nil end

 -- print("b")
  
  local className = mono_class_getFullName(caddr)
  --print('Populating '..className)
  
  -- handle Array as separate case

  if string.sub(className,-2)=='[]' then
    local elemtype = mono_class_getArrayElementClass(caddr)
    return monoform_exportArrayStructInternal(s, caddr, elemtype, recursive, structmap, makeglobal, true)
  end

  
  local hasStatic = false
  structure_beginUpdate(s)
  
  local fields=mono_class_enumFields(caddr)
  local str -- string struct
  local childstructs = {}
  local i
  for i=1, #fields do
    hasStatic = hasStatic or fields[i].isStatic

    if fields[i].isStatic==static and not fields[i].isConst then
      local e=s.addElement()
      local ft = fields[i].monotype
      local fieldname = monoform_escapename(fields[i].name)
      if fieldname~=nil then
        e.Name=fieldname
      end        
      e.Offset=fields[i].offset
      e.Vartype=monoTypeToVarType(ft)
            
      --print(string.format("  Field: %d: %d: %d: %s", e.Offset, e.Vartype, ft, fieldname))

      if ft==MONO_TYPE_STRING then
--print(string.format("  Field: %d: %d: %d: %s", e.Offset, e.Vartype, ft, fieldname))

         if mono_StringStruct==nil then
         --  print("Creating string object")

           mono_StringStruct = createStructure("String")
           
           mono_StringStruct.beginUpdate()
           local ce=mono_StringStruct.addElement()
           ce.Name="Length"
           if targetIs64Bit() then
             ce.Offset=0x10
	   else
             ce.Offset=0x8
	   end

           ce.Vartype=vtDword
           ce=mono_StringStruct.addElement()
           ce.Name="Value"
           if targetIs64Bit() then
             ce.Offset=0x14
           else
             ce.Offset=0xC 
           end
           ce.Vartype=vtUnicodeString
           ce.Bytesize=128
           mono_StringStruct.endUpdate()
           mono_StringStruct.addToGlobalStructureList()
         end
         e.setChildStruct(mono_StringStruct)
--[[
      elseif ft == MONO_TYPE_PTR or ft == MONO_TYPE_CLASS or ft == MONO_TYPE_BYREF 
          or ft == MONO_TYPE_GENERICINST then
        --print("bla")
        local typename = monoform_escapename(fields[i].typename)
        if typename ~= nil then
          local typeval = mono_type_getClass(fields[i].field)
          --print(string.format("PTR: %X: %s", typeval, typename))
          cs = monoform_exportStruct(typeval, typename, recursive, false, structmap, makeglobal)
          if cs~=nil then e.setChildStruct(cs) end
        end
      elseif ft == MONO_TYPE_SZARRAY then
        --print("bla2")
        local typename = monoform_escapename(fields[i].typename)
        local arraytype = mono_type_getClass(fields[i].field)
        local elemtype = mono_class_getArrayElementClass(arraytype)
	--print(typename)

        --local acs = monoform_exportArrayStruct(arraytype, elemtype, typename, recursive, static, structmap, makeglobal, false)
        --if acs~=nil then e.setChildStruct(acs) end --]]
      end
    
    end
  end

  structure_endUpdate(s)
  return s
end

function monoform_exportArrayStruct(arraytype, elemtype, typename, recursive, static, structmap, makeglobal, reload)
  local acs=nil
  if typename~=nil then
    acs = structmap[typename]
    if acs==nil and arraytype~=nil then
      acs = monoform_exportStruct(arraytype, typename, recursive, false, structmap, makeglobal)
      reload = true
    end
  end
  return monoform_exportArrayStructInternal(acs, arraytype, elemtype, recursive, structmap, makeglobal, reload)  
end

function monoform_exportArrayStructInternal(acs, arraytype, elemtype, recursive, structmap, makeglobal, reload)
  if acs~=nil then
    cs = monoform_exportStruct(elemtype, nil, recursive, false, structmap, makeglobal)
    if cs~=nil and reload then
      structure_beginUpdate(acs)
      local ce=acs.addElement()
      ce.Name='Count'
      ce.Offset=0xC
      ce.Vartype=vtDword
      ce.setChildStruct(cs)
      
      local j
      local psize
      if targetIs64Bit() then
        psize=8
      else
        psize=4
      end
 	
      for j=0, 9 do -- Arbitrarily add 10 elements
        ce=acs.addElement()
        ce.Name=string.format("Item[%d]",j)
        ce.Offset=j*psize+0x10
        ce.Vartype=vtPointer
        ce.setChildStruct(cs)
      end
      structure_endUpdate(acs)
    end
  end
  return acs
end

function monoAA_GETMONOSTRUCT(parameters, syntaxcheckonly)
  --called whenever an auto assembler script encounters the GETMONOSTRUCT() line

  --parameters: classname or classname,namespace:classname  (or classname,classname)

  --turns into a struct define

  local c,name,classname,namespace

  c=string.find(parameters,",")
  if c==nil then
    --just find this class
    name=parameters
    classname=parameters
    namespace=''
    --print("Format 1")
    --print("name="..name)
    --print("classname="..classname)
    --print("namespace="..namespace)

  else
    --this is a name,namespace:classname notation
    print("Format 2")

    name=string.sub(parameters, 1, c-1)
    parameters=string.sub(parameters, c+1, #parameters)


    c=string.find(parameters,":")
    if (c~=nil) then
      namespace=string.sub(parameters, 1,c-1)

      classname=string.sub(parameters, c+1, #parameters)
    else
      namespace='';
      classname=parameters
    end

    --print("name="..name)
    --print("classname="..classname)
    --print("namespace="..namespace)

  end

  name=name:match "^%s*(.-)%s*$"
  classname=classname:match "^%s*(.-)%s*$"
  namespace=namespace:match "^%s*(.-)%s*$"

  local class=mono_findClass(namespace, classname)
  if (class==nil) or (class==0) then
    return nil,translate("The class ")..namespace..":"..classname..translate(" could not be found")
  end

  local fields=mono_class_enumFields(class)
  if (fields==nil) or (#fields==0) then
    return nil,namespace..":"..classname..translate(" has no fields")
  end


  local offsets={}
  local i
  for i=1, #fields do
    if fields[i].offset~=0 then
      offsets[fields[i].offset]=fields[i].name
    end
  end

  local sortedindex={}
  for c in pairs(offsets) do
    table.insert(sortedindex, c)
  end
  table.sort(sortedindex)

  local result="struct "..name.."\n"
  local fieldsize

  if #sortedindex>0 then
    fieldsize=sortedindex[1]-0;

    result=result.."vtable: resb "..fieldsize
  end

  result=result.."\n"


  for i=1, #sortedindex do
    local offset=sortedindex[i]



    local name=offsets[offset]
    result=result..name..": "
    if sortedindex[i+1]~=nil then
      fieldsize=sortedindex[i+1]-offset
    else
      --print("last one")
      fieldsize=1 --last one
    end

    result=result.." resb "..fieldsize.."\n"

  end  

  result=result.."ends\n"

  --showMessage(result)

  return result
end

function monoAA_GETMONOSTATICDATA(assemblyname, namespace, classname, symbolprefix, enable)
  --parameters: assemblyname = partial name match of assembly
  --            namespace = namespace of class (empty string if no namespace)
  --            classname = name of class
  --            symbolprefix = name of symbol prefix (sanitized classname used if nil)

  -- returns AA script for locating static data location for given structure
  local SYMCLASSNAME
  if assemblyname==nil or namespace==nil or classname==nil then
    return ''
  end
  if symbolprefix~=nil then
    SYMCLASSNAME = symbolprefix:gsub("[^A-Za-z0-9._]", "")
  else
    SYMCLASSNAME = classname:gsub("[^A-Za-z0-9._]", "")
  end
  -- Populates ###.Static and ###.Class where ### the symbol prefix
  local script_tmpl
  if enable then
    script_tmpl = [===[
label($SYMCLASSNAME$.threadexit)
label(classname)
label(namespace)
label(assemblyname)
label(status)
label(domain)
label(assembly)
label($SYMCLASSNAME$.Static)
label($SYMCLASSNAME$.Class)
alloc($SYMCLASSNAME$.threadstart, 2048)

registersymbol($SYMCLASSNAME$.Static)
registersymbol($SYMCLASSNAME$.Class)

$SYMCLASSNAME$.threadstart:
mov [$SYMCLASSNAME$.Class],0
mov [$SYMCLASSNAME$.Static],0

call mono.mono_get_root_domain
cmp eax,0
je $SYMCLASSNAME$.threadexit
mov [domain],eax

push [domain]
call mono.mono_thread_attach
add esp,4

push status
push assemblyname
call mono.mono_assembly_load_with_partial_name
add esp,8
cmp eax,0
je $SYMCLASSNAME$.threadexit

push eax
call mono.mono_assembly_get_image
add esp,4
cmp eax,0
je $SYMCLASSNAME$.threadexit
mov [assembly], eax

push classname
push namespace
push eax
call mono.mono_class_from_name_case
add esp,C
cmp eax,0
je $SYMCLASSNAME$.threadexit
mov [$SYMCLASSNAME$.Class],eax

push eax
push [domain]
call mono.mono_class_vtable
add esp,8
cmp eax,0
je $SYMCLASSNAME$.threadexit

push eax
call mono.mono_vtable_get_static_field_data
add esp,4
mov [$SYMCLASSNAME$.Static],eax
jmp $SYMCLASSNAME$.threadexit
///////////////////////////////////////////////////////
// Data section
$SYMCLASSNAME$.Static:
dd 0
$SYMCLASSNAME$.Class:
dd 0
assemblyname:
db '$ASSEMBLYNAME$',0
namespace:
db '$NAMESPACE$',0
classname:
db '$CLASSNAME$',0
status:
dd 0
domain:
dd 0
assembly:
dd 0
$SYMCLASSNAME$.threadexit:
ret
createthread($SYMCLASSNAME$.threadstart)
]===]
  else
    script_tmpl = [===[
unregistersymbol($SYMCLASSNAME$.Static)
unregistersymbol($SYMCLASSNAME$.Class)
dealloc($SYMCLASSNAME$.threadstart)
]===]
  end
  return script_tmpl
         :gsub('($CLASSNAME$)', classname)
         :gsub('($SYMCLASSNAME$)', SYMCLASSNAME)
         :gsub('($NAMESPACE$)', namespace)
         :gsub('($ASSEMBLYNAME$)', assemblyname)
end

function monoAA_GETMONOSTATICFIELDDATA(assemblyname, namespace, classname, fieldname, symbolprefix, enable)
  --parameters: assemblyname = partial name match of assembly
  --            namespace = namespace of class (empty string if no namespace)
  --            classname = name of class
  --            fieldname = name of field
  --            symbolprefix = name of symbol prefix (sanitized classname used if nil)

  -- returns AA script for locating static data location for given structure
  local SYMCLASSNAME
  if assemblyname==nil or namespace==nil or classname==nil or fieldname==nil then
    return ''
  end
  if symbolprefix~=nil then
    SYMCLASSNAME = symbolprefix:gsub("[^A-Za-z0-9._]", "")
  else
    SYMCLASSNAME = classname:gsub("[^A-Za-z0-9._]", "")
  end
  local SYMFIELDNAME = fieldname:gsub("[^A-Za-z0-9._]", "")
  
  -- Populates ###.Static and ###.Class where ### the symbol prefix
  local script_tmpl
  if enable then
    script_tmpl = [===[
label(classname)
label(namespace)
label(assemblyname)
label(fieldname)
label(status)
label(domain)
label(assembly)
label(field)
label($SYMCLASSNAME$.$SYMFIELDNAME$)
label($SYMCLASSNAME$.$SYMFIELDNAME$.threadexit)
alloc($SYMCLASSNAME$.$SYMFIELDNAME$.threadstart, 2048)

registersymbol($SYMCLASSNAME$.$SYMFIELDNAME$)

$SYMCLASSNAME$.$SYMFIELDNAME$.threadstart:
mov [$SYMCLASSNAME$.$SYMFIELDNAME$],0

call mono.mono_get_root_domain
cmp eax,0
je $SYMCLASSNAME$.$SYMFIELDNAME$.threadexit
mov [domain],eax

push [domain]
call mono.mono_thread_attach
add esp,4

push status
push assemblyname
call mono.mono_assembly_load_with_partial_name
add esp,8
cmp eax,0
je $SYMCLASSNAME$.$SYMFIELDNAME$.threadexit

push eax
call mono.mono_assembly_get_image
add esp,4
cmp eax,0
je $SYMCLASSNAME$.$SYMFIELDNAME$.threadexit
mov [assembly], eax

push classname
push namespace
push eax
call mono.mono_class_from_name_case
add esp,C
cmp eax,0
je $SYMCLASSNAME$.$SYMFIELDNAME$.threadexit
push fieldname
push eax
call mono.mono_class_get_field_from_name
add esp,8
cmp eax,0
je $SYMCLASSNAME$.$SYMFIELDNAME$.threadexit
mov [field], eax
push eax
call mono.mono_field_get_parent
add esp,4
cmp eax,0
je $SYMCLASSNAME$.$SYMFIELDNAME$.threadexit
push eax
push [domain]
call mono.mono_class_vtable
add esp,8
cmp eax,0
je $SYMCLASSNAME$.$SYMFIELDNAME$.threadexit
push eax
call mono.mono_vtable_get_static_field_data
add esp,4
cmp eax,0
je $SYMCLASSNAME$.$SYMFIELDNAME$.threadexit
push eax // save data on stack
push [field]
call mono.mono_field_get_offset
add esp,4
pop ebx // restore data
add eax,ebx
mov [$SYMCLASSNAME$.$SYMFIELDNAME$],eax
jmp $SYMCLASSNAME$.$SYMFIELDNAME$.threadexit
///////////////////////////////////////////////////////
// Data section
$SYMCLASSNAME$.$SYMFIELDNAME$:
dd 0
assemblyname:
db '$ASSEMBLYNAME$',0
namespace:
db '$NAMESPACE$',0
classname:
db '$CLASSNAME$',0
fieldname:
db '$FIELDNAME$',0
status:
dd 0
domain:
dd 0
assembly:
dd 0
field:
dd 0
$SYMCLASSNAME$.$SYMFIELDNAME$.threadexit:
ret
createthread($SYMCLASSNAME$.$SYMFIELDNAME$.threadstart)
]===]
  else
    script_tmpl = [===[
unregistersymbol($SYMCLASSNAME$.$SYMFIELDNAME$)
dealloc($SYMCLASSNAME$.$SYMFIELDNAME$.threadstart)
]===]
  end
  return script_tmpl
         :gsub('($CLASSNAME$)', classname)
         :gsub('($SYMCLASSNAME$)', SYMCLASSNAME)
         :gsub('($FIELDNAME$)', fieldname)
         :gsub('($SYMFIELDNAME$)', SYMFIELDNAME)
         :gsub('($NAMESPACE$)', namespace)
         :gsub('($ASSEMBLYNAME$)', assemblyname)
end

function mono_initialize()
  --register a function to be called when a process is opened
  if (mono_init1==nil) then
    mono_init1=true
    mono_oldOnOpenProcess=onOpenProcess
    onOpenProcess=mono_OpenProcess

    registerAutoAssemblerCommand("USEMONO", monoAA_USEMONO)
    registerAutoAssemblerCommand("FINDMONOMETHOD", monoAA_FINDMONOMETHOD)
    registerAutoAssemblerCommand("GETMONOSTRUCT", monoAA_GETMONOSTRUCT)

    registerEXETrainerFeature('Mono', function()
      local r={}
      r[1]={}
      r[1].PathToFile=getCheatEngineDir()..[[autorun\monoscript.lua]]
      r[1].RelativePath=[[autorun\]];

      r[2]={}
      r[2].PathToFile=getCheatEngineDir()..[[autorun\forms\MonoDataCollector.frm]]
      r[2].RelativePath=[[autorun\forms\]];

      r[3]={}
      r[3].PathToFile=getCheatEngineDir()..[[autorun\dlls\MonoDataCollector32.dll]]
      r[3].RelativePath=[[autorun\dlls\]];

      r[4]={}
      r[4].PathToFile=getCheatEngineDir()..[[autorun\dlls\MonoDataCollector64.dll]]
      r[4].RelativePath=[[autorun\dlls\]];

      return r
    end)


  end
end


mono_initialize()



