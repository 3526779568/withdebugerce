unit StructuresFrm2;


{$mode delphi}

interface

uses
  windows, win32proc, Classes, LCLProc, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls, math,
  StdCtrls, ComCtrls, Menus, lmessages, scrolltreeview, byteinterpreter, symbolhandler, cefuncproc,
  newkernelhandler, frmSelectionlistunit, frmStructuresConfigUnit, registry, Valuechange, DOM,
  XMLRead, XMLWrite, Clipbrd, CustomTypeHandler, strutils, dotnetpipe, DotNetTypes, commonTypeDefs,
  contnrs;


const structureversion=2;

  { TfrmStructures2 }
type
  TdisplayMethod=(dtUnsignedInteger, dtSignedInteger, dtHexadecimal );
  TStructOperation=(soAdd, soDelete, soSort);

  TDissectedStruct=class;
  TStructureDissectOverride=function(structure: TObject; address: ptruint): boolean of object;
  TStructureNameLookup=function(var address: ptruint; var name: string): boolean of object;

  TStructelement=class
  private
    fparent: TDissectedStruct;
    foffset: integer;
    fbytesize: integer;
    fname: string;
    fvartype: TVariableType;
    fbackgroundcolor: TColor;
    fCustomType: TCustomtype;
    fdisplayMethod: TdisplayMethod;
    fchildstruct: TDissectedStruct;
    fchildstructstart: integer; //offset into the childstruct where this pointer starts. Always 0 for local structs, can be higher than 0 for other defined structs
    fExpandChangesAddress: boolean;
  public
    delayLoadedStructname: string;
    constructor createFromXMLElement(parent:TDissectedStruct; element: TDOMElement);
    constructor create(parent:TDissectedStruct);
    destructor destroy; override;
    function getParent: TDissectedStruct;
    function getOffset: integer;
    procedure setOffset(newOffset: integer);
    function getName: string;
    procedure setName(newname: string);
    function getVartype: TVariableType;
    procedure setVartype(newVartype: TVariableType);
    function getCustomType: TCustomType;
    procedure setCustomType(newCustomtype: TcustomType);
    function getDisplayMethod: TdisplayMethod;
    procedure setDisplayMethod(newDisplayMethod: TdisplayMethod);
    function getBytesize: integer;
    procedure setBytesize(newByteSize: integer);
    function getBackgroundColor: integer;
    procedure setBackgroundColor(c: TColor);
    function getValue(address: ptruint; hashexprefix: boolean=false; showAsHexOverride: boolean=false): string;
    procedure setvalue(address: ptruint; value: string);
    function getValueFromBase(baseaddress: ptruint): string;
    procedure setValueFromBase(baseaddress: ptruint; value: string);
    function isPointer: boolean;
    function getChildStruct: TDissectedStruct;
    procedure setChildStruct(newChildStruct: TDissectedStruct);
    procedure setChildStructStart(offset: integer);

    function getIndex: integer;

    procedure AutoCreateChildStruct(name: string; address: ptruint);

    procedure WriteToXMLNode(elementnodes: TDOMNode);

  published
    property Name: string read getName write setName; //stored as utf8
    property VarType: TVariableType read getVarType write setVarType;
    property CustomType: TCustomType read getCustomType write setCustomType;
    property Offset: integer read getOffset write setOffset;
    property DisplayMethod: TdisplayMethod read getDisplayMethod write setDisplayMethod;
    property Bytesize: integer read getByteSize write setByteSize;
    property BackgroundColor: TColor read getBackgroundColor write setBackgroundColor;
    property ChildStruct: TDissectedStruct read getChildStruct write setChildStruct;
    property ChildStructStart: integer read fchildstructstart write setChildStructStart;
    property index: integer read getIndex;
    property parent: TDissectedStruct read getParent;
    property ExpandChangesAddress: boolean read fExpandChangesAddress write fExpandChangesAddress;
  end;



  TDissectedStruct=class
  private
    structname: string;
    structelementlist: tlist;

    fAutoCreate: boolean;
    fAutoCreateStructsize: integer;
    fDoNotSaveLocal: boolean;
    fAutoDestroy: boolean;
    fAutoFill: boolean;
    fDefaultHex: boolean;
    fRLECompression: boolean;


    fUpdateCounter: integer;
    fullstructupdate: boolean;

    updatecalledSort: boolean;
    updateChangedInformation: boolean;
    updatedelements: Tlist;



    function isUpdating: boolean;
    function getStructureSize: integer;
    procedure DoOptionsChangedNotification;
    procedure DoFullStructChangeNotification;
    procedure DoDeleteStructNotification;
    procedure setupDefaultSettings;

    procedure setDoNotSaveLocal(state: boolean);
    procedure setAutoCreateStructsize(size: integer);
    procedure setAutoCreate(state: boolean);
    procedure setAutoDestroy(state: boolean);
    procedure setAutoFill(state: boolean);
    procedure setDefaultHex(state: boolean);
    procedure setRLECompression(state: boolean);
  public
    constructor create(name: string);
    constructor createFromXMLNode(structure: TDOMNode);
    constructor createFromOutdatedXMLNode(structure: TDOMNode);

    procedure WriteToXMLNode(node: TDOMNode);

    destructor destroy; override;




    function getName: string;
    procedure setName(newname: string);
    function getElementCount: integer;
    function getElement(index: integer): TStructelement;
    procedure fillDelayLoadedChildstructs;

    procedure beginUpdate;
    procedure endUpdate;
    procedure DoElementChangeNotification(element: TStructelement);

    procedure OnDeleteStructNotification(structtodelete: TDissectedStruct; path: TList);

    procedure sortElements;
    function addElement(name: string=''; offset: integer=0; vartype: TVariableType=vtByte; customtype:TCustomtype=nil; bytesize: integer=0; childstruct: TDissectedStruct=nil): TStructelement;
    procedure removeElement(element: TStructelement);
    procedure delete(index: integer);
    procedure fillFromDotNetAddressData(const data: TAddressData);
    procedure autoGuessStruct(baseaddress: ptruint; offset: integer; bytesize: integer);
    procedure fillGaps(structbase: ptruint; askiftoobig: boolean);
    procedure addToGlobalStructList;
    procedure removeFromGlobalStructList;
    function isInGlobalStructList: boolean;
    function getIndexOf(element: TStructElement): integer;
    function getIndexOfOffset(offset: dword): integer;
    property structuresize : integer read getStructureSize;
    property name: string read getName write setName;

    //these properties are just for the gui
    property DoNotSaveLocal: boolean read fDoNotSaveLocal write setDoNotSaveLocal;
    property AutoCreateStructsize: integer read fAutoCreateStructsize write setAutoCreateStructsize;
    property AutoCreate: boolean read fAutoCreate write setAutoCreate;
    property AutoDestroy: boolean read fAutoDestroy write setAutoDestroy;
    property AutoFill: boolean read fAutoFill write setAutoFill;
    property count: integer read getElementCount;
    property element[Index: Integer]: TStructelement read getElement; default;
    property RLECompression: boolean read fRLECompression write setRLECompression;
  published
    property DefaultHex: boolean read fDefaultHex write setDefaultHex;
  end;

  PDissectedStruct=^TDissectedStruct;

  //TDissectedStructs=TFPGList<TDissectedStruct>;

  TfrmStructures2=class;
  TStructColumn=class;

  TStructGroup=class //Will handle the group compares for each group
  private
    parent: TfrmStructures2;
    fcolumns: TList;
    fgroupname: string;
    fMatches: boolean;
    fcurrentString: string;
    isempty: boolean;

    GroupBox: TGroupbox;
    refcount: integer;
    grouppopup: TPopupMenu;
    miRename: TMenuItem;
    miDelete: TMenuItem;

    function getColumnCount: integer;
    function getColumn(i: integer): TStructColumn;
    procedure RenameClick(sender: tobject);
    procedure DeleteClick(sender: Tobject);
    procedure setGroupName(newname: string);
    procedure groupboxresize(sender: TObject);
  public
    function getParent: TfrmStructures2;
    function AColumnHasSetCaption: boolean;
    procedure setPositions;
    constructor create(parent: TfrmStructures2; GroupName: string);
    destructor destroy; override;

    procedure clear; //sets matches to true
    property Matches: boolean read fMatches;
    procedure addString(s:string); //sets matches to false if it doesn't match the previous string (also sets currentStrign to '' on false)

  published
    property currentString: string read fCurrentString;
    property groupname: string read fGroupName write setGroupName;
    property name: string read fGroupName write setGroupName;
    property box: TGroupbox read GroupBox;
    property columnCount: integer read getColumnCount;
    property columns[index: integer]: TStructColumn read Getcolumn;
  end;


  TStructColumn=class
  private
    parent: TStructGroup;

    faddress: ptruint;
    fsavedstate: pointer; //points to a copy made in the target process
    fsavedstatesize: integer;
    fFocused: boolean;
    edtAddress: TEdit;
    columneditpopupmenu: TPopupMenu;

    miToggleLock: TMenuItem;
    miChangeGroup: TMenuItem;
    miDelete: TMenuItem;
    miCut: TMenuItem;
    miCopy: TMenuItem;
    miPaste: TMenuItem;
    miSpider: TMenuItem;
    miSetCaption: TMenuItem;


    focusedShape: TShape;
    lblName: TLabel;


    fcompareValue: string;

    backlist: Tstack;

    procedure ChangeGroupClick(sender: tobject);
    procedure DeleteClick(sender: TObject);
    procedure ToggleLockClick(sender: TObject);

    procedure CutClick(sender: TObject);
    procedure CopyClick(sender: TObject);
    procedure PasteClick(sender: TObject);
    procedure SpiderClick(sender: TObject);
    procedure SetCaptionClick(sender: TObject);

    procedure MenuPopup(sender: TObject);


    procedure edtAddressChange(sender: TObject);
    function getAddress: ptruint;
    procedure setAddress(address: ptruint);
    function getAddressText: string;
    procedure setAddressText(address: string);

    procedure setFocused(state: boolean);
    function getFocused: boolean;
    function getGlobalIndex: integer;
    procedure setNewParent(group: TStructGroup);

    function getName: string;

    procedure setAnchorsForPos(i: integer);
  public
    currentNodeAddress: string;    //temporary storage for rendering
    currentNodeValue: string;
    currentNodeColor: Tcolor;

    constructor create(parent: TStructGroup);
    destructor destroy; override;


    procedure focus;
    procedure edtAddressEnter(sender: tobject);
    procedure edtaddressMousedown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    procedure clearSavedState;
    function saveState: boolean;
    function getSavedState: pointer;
    function getSavedStateSize: integer;
    function LockAddress(shownaddress: ptruint; memoryblock: pointer; size: integer): boolean; //call this when you wish to set a specific lock state based on locally saved data


    function getEditWidth: integer;
    function getEditLeft: integer;
    function isXInColumn(x: integer): boolean;
    procedure SetProperEditboxPosition;

    procedure pushAddress;
    procedure popAddress;
    function canPopAddress: boolean;
  published
    property EditWidth: integer read getEditwidth;
    property EditLeft: integer read getEditleft;
    property Address: ptruint read getAddress write setAddress;
    property Focused: boolean read getFocused write setFocused;
    property CompareValue: string read fcompareValue write fcompareValue;
    property GlobalIndex: integer read getGlobalIndex;
    property AddressText: string read getAddressText write setAddressText;
    property Name: string read getName;
  end;

  TfrmStructures2 = class(TForm)
    FindDialog1: TFindDialog;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    miBack: TMenuItem;
    N5: TMenuItem;
    miExpandAll: TMenuItem;
    miExpandAllDefined: TMenuItem;
    miClear: TMenuItem;
    miCopy: TMenuItem;
    miPaste: TMenuItem;
    N4: TMenuItem;
    miExportAll: TMenuItem;
    miEverythingHex: TMenuItem;
    miGenerateGroupscan: TMenuItem;
    miDefaultHexadecimal: TMenuItem;
    miRLECompression: TMenuItem;
    miFindRelations: TMenuItem;
    miShowTypeForEntriesWithNoDescription: TMenuItem;
    miAutoDestroyLocal: TMenuItem;
    miAutoFillGaps: TMenuItem;
    miFillGaps: TMenuItem;
    miChangeValue: TMenuItem;
    miShowAddresses: TMenuItem;
    miDoNotSaveLocal: TMenuItem;
    miFullUpgrade: TMenuItem;
    miAddChildElement: TMenuItem;
    miAddElement: TMenuItem;
    Addextraaddress1: TMenuItem;
    miAddToAddresslist: TMenuItem;
    miAutoGuess: TMenuItem;
    miChangeElement: TMenuItem;
    miCommands: TMenuItem;
    Definenewstructure1: TMenuItem;
    Deletecurrentstructure1: TMenuItem;
    miDeleteElement: TMenuItem;
    File1: TMenuItem;
    HeaderControl1: THeaderControl;
    MainMenu1: TMainMenu;
    miBrowsePointer: TMenuItem;
    miBrowseAddress: TMenuItem;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    miAutoCreate: TMenuItem;
    miAutostructsize: TMenuItem;
    miChangeColors: TMenuItem;
    miUpdateInterval: TMenuItem;
    miUpdateOffsets: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    miNewWindow: TMenuItem;
    Open1: TMenuItem;
    OpenDialog1: TOpenDialog;
    pmStructureView: TPopupMenu;
    miRecalculateAddress: TMenuItem;
    Renamestructure1: TMenuItem;
    Save1: TMenuItem;
    SaveDialog1: TSaveDialog;
    saveValues: TSaveDialog;
    pnlGroups: TScrollBox;
    Structures1: TMenuItem;
    tmFixGui: TTimer;
    updatetimer: TTimer;
    tvStructureView: TTreeView;
    procedure Addextraaddress1Click(Sender: TObject);
    procedure FindDialog1Find(Sender: TObject);
    procedure HeaderControl1SectionResize(HeaderControl: TCustomHeaderControl;
      Section: THeaderSection);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure miBackClick(Sender: TObject);
    procedure miExpandAllClick(Sender: TObject);
    procedure miExpandAllDefinedClick(Sender: TObject);
    procedure miClearClick(Sender: TObject);
    procedure miCopyClick(Sender: TObject);
    procedure miExportAllClick(Sender: TObject);
    procedure miGenerateGroupscanClick(Sender: TObject);
    procedure miAutoCreateClick(Sender: TObject);
    procedure miAutoDestroyLocalClick(Sender: TObject);
    procedure miAutoFillGapsClick(Sender: TObject);
    procedure miChangeValueClick(Sender: TObject);
    procedure miBrowseAddressClick(Sender: TObject);
    procedure miBrowsePointerClick(Sender: TObject);
    procedure miAddToAddresslistClick(Sender: TObject);
    procedure Deletecurrentstructure1Click(Sender: TObject);
    procedure miAutoGuessClick(Sender: TObject);
    procedure miAutostructsizeClick(Sender: TObject);
    procedure miChangeColorsClick(Sender: TObject);
    procedure miDefaultHexadecimalClick(Sender: TObject);
    procedure miRLECompressionClick(Sender: TObject);
    procedure miDoNotSaveLocalClick(Sender: TObject);
    procedure miFillGapsClick(Sender: TObject);
    procedure miFindRelationsClick(Sender: TObject);
    procedure miFullUpgradeClick(Sender: TObject);
    procedure miChangeElementClick(Sender: TObject);
    procedure Definenewstructure1Click(Sender: TObject);
    procedure miDeleteElementClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure HeaderControl1SectionTrack(HeaderControl: TCustomHeaderControl;
      Section: THeaderSection; Width: Integer; State: TSectionTrackState);
    procedure miAddChildElementClick(Sender: TObject);
    procedure miAddElementClick(Sender: TObject);
    procedure miPasteClick(Sender: TObject);
    procedure miShowAddressesClick(Sender: TObject);
    procedure miUpdateOffsetsClick(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure pmStructureViewPopup(Sender: TObject);
    procedure miNewWindowClick(Sender: TObject);
    procedure miUpdateIntervalClick(Sender: TObject);
    procedure pnlGroupsClick(Sender: TObject);
    procedure miRecalculateAddressClick(Sender: TObject);
    procedure pnlGroupsResize(Sender: TObject);
    procedure Renamestructure1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure tmFixGuiTimer(Sender: TObject);
    procedure tvStructureViewAdvancedCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
      var PaintImages, DefaultDraw: Boolean);
    procedure tvStructureViewDblClick(Sender: TObject);
    procedure tvStructureViewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure updatetimerTimer(Sender: TObject);
    procedure tvStructureViewCollapsed(Sender: TObject; Node: TTreeNode);
    procedure tvStructureViewCollapsing(Sender: TObject; Node: TTreeNode;
      var AllowCollapse: Boolean);
    procedure tvStructureViewExpanded(Sender: TObject; Node: TTreeNode);
    procedure tvStructureViewExpanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
  private
    { private declarations }
    fmainStruct: TDissectedStruct;
    fgroups: Tlist;


    fDefaultColor: TColor;
    fNoMatchColor: TColor; //The color to use when not all elements have the same color
    fMatchColor: tcolor; //The color to use when all elements in the group match
    fAllMatchColorSame: TColor; //The color to use when all groups have matching elements AND the same value
    fAllMatchColorDiff: TColor; //The color to use when all groups have matching alements but different values between groups

    fDefaultColorHighlighted: TColor;
    fNoMatchColorHighlighted: TColor; //The color to use when not all elements have the same color
    fMatchColorHighlighted: tcolor; //The color to use when all elements in the group match
    fAllMatchColorSameHighlighted: TColor; //The color to use when all groups have matching elements AND the same value
    fAllMatchColorDiffHighlighted: TColor; //The color to use when all groups have matching alements but different values between groups

    procedure UpdateCurrentStructOptions;
    procedure setupColors;

    procedure miSelectStructureClick(Sender: tobject);
    function getHorizontalScrollbarString: String; //returns a string out of spaces that fills up the length of all the columns combined
    procedure SetupFirstNodeLength;
    procedure InitializeFirstNode;
    procedure RefreshStructureList;
    procedure TreeViewHScroll(sender: TObject; scrolledleft, maxscrolledleft: integer);
    procedure TreeViewVScroll(sender: TObject);

    procedure removeColumn(columnid: integer);
    procedure FillTreenodeWithStructData(currentnode: TTreenode);
    function getDisplayedDescription(se: TStructelement): string;
    procedure setupNodeWithElement(node: TTreenode; element: TStructElement);
    procedure setCurrentNodeStringsInColumns(node: TTreenode; element: TStructElement; highlighted: boolean=false);  //sets the value for the current node into the columns
    
    procedure setMainStruct(struct: TDissectedStruct);
    function getColumn(i: integer): TStructColumn;
    function getColumnCount: integer;

    function getGroup(i: integer): TStructGroup;
    function getGroupCount: integer;

    procedure getValues(f: Tstrings); //fills a strings object with all the values
    function searchString(search: string; findoptions: TFindOptions): integer;

    procedure EditValueOfSelectedNodes(c:TStructColumn);
    procedure expandtree(all: boolean);
  public
    { public declarations }
    initialaddress: PtrUInt;
    lastresizecheck: dword;

    function DefineNewStructure(recommendedSize: integer=4096): TDissectedStruct;
    procedure addLockedAddress(shownaddress: ptruint; memoryblock: pointer; size: integer); //call this to add a locked address, and copy the memoryblock to the target process)
    procedure RefreshVisibleNodes;

    function addColumn: TStructColumn;
    function getFocusedColumn: TStructColumn;
    function getColumnAtXPos(x: integer): TStructColumn;
    procedure changeNodes;
    procedure addFromNode(n: TTreenode; asChild: boolean=false);
    function getStructElementFromNode(node: TTreenode): TStructelement;
    function getStructFromNode(node: TTreenode): TDissectedStruct;
    function getChildStructFromNode(node: TTreenode): TDissectedStruct;
    function getMainStruct: TDissectedStruct;

    procedure getPointerFromNode(node: TTreenode; column:TStructcolumn; var baseaddress: ptruint; var offsetlist: toffsetlist);
    function getAddressFromNode(node: TTreenode; column: TStructColumn; var hasError: boolean): ptruint;

    procedure onAddedToStructList(sender: TDissectedStruct);
    procedure onRemovedFromStructList(sender: TDissectedStruct);
    procedure onFullStructChange(sender: TDissectedStruct);   //called when a structure is changed (sort/add/remove entry)
    procedure onStructOptionsChange(sender: TDissectedStruct);
    procedure onElementChange(struct:TDissectedStruct; element: TStructelement); //called when an element of a structure is changed
    procedure onStructureDelete(sender: TDissectedStruct);

    procedure FixPositions;
  published
    property DefaultColor: TColor read fDefaultColor;
    property MatchColor: TColor read fMatchColor;
    property NoMatchColor: Tcolor read fNoMatchcolor;
    property AllMatchColorSame: TColor read fAllMatchColorSame;
    property AllMatchColorDiff: TColor read fAllMatchColorDiff;

    property mainStruct : TDissectedStruct read fmainStruct write setMainStruct;
    property columnCount: integer read getColumnCount;
    property columns[index: integer]: TStructColumn read Getcolumn;
    property groupcount: integer read getGroupCount;
    property group[index: integer]: TStructGroup read getGroup;
  end;

