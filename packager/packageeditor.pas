{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

  Author: Mattias Gaertner

  Abstract:
    TPackageEditorForm is the form of a package editor.

  ToDo:
    - Multiselect
    CallRegisterProcCheckBox,
    DisableI18NForLFMCheckBox
    replace GetCurrentDependency
    replace GetCurrentFile
}
unit PackageEditor;

{$mode objfpc}{$H+}

interface

uses
  // LCL FCL
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, Buttons, Graphics,
  LCLType, LCLProc, Menus, Dialogs, FileUtil, LazFileCache,
  contnrs,
  // IDEIntf CodeTools
  IDEImagesIntf, MenuIntf, ExtCtrls, LazIDEIntf, ProjectIntf,
  CodeToolsStructs, FormEditingIntf, TreeFilterEdit, PackageIntf,
  IDEDialogs, IDEHelpIntf, IDEOptionsIntf, IDEProcs, LazarusIDEStrConsts,
  IDEDefs, CompilerOptions, ComponentReg, EnvironmentOpts,
  PackageDefs, AddToPackageDlg, PkgVirtualUnitEditor,
  MissingPkgFilesDlg, PackageSystem, CleanPkgDeps;
  
const
  PackageEditorMenuRootName = 'PackageEditor';
  PackageEditorMenuFilesRootName = 'PackageEditorFiles';
  PackageEditorWindowPrefix = 'PackageEditor_';
var
  // single file
  PkgEditMenuOpenFile: TIDEMenuCommand;
  PkgEditMenuRemoveFile: TIDEMenuCommand;
  PkgEditMenuReAddFile: TIDEMenuCommand;
  PkgEditMenuEditVirtualUnit: TIDEMenuCommand;
  PkgEditMenuSectionFileType: TIDEMenuSection;

  // directories
  PkgEditMenuExpandDirectory: TIDEMenuCommand;
  PkgEditMenuCollapseDirectory: TIDEMenuCommand;
  PkgEditMenuUseAllUnitsInDirectory: TIDEMenuCommand;
  PkgEditMenuUseNoUnitsInDirectory: TIDEMenuCommand;

  // dependencies
  PkgEditMenuOpenPackage: TIDEMenuCommand;
  PkgEditMenuRemoveDependency: TIDEMenuCommand;
  PkgEditMenuReAddDependency: TIDEMenuCommand;
  PkgEditMenuDependencyStoreFileNameAsDefault: TIDEMenuCommand;
  PkgEditMenuDependencyStoreFileNameAsPreferred: TIDEMenuCommand;
  PkgEditMenuDependencyClearStoredFileName: TIDEMenuCommand;
  PkgEditMenuCleanDependencies: TIDEMenuCommand;

  // multi files
  PkgEditMenuSortFiles: TIDEMenuCommand;
  PkgEditMenuFixFilesCase: TIDEMenuCommand;
  PkgEditMenuShowMissingFiles: TIDEMenuCommand;

  // package
  PkgEditMenuSave: TIDEMenuCommand;
  PkgEditMenuSaveAs: TIDEMenuCommand;
  PkgEditMenuRevert: TIDEMenuCommand;
  PkgEditMenuPublish: TIDEMenuCommand;

  // compile
  PkgEditMenuCompile: TIDEMenuCommand;
  PkgEditMenuRecompileClean: TIDEMenuCommand;
  PkgEditMenuRecompileAllRequired: TIDEMenuCommand;
  PkgEditMenuCreateMakefile: TIDEMenuCommand;
  PkgEditMenuCreateFpmakeFile: TIDEMenuCommand;
  PkgEditMenuViewPackageSource: TIDEMenuCommand;

type
  TOnCreatePkgMakefile =
    function(Sender: TObject; APackage: TLazPackage): TModalResult of object;
  TOnCreatePkgFpmakeFile =
    function(Sender: TObject; APackage: TLazPackage): TModalResult of object;
  TOnOpenFile =
    function(Sender: TObject; const Filename: string): TModalResult of object;
  TOnOpenPkgFile =
    function(Sender: TObject; PkgFile: TPkgFile): TModalResult of object;
  TOnOpenPackage =
    function(Sender: TObject; APackage: TLazPackage): TModalResult of object;
  TOnSavePackage =
    function(Sender: TObject; APackage: TLazPackage;
             SaveAs: boolean): TModalResult of object;
  TOnRevertPackage =
    function(Sender: TObject; APackage: TLazPackage): TModalResult of object;
  TOnPublishPackage =
    function(Sender: TObject; APackage: TLazPackage): TModalResult of object;
  TOnCompilePackage =
    function(Sender: TObject; APackage: TLazPackage;
             CompileClean, CompileRequired: boolean): TModalResult of object;
  TOnAddPkgToProject =
    function(Sender: TObject; APackage: TLazPackage;
             OnlyTestIfPossible: boolean): TModalResult of object;
  TOnInstallPackage =
    function(Sender: TObject; APackage: TLazPackage): TModalResult of object;
  TOnUninstallPackage =
    function(Sender: TObject; APackage: TLazPackage): TModalResult of object;
  TOnViewPackageSource =
    function(Sender: TObject; APackage: TLazPackage): TModalResult of object;
  TOnViewPackageToDos =
    function(Sender: TObject; APackage: TLazPackage): TModalResult of object;
  TOnCreateNewPkgFile =
    function(Sender: TObject; Params: TAddToPkgResult): TModalResult  of object;
  TOnDeleteAmbiguousFiles =
    function(Sender: TObject; APackage: TLazPackage;
             const Filename: string): TModalResult of object;
  TOnFreePkgEditor = procedure(APackage: TLazPackage) of object;

  TPENodeType = (
    penFile,
    penDependency
    );

  { TPENodeData }

  TPENodeData = class(TTFENodeData)
  public
    Typ: TPENodeType;
    Name: string; // file or package name
    Removed: boolean;
    Next: TPENodeData;
    constructor Create(aTyp: TPENodeType; aName: string; aRemoved: boolean);
  end;

  TPEFlag = (
    pefNeedUpdateTitle,
    pefNeedUpdateButtons,
    pefNeedUpdateFiles,
    pefNeedUpdateRequiredPkgs,
    pefNeedUpdateProperties,
    pefNeedUpdateApplyDependencyButton,
    pefNeedUpdateStatusBar
    );
  TPEFlags = set of TPEFlag;

  { TPackageEditorForm }

  TPackageEditorForm = class(TBasePackageEditor)
    MoveDownBtn: TSpeedButton;
    MoveUpBtn: TSpeedButton;
    DirectoryHierarchyButton: TSpeedButton;
    OpenButton: TSpeedButton;
    DisableI18NForLFMCheckBox: TCheckBox;
    FilterEdit: TTreeFilterEdit;
    FilterPanel: TPanel;
    SortAlphabeticallyButton: TSpeedButton;
    Splitter1: TSplitter;
    // toolbar
    ToolBar: TToolBar;
    // toolbuttons
    SaveBitBtn: TToolButton;
    CompileBitBtn: TToolButton;
    UseBitBtn: TToolButton;
    AddBitBtn: TToolButton;
    RemoveBitBtn: TToolButton;
    OptionsBitBtn: TToolButton;
    MoreBitBtn: TToolButton;
    HelpBitBtn: TToolButton;
    // items
    ItemsTreeView: TTreeView;
    // properties
    PropsGroupBox: TGroupBox;
    // file properties
    CallRegisterProcCheckBox: TCheckBox;
    AddToUsesPkgSectionCheckBox: TCheckBox;
    RegisteredPluginsGroupBox: TGroupBox;
    RegisteredListBox: TListBox;
    // dependency properties
    UseMinVersionCheckBox: TCheckBox;
    MinVersionEdit: TEdit;
    UseMaxVersionCheckBox: TCheckBox;
    MaxVersionEdit: TEdit;
    ApplyDependencyButton: TButton;
    // statusbar
    StatusBar: TStatusBar;
    // hidden components
    UsePopupMenu: TPopupMenu;
    ItemsPopupMenu: TPopupMenu;
    MorePopupMenu: TPopupMenu;
    procedure AddBitBtnClick(Sender: TObject);
    procedure AddToProjectClick(Sender: TObject);
    procedure AddToUsesPkgSectionCheckBoxChange(Sender: TObject);
    procedure ApplyDependencyButtonClick(Sender: TObject);
    procedure CallRegisterProcCheckBoxChange(Sender: TObject);
    procedure ChangeFileTypeMenuItemClick(Sender: TObject);
    procedure CleanDependenciesMenuItemClick(Sender: TObject);
    procedure ClearDependencyFilenameMenuItemClick(Sender: TObject);
    procedure CollapseDirectoryMenuItemClick(Sender: TObject);
    procedure CompileAllCleanClick(Sender: TObject);
    procedure CompileBitBtnClick(Sender: TObject);
    procedure CompileCleanClick(Sender: TObject);
    procedure CreateMakefileClick(Sender: TObject);
    procedure CreateFpmakeFileClick(Sender: TObject);
    procedure DirectoryHierarchyButtonClick(Sender: TObject);
    procedure DisableI18NForLFMCheckBoxChange(Sender: TObject);
    procedure EditVirtualUnitMenuItemClick(Sender: TObject);
    procedure ExpandDirectoryMenuItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ItemsPopupMenuPopup(Sender: TObject);
    procedure ItemsTreeViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MorePopupMenuPopup(Sender: TObject);
    procedure ItemsTreeViewDblClick(Sender: TObject);
    procedure ItemsTreeViewSelectionChanged(Sender: TObject);
    procedure FixFilesCaseMenuItemClick(Sender: TObject);
    procedure HelpBitBtnClick(Sender: TObject);
    procedure InstallClick(Sender: TObject);
    procedure MaxVersionEditChange(Sender: TObject);
    procedure MinVersionEditChange(Sender: TObject);
    procedure MoveDownBtnClick(Sender: TObject);
    procedure MoveUpBtnClick(Sender: TObject);
    procedure OnIdle(Sender: TObject; var Done: Boolean);
    procedure OpenFileMenuItemClick(Sender: TObject);
    procedure OptionsBitBtnClick(Sender: TObject);
    procedure PackageEditorFormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure PackageEditorFormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure PublishClick(Sender: TObject);
    procedure ReAddMenuItemClick(Sender: TObject);
    procedure RegisteredListBoxDrawItem(Control: TWinControl; Index: Integer;
                                        ARect: TRect; State: TOwnerDrawState);
    procedure RemoveBitBtnClick(Sender: TObject);
    procedure RevertClick(Sender: TObject);
    procedure SaveAsClick(Sender: TObject);
    procedure SaveBitBtnClick(Sender: TObject);
    procedure SetDependencyDefaultFilenameMenuItemClick(Sender: TObject);
    procedure SetDependencyPreferredFilenameMenuItemClick(Sender: TObject);
    procedure ShowMissingFilesMenuItemClick(Sender: TObject);
    procedure SortAlphabeticallyButtonClick(Sender: TObject);
    procedure SortFilesMenuItemClick(Sender: TObject);
    procedure UninstallClick(Sender: TObject);
    procedure UseAllUnitsInDirectoryMenuItemClick(Sender: TObject);
    procedure UseMaxVersionCheckBoxChange(Sender: TObject);
    procedure UseMinVersionCheckBoxChange(Sender: TObject);
    procedure UseNoUnitsInDirectoryMenuItemClick(Sender: TObject);
    procedure UsePopupMenuPopup(Sender: TObject);
    procedure ViewPkgSourceClick(Sender: TObject);
    procedure ViewPkgTodosClick(Sender: TObject);
  private
    FIdleConnected: boolean;
    FLazPackage: TLazPackage;
    FNextSelectedPart: TPENodeData;// select this file/dependency on next update
    FFilesNode: TTreeNode;
    FRequiredPackagesNode: TTreeNode;
    FRemovedFilesNode: TTreeNode;
    FRemovedRequiredNode: TTreeNode;
    FPlugins: TStringList; // ComponentClassName, Objects=TPkgComponent
    FShowDirectoryHierarchy: boolean;
    FSortAlphabetically: boolean;
    FDirSummaryLabel: TLabel;
    FSingleSelectedFile: TPkgFile;
    FSingleSelectedDependency: TPkgDependency;
    FFirstNodeData: array[TPENodeType] of TPENodeData;
    fUpdateLock: integer;
    procedure FreeNodeData(Typ: TPENodeType);
    function CreateNodeData(Typ: TPENodeType; aName: string; aRemoved: boolean): TPENodeData;
    procedure SetDependencyDefaultFilename(AsPreferred: boolean);
    procedure SetIdleConnected(AValue: boolean);
    procedure SetShowDirectoryHierarchy(const AValue: boolean);
    procedure SetSortAlphabetically(const AValue: boolean);
    procedure SetupComponents;
    function OnTreeViewGetImageIndex(Str: String; Data: TObject; var AIsEnabled: Boolean): Integer;
    procedure UpdatePending;
    function CanUpdate(Flag: TPEFlag): boolean;
    procedure UpdateTitle(Immediately: boolean = false);
    procedure UpdateButtons(Immediately: boolean = false);
    procedure UpdateFiles(Immediately: boolean = false);
    procedure UpdateRequiredPkgs(Immediately: boolean = false);
    procedure UpdatePEProperties(Immediately: boolean = false);
    procedure UpdateApplyDependencyButton(Immediately: boolean = false);
    procedure UpdateStatusBar(Immediately: boolean = false);
    function GetCurrentDependency(out Removed: boolean): TPkgDependency;
    function GetCurrentFile(out Removed: boolean): TPkgFile;
    function GetNodeData(TVNode: TTreeNode): TPENodeData;
    function GetNodeItem(NodeData: TPENodeData): TObject;
    function GetNodeDataItem(TVNode: TTreeNode; out NodeData: TPENodeData;
      out Item: TObject): boolean;
    function IsDirectoryNode(Node: TTreeNode): boolean;
    procedure GetDirectorySummary(DirNode: TTreeNode;
        out FileCount, HasRegisterProcCount, AddToUsesPkgSectionCount: integer);
    procedure ExtendUnitIncPathForNewUnit(const AnUnitFilename,
      AnIncludeFile: string; var IgnoreUnitPaths: TFilenameToStringTree);
    procedure ExtendIncPathForNewIncludeFile(const AnIncludeFile: string;
      var IgnoreIncPaths: TFilenameToStringTree);
    function CanBeAddedToProject: boolean;
  protected
    fFlags: TPEFlags;
    fLastDlgPage: TAddToPkgType;
    procedure SetLazPackage(const AValue: TLazPackage); override;
    property IdleConnected: boolean read FIdleConnected write SetIdleConnected;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure DoCompile(CompileClean, CompileRequired: boolean);
    procedure DoFixFilesCase;
    procedure DoShowMissingFiles;
    procedure DoMoveCurrentFile(Offset: integer);
    procedure DoMoveDependency(Offset: integer);
    procedure DoPublishProject;
    procedure DoEditVirtualUnit;
    procedure DoExpandDirectory;
    procedure DoCollapseDirectory;
    procedure DoUseUnitsInDirectory(Use: boolean);
    procedure DoRevert;
    procedure DoSave(SaveAs: boolean);
    procedure DoSortFiles;
    function DoOpenPkgFile(PkgFile: TPkgFile): TModalResult;
    procedure UpdateAll(Immediately: boolean); override;
    function ShowAddDialog(var DlgPage: TAddToPkgType): TModalResult;
    procedure BeginUdate;
    procedure EndUpdate;
  public
    property LazPackage: TLazPackage read FLazPackage write SetLazPackage;
    property SortAlphabetically: boolean read FSortAlphabetically write SetSortAlphabetically;
    property ShowDirectoryHierarchy: boolean read FShowDirectoryHierarchy write SetShowDirectoryHierarchy;
  end;
  
  
  { TPackageEditors }
  
  TPackageEditors = class
  private
    FItems: TFPList; // list of TPackageEditorForm
    FOnAddToProject: TOnAddPkgToProject;
    FOnAfterWritePackage: TIDEOptionsWriteEvent;
    FOnBeforeReadPackage: TNotifyEvent;
    FOnCompilePackage: TOnCompilePackage;
    FOnCreateNewFile: TOnCreateNewPkgFile;
    FOnCreateMakefile: TOnCreatePkgMakefile;
    FOnCreateFpmakeFile: TOnCreatePkgFpmakeFile;
    FOnDeleteAmbiguousFiles: TOnDeleteAmbiguousFiles;
    FOnFreeEditor: TOnFreePkgEditor;
    FOnGetIDEFileInfo: TGetIDEFileStateEvent;
    FOnGetUnitRegisterInfo: TOnGetUnitRegisterInfo;
    FOnInstallPackage: TOnInstallPackage;
    FOnOpenFile: TOnOpenFile;
    FOnOpenPackage: TOnOpenPackage;
    FOnOpenPkgFile: TOnOpenPkgFile;
    FOnPublishPackage: TOnPublishPackage;
    FOnRevertPackage: TOnRevertPackage;
    FOnSavePackage: TOnSavePackage;
    FOnUninstallPackage: TOnUninstallPackage;
    FOnViewPackageSource: TOnViewPackageSource;
    FOnViewPackageToDos: TOnViewPackageToDos;
    function GetEditors(Index: integer): TPackageEditorForm;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: integer;
    procedure Clear;
    procedure Remove(Editor: TPackageEditorForm);
    function IndexOfPackage(Pkg: TLazPackage): integer;
    function FindEditor(Pkg: TLazPackage): TPackageEditorForm;
    function OpenEditor(Pkg: TLazPackage): TPackageEditorForm;
    function OpenFile(Sender: TObject; const Filename: string): TModalResult;
    function OpenPkgFile(Sender: TObject; PkgFile: TPkgFile): TModalResult;
    function OpenDependency(Sender: TObject;
                            Dependency: TPkgDependency): TModalResult;
    procedure DoFreeEditor(Pkg: TLazPackage);
    function CreateNewFile(Sender: TObject; Params: TAddToPkgResult): TModalResult;
    function SavePackage(APackage: TLazPackage; SaveAs: boolean): TModalResult;
    function RevertPackage(APackage: TLazPackage): TModalResult;
    function PublishPackage(APackage: TLazPackage): TModalResult;
    function CompilePackage(APackage: TLazPackage;
                            CompileClean,CompileRequired: boolean): TModalResult;
    procedure UpdateAllEditors(Immediately: boolean);
    function ShouldNotBeInstalled(APackage: TLazPackage): boolean;// possible, but probably a bad idea
    function InstallPackage(APackage: TLazPackage): TModalResult;
    function UninstallPackage(APackage: TLazPackage): TModalResult;
    function ViewPkgSource(APackage: TLazPackage): TModalResult;
    function ViewPkgToDos(APackage: TLazPackage): TModalResult;
    function DeleteAmbiguousFiles(APackage: TLazPackage;
                                  const Filename: string): TModalResult;
    function AddToProject(APackage: TLazPackage;
                          OnlyTestIfPossible: boolean): TModalResult;
    function CreateMakefile(APackage: TLazPackage): TModalResult;
    function CreateFpmakeFile(APackage: TLazPackage): TModalResult;
  public
    property Editors[Index: integer]: TPackageEditorForm read GetEditors;
    property OnAddToProject: TOnAddPkgToProject read FOnAddToProject
                                                write FOnAddToProject;
    property OnAfterWritePackage: TIDEOptionsWriteEvent read FOnAfterWritePackage
                                               write FOnAfterWritePackage;
    property OnBeforeReadPackage: TNotifyEvent read FOnBeforeReadPackage
                                               write FOnBeforeReadPackage;
    property OnCompilePackage: TOnCompilePackage read FOnCompilePackage
                                                 write FOnCompilePackage;
    property OnCreateMakeFile: TOnCreatePkgMakefile read FOnCreateMakefile
                                                     write FOnCreateMakefile;
    property OnCreateFpmakeFile: TOnCreatePkgFpmakeFile read FOnCreateFpmakeFile
                                                     write FOnCreateFpmakeFile;
    property OnCreateNewFile: TOnCreateNewPkgFile read FOnCreateNewFile
                                                  write FOnCreateNewFile;
    property OnDeleteAmbiguousFiles: TOnDeleteAmbiguousFiles
                     read FOnDeleteAmbiguousFiles write FOnDeleteAmbiguousFiles;
    property OnFreeEditor: TOnFreePkgEditor read FOnFreeEditor
                                            write FOnFreeEditor;
    property OnGetIDEFileInfo: TGetIDEFileStateEvent read FOnGetIDEFileInfo
                                                     write FOnGetIDEFileInfo;
    property OnGetUnitRegisterInfo: TOnGetUnitRegisterInfo
                       read FOnGetUnitRegisterInfo write FOnGetUnitRegisterInfo;
    property OnInstallPackage: TOnInstallPackage read FOnInstallPackage
                                                 write FOnInstallPackage;
    property OnOpenFile: TOnOpenFile read FOnOpenFile write FOnOpenFile;
    property OnOpenPackage: TOnOpenPackage read FOnOpenPackage
                                           write FOnOpenPackage;
    property OnOpenPkgFile: TOnOpenPkgFile read FOnOpenPkgFile
                                           write FOnOpenPkgFile;
    property OnPublishPackage: TOnPublishPackage read FOnPublishPackage
                                               write FOnPublishPackage;
    property OnRevertPackage: TOnRevertPackage read FOnRevertPackage
                                               write FOnRevertPackage;
    property OnSavePackage: TOnSavePackage read FOnSavePackage
                                           write FOnSavePackage;
    property OnUninstallPackage: TOnUninstallPackage read FOnUninstallPackage
                                                 write FOnUninstallPackage;
    property OnViewPackageSource: TOnViewPackageSource read FOnViewPackageSource
                                                 write FOnViewPackageSource;
    property OnViewPackageToDos: TOnViewPackageToDos read FOnViewPackageToDos
                                                 write FOnViewPackageToDos;
  end;
  