var
  frmStructures2: TList;
  DissectedStructs: TList;


function registerStructureDissectOverride(m: TStructureDissectOverride): integer;
procedure unregisterStructureDissectOverride(id: integer);
function lookupStructureName(address: ptruint; defaultName: string) : string;

function registerStructureNameLookup(m: TStructureNameLookup): integer;
procedure unregisterStructureNameLookup(id: integer);

implementation

{$R *.lfm}

uses MainUnit, mainunit2, frmStructures2ElementInfoUnit, MemoryBrowserFormUnit,
  frmStructureLinkerUnit, frmgroupscanalgoritmgeneratorunit, frmStringPointerScanUnit,
  ProcessHandlerUnit, Parsers, LuaCaller;

resourcestring
  rsAddressValue = 'Address: Value';
  rsUndefined = 'undefined';

  rsThisIsQuiteABigStructureHowManyBytesDoYouWantToSav = 'This is quite a big '
     +'structure. How many bytes do you want to save?';
   rsStructureViewLock = 'Structure view lock';
   rsPointerTo = 'Pointer';
   rsUnnamedStructure = 'unnamed structure';
   rsStructureDefine = 'Structure define';
   rsStructAlreadyExists = 'The structure named %s already exists. Are you sure you want to make another structure with this name ?';
   rsGiveTheNameForThisStructure = 'Give the name for this structure';
   rsDoYouWantCheatEngineToTryAndFillInTheMostBasicType = 'Do you want Cheat '
     +'Engine to try and fill in the most basic types of the struct using the '
     +'current address?';
   rsPleaseGiveAStartingSizeOfTheStructYouCanChangeThis = 'Please give a '
     +'starting size of the struct (You can change this later if needed)';

   rsMemoryDissect = 'Memory dissect';
   rsFirstSelectAStructureYouWantToModifyOrDefine = 'First select a structure '
     +'you want to modify or define one first';
   rsUpdateInterval = 'Update interval';
   rsNewInterval = 'New interval';
   rsDissectData = 'Dissect Data';
   rsHowManyBytesDoYouWantToShiftThisAndFollowingOffset = 'How many bytes do '
     +'you want to shift this and following offsets? (Decimal)';
   rsAreYouSureYouWantToDelete = 'Are you sure you want to delete %s?';
   rsThisIsNotAValidStructureFile = 'This is not a valid structure file';
   rsWrongVersion = 'This structure file was generated with a newer version of '
     +'DDY Engine. (That means there''s more than likely a new version so '
     +'please update....)';
   rsUnkownFileExtension = 'Unknown file extension';
   rsAreYouSureYouWantToRemoveAllStructures = 'Are you sure you want to remove '
     +'all structures?';
   rsRecalculateBaseOfStructure = 'Recalculate base of structure';
   rsGiveTheAddressOfThisElement = 'Give the address of this element';
   rsIHaveNoIdeaWhatMeans = 'I have no idea what %s means';
   rsChangeGroup = 'Change group';
   rsLockMemory = 'Lock memory';
   rsUnlockMemory = 'Unlock memory';
   rsRenameStructure = 'Rename structure';
   rsGiveTheNewNameOfThisStructure = 'Give the new name of this structure';
   rsPleaseGiveAStartingOffsetToEvaluate = 'Please give a starting offset to '
     +'evaluate';
   rsPleaseGiveTheSizeOfTheBlockToEvaluate = 'Please give the size of the '
     +'block to evaluate';
   rsStructureDefiner = 'Structure definer';
   rsWhichGroupDoYouWantToSetThisAddressTo = 'Which group do you want to set '
     +'this address to?';
   rsAutogeneratedFor = 'Autogenerated for %s';
   rsStructureDissect = 'Structure dissect';
   rsLock = 'Lock';
   rsChangeGroup2 = 'Change Group';
   rsDeleteAddress = 'Delete address';

   rsCut = 'Cut';
   rsCopy = 'Copy';
   rsPaste = 'Paste';
   rsSpider = 'Spider';
   rsSF2GiveTheNewNameForThisStructure = 'Give the new name for this structure';
   rsSF2StructureRename = 'Structure rename';
   rsSF2AreYouSureYouWantToDeleteTheStructureNamed = 'Are you sure you want to delete the structure named :';
   rsSF2AreYouSureYouWantToDeleteAllTheDefinedStructures = 'Are you sure you want to delete all the defined structures ?';
   rsSF2AutocreateStructureSize = 'Autocreate structure size: ';
   rsSF2ChangeValue = 'Change Value';
   rsSF2NewValueForThisAddress = 'New value for this address:';
   rsSF2Group1 = 'Group 1';
   rsSF2Group = 'Group ';
   rsSF2Group2 = 'Group ';
   rsSF2Rename = 'Rename';
   rsSF2DeleteGroup = 'Delete group';
  rsSF2TheGapBetweenOffset = 'The gap between offset %x and %x is %d bytes long. Autofill this?';
  rsSF2NewGroup = '<New group>';
  rsSF2GroupPicker = 'Group picker';
  rsSF2SecletTheGroupThisColumnShouldBecomePartOf = 'Select the group this column should become part of';
  rsSF2NewGroup2 = 'New group';
  rsSF2GiveTheNewName = 'Give the new name';
  rsSF2ShadowcopyAt = 'Lock ( Shadowcopy at %s )';
  rsSF2NewColumnName = 'New column name';
  rsSF2WhatNameShouldThisColumnHave = 'What name should this column have?';
  rsSF2TStructColumnCreateError = 'TStructColumn.create Error';
  rsSF2SetNameRename = 'Set name/Rename';
  rsSF2RenameGroup = 'Rename group';
  rsSF2GiveTheNewNameForTheGroup = 'Give the new name for the group';
  rsSF2AutocreatedFrom = 'Autocreated from ';
  rsSF2NameForThisGroup = 'Name for this group';
  rsFS2StructureDefine = 'Structure define';
  rsSF2TheGroupscanCommandHasBeenCopiedToTheClipboard = 'The groupscan command has been copied to the clipboard';
  rsSF2AutocreateStructure = 'Autocreate structure';
  rsSF2DefaultSize = 'Default size:';
  rsSF2UnknownCustomType = 'Unknown custom type';
  rsSF2Hex = ' (Hex)';
  rsSF2Signed = ' (Signed)';
  rsSF2To = ' to ';
  rsP = 'P->';
  rsUnsignedInteger = 'Unsigned Integer';
  rsSignedInteger = 'Signed Integer';
  rsHexadecimal = 'Hexadecimal';
  rsDefinePointer = 'Define pointer';
  rsUpgradePointer = 'Upgrade child structure to full structure';

var
  StructureDissectOverrides: array of TStructureDissectOverride;
  StructureNameLookups: array of TStructureNameLookup;

function registerStructureNameLookup(m: TStructureNameLookup): integer;
var i: integer;
begin
  for i:=0 to length(StructureNameLookups)-1 do
  begin
    if assigned(StructureNameLookups[i])=false then
    begin
      StructureNameLookups[i]:=m;
      result:=i;
      exit;
    end
  end;

  result:=length(StructureNameLookups);
  setlength(StructureNameLookups, result+1);
  StructureNameLookups[result]:=m;
end;

procedure unregisterStructureNameLookup(id: integer);
begin
  if id<length(StructureNameLookups) then
  begin
    CleanupLuaCall(TMethod(StructureNameLookups[id]));
    StructureNameLookups[id]:=nil;
  end;
end;

function registerStructureDissectOverride(m: TStructureDissectOverride): integer;
var i: integer;
begin
  for i:=0 to length(StructureDissectOverrides)-1 do
  begin
    if assigned(StructureDissectOverrides[i])=false then
    begin
      StructureDissectOverrides[i]:=m;
      result:=i;
      exit;
    end
  end;

  result:=length(StructureDissectOverrides);
  setlength(StructureDissectOverrides, result+1);
  StructureDissectOverrides[result]:=m;
end;

procedure unregisterStructureDissectOverride(id: integer);
begin
  if id<length(StructureDissectOverrides) then
  begin
    CleanupLuaCall(TMethod(StructureDissectOverrides[id]));
    StructureDissectOverrides[id]:=nil;
  end;
end;

function lookupStructureName(address: ptruint; defaultName: string) : string;
var
  structName: string;
  i: integer;
  found: boolean;
begin
  found:=false;
  for i:=0 to length(StructureNameLookups)-1 do
  begin
    if assigned(StructureNameLookups[i]) then
    begin
      found := StructureNameLookups[i](address, structname);
      if found then break;
    end;
  end;
  if not found then structname:=defaultName;
  result := structname;
end;

function DisplaymethodToString(d:TdisplayMethod): string;
begin
  case d of
    dtUnsignedInteger: result:=rsUnsignedInteger;
    dtSignedInteger: result:=rsSignedInteger;
    dtHexadecimal: result:=rsHexadecimal;
  end;
end;

function StringToDisplayMethod(s: string): TdisplayMethod;
begin
  s:=LowerCase(s);
  result:=dtUnsignedInteger;

  if s='unsigned integer' then result:=dtUnsignedInteger else
  if s='signed integer' then result:=dtSignedInteger else
  if s='hexadecimal' then result:=dtHexadecimal;
end;

{Struct}

procedure TStructelement.WriteToXMLNode(elementnodes: TDOMNode);
var
  doc: TDOMDocument;
  elementnode: TDOMElement;
begin
  doc:=elementnodes.OwnerDocument;
  elementnode:=TDOMElement(elementnodes.AppendChild(doc.CreateElement('Element')));

  elementnode.SetAttribute('Offset', IntToStr(self.Offset));
  if self.Name<>'' then
    elementnode.SetAttribute('Description', utf8toansi(self.Name));

  if ExpandChangesAddress then
    elementnode.SetAttribute('ExpandChangesAddress', '1');

  elementnode.SetAttribute('Vartype', VariableTypeToString(self.VarType));
  if self.CustomType<>nil then
    elementnode.SetAttribute('Customtype', self.CustomType.name);

  elementnode.SetAttribute('Bytesize', IntToStr(self.Bytesize));
  elementnode.SetAttribute('DisplayMethod', DisplaymethodToString(self.DisplayMethod));

  if self.ChildStructStart<>0 then
    elementnode.SetAttribute('ChildStructStart', IntToStr(self.ChildStructStart));

  if backgroundcolor<>clWindow then
    elementnode.SetAttribute('BackgroundColor', IntToHex(backgroundcolor, 6));


  if (self.isPointer) and (self.ChildStruct<>nil) then
  begin
    if (self.ChildStruct.isInGlobalStructList) then
    begin
      //set childstruct as an attribute
      elementnode.SetAttribute('ChildStruct', utf8toansi(self.ChildStruct.Name));
    end
    else
    begin
      //local struct, only save if allowed
      if (parent<>nil) and (parent.doNotSaveLocal=false) then  //save this whole struct
      begin
        ChildStruct.fRLECompression:=parent.fRLECompression;
        ChildStruct.WriteToXMLNode(elementnode);
      end;
    end;
  end;

end;

function TStructelement.getParent: TDissectedStruct;
begin
  result:=fParent;
end;

function TStructelement.getOffset: integer;
begin
  result:=fOffset;
end;

procedure TStructelement.setOffset(newOffset: integer);
begin
  if newOffset<>fOffset then
  begin
    fOffset:=newOffset;
    parent.sortElements;
  end;
end;

function TStructelement.getName: string;
begin
  result:=fname;
end;

procedure TStructelement.setName(newname: string);
begin
  if newname<>fname then
  begin
    fname:=newname;
    parent.DoElementChangeNotification(Self);
  end;
end;

function TStructelement.getVartype: TVariableType;
begin
  result:=fVartype;
end;

procedure TStructelement.setVartype(newVartype: TVariableType);
begin
  if newVartype<>fVartype then
  begin
    fVartype:=newVartype;
    parent.DoElementChangeNotification(self);
  end;
end;

function TStructelement.getCustomType: TCustomType;
begin
  result:=fCustomType;
end;

procedure TStructelement.setCustomType(newCustomtype: TcustomType);
begin
  if newCustomtype<>fCustomType then
  begin
    fCustomType:=newCustomtype;
    parent.DoElementChangeNotification(self);
  end;
end;

function TStructelement.getDisplayMethod: TdisplayMethod;
begin
  result:=fDisplayMethod;
end;

procedure TStructelement.setDisplayMethod(newDisplayMethod: TdisplayMethod);
begin
  if newDisplayMethod<>fDisplayMethod then
    fDisplayMethod:=newDisplayMethod;

  parent.DoElementChangeNotification(self);
end;

function TStructelement.getBytesize: integer;
begin
  if vartype in [vtByteArray, vtString, vtUnicodeString] then
    result:=fbytesize
  else
  begin
    result:=1;
    case vartype of
      vtByte: result:=1;
      vtWord: result:=2;
      vtDword: result:=4;
      vtQword: result:=8;
      vtSingle: result:=4;
      vtDouble: result:=8;
      vtPointer: result:=processhandler.pointersize;
      vtCustom: if customtype<>nil then result:=CustomType.bytesize;
    end;
  end;
end;

procedure TStructelement.setBytesize(newByteSize: integer);
begin
  if newByteSize<>fbytesize then
  begin
    fbytesize:=max(1,newByteSize); //at least 1 byte
    parent.DoElementChangeNotification(self);
  end;
end;

function TStructelement.getBackgroundColor: integer;
begin
  result:=fBackgroundColor;
end;

procedure TStructelement.setBackgroundColor(c: TColor);
begin
  fBackgroundColor:=c;
  parent.DoElementChangeNotification(self);
end;

function TStructelement.getValue(address: ptruint; hashexprefix: boolean=false; showAsHexOverride: boolean=false): string;
var vt: TVariableType;
  ashex: boolean;
begin
  if vartype=vtPointer then
  begin
    ashex:=true;
    result:=rsP;

    if processhandler.is64Bit then
      vt:=vtQword
    else
      vt:=vtDword;
  end
  else
  begin
    result:='';
    vt:=vartype;
    ashex:=displaymethod=dtHexadecimal;
  end;


  if showAsHexOverride then
    ashex:=true;

  if hashexprefix and ashex then
    result:='0x'; //also takes care of P->


  result:=result+readAndParseAddress(address, vt,  fCustomType, ashex, displayMethod=dtSignedInteger, bytesize);
end;

procedure TStructelement.setvalue(address: ptruint; value: string);
var hex: boolean;
  vt: TVariableType;
begin
  if vartype=vtPointer then
  begin
    if processhandler.is64Bit then
      vt:=vtQword
    else
      vt:=vtDword;
    hex:=true;

    //strip optional P-> part
    if copy(value, 1,3)=rsP then
      value:=copy(value,4, length(value)-3);
  end
  else
  begin
    vt:=vartype;
    hex:=displaymethod=dtHexadecimal;
  end;

  try
    ParseStringAndWriteToAddress(value, address, vt, hex, fCustomType);
    parent.DoElementChangeNotification(self);
  except
  end;
end;

function TStructelement.getValueFromBase(baseaddress: ptruint): string;
begin
  result:=getvalue(baseaddress+offset);
end;

procedure TStructelement.setValueFromBase(baseaddress: ptruint; value: string);
begin
  setvalue(baseaddress+offset, value);
end;

function TStructelement.isPointer: boolean;
begin
  result:=vartype=vtPointer;
end;

function TStructelement.getChildStruct: TDissectedStruct;
begin
  result:=fchildstruct;
end;

procedure TStructelement.setChildStruct(newChildStruct: TDissectedStruct);
begin
  fchildstruct:=newChildStruct;
  parent.DoElementChangeNotification(self);
end;

procedure TStructelement.setChildStructStart(offset: integer);
begin
  fchildstructstart:=offset;
  parent.DoElementChangeNotification(self);
end;

function TStructelement.getIndex: integer;
begin
  result:=parent.getIndexOf(self);
end;

procedure TStructelement.AutoCreateChildStruct(name: string; address: ptruint);
var c: TDissectedStruct;
  addressdata: TAddressData;
  UsedOverride: boolean;
  i: integer;
begin
  if isPointer and (ChildStruct=nil) then
  begin
    c:=TDissectedStruct.create(name);

    if symhandler.GetLayoutFromAddress(address, addressdata) then
    begin
      c.fillFromDotNetAddressData(addressdata);
      c.name:=addressdata.classname;
      if c.count>0 then
      begin
        ChildStruct:=c;
        ChildStructStart:=address-addressdata.startaddress;
      end
      else
        c.free;
    end
    else
    begin
      UsedOverride:=false;
      for i:=0 to length(StructureDissectOverrides)-1 do
      begin
        if assigned(StructureDissectOverrides[i]) then
        begin
          UsedOverride:=StructureDissectOverrides[i](c, address);
          if UsedOverride then break;
        end;
      end;
      
      if not UsedOverride then
        c.autoGuessStruct(address, 0, parent.autoCreateStructsize);

      if c.count>0 then
        ChildStruct:=c
      else
        c.free;
    end;

  end;
end;

destructor TStructelement.destroy;
begin
  parent.removeElement(self);
  inherited destroy;
end;

constructor TStructelement.create(parent:TDissectedStruct);
begin
  fparent:=parent;
  fbytesize:=1;
  fbackgroundcolor:=clWindow;
end;

constructor TStructelement.createFromXMLElement(parent:TDissectedStruct; element: tdomelement);
var ChildStructStartS: string;
  childnode: TDOMElement;
  childname: string;

  s: string;

  e: TDOMAttr;
begin
  fparent:=parent;
  fbackgroundcolor:=clWindow;
  self.foffset:=strtoint(element.GetAttribute('Offset'));
  self.fname:=AnsiToUtf8(element.GetAttribute('Description'));
  self.fvartype:=StringToVariableType(element.GetAttribute('Vartype'));
  self.fCustomType:=GetCustomTypeFromName(element.GetAttribute('Customtype'));
  self.fdisplayMethod:=StringToDisplayMethod(element.GetAttribute('DisplayMethod'));
  self.fbytesize:=strtoint(element.GetAttribute('Bytesize'));
  s:=element.GetAttribute('BackgroundColor');
  if s<>'' then
    self.fbackgroundcolor:=HexStrToInt(s);

  self.fExpandChangesAddress:=element.GetAttribute('ExpandChangesAddress')='1';


  ChildStructStartS:=element.GetAttribute('ChildStructStart');
  if ChildStructStartS<>'' then
    fChildStructStart:=strtoint(ChildStructStartS)
  else
    fChildStructStart:=0;



  if fvartype=vtPointer then
  begin
    //check if it has a child struct
    childnode:=TDOMElement(element.FindNode('Structure'));
    if childnode<>nil then
      fchildstruct:=TDissectedStruct.createFromXMLNode(childnode)
    else
      delayLoadedStructname:=AnsiToUtf8(element.GetAttribute('ChildStruct'));
  end;

end;

{TDissectedStruct}


function TDissectedStruct.getName: string;
begin
  result:=structname;
end;

procedure TDissectedStruct.setName(newname: string);
begin
  structname:=newname;
  DoFullStructChangeNotification;
end;

function TDissectedStruct.getElementCount: integer;
begin
  if structelementlist<>nil then
    result:=structelementlist.Count
  else
    result:=0;
end;

function TDissectedStruct.getElement(index: integer): TStructelement;
begin

  if (structelementlist<>nil) and ((index>=0) and (index<structelementlist.Count)) then
    result:=TStructelement(structelementlist.Items[index])
  else
    result:=nil;
end;

function TDissectedStruct.isUpdating: boolean;
begin

  result:=fUpdateCounter>0;
end;

function elementsort(Item1, Item2: Pointer): Integer;
begin
  result:=CompareValue(TStructelement(item1).offset, TStructelement(item2).offset);
end;


procedure TDissectedStruct.sortElements;
begin
  if isUpdating=false then
  begin
    structelementlist.Sort(elementsort);
    DoFullStructChangeNotification;
  end
  else
    updateCalledSort:=true;

end;

procedure TDissectedStruct.DoOptionsChangedNotification;
//update all windows with this as the current structure
var i: integer;
begin
  for i:=0 to frmStructures2.Count-1 do
    TfrmStructures2(frmStructures2[i]).onStructOptionsChange(self);

end;


procedure TDissectedStruct.DoFullStructChangeNotification;
var i: integer;
begin
  if isUpdating=false then
  begin
    for i:=0 to frmStructures2.Count-1 do
      TfrmStructures2(frmStructures2[i]).onFullStructChange(self);
  end
  else
    fullstructupdate:=true;
end;



procedure TDissectedStruct.DoElementChangeNotification(element: TStructelement);
var i: integer;
begin
  mainform.editedsincelastsave:=true;

  if isUpdating=false then
  begin
    for i:=0 to frmStructures2.Count-1 do
      TfrmStructures2(frmStructures2[i]).onElementChange(self, element);
  end
  else
  begin
    if updatedelements.IndexOf(element)=-1 then  //add this element to the list of updated elements that endupdate should then update
      updatedelements.Add(element);

    updateChangedInformation:=true;
  end;
end;

procedure TDissectedStruct.beginUpdate;
begin
  inc(fUpdateCounter);
  updatecalledSort:=false;
  updateChangedInformation:=false;
  fullstructupdate:=false;

  if updatedelements=nil then
    updatedelements:=TList.Create;

  updatedelements.clear;
end;

procedure TDissectedStruct.endUpdate;
var i: integer;
begin
  if isUpdating then
    dec(fUpdateCounter);

  if fUpdateCounter=0 then
  begin
    if updatecalledsort then
    begin
      sortElements; //sort them now
      updatecalledSort:=false;
    end
    else
    if fullstructupdate then
    begin
      DoFullStructChangeNotification;
      fullstructupdate:=false;
    end
    else //no need to call the individual updates if sort was done.
    if updateChangedInformation then //not set for changing the offset, only for other visual stuff
    begin
      for i:=0 to updatedelements.count-1 do
        DoElementChangeNotification(TStructelement(updatedelements[i]));

      updatedelements.clear;
      updateChangedInformation:=false;
    end;


  end;
end;

function TDissectedStruct.addElement(name: string=''; offset: integer=0; vartype: TVariableType=vtByte; customType: TCustomtype=nil; bytesize: integer=0; childstruct: TDissectedStruct=nil): TStructelement;
begin
  beginUpdate;
  result:=TStructelement.create(self);
  structelementlist.Add(result);

  result.name:=name;
  result.offset:=offset;
  result.vartype:=vartype;
  result.CustomType:=customType;
  result.childstruct:=childstruct;
  result.bytesize:=bytesize;

  sortElements;
  endUpdate;
end;

procedure TDissectedStruct.removeElement(element: TStructelement);
begin
  structelementlist.Remove(element);

  DoFullStructChangeNotification;
end;

procedure TDissectedStruct.delete(index: integer);
begin
  removeElement(element[index]);
end;

procedure TDissectedStruct.fillGaps(structbase: ptruint; askiftoobig: boolean);
//Will find gaps and fill them up. If a gap is bigger than 512, ask the user, or skip if not asked
var i,j: integer;
  size: integer;
  smallestacceptedsize: integer;
  v: TVariableType;

  newoffset: integer;
  e: TStructelement;
begin
  i:=1;
  smallestacceptedsize:=512;
  while i<count do
  begin
    size:=element[i].Offset-(element[i-1].Offset+element[i-1].Bytesize);
    if size>0 then
    begin
      if size>smallestacceptedsize then
      begin
        if (askiftoobig=false) or (MessageDlg(format(rsSF2TheGapBetweenOffset, [element[i-1].Offset, element[i-1].Offset, size]), mtConfirmation, [mbyes,mbno],0)<>mryes) then
        begin
          inc(i);
          continue;
        end;
      end;
      smallestacceptedsize:=max(smallestacceptedsize, size); //update the smallestacceptedsize

      //and fill this range
      v:=element[i-1].VarType;
      newoffset:=element[i-1].Offset+element[i-1].Bytesize;
      if (v in [vtDword, vtSingle]) and (size in [4,8,12,16,20,24,32]) then //previous was a 4 byte type and nicely aligned, so fill with the same type
      begin
        for j:=0 to (size div 4)-1 do
        begin
          e:=addElement('', newOffset, v);

          if fDefaultHex and (v in [vtByte..vtQword]) then
            e.DisplayMethod:=dtHexadecimal;

          inc(newOffset,4);
        end;
      end
      else
      begin
        //not really sure what to fill it with so use the autoguess method
        autoGuessStruct(structbase+newoffset, newoffset, size);
      end;
    end;

    inc(i);
  end;
end;

procedure TDissectedStruct.fillFromDotNetAddressData(const data: TAddressData);
var
  i,j: integer;
  x: ptruint;
  e: TStructelement;
  buf: pbytearray;
  bufsize: integer;
  ctp: PCustomType;
  customtype: TCustomType;

  vt: TVariableType;

  offset: integer;
  elemsize: integer;
begin

  if (frmStructuresConfig<>nil) and frmStructuresConfig.cbAutoGuessCustomTypes.checked then
    ctp:=@customtype
  else
    ctp:=nil;


  e:=addElement('Vtable',0, vtPointer);

  if (data.objecttype = ELEMENT_TYPE_ARRAY) or  (data.objecttype = ELEMENT_TYPE_SZARRAY) then //elements are integral, rather than named fields
  begin
    readprocessmemory(processhandle,pointer(data.startaddress+data.countoffset),@j,sizeof(j),x); //read array length (always flat addressing, regardless of rank)
    addElement('Number of Elements', data.countoffset, vtDword);
    //arbitrarily decide that we only want to see the first 100 elements...
    if j > 100 then //maybe prompt instead, but it's easy enough to add elements later and some
      j := 100; //structures (Terraria's tiles, eg, are 2*10^9 elements) and it's either too slow or not possible to diagram
    for i:=0 to j-1 do
    begin
      e:=addElement(data.classname + '['+inttostr(i)+']', data.firstelementoffset+i*data.elementsize, vtPointer);
      case data.elementtype of
        ELEMENT_TYPE_END            : e.VarType:=vtDword;
        ELEMENT_TYPE_VOID           : e.VarType:=vtDword;
        ELEMENT_TYPE_BOOLEAN        : e.VarType:=vtByte;
        ELEMENT_TYPE_CHAR           : begin e.VarType:=vtUnicodeString; e.setBytesize(256); end;
        ELEMENT_TYPE_I1             : begin e.DisplayMethod:=dtSignedInteger; e.VarType:=vtByte; end;
        ELEMENT_TYPE_U1             : e.VarType:=vtByte;
        ELEMENT_TYPE_I2             : begin e.DisplayMethod:=dtSignedInteger; e.VarType:=vtWord; end;
        ELEMENT_TYPE_U2             : e.VarType:=vtWord;
        ELEMENT_TYPE_I4             : begin e.DisplayMethod:=dtSignedInteger; e.VarType:=vtDWord; end;
        ELEMENT_TYPE_U4             : e.VarType:=vtDWord;
        ELEMENT_TYPE_I8             : begin e.DisplayMethod:=dtSignedInteger; e.VarType:=vtQWord; end;
        ELEMENT_TYPE_U8             : e.VarType:=vtQWord;
        ELEMENT_TYPE_R4             : e.VarType:=vtSingle;
        ELEMENT_TYPE_R8             : e.VarType:=vtDouble;
      end
    end;
  end;

  if length(data.fields)>0 then
  begin
    bufsize:=data.fields[length(data.fields)-1].offset+16;
    getmem(buf, bufsize);
    readprocessmemory(processhandle,pointer(data.startaddress),@buf[0],bufsize,x);


    beginupdate;
    try
      for i:=0 to length(data.fields)-1 do
      begin
        e:=addElement(data.fields[i].name, data.fields[i].offset);

        e.DisplayMethod:=dtUnSignedInteger;


        case data.fields[i].fieldtype of
          ELEMENT_TYPE_END            : e.VarType:=vtDword;
          ELEMENT_TYPE_VOID           : e.VarType:=vtDword;
          ELEMENT_TYPE_BOOLEAN        : e.VarType:=vtByte;
          ELEMENT_TYPE_CHAR           : begin e.VarType:=vtUnicodeString; e.setBytesize(256); end;
          ELEMENT_TYPE_I1             : begin e.DisplayMethod:=dtSignedInteger; e.VarType:=vtByte; end;
          ELEMENT_TYPE_U1             : e.VarType:=vtByte;
          ELEMENT_TYPE_I2             : begin e.DisplayMethod:=dtSignedInteger; e.VarType:=vtWord; end;
          ELEMENT_TYPE_U2             : e.VarType:=vtWord;
          ELEMENT_TYPE_I4             : begin e.DisplayMethod:=dtSignedInteger; e.VarType:=vtDWord; end;
          ELEMENT_TYPE_U4             : e.VarType:=vtDWord;
          ELEMENT_TYPE_I8             : begin e.DisplayMethod:=dtSignedInteger; e.VarType:=vtQWord; end;
          ELEMENT_TYPE_U8             : e.VarType:=vtQWord;
          ELEMENT_TYPE_R4             : e.VarType:=vtSingle;
          ELEMENT_TYPE_R8             : e.VarType:=vtDouble;
          ELEMENT_TYPE_STRING         : e.VarType:=vtPointer;
          ELEMENT_TYPE_PTR            : e.VarType:=vtPointer;
          ELEMENT_TYPE_BYREF          : e.VarType:=vtPointer;
         // ELEMENT_TYPE_VALUETYPE      : e.VarType:=vtPointer;
          ELEMENT_TYPE_CLASS          : e.VarType:=vtPointer;
          ELEMENT_TYPE_VAR            : e.VarType:=vtPointer;
          ELEMENT_TYPE_ARRAY          : e.VarType:=vtPointer;
          ELEMENT_TYPE_GENERICINST    : e.VarType:=vtPointer;
          ELEMENT_TYPE_TYPEDBYREF     : e.VarType:=vtPointer;
          ELEMENT_TYPE_FNPTR          : e.VarType:=vtPointer;
          ELEMENT_TYPE_OBJECT         : e.VarType:=vtPointer;
          ELEMENT_TYPE_SZARRAY        : e.VarType:=vtPointer;
          else
          begin
            //unknown type. Guess

            offset:=data.fields[i].offset;

            if i<length(data.fields)-1 then
              elemsize:=data.fields[i+1].offset-data.fields[i].offset
            else
              elemsize:=bufsize-offset;

            j:=1;
            while elemsize>0 do
            begin

              vt:=FindTypeOfData(data.startaddress+offset,@buf[data.fields[i].offset],elemsize, ctp, [biNoString]);
              e.vartype:=vt;
              if vt=vtCustom then
                e.CustomType:=customtype;

              inc(offset, e.Bytesize);
              dec(elemsize, e.bytesize);
              inc(j);

              if elemsize>0 then
                e:=addElement(data.fields[i].name+'_'+inttostr(j), offset);


            end;



          end;

        end;

      end;

    finally
      endUpdate;
    end;

  end;
  DoFullStructChangeNotification;
end;

procedure TDissectedStruct.autoGuessStruct(baseaddress: ptruint; offset: integer; bytesize: integer);
var
  buf: pbytearray;

  currentOffset: integer;
  x: ptruint;
  i,j: integer;
  bs: integer;
  vt: TVariableType;

  e: TStructelement;

  customtype: TCustomType;
  ctp: PCustomType;
begin
  if frmStructuresConfig.cbAutoGuessCustomTypes.checked then
    ctp:=@customtype
  else
    ctp:=nil;

  //figure out the structure for this base address
  getmem(buf, bytesize);

  try
    beginUpdate;




    x:=0;
    readprocessmemory(processhandle,pointer(baseaddress),@buf[0],bytesize,x);

    if x>0 then
    begin
      currentOffset:=offset;

      i:=0;
      while i<x do
      begin
        vt:=FindTypeOfData(baseAddress+i,@buf[i],bytesize-i, ctp);
        e:=addElement();
        e.Offset:=currentOffset;
        e.vartype:=vt;
        if vt=vtCustom then
          e.CustomType:=customtype;

        if vt in [vtByte..vtQword] then
        begin
          if fDefaultHex or ((vt=vtDword) and (not isHumanReadableInteger(pinteger(@buf[i])^))) then
            e.DisplayMethod:=dtHexadecimal;

        end
        else
        if vt in [vtString, vtUnicodeString] then
        begin
          //find out the size of the string
          bs:=0;
          j:=i;


          while (j<bytesize) and (buf[j]>=32) and (buf[j]<=127) do
          begin
            if vt=vtString then
              inc(j)
            else
              inc(j,2);

            inc(bs);
          end;

          if (j<bytesize-1) and (buf[j]=0) then //add the zero terminator if one exists
            inc(bs);

          e.Bytesize:=bs;
        end;

        inc(i, e.Bytesize);
        inc(currentOffset, e.ByteSize);
      end;
    end;
  finally
    endUpdate;
    DoFullStructChangeNotification;
    freemem(buf);
  end;
end;

function TDissectedStruct.getStructureSize: integer;
var e: TStructelement;
begin
  result:=0;
  if getElementCount>0 then
  begin
    e:=getElement(getElementCount-1);
    result:=e.Offset+e.Bytesize;
  end;
end;

procedure TDissectedStruct.addToGlobalStructList;
var i: integer;
begin
  if not isInGlobalStructList then
  begin
    DissectedStructs.Add(self);

    //notify that this structure has been added
    for i:=0 to frmStructures2.Count-1 do
       TfrmStructures2(frmStructures2[i]).onAddedToStructList(self);
  end;
end;

procedure TDissectedStruct.removeFromGlobalStructList;
var i: integer;
begin
  if isInGlobalStructList then
  begin
    DissectedStructs.Remove(self);

    //notify that this structure has been removed
    for i:=0 to frmStructures2.Count-1 do
       TfrmStructures2(frmStructures2[i]).onRemovedFromStructList(self);
  end;
end;

function TDissectedStruct.isInGlobalStructList: boolean;
begin
  result:=DissectedStructs.IndexOf(self)<>-1;
end;

function TDissectedStruct.getIndexOf(element: TStructElement): integer;
begin
  result:=structelementlist.IndexOf(element);
end;

function TDissectedStruct.getIndexOfOffset(offset: dword): integer;
//Find the first index where the offset is equal or bigger than the searched for index
begin
  result:=0;
  while result<count do
  begin
    if element[result].Offset>=offset then break; //found it
    inc(result);
  end;
  //if nothing is found result will contain the current count, resulting in nothing
end;

procedure TDissectedStruct.OnDeleteStructNotification(structtodelete: TDissectedStruct; path: TList);
var
  i: integer;
  s: TDissectedStruct;
begin
  //remove all mentioning of this struct
  if structtodelete=self then exit;

  if structelementlist=nil then exit; //destroyed structure called (bug)

  beginUpdate;

  for i:=0 to count-1 do
  begin
    s:=element[i].ChildStruct;

    if s<>nil then
    begin
      if element[i].ChildStruct=structtodelete then
        element[i].ChildStruct:=nil
      else
      begin
        //a struct but not the deleted one. Make sure it is a LOCAL one to prevent an infinite loop (a global struct can point to itself)
        if (not s.isInGlobalStructList) and (path.IndexOf(self)=-1) then
        begin
          path.Add(self); //prevents infinite loops
          s.OnDeleteStructNotification(structtodelete, path);
          path.Remove(self);
        end;
      end;
    end;
  end;
  endUpdate;
end;

procedure TDissectedStruct.DoDeleteStructNotification;
var
  i: integer;
  infiniteLoopProtection: tlist;
begin
  //tell each structure that it should remove all the childstruct mentions of this structure

  for i:=0 to DissectedStructs.count-1 do
  begin
    if DissectedStructs[i]<>self then
    begin
      infiniteLoopProtection:=TList.create;
      try
        TDissectedStruct(DissectedStructs[i]).OnDeleteStructNotification(self, infiniteLoopProtection);
      finally
        infiniteLoopProtection.Free;
      end;
    end;
  end;

  //tell each form that it should close this structure
  for i:=0 to frmStructures2.Count-1 do
    TfrmStructures2(frmStructures2[i]).OnStructureDelete(self);


end;


procedure TDissectedStruct.WriteToXMLNode(node: TDOMNode);
var
  i,j: integer;
  RLECount: integer;
  doc: TDOMDocument;

  structnode: TDOMElement;
  elementnodes: TDOMElement;
begin
  doc:=node.OwnerDocument;

  structnode:=TDOMElement(node.AppendChild(doc.CreateElement('Structure')));
  TDOMElement(structnode).SetAttribute('Name',Utf8ToAnsi(name));



  TDOMElement(structnode).SetAttribute('DoNotSaveLocal',BoolToStr(fDoNotSaveLocal,'1','0'));
  TDOMElement(structnode).SetAttribute('AutoCreate',BoolToStr(fAutoCreate,'1','0'));
  TDOMElement(structnode).SetAttribute('AutoCreateStructsize',inttostr(fAutoCreateStructsize));
  TDOMElement(structnode).SetAttribute('AutoDestroy',BoolToStr(fAutoDestroy,'1','0'));
  TDOMElement(structnode).SetAttribute('AutoFill',BoolToStr(fAutoFill,'1','0'));
  TDOMElement(structnode).SetAttribute('DefaultHex',BoolToStr(fDefaultHex,'1','0'));
  TDOMElement(structnode).SetAttribute('RLECompression',BoolToStr(fRLECompression,'1','0'));

  elementnodes:=TDOMElement(structnode.AppendChild(TDOMNode(doc.CreateElement('Elements'))));

  RLECount:=0;
  for i:=0 to count-1 do
  begin
    if RLECount>0 then begin dec(RLECount); Continue; end;

    if fRLECompression then
    for j:=i to count-2 do
      if ( element[j].Bytesize=element[j+1].Bytesize ) and
         ( element[j].Name=element[j+1].Name ) and
         ( element[j].DisplayMethod=element[j+1].DisplayMethod ) and
         ( element[j].BackgroundColor=element[j+1].BackgroundColor ) and
         ( (element[j].Bytesize+element[j].Offset) = element[j+1].Offset ) and
         ( element[j].VarType=element[j+1].VarType ) and
         ( element[j].ChildStruct=nil ) and ( element[j+1].ChildStruct=nil ) and

         ( ((element[j].CustomType=nil) and (element[j+1].CustomType=nil)) or
           ((element[j].CustomType<>nil) and (element[j+1].CustomType<>nil) and
            (element[j].CustomType.name=element[j+1].CustomType.name)) )

      then Inc(RLECount) else break;

    element[i].WriteToXMLNode(elementnodes);

    if RLECount<>0 then
    begin
      TDOMElement(elementnodes.LastChild).SetAttribute('RLECount',IntToStr(RLECount+1));
      if element[i].VarType=vtPointer then
        TDOMElement(elementnodes.LastChild).SetAttribute('PointerSize',IntToStr(element[i].Bytesize));
    end;
  end;
end;

procedure TDissectedStruct.fillDelayLoadedChildstructs;
//call this when all structures have been loaded
var
  i,j: integer;
  sn: string;
begin
  beginUpdate;
  for i:=0 to count-1 do
  begin
    sn:=element[i].delayLoadedStructname;
    if sn<>'' then
    begin
      //find and fill in the struct
      for j:=0 to DissectedStructs.count-1 do
      begin
        if TDissectedStruct(DissectedStructs[j]).name=sn then
        begin
          //found it, set the struct
          element[i].ChildStruct:=TDissectedStruct(DissectedStructs[j]);
          break;
        end;
      end;
    end
    else
    begin
      if (element[i].isPointer) and (element[i].ChildStruct<>nil) and (element[i].ChildStruct.isInGlobalStructList=false) then //local structure, scan this one as well
        element[i].ChildStruct.fillDelayLoadedChildstructs;
    end;
  end;
  endUpdate;
end;

procedure TDissectedStruct.setDoNotSaveLocal(state: boolean);
begin
  fDoNotSaveLocal:=state;
  DoOptionsChangedNotification;
end;

procedure TDissectedStruct.setAutoCreateStructsize(size: integer);
begin
  fAutoCreateStructsize:=size;
  DoOptionsChangedNotification;
end;

procedure TDissectedStruct.setAutoCreate(state: boolean);
begin
  fAutoCreate:=state;
  DoOptionsChangedNotification;
end;

procedure TDissectedStruct.setAutoDestroy(state: boolean);
begin
  fAutoDestroy:=state;
  DoOptionsChangedNotification;
end;

procedure TDissectedStruct.setAutoFill(state: boolean);
begin
  fAutoFill:=state;
  DoOptionsChangedNotification;
end;

procedure TDissectedStruct.setDefaultHex(state: boolean);
begin
  fDefaultHex:=state;
  DoOptionsChangedNotification;
end;

procedure TDissectedStruct.setRLECompression(state: boolean);
begin
  fRLECompression:=state;
  DoOptionsChangedNotification;
end;