var
  PackageEditors: TPackageEditors;

procedure RegisterStandardPackageEditorMenuItems;

implementation

{$R *.lfm}

var
  ImageIndexFiles: integer;
  ImageIndexRemovedFiles: integer;
  ImageIndexRequired: integer;
  ImageIndexRemovedRequired: integer;
  ImageIndexUnit: integer;
  ImageIndexRegisterUnit: integer;
  ImageIndexLFM: integer;
  ImageIndexLRS: integer;
  ImageIndexInclude: integer;
  ImageIndexIssues: integer;
  ImageIndexText: integer;
  ImageIndexBinary: integer;
  ImageIndexConflict: integer;
  ImageIndexDirectory: integer;

procedure RegisterStandardPackageEditorMenuItems;
var
  AParent: TIDEMenuSection;
begin
  PackageEditorMenuRoot     :=RegisterIDEMenuRoot(PackageEditorMenuRootName);
  PackageEditorMenuFilesRoot:=RegisterIDEMenuRoot(PackageEditorMenuFilesRootName);

  // register the section for operations on single files
  PkgEditMenuSectionFile:=RegisterIDEMenuSection(PackageEditorMenuFilesRoot,'File');
  AParent:=PkgEditMenuSectionFile;
  PkgEditMenuOpenFile:=RegisterIDEMenuCommand(AParent,'Open File',lisOpenFile);
  PkgEditMenuRemoveFile:=RegisterIDEMenuCommand(AParent,'Remove File',lisPckEditRemoveFile);
  PkgEditMenuReAddFile:=RegisterIDEMenuCommand(AParent,'ReAdd File',lisPckEditReAddFile);
  PkgEditMenuEditVirtualUnit:=RegisterIDEMenuCommand(AParent,'Edit Virtual File',lisPEEditVirtualUnit);
  PkgEditMenuSectionFileType:=RegisterIDESubMenu(AParent,'File Type',lisAF2PFileType);

  // register the section for operations on directories
  PkgEditMenuSectionDirectory:=RegisterIDEMenuSection(PackageEditorMenuFilesRoot,'Directory');
  AParent:=PkgEditMenuSectionDirectory;
  PkgEditMenuExpandDirectory:=RegisterIDEMenuCommand(AParent,'Expand directory',lisPEExpandDirectory);
  PkgEditMenuCollapseDirectory:=RegisterIDEMenuCommand(AParent, 'Collapse directory', lisPECollapseDirectory);
  PkgEditMenuUseAllUnitsInDirectory:=RegisterIDEMenuCommand(AParent, 'Use all units in directory', lisPEUseAllUnitsInDirectory);
  PkgEditMenuUseNoUnitsInDirectory:=RegisterIDEMenuCommand(AParent, 'Use no units in directory', lisPEUseNoUnitsInDirectory);

  // register the section for operations on dependencies
  PkgEditMenuSectionDependency:=RegisterIDEMenuSection(PackageEditorMenuFilesRoot,'Dependency');
  AParent:=PkgEditMenuSectionDependency;
  PkgEditMenuOpenPackage:=RegisterIDEMenuCommand(AParent,'Open Package',lisMenuOpenPackage);
  PkgEditMenuRemoveDependency:=RegisterIDEMenuCommand(AParent,'Remove Dependency',lisPckEditRemoveDependency);
  PkgEditMenuReAddDependency:=RegisterIDEMenuCommand(AParent,'ReAdd Dependency',lisPckEditReAddDependency);
  PkgEditMenuDependencyStoreFileNameAsDefault:=RegisterIDEMenuCommand(AParent,'Dependency Store Filename As Default',lisPckEditStoreFileNameAsDefaultForThisDependency);
  PkgEditMenuDependencyStoreFileNameAsPreferred:=RegisterIDEMenuCommand(AParent,'Dependency Store Filename As Preferred',lisPckEditStoreFileNameAsPreferredForThisDependency);
  PkgEditMenuDependencyClearStoredFileName:=RegisterIDEMenuCommand(AParent,'Dependency Clear Stored Filename',lisPckEditClearDefaultPreferredFilenameOfDependency);
  PkgEditMenuCleanDependencies:=RegisterIDEMenuCommand(AParent, 'Clean up dependencies', lisPckEditCleanUpDependencies);

  // register the section for operations on all files
  PkgEditMenuSectionFiles:=RegisterIDEMenuSection(PackageEditorMenuRoot,'Files');
  AParent:=PkgEditMenuSectionFiles;
  PkgEditMenuSortFiles:=RegisterIDEMenuCommand(AParent,'Sort Files Permanently',lisPESortFiles);
  PkgEditMenuFixFilesCase:=RegisterIDEMenuCommand(AParent,'Fix Files Case',lisPEFixFilesCase);
  PkgEditMenuShowMissingFiles:=RegisterIDEMenuCommand(AParent, 'Show Missing Files', lisPEShowMissingFiles);

  // register the section for using the package
  PkgEditMenuSectionUse:=RegisterIDEMenuSection(PackageEditorMenuRoot,'Use');

  // register the section for saving the package
  PkgEditMenuSectionSave:=RegisterIDEMenuSection(PackageEditorMenuRoot,'Save');
  AParent:=PkgEditMenuSectionSave;
  PkgEditMenuSave:=RegisterIDEMenuCommand(AParent, 'Save', lisPckEditSavePackage);
  PkgEditMenuSaveAs:=RegisterIDEMenuCommand(AParent, 'Save As', lisPESavePackageAs);
  PkgEditMenuRevert:=RegisterIDEMenuCommand(AParent, 'Revert', lisPERevertPackage);
  PkgEditMenuPublish:=RegisterIDEMenuCommand(AParent,'Publish',lisPkgEditPublishPackage);

  // register the section for compiling the package
  PkgEditMenuSectionCompile:=RegisterIDEMenuSection(PackageEditorMenuRoot,'Compile');
  AParent:=PkgEditMenuSectionCompile;
  PkgEditMenuCompile:=RegisterIDEMenuCommand(AParent,'Compile',lisCompile);
  PkgEditMenuRecompileClean:=RegisterIDEMenuCommand(AParent,'Recompile Clean',lisPckEditRecompileClean);
  PkgEditMenuRecompileAllRequired:=RegisterIDEMenuCommand(AParent,'Recompile All Required',lisPckEditRecompileAllRequired);
  PkgEditMenuCreateFpmakeFile:=RegisterIDEMenuCommand(AParent,'Create fpmake.pp',lisPckEditCreateFpmakeFile);
  PkgEditMenuCreateMakefile:=RegisterIDEMenuCommand(AParent,'Create Makefile',lisPckEditCreateMakefile);

  // register the section for adding to or removing from package
  PkgEditMenuSectionAddRemove:=RegisterIDEMenuSection(PackageEditorMenuRoot,'AddRemove');

  // register the section for other things
  PkgEditMenuSectionMisc:=RegisterIDEMenuSection(PackageEditorMenuRoot,'Misc');
  AParent:=PkgEditMenuSectionMisc;
  PkgEditMenuViewPackageSource:=RegisterIDEMenuCommand(AParent,'View Package Source',lisPckEditViewPackageSource);
end;

{ TPENodeData }

constructor TPENodeData.Create(aTyp: TPENodeType; aName: string;
  aRemoved: boolean);
begin
  Typ:=aTyp;
  Name:=aName;;
  Removed:=aRemoved;
end;

{ TPackageEditorForm }

procedure TPackageEditorForm.PublishClick(Sender: TObject);
begin
  DoPublishProject;
end;

procedure TPackageEditorForm.ReAddMenuItemClick(Sender: TObject);
var
  PkgFile: TPkgFile;
  AFilename: String;
  Dependency: TPkgDependency;
  i: Integer;
  TVNode: TTreeNode;
  NodeData: TPENodeData;
  Item: TObject;
begin
  BeginUdate;
  try
    for i:=0 to ItemsTreeView.SelectionCount-1 do begin
      TVNode:=ItemsTreeView.Selections[i];
      if not GetNodeDataItem(TVNode,NodeData,Item) then continue;
      if not NodeData.Removed then continue;
      if Item is TPkgFile then begin
        // re-add file
        PkgFile:=TPkgFile(Item);
        AFilename:=PkgFile.GetFullFilename;
        if PkgFile.FileType in PkgFileRealUnitTypes then begin
          if not CheckAddingUnitFilename(LazPackage,d2ptUnit,
            PackageEditors.OnGetIDEFileInfo,AFilename) then exit;
        end else if PkgFile.FileType=pftVirtualUnit then begin
          if not CheckAddingUnitFilename(LazPackage,d2ptVirtualUnit,
            PackageEditors.OnGetIDEFileInfo,AFilename) then exit;
        end else begin
          if not CheckAddingUnitFilename(LazPackage,d2ptFile,
            PackageEditors.OnGetIDEFileInfo,AFilename) then exit;
        end;
        PkgFile.Filename:=AFilename;
        LazPackage.UnremovePkgFile(PkgFile);
        UpdateFiles;
      end else if Item is TPkgDependency then begin
        Dependency:=TPkgDependency(Item);
        // re-add dependency
        if CheckAddingDependency(LazPackage,Dependency,false,true)<>mrOk then exit;
        LazPackage.RemoveRemovedDependency(Dependency);
        PackageGraph.AddDependencyToPackage(LazPackage,Dependency);
        UpdateRequiredPkgs;
      end;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TPackageEditorForm.ItemsPopupMenuPopup(Sender: TObject);

  procedure SetItem(Item: TIDEMenuCommand; AnOnClick: TNotifyEvent;
                    aShow: boolean = true; AEnable: boolean = true);
  begin
    //debugln(['SetItem ',Item.Caption,' Visible=',aShow,' Enable=',AEnable]);
    Item.OnClick:=AnOnClick;
    Item.Visible:=aShow;
    Item.Enabled:=AEnable;
  end;

  procedure AddFileTypeMenuItem;
  var
    CurPFT: TPkgFileType;
    VirtualFileExists: Boolean;
    NewMenuItem: TIDEMenuCommand;
  begin
    PkgEditMenuSectionFileType.Clear;
    if FSingleSelectedFile=nil then exit;
    VirtualFileExists:=(FSingleSelectedFile.FileType=pftVirtualUnit)
                    and FileExistsCached(FSingleSelectedFile.GetFullFilename);
    for CurPFT:=Low(TPkgFileType) to High(TPkgFileType) do begin
      NewMenuItem:=RegisterIDEMenuCommand(PkgEditMenuSectionFileType,
                      'SetFileType'+IntToStr(ord(CurPFT)),
                      GetPkgFileTypeLocalizedName(CurPFT),
                      @ChangeFileTypeMenuItemClick);
      if CurPFT=FSingleSelectedFile.FileType then begin
        // menuitem to keep the current type
        NewMenuItem.Enabled:=true;
        NewMenuItem.Checked:=true;
      end else if VirtualFileExists then
        // a virtual unit that exists can be changed into anything
        NewMenuItem.Enabled:=true
      else if (not (CurPFT in PkgFileUnitTypes)) then
        // all other files can be changed into all non unit types
        NewMenuItem.Enabled:=true
      else if FilenameIsPascalUnit(FSingleSelectedFile.Filename) then
        // a pascal file can be changed into anything
        NewMenuItem.Enabled:=true
      else
        // default is to not allow
        NewMenuItem.Enabled:=false;
    end;
  end;