procedure TDissectedStruct.setupDefaultSettings;
//loads the default settings for new structures
var reg: Tregistry;
begin
  fAutoCreate:=true; //default settings in case of no previous settings
  fAutoCreateStructsize:=4096;
  fRLECompression:=true;

  reg:=tregistry.create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('\Software\DDY Engine\DissectData',false) then
    begin
      if reg.ValueExists('Autocreate') then fAutoCreate:=reg.ReadBool('Autocreate');
      if reg.ValueExists('Autocreate Size') then fAutoCreateStructsize:=reg.ReadInteger('Autocreate Size');
      if reg.ValueExists('Autodestroy') then fAutoDestroy:=reg.ReadBool('Autodestroy');
      if reg.ValueExists('Don''t save local') then fDoNotSaveLocal:=reg.ReadBool('Don''t save local');
      if reg.ValueExists('Autofill') then fAutoFill:=reg.ReadBool('Autofill');
      if reg.ValueExists('DefaultHex') then fDefaultHex:=reg.ReadBool('DefaultHex');

    end;
  finally
    reg.free;
  end;
end;

constructor TDissectedStruct.createFromOutdatedXMLNode(structure: TDOMNode);
//Constructor for loading old V1 structures
var tempnode: TDOMNode;
  elements: TDOMNode;
  element, tempelement: TDOMNode;
  i: integer;
  currentOffset: dword;
  findoffset: boolean;

  offset: integer;
  description: string;
  vartype: TVariableType;
  bytesize: integer;
  displaymethod: TdisplayMethod;
  childstruct: string;
  isPointer: boolean;
  structurenr: integer;

  se: TStructelement;
begin
  currentoffset:=0;

  self.name:='';
  structelementlist:=tlist.Create;
  autoCreateStructsize:=4096; //default autocreate size
  setupDefaultSettings;

  beginupdate;
  try
    if structure.NodeName='Structure' then
    begin
      tempnode:=structure.FindNode('Name');
      if tempnode<>nil then
        self.name:=tempnode.TextContent;

      elements:=structure.FindNode('Elements');
      for i:=0 to elements.childnodes.count-1 do
      begin
        element:=elements.ChildNodes[i];

        childstruct:='';
        findoffset:=true;
        tempnode:=element.FindNode('Offset');
        if tempnode<>nil then
        begin
          try
            offset:=strtoint(tempnode.textcontent);
            findoffset:=false; //the offset was fetched properly, no need to calculate it
          except

          end;
        end;

        if findoffset then //it couldn't be read out
          offset:=currentoffset;  //calculated offset


        tempnode:=element.FindNode('Description');
        if tempnode<>nil then
          description:=tempnode.TextContent;

        {
        tempnode:=element.FindNode('PointerTo');
        tempnode:=element.FindNode('PointerToSize');   }


        tempnode:=element.FindNode('Structurenr');
        if tempnode<>nil then
        begin
          displaymethod:=dtUnsignedInteger;
          structurenr:=strtoint(tempnode.TextContent);
          case structurenr of
            -1,-2,-3: //byte
            begin
              vartype:=vtByte;
              bytesize:=1;

              if structurenr=-2 then
                displaymethod:=dtSignedInteger
              else
              if structurenr=-3 then
                displaymethod:=dtHexadecimal;
            end;

            -4,-5,-6: //word
            begin
              vartype:=vtWord;
              bytesize:=2;

              if structurenr=-5 then
                displaymethod:=dtSignedInteger
              else
              if structurenr=-6 then
                displaymethod:=dtHexadecimal;
            end;

            -7,-8,-9: //dword
            begin
              vartype:=vtDWord;
              bytesize:=4;

              if structurenr=-8 then
                displaymethod:=dtSignedInteger
              else
              if structurenr=-9 then
                displaymethod:=dtHexadecimal;
            end;

            -10,-11: //qword
            begin
              vartype:=vtQWord;
              bytesize:=8;

              if structurenr=-11 then
                displaymethod:=dtHexadecimal;
            end;

            -12: //single
            begin
              vartype:=vtSingle;
              bytesize:=4;
            end;

            -13: //double
            begin
              vartype:=vtDouble;
              bytesize:=8;
            end;

            -14: //string
            begin
              vartype:=vtString;
            end;

            -15: //unicode string
            begin
              vartype:=vtUnicodeString;
            end;
          end;
        end;

        tempnode:=element.FindNode('Bytesize');
        if tempnode<>nil then
          bytesize:=strtoint(tempnode.TextContent);


        se:=addElement(description, offset, vartype,nil, bytesize, nil);
        se.DisplayMethod:=displaymethod;

        currentoffset:=offset+Bytesize;
      end;


    end; //structure.NodeName='Structure'
  finally
    endupdate;
  end;
end;

constructor TDissectedStruct.createFromXMLNode(structure: TDOMNode);
//Create the structure with the given data and possible local structs as well
var
  elementnodes, elementnode: TDOMElement;
  childnode: TDOMElement;
  i,j: integer;
  se: TStructelement;

  offset: integer;
  description: string;
  vartype: TVariableType;
  customtype: TCustomType;
  bytesize: integer;
  displaymethod :TdisplayMethod;


  childstruct: TDissectedStruct;
  childname: string;
  ChildStructStartS: string;
  ChildStructStart: integer;
begin
  self.name:='';
  structelementlist:=tlist.Create;
  autoCreateStructsize:=4096; //default autocreate size
  setupDefaultSettings;

  beginUpdate;
  try
    if structure.NodeName='Structure' then
    begin
      self.name:=TDOMElement(structure).GetAttribute('Name');

      fDoNotSaveLocal:=TDOMElement(structure).GetAttribute('DoNotSaveLocal')='1';
      fAutoCreate:=TDOMElement(structure).GetAttribute('AutoCreate')='1';
      fAutoCreateStructsize:=StrToIntDef(TDOMElement(structure).GetAttribute('AutoCreateStructsize'), 4096);
      fAutoDestroy:=TDOMElement(structure).GetAttribute('AutoDestroy')='1';
      fAutoFill:=TDOMElement(structure).GetAttribute('AutoFill')='1';
      fDefaultHex:=TDOMElement(structure).GetAttribute('DefaultHex')='1';
      fRLECompression:=TDOMElement(structure).GetAttribute('RLECompression')='1';


      elementnodes:=TDOMElement(structure.FindNode('Elements'));
      if elementnodes<>nil then
      begin
        for i:=0 to elementnodes.ChildNodes.Count-1 do
        begin
          elementnode:=TDOMELement(elementnodes.ChildNodes[i]);

          if elementnode.Attributes.GetNamedItem('RLECount')=nil then
            structelementlist.Add(TStructelement.createFromXMLElement(self,elementnode))
          else
          begin
            if elementnode.Attributes.GetNamedItem('PointerSize')<>nil then
              Bytesize:=strtoint(elementnode.GetAttribute('PointerSize'));

            for j:=1 to strtoint(elementnode.GetAttribute('RLECount')) do
            begin
              se:=TStructelement.createFromXMLElement(self,TDOMELement(elementnode));
              if se.VarType=vtPointer then se.Offset:=se.Offset+   Bytesize*(j-1)
              else                         se.Offset:=se.Offset+se.Bytesize*(j-1);
              structelementlist.Add(se);
            end;
          end;

        end;


        sortElements;
      end;
    end;
  finally
    endUpdate;
  end;
end;

constructor TDissectedStruct.create(name: string);
begin
  self.name:=name;
  structelementlist:=tlist.Create;

  autoCreateStructsize:=4096; //default autocreate size
  setupDefaultSettings;
end;

destructor TDissectedStruct.destroy;
var i: integer;
begin
  beginUpdate; //never endupdate


  DoDeleteStructNotification;

  if structelementlist<>nil then
  begin
    while structelementlist.Count>0 do
      TStructelement(structelementlist.Items[0]).free;

    freeandnil(structelementlist);
  end;


  removeFromGlobalStructList;


  inherited destroy;
end;


{ TStructColumn }

procedure TStructColumn.pushAddress;
begin
  backlist.Push(pointer(faddress));
end;

procedure TStructColumn.popAddress;
begin
  if canPopAddress then
    Address:=ptruint(backlist.Pop);
end;

function TStructColumn.canPopAddress: boolean;
begin
  result:=backlist.Count>0;
end;

procedure TStructColumn.setNewParent(group: TStructGroup);
var i: integer;
   oldparent: TStructGroup;
begin
  oldparent:=parent;
  i:=parent.fcolumns.IndexOf(self);

  parent.fcolumns.Remove(self);

  if i<parent.fcolumns.Count then
    TStructColumn(parent.fcolumns[i]).setAnchorsForPos(i);

  if parent.fcolumns.Count=0 then //group has 0 entries , destroy the group
    parent.Free;



  parent:=group;
  i:=parent.fcolumns.Add(self);

  edtAddress.parent:=group.box;
  focusedShape.parent:=group.box;
  if lblname<>nil then
    lblName.parent:=group.box;

  setAnchorsForPos(i);



  group.setPositions; //update the gui
end;

procedure TStructColumn.DeleteClick(sender: TObject);
begin
  if parent.parent.columnCount>1 then //leave one intact
    free;
end;

procedure TStructColumn.ChangeGroupClick(sender: tobject);
var
  grouplist: TStringList;
  l: TfrmSelectionList;
  i: integer;

  g: TStructGroup;
  newname: string;
begin
  //input a window to choose which group
  grouplist:=TStringList.create;
  for i:=0 to parent.parent.groupcount-1 do
    grouplist.AddObject(parent.parent.group[i].groupname, parent.parent.group[i]);

  grouplist.AddObject(rsSF2NewGroup,nil);

  l := TfrmSelectionList.Create(parent.parent, grouplist);
  l.Caption := rsSF2GroupPicker;
  l.label1.Caption := rsSF2SecletTheGroupThisColumnShouldBecomePartOf;
  l.ItemIndex := 0;

  if (l.showmodal = mrOk) and (l.ItemIndex <> -1) then
  begin
    //apply change
    if grouplist.Objects[l.itemindex]=nil then //new group
    begin
      newname:=rsSF2Group2+inttostr(parent.parent.groupcount+1);
      if inputquery(rsSF2NewGroup2,rsSF2GiveTheNewName, newname) then
        g:=TStructGroup.create(parent.parent, newname)
      else
        exit; //no new group, no change
    end
    else
      g:=TStructGroup(grouplist.Objects[l.itemindex]);

    setNewParent(g);
  end;
  l.free;
  grouplist.free;





end;

function TStructColumn.getGlobalIndex: integer;
var i: integer;
begin
  //can be optimized
  result:=-1;
  for i:=0 to parent.parent.columnCount-1 do
    if parent.parent.columns[i]=self then
    begin
      result:=-1;
      exit;
    end;
end;

function TStructColumn.isXInColumn(x: integer): boolean;
var i: integer;
  hsection: Theadersection;
begin
  //check if this x position is in the current columns
  i:=getGlobalIndex;
  hsection:=parent.parent.HeaderControl1.Sections[i+1];
  result:=InRange(x, hsection.left, hsection.Right);
end;

procedure TStructColumn.focus;
begin
  focused:=true;
end;

procedure TStructColumn.edtAddressEnter(sender: tobject);
begin
  focus;
end;

procedure TStructColumn.edtaddressMousedown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  focus;
end;

function TStructColumn.getFocused:boolean;
begin
  result:=fFocused;
end;

procedure TStructColumn.setFocused(state: boolean);
var i,x: integer;
begin
  if fFocused=state then exit;

  //sets this column as the focused column
  //(there can be only one focused column)


  if state then //set all others to false
  begin
    for i:=0 to parent.parent.columncount-1 do
      if parent.parent.columns[i]<>self then
      begin
        parent.parent.columns[i].focused:=false;
      end
      else
      begin
        if state and parent.parent.pnlGroups.HorzScrollBar.IsScrollBarVisible then
        begin

          x:=parent.parent.columns[i].EditLeft+parent.parent.columns[i].parent.GroupBox.left;
          //if not visible, then make it visible
          if not InRange(x+parent.parent.columns[i].EditWidth div 2, parent.parent.pnlGroups.HorzScrollBar.Position,  parent.parent.pnlGroups.ClientWidth) then
          begin
            parent.parent.pnlGroups.HorzScrollBar.Position:=x-5;
          end;

        end;
      end;
  end;

  //make focus visible
  focusedShape.visible:=state;
  fFocused:=state;


end;

procedure TStructColumn.clearSavedState;
begin

  if fsavedstate<>nil then
  begin
    VirtualFreeEx(processhandle, fsavedstate, 0, MEM_RELEASE);
    fsavedstatesize:=0;
    fsavedstate:=nil;
  end;

  miToggleLock.Checked:=false;
  mitoggleLock.caption:=rsLock;

end;

function TStructColumn.getAddress: ptruint;
begin
  result:=faddress;
end;

procedure TStructColumn.setAddress(address: ptruint);
begin
  clearSavedState;
  faddress:=address;

  edtAddress.Text:=IntToHex(faddress,8);
end;

function TStructColumn.getAddressText: string;
begin
  result:=edtAddress.Text;
end;

procedure TStructColumn.setAddressText(address: string);
begin
  clearSavedState;
  edtAddress.Text:=address;
  edtAddressChange(nil);
end;

function TStructColumn.getName: string;
begin
  if lblname<>nil then
    result:=lblName.Caption
  else
    result:='';
end;

function TStructColumn.LockAddress(shownaddress: ptruint; memoryblock: pointer; size: integer): boolean;
var
  x: ptruint;
begin
  result:=false;

  address:=shownaddress;

  fsavedstatesize:=size;
  fsavedstate:=VirtualAllocEx(processhandle, nil, fsavedstatesize+1, MEM_COMMIT or MEM_RESERVE, PAGE_READWRITE);
  if fsavedstate<>nil then
  begin
    //copy the original bytes to the copy
    x:=0;
    if WriteProcessMemory(processhandle, pointer(fsavedstate), memoryblock, fsavedstatesize, x) then
      result:=true
    else
    begin
      if x=0 then
        VirtualFreeEx(processhandle, fsavedstate, 0, MEM_RELEASE)   //copy failed for some unknown reason, free the allocated buffer
      else
      begin
        result:=true;
        fsavedstatesize:=x;
      end;
    end;
  end;



  miToggleLock.Checked:=result;
  miToggleLock.Caption:=format(rsSF2ShadowcopyAt, [inttohex(qword(fsavedstate),8)]);
end;

function TStructColumn.saveState: boolean;
var buf: pointer;
  size: integer;
  x: ptruint;
begin
  clearSavedState;
  result:=false;

  if parent.parent.MainStruct<>nil then
    size:=max(8192, parent.parent.MainStruct.getStructureSize)
  else
    size:=8192;

  getmem(buf, size);
  try
    if readprocessmemory(processhandle, pointer(faddress), buf, size, x) then
      result:=LockAddress(faddress, buf, x);
  finally
    freemem(buf);
  end;
end;

function TStructColumn.getSavedState: pointer;
begin
  result:=fsavedstate;
end;

function TStructColumn.getSavedStateSize: integer;
begin
  if fsavedstate<>nil then
    result:=fsavedstatesize
  else
    result:=0;
end;

function TStructColumn.getEditWidth: integer;
begin
  if edtAddress<>nil then
    result:=edtAddress.Width
  else
    result:=0;
end;

function TStructColumn.getEditLeft: integer;
begin
  if edtAddress<>nil then
    result:=edtAddress.left
  else
    result:=0;
end;

procedure TStructColumn.edtAddressChange(sender: TObject);
var
  invalidaddress: boolean;
  a: ptruint;
begin
  //get the string in the editbox and parse it. On error, indicate with red text
  a:=symhandler.getAddressFromName(edtAddress.Text, false, invalidaddress);

  if invalidaddress then
    edtAddress.Font.Color:=clred
  else
  begin
    faddress:=a;
    edtAddress.Font.Color:=clWindowText;
  end;

  parent.parent.tvStructureView.Refresh;
end;

procedure TStructColumn.ToggleLockClick(sender: TObject);
begin
  //togglelock is not set to autocheck, so if it's not checked, it needs to be checked

  if not miToggleLock.Checked then
    saveState
  else
    clearSavedState;

  parent.parent.tvStructureView.Refresh;
end;

procedure TStructColumn.CutClick(sender: TObject);
begin
  edtAddress.CutToClipboard;
end;

procedure TStructColumn.CopyClick(sender: TObject);
begin
  edtAddress.CopyToClipboard;
end;

procedure TStructColumn.PasteClick(sender: TObject);
begin
  edtAddress.PasteFromClipboard;
end;

procedure TStructColumn.SpiderClick(sender: TObject);
//Opens the structure spider on the current address
var f: Tfrmstringpointerscan;
  ss: ptruint;
begin
  f:=Tfrmstringpointerscan.create(application);

  f.rbDatascan.Checked:=true;
  f.edtBase.text:=edtAddress.Text;
  ss:=ptruint(getSavedState);

  f.cbHasShadow.checked:=ss<>0;

  if ss<>0 then
  begin
    f.edtShadowAddress.Text:=inttohex(ss,8);
    f.edtShadowSize.text:=inttostr(getSavedStateSize);
  end;


  f.show;
end;

procedure TStructColumn.SetCaptionClick(sender: TObject);
var
  i: integer;
  newname: string;
begin
  parent.parent.AutoSize:=false;

  newname:=lblname.caption;
  if InputQuery(rsSF2NewColumnName, rsSF2WhatNameShouldThisColumnHave, newname) then
    lblname.caption:=newname;

  lblname.visible:=lblname.caption<>'';

  if lblname.Width+4>edtAddress.Width then
  begin
    edtAddress.Width:=lblname.width+4;
    focusedShape.Width:=edtAddress.width+2*(focusedshape.Pen.Width);
  end;

  //update the header text as well
  for i:=0 to parent.parent.columnCount-1 do
    if parent.parent.columns[i]=self then
    begin
      parent.parent.HeaderControl1.Sections[i+1].Text:=newname;
      break;
    end;

end;

procedure TStructColumn.MenuPopup(sender: TObject);
begin
  miCut.enabled:=edtAddress.SelLength>0;
  miCopy.enabled:=edtAddress.SelLength>0;
  miPaste.enabled:=Clipboard.HasFormat(CF_TEXT);
end;

procedure TStructColumn.SetProperEditboxPosition;
begin

end;

procedure TStructColumn.setAnchorsForPos(i: integer);
begin
  if i=0 then
  begin
    edtAddress.AnchorSideTop.control:=parent.box;
    edtAddress.AnchorSideTop.side:=asrTop;
    edtAddress.BorderSpacing.Top:=4;

    edtAddress.AnchorSideLeft.control:=parent.box;
    edtAddress.AnchorSideLeft.side:=asrLeft;
    edtAddress.BorderSpacing.Left:=4;
  end
  else
  begin
    edtAddress.AnchorSideTop.control:=parent.columns[i-1].edtAddress;
    edtAddress.AnchorSideTop.side:=asrTop;
    edtAddress.BorderSpacing.Top:=0;

    edtAddress.AnchorSideLeft.control:=parent.columns[i-1].edtAddress;
    edtAddress.AnchorSideLeft.side:=asrRight;
    edtAddress.BorderSpacing.Left:=4;
  end;



  if focusedShape<>nil then
  begin
    focusedShape.AnchorSideLeft.Control:=edtAddress;
    focusedShape.AnchorSideLeft.Side:=asrCenter;
    focusedShape.AnchorSideTop.Control:=edtAddress;
    focusedShape.AnchorSideTop.Side:=asrCenter;
  end;

  if lblname<>nil then
  begin
    lblname.AnchorSideTop.Control:=edtAddress;
    lblname.AnchorSideTop.Side:=asrBottom;
    lblname.AnchorSideLeft.control:=edtAddress;
    lblname.AnchorSideLeft.side:=asrCenter;
  end;


end;

constructor TStructColumn.create(parent: TStructGroup);
var hsection: THeaderSection;
  s: TMenuItem;
  i: integer;
  marginsize: integer;

  fsmultiplication: single;
begin
  if parent=nil then raise exception.create(rsSF2TStructColumnCreateError);
  self.parent:=parent;

  columneditpopupmenu:=TPopupMenu.Create(parent.parent);

  miToggleLock:=TMenuItem.create(columneditpopupmenu);
  miToggleLock.caption:=rsLock;
  miToggleLock.OnClick:=ToggleLockClick;
  columneditpopupmenu.Items.Add(miToggleLock);

  miChangeGroup:=TMenuItem.Create(columneditpopupmenu);
  miChangeGroup.Caption:=rsChangeGroup2;
  miChangeGroup.OnClick:=ChangeGroupClick;
  columneditpopupmenu.Items.Add(miChangeGroup);

  miDelete:=TMenuItem.create(columneditpopupmenu);
  miDelete.caption:=rsDeleteAddress;
  miDelete.OnClick:=DeleteClick;
  columneditpopupmenu.Items.Add(miDelete);

  columneditpopupmenu.Items.AddSeparator;

  miCut:=TMenuItem.create(columneditpopupmenu);
  miCut.OnClick:=CutClick;
  miCut.caption:=rsCut;
  miCut.ShortCut:=TextToShortCut('Ctrl+X');
  columneditpopupmenu.Items.Add(miCut);

  miCopy:=TMenuItem.create(columneditpopupmenu);
  miCopy.OnClick:=Copyclick;
  miCopy.caption:=rsCopy;
  miCopy.ShortCut:=TextToShortCut('Ctrl+C');
  columneditpopupmenu.Items.Add(miCopy);

  miPaste:=TMenuItem.create(columneditpopupmenu);
  mipaste.OnClick:=PasteClick;
  mipaste.caption:=rsPaste;
  miPaste.ShortCut:=TextToShortCut('Ctrl+V');
  columneditpopupmenu.Items.Add(miPaste);


  miSpider:=TMenuItem.create(columneditpopupmenu);
  miSpider.OnClick:=SpiderClick;
  miSpider.caption:=rsSpider;
  miSpider.ShortCut:=TextToShortCut('Ctrl+Alt+S');
  columneditpopupmenu.Items.Add(miSpider);


  s:=TMenuItem.create(columneditpopupmenu);
  s.caption:='-';
  columneditpopupmenu.Items.Add(s);

  miSetCaption:=TMenuItem.create(columneditpopupmenu);
  miSetCaption.OnClick:=SetCaptionClick;
  miSetCaption.caption:=rsSF2SetNameRename;
  miSetCaption.ShortCut:=TextToShortCut('Ctrl+R');
  columneditpopupmenu.Items.Add(miSetCaption);



  columneditpopupmenu.OnPopup:=MenuPopup;




  i:=parent.fcolumns.add(self);

  focusedShape:=TShape.Create(parent.parent);
  focusedShape.Shape:=stRectangle;  //stRoundRect;
  focusedShape.visible:=false;
  focusedShape.parent:=parent.box;


  edtAddress:=TEdit.Create(parent.parent);
  edtAddress.Tag:=ptruint(self);
  edtAddress.OnChange:=edtAddressChange;
  edtAddress.PopupMenu:=columneditpopupmenu;
  edtAddress.OnEnter:=edtAddressEnter;
  edtAddress.Parent:=parent.box;
  edtAddress.OnMouseDown:=edtaddressMousedown;

 // setAnchorsForPos(i);
  edtAddress.BorderSpacing.Bottom:=3;
  edtAddress.BorderSpacing.Right:=4;


  if WindowsVersion>=wvVista then
  begin
    marginsize:=sendmessage(edtAddress.Handle, EM_GETMARGINS, 0,0);
    marginsize:=(marginsize shr 16)+(marginsize and $ffff);
  end
  else
    marginsize:=8;

  edtAddress.ClientWidth:=parent.parent.Canvas.TextWidth('DDDDDDDDFFFF')+marginsize;
  edtAddress.Constraints.MinWidth:=edtAddress.Width;

  focusedShape.Width:=edtAddress.width+2*(focusedshape.Pen.Width);
  focusedShape.Height:=edtAddress.Height+2*(focusedshape.Pen.Width);



  hsection:=parent.parent.headercontrol1.Sections.Add;
  hsection.Text:=rsAddressValue;
  hsection.Width:=parent.parent.headercontrol1.Sections[parent.parent.headercontrol1.Sections.Count-2].width;
  hsection.MinWidth:=20;

  lblName:=tlabel.create(parent.parent);
  lblName.AutoSize:=true;
  lblName.parent:=edtAddress.Parent;
  lblName.Alignment:=taCenter;
  lblName.visible:=false;

  setAnchorsForPos(i);

  parent.setPositions;
  Address:=MemoryBrowser.hexview.address;

  backlist:=TStack.Create;

end;

destructor TStructColumn.destroy;
var i: integer;
begin
  for i:=0 to parent.columnCount-2 do
    if parent.columns[i]=self then
    begin
      parent.columns[i+1].edtAddress.BorderSpacing:=edtaddress.BorderSpacing;
      parent.columns[i+1].edtAddress.AnchorSideTop:=edtAddress.AnchorSideTop;
      parent.columns[i+1].edtAddress.AnchorSideLeft:=edtAddress.AnchorSideLeft;
      break;
    end;

  parent.fcolumns.remove(self);
  parent.parent.headercontrol1.Sections.Delete(parent.parent.HeaderControl1.Sections.Count-1);

  clearSavedState;



  if edtAddress<>nil then
    freeandnil(edtAddress);

  if focusedShape<>nil then
    focusedShape.free;

  if lblname<>nil then
    lblname.free;

  //parent.setPositions;

  if parent.fcolumns.Count=0 then
  begin
    //free the parent group unless it's already deleting itself
    //if it was, it already has removed itself from the form's grouplist
    if parent.parent.fgroups.IndexOf(parent)<>-1 then  //damn!
      parent.Free;
  end;


  if backlist<>nil then
    freeandnil(backlist);
end;

{ Tstructgroup }
procedure TStructGroup.addString(s:string);
begin
  if isempty then
  begin
    fcurrentString:=s;
    isempty:=false;
  end
  else
    if fcurrentString<>s then
      fMatches:=false;
end;

procedure TStructGroup.clear;
begin
  fMatches:=true;
  isempty:=true;
end;

procedure TStructGroup.setGroupName(newname: string);
begin
  groupbox.Caption:=newname;
  fgroupname:=newname;
end;

procedure TStructGroup.RenameClick(sender: tobject);
var newname: string;
begin
  newname:=groupname;
  if inputquery(rsSF2RenameGroup, rsSF2GiveTheNewNameForTheGroup, newname) then
    groupname:=newname;
end;

procedure TStructGroup.DeleteClick(sender: tobject);
begin
  //delete he current group if it's not the last one
  if parent.groupcount>1 then
    free;
end;

procedure TStructGroup.groupboxresize(sender: TObject);
var
  i: integer;
  preferedheight: integer;
begin
  groupbox.OnResize:=nil;
  preferedheight:=10;
  for i:=0 to parent.groupcount-1 do
    preferedheight:=max(parent.group[i].GroupBox.Height+2, preferedheight);

  parent.pnlGroups.ClientHeight:=preferedheight;

  groupbox.OnResize:=groupboxresize;
end;

function TStructGroup.getColumnCount: integer;
begin
  result:=fcolumns.count;
end;

function TStructGroup.getColumn(i: integer): TStructColumn;
begin
  result:=fcolumns[i];
end;

function TStructGroup.getParent: TfrmStructures2;
begin
  result:=parent;
end;

function TStructGroup.AColumnHasSetCaption: boolean;
var i: integer;
begin
  result:=false;
  for i:=0 to columnCount-1 do
  begin
    if columns[i].lblName.caption<>'' then
    begin
      result:=true;
      exit;
    end;
  end;
end;

procedure TStructGroup.setPositions;
begin
  //now set the height
  parent.FixPositions;
end;

constructor TStructGroup.create(parent: TfrmStructures2; GroupName: string);
var i: integer;
begin
  self.parent:=parent;
  i:=parent.fgroups.Add(self);

  fGroupName:=groupname;

  fcolumns:=tlist.create;

  grouppopup:=Tpopupmenu.create(parent);
  miRename:=TmenuItem.create(grouppopup);
  miRename.caption:=rsSF2Rename;
  miRename.OnClick:=RenameClick;
  grouppopup.items.Add(miRename);

  miDelete:=TMenuItem.create(grouppopup);
  miDelete.caption:=rsSF2DeleteGroup;
  miDelete.OnClick:=DeleteClick;
  grouppopup.items.Add(miDelete);

  //create the groupbox
  GroupBox:=TGroupBox.Create(parent);
  GroupBox.Caption:=groupname;
  GroupBox.height:=parent.pnlGroups.ClientHeight;
  groupbox.parent:=parent.pnlGroups;
  groupbox.AutoSize:=true;

  groupbox.OnResize:=groupboxresize;

  groupbox.popupmenu:=grouppopup;

  if i=0 then
  begin
    groupbox.AnchorSideTop.Control:=parent.pnlGroups;
    groupbox.AnchorSideTop.Side:=asrTop;

    groupbox.AnchorSideLeft.Control:=parent.pnlGroups;
    groupbox.AnchorSideLeft.Side:=asrLeft;
  end
  else
  begin
    groupbox.AnchorSideTop.Control:=parent.group[i-1].GroupBox;
    groupbox.AnchorSideTop.Side:=asrTop;

    groupbox.AnchorSideLeft.Control:=parent.group[i-1].GroupBox;
    groupbox.AnchorSideLeft.Side:=asrRight;
    groupbox.BorderSpacing.Left:=8;
  end;

end;

destructor TStructGroup.destroy;
var i: integer;
  g: tgroupbox;
begin
  //delete all the columns first
  i:=parent.fgroups.IndexOf(self);
  if i<parent.fgroups.count-1 then
  begin
    //has stuff right of it
    g:=TStructGroup(parent.fgroups[i+1]).GroupBox;

    g.AnchorSideTop:=groupbox.AnchorSideTop;
    g.AnchorSideLeft:=groupbox.AnchorSideLeft;
    g.BorderSpacing.Left:=groupbox.BorderSpacing.Left;
  end;

  parent.fgroups.Remove(self);

  while fcolumns.count>0 do
    TStructColumn(fcolumns[0]).free;

  if groupbox<>nil then
    freeandnil(groupbox);

  if grouppopup<>nil then
    freeandnil(grouppopup);

  inherited destroy;
end;

{ TfrmStructures2 }

procedure TfrmStructures2.TreeViewVScroll(sender: TObject);
begin
  RefreshVisibleNodes;
end;

procedure TfrmStructures2.TreeViewHScroll(sender: TObject; scrolledleft, maxscrolledleft: integer);
begin


  HeaderControl1.Left:=-scrolledleft;
  HeaderControl1.Width:=tvStructureView.clientwidth  +maxscrolledleft+100;
end;


procedure TfrmStructures2.FormDestroy(Sender: TObject);
var showaddress: integer;
  descriptionsize: integer;
  autoguess: integer;
  defaultstructsize: integer;
begin
  frmStructures2.Remove(self);

  //save the settings
  if miShowAddresses.checked then showaddress:=1 else showaddress:=0;
  if miAutoCreate.checked then autoguess:=1 else autoguess:=0;

  descriptionsize:=HeaderControl1.Sections[0].Width;

  SaveFormPosition(self, [showaddress,autoguess, descriptionsize]);
end;

procedure TfrmStructures2.FormCreate(Sender: TObject);
var x: array of integer;
begin
  //set default colors

  if frmStructuresConfig=nil then
    frmStructuresConfig:=TfrmStructuresConfig.Create(application);

  tvStructureView.Top:=headercontrol1.top+headercontrol1.height;
  tvStructureView.left:=0;
  tvStructureView.width:=clientwidth;
  tvStructureView.height:=clientheight-tvStructureView.Top;

  tvStructureView.onHScroll:=TreeViewHScroll;
  tvStructureView.onVScroll:=TreeViewVScroll;


  frmStructures2.Add(self);

  RefreshStructureList; //get the current structure list

  fgroups:=tlist.create;

  setlength(x,3);
  if LoadFormPosition(self, x) then
  begin
    if length(x)>0 then
    begin
      miShowAddresses.checked:=x[0]=1;
      miAutoCreate.checked:=x[1]=1;
      HeaderControl1.Sections[0].Width:=x[2];
    end;
  end;


  setupColors; //load colors and default struct options


end;

procedure TfrmStructures2.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:=cafree;
end;




procedure TfrmStructures2.FormShow(Sender: TObject);
begin
  HeaderControl1.Height:=canvas.TextHeight('XgjQh'+HeaderControl1.Sections[0].Text)+4;
  if (initialaddress<>0) and (columnCount=0) then  //add the initial address, else it looks so sad...
  begin
    addColumn;
    columns[0].setAddress(initialaddress);
    columns[0].setFocused(true);
    columns[0].edtAddress.SetFocus;
  end;

  tvStructureView.Font.Height:=GetFontData(font.handle).Height;
  if tvStructureView.Font.Height>-15 then
    tvStructureView.Font.Height:=-15;

  if (frmStructuresConfig<>nil) and (frmStructuresConfig.customfont) then
    tvStructureView.font.Assign(frmStructuresConfig.GroupBox1.Font);
end;


procedure TfrmStructures2.HeaderControl1SectionResize(
  HeaderControl: TCustomHeaderControl; Section: THeaderSection);
begin
  SetupFirstNodeLength;
  tvStructureView.ReAlign;

  HeaderControl.Left:=-tvStructureView.scrolledleft;
end;

procedure TfrmStructures2.HeaderControl1SectionTrack(
  HeaderControl: TCustomHeaderControl; Section: THeaderSection; Width: Integer;
  State: TSectionTrackState);
var x: integer;
    s: string;

begin
  if gettickcount>lastresizecheck+50 then
  begin
    lastresizecheck:=GetTickCount;
    SetupFirstNodeLength;
    tvStructureView.ReAlign;

    HeaderControl.Left:=-tvStructureView.scrolledleft;
  end;

  tvStructureView.Repaint;
end;

procedure TfrmStructures2.RefreshVisibleNodes;
begin
  tvStructureView.Repaint;
end;

procedure TfrmStructures2.getPointerFromNode(node: TTreenode;
  column: TStructcolumn; var baseaddress: ptruint; var offsetlist: toffsetlist);
var
  i: integer;
  lastoffsetentry: integer;
  offset0: integer; //the offset at the base of the structure
  prevnode: TTreenode;
  displacement: integer;

  parentelement: TStructelement;
  n: TStructelement;
begin
  baseaddress:=column.Address;
  setlength(offsetlist,0);

  if (node=nil) or (node.level=0) then exit; //first entry in the mainstruct

  setlength(offsetlist, node.Level-1);
  lastoffsetentry:=node.level-2;


  i:=0;
  while node.level>1 do
  begin
    prevnode:=node.parent;

    parentelement:=getStructElementFromNode(node.parent);
    if parentelement<>nil then
      displacement:=parentelement.ChildStructStart
    else
      displacement:=0;

    n:=getStructElementFromNode(node);
    if n=nil then
    begin
      baseaddress:=0;
      setlength(offsetlist,0);
      exit;
    end;

    offsetlist[i]:=n.Offset-displacement;
    inc(i);

    node:=prevnode;
  end;

  //now at node.level=1
  //add the starting offset
  inc(baseaddress, getStructElementFromNode(node).Offset);
end;



function getPointerAddressOverride(c: TStructColumn; address: ptruint; const offsets: array of integer; var hasError: boolean): ptruint;
//special version of the normal getPointerAddress with support for locked addresses
var realaddress, realaddress2: PtrUInt;
    count: ptruint;
    check: boolean;
    i: integer;

    savedstate: ptruint;
begin
  savedstate:=ptruint(c.getSavedState);
  realaddress2:=address;


  for i:=length(offsets)-1 downto 0 do
  begin
    realaddress:=0;
    if (savedstate<>0) and (InRangeX(realaddress2, c.Address, c.address+ c.getSavedStateSize)) then
       realaddress2:=realaddress2+(savedstate-c.address);


    check:=readprocessmemory(processhandle,pointer(realaddress2),@realaddress,processhandler.pointersize,count);
    if check and (count=processhandler.pointersize) then
      realaddress2:=realaddress+offsets[i]
    else
    begin
      hasError:=true;
      result:=0;

      exit;
    end;
  end;

  result:=realAddress2;


  hasError:=false;
end;

function TfrmStructures2.getAddressFromNode(node: TTreenode; column: TStructColumn; var hasError: boolean): ptruint;
//Find out the address of this node
var
  baseaddress: ptruint;
  offsets: array of integer;
begin
  getPointerFromNode(node,column, baseaddress, offsets);
  result:=getPointerAddressOverride(column, baseaddress,  offsets, hasError);
end;


procedure TfrmStructures2.setCurrentNodeStringsInColumns(node: TTreenode; element: TStructElement; highlighted: boolean=false);
{
This method will get the address and value of the current node and store them temporarily in the column for the renderer to fetch
}
var
    i: integer;
    error: boolean;
    address, displayaddress: ptruint;

    groupvalue: string;
    allmatch: boolean;
    allsame: boolean;

    c: TStructColumn;
    savedstate: ptruint;
    everythinghex: boolean;

begin
  if element<>nil then
  begin
    for i:=0 to groupcount-1 do
      group[i].clear;

    everythinghex:=miEverythingHex.checked;

    for i:=0 to columnCount-1 do
    begin
      c:=columns[i];

      displayaddress:=getAddressFromNode(node, columns[i], error);  //get the address to show the user

      savedstate:=ptruint(c.getSavedState);
      address:=displayaddress;

      if (savedstate<>0) and (InRangeX(address, c.Address, c.address+ c.getSavedStateSize)) then
        address:=address+(savedstate-c.address);




      if not error then
      begin
        c.currentNodeAddress:=inttohex(displayaddress,1)+' : ';
        c.currentNodeValue:=element.getValue(address, false, everythinghex);
      end
      else
      begin
        c.currentNodeAddress:='??? : ';
        c.currentNodeValue:='???';
      end;

      //add this string for comparison
      c.parent.addString(c.currentNodeValue);
    end;

    //now find out which groups have matching sets
    allmatch:=true;
    allsame:=true;

    groupvalue:='';
    for i:=0 to groupcount-1 do
    begin
      if group[i].Matches=false then
      begin
        allmatch:=false;
        allsame:=false;
        break;
      end;

      if i=0 then
        groupvalue:=group[0].currentString
      else
      begin
        if groupvalue<>group[i].currentString then
          allsame:=false;
      end;
    end;


    for i:=0 to columncount-1 do
    begin
      c:=columns[i];

      if c.parent.Matches then
      begin
        if not highlighted then
          c.currentNodeColor:=fMatchColor //default match color
        else
          c.currentNodeColor:=fMatchColorHighlighted;


        if (groupcount>1) and allmatch then //if all the groups have columns that match, and more than 1 group, then
        begin
          if allsame then //if all the groups have the same value then
          begin
            if not highlighted then
              c.currentNodeColor:=fAllMatchColorSame
            else
              c.currentNodeColor:=fAllMatchColorSameHighlighted;
          end
          else
          begin
            if not highlighted then
              c.currentNodeColor:=fAllMatchColorDiff
            else
              c.currentNodeColor:=fAllMatchColorDiffHighlighted;
          end;
        end;
      end
      else
      begin
        if not highlighted then
          c.currentNodeColor:=fNoMatchColor
        else
          c.currentNodeColor:=fNoMatchColorHighlighted;
      end;
    end;

  end
  else
  begin
    //invalid struct
    for i:=0 to columnCount-1 do
    begin
      c:=columns[i];
      if not highlighted then
        c.currentNodeColor:=tvStructureView.BackgroundColor
      else
        c.currentNodeColor:=tvStructureView.SelectionColor;

      c.currentNodeValue:='';
      c.currentNodeAddress:='';
    end;
  end;
end;

procedure TfrmStructures2.setupNodeWithElement(node: TTreenode; element: TStructElement);
begin
  tvStructureView.OnCollapsing:=nil;
  tvStructureView.OnCollapsed:=nil;

  try
    if (element.isPointer) then
    begin
      node.Data:=element.ChildStruct;
      if node.data=nil then
        node.DeleteChildren;

      node.HasChildren:=true;
    end
    else
    begin
      //an update caused this node to lose it's pointerstate. If it had children, it doesn't anymore
      node.data:=nil;
      node.DeleteChildren;
      node.haschildren:=false;
    end;




  finally
    tvStructureView.OnCollapsing:=tvStructureViewCollapsing;
    tvStructureView.OnCollapsed:=tvStructureViewCollapsed;
  end;
end;

procedure TfrmStructures2.FillTreenodeWithStructData(currentnode: TTreenode);
var
  struct: TDissectedStruct;
  se: TStructelement;
  newnode: TTreenode;
  i: integer;
  startindex: integer;
begin
  tvStructureView.OnExpanded:=nil;
  tvStructureView.OnExpanding:=nil;
  tvStructureView.OnCollapsed:=nil;
  tvStructureView.OnCollapsing:=nil;

  tvStructureView.BeginUpdate;
  if currentnode.haschildren then
    currentnode.DeleteChildren;

  struct:=TDissectedStruct(currentnode.data);



  if struct<>nil then
  begin
    //get the start index of this structure
    startindex:=0;
    se:=getStructElementFromNode(currentnode);
    if (se<>nil) and (se.ChildStructStart<>0) then
      startindex:=struct.getIndexOfOffset(se.ChildStructStart);

    for i:=startindex to struct.count-1 do
    begin
      newnode:=tvStructureView.Items.AddChild(currentnode,'');
      setupNodeWithElement(newnode, struct[i]);
    end;

    if currentnode.haschildren then
      currentnode.Expand(false);
  end;

  tvStructureView.EndUpdate;

  tvStructureView.OnExpanded:=tvStructureViewExpanded;
  tvStructureView.OnExpanding:=tvStructureViewExpanding;
  tvStructureView.OnCollapsed:=tvStructureViewCollapsed;
  tvStructureView.OnCollapsing:=tvStructureViewCollapsing;