var
  i: Integer;
  TVNode: TTreeNode;
  NodeData: TPENodeData;
  Item: TObject;
  SingleSelectedRemoved: Boolean;
  SelDepCount: Integer;
  SelFileCount: Integer;
  SelDirCount: Integer;
  SelRemovedFileCount: Integer;
  Writable: Boolean;
  CurDependency: TPkgDependency;
  CurFile: TPkgFile;
begin
  //debugln(['TPackageEditorForm.FilesPopupMenuPopup START ',ItemsPopupMenu.Items.Count]);
  PackageEditorMenuFilesRoot.MenuItem:=ItemsPopupMenu.Items;
  //debugln(['TPackageEditorForm.FilesPopupMenuPopup START after connect ',ItemsPopupMenu.Items.Count]);
  PackageEditorMenuRoot.BeginUpdate;
  try
    SelFileCount:=0;
    SelDepCount:=0;
    SelDirCount:=0;
    SelRemovedFileCount:=0;
    SingleSelectedRemoved:=false;
    for i:=0 to ItemsTreeView.SelectionCount-1 do begin
      TVNode:=ItemsTreeView.Selections[i];
      if GetNodeDataItem(TVNode,NodeData,Item) then begin
        if Item is TPkgFile then begin
          CurFile:=TPkgFile(Item);
          inc(SelFileCount);
          FSingleSelectedFile:=CurFile;
          SingleSelectedRemoved:=NodeData.Removed;
          if NodeData.Removed then
            inc(SelRemovedFileCount);
        end else if Item is TPkgDependency then begin
          CurDependency:=TPkgDependency(Item);
          inc(SelDepCount);
          FSingleSelectedDependency:=CurDependency;
          SingleSelectedRemoved:=NodeData.Removed;
        end;
      end else if IsDirectoryNode(TVNode) or (TVNode=FFilesNode) then begin
        inc(SelDirCount);
      end;
    end;

    if (SelFileCount+SelDepCount+SelDirCount>1) then begin
      // it is a multi selection
      FSingleSelectedFile:=nil;
      FSingleSelectedDependency:=nil;
    end;

    Writable:=(not LazPackage.ReadOnly);

    PkgEditMenuSectionFileType.Clear;

    // items for single files, under section PkgEditMenuSectionFile
    PkgEditMenuSectionFile.Visible:=SelFileCount>0;
    if PkgEditMenuSectionFile.Visible then begin
      SetItem(PkgEditMenuOpenFile,@OpenFileMenuItemClick);
      SetItem(PkgEditMenuReAddFile,@ReAddMenuItemClick,SingleSelectedRemoved);
      SetItem(PkgEditMenuRemoveFile,@RemoveBitBtnClick,SelRemovedFileCount>0,RemoveBitBtn.Enabled);
      AddFileTypeMenuItem;
      SetItem(PkgEditMenuEditVirtualUnit,@EditVirtualUnitMenuItemClick,
              (FSingleSelectedFile<>nil) and (FSingleSelectedFile.FileType=pftVirtualUnit)
              and not SingleSelectedRemoved,Writable);
    end;

    // items for directories, under section PkgEditMenuSectionDirectory
    PkgEditMenuSectionDirectory.Visible:=(SelDirCount>0) and ShowDirectoryHierarchy;
    if PkgEditMenuSectionDirectory.Visible then begin
      SetItem(PkgEditMenuExpandDirectory,@ExpandDirectoryMenuItemClick);
      SetItem(PkgEditMenuCollapseDirectory,@CollapseDirectoryMenuItemClick);
      SetItem(PkgEditMenuUseAllUnitsInDirectory,@UseAllUnitsInDirectoryMenuItemClick);
      SetItem(PkgEditMenuUseNoUnitsInDirectory,@UseNoUnitsInDirectoryMenuItemClick);
    end;

    // items for dependencies, under section PkgEditMenuSectionDependency
    PkgEditMenuSectionDependency.Visible:=(SelDepCount>0)
      or (ItemsTreeView.Selected=FRequiredPackagesNode);
    SetItem(PkgEditMenuOpenPackage,@OpenFileMenuItemClick,
            (FSingleSelectedDependency<>nil) and (FSingleSelectedDependency.RequiredPackage<>nil));
    SetItem(PkgEditMenuRemoveDependency,@RemoveBitBtnClick,
            (FSingleSelectedDependency<>nil) and (not SingleSelectedRemoved),
            Writable);
    SetItem(PkgEditMenuReAddDependency,@ReAddMenuItemClick,
            (FSingleSelectedDependency<>nil) and SingleSelectedRemoved,
            Writable);
    SetItem(PkgEditMenuDependencyStoreFileNameAsDefault,
            @SetDependencyDefaultFilenameMenuItemClick,
            (FSingleSelectedDependency<>nil) and (not SingleSelectedRemoved),
            Writable and (FSingleSelectedDependency<>nil)
            and (FSingleSelectedDependency.RequiredPackage<>nil));
    SetItem(PkgEditMenuDependencyStoreFileNameAsPreferred,
            @SetDependencyPreferredFilenameMenuItemClick,
            (FSingleSelectedDependency<>nil) and (not SingleSelectedRemoved),
            Writable and (FSingleSelectedDependency<>nil)
            and (FSingleSelectedDependency.RequiredPackage<>nil));
    SetItem(PkgEditMenuDependencyClearStoredFileName,
            @ClearDependencyFilenameMenuItemClick,
            (FSingleSelectedDependency<>nil) and (not SingleSelectedRemoved),
            Writable and (FSingleSelectedDependency<>nil)
            and (FSingleSelectedDependency.RequiredPackage<>nil));
    SetItem(PkgEditMenuCleanDependencies,
            @CleanDependenciesMenuItemClick,LazPackage.FirstRequiredDependency<>nil,
            Writable);

  finally
    PackageEditorMenuRoot.EndUpdate;
  end;
  //debugln(['TPackageEditorForm.FilesPopupMenuPopup END ',ItemsPopupMenu.Items.Count]); PackageEditorMenuRoot.WriteDebugReport('  ',true);
end;

procedure TPackageEditorForm.MorePopupMenuPopup(Sender: TObject);
var
  Writable: Boolean;

  procedure SetItem(Item: TIDEMenuCommand; AnOnClick: TNotifyEvent;
                    aShow: boolean = true; AEnable: boolean = true);
  begin
    //debugln(['SetItem ',Item.Caption,' Visible=',aShow,' Enable=',AEnable]);
    Item.OnClick:=AnOnClick;
    Item.Visible:=aShow;
    Item.Enabled:=AEnable;
  end;

begin
  PackageEditorMenuRoot.MenuItem:=MorePopupMenu.Items;
  PackageEditorMenuRoot.BeginUpdate;
  try
    Writable:=(not LazPackage.ReadOnly);

    PkgEditMenuSectionFileType.Clear;

    // under section PkgEditMenuSectionFiles
    SetItem(PkgEditMenuSortFiles,@SortFilesMenuItemClick,(LazPackage.FileCount>1),Writable);
    SetItem(PkgEditMenuFixFilesCase,@FixFilesCaseMenuItemClick,(LazPackage.FileCount>0),Writable);
    SetItem(PkgEditMenuShowMissingFiles,@ShowMissingFilesMenuItemClick,(LazPackage.FileCount>0),Writable);

    // under section PkgEditMenuSectionSave
    SetItem(PkgEditMenuSave,@SaveBitBtnClick,true,SaveBitBtn.Enabled);
    SetItem(PkgEditMenuSaveAs,@SaveAsClick,true,true);
    SetItem(PkgEditMenuRevert,@RevertClick,true,
            (not LazPackage.IsVirtual) and FileExistsUTF8(LazPackage.Filename));
    SetItem(PkgEditMenuPublish,@PublishClick,true,
            (not LazPackage.Missing) and LazPackage.HasDirectory);

    // under section PkgEditMenuSectionCompile
    SetItem(PkgEditMenuCompile,@CompileBitBtnClick,true,CompileBitBtn.Enabled);
    SetItem(PkgEditMenuRecompileClean,@CompileCleanClick,true,CompileBitBtn.Enabled);
    SetItem(PkgEditMenuRecompileAllRequired,@CompileAllCleanClick,true,CompileBitBtn.Enabled);
    SetItem(PkgEditMenuCreateFpmakeFile,@CreateFpmakeFileClick,true,CompileBitBtn.Enabled);
    SetItem(PkgEditMenuCreateMakefile,@CreateMakefileClick,true,CompileBitBtn.Enabled);

    // under section PkgEditMenuSectionMisc
    SetItem(PkgEditMenuViewPackageSource,@ViewPkgSourceClick);
  finally
    PackageEditorMenuRoot.EndUpdate;
  end;
end;

procedure TPackageEditorForm.SortAlphabeticallyButtonClick(Sender: TObject);
begin
  SortAlphabetically:=SortAlphabeticallyButton.Down;
end;

procedure TPackageEditorForm.UsePopupMenuPopup(Sender: TObject);
var
  ItemCnt: Integer;

  function AddPopupMenuItem(const ACaption: string; AnEvent: TNotifyEvent;
    EnabledFlag: boolean): TMenuItem;
  begin
    if UsePopupMenu.Items.Count<=ItemCnt then begin
      Result:=TMenuItem.Create(Self);
      UsePopupMenu.Items.Add(Result);
    end else begin
      Result:=UsePopupMenu.Items[ItemCnt];
      while Result.Count>0 do Result.Delete(Result.Count-1);
    end;
    Result.Caption:=ACaption;
    Result.OnClick:=AnEvent;
    Result.Enabled:=EnabledFlag;
    inc(ItemCnt);
  end;

begin
  ItemCnt:=0;

  AddPopupMenuItem(lisPckEditAddToProject, @AddToProjectClick,
                   CanBeAddedToProject);
  AddPopupMenuItem(lisPckEditInstall, @InstallClick,(not LazPackage.Missing)
           and (LazPackage.PackageType in [lptDesignTime,lptRunAndDesignTime]));
  AddPopupMenuItem(lisPckEditUninstall, @UninstallClick,
          (LazPackage.Installed<>pitNope) or (LazPackage.AutoInstall<>pitNope));

  // remove unneeded menu items
  while UsePopupMenu.Items.Count>ItemCnt do
    UsePopupMenu.Items.Delete(UsePopupMenu.Items.Count-1);
end;

procedure TPackageEditorForm.ItemsTreeViewDblClick(Sender: TObject);
begin
  OpenFileMenuItemClick(Self);
end;

procedure TPackageEditorForm.ItemsTreeViewKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  Handled: Boolean;
begin
  Handled := True;
  if (ssCtrl in Shift) then
  begin
    if Key = VK_UP then
      MoveUpBtnClick(Nil)
    else if Key = VK_DOWN then
      MoveDownBtnClick(Nil)
    else
      Handled := False;
  end
  else if Key = VK_RETURN then
    OpenFileMenuItemClick(Nil)
  else if Key = VK_DELETE then
    RemoveBitBtnClick(Nil)
  else if Key = VK_INSERT then
    AddBitBtnClick(Nil)
  else
    Handled := False;

  if Handled then
    Key := VK_UNKNOWN;
end;

procedure TPackageEditorForm.ItemsTreeViewSelectionChanged(Sender: TObject);
begin
  if fUpdateLock>0 then exit;
  UpdatePEProperties;
  UpdateButtons;
end;

procedure TPackageEditorForm.HelpBitBtnClick(Sender: TObject);
begin
  LazarusHelp.ShowHelpForIDEControl(Self);
end;

procedure TPackageEditorForm.InstallClick(Sender: TObject);
begin
  PackageEditors.InstallPackage(LazPackage);
end;

procedure TPackageEditorForm.MaxVersionEditChange(Sender: TObject);
begin
  UpdateApplyDependencyButton;
end;

procedure TPackageEditorForm.MinVersionEditChange(Sender: TObject);
begin
  UpdateApplyDependencyButton;
end;

procedure TPackageEditorForm.SetDependencyDefaultFilenameMenuItemClick(Sender: TObject);
begin
  SetDependencyDefaultFilename(false);
end;

procedure TPackageEditorForm.SetDependencyPreferredFilenameMenuItemClick(Sender: TObject);
begin
  SetDependencyDefaultFilename(true);
end;

procedure TPackageEditorForm.ClearDependencyFilenameMenuItemClick(Sender: TObject);
var
  Removed: boolean;
  CurDependency: TPkgDependency;
begin
  if LazPackage=nil then exit;
  CurDependency:=GetCurrentDependency(Removed);
  if (CurDependency=nil) or Removed then exit;
  if LazPackage.ReadOnly then exit;
  if CurDependency.RequiredPackage=nil then exit;
  if CurDependency.DefaultFilename='' then exit;
  CurDependency.DefaultFilename:='';
  CurDependency.PreferDefaultFilename:=false;
  LazPackage.Modified:=true;
  UpdateRequiredPkgs;
  UpdateButtons;
end;

procedure TPackageEditorForm.CollapseDirectoryMenuItemClick(Sender: TObject);
begin
  DoCollapseDirectory;
end;

procedure TPackageEditorForm.MoveUpBtnClick(Sender: TObject);
begin
  if SortAlphabetically then exit;
  if Assigned(FSingleSelectedFile) then
    DoMoveCurrentFile(-1)
  else if Assigned(FSingleSelectedDependency) then
    DoMoveDependency(-1)
end;

procedure TPackageEditorForm.OnIdle(Sender: TObject; var Done: Boolean);
begin
  if fUpdateLock>0 then exit;
  IdleConnected:=false;
  UpdatePending;
end;

procedure TPackageEditorForm.MoveDownBtnClick(Sender: TObject);
begin
  if SortAlphabetically then exit;
  if Assigned(FSingleSelectedFile) then
    DoMoveCurrentFile(1)
  else if Assigned(FSingleSelectedDependency) then
    DoMoveDependency(1)
end;

procedure TPackageEditorForm.OpenFileMenuItemClick(Sender: TObject);
var
  CurFile: TPkgFile;
  CurDependency: TPkgDependency;
  i: Integer;
  TVNode: TTreeNode;
  NodeData: TPENodeData;
  Item: TObject;
begin
  for i:=0 to ItemsTreeView.SelectionCount-1 do begin
    TVNode:=ItemsTreeView.Selections[i];
    if GetNodeDataItem(TVNode,NodeData,Item) then begin
      if Item is TPkgFile then begin
        CurFile:=TPkgFile(Item);
        if DoOpenPkgFile(CurFile)<>mrOk then exit;
      end else if Item is TPkgDependency then begin
        CurDependency:=TPkgDependency(Item);
        if PackageEditors.OpenDependency(Self,CurDependency)<>mrOk then exit;
      end;
    end;
  end;
end;

procedure TPackageEditorForm.OptionsBitBtnClick(Sender: TObject);
const
  Settings: array[Boolean] of TIDEOptionsEditorSettings = (
    [],
    [ioesReadOnly]
  );
begin
  Package1 := LazPackage;
  Package1.OnBeforeRead:=PackageEditors.OnBeforeReadPackage;
  Package1.OnAfterWrite:=PackageEditors.OnAfterWritePackage;
  LazarusIDE.DoOpenIDEOptions(nil,
    Format(lisPckEditCompilerOptionsForPackage, [LazPackage.IDAsString]),
    [TLazPackage, TPkgCompilerOptions], Settings[LazPackage.ReadOnly]);
  UpdateButtons;
  UpdateTitle;
  UpdateStatusBar;
end;

procedure TPackageEditorForm.PackageEditorFormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  //debugln(['TPackageEditorForm.PackageEditorFormClose ',Caption]);
  if LazPackage=nil then exit;
end;

procedure TPackageEditorForm.PackageEditorFormCloseQuery(Sender: TObject;
  var CanClose: boolean);
var
  MsgResult: Integer;
begin
  //debugln(['TPackageEditorForm.PackageEditorFormCloseQuery ',Caption]);
  if (LazPackage<>nil) and (not (lpfDestroying in LazPackage.Flags))
  and (not LazPackage.ReadOnly) and LazPackage.Modified then begin

    MsgResult:=MessageDlg(lisPkgMangSavePackage,
      Format(lisPckEditPackageHasChangedSavePackage,
             ['"',LazPackage.IDAsString,'"',LineEnding]),
      mtConfirmation,[mbYes,mbNo,mbAbort],0);
    case MsgResult of
      mrYes:
        MsgResult:=PackageEditors.SavePackage(LazPackage,false);
      mrNo:
        LazPackage.UserIgnoreChangeStamp:=LazPackage.ChangeStamp;
    end;
    if MsgResult=mrAbort then CanClose:=false;
    LazPackage.Modified:=false; // clear modified flag, so that it will be closed
  end;
  //debugln(['TPackageEditorForm.PackageEditorFormCloseQuery CanClose=',CanClose,' ',Caption]);
  if CanClose then
    Application.ReleaseComponent(Self);
end;

procedure TPackageEditorForm.RegisteredListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  CurComponent: TPkgComponent;
  CurStr: string;
  CurObject: TObject;
  TxtH: Integer;
  CurIcon: TCustomBitmap;
  IconWidth: Integer;
  IconHeight: Integer;
begin
  //DebugLn('TPackageEditorForm.RegisteredListBoxDrawItem START');
  if LazPackage=nil then exit;
  if (Index<0) or (Index>=FPlugins.Count) then exit;
  CurObject:=FPlugins.Objects[Index];
  if CurObject is TPkgComponent then begin
    // draw registered component
    CurComponent:=TPkgComponent(CurObject);
    with RegisteredListBox.Canvas do begin
      CurStr:=Format(lisPckEditPage, [CurComponent.ComponentClass.ClassName,
        CurComponent.Page.PageName]);
      TxtH:=TextHeight(CurStr);
      FillRect(ARect);
      CurIcon:=CurComponent.Icon;
      //DebugLn('TPackageEditorForm.RegisteredListBoxDrawItem ',DbgSName(CurIcon),' ',CurComponent.ComponentClass.ClassName);
      if CurIcon<>nil then begin
        IconWidth:=CurIcon.Width;
        IconHeight:=CurIcon.Height;
        Draw(ARect.Left+(25-IconWidth) div 2,
             ARect.Top+(ARect.Bottom-ARect.Top-IconHeight) div 2,
             CurIcon);
      end;
      TextOut(ARect.Left+25,
              ARect.Top+(ARect.Bottom-ARect.Top-TxtH) div 2,
              CurStr);
    end;
  end;
end;

procedure TPackageEditorForm.RemoveBitBtnClick(Sender: TObject);
var
  ANode: TTreeNode;
  CurFile: TPkgFile;
  CurDependency: TPkgDependency;
  s: String;
  mt: TMsgDlgType;
  i: Integer;
  TVNode: TTreeNode;
  NodeData: TPENodeData;
  Item: TObject;
  MainUnitSelected: Boolean;
  FileWarning: String;
  FileCount: Integer;
  PkgCount: Integer;
  PkgWarning: String;
begin
  BeginUdate;
  try
    ANode:=ItemsTreeView.Selected;
    if (ANode=nil) or LazPackage.ReadOnly then begin
      UpdateButtons;
      exit;
    end;

    // check selection
    MainUnitSelected:=false;
    FileWarning:='';
    FileCount:=0;
    PkgCount:=0;
    PkgWarning:='';
    for i:=0 to ItemsTreeView.SelectionCount-1 do begin
      TVNode:=ItemsTreeView.Selections[i];
      if not GetNodeDataItem(TVNode,NodeData,Item) then continue;
      if NodeData.Removed then continue;
      if Item is TPkgFile then begin
        CurFile:=TPkgFile(Item);
        inc(FileCount);
        if CurFile.FileType=pftMainUnit then
          MainUnitSelected:=true;
        if FileWarning='' then
          FileWarning:=Format(lisPckEditRemoveFileFromPackage,
            ['"', CurFile.Filename, '"', LineEnding, '"', LazPackage.IDAsString, '"']);
      end else if Item is TPkgDependency then begin
        CurDependency:=TPkgDependency(Item);
        inc(PkgCount);
        if PkgWarning='' then
          PkgWarning:=Format(lisPckEditRemoveDependencyFromPackage, ['"',
            CurDependency.AsString, '"', LineEnding, '"', LazPackage.IDAsString, '"']);
      end;
    end;
    if (FileCount=0) and (PkgCount=0) then begin
      UpdateButtons;
      exit;
    end;

    // confirm deletion
    if FileCount>0 then begin
      s:='';
      mt:=mtConfirmation;
      if FileCount=1 then
        s:=FileWarning
      else
        s:=Format(lisRemoveFilesFromPackage, [IntToStr(FileCount), LazPackage.
          Name]);
      if MainUnitSelected then begin
        s+=Format(lisWarningThisIsTheMainUnitTheNewMainUnitWillBePas,
                  [LineEnding+LineEnding, lowercase(LazPackage.Name)]);
        mt:=mtWarning;
      end;
      if IDEMessageDialog(lisPckEditRemoveFile2,s,mt,[mbYes,mbNo])<>mrYes then
        exit;
    end;
    if PkgCount>0 then begin
      s:='';
      mt:=mtConfirmation;
      if PkgCount=1 then
        s:=PkgWarning
      else
        s:=Format(lisRemoveDependenciesFromPackage, [IntToStr(PkgCount),
          LazPackage.Name]);
      if IDEMessageDialog(lisPckEditRemoveDependencyFromPackage,s,mt,[mbYes,mbNo])<>mrYes then
        exit;
    end;

    // remove
    for i:=0 to ItemsTreeView.SelectionCount-1 do begin
      TVNode:=ItemsTreeView.Selections[i];
      if not GetNodeDataItem(TVNode,NodeData,Item) then continue;
      if NodeData.Removed then continue;
      if Item is TPkgFile then begin
        CurFile:=TPkgFile(Item);
        LazPackage.RemoveFile(CurFile);
        UpdateFiles;
      end else if Item is TPkgDependency then begin
        CurDependency:=TPkgDependency(Item);
        PackageGraph.RemoveDependencyFromPackage(LazPackage,CurDependency,true);
        UpdateRequiredPkgs;
      end;
    end;

  finally
    EndUpdate;
  end;
end;

procedure TPackageEditorForm.EditVirtualUnitMenuItemClick(Sender: TObject);
begin
  DoEditVirtualUnit;
end;

procedure TPackageEditorForm.ExpandDirectoryMenuItemClick(Sender: TObject);
begin
  DoExpandDirectory;
end;

procedure TPackageEditorForm.FormCreate(Sender: TObject);
begin
  FPlugins:=TStringList.Create;
  {$IFDEF enablePkgEditMultiSelect}
  ItemsTreeView.MultiSelect:=true;
  {$ENDIF}
  SetupComponents;
  SortAlphabetically := EnvironmentOptions.PackageEditorSortAlphabetically;
  ShowDirectoryHierarchy := EnvironmentOptions.PackageEditorShowDirHierarchy;
end;

procedure TPackageEditorForm.FormDestroy(Sender: TObject);
var
  nt: TPENodeType;
begin
  FreeAndNil(FNextSelectedPart);
  EnvironmentOptions.PackageEditorSortAlphabetically := SortAlphabetically;
  EnvironmentOptions.PackageEditorShowDirHierarchy := ShowDirectoryHierarchy;
  FilterEdit.ForceFilter('');
  for nt:=Low(TPENodeType) to High(TPENodeType) do
    FreeNodeData(nt);
  if PackageEditorMenuRoot.MenuItem=ItemsPopupMenu.Items then
    PackageEditorMenuRoot.MenuItem:=nil;
  PackageEditors.DoFreeEditor(LazPackage);
  FLazPackage:=nil;
  FreeAndNil(FPlugins);
end;

procedure TPackageEditorForm.RevertClick(Sender: TObject);
begin
  DoRevert;
end;

procedure TPackageEditorForm.SaveBitBtnClick(Sender: TObject);
begin
  DoSave(false);
end;

procedure TPackageEditorForm.SaveAsClick(Sender: TObject);
begin
  DoSave(true);
end;

procedure TPackageEditorForm.SortFilesMenuItemClick(Sender: TObject);
begin
  DoSortFiles;
end;

procedure TPackageEditorForm.FixFilesCaseMenuItemClick(Sender: TObject);
begin
  DoFixFilesCase;
end;

procedure TPackageEditorForm.ShowMissingFilesMenuItemClick(Sender: TObject);
begin
  DoShowMissingFiles;
end;

procedure TPackageEditorForm.UninstallClick(Sender: TObject);
begin
  PackageEditors.UninstallPackage(LazPackage);
end;

procedure TPackageEditorForm.UseAllUnitsInDirectoryMenuItemClick(Sender: TObject);
begin
  DoUseUnitsInDirectory(true);
end;

procedure TPackageEditorForm.ViewPkgSourceClick(Sender: TObject);
begin
  PackageEditors.ViewPkgSource(LazPackage);
end;

procedure TPackageEditorForm.ViewPkgTodosClick(Sender: TObject);
begin
  PackageEditors.ViewPkgToDos(LazPackage);
end;

procedure TPackageEditorForm.FreeNodeData(Typ: TPENodeType);
var
  NodeData: TPENodeData;
  n: TPENodeData;
begin
  NodeData:=FFirstNodeData[Typ];
  while NodeData<>nil do begin
    n:=NodeData;
    NodeData:=NodeData.Next;
    if Assigned(n.Branch) Then
      n.Branch.FreeNodeData(n.Node);
    n.Free;
  end;
  FFirstNodeData[Typ]:=nil;
end;

function TPackageEditorForm.CreateNodeData(Typ: TPENodeType; aName: string;
  aRemoved: boolean): TPENodeData;
begin
  Result:=TPENodeData.Create(Typ,aName,aRemoved);
  Result.Next:=FFirstNodeData[Typ];
  FFirstNodeData[Typ]:=Result;
end;

procedure TPackageEditorForm.UseMaxVersionCheckBoxChange(Sender: TObject);
begin
  MaxVersionEdit.Enabled:=UseMaxVersionCheckBox.Checked;
  UpdateApplyDependencyButton;
end;

procedure TPackageEditorForm.UseMinVersionCheckBoxChange(Sender: TObject);
begin
  MinVersionEdit.Enabled:=UseMinVersionCheckBox.Checked;
  UpdateApplyDependencyButton;
end;

procedure TPackageEditorForm.UseNoUnitsInDirectoryMenuItemClick(Sender: TObject);
begin
  DoUseUnitsInDirectory(false);
end;

procedure TPackageEditorForm.AddBitBtnClick(Sender: TObject);
begin
  if LazPackage=nil then exit;
  BeginUdate;
  try
    ShowAddDialog(fLastDlgPage);
  finally
    EndUpdate;
  end;
end;

procedure TPackageEditorForm.AddToUsesPkgSectionCheckBoxChange(Sender: TObject);
var
  CurFile: TPkgFile;
  i: Integer;
  OtherFile: TPkgFile;
  TVNode: TTreeNode;
  NodeData: TPENodeData;
  Item: TObject;
  j: Integer;
begin
  if LazPackage=nil then exit;
  BeginUdate;
  try
    for i:=0 to ItemsTreeView.SelectionCount-1 do begin
      TVNode:=ItemsTreeView.Selections[i];
      if not GetNodeDataItem(TVNode,NodeData,Item) then continue;
      if Item is TPkgFile then begin
        CurFile:=TPkgFile(Item);
        if not (CurFile.FileType in PkgFileUnitTypes) then continue;
        if CurFile.AddToUsesPkgSection=AddToUsesPkgSectionCheckBox.Checked then
          continue;
        // change flag
        CurFile.AddToUsesPkgSection:=AddToUsesPkgSectionCheckBox.Checked;
        if (not NodeData.Removed) and CurFile.AddToUsesPkgSection then begin
          // mark all other units with the same name as unused
          for j:=0 to LazPackage.FileCount-1 do begin
            OtherFile:=LazPackage.Files[j];
            if (OtherFile<>CurFile)
            and (SysUtils.CompareText(OtherFile.Unit_Name,CurFile.Unit_Name)=0) then
              OtherFile.AddToUsesPkgSection:=false;
          end;
        end;
        LazPackage.Modified:=true;
        UpdateFiles;
      end;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TPackageEditorForm.AddToProjectClick(Sender: TObject);
begin
  if LazPackage=nil then exit;
  PackageEditors.AddToProject(LazPackage,false);
end;

procedure TPackageEditorForm.ApplyDependencyButtonClick(Sender: TObject);
var
  CurDependency: TPkgDependency;
  Removed: boolean;
  NewDependency: TPkgDependency;
begin
  if LazPackage=nil then exit;
  CurDependency:=GetCurrentDependency(Removed);
  if (CurDependency=nil) or Removed then exit;

  NewDependency:=TPkgDependency.Create;
  try
    NewDependency.Assign(CurDependency);

    // read minimum version
    if UseMinVersionCheckBox.Checked then begin
      NewDependency.Flags:=NewDependency.Flags+[pdfMinVersion];
      if not NewDependency.MinVersion.ReadString(MinVersionEdit.Text) then begin
        MessageDlg(lisPckEditInvalidMinimumVersion,
          Format(lisPckEditTheMinimumVersionIsNotAValidPackageVersion, ['"',
            MinVersionEdit.Text, '"', LineEnding]),
          mtError,[mbCancel],0);
        exit;
      end;
    end else begin
      NewDependency.Flags:=NewDependency.Flags-[pdfMinVersion];
    end;

    // read maximum version
    if UseMaxVersionCheckBox.Checked then begin
      NewDependency.Flags:=NewDependency.Flags+[pdfMaxVersion];
      if not NewDependency.MaxVersion.ReadString(MaxVersionEdit.Text) then begin
        MessageDlg(lisPckEditInvalidMaximumVersion,
          Format(lisPckEditTheMaximumVersionIsNotAValidPackageVersion, ['"',
            MaxVersionEdit.Text, '"', LineEnding]),
          mtError,[mbCancel],0);
        exit;
      end;
    end else begin
      NewDependency.Flags:=NewDependency.Flags-[pdfMaxVersion];
    end;

    PackageGraph.ChangeDependency(CurDependency,NewDependency);
  finally
    NewDependency.Free;
  end;
end;

procedure TPackageEditorForm.CallRegisterProcCheckBoxChange(Sender: TObject);
var
  CurFile: TPkgFile;
  Removed: boolean;
begin
  if LazPackage=nil then exit;
  CurFile:=GetCurrentFile(Removed);
  if (CurFile=nil) then exit;
  if CurFile.HasRegisterProc=CallRegisterProcCheckBox.Checked then exit;
  CurFile.HasRegisterProc:=CallRegisterProcCheckBox.Checked;
  if not Removed then begin
    LazPackage.Modified:=true;
  end;
  UpdateFiles;
end;

procedure TPackageEditorForm.ChangeFileTypeMenuItemClick(Sender: TObject);
var
  CurPFT: TPkgFileType;
  Removed: boolean;
  CurFile: TPkgFile;
  CurItem: TIDEMenuCommand;
begin
  if LazPackage=nil then exit;
  CurItem:=TIDEMenuCommand(Sender);
  CurFile:=GetCurrentFile(Removed);
  if CurFile=nil then exit;
  for CurPFT:=Low(TPkgFileType) to High(TPkgFileType) do begin
    if CurItem.Caption=GetPkgFileTypeLocalizedName(CurPFT) then begin
      if (not FilenameIsPascalUnit(CurFile.Filename))
      and (CurPFT in PkgFileUnitTypes) then exit;
      if CurFile.FileType<>CurPFT then begin
        CurFile.FileType:=CurPFT;
        LazPackage.Modified:=true;
        UpdateFiles;
      end;
      exit;
    end;
  end;