end;


procedure TfrmStructures2.tvStructureViewCollapsed(Sender: TObject; Node: TTreeNode);
var struct, childstruct: TDissectedStruct;
begin
  tvStructureView.BeginUpdate;
  try
    if node.HasChildren then
    begin
      tvStructureView.OnCollapsing:=nil;
      tvStructureView.OnCollapsed:=nil;

      node.DeleteChildren; //delete the children when collapsed

      tvStructureView.OnCollapsing:=tvStructureViewCollapsing;
      tvStructureView.OnCollapsed:=tvStructureViewCollapsed;

    end;

    if node.parent<>nil then //almost always, and then it IS a child
    begin
      //get the structure this node belongs to

      struct:=getStructFromNode(node);

      if (struct=nil) or (struct.structelementlist=nil) then exit; //this whole structure is destroyed

      //now get the element this node represents and check if it is a pointer
      node.HasChildren:=struct[node.Index].isPointer;

      if miAutoDestroyLocal.checked then //delete autocreated local structs when closed
      begin
        childstruct:=TDissectedStruct(node.data);
        if childstruct<>nil then
        begin
          if not childstruct.isInGlobalStructList then
          begin
            //delete this local struct
            childstruct.free;

            {$ifdef DEBUG}
            assert(node.data=nil);
            {$endif}
            node.data:=nil;   //not necessary
          end;
        end;

      end;

    end
    else //root node (mainstruct)
    if node.data<>nil then //weird if not...
    begin
      node.HasChildren:=true;
      node.Expand(false); //causes the expand the fill in the nodes
    end;


  finally
    tvStructureView.EndUpdate;
  end;
end;

procedure TfrmStructures2.tvStructureViewCollapsing(Sender: TObject;
  Node: TTreeNode; var AllowCollapse: Boolean);
begin
  AllowCollapse:=node.level>0;


end;

procedure TfrmStructures2.tvStructureViewExpanded(Sender: TObject;
  Node: TTreeNode);
begin
  if node.data<>nil then
    FillTreenodeWithStructData(node)
end;

procedure TfrmStructures2.tvStructureViewExpanding(Sender: TObject;
  Node: TTreeNode; var AllowExpansion: Boolean);
var n: TStructelement;
  error: boolean;

  address, address2: ptruint;
  c: TStructColumn;
  x: ptruint;
  temp: byte;
  savedstate: PtrUInt;
  structName: string;
begin
  AllowExpansion:=true;
  n:=getStructElementFromNode(node);


  if (n<>nil) and (n.ExpandChangesAddress) then
  begin
    //change address and the structure if needed
    AllowExpansion:=false;

    c:=getFocusedColumn;
    address:=getAddressFromNode(node, c, error);
    if not error then
    begin
      //dereference the pointer and fill it in if possible
      address2:=0;
      if ReadProcessMemory(processhandle, pointer(address), @address2, processhandler.pointersize, x) then
      begin
        if ReadProcessMemory(processhandle, pointer(address2), @address2, 1, x) then
        begin
          c:=getFocusedColumn;
          c.pushAddress;
          c.Address:=address2-n.ChildStructStart;
          mainStruct:=n.ChildStruct;
        end;
      end;
    end;

    exit;
  end;


  if (n<>nil) and (n.isPointer) and (n.ChildStruct=nil) then
  begin
    if miAutoCreate.Checked then
    begin

      //create a structure
      c:=getFocusedColumn;
      if c=nil then
        c:=columns[0];

      address:=getAddressFromNode(node, c, error);

      savedstate:=ptruint(c.getSavedState);
      if (savedstate<>0) and (InRangeX(address, c.Address, c.address+ c.getSavedStateSize)) then
        address:=address+(savedstate-c.address);

      if not error then
      begin
        //dereference the pointer and fill it in if possible

        if ReadProcessMemory(processhandle, pointer(address), @address, processhandler.pointersize, x) then
        begin
          //adjust the address again if it's inside the savedstate
          if (savedstate<>0) and (InRangeX(address, c.Address, c.address+ c.getSavedStateSize)) then
            address:=address+(savedstate-c.address);

          //check if the address pointed to is readable
          if ReadProcessMemory(processhandle, pointer(address), @temp, 1, x) then
          begin
            structName:=lookupStructureName(address, rsSF2AutocreatedFrom+inttohex(address,8));
            n.AutoCreateChildStruct(structName, address)
          end
          else
            error:=true;
        end
        else
          error:=true;
      end;

      AllowExpansion:=not error;
    end
    else
      AllowExpansion:=false;

  end;
end;

function TfrmStructures2.getMainStruct: TDissectedStruct;
begin
  result:=mainStruct;
end;

function TfrmStructures2.getHorizontalScrollbarString: String; //returns a string out of spaces that fills up the length of all the columns combined
var
  i: integer;
  s: THeaderSection;
  totalwidth: integer;
  currentwidth: integer;
begin
  currentwidth:=0;
  result:='';
  s:=HeaderControl1.Sections[HeaderControl1.Sections.Count-1];
  totalwidth:=s.Left+s.Width;

  while currentwidth<totalwidth do
  begin
    result:=result+'    ';
    currentwidth:=tvStructureView.Canvas.GetTextWidth(result);
  end;


end;

procedure TfrmStructures2.SetupFirstNodeLength;
begin
  if tvStructureView.items.count>0 then
    tvStructureView.Items[0].Text:=getHorizontalScrollbarString;
end;

procedure TfrmStructures2.InitializeFirstNode;
//Clear the screen and setup the first node
var tn: TTreenode;
begin
  tvStructureView.Items.Clear;
  if mainStruct<>nil then
  begin
    tn:=tvStructureView.Items.Add(nil, '');
    tn.Data:=mainStruct;
    tn.HasChildren:=true;
    tn.Expand(false);

    SetupFirstNodeLength;

  end;
end;

procedure TfrmStructures2.onAddedToStructList(sender: TDissectedStruct);
begin
  RefreshStructureList;
end;

procedure TfrmStructures2.onRemovedFromStructList(sender: TDissectedStruct);
begin
  RefreshStructureList;
end;

procedure TfrmStructures2.onStructureDelete(sender: TDissectedStruct);
var n: TTreenode;
begin
  if sender=mainStruct then
  begin
    mainstruct:=nil;
    tvStructureView.Items.Clear;
  end
  else
  begin
    tvStructureView.OnCollapsing:=nil;
    tvStructureView.OnCollapsed:=nil;

    try
      n:=tvStructureView.Items.GetFirstNode;

      while n<>nil do
      begin
        if n.data=sender then
        begin
          n.data:=nil;
          n.Collapse(true);
          n.DeleteChildren;
        end;
        n:=n.GetNext;
      end;

    finally
      tvStructureView.OnCollapsing:=tvStructureViewCollapsing;
      tvStructureView.OnCollapsed:=tvStructureViewCollapsed;
    end;
  end;
end;

procedure TfrmStructures2.onStructOptionsChange(sender: TDissectedStruct);
begin
  if mainStruct=sender then
    UpdateCurrentStructOptions;
end;

procedure TfrmStructures2.onFullStructChange(sender: TDissectedStruct);
var currentNode: TTreenode;
    nextnode: TTreenode;
begin
  //update the childnode of the treenode with this struct to represent the new state
  if mainStruct<>nil then
  begin

    currentNode:=tvStructureView.Items.GetFirstNode;
    if currentnode=nil then
    begin
      InitializeFirstNode;
      currentNode:=tvStructureView.Items.GetFirstNode;
    end;

    while currentnode<>nil do
    begin
      //go through all entries

      //check if currentnode.data is of the type that needs to be updated
      if (currentnode.Data=sender) and (currentnode.Expanded or (currentNode.level=0)) then  //node is of the updated type and currently has children , or it's the root node
        FillTreeNodeWithStructData(currentnode);


      //nothing else to be done, get the next one
      nextnode:=currentnode.GetFirstChild;
      if nextnode=nil then
        nextnode:=currentnode.GetNextSibling;
      if nextnode=nil then
      begin
        //up one level
        nextnode:=currentnode.Parent;
        if nextnode<>nil then
          nextnode:=nextnode.GetNextSibling;
      end;
      currentnode:=nextnode;
    end;

  end;


  //else nothing to update

  //and also the structure list in case it's one I didn't know of
  RefreshStructureList;
end;

procedure TfrmStructures2.onElementChange(struct:TDissectedStruct; element: TStructelement);
var i: integer;
    n: Ttreenode;
begin
  //find the treenodes that belong to this specific element and change them accordingly
  i:=0;
  n:=tvStructureView.Items.GetFirstNode;
  while n<>nil do
  begin
    if n.data=struct then
    begin
      if n.expanded then
      begin
        if n.Count>=element.index then
          setupNodeWithElement(n[element.index], element)
        else
        begin
          tvStructureView.OnCollapsing:=nil;
          tvStructureView.OnCollapsed:=nil;

          n.DeleteChildren;

          tvStructureView.OnCollapsing:=tvStructureViewCollapsing;
          tvStructureView.OnCollapsed:=tvStructureViewCollapsed;
        end;
      end;
    end;
    n:=n.GetNext;
  end;

{  while i<tvStructureView.Items.Count do
  begin
    if tvStructureView.Items[i].Data=struct then //this node contains the element
    begin
      if tvStructureView.Items[i].Expanded then
      begin
        //it's expanded so visible. Find the specific node and apply a update
        n:=tvStructureView.Items[i].Items[element.index];

        setupNodeWithElement(n, element);
      end;
    end;
    inc(i);
  end;   }



end;

function TfrmStructures2.DefineNewStructure(recommendedSize: integer=4096): TDissectedStruct;
var
  structName: string;
  autoFillIn: integer;
  sstructsize: string;
  structsize: integer;

  addressdata: TAddressData;
  hasAddressData: boolean;
  i: integer;

  UsedOverride: boolean;
  a: ptruint;
begin
  result:=nil;
  if columnCount>0 then
  begin
    hasAddressData:=symhandler.GetLayoutFromAddress(TStructColumn(columns[0]).getAddress, addressdata);

    if hasAddressData then
      structname:=addressdata.classname
    else
    begin


      structname:=rsUnnamedStructure;

      for i:=0 to length(StructureNameLookups)-1 do
      begin
        if assigned(StructureNameLookups[i]) then
        begin
          a:=TStructColumn(columns[0]).getAddress;
          if StructureNameLookups[i](a, structname) then
          begin
            TStructColumn(columns[0]).setAddress(a);
            break;
          end;
        end;
      end;
    end;

    //get the name
    if not inputquery(rsStructureDefine, rsGiveTheNameForThisStructure, structName) then exit;

    if structname<>rsUnnamedStructure then
    begin
      for i:=0 to DissectedStructs.Count-1 do
        if TDissectedStruct(dissectedstructs[i]).name=structname then
        begin
          if messagedlg(format(rsStructAlreadyExists,[structname]), mtWarning, [mbyes, mbno], 0)<>mryes then exit else break;
        end;
    end;


    //ask if it should be filled in automatically
    autoFillIn:=messagedlg(rsDoYouWantCheatEngineToTryAndFillInTheMostBasicType, mtconfirmation, [mbyes, mbno, mbcancel], 0);
    if autoFillIn=mrcancel then exit;

    mainStruct:=nil;
    tvStructureView.items.clear;


    mainStruct:=TDissectedStruct.create(structname);

    if autofillin=mryes then
    begin
      if hasAddressData then
      begin
        TStructColumn(columns[0]).setAddress(addressdata.startaddress);
        mainStruct.FillFromDotNetAddressData(addressdata);
      end
      else
      begin
        UsedOverride:=false;
        for i:=0 to length(StructureDissectOverrides)-1 do
        begin
          if assigned(StructureDissectOverrides[i]) then
          begin
            a:=TStructColumn(columns[0]).getAddress;
            UsedOverride:=StructureDissectOverrides[i](mainStruct, a);
            if UsedOverride then break;
          end;
        end;

        if not UsedOverride then
        begin
          sstructsize:=inttostr(recommendedSize);
          if not inputquery(rsStructureDefine, rsPleaseGiveAStartingSizeOfTheStructYouCanChangeThis, Sstructsize) then exit;
          structsize:=strtoint(sstructsize);

          if TStructColumn(columns[0]).getSavedState=nil then
            mainStruct.autoGuessStruct(TStructColumn(columns[0]).getAddress, 0, structsize )
          else
            mainStruct.autoGuessStruct(ptruint(TStructColumn(columns[0]).getSavedState), 0, min(structsize, TStructColumn(columns[0]).getSavedStateSize)); //fill base don the saved state
        end;
      end;
    end;

    mainStruct.addToGlobalStructList;
    UpdateCurrentStructOptions;

    result:=mainStruct;

  end;

end;

procedure TfrmStructures2.Definenewstructure1Click(Sender: TObject);
begin
  DefineNewStructure(4096);
end;


function TfrmStructures2.getStructElementFromNode(node: TTreenode): TStructelement;
var i: integer;
  s: TDissectedStruct;
  nodestruct: TDissectedStruct;

  pse: TStructelement;
  n: TTreenode;
begin
  //find the structure this node belongs
  result:=nil;

  if (node<>nil) and (node.level>0) then
  begin
    pse:=getStructElementFromNode(node.parent);
    nodestruct:=TDissectedStruct(node.parent.data);

    if nodestruct=nil then exit;

    if pse<>nil then
      i:=nodestruct.getIndexOfOffset(pse.ChildStructStart)
    else
      i:=0;

    result:=nodestruct[node.index+i];
  end;
end;

function TfrmStructures2.getStructFromNode(node: TTreenode): TDissectedStruct;
begin
  result:=mainStruct;

  if node<>nil then
  begin
    node:=node.parent;

    if node<>nil then
      result:=TDissectedStruct(node.data);
  end;
end;

function TfrmStructures2.getChildStructFromNode(node: TTreenode): TDissectedStruct;
begin
  result:=nil;
  if node=nil then exit;

  result:=TDissectedStruct(node.data);
end;

procedure TfrmStructures2.changeNodes;
var
  s, structelement: TStructElement;
  n: TTreenode;
  i: integer;
  ei: TfrmStructures2ElementInfo;
begin
  n:=tvStructureView.selected;
  if n=nil then exit;

  structElement:=getStructElementFromNode(n);
  if structElement=nil then exit;

  ei:=tfrmstructures2ElementInfo.create(self);

  with ei do
  begin
    description:=structelement.name;
    offset:=structelement.offset;
    vartype:=structelement.vartype;
    customtype:=structelement.CustomType;
    backgroundcolor:=structelement.BackgroundColor;

    bytesize:=structelement.bytesize;
    childstruct:=structelement.childstruct;
    hexadecimal:=structelement.displayMethod=dtHexadecimal;
    signed:=structelement.displaymethod=dtSignedInteger;

    ExpandChangesAddress:=structelement.ExpandChangesAddress;


    if tvStructureView.SelectionCount>1 then
      edtOffset.Enabled:=false;


    childstructstart:=structelement.ChildStructStart;

    //fill in basic info

    ChangedDescription:=false;
    ChangedOffset:=false;
    ChangedHexadecimal:=false;
    ChangedSigned:=false;
    ChangedVartype:=false;
    ChangedByteSize:=false;
    ChangedBackgroundColor:=false;
    ChangedChildStruct:=false;
    ChangedchildStructStart:=false;



    if showmodal=mrok then
    begin
      for i:=0 to tvStructureView.SelectionCount-1 do
      begin
        tvStructureView.Selections[i].Collapse(true); //close the selections (destroys autocreated structure nodes if destroy is enabled)

        structElement:=getStructElementFromNode(tvStructureView.Selections[i]);
        if structelement=nil then continue;


        structElement.parent.beginUpdate;
        try
          structelement.ExpandChangesAddress:=ExpandChangesAddress;

          if changedDescription then
            structElement.name:=description;

          if tvStructureView.SelectionCount=1 then //only update the offset if only one entry is selected (e.g the user might be so stupid to select a level 1 and a level 3 of a completely different structure....)
            structElement.offset:=offset;

          if changedVartype then
          begin
            structElement.vartype:=vartype;
            structElement.CustomType:=customtype;
          end;

          if changedBytesize then
            structElement.bytesize:=bytesize;

          if changedBackgroundColor then
            structElement.BackgroundColor:=backgroundColor;

          if changedChildstruct then
            structElement.childstruct:=childstruct;

          if changedhexadecimal or changedsigned then
          begin
            if hexadecimal then
              structelement.displayMethod:=dtHexadecimal
            else
            if signed then
              structelement.displayMethod:=dtSignedInteger
            else
              structelement.displayMethod:=dtUnsignedInteger;
          end;

          if changedChildStructStart then
            structelement.ChildStructStart:=childstructstart;

          if (structelement.VarType<>vtPointer) and (miAutoDestroyLocal.checked=false) then
          begin
            if (structelement.ChildStruct<>nil) and (not structelement.ChildStruct.isInGlobalStructList) then
              structelement.ChildStruct.free;

            structelement.ChildStruct:=nil;
            structelement.ChildStructStart:=0;
          end;



        finally
          structElement.parent.endupdate;
        end;

      end;
    end;


  end;

  ei.free;

end;

procedure TfrmStructures2.addFromNode(n: TTreenode; asChild: boolean=false);
var
  struct: TDissectedStruct;
  structElement: TStructElement;
begin
  if asChild then
    struct:=getChildStructFromNode(n)
  else
    struct:=getStructFromNode(n);  //find out what node this belongs to. (n can be nil, as that will return the mainstruct)

  if struct<>nil then
  begin
    with tfrmstructures2ElementInfo.create(self) do
    begin
      //fill in some basic info
      structElement:=getStructElementFromNode(n);



      if structElement<>nil then
      begin
        //set the default variabes to the type of the currently selected item
        vartype:=structElement.VarType;
        customtype:=structElement.CustomType;
        bytesize:=structElement.Bytesize;
        signed:=structElement.DisplayMethod=dtSignedInteger;


        if struct.DefaultHex and (vartype in [vtByte..vtQword, vtByteArray]) then   //if defaulthex is set and the previous item was an integer type then use the defaulthex's state
          hexadecimal:=struct.DefaultHex
        else
          hexadecimal:=structElement.DisplayMethod=dtHexadecimal

      end
      else
      begin
        vartype:=vtDword;
        hexadecimal:=struct.DefaultHex;
      end;

      if asChild then
        structElement:=nil //adding as child from a rootnode
      else
        structElement:=getStructElementFromNode(n); //can return nil if no node was selected, or the mainnode was selected

      if structelement=nil then
        offset:=struct.getStructureSize
      else         //clicked on a node, find the offset and add it after that
        offset:=structElement.Offset+structElement.Bytesize;

      //show the form to make modification
      if showmodal=mrok then
      begin
        structElement:=struct.addElement(description, offset, vartype, customtype, bytesize, childstruct);
        if hexadecimal then
          structelement.DisplayMethod:=dtHexadecimal
        else
        if signed then
          structElement.DisplayMethod:=dtSignedInteger
        else
          structElement.DisplayMethod:=dtUnsignedInteger; //default, but set anyhow

        //set the selection to this entry
        if not asChild then
        begin
          if (n=nil) or (n.level=0) then
            n:=tvStructureView.Items.GetFirstNode
          else
            n:=n.parent;
        end;

        structElement.BackgroundColor:=backgroundColor;
        structElement.ExpandChangesAddress:=ExpandChangesAddress;



        tvStructureView.Items.SelectOnlyThis(n.Items[structElement.Index]);
      end;

      free;
    end;
  end;

end;

procedure TfrmStructures2.miChangeElementClick(Sender: TObject);
begin
  ChangeNodes;
end;


procedure TfrmStructures2.miAddChildElementClick(Sender: TObject);
begin
  addFromNode(tvStructureView.selected, true);
end;


procedure TfrmStructures2.miAddElementClick(Sender: TObject);
begin
  addFromNode(tvStructureView.selected);
end;



procedure TfrmStructures2.miShowAddressesClick(Sender: TObject);
begin
  RefreshVisibleNodes;
end;

procedure TfrmStructures2.miUpdateOffsetsClick(Sender: TObject);
var offsetstring: string;
  struct: TDissectedStruct;
  element: TStructelement;
  i: integer;
  offset: integer;
begin
  //get the structure and the element to start from
  struct:=getStructFromNode(tvStructureView.selected);
  if struct<>nil then
  begin
    element:=getStructElementFromNode(tvStructureView.selected);
    if (element=nil) and (struct.count>0) then
      element:=struct[0];

    if element<>nil then
    begin
      offsetstring:='0';
      if InputQuery(rsDissectData, rsHowManyBytesDoYouWantToShiftThisAndFollowingOffset, offsetstring) then
      begin

        offset:=StrToInt(offsetstring);

        struct.beginUpdate; //prevents sorting
        for i:=element.index to struct.count-1 do
          struct[i].Offset:=struct[i].offset+offset;

        struct.endUpdate;//resort and update
      end;
    end;

  end;