end;

procedure TPackageEditorForm.CleanDependenciesMenuItemClick(Sender: TObject);
var
  ListOfNodeInfos: TObjectList;
  i: Integer;
  Info: TCPDNodeInfo;
  Dependency: TPkgDependency;
begin
  if LazPackage=nil then exit;
  ListOfNodeInfos:=nil;
  try
    if ShowCleanPkgDepDlg(LazPackage,ListOfNodeInfos)<>mrOk then exit;
    for i:=0 to ListOfNodeInfos.Count-1 do begin
      Info:=TCPDNodeInfo(ListOfNodeInfos[i]);
      Dependency:=LazPackage.FindDependencyByName(Info.Dependency);
      if Dependency<>nil then
        PackageGraph.RemoveDependencyFromPackage(LazPackage,Dependency,true);
    end;
  finally
    ListOfNodeInfos.Free;
  end;
end;

procedure TPackageEditorForm.CompileAllCleanClick(Sender: TObject);
begin
  if LazPackage=nil then exit;
  if MessageDlg(lisPckEditCompileEverything,
    lisPckEditReCompileThisAndAllRequiredPackages,
    mtConfirmation,[mbYes,mbNo],0)<>mrYes then exit;
  DoCompile(true,true);
end;

procedure TPackageEditorForm.CompileCleanClick(Sender: TObject);
begin
  DoCompile(true,false);
end;

procedure TPackageEditorForm.CompileBitBtnClick(Sender: TObject);
begin
  DoCompile(false,false);
end;

procedure TPackageEditorForm.CreateMakefileClick(Sender: TObject);
begin
  PackageEditors.CreateMakefile(LazPackage);
end;

procedure TPackageEditorForm.CreateFpmakeFileClick(Sender: TObject);
begin
  debugln(['TPackageEditorForm.CreateFpmakeFileClick AAA1']);
  PackageEditors.CreateFpmakeFile(LazPackage);
end;

procedure TPackageEditorForm.DirectoryHierarchyButtonClick(Sender: TObject);
begin
  ShowDirectoryHierarchy:=DirectoryHierarchyButton.Down;
end;

procedure TPackageEditorForm.DisableI18NForLFMCheckBoxChange(Sender: TObject);
var
  CurFile: TPkgFile;
  Removed: boolean;
begin
  if LazPackage=nil then exit;
  CurFile:=GetCurrentFile(Removed);
  if (CurFile=nil) then exit;
  if CurFile.DisableI18NForLFM=DisableI18NForLFMCheckBox.Checked then exit;
  CurFile.DisableI18NForLFM:=DisableI18NForLFMCheckBox.Checked;
  if not Removed then
    LazPackage.Modified:=true;
end;

procedure TPackageEditorForm.SetLazPackage(const AValue: TLazPackage);
begin
  if FLazPackage=AValue then exit;
  if FLazPackage<>nil then FLazPackage.Editor:=nil;
  FLazPackage:=AValue;
  if FLazPackage=nil then begin
    Name:=Name+'___off___';
    exit;
  end;
  Name:=PackageEditorWindowPrefix+LazPackage.Name;
  FLazPackage.Editor:=Self;
  // update components
  UpdateAll(true);
end;

procedure TPackageEditorForm.SetupComponents;

  function CreateToolButton(AName, ACaption, AHint, AImageName: String; AOnClick: TNotifyEvent): TToolButton;
  begin
    Result := TToolButton.Create(Self);
    Result.Name := AName;
    Result.Caption := ACaption;
    Result.Hint := AHint;
    if AImageName <> '' then
      Result.ImageIndex := IDEImages.LoadImage(16, AImageName);
    Result.ShowHint := True;
    Result.OnClick := AOnClick;
    Result.AutoSize := True;
    Result.Parent := ToolBar;
  end;

  function CreateDivider: TToolButton;
  begin
    Result := TToolButton.Create(Self);
    Result.Style := tbsDivider;
    Result.AutoSize := True;
    Result.Parent := ToolBar;
  end;

begin
  ImageIndexFiles           := IDEImages.LoadImage(16, 'pkg_files');
  ImageIndexRemovedFiles    := IDEImages.LoadImage(16, 'pkg_removedfiles');
  ImageIndexRequired        := IDEImages.LoadImage(16, 'pkg_required');
  ImageIndexRemovedRequired := IDEImages.LoadImage(16, 'pkg_removedrequired');
  ImageIndexUnit            := IDEImages.LoadImage(16, 'pkg_unit');
  ImageIndexRegisterUnit    := IDEImages.LoadImage(16, 'pkg_registerunit');
  ImageIndexLFM             := IDEImages.LoadImage(16, 'pkg_lfm');
  ImageIndexLRS             := IDEImages.LoadImage(16, 'pkg_lrs');
  ImageIndexInclude         := IDEImages.LoadImage(16, 'pkg_include');
  ImageIndexIssues          := IDEImages.LoadImage(16, 'pkg_issues');
  ImageIndexText            := IDEImages.LoadImage(16, 'pkg_text');
  ImageIndexBinary          := IDEImages.LoadImage(16, 'pkg_binary');
  ImageIndexConflict        := IDEImages.LoadImage(16, 'pkg_conflict');
  ImageIndexDirectory       := IDEImages.LoadImage(16, 'pkg_files');

  ItemsTreeView.Images := IDEImages.Images_16;
  ToolBar.Images := IDEImages.Images_16;
  FilterEdit.OnGetImageIndex:=@OnTreeViewGetImageIndex;

  SaveBitBtn    := CreateToolButton('SaveBitBtn', lisMenuSave, lisPckEditSavePackage, 'laz_save', @SaveBitBtnClick);
  CompileBitBtn := CreateToolButton('CompileBitBtn', lisCompile, lisPckEditCompilePackage, 'pkg_compile', @CompileBitBtnClick);
  UseBitBtn     := CreateToolButton('UseBitBtn', lisPckEditInstall, lisPckEditInstallPackageInTheIDE, 'pkg_install', nil);
  CreateDivider;
  AddBitBtn     := CreateToolButton('AddBitBtn', lisAdd, lisPckEditAddAnItem, 'laz_add', @AddBitBtnClick);
  RemoveBitBtn  := CreateToolButton('RemoveBitBtn', lisRemove, lisPckEditRemoveSelectedItem, 'laz_delete', @RemoveBitBtnClick);
  CreateDivider;
  OptionsBitBtn := CreateToolButton('OptionsBitBtn', dlgFROpts, lisPckEditEditGeneralOptions, 'pkg_properties', @OptionsBitBtnClick);
  HelpBitBtn    := CreateToolButton('HelpBitBtn', GetButtonCaption(idButtonHelp), lisPkgEdThereAreMoreFunctionsInThePopupmenu, 'menu_help', @HelpBitBtnClick);
  MoreBitBtn    := CreateToolButton('MoreBitBtn', lisMoreSub, lisPkgEdThereAreMoreFunctionsInThePopupmenu, '', nil);

  MoreBitBtn.DropdownMenu := MorePopupMenu;

  // Buttons on FilterPanel
  OpenButton.LoadGlyphFromResourceName(HInstance, 'laz_open');
  OpenButton.Hint:=lisOpenFile2;
  SortAlphabeticallyButton.Hint:=lisPESortFilesAlphabetically;
  SortAlphabeticallyButton.LoadGlyphFromResourceName(HInstance, 'pkg_sortalphabetically');
  DirectoryHierarchyButton.Hint:=lisPEShowDirectoryHierarchy;
  DirectoryHierarchyButton.LoadGlyphFromResourceName(HInstance, 'pkg_hierarchical');

  // Up / Down buttons
  MoveUpBtn.LoadGlyphFromResourceName(HInstance, 'arrow_up');
  MoveDownBtn.LoadGlyphFromResourceName(HInstance, 'arrow_down');
  MoveUpBtn.Hint:=lisMoveSelectedUp;
  MoveDownBtn.Hint:=lisMoveSelectedDown;

  ItemsTreeView.BeginUpdate;
  FFilesNode:=ItemsTreeView.Items.Add(nil, dlgEnvFiles);
  FFilesNode.ImageIndex:=ImageIndexFiles;
  FFilesNode.SelectedIndex:=FFilesNode.ImageIndex;
  FRequiredPackagesNode:=ItemsTreeView.Items.Add(nil, lisPckEditRequiredPackages);
  FRequiredPackagesNode.ImageIndex:=ImageIndexRequired;
  FRequiredPackagesNode.SelectedIndex:=FRequiredPackagesNode.ImageIndex;
  ItemsTreeView.EndUpdate;

  PropsGroupBox.Caption:=lisPckEditFileProperties;

  CallRegisterProcCheckBox.Caption:=lisPckEditRegisterUnit;
  CallRegisterProcCheckBox.Hint:=Format(lisPckEditCallRegisterProcedureOfSelectedUnit, ['"', '"']);

  AddToUsesPkgSectionCheckBox.Caption:=lisPkgMangUseUnit;
  AddToUsesPkgSectionCheckBox.Hint:=lisPkgMangAddUnitToUsesClauseOfPackageDisableThisOnlyForUnit;

  DisableI18NForLFMCheckBox.Caption:=lisPckDisableI18NOfLfm;
  DisableI18NForLFMCheckBox.Hint:=lisPckWhenTheFormIsSavedTheIDECanStoreAllTTranslateString;

  UseMinVersionCheckBox.Caption:=lisPckEditMinimumVersion;
  UseMaxVersionCheckBox.Caption:=lisPckEditMaximumVersion;
  ApplyDependencyButton.Caption:=lisPckEditApplyChanges;
  RegisteredPluginsGroupBox.Caption:=lisPckEditRegisteredPlugins;
  RegisteredListBox.ItemHeight:=ComponentPaletteImageHeight;

  FDirSummaryLabel:=TLabel.Create(Self);
  with FDirSummaryLabel do
  begin
    Name:='DirSummaryLabel';
    Parent:=PropsGroupBox;
  end;
end;

procedure TPackageEditorForm.SetDependencyDefaultFilename(AsPreferred: boolean);
var
  NewFilename: String;
  CurDependency: TPkgDependency;
  Removed: boolean;
begin
  CurDependency:=GetCurrentDependency(Removed);
  if (CurDependency=nil) or Removed then exit;
  if LazPackage.ReadOnly then exit;
  if CurDependency.RequiredPackage=nil then exit;
  NewFilename:=CurDependency.RequiredPackage.Filename;
  if (NewFilename=CurDependency.DefaultFilename)
  and (CurDependency.PreferDefaultFilename=AsPreferred) then
    exit;
  CurDependency.DefaultFilename:=NewFilename;
  CurDependency.PreferDefaultFilename:=AsPreferred;
  LazPackage.Modified:=true;
  UpdateRequiredPkgs;
  UpdateButtons;
end;

procedure TPackageEditorForm.SetIdleConnected(AValue: boolean);
begin
  if FIdleConnected=AValue then Exit;
  FIdleConnected:=AValue;
  if IdleConnected then
    Application.AddOnIdleHandler(@OnIdle)
  else
    Application.AddOnIdleHandler(@OnIdle);
end;

procedure TPackageEditorForm.SetShowDirectoryHierarchy(const AValue: boolean);
begin
  //debugln(['TPackageEditorForm.SetShowDirectoryHierachy Old=',FShowDirectoryHierarchy,' New=',AValue]);
  if FShowDirectoryHierarchy=AValue then exit;
  FShowDirectoryHierarchy:=AValue;
  DirectoryHierarchyButton.Down:=FShowDirectoryHierarchy;
  FilterEdit.ShowDirHierarchy:=FShowDirectoryHierarchy;
  FilterEdit.InvalidateFilter;
end;

procedure TPackageEditorForm.SetSortAlphabetically(const AValue: boolean);
begin
  if FSortAlphabetically=AValue then exit;
  FSortAlphabetically:=AValue;
  SortAlphabeticallyButton.Down:=FSortAlphabetically;
  FilterEdit.SortData:=FSortAlphabetically;
  FilterEdit.InvalidateFilter;
end;

procedure TPackageEditorForm.UpdateAll(Immediately: boolean);
begin
  if csDestroying in ComponentState then exit;
  if LazPackage=nil then exit;
  Name:=PackageEditorWindowPrefix+LazPackage.Name;
  UpdateTitle(Immediately);
  UpdateButtons(Immediately);
  UpdateFiles(Immediately);
  UpdateRequiredPkgs(Immediately);
  UpdatePEProperties(Immediately);
  UpdateStatusBar(Immediately);
end;

function TPackageEditorForm.ShowAddDialog(var DlgPage: TAddToPkgType): TModalResult;
var
  IgnoreUnitPaths, IgnoreIncPaths: TFilenameToStringTree;

  function PkgDependsOn(PkgName: string): boolean;
  begin
    if PkgName='' then exit(false);
    Result:=PackageGraph.FindDependencyRecursively(LazPackage.FirstRequiredDependency,PkgName)<>nil;
  end;

  procedure AddUnit(AddParams: TAddToPkgResult);
  var
    NewLFMFilename: String;
    NewLRSFilename: String;
  begin
    NewLFMFilename:='';
    NewLRSFilename:='';
    // add lfm file
    if AddParams.AutoAddLFMFile then begin
      NewLFMFilename:=ChangeFileExt(AddParams.UnitFilename,'.lfm');
      if FileExistsUTF8(NewLFMFilename)
      and (LazPackage.FindPkgFile(NewLFMFilename,true,false)=nil) then
        LazPackage.AddFile(NewLFMFilename,'',pftLFM,[],cpNormal)
      else
        NewLFMFilename:='';
    end;
    // add lrs file
    if AddParams.AutoAddLRSFile then begin
      NewLRSFilename:=ChangeFileExt(AddParams.UnitFilename,'.lrs');
      if FileExistsUTF8(NewLRSFilename)
      and (LazPackage.FindPkgFile(NewLRSFilename,true,false)=nil) then
        LazPackage.AddFile(NewLRSFilename,'',pftLRS,[],cpNormal)
      else
        NewLRSFilename:='';
    end;
    ExtendUnitIncPathForNewUnit(AddParams.UnitFilename,NewLRSFilename,
                                IgnoreUnitPaths);
    // add unit file
    with AddParams do
      LazPackage.AddFile(UnitFilename,Unit_Name,
                                          FileType,PkgFileFlags,cpNormal);
    FreeAndNil(FNextSelectedPart);
    FNextSelectedPart:=TPENodeData.Create(penFile,AddParams.UnitFilename,false);
    PackageEditors.DeleteAmbiguousFiles(LazPackage,AddParams.UnitFilename);
    UpdateFiles;
  end;

  procedure AddVirtualUnit(AddParams: TAddToPkgResult);
  begin
    with AddParams do
      LazPackage.AddFile(UnitFilename,Unit_Name,FileType,
                                          PkgFileFlags,cpNormal);
    FreeAndNil(FNextSelectedPart);
    FNextSelectedPart:=TPENodeData.Create(penFile,AddParams.UnitFilename,false);
    PackageEditors.DeleteAmbiguousFiles(LazPackage,AddParams.UnitFilename);
    UpdateFiles;
  end;

  procedure AddNewComponent(AddParams: TAddToPkgResult);
  begin
    ExtendUnitIncPathForNewUnit(AddParams.UnitFilename,'',IgnoreUnitPaths);
    // add file
    with AddParams do
      LazPackage.AddFile(UnitFilename,Unit_Name,FileType,
                                              PkgFileFlags,cpNormal);
    FreeAndNil(FNextSelectedPart);
    FNextSelectedPart:=TPENodeData.Create(penFile,AddParams.UnitFilename,false);
    // add dependency
    if (AddParams.Dependency<>nil)
    and (not PkgDependsOn(AddParams.Dependency.PackageName)) then
      PackageGraph.AddDependencyToPackage(LazPackage,AddParams.Dependency);
    if (AddParams.IconFile<>'')
    and (not PkgDependsOn('LCL')) then
      PackageGraph.AddDependencyToPackage(LazPackage,PackageGraph.LCLPackage);
    PackageEditors.DeleteAmbiguousFiles(LazPackage,AddParams.UnitFilename);
    // open file in editor
    PackageEditors.CreateNewFile(Self,AddParams);
    UpdateFiles;
  end;

  procedure AddRequiredPkg(AddParams: TAddToPkgResult);
  begin
    // add dependency
    PackageGraph.AddDependencyToPackage(LazPackage,AddParams.Dependency);
    FreeAndNil(FNextSelectedPart);
    FNextSelectedPart:=TPENodeData.Create(penDependency,
                                        AddParams.Dependency.PackageName,false);
    UpdateRequiredPkgs;
  end;

  procedure AddFile(AddParams: TAddToPkgResult);
  begin
    // add file
    with AddParams do begin
      if (CompareFileExt(UnitFilename,'.inc',false)=0)
      or (CompareFileExt(UnitFilename,'.lrs',false)=0) then
        ExtendIncPathForNewIncludeFile(UnitFilename,IgnoreIncPaths);
      LazPackage.AddFile(UnitFilename,Unit_Name,FileType,
                                          PkgFileFlags,cpNormal);
    end;
    FreeAndNil(FNextSelectedPart);
    FNextSelectedPart:=TPENodeData.Create(penFile,AddParams.UnitFilename,false);
    UpdateFiles;
  end;

  procedure AddNewFile(AddParams: TAddToPkgResult);
  var
    NewFilename: String;
    DummyResult: TModalResult;
    NewFileType: TPkgFileType;
    NewPkgFileFlags: TPkgFileFlags;
    Desc: TProjectFileDescriptor;
    NewUnitName: String;
    HasRegisterProc: Boolean;
  begin
    if AddParams.NewItem is TNewItemProjectFile then begin
      // create new file
      Desc:=TNewItemProjectFile(AddParams.NewItem).Descriptor;
      NewFilename:='';
      DummyResult:=LazarusIDE.DoNewFile(Desc,NewFilename,'',
        [nfOpenInEditor,nfCreateDefaultSrc,nfIsNotPartOfProject],LazPackage);
      if DummyResult=mrOk then begin
        // success -> now add it to package
        NewUnitName:='';
        NewFileType:=FileNameToPkgFileType(NewFilename);
        NewPkgFileFlags:=[];
        if (NewFileType in PkgFileUnitTypes) then begin
          Include(NewPkgFileFlags,pffAddToPkgUsesSection);
          NewUnitName:=ExtractFilenameOnly(NewFilename);
          if Assigned(PackageEditors.OnGetUnitRegisterInfo) then begin
            HasRegisterProc:=false;
            PackageEditors.OnGetUnitRegisterInfo(Self,NewFilename,
              NewUnitName,HasRegisterProc);
            if HasRegisterProc then
              Include(NewPkgFileFlags,pffHasRegisterProc);
          end;
        end;
        LazPackage.AddFile(NewFilename,NewUnitName,NewFileType,
                                                NewPkgFileFlags, cpNormal);
        FreeAndNil(FNextSelectedPart);
        FNextSelectedPart:=TPENodeData.Create(penFile,NewFilename,false);
        UpdateFiles;
      end;
    end;
  end;

var
  AddParams: TAddToPkgResult;
  OldParams: TAddToPkgResult;
begin
  if LazPackage.ReadOnly then begin
    UpdateButtons;
    exit(mrCancel);
  end;

  Result:=ShowAddToPackageDlg(LazPackage,AddParams,PackageEditors.OnGetIDEFileInfo,
    PackageEditors.OnGetUnitRegisterInfo,DlgPage);
  fLastDlgPage:=DlgPage;
  if Result<>mrOk then exit;

  PackageGraph.BeginUpdate(false);
  IgnoreUnitPaths:=nil;
  IgnoreIncPaths:=nil;
  try
    while AddParams<>nil do begin
      case AddParams.AddType of

      d2ptUnit:
        AddUnit(AddParams);

      d2ptVirtualUnit:
        AddVirtualUnit(AddParams);

      d2ptNewComponent:
        AddNewComponent(AddParams);

      d2ptRequiredPkg:
        AddRequiredPkg(AddParams);

      d2ptFile:
        AddFile(AddParams);

      d2ptNewFile:
        AddNewFile(AddParams);

      end;
      OldParams:=AddParams;
      AddParams:=AddParams.Next;
      OldParams.Next:=nil;
      OldParams.Free;
    end;
    AddParams.Free;
    LazPackage.Modified:=true;
  finally
    IgnoreUnitPaths.Free;
    IgnoreIncPaths.Free;
    PackageGraph.EndUpdate;
  end;
end;

procedure TPackageEditorForm.BeginUdate;
begin
  inc(fUpdateLock);
end;

procedure TPackageEditorForm.EndUpdate;
begin
  if fUpdateLock=0 then
    RaiseException('');
  dec(fUpdateLock);
  UpdatePending;
end;

procedure TPackageEditorForm.UpdateTitle(Immediately: boolean);
var
  NewCaption: String;
begin
  if not CanUpdate(pefNeedUpdateTitle) then exit;
  NewCaption:=Format(lisPckEditPackage, [FLazPackage.Name]);
  if LazPackage.Modified then
    NewCaption:=NewCaption+'*';
  Caption:=NewCaption;
end;

procedure TPackageEditorForm.UpdateButtons(Immediately: boolean);
var
  Removed: boolean;
  CurFile: TPkgFile;
  CurDependency: TPkgDependency;
begin
  if not CanUpdate(pefNeedUpdateButtons) then exit;

  CurFile:=GetCurrentFile(Removed);
  if CurFile=nil then
    CurDependency:=GetCurrentDependency(Removed)
  else
    CurDependency:=nil;

  SaveBitBtn.Enabled:=(not LazPackage.ReadOnly)
                              and (LazPackage.IsVirtual or LazPackage.Modified);
  CompileBitBtn.Enabled:=(not LazPackage.IsVirtual) and LazPackage.CompilerOptions.HasCommands;
  AddBitBtn.Enabled:=not LazPackage.ReadOnly;
  RemoveBitBtn.Enabled:=(not LazPackage.ReadOnly)
     and (not Removed)
     and ((CurFile<>nil) or (CurDependency<>nil));
  OpenButton.Enabled:=(CurFile<>nil) or (CurDependency<>nil);
  UseBitBtn.Caption:=lisUseSub;
  UseBitBtn.Hint:=lisClickToSeeThePossibleUses;
  UseBitBtn.OnClick:=nil;
  UseBitBtn.DropdownMenu:=UsePopupMenu;
  OptionsBitBtn.Enabled:=true;
end;

function TPackageEditorForm.OnTreeViewGetImageIndex(Str: String; Data: TObject;
                                             var AIsEnabled: Boolean): Integer;
var
  PkgFile: TPkgFile;
  Item: TObject;
  PkgDependency: TPkgDependency;
  NodeData: TPENodeData;
begin
  Result:=-1;
  if not (Data is TPENodeData) then exit;
  NodeData:=TPENodeData(Data);
  Item:=GetNodeItem(NodeData);
  if Item=nil then exit;
  if Item is TPkgFile then begin
    PkgFile:=TPkgFile(Item);
    case PkgFile.FileType of
      pftUnit,pftVirtualUnit,pftMainUnit:
        if PkgFile.HasRegisterProc then
          Result:=ImageIndexRegisterUnit
        else
          Result:=ImageIndexUnit;
      pftLFM: Result:=ImageIndexLFM;
      pftLRS: Result:=ImageIndexLRS;
      pftInclude: Result:=ImageIndexInclude;
      pftIssues: Result:=ImageIndexIssues;
      pftText: Result:=ImageIndexText;
      pftBinary: Result:=ImageIndexBinary;
      else
        Result:=-1;
    end;
  end
  else if Item is TPkgDependency then begin
    PkgDependency:=TPkgDependency(Item);
    if PkgDependency.Removed then
      Result:=ImageIndexRemovedRequired
    else if PkgDependency.LoadPackageResult=lprSuccess then
      Result:=ImageIndexRequired
    else
      Result:=ImageIndexConflict;
  end;
end;

procedure TPackageEditorForm.UpdatePending;
begin
  if pefNeedUpdateTitle in fFlags then
    UpdateTitle(true);
  if pefNeedUpdateButtons in fFlags then
    UpdateButtons(true);
  if pefNeedUpdateFiles in fFlags then
    UpdateFiles(true);
  if pefNeedUpdateRequiredPkgs in fFlags then
    UpdateRequiredPkgs(true);
  if pefNeedUpdateProperties in fFlags then
    UpdatePEProperties(true);
  if pefNeedUpdateApplyDependencyButton in fFlags then
    UpdateApplyDependencyButton(true);
  if pefNeedUpdateStatusBar in fFlags then
    UpdateStatusBar(true);
end;

function TPackageEditorForm.CanUpdate(Flag: TPEFlag): boolean;
begin
  Result:=false;
  if csDestroying in ComponentState then exit;
  if LazPackage=nil then exit;
  if fUpdateLock>0 then begin
    Include(fFlags,Flag);
    IdleConnected:=true;
    Result:=false;
  end else begin
    Exclude(fFlags,Flag);
    Result:=true;
  end;
end;

procedure TPackageEditorForm.UpdateFiles(Immediately: boolean);
var
  i: Integer;
  CurFile: TPkgFile;
  FilesBranch, RemovedBranch: TTreeFilterBranch;
  Filename: String;
  NodeData: TPENodeData;
  OldFilter : String;
begin
  if not CanUpdate(pefNeedUpdateFiles) then exit;

  OldFilter := FilterEdit.ForceFilter('');

  // files belonging to package
  FilesBranch:=FilterEdit.GetBranch(FFilesNode);
  FreeNodeData(penFile);
  FilesBranch.Clear;
  FilterEdit.SelectedPart:=nil;
  FilterEdit.ShowDirHierarchy:=ShowDirectoryHierarchy;
  FilterEdit.SortData:=SortAlphabetically;
  FilterEdit.ImageIndexDirectory:=ImageIndexDirectory;
  // collect and sort files
  for i:=0 to LazPackage.FileCount-1 do begin
    CurFile:=LazPackage.Files[i];
    NodeData:=CreateNodeData(penFile,CurFile.Filename,false);
    Filename:=CurFile.GetShortFilename(true);
    if Filename='' then continue;
    if (FNextSelectedPart<>nil) and (FNextSelectedPart.Typ=penFile)
    and (FNextSelectedPart.Name=NodeData.Name)
    then
      FilterEdit.SelectedPart:=NodeData;
    FilesBranch.AddNodeData(Filename, NodeData, CurFile.Filename);
  end;
  if (FNextSelectedPart<>nil) and (FNextSelectedPart.Typ=penFile) then
    FreeAndNil(FNextSelectedPart);

  // removed files
  if LazPackage.RemovedFilesCount>0 then begin
    // Create root node for removed dependencies if not done yet.
    if FRemovedFilesNode=nil then begin
      FRemovedFilesNode:=ItemsTreeView.Items.Add(FRequiredPackagesNode,
                                                 lisPckEditRemovedFiles);
      FRemovedFilesNode.ImageIndex:=ImageIndexRemovedFiles;
      FRemovedFilesNode.SelectedIndex:=FRemovedFilesNode.ImageIndex;
    end;
    RemovedBranch:=FilterEdit.GetBranch(FRemovedFilesNode);
    RemovedBranch.Clear;
    for i:=0 to LazPackage.RemovedFilesCount-1 do begin
      CurFile:=LazPackage.RemovedFiles[i];
      NodeData:=CreateNodeData(penFile,CurFile.Filename,true);
      RemovedBranch.AddNodeData(CurFile.GetShortFilename(true), NodeData);
    end;
  end else begin
    // No more removed files left -> delete the root node
    if FRemovedFilesNode<>nil then begin
      FilterEdit.DeleteBranch(FRemovedFilesNode);
      FreeAndNil(FRemovedFilesNode);
    end;
  end;
  FilterEdit.Filter := OldFilter;            // This triggers ApplyFilter

  UpdatePEProperties(true);
end;

procedure TPackageEditorForm.UpdateRequiredPkgs(Immediately: boolean);
var
  CurDependency: TPkgDependency;
  RequiredBranch, RemovedBranch: TTreeFilterBranch;
  CurNodeText, aFilename, OldFilter: String;
  NodeData: TPENodeData;
begin
  if not CanUpdate(pefNeedUpdateRequiredPkgs) then exit;

  OldFilter := FilterEdit.ForceFilter('');

  // required packages
  RequiredBranch:=FilterEdit.GetBranch(FRequiredPackagesNode);
  FreeNodeData(penDependency);
  RequiredBranch.Clear;
  CurDependency:=LazPackage.FirstRequiredDependency;
  FilterEdit.SelectedPart:=nil;
  while CurDependency<>nil do begin
    CurNodeText:=CurDependency.AsString;
    if CurDependency.DefaultFilename<>'' then begin
      aFilename:=CurDependency.MakeFilenameRelativeToOwner(CurDependency.DefaultFilename);
      if CurDependency.PreferDefaultFilename then
        CurNodeText:=CurNodeText+' in '+aFilename // like the 'in' keyword in uses section
      else
        CurNodeText:=Format(lisPckEditDefault, [CurNodeText, aFilename]);
    end;
    NodeData:=CreateNodeData(penDependency,CurDependency.PackageName,false);
    if (FNextSelectedPart<>nil) and (FNextSelectedPart.Typ=penDependency)
    and (FNextSelectedPart.Name=NodeData.Name)
    then
      FilterEdit.SelectedPart:=NodeData;
    RequiredBranch.AddNodeData(CurNodeText, NodeData);
    CurDependency:=CurDependency.NextRequiresDependency;
  end;
  if (FNextSelectedPart<>nil) and (FNextSelectedPart.Typ=penDependency) then
    FreeAndNil(FNextSelectedPart);

  // removed required packages
  CurDependency:=LazPackage.FirstRemovedDependency;
  if CurDependency<>nil then begin
    if FRemovedRequiredNode=nil then begin
      FRemovedRequiredNode:=ItemsTreeView.Items.Add(nil,lisPckEditRemovedRequiredPackages);
      FRemovedRequiredNode.ImageIndex:=ImageIndexRemovedRequired;
      FRemovedRequiredNode.SelectedIndex:=FRemovedRequiredNode.ImageIndex;
    end;
    RemovedBranch:=FilterEdit.GetBranch(FRemovedRequiredNode);
    RemovedBranch.Clear;
    while CurDependency<>nil do begin
      NodeData:=CreateNodeData(penDependency,CurDependency.PackageName,true);
      RemovedBranch.AddNodeData(CurDependency.AsString, NodeData);
      CurDependency:=CurDependency.NextRequiresDependency;
    end;
  end else begin
    if FRemovedRequiredNode<>nil then begin
      FilterEdit.DeleteBranch(FRemovedRequiredNode);
      FreeAndNil(FRemovedRequiredNode);
    end;
  end;
  FNextSelectedPart:=nil;
  FilterEdit.ForceFilter(OldFilter);

  UpdatePEProperties(true);
end;

procedure TPackageEditorForm.UpdatePEProperties(Immediately: boolean);
type
  TMultiBool = (mubNone, mubAllTrue, mubAllFalse, mubMixed);

  procedure MergeMultiBool(var b: TMultiBool; NewValue: boolean);
  begin
    case b of
    mubNone: if NewValue then b:=mubAllTrue else b:=mubAllFalse;
    mubAllTrue: if not NewValue then b:=mubMixed;
    mubAllFalse: if NewValue then b:=mubMixed;
    mubMixed: ;
    end;
  end;

  procedure SetCheckBox(Box: TCheckBox; aVisible: boolean; State: TMultiBool);
  begin
    Box.Visible:=aVisible;
    case State of
    mubAllTrue:
      begin
        Box.State:=cbChecked;
        Box.AllowGrayed:=false;
      end;
    mubAllFalse:
      begin
        Box.State:=cbUnchecked;
        Box.AllowGrayed:=false;
      end;
    mubMixed:
      begin
        Box.AllowGrayed:=true;
        Box.State:=cbGrayed;
      end;
    end;
  end;