end;

procedure TfrmStructures2.Open1Click(Sender: TObject);
var doc: TXMLDocument;
  structnode: TDOMNode;
  s: TDissectedStruct;
  i: integer;
begin
  if Opendialog1.Execute then
  begin
    mainstruct:=nil;
    tvStructureView.items.clear;

    ReadXMLFile(doc, Opendialog1.FileName);

    if doc<>nil then
    begin
      structnode:=doc.FindNode('Structures');

      for i:=0 to structnode.ChildNodes.Count-1 do
      begin
        s:=TDissectedStruct.createFromXMLNode(structnode.ChildNodes[i]);

        if s<>nil then
        begin
          s.addToGlobalStructList;

          if mainstruct=nil then
          begin
            mainstruct:=s;

            onFullStructChange(mainstruct);
            RefreshStructureList;
            UpdateCurrentStructOptions;
          end;
        end;
      end;

      for i:=0 to DissectedStructs.count-1 do
        TDissectedStruct(DissectedStructs[i]).fillDelayLoadedChildstructs;


    end;

    doc.Free;
  end;
end;

procedure TfrmStructures2.Save1Click(Sender: TObject);
var doc: TXMLDocument;
  structnode: TDOMNode;
begin
  if mainstruct=nil then exit;

  if Savedialog1.Execute then
  begin
    doc:=TXMLDocument.Create;
    structnode:=TDOMElement(doc.AppendChild(TDOMNode(doc.CreateElement('Structures'))));

    mainstruct.WriteToXMLNode(structnode);
    WriteXML(structnode, savedialog1.filename);

    doc.Free;
  end;
end;

procedure TfrmStructures2.tmFixGuiTimer(Sender: TObject);
begin
  tmFixgui.enabled:=false;
  FixPositions;
end;

procedure TfrmStructures2.pmStructureViewPopup(Sender: TObject);
var childstruct: TDissectedStruct;
  ownerstruct: TDissectedStruct;
  structelement: TStructelement;
  c: TStructColumn;
begin
  ownerstruct:=getStructFromNode(tvStructureView.selected);
  childstruct:=getChildStructFromNode(tvStructureView.selected);
  structelement:=getStructElementFromNode(tvStructureView.Selected);

  miFullUpgrade.visible:=((childstruct=nil) and (structelement<>nil) and (structelement.isPointer)) or ((childstruct<>nil) and (not childstruct.isInGlobalStructList));
  if miFullUpgrade.visible then
  begin
    if (childstruct=nil) then
      miFullUpgrade.caption:=rsDefinePointer
    else
      miFullUpgrade.caption:=rsUpgradePointer;

  end;

  miAddElement.visible:=(ownerstruct<>nil) or (childstruct<>nil);
  miAddChildElement.visible:=(childstruct<>nil);
  miDeleteElement.visible:=tvStructureView.Selected<>nil;
  miChangeElement.visible:=structElement<>nil;

  miBrowseAddress.Visible:=tvStructureView.Selected<>nil;
  miBrowsePointer.visible:=(structelement<>nil) and (structelement.isPointer);


  miChangeValue.Visible:=structelement<>nil;
  miUpdateOffsets.visible:=structelement<>nil;
  miAddToAddresslist.Visible:=structelement<>nil;

  miRecalculateAddress.Visible:=(structelement<>nil) and (tvStructureView.selected.Level=1);

  n1.visible:=ownerstruct<>nil;
  n2.visible:=ownerstruct<>nil;

  N3.visible:=miRecalculateAddress.visible or miUpdateOffsets.visible;

  micopy.Visible:=structelement<>nil;
  mipaste.Visible:=structelement<>nil;
  n4.visible:=n3.visible and (miCopy.visible or mipaste.visible);

  c:=getFocusedColumn;
  n5.Visible:=(c<>nil) and c.canPopAddress;
  miBack.visible:=n5.Visible;
end;

procedure TfrmStructures2.miNewWindowClick(Sender: TObject);
begin
  with tfrmstructures2.create(application) do
  begin
    initialaddress:=MemoryBrowser.hexview.address; //self.getFocusedColumn.Address;
    show;
  end;
end;

procedure TfrmStructures2.miUpdateIntervalClick(Sender: TObject);
var interval: string;
begin
  interval:=inttostr(updatetimer.interval);
  if InputQuery(rsUpdateInterval, rsNewInterval+':', interval) then
  begin
    try
      updatetimer.interval:=strtoint(interval);
    except
    end;

    miUpdateInterval.caption:=rsUpdateInterval+': '+inttostr(
      updatetimer.interval);
  end;
end;

procedure TfrmStructures2.pnlGroupsClick(Sender: TObject);
begin

end;


procedure TfrmStructures2.Renamestructure1Click(Sender: TObject);
var newname: string;
begin
  if mainstruct<>nil then
  begin
    newname:=mainStruct.name;
    if InputQuery(rsSF2GiveTheNewNameForThisStructure, rsSF2StructureRename, newname) then
      mainStruct.name:=newname;
  end;
end;




procedure TfrmStructures2.tvStructureViewMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var i: integer;
  c: TStructColumn;
  n: TTreenode;
begin

  c:=getColumnAtXPos(x+tvStructureView.ScrolledLeft);
  if c<>nil then
    c.focus;

  if (button=mbRight) then //lazarus 32774: If rightclickselect is on it does not deselect other lines
  begin
    n:=tvStructureView.GetNodeAt(x,y);
    if n<>nil then
    begin



      if (not n.Selected) and (not n.MultiSelected) then
      begin
        //not yet selected
        if not ((ssShift in Shift) or (ssCtrl in Shift)) then
          tvStructureView.Items.SelectOnlyThis(n)
        else
          n.Selected:=true;
      end;


    end;
  end;
end;

function TfrmStructures2.getFocusedColumn: TStructColumn;
var i: integer;
begin
  if columncount=0 then exit(nil); //rare/impossible

  for i:=0 to columnCount-1 do
    if columns[i].Focused then
    begin
      result:=columns[i];
      exit;
    end;

  result:=columns[0]; //nothing found, so give the first column
end;


function TfrmStructures2.getColumnAtXPos(x: integer): TStructColumn;
var i: integer;
begin
  //find which header is clicked. This coincides with the form's structure list
  result:=nil;
  for i:=1 to HeaderControl1.Sections.count-1 do
    if inrange(x, HeaderControl1.Sections[i].Left, HeaderControl1.Sections[i].Right) then
    begin
      result:=columns[i-1];
      exit;
    end;
end;



procedure TfrmStructures2.updatetimerTimer(Sender: TObject);
begin
  //refresh the visible nodes
  RefreshVisibleNodes;
end;

procedure TfrmStructures2.miRecalculateAddressClick(Sender: TObject);
var s: string;
  n: TTreenode;
  e: boolean;
  a: string;
  oldaddress, newaddress: ptruint;
  offset: ptruint;
begin
  n:=tvStructureView.Selected;
  if (n<>nil) and (n.level=1) then //recalculate can only be done on the main structure
  begin
    oldaddress:=getAddressFromNode(n, getFocusedColumn, e);
    if not e then
    begin
      a:=inttohex(memorybrowser.hexview.address,8);
      if inputquery(rsRecalculateBaseOfStructure, rsGiveTheAddressOfThisElement, a) then
      begin
        newaddress:=StrToQWordEx('$'+a);
        offset:=newaddress-oldaddress;
        getFocusedColumn.Address:=getFocusedColumn.Address+offset;
      end;

    end;

  end;
end;

procedure TfrmStructures2.pnlGroupsResize(Sender: TObject);
begin

end;


procedure TfrmStructures2.miDeleteElementClick(Sender: TObject);
var elementlist: Tlist;
  e: TStructelement;

  struct: TDissectedStruct;
  i: integer;

  originalindex: integer;
begin
  //save the old selection pos
 { if tvStructureView.Selected<>nil then
    originalindex:=tvStructureView.Selected.AbsoluteIndex
  else    }
    originalindex:=-1;


  //fill the nodelist with all the selected entries that match the requirement: Same siblings only
  struct:=nil;
  elementlist:=tlist.create;
  try
    for i:=0 to tvStructureView.SelectionCount-1 do
    begin
      if originalindex=-1 then
        originalindex:=tvStructureView.Selections[i].AbsoluteIndex;

      originalindex:=min(tvStructureView.Selections[i].AbsoluteIndex, originalindex);

      e:=getStructElementFromNode(tvStructureView.Selections[i]);
      if (e<>nil) and ((struct=nil) or (e.parent=struct))  then //the element can be null if it's the origin
      begin
        if struct=nil then
          struct:=e.parent;

        elementlist.add(e);
      end;
    end;

    //now delete the entries in the list (if there are any)
    if struct<>nil then
    begin
      struct.beginUpdate;
      try
        for i:=0 to elementlist.count-1 do
          struct.removeElement(TStructelement(elementlist[i]));

      finally
        struct.endUpdate;

        if (not struct.isInGlobalStructList) and (struct.count=0) then
          struct.free;
      end;
    end;

  finally
    elementlist.free;
  end;

  //restore the selection pos
  if originalindex>=0 then
  begin
    tvStructureView.Items.SelectOnlyThis(tvStructureView.Items[min(tvStructureView.items.count-1, originalindex)]);
  end;

end;

function TfrmStructures2.addColumn: TStructColumn;
var c: TStructColumn;
begin
  result:=nil;
  if groupcount=0 then
    TStructGroup.create(self,rsSF2Group1);

  c:=getFocusedColumn;
  if c=nil then
    result:=TStructColumn.create(group[0])
  else
    result:=TStructColumn.create(c.parent);

  SetupFirstNodeLength;
  RefreshVisibleNodes;
end;

procedure TfrmStructures2.removeColumn(columnid: integer);
begin
  columns[columnid].free;
  SetupFirstNodeLength;
  RefreshVisibleNodes;
end;

procedure TfrmStructures2.Addextraaddress1Click(Sender: TObject);
begin
  addColumn;
end;

procedure TfrmStructures2.FindDialog1Find(Sender: TObject);
var i: integer;
  n: ttreenode;
begin
  i:=searchString(FindDialog1.FindText, finddialog1.Options);
  if i<>-1 then
  begin
    n:=tvStructureView.Items[i];
    tvStructureView.Items.SelectOnlyThis(n);
    n.MakeVisible;
  end;
end;



function TfrmStructures2.searchString(search: string; findoptions: TFindOptions): integer;
{
Searches the current list for the specified value
}
var i,j: integer;
  se: TStructelement;
  c: TStructColumn;
  s,s2: string;
  node: TTreenode;
  cc: integer;

  casesensitive: boolean;
begin
  result:=-1;

  casesensitive:=frMatchCase in findoptions;

  if not casesensitive then
    search:=uppercase(search);

  if tvStructureView.Selected<>nil then
    i:=tvStructureView.Selected.AbsoluteIndex
  else
    i:=-1;

  if frDown in findoptions then
    i:=i+1
  else
    i:=i-1;


  while (i>0) and (i<tvStructureView.Items.Count) do
  begin
    node:=tvStructureView.Items[i];
    se:=getStructElementFromNode(node);

    if se<>nil then
    begin

      s:=se.Name;



      setCurrentNodeStringsInColumns(node,se);

      //column now contains the strings
      cc:=columnCount;
      for j:=0 to columnCount-1 do
      begin
        c:=columns[j];
        s:=s+c.currentNodeValue;
      end;

      if not casesensitive then
        s:=uppercase(s);

      if pos(search,s)>0 then //fouind a match
      begin
        result:=i;
        exit;
      end;
    end;


    if frDown in findoptions then
      i:=i+1
    else
      i:=i-1;

  end;

  beep;



end;


procedure TfrmStructures2.getValues(f: Tstrings);
var i,j: integer;
  se: TStructelement;
  c: TStructColumn;
  s,s2: string;
  node: TTreenode;
  cc: integer;
begin
  f.clear;

  s:='Offset-Description';
  s:=padright(s,25);
  for j:=0 to columncount-1 do
  begin
    if miShowAddresses.checked then
      s:=s+PadRight(columns[j].Name,30)
    else
      s:=s+PadRight(columns[j].Name,20);
  end;

  f.add(s);


  for i:=1 to tvStructureView.Items.Count-1 do
  begin
    node:=tvStructureView.Items[i];
    se:=getStructElementFromNode(node);

    if se<>nil then
    begin
      s:=getDisplayedDescription(se);
      s:=PadRight(S, 25);

      for j:=1 to node.level-1 do
        s:=AddChar('-',S,length(s)+5);

      setCurrentNodeStringsInColumns(node,se);

      //column now contains the strings
      cc:=columnCount;
      for j:=0 to columnCount-1 do
      begin
        c:=columns[j];

        if miShowAddresses.checked then
        begin
          s2:=PadRight(c.currentNodeAddress+c.currentNodeValue,30);

          if j<cc-1 then //not the last column
            setlength(s2,30); //cut of excess
        end
        else
        begin
          s2:=PadRight(c.currentNodeValue,20);
          if j<cc-1 then
            setlength(s2,20);
        end;



        s:=s+s2;
      end;
    end;

    f.add(s);
  end;
end;

procedure TfrmStructures2.MenuItem3Click(Sender: TObject);
var
  f: TStringList;
begin

  if saveValues.execute then
  begin
    f:=tstringlist.create;
    getValues(f);
    f.SaveToFile(saveValues.FileName);
    f.free;
  end;
end;

procedure TfrmStructures2.MenuItem5Click(Sender: TObject);
var s: string;
  g: Tstructgroup;
begin
  s:=rsSF2Group+inttostr(groupcount+1);
  if InputQuery(rsSF2NameForThisGroup,rsFS2StructureDefine, s) then
  begin
    g:=TStructGroup.create(self, s);

    //add the first address as well
    TStructColumn.create(g);
  end;
end;

procedure TfrmStructures2.MenuItem6Click(Sender: TObject);
begin
  finddialog1.Execute;
end;

procedure TfrmStructures2.miBackClick(Sender: TObject);
var c: TStructColumn;
begin
  c:=getFocusedColumn;
  if c<>nil then c.popAddress;
end;



procedure TfrmStructures2.expandtree(all: boolean);
var
  i: integer;
  maxlevel: integer;
begin
  tvStructureView.BeginUpdate;
  try
    if mainstruct<>nil then
    begin
      maxlevel:=frmStructuresConfig.maxautoexpandlevel+1;
      i:=1;
      while i<tvStructureView.Items.Count do
      begin
        if tvStructureView.Items[i].HasChildren and (tvStructureView.Items[i].Level<maxlevel) and (all or (getStructElementFromNode(tvStructureView.Items[i]).ChildStruct<>nil)) then
          tvStructureView.Items[i].Expand(false);

        inc(i);
      end;

    end;
  finally
    tvStructureView.EndUpdate;
  end;
end;

procedure TfrmStructures2.miExpandAllDefinedClick(Sender: TObject);
begin
  expandtree(false);
end;

procedure TfrmStructures2.miExpandAllClick(Sender: TObject);
begin
  expandtree(true);
end;

procedure TfrmStructures2.miClearClick(Sender: TObject);
begin
  if MessageDlg(rsSF2AreYouSureYouWantToDeleteAllTheDefinedStructures, mtWarning, [mbyes, mbno],0)=mryes then
  begin
    if mainstruct<>nil then //this one first
    begin
      mainstruct.free;
      mainstruct:=nil;
    end;

    while DissectedStructs.Count>0 do
      TDissectedStruct(DissectedStructs[0]).free;
  end;
end;

procedure TfrmStructures2.miPasteClick(Sender: TObject);
var
  baseoffset: dword; //startoffset to start appending from  (currently selected+size)
  doc: TXMLDocument;
  elementnodes: TDOMElement;
  i,j,k: integer;
  e: TStructelement;
  firstoffset: dword;
  ss: Tstringstream;

  struct: TDissectedStruct;

  pathtobase: array of integer; //since the parent treenode might collapse if it's a pointer to itself...
  n: TTreenode;
  isroot: boolean;
begin
  isroot:=false;
  if (mainstruct<>nil) and (tvStructureView.Selected<>nil) then
  begin
    e:=getStructElementFromNode(tvStructureView.Selected);
    struct:=getStructFromNode(tvStructureView.Selected);

    setlength(pathtobase,0);
    n:=tvStructureView.Selected.parent;
    if n<>nil then
    begin
      while n.parent<>nil do
      begin
        setlength(pathtobase, length(pathtobase)+1);
        pathtobase[length(pathtobase)-1]:=n.Index;
        n:=n.parent;
      end;
    end
    else
    begin
      //root
      isroot:=true;
    end;



    if isroot or ((e<>nil) and (struct<>nil)) then
    begin
      if isroot then
        baseoffset:=0
      else
        baseoffset:=e.Offset+e.Bytesize;

      doc:=nil;
      ss:=TStringStream.create(clipboard.AsText);
      try
        try
          ReadXMLFile(doc, ss);
          if doc<>nil then
          begin
            elementnodes:=TDOMElement(doc.FindNode('Elements'));
            if elementnodes<>nil then
            begin
              struct.beginUpdate;
              for i:=0 to elementnodes.ChildNodes.Count-1 do
              begin
                e:=TStructelement.createFromXMLElement(struct, TDOMElement(elementnodes.ChildNodes[i]));
                if i=0 then firstoffset:=e.Offset;

                e.offset:=baseoffset+(e.offset-firstoffset);
                struct.structelementlist.Add(e);
              end;
              struct.sortElements;
              struct.endUpdate;
              struct.fillDelayLoadedChildstructs;
            end;

            doc.free;
          end;

          //select the last added element
          i:=struct.getIndexOfOffset(e.offset);
          n:=tvStructureView.Items.GetFirstNode;

          //open the path if it was closed
          for j:=length(pathtobase)-1 downto 0 do
          begin
            k:=pathtobase[j];
            if k<n.Count then
            begin
              if n.Items[k].HasChildren then
              begin
                n.Items[k].Expanded:=true;
                n:=n.items[k];
              end
              else
                exit; //give up
            end;
          end;

          tvStructureView.Items.SelectOnlyThis(n.items[i]);
        except
        end;
      finally
        ss.free;
      end;

    end;
  end;



end;

procedure TfrmStructures2.miCopyClick(Sender: TObject);
var
  doc: TXMLDocument;
  elementnodes: TDOMElement;
  i: integer;
  se: TStructelement;
  ms: TStringStream;
begin
  if mainstruct<>nil then
  begin
    doc:=TXMLDocument.Create;
    elementnodes:=TDOMElement(doc.AppendChild(TDOMNode(doc.CreateElement('Elements'))));

    for i:=0 to tvStructureView.SelectionCount-1 do
    begin
      se:=getStructElementFromNode(tvStructureView.Selections[i]);
      if se<>nil then
        se.WriteToXMLNode(elementnodes);
    end;


    ms:=TStringStream.create('');
    WriteXML(elementnodes, ms);

    Clipboard.AsText:=ms.DataString;
    ms.free;

    doc.Free;
  end;
end;

procedure TfrmStructures2.miExportAllClick(Sender: TObject);
var
  doc: TXMLDocument;
  structnode: TDOMNode;
  i: integer;
begin
  if Savedialog1.Execute then
  begin
    doc:=TXMLDocument.Create;
    structnode:=TDOMElement(doc.AppendChild(TDOMNode(doc.CreateElement('Structures'))));

    for i:=0 to DissectedStructs.Count-1 do
      TDissectedStruct(DissectedStructs[i]).WriteToXMLNode(structnode);

    WriteXML(structnode, savedialog1.filename);

    doc.Free;
  end;
end;


procedure TfrmStructures2.miGenerateGroupscanClick(Sender: TObject);
var gcf: TfrmGroupScanAlgoritmGenerator;
  previous, e: TStructelement;
  n: TTreeNode;
  err: boolean;
  address: ptruint;
  i,j: integer;