var
  CurFile: TPkgFile;
  CurDependency: TPkgDependency;
  CurComponent: TPkgComponent;
  CurLine, CurFilename: string;
  i, j: Integer;
  NodeData: TPENodeData;
  Item: TObject;
  SelFileCount: Integer;
  SelDepCount: Integer;
  SelHasRegisterProc: TMultiBool;
  SelAddToUsesPkgSection: TMultiBool;
  SelDisableI18NForLFM: TMultiBool;
  SelUnitCount: Integer;
  SelDirCount: Integer;
  SelHasLFMCount: Integer;
  OnlyFilesSelected: Boolean;
  OnlyFilesWithUnitsSelected: Boolean;
  aVisible: Boolean;
  TVNode: TTreeNode;
  SingleSelectedDirectory: TTreeNode;
  SingleSelectedRemoved: Boolean;
  SingleSelected: TTreeNode;
  FileCount: integer;
  HasRegisterProcCount: integer;
  AddToUsesPkgSectionCount: integer;
begin
  if not CanUpdate(pefNeedUpdateProperties) then exit;

  FPlugins.Clear;

  // check selection
  FSingleSelectedDependency:=nil;
  FSingleSelectedFile:=nil;
  SingleSelectedDirectory:=nil;
  SingleSelectedRemoved:=false;
  SingleSelected:=nil;
  SelFileCount:=0;
  SelDepCount:=0;
  SelHasRegisterProc:=mubNone;
  SelAddToUsesPkgSection:=mubNone;
  SelDisableI18NForLFM:=mubNone;
  SelUnitCount:=0;
  SelHasLFMCount:=0;
  SelDirCount:=0;
  for i:=0 to ItemsTreeView.SelectionCount-1 do begin
    TVNode:=ItemsTreeView.Selections[i];
    if GetNodeDataItem(TVNode,NodeData,Item) then begin
      if Item is TPkgFile then begin
        CurFile:=TPkgFile(Item);
        inc(SelFileCount);
        FSingleSelectedFile:=CurFile;
        SingleSelected:=TVNode;
        SingleSelectedRemoved:=NodeData.Removed;
        MergeMultiBool(SelHasRegisterProc,CurFile.HasRegisterProc);
        if CurFile.FileType in PkgFileUnitTypes then begin
          inc(SelUnitCount);
          MergeMultiBool(SelAddToUsesPkgSection,CurFile.AddToUsesPkgSection);
          if (CurFile.FileType in PkgFileRealUnitTypes) then
          begin
            CurFilename:=CurFile.GetFullFilename;
            if FilenameIsAbsolute(CurFilename)
                and FileExistsCached(ChangeFileExt(CurFilename,'.lfm'))
            then begin
              inc(SelHasLFMCount);
              MergeMultiBool(SelDisableI18NForLFM,CurFile.DisableI18NForLFM);
            end;
          end;
          // fetch all registered plugins
          for j:=0 to CurFile.ComponentCount-1 do begin
            CurComponent:=CurFile.Components[j];
            CurLine:=CurComponent.ComponentClass.ClassName;
            FPlugins.AddObject(CurLine,CurComponent);
          end;
        end;
      end else if Item is TPkgDependency then begin
        inc(SelDepCount);
        CurDependency:=TPkgDependency(Item);
        FSingleSelectedDependency:=CurDependency;
        SingleSelected:=TVNode;
        SingleSelectedRemoved:=NodeData.Removed;
      end;
    end else if IsDirectoryNode(TVNode) or (TVNode=FFilesNode) then begin
      inc(SelDirCount);
      SingleSelectedDirectory:=TVNode;
      SingleSelected:=TVNode;
    end;
  end;

  if (SelFileCount+SelDepCount+SelDirCount>1) then begin
    // it is a multi selection
    FSingleSelectedFile:=nil;
    FSingleSelectedDependency:=nil;
    SingleSelectedDirectory:=nil;
    SingleSelected:=nil;
  end;
  OnlyFilesSelected:=(SelFileCount>0) and (SelDepCount=0) and (SelDirCount=0);
  OnlyFilesWithUnitsSelected:=OnlyFilesSelected and (SelUnitCount>0);

  //debugln(['TPackageEditorForm.UpdatePEProperties SelFileCount=',SelFileCount,' SelDepCount=',SelDepCount,' SelDirCount=',SelDirCount,' SelUnitCount=',SelUnitCount]);
  //debugln(['TPackageEditorForm.UpdatePEProperties FSingleSelectedFile=',FSingleSelectedFile<>nil,' FSingleSelectedDependency=',FSingleSelectedDependency<>nil,' SingleSelectedDirectory=',SingleSelectedDirectory<>nil]);

  DisableAlign;
  try
    // move up/down (only single selection)
    aVisible:=(not (SortAlphabetically or SingleSelectedRemoved))
       and ((FSingleSelectedFile<>nil) or (FSingleSelectedDependency<>nil));
    MoveUpBtn.Enabled  :=aVisible and Assigned(SingleSelected.GetPrevVisibleSibling);
    MoveDownBtn.Enabled:=aVisible and Assigned(SingleSelected.GetNextVisibleSibling);

    // Min/Max version of dependency (only single selection)
    aVisible:=FSingleSelectedDependency<>nil;
    UseMinVersionCheckBox.Visible:=aVisible;
    MinVersionEdit.Visible:=aVisible;
    UseMaxVersionCheckBox.Visible:=aVisible;
    MaxVersionEdit.Visible:=aVisible;
    ApplyDependencyButton.Visible:=aVisible;

    // 'RegisterProc' of files (supports multi selection)
    SetCheckBox(CallRegisterProcCheckBox,OnlyFilesWithUnitsSelected,
      SelHasRegisterProc);
    CallRegisterProcCheckBox.Enabled:=(not LazPackage.ReadOnly);

    // 'Add to uses' of files (supports multi selection)
    SetCheckBox(AddToUsesPkgSectionCheckBox,OnlyFilesWithUnitsSelected,
      SelAddToUsesPkgSection);
    AddToUsesPkgSectionCheckBox.Enabled:=(not LazPackage.ReadOnly);

    // disable i18n for lfm (supports multi selection)
    SetCheckBox(DisableI18NForLFMCheckBox,
     OnlyFilesWithUnitsSelected and (SelHasLFMCount>0) and LazPackage.EnableI18N
     and LazPackage.EnableI18NForLFM,
     SelDisableI18NForLFM);
    DisableI18NForLFMCheckBox.Enabled:=(not LazPackage.ReadOnly);

    // registered plugins (supports multi selection)
    RegisteredPluginsGroupBox.Visible:=OnlyFilesWithUnitsSelected;
    RegisteredPluginsGroupBox.Enabled:=(not LazPackage.ReadOnly);
    if not RegisteredPluginsGroupBox.Visible then
      FPlugins.Clear;
    RegisteredListBox.Items.Assign(FPlugins);

    // directory summary (only single selection)
    FDirSummaryLabel.Visible:=(SelFileCount=0) and (SelDepCount=0) and (SelDirCount=1);

    if SelFileCount>0 then begin
      PropsGroupBox.Enabled:=true;
      PropsGroupBox.Caption:=lisPckEditFileProperties;
    end
    else if FSingleSelectedDependency<>nil then begin
      PropsGroupBox.Enabled:=not SingleSelectedRemoved;
      PropsGroupBox.Caption:=lisPckEditDependencyProperties;
      UseMinVersionCheckBox.Checked:=pdfMinVersion in FSingleSelectedDependency.Flags;
      MinVersionEdit.Text:=FSingleSelectedDependency.MinVersion.AsString;
      MinVersionEdit.Enabled:=pdfMinVersion in FSingleSelectedDependency.Flags;
      UseMaxVersionCheckBox.Checked:=pdfMaxVersion in FSingleSelectedDependency.Flags;
      MaxVersionEdit.Text:=FSingleSelectedDependency.MaxVersion.AsString;
      MaxVersionEdit.Enabled:=pdfMaxVersion in FSingleSelectedDependency.Flags;
      UpdateApplyDependencyButton;
    end
    else if SingleSelectedDirectory<>nil then begin
      PropsGroupBox.Enabled:=true;
      GetDirectorySummary(SingleSelectedDirectory,
        FileCount,HasRegisterProcCount,AddToUsesPkgSectionCount);
      FDirSummaryLabel.Caption:=Format(
        lisFilesHasRegisterProcedureInPackageUsesSection, [IntToStr(FileCount),
        IntToStr(HasRegisterProcCount), IntToStr(AddToUsesPkgSectionCount)]);
    end
    else begin
      PropsGroupBox.Enabled:=false;
    end;
  finally
    EnableAlign;
  end;
end;

procedure TPackageEditorForm.UpdateApplyDependencyButton(Immediately: boolean);
var
  DepencyChanged: Boolean;
  CurDependency: TPkgDependency;
  AVersion: TPkgVersion;
  Removed: boolean;
begin
  if not CanUpdate(pefNeedUpdateApplyDependencyButton) then exit;

  DepencyChanged:=false;
  CurDependency:=GetCurrentDependency(Removed);
  if (CurDependency<>nil) then begin
    // check min version
    if UseMinVersionCheckBox.Checked<>(pdfMinVersion in CurDependency.Flags) then
      DepencyChanged:=true;
    if UseMinVersionCheckBox.Checked then begin
      AVersion:=TPkgVersion.Create;
      if AVersion.ReadString(MinVersionEdit.Text)
      and (AVersion.Compare(CurDependency.MinVersion)<>0) then
        DepencyChanged:=true;
      AVersion.Free;
    end;
    // check max version
    if UseMaxVersionCheckBox.Checked<>(pdfMaxVersion in CurDependency.Flags) then
      DepencyChanged:=true;
    if UseMaxVersionCheckBox.Checked then begin
      AVersion:=TPkgVersion.Create;
      if AVersion.ReadString(MaxVersionEdit.Text)
      and (AVersion.Compare(CurDependency.MaxVersion)<>0) then
        DepencyChanged:=true;
      AVersion.Free;
    end;
  end;
  ApplyDependencyButton.Enabled:=DepencyChanged;
end;

procedure TPackageEditorForm.UpdateStatusBar(Immediately: boolean);
var
  StatusText: String;
begin
  if not CanUpdate(pefNeedUpdateStatusBar) then exit;

  if LazPackage.IsVirtual and (not LazPackage.ReadOnly) then begin
    StatusText:=Format(lisPckEditpackageNotSaved, [LazPackage.Name]);
  end else begin
    StatusText:=LazPackage.Filename;
  end;
  if LazPackage.ReadOnly then
    StatusText:=Format(lisPckEditReadOnly, [StatusText]);
  if LazPackage.Modified then
    StatusText:=Format(lisPckEditModified, [StatusText]);
  StatusBar.SimpleText:=StatusText;
end;

function TPackageEditorForm.GetCurrentDependency(out Removed: boolean): TPkgDependency;
var
  NodeData: TPENodeData;
begin
  Result:=nil;
  Removed:=false;
  NodeData:=GetNodeData(ItemsTreeView.Selected);
  if NodeData=nil then exit;
  if NodeData.Typ<>penDependency then exit;
  Removed:=NodeData.Removed;
  if Removed then
    Result:=LazPackage.FindRemovedDependencyByName(NodeData.Name)
  else
    Result:=LazPackage.FindDependencyByName(NodeData.Name);
end;

function TPackageEditorForm.GetCurrentFile(out Removed: boolean): TPkgFile;
var
  NodeData: TPENodeData;
begin
  Result:=nil;
  Removed:=false;
  NodeData:=GetNodeData(ItemsTreeView.Selected);
  if NodeData=nil then exit;
  if NodeData.Typ<>penFile then exit;
  Removed:=NodeData.Removed;
  if Removed then
    Result:=LazPackage.FindRemovedPkgFile(NodeData.Name)
  else
    Result:=LazPackage.FindPkgFile(NodeData.Name,true,true);
end;

function TPackageEditorForm.GetNodeData(TVNode: TTreeNode): TPENodeData;
var
  o: TObject;
begin
  Result:=nil;
  if (TVNode=nil) then exit;
  o:=TObject(TVNode.Data);
  if o is TFileNameItem then
    o:=TObject(TFileNameItem(o).Data);
  if o is TPENodeData then
    Result:=TPENodeData(o);
end;

function TPackageEditorForm.GetNodeItem(NodeData: TPENodeData): TObject;
begin
  Result:=nil;
  if (LazPackage=nil) or (NodeData=nil) then exit;
  case NodeData.Typ of
  penFile:
    if NodeData.Removed then
      Result:=LazPackage.FindRemovedPkgFile(NodeData.Name)
    else
      Result:=LazPackage.FindPkgFile(NodeData.Name,true,true);
  penDependency:
    if NodeData.Removed then
      Result:=LazPackage.FindRemovedDependencyByName(NodeData.Name)
    else
      Result:=LazPackage.FindDependencyByName(NodeData.Name);
  end;
end;

function TPackageEditorForm.GetNodeDataItem(TVNode: TTreeNode; out
  NodeData: TPENodeData; out Item: TObject): boolean;
begin
  Result:=false;
  Item:=nil;
  NodeData:=GetNodeData(TVNode);
  Item:=GetNodeItem(NodeData);
  Result:=Item<>nil;
end;

function TPackageEditorForm.IsDirectoryNode(Node: TTreeNode): boolean;
begin
  Result:=(Node<>nil) and (Node.Data=nil) and Node.HasAsParent(FFilesNode);
end;

procedure TPackageEditorForm.GetDirectorySummary(DirNode: TTreeNode; out
  FileCount, HasRegisterProcCount, AddToUsesPkgSectionCount: integer);

  procedure Traverse(Node: TTreeNode);
  var
    CurFile: TPkgFile;
    NodeData: TPENodeData;
  begin
    NodeData:=GetNodeData(Node);
    if NodeData<>nil then begin
      if NodeData.Typ=penFile then begin
        CurFile:=LazPackage.FindPkgFile(NodeData.Name,true,true);
        if CurFile<>nil then begin
          inc(FileCount);
          if CurFile.HasRegisterProc then inc(HasRegisterProcCount);
          if CurFile.AddToUsesPkgSection then inc(AddToUsesPkgSectionCount);
        end;
      end;
    end;
    Node:=Node.GetFirstChild;
    while Node<>nil do begin
      Traverse(Node);
      Node:=Node.GetNextSibling;
    end;
  end;

begin
  FileCount:=0;
  HasRegisterProcCount:=0;
  AddToUsesPkgSectionCount:=0;
  Traverse(DirNode);
end;

procedure TPackageEditorForm.ExtendUnitIncPathForNewUnit(const AnUnitFilename,
  AnIncludeFile: string;
  var IgnoreUnitPaths: TFilenameToStringTree);
var
  NewDirectory: String;
  UnitPath: String;
  ShortDirectory: String;
  NewIncDirectory: String;
  ShortIncDirectory: String;
  IncPath: String;
  UnitPathPos: Integer;
  IncPathPos: Integer;