begin
  if mainstruct<>nil then
  begin
    gcf:=TfrmGroupScanAlgoritmGenerator.create(self);

    //fill the algoritm with what is currently selected

    for i:=0 to tvStructureView.items.Count-1 do //find the first selected element
    begin
      if tvStructureView.items[i].MultiSelected or tvStructureView.items[i].Selected then
      begin
        //found the first element, from here, add all selected siblings and fill in wildcards
        n:=tvStructureView.items[i];
        previous:=nil;
        while n<>nil do
        begin

          if n.MultiSelected or n.Selected then
          begin
            e:=getStructElementFromNode(n);
            if (e<>nil) then
            begin
              //add this element (if it's a valid type)
              if e.vartype in [vtByte..vtDouble, vtstring, vtunicodestring, vtCustom, vtPointer] then
              begin
                //get the address
                address:=getAddressFromNode(n, getFocusedColumn, err);
                if not err then
                begin
                  //everything ok, add it
                  if previous<>nil then //Fill gaps with the previous element
                  begin

                    j:=e.Offset-(previous.Offset+previous.Bytesize);   //get the number of bytes to fill
                    if j>0 then
                      gcf.addwildcard(j);
                  end;


                  gcf.AddLine(e.VarType, e.CustomType, e.getValue(address, true));
                  previous:=e;
                end;
              end;
            end;
          end;
          n:=n.GetNextSibling;
        end;

        //    gcf.addByte(value)

        break;
      end;

    end;

    if gcf.showmodal=mrok then
    begin
      if (mainform.VarType.enabled) or (mainform.getVarType=vtGrouped) then
      begin
        if mainform.getVarType<>vtGrouped then
          mainform.setVarType(vtGrouped);

        mainform.scanvalue.text:=gcf.getparameters;
      end
      else
        showmessage(rsSF2TheGroupscanCommandHasBeenCopiedToTheClipboard);

      clipboard.astext:=gcf.getparameters;


    end;

    gcf.free;

  end;
end;

procedure TfrmStructures2.miAutoCreateClick(Sender: TObject);
begin
  if mainstruct<>nil then
    mainStruct.AutoCreate:=not mainstruct.AutoCreate;
end;

procedure TfrmStructures2.miAutoDestroyLocalClick(Sender: TObject);
begin
  if mainstruct<>nil then
    mainstruct.AutoDestroy:=not mainstruct.AutoDestroy;
end;

procedure TfrmStructures2.miAutoFillGapsClick(Sender: TObject);
begin
  if mainstruct<>nil then
    mainstruct.AutoFill:=not mainstruct.AutoFill;
end;

procedure TfrmStructures2.miChangeValueClick(Sender: TObject);
begin
  EditValueOfSelectedNodes(getFocusedColumn);
end;

procedure TfrmStructures2.miBrowseAddressClick(Sender: TObject);
var
  n: ttreenode;
  a: ptruint;
  error: boolean;
  x: dword;
begin
  n:=tvStructureView.Selected;
  if n<>nil then
  begin
    a:=getAddressFromNode(n, getFocusedColumn, error);

    if not error then
      MemoryBrowser.hexview.address:=a;
  end;
end;

procedure TfrmStructures2.miBrowsePointerClick(Sender: TObject);
var
  n: ttreenode;
  a: ptruint;
  error: boolean;
  x: ptruint;
  c: TStructColumn;
  savedstate: ptruint;
begin
  n:=tvStructureView.Selected;
  if n<>nil then
  begin
    c:=getFocusedColumn;
    a:=getAddressFromNode(n, c, error);

    savedstate:=ptruint(c.getSavedState);

    if (savedstate<>0) and (InRangeX(a, c.Address, c.address+ c.getSavedStateSize)) then
       a:=a+(savedstate-c.address);



    if not error then
    begin
      //get the address this address points to
      if ReadProcessMemory(processhandle, pointer(a), @a, processhandler.pointersize, x) and (x=processhandler.pointersize) then
        MemoryBrowser.hexview.address:=a;
    end;
  end;
end;


procedure TfrmStructures2.miAddToAddresslistClick(Sender: TObject);
var baseaddress: ptruint;
  offsetlist: array of integer;
  element, element2: TStructelement;

  sname: string;
  n: ttreenode;
  name: string;

  i: integer;
begin
//  n:=tvStructureView.Selected;

  for i:=0 to tvStructureView.SelectionCount-1 do
  begin
    n:=tvStructureView.Selections[i];

    if n<>nil then
    begin
      element:=getStructElementFromNode(n);
      if element<>nil then
      begin
        baseaddress:=0;
        getPointerFromNode(n, getFocusedColumn, baseaddress, offsetlist);
        if baseaddress<>0 then
        begin
          //add this baseaddress with it's offsetlist to the addresslist

          sname:=element.Name;
          while (n<>nil) and (n.level>=1) do
          begin
            element2:=getStructElementFromNode(n);
            if element2<>nil then
              sname:=element.name+'->'+sname;

            n:=n.parent;
          end;

          name:=element.Name;
          if name='' then
            name:=VariableTypeToString(element.VarType);

          mainform.addresslist.addaddress(name, inttohex(baseaddress,1), offsetlist, length(offsetlist), element.VarType,'',element.Bytesize);
        end;


      end;


      //mainform.a
    end;

  end;
end;

procedure TfrmStructures2.Deletecurrentstructure1Click(Sender: TObject);
begin
  if mainstruct<>nil then
  begin
    if messagedlg(rsSF2AreYouSureYouWantToDeleteTheStructureNamed+mainstruct.structname+' ?', mtConfirmation, [mbyes,mbno],0) = mryes then
    begin
      mainstruct.free;
      mainstruct:=nil; //should happen automatically thanks to the destroy procedure of the struct
    end;
  end;
end;

procedure TfrmStructures2.miAutoGuessClick(Sender: TObject);
var
  sStartOffset: string;
  sStructSize: string;
  //base: TbaseStructure;
  startOffset: integer;
  structSize: integer;
begin
  if mainStruct<>nil then
  begin
    sStartOffset:=inttohex(mainstruct.structuresize,1);
    if not inputquery(rsStructureDefine, rsPleaseGiveAStartingOffsetToEvaluate, sStartOffset) then exit;
    startOffset:=StrToInt('$'+sStartOffset);

    sStructSize:='4096';
    if not inputquery(rsStructureDefine, rsPleaseGiveTheSizeOfTheBlockToEvaluate, sStructSize) then exit;
    structSize:=StrToInt(sStructSize);


    mainStruct.autoGuessStruct(getFocusedColumn.Address+startOffset, startOffset, structsize);
  end;
end;

procedure TfrmStructures2.miAutostructsizeClick(Sender: TObject);
var newsize: string;
begin
  if mainstruct<>nil then
  begin
    newsize:=inttostr(mainstruct.autoCreateStructsize);
    if InputQuery(rsSF2AutocreateStructure, rsSF2DefaultSize, newsize) then
      mainstruct.autoCreateStructsize:=strtoint(newsize);
  end;
end;

procedure TfrmStructures2.setupColors;
begin
  fDefaultColor:=frmStructuresConfig.defaultText;
  fMatchColor:=frmStructuresConfig.equalText;
  fNoMatchColor:=frmStructuresConfig.differentText;
  fAllMatchColorSame:=frmStructuresConfig.groupequalText;
  fAllMatchColorDiff:=frmStructuresConfig.groupDifferentText;


  fDefaultColorHighlighted:=frmStructuresConfig.selecteddefaultText;
  fMatchColorHighlighted:=frmStructuresConfig.selectedequalText;
  fNoMatchColorHighlighted:=frmStructuresConfig.selecteddifferentText;
  fAllMatchColorSameHighlighted:=frmStructuresConfig.selectedgroupequalText;
  fAllMatchColorDiffHighlighted:=frmStructuresConfig.selectedgroupDifferentText;
end;

procedure TfrmStructures2.UpdateCurrentStructOptions;
begin
  if mainStruct<>nil then
  begin
    miAutoCreate.Checked:=mainstruct.AutoCreate;
    miAutostructsize.caption:=rsSF2AutocreateStructureSize+inttostr(mainstruct.autoCreateStructsize);
    miAutoDestroyLocal.Checked:=mainstruct.AutoDestroy;
    miDoNotSaveLocal.checked:=mainstruct.DoNotSaveLocal;
    miAutoFillGaps.Checked:=mainStruct.AutoFill;
    miDefaultHexadecimal.checked:=mainstruct.DefaultHex;
    miRLECompression.checked:=mainstruct.RLECompression;

    caption:=rsStructureDissect+':'+mainStruct.name;
  end
  else
    caption:=rsStructureDissect;
end;


procedure TfrmStructures2.miChangeColorsClick(Sender: TObject);
begin
  //show and wait for the user
  frmStructuresConfig.groupbox1.Font.assign(tvStructureView.Font);

  if frmStructuresConfig.showmodal=mrok then
  begin
    //just apply new colors
    setupColors; //gets the colors from the structures config


    //and show the new colors
    RefreshVisibleNodes;

    tvStructureView.Font.Assign(frmStructuresConfig.groupbox1.Font);
  end;
end;

procedure TfrmStructures2.miDefaultHexadecimalClick(Sender: TObject);
begin
  if mainstruct<>nil then
    mainstruct.DefaultHex:=not mainstruct.DefaultHex;
end;

procedure TfrmStructures2.miRLECompressionClick(Sender: TObject);
begin
  if mainstruct<>nil then
    mainstruct.RLECompression:=not mainstruct.RLECompression;
end;



procedure TfrmStructures2.miDoNotSaveLocalClick(Sender: TObject);
begin
  if mainstruct<>nil then
    mainstruct.DoNotSaveLocal:=not mainstruct.DoNotSaveLocal;
end;

procedure TfrmStructures2.miFillGapsClick(Sender: TObject);
begin

  if mainstruct<>nil then
    mainstruct.fillGaps(getFocusedColumn.address, true);

end;



procedure TfrmStructures2.miFullUpgradeClick(Sender: TObject);
var
  struct: TDissectedStruct;
  f: TfrmStructures2;
  a,p: ptruint;

  node: TTreenode;
  e: boolean;
  x: ptruint;

  se: TStructelement;
begin
  struct:=getChildStructFromNode(tvStructureView.Selected);
  if struct<>nil then
    struct.addToGlobalStructList
  else
  begin
    //create a new structure from this entry
    node:=tvStructureView.Selected;
    if node=nil then exit;

    a:=getAddressFromNode(node, getFocusedColumn, e);
    if not e then
    begin
      p:=0;
      x:=0;
      ReadProcessMemory(processhandle, pointer(a), @p, ProcessHandler.pointersize, x);
      if x=ProcessHandler.pointersize then
      begin
        if p=0 then exit;

        f:=tfrmstructures2.create(application);
        f.initialaddress:=p;
        f.show;
        struct:=f.DefineNewStructure(4096);

        se:=getStructElementFromNode(node);
        if se<>nil then
          se.ChildStruct:=struct;

      end;
    end;
  end;

end;

procedure TfrmStructures2.miSelectStructureClick(Sender: tobject);
//a structure has been selected from the menu. Handle it
begin
  mainStruct:=TdissectedStruct(TmenuItem(sender).Tag);

  InitializeFirstNode;
  UpdateCurrentStructOptions;
end;

procedure TfrmStructures2.RefreshStructureList;
var
  i: integer;
  s: string;
  mi: TMenuItem;
begin
  while structures1.count>2 do
    Structures1.Delete(2);

  for i:=0 to DissectedStructs.count-1 do
  begin
    s:=TDissectedStruct(DissectedStructs[i]).structname;
    mi:=tmenuitem.Create(Structures1);
    mi.Caption:=s;
    mi.OnClick:=miSelectStructureClick;
    mi.Tag:=ptruint(DissectedStructs[i]);
    mi.RadioItem:=true;
    mi.AutoCheck:=true;
    mi.Checked:=mainStruct=TDissectedStruct(DissectedStructs[i]);
    Structures1.Add(mi);
  end;
end;

procedure TfrmStructures2.setMainStruct(struct: TDissectedStruct);
begin
  fmainStruct:=struct;

  if struct=nil then
    tvStructureView.Items.Clear;

  miCommands.Enabled:=struct<>nil;
end;

function TfrmStructures2.getColumn(i: integer): TStructColumn;
//look through the groups to find this column
var j,c: integer;
begin
  result:=nil;
  c:=0;
  for j:=0 to groupcount-1 do
  begin
    if c+group[j].columnCount>i then
    begin
      result:=TStructColumn(group[j].columns[i-c]);
      exit;
    end
    else
      inc(c,group[j].columnCount);
  end;
end;


function TfrmStructures2.getColumnCount: integer;
var i: integer;
begin
  result:=0;
  for i:=0 to groupcount-1 do
    inc(result, group[i].columncount);
end;

function TfrmStructures2.getGroup(i: integer): TStructGroup;
begin
  result:=TStructGroup(fgroups[i]);
end;

function TfrmStructures2.getGroupCount: integer;
begin
  result:=fgroups.count;
end;

function TfrmStructures2.getDisplayedDescription(se: TStructelement): string;
var description, varname: string;
begin
  result:='';
  if se=nil then exit;

  if (se.name='') and (miShowTypeForEntriesWithNoDescription.checked) then
  begin
    if se.vartype=vtCustom then
    begin
      if se.CustomType<>nil then
        varname:=se.CustomType.name
      else
        varname:=rsSF2UnknownCustomType;
    end
    else
      varname:=VariableTypeToString(se.VarType);

    description:=inttohex(se.Offset,4)+' - '+varname;

    //show nondefault displaymethods
    case se.DisplayMethod of
      dtHexadecimal: description:=description+rsSF2Hex;
      dtSignedInteger: description:=description+rsSF2Signed;
    end;

    if (se.VarType=vtPointer) and (se.ChildStruct<>nil) then
    begin
      description:=description+rsSF2To+se.ChildStruct.name;
      if se.ChildStructStart<>0 then
        description:=description+'+'+inttohex(se.ChildStructStart,1);
    end;
  end
  else
    description:=inttohex(se.Offset,4)+' - '+se.Name;

  result:=description;
end;

procedure TfrmStructures2.tvStructureViewAdvancedCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode;
  State: TCustomDrawState; Stage: TCustomDrawStage; var PaintImages, DefaultDraw: Boolean);
var
  textrect: trect;
  linerect: trect;

  textlinerect: trect;
  fulltextline: trect;

  clip: TRect;

  se, se2: TStructelement;
  description: string;
  s: string;

  c: TStructColumn;
  i: integer;
  selected: boolean;

  nodescription: boolean; //if set render the description using a lighter color
  r,g,b: byte;

  displacement: integer;
  //varname: string;


begin
  if mainstruct=nil then exit; //no rendering


  if stage=cdPrePaint then
  begin
    se:=getStructElementFromNode(node);
    if se<>nil then
      sender.BackgroundColor:=se.backgroundColor;
  end;




  if stage=cdPostPaint then
  begin


    textrect:=node.DisplayRect(true);
    linerect:=node.DisplayRect(false);

    fulltextline:=linerect;
    fulltextline.Left:=textrect.Left;
    fulltextline.Right:=tvStructureView.ClientWidth;

    //get the next text
    se:=getStructElementFromNode(node);

    nodescription:=(se<>nil) and (se.name='');
    if (se=nil) then
      description:=mainstruct.name
    else
      description:=getDisplayedDescription(se);

    selected:=(cdsSelected in State) or (cdsMarked in state);
    setCurrentNodeStringsInColumns(node,se,selected);


    //draw an empty line.
    textlinerect.left:=textrect.left;
    textlinerect.Top:=linerect.Top;
    textlinerect.Right:=max(tvStructureView.clientwidth, headercontrol1.left+headercontrol1.Sections.Items[headercontrol1.Sections.Count-1].Left+headercontrol1.Sections.Items[headercontrol1.Sections.Count-1].Width);
    textlinerect.Bottom:=linerect.Bottom;
    if textlinerect.right<textlinerect.left then
      textlinerect.right:=textlinerect.left;


    //draw the description
    clip:=textrect;
    clip.Right:=headercontrol1.left+headercontrol1.Sections[0].Left+headercontrol1.Sections[0].Width;


    if selected then
      sender.Canvas.Font.Color:=fDefaultColorHighlighted
    else
      sender.Canvas.Font.Color:=fDefaultColor;

    if nodescription then
    begin        //blatantly stolen from DecColor   (why the fuck is there no incColor ?)
      RedGreenBlue(ColorToRGB(sender.Canvas.Font.Color), R, G, B);
      R := Max(0, Integer(R) + 75);
      G := Max(0, Integer(G) + 75);
      B := Max(0, Integer(B) + 75);
      sender.Canvas.Font.Color := RGBToColor(R, G, B);
    end;


    sender.Canvas.Refresh;
    sender.Canvas.TextRect(clip,textrect.Left,textrect.Top,description);

    //draw the columns
    for i:=0 to columnCount-1 do
    begin
      c:=columns[i];
      clip.left:=headercontrol1.left+headercontrol1.Sections[i+1].Left;
      clip.right:=headercontrol1.left+headercontrol1.Sections[i+1].Right;

      sender.canvas.font.Color:=c.currentNodeColor;

      sender.Canvas.Refresh;


      if miShowAddresses.checked then
        s:=c.currentNodeAddress
      else
        s:='';

      s:=s+c.currentNodeValue;
      sender.Canvas.TextRect(clip,clip.left,textrect.Top,s);
    end;

    sender.BackgroundColor:=clWindow;
  end;
  DefaultDraw:=true;
end;

procedure TfrmStructures2.EditValueOfSelectedNodes(c:TStructColumn);
var a: PtrUInt;
  error: boolean;
  se: Tstructelement;
  node: TTreeNode;
  i: integer;
  s: string;
  savedstate: PtrUInt;
begin
  node:=tvStructureView.Selected;
  if node=nil then exit;

  se:=getStructElementFromNode(node);
  if se<>nil then
  begin
    a:=getAddressFromNode(node, c, error);

    if not error then
    begin
      //show the change value dialog
      s:=se.getValue(a);
      if InputQuery(rsSF2ChangeValue,rsSF2NewValueForThisAddress, s) then
      begin
        //try setting the value
        for i:=0 to tvStructureView.SelectionCount-1 do
        begin
          se:=getStructElementFromNode(tvStructureView.Selections[i]);
          a:=getAddressFromNode(tvStructureView.Selections[i], c, error);


{
displayaddress:=getAddressFromNode(node, columns[i], error);  //get the address to show the user

savedstate:=ptruint(c.getSavedState);
address:=displayaddress;

if (savedstate<>0) and (InRangeX(address, c.Address, c.address+ c.getSavedStateSize)) then
  address:=address+(savedstate-c.address);

}


          if not error then
          begin
            savedstate:=ptruint(c.getSavedState);
            if (savedstate<>0) and (InRangeX(a, c.Address, c.address+ c.getSavedStateSize)) then
              a:=a+(savedstate-c.address);

            se.setvalue(a, s); //I knew there was a reason I implemented this
          end;
        end;
      end;
    end;
  end;
end;

procedure TfrmStructures2.tvStructureViewDblClick(Sender: TObject);
var
  m: TPoint;
  c: TStructColumn;
begin
  //if first column is doubleclicked edit the type, else edit the value
  m:=mouse.CursorPos;
  m:=tvStructureView.ScreenToClient(m);
  c:=getColumnAtXPos(m.x+tvStructureView.ScrolledLeft);

  if c=nil then
    miChangeElementClick(miChangeElement)
  else
    EditValueOfSelectedNodes(c);
end;

procedure TfrmStructures2.miFindRelationsClick(Sender: TObject);
var sl: TfrmStructureLinker;
begin
  //show the "find Relations" form where the user can fill in known addresses for structures
  //the structures will then check each pointer and fill them in

  sl:=TfrmStructureLinker.Create(self);
  sl.ShowModal;
  sl.free;

end;

procedure TfrmStructures2.addLockedAddress(shownaddress: ptruint; memoryblock: pointer; size: integer);
begin
  //add a column and lock it with the given state


  addColumn.LockAddress(shownaddress, memoryblock, size);




end;

procedure TfrmStructures2.FixPositions;
var
  maxh: integer;
  i,j, h: integer;
begin
  {
  maxh:=0;

  //first get the height needed
  for i:=0 to groupcount-1 do
  begin
    for j:=0 to group[i].columnCount-1 do
    begin
      h:=group[i].columns[j].edtAddress.height;
      if group[i].columns[j].lblName.caption<>'' then
        inc(h, group[i].columns[j].lblName.height);

      maxh:=max(maxh, h);
    end;
  end;

  inc(maxh, 3);

  for i:=0 to groupcount-1 do
    group[i].GroupBox.ClientHeight:=maxh;



  for i:=0 to groupcount-1 do
  begin
    //update the editboxes inside each group
    for j:=0 to group[i].columnCount-1 do
      group[i].columns[j].SetProperEditboxPosition;

    //and then update the groupbox to fit in he grouppanel and right size
    //set the left position
    if i=0 then
      group[i].box.Left:=3
    else
      group[i].box.Left:=group[i-1].box.Left+group[i-1].box.Width+10;

    //set the width
    if group[i].columnCount>0 then
      group[i].box.width:=group[i].columns[group[i].columnCount-1].EditLeft+group[i].columns[group[i].columnCount-1].EditWidth+10
    else
      group[i].box.width:=20;
  end;

  pnlGroups.ClientHeight:=group[0].GroupBox.top+group[0].GroupBox.Height+2;  }
end;

initialization
  DissectedStructs:=TList.create;
  frmStructures2:=tlist.Create;

end.
//add expandallnodes(maxlevel)