begin
  if LazPackage=nil then exit;
  // check if directory is already in the unit path of the package
  NewDirectory:=ExtractFilePath(AnUnitFilename);
  ShortDirectory:=NewDirectory;
  LazPackage.ShortenFilename(ShortDirectory,true);
  if ShortDirectory='' then exit;
  LazPackage.LongenFilename(NewDirectory);
  NewDirectory:=ChompPathDelim(NewDirectory);
  
  UnitPath:=LazPackage.GetUnitPath(false);
  UnitPathPos:=SearchDirectoryInSearchPath(UnitPath,NewDirectory,1);
  IncPathPos:=1;
  if AnIncludeFile<>'' then begin
    NewIncDirectory:=ChompPathDelim(ExtractFilePath(AnIncludeFile));
    ShortIncDirectory:=NewIncDirectory;
    LazPackage.ShortenFilename(ShortIncDirectory,false);
    if ShortIncDirectory<>'' then begin
      LazPackage.LongenFilename(NewIncDirectory);
      NewIncDirectory:=ChompPathDelim(NewIncDirectory);
      IncPath:=LazPackage.GetIncludePath(false);
      IncPathPos:=SearchDirectoryInSearchPath(IncPath,NewIncDirectory,1);
    end;
  end;
  if UnitPathPos<1 then begin
    // ask user to add the unit path
    if (IgnoreUnitPaths<>nil) and (IgnoreUnitPaths.Contains(ShortDirectory))
    then exit;
    if MessageDlg(lisPkgEditNewUnitNotInUnitpath,
        Format(lisPkgEditTheFileIsCurrentlyNotInTheUnitpathOfThePackage, ['"',
          AnUnitFilename,'"',LineEnding,LineEnding,LineEnding,'"',ShortDirectory,'"']),
        mtConfirmation,[mbYes,mbNo],0)<>mrYes
    then begin
      if IgnoreUnitPaths=nil then
        IgnoreUnitPaths:=TFilenameToStringTree.Create(false);
      IgnoreUnitPaths.Add(ShortDirectory,'');
      exit;
    end;
    // add path
    with LazPackage.CompilerOptions do
      OtherUnitFiles:=MergeSearchPaths(OtherUnitFiles,ShortDirectory);
  end;
  if IncPathPos<1 then begin
    // the unit is in unitpath, but the include file not in the incpath
    // -> auto extend the include path
    with LazPackage.CompilerOptions do
      IncludePath:=MergeSearchPaths(IncludePath,ShortIncDirectory);
  end;
end;

procedure TPackageEditorForm.ExtendIncPathForNewIncludeFile(
  const AnIncludeFile: string; var IgnoreIncPaths: TFilenameToStringTree);
var
  NewDirectory: String;
  ShortDirectory: String;
  IncPath: String;
  IncPathPos: LongInt;
begin
  if LazPackage=nil then exit;
  // check if directory is already in the unit path of the package
  NewDirectory:=ExtractFilePath(AnIncludeFile);
  ShortDirectory:=NewDirectory;
  LazPackage.ShortenFilename(ShortDirectory,false);
  if ShortDirectory='' then exit;
  LazPackage.LongenFilename(NewDirectory);
  NewDirectory:=ChompPathDelim(NewDirectory);
  IncPath:=LazPackage.GetIncludePath(false);
  IncPathPos:=SearchDirectoryInSearchPath(IncPath,NewDirectory,1);
  if IncPathPos>0 then exit;
  // ask user to add the unit path
  if (IgnoreIncPaths<>nil) and (IgnoreIncPaths.Contains(ShortDirectory))
  then exit;
  if MessageDlg(lisPENewFileNotInIncludePath,
     Format(lisPETheFileIsCurrentlyNotInTheIncludePathOfThePackageA,
            [AnIncludeFile, LineEnding, ShortDirectory]),
      mtConfirmation,[mbYes,mbNo],0)<>mrYes
  then begin
    if IgnoreIncPaths=nil then
      IgnoreIncPaths:=TFilenameToStringTree.Create(false);
    IgnoreIncPaths.Add(ShortDirectory,'');
    exit;
  end;
  // add path
  with LazPackage.CompilerOptions do
    IncludePath:=MergeSearchPaths(IncludePath,ShortDirectory);
end;

function TPackageEditorForm.CanBeAddedToProject: boolean;
begin
  if LazPackage=nil then exit(false);
  Result:=PackageEditors.AddToProject(LazPackage,true)=mrOk;
end;

procedure TPackageEditorForm.DoSave(SaveAs: boolean);
begin
  PackageEditors.SavePackage(LazPackage,SaveAs);
  UpdateButtons;
  UpdateTitle;
  UpdateStatusBar;
end;

procedure TPackageEditorForm.DoCompile(CompileClean, CompileRequired: boolean);
begin
  PackageEditors.CompilePackage(LazPackage,CompileClean,CompileRequired);
  UpdateButtons;
  UpdateTitle;
  UpdateStatusBar;
end;

procedure TPackageEditorForm.DoRevert;
begin
  if MessageDlg(lisPkgEditRevertPackage,
    Format(lisPkgEditDoYouReallyWantToForgetAllChangesToPackageAnd, [LazPackage.IDAsString]),
    mtConfirmation,[mbYes,mbNo],0)<>mrYes
  then exit;
  PackageEditors.RevertPackage(LazPackage);
  UpdateAll(true);
end;

procedure TPackageEditorForm.DoPublishProject;
begin
  PackageEditors.PublishPackage(LazPackage);
end;

procedure TPackageEditorForm.DoEditVirtualUnit;
var
  Removed: boolean;
  CurFile: TPkgFile;
begin
  CurFile:=GetCurrentFile(Removed);
  if (CurFile=nil) or Removed then exit;
  if ShowEditVirtualPackageDialog(CurFile)=mrOk then
    UpdateFiles;
end;

procedure TPackageEditorForm.DoExpandDirectory;
var
  CurNode: TTreeNode;
begin
  if not ShowDirectoryHierarchy then exit;
  CurNode:=ItemsTreeView.Selected;
  if not (IsDirectoryNode(CurNode) or (CurNode=FFilesNode)) then exit;
  ItemsTreeView.BeginUpdate;
  CurNode.Expand(true);
  ItemsTreeView.EndUpdate;
end;

procedure TPackageEditorForm.DoCollapseDirectory;
var
  CurNode: TTreeNode;
  Node: TTreeNode;
begin
  if not ShowDirectoryHierarchy then exit;
  CurNode:=ItemsTreeView.Selected;
  if not (IsDirectoryNode(CurNode) or (CurNode=FFilesNode)) then exit;
  ItemsTreeView.BeginUpdate;
  Node:=CurNode.GetFirstChild;
  while Node<>nil do
  begin
    Node.Collapse(true);
    Node:=Node.GetNextSibling;
  end;
  ItemsTreeView.EndUpdate;
end;

procedure TPackageEditorForm.DoUseUnitsInDirectory(Use: boolean);

  procedure Traverse(Node: TTreeNode);
  var
    PkgFile: TPkgFile;
    NodeData: TPENodeData;
  begin
    NodeData:=GetNodeData(Node);
    if (NodeData<>nil) and (NodeData.Typ=penFile) then
    begin
      PkgFile:=LazPackage.FindPkgFile(NodeData.Name,true,true);
      if (PkgFile<>nil) and (PkgFile.FileType in [pftUnit,pftVirtualUnit]) then
      begin
        if PkgFile.AddToUsesPkgSection<>Use then
        begin
          PkgFile.AddToUsesPkgSection:=Use;
          LazPackage.Modified:=true;
        end;
      end;
    end;
    Node:=Node.GetFirstChild;
    while Node<>nil do
    begin
      Traverse(Node);
      Node:=Node.GetNextSibling;
    end;
  end;

var
  CurNode: TTreeNode;
begin
  if not ShowDirectoryHierarchy then exit;
  CurNode:=ItemsTreeView.Selected;
  if not (IsDirectoryNode(CurNode) or (CurNode=FFilesNode)) then exit;
  Traverse(CurNode);
  UpdatePEProperties;
end;

procedure TPackageEditorForm.DoMoveCurrentFile(Offset: integer);
var
  Removed: Boolean;
  OldIndex, NewIndex: Integer;
  CurFile: TPkgFile;
  FilesBranch: TTreeFilterBranch;
begin
  CurFile:=GetCurrentFile(Removed);
  if (CurFile=nil) or Removed then exit;
  OldIndex:=LazPackage.IndexOfPkgFile(CurFile);
  NewIndex:=OldIndex+Offset;
  if (NewIndex<0) or (NewIndex>=LazPackage.FileCount) then exit;
  FilesBranch:=FilterEdit.GetExistingBranch(FFilesNode);
  LazPackage.MoveFile(OldIndex,NewIndex);
  FilesBranch.MoveFile(OldIndex,NewIndex);
  UpdatePEProperties;
  UpdateStatusBar;
  FilterEdit.InvalidateFilter;
end;

procedure TPackageEditorForm.DoMoveDependency(Offset: integer);
var
  OldSelection: TStringList;
begin
  ItemsTreeView.BeginUpdate;
  OldSelection:=ItemsTreeView.StoreCurrentSelection;
  if Offset<0 then
    PackageGraph.MoveRequiredDependencyUp(FSingleSelectedDependency)
  else
    PackageGraph.MoveRequiredDependencyDown(FSingleSelectedDependency);
  ItemsTreeView.ApplyStoredSelection(OldSelection);
  ItemsTreeView.EndUpdate;
end;

procedure TPackageEditorForm.DoSortFiles;
var
  TreeSelection: TStringList;
begin
  TreeSelection:=ItemsTreeView.StoreCurrentSelection;
  LazPackage.SortFiles;
  UpdateFiles;
  ItemsTreeView.ApplyStoredSelection(TreeSelection);
end;

function TPackageEditorForm.DoOpenPkgFile(PkgFile: TPkgFile): TModalResult;
begin
  Result:=PackageEditors.OpenPkgFile(Self,PkgFile);
end;

procedure TPackageEditorForm.DoFixFilesCase;
begin
  if LazPackage.FixFilesCaseSensitivity then
    LazPackage.Modified:=true;
  UpdateFiles;
  UpdateButtons;
end;

procedure TPackageEditorForm.DoShowMissingFiles;
begin
  ShowMissingPkgFilesDialog(LazPackage);
  UpdateFiles;
end;

constructor TPackageEditorForm.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
end;

destructor TPackageEditorForm.Destroy;
begin
  inherited Destroy;
end;

{ TPackageEditors }

function TPackageEditors.GetEditors(Index: integer): TPackageEditorForm;
begin
  Result:=TPackageEditorForm(FItems[Index]);
end;

constructor TPackageEditors.Create;
begin
  FItems:=TFPList.Create;
end;

destructor TPackageEditors.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited Destroy;
end;

function TPackageEditors.Count: integer;
begin
  Result:=FItems.Count;
end;

procedure TPackageEditors.Clear;
begin
  FItems.Clear;
end;

procedure TPackageEditors.Remove(Editor: TPackageEditorForm);
begin
  if FItems<>nil then
    FItems.Remove(Editor);
end;

function TPackageEditors.IndexOfPackage(Pkg: TLazPackage): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (Editors[Result].LazPackage<>Pkg) do dec(Result);
end;

function TPackageEditors.FindEditor(Pkg: TLazPackage): TPackageEditorForm;
var
  i: Integer;
begin
  i:=IndexOfPackage(Pkg);
  if i>=0 then
    Result:=Editors[i]
  else
    Result:=nil;
end;

function TPackageEditors.OpenEditor(Pkg: TLazPackage): TPackageEditorForm;
begin
  Result:=FindEditor(Pkg);
  if Result=nil then begin
    Result:=TPackageEditorForm.Create(LazarusIDE.OwningComponent);
    Result.LazPackage:=Pkg;
    FItems.Add(Result);
  end;
end;

function TPackageEditors.OpenFile(Sender: TObject; const Filename: string): TModalResult;
begin
  if Assigned(OnOpenFile) then
    Result:=OnOpenFile(Sender,Filename)
  else
    Result:=mrCancel;
end;

function TPackageEditors.OpenPkgFile(Sender: TObject; PkgFile: TPkgFile): TModalResult;
begin
  if Assigned(OnOpenPkgFile) then
    Result:=OnOpenPkgFile(Sender,PkgFile)
  else
    Result:=mrCancel;
end;

function TPackageEditors.OpenDependency(Sender: TObject;
  Dependency: TPkgDependency): TModalResult;
var
  APackage: TLazPackage;
begin
  Result:=mrCancel;
  if PackageGraph.OpenDependency(Dependency,false)=lprSuccess then
  begin
    APackage:=Dependency.RequiredPackage;
    if Assigned(OnOpenPackage) then Result:=OnOpenPackage(Sender,APackage);
  end;
end;

procedure TPackageEditors.DoFreeEditor(Pkg: TLazPackage);
begin
  if FItems<>nil then
    FItems.Remove(Pkg.Editor);
  if Assigned(OnFreeEditor) then OnFreeEditor(Pkg);
end;

function TPackageEditors.CreateNewFile(Sender: TObject;
  Params: TAddToPkgResult): TModalResult;
begin
  Result:=mrCancel;
  if Assigned(OnCreateNewFile) then
    Result:=OnCreateNewFile(Sender,Params)
  else
    Result:=mrCancel;
end;

function TPackageEditors.SavePackage(APackage: TLazPackage;
  SaveAs: boolean): TModalResult;
begin
  if Assigned(OnSavePackage) then
    Result:=OnSavePackage(Self,APackage,SaveAs)
  else
    Result:=mrCancel;
end;

function TPackageEditors.CompilePackage(APackage: TLazPackage;
  CompileClean, CompileRequired: boolean): TModalResult;
begin
  if Assigned(OnCompilePackage) then
    Result:=OnCompilePackage(Self,APackage,CompileClean,CompileRequired)
  else
    Result:=mrCancel;
end;

procedure TPackageEditors.UpdateAllEditors(Immediately: boolean);
var
  i: Integer;
begin
  for i:=0 to Count-1 do
    Editors[i].UpdateAll(Immediately);
end;

function TPackageEditors.ShouldNotBeInstalled(APackage: TLazPackage): boolean;
begin
  Result:=APackage.Missing
     or ((APackage.FindUnitWithRegister=nil) and (APackage.Provides.Count=0));
end;

function TPackageEditors.InstallPackage(APackage: TLazPackage): TModalResult;
begin
  if ShouldNotBeInstalled(APackage) then begin
    if IDEQuestionDialog(lisNotAnInstallPackage,
      Format(lisThePackageDoesNotHaveAnyRegisterProcedureWhichTypi,
             [APackage.Name, LineEnding, LineEnding]),
      mtWarning,
      [mrIgnore, lisInstallItILikeTheFat, mrCancel, lisCancel], '')<>mrIgnore
    then exit(mrCancel);
  end;
  if Assigned(OnInstallPackage) then
    Result:=OnInstallPackage(Self,APackage)
  else
    Result:=mrCancel;
end;

function TPackageEditors.UninstallPackage(APackage: TLazPackage): TModalResult;
begin
  if Assigned(OnUninstallPackage) then
    Result:=OnUninstallPackage(Self,APackage)
  else
    Result:=mrCancel;
end;

function TPackageEditors.ViewPkgSource(APackage: TLazPackage): TModalResult;
begin
  if Assigned(OnViewPackageSource) then
    Result:=OnViewPackageSource(Self,APackage)
  else
    Result:=mrCancel;
end;

function TPackageEditors.ViewPkgToDos(APackage: TLazPackage): TModalResult;
begin
  if Assigned(OnViewPackageToDos) then
    Result:=OnViewPackageToDos(Self,APackage)
  else
    Result:=mrCancel;
end;

function TPackageEditors.DeleteAmbiguousFiles(APackage: TLazPackage;
  const Filename: string): TModalResult;
begin
  if Assigned(OnDeleteAmbiguousFiles) then
    Result:=OnDeleteAmbiguousFiles(Self,APackage,Filename)
  else
    Result:=mrOk;
end;

function TPackageEditors.AddToProject(APackage: TLazPackage;
  OnlyTestIfPossible: boolean): TModalResult;
begin
  if Assigned(OnAddToProject) then
    Result:=OnAddToProject(Self,APackage,OnlyTestIfPossible)
  else
    Result:=mrCancel;
end;

function TPackageEditors.CreateMakefile(APackage: TLazPackage): TModalResult;
begin
  if Assigned(OnCreateMakeFile) then
    Result:=OnCreateMakeFile(Self,APackage)
  else
    Result:=mrCancel;
end;

function TPackageEditors.CreateFpmakeFile(APackage: TLazPackage): TModalResult;
begin
  if Assigned(OnCreateFpmakefile) then
    Result:=OnCreateFpmakefile(Self,APackage)
  else
    Result:=mrCancel;
end;

function TPackageEditors.RevertPackage(APackage: TLazPackage): TModalResult;
begin
  if Assigned(OnRevertPackage) then
    Result:=OnRevertPackage(Self,APackage)
  else
    Result:=mrCancel;
end;

function TPackageEditors.PublishPackage(APackage: TLazPackage): TModalResult;
begin
  if Assigned(OnPublishPackage) then
    Result:=OnPublishPackage(Self,APackage)
  else
    Result:=mrCancel;
end;

initialization
  PackageEditors:=nil;

end.

