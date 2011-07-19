{  $Id$  }
{
 /***************************************************************************
                            lclstrconsts.pas
                            ----------------
     This unit contains all resource strings of the LCL (not interfaces)


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit LCLStrConsts;

{$mode objfpc}{$H+}

interface

resourceString
  // common Delphi strings
  SNoMDIForm = 'No MDI form present.';

  // message/input dialog buttons
  rsMbYes          = '&Yes';
  rsMbNo           = '&No';
  rsMbOK           = '&OK';
  rsMbCancel       = 'Cancel';
  rsMbAbort        = 'Abort';
  rsMbRetry        = '&Retry';
  rsMbIgnore       = '&Ignore';
  rsMbAll          = '&All';
  rsMbNoToAll      = 'No to all';
  rsMbYesToAll     = 'Yes to &All';
  rsMbHelp         = '&Help';
  rsMbClose        = '&Close';
  rsmbOpen         = '&Open';
  rsmbSave         = '&Save';
  rsmbUnlock       = '&Unlock';

  rsMtWarning      = 'Warning';
  rsMtError        = 'Error';
  rsMtInformation  = 'Information';
  rsMtConfirmation = 'Confirmation';
  rsMtAuthentication = 'Authentication';
  rsMtCustom       = 'Custom';

  // file dialog
  rsfdOpenFile           = 'Open existing file';
  rsfdOverwriteFile      = 'Overwrite file ?';
  rsfdFileAlreadyExists  = 'The file "%s" already exists. Overwrite ?';
  rsfdPathMustExist      = 'Path must exist';
  rsfdPathNoExist        = 'The path "%s" does not exist.';
  rsfdFileMustExist      = 'File must exist';
  rsfdDirectoryMustExist = 'Directory must exist';
  rsfdFileNotExist       = 'The file "%s" does not exist.';
  rsfdDirectoryNotExist  = 'The directory "%s" does not exist.';
  rsFind = 'Find';
  rsfdFileReadOnlyTitle  = 'File is not writable';
  rsfdFileReadOnly       = 'The file "%s" is not writable.';
  rsfdFileSaveAs         = 'Save file as';
  rsAllFiles = 'All files (%s)|%s|%s';
  rsfdSelectDirectory    = 'Select Directory';
  rsDirectory            = '&Directory';

  // Select color dialog
  rsSelectcolorTitle    = 'Select color';
   
  // Select font dialog
  rsSelectFontTitle     = 'Select a font';
  rsFindMore = 'Find more';
  rsReplace = 'Replace';
  rsReplaceAll = 'Replace all';
  
  // DBGrid
  rsDeleteRecord = 'Delete record?';

  // DBCtrls
  rsFirstRecordHint = 'First';
  rsPriorRecordHint = 'Prior';
  rsNextRecordHint = 'Next';
  rsLastRecordHint = 'Last';
  rsInsertRecordHint = 'Insert';
  rsDeleteRecordHint = 'Delete';
  rsEditRecordHint = 'Edit';
  rsPostRecordHint = 'Post';
  rsCancelRecordHint = 'Cancel';
  rsRefreshRecordsHint = 'Refresh';
  
  // gtk interface
  rsWarningUnremovedPaintMessages = ' WARNING: There are %s unremoved LM_'
    +'PAINT/LM_GtkPAINT message links left.';
  rsWarningUnreleasedDCsDump = ' WARNING: There are %d unreleased DCs, a '
    +'detailed dump follows:';
  rsWarningUnreleasedGDIObjectsDump = ' WARNING: There are %d unreleased '
    +'GDIObjects, a detailed dump follows:';
  rsWarningUnreleasedMessagesInQueue = ' WARNING: There are %d messages left '
    +'in the queue! I''ll free them';
  rsWarningUnreleasedTimerInfos = ' WARNING: There are %d TimerInfo '
    +'structures left, I''ll free them';
  rsFileInformation = 'File information';
  rsgtkFilter = 'Filter:';
  rsgtkHistory = 'History:';
  rsDefaultFileInfoValue = 'permissions user group size date time';
  rsBlank = 'Blank';
  rsUnableToLoadDefaultFont = 'Unable to load default font';
  rsFileInfoFileNotFound = '(file not found: "%s")';
  rsgtkOptionNoTransient = '--lcl-no-transient    Do not set transient order for'
    +' modal forms';
  rsgtkOptionModule = '--gtk-module module   Load the specified module at '
    +'startup.';
  rsgOptionFatalWarnings = '--g-fatal-warnings    Warnings and errors '
    +'generated by Gtk+/GDK will halt the application.';
  rsgtkOptionDebug = '--gtk-debug flags     Turn on specific Gtk+ trace/'
    +'debug messages.';
  rsgtkOptionNoDebug = '--gtk-no-debug flags  Turn off specific Gtk+ trace/'
    +'debug messages.';
  rsgdkOptionDebug = '--gdk-debug flags     Turn on specific GDK trace/debug '
    +'messages.';
  rsgdkOptionNoDebug = '--gdk-no-debug flags  Turn off specific GDK trace/'
    +'debug messages.';
  rsgtkOptionDisplay = '--display h:s:d       Connect to the specified X '
    +'server, where "h" is the hostname, "s" is the server number (usually 0), '
    +'and "d" is the display number (typically omitted). If --display is not '
    +'specified, the DISPLAY environment variable is used.';
  rsgtkOptionSync = '--sync                Call XSynchronize (display, True) '
    +'after the Xserver connection has been established. This makes debugging '
    +'X protocol errors easier, because X request buffering will be disabled '
    +'and X errors will be received immediately after the protocol request that '
    +'generated the error has been processed by the X server.';
  rsgtkOptionNoXshm = '--no-xshm             Disable use of the X Shared '
    +'Memory Extension.';
  rsgtkOptionName = '--name programe       Set program name to "progname". '
    +'If not specified, program name will be set to ParamStrUTF8(0).';
  rsgtkOptionClass = '--class classname     Following Xt conventions, the '
    +'class of a program is the program name with the initial character '
    +'capitalized. For example, the classname for gimp is "Gimp". If --class '
    +'is specified, the class of the program will be set to "classname".';

  // qt interface
  rsqtOptionNoGrab = '-nograb, tells Qt that it must never grab '
    +'the mouse or the keyboard. Need QT_DEBUG.';
  rsqtOptionDoGrab = '-dograb (only under X11), running under a debugger can '
    +'cause an implicit -nograb, use -dograb to override. Need QT_DEBUG.';
  rsqtOptionSync = '-sync (only under X11), switches to synchronous mode '
    +'for debugging.';
  rsqtOptionStyle = '-style style or -style=style, sets the application GUI '
    +'style. Possible values are motif, windows, and platinum. If you compiled '
    +'Qt with additional styles or have additional styles as plugins these '
    +'will be available to the -style  command line option. NOTE: Not all '
    +'styles are available on all platforms. If style param does not exist '
    +'Qt will start an application with default common style (windows).';
  rsqtOptionStyleSheet = '-stylesheet stylesheet or -stylesheet=stylesheet, '
    +'sets the application Style Sheet. '
    +'The value must be a path to a file that contains the Style Sheet. '
    +'Note: Relative URLs in the Style Sheet file are relative '
    +'to the Style Sheet file''s path.';
  rsqtOptionGraphicsStyle = '-graphicssystem param, sets the backend to be '
   +'used for on-screen widgets and QPixmaps. '
   +'Available options are native, raster and opengl. OpenGL is still unstable.';
  rsqtOptionSession = '-session session, restores the application from an '
    +'earlier session.';
  rsqtOptionWidgetCount = '-widgetcount, prints debug message at the end about '
    +'number of widgets left undestroyed and maximum number of widgets existed '
    +'at the same time.';
  rsqtOptionReverse = '-reverse, sets the application''s layout direction '
    +'to Qt::RightToLeft.';
  // qt X11 options
  rsqtOptionX11Display = '-display display, sets the X display '
    +'(default is $DISPLAY).';
  rsqtOptionX11Geometry = '-geometry geometry, sets the client geometry of '
    +'the first window that is shown.';
  rsqtOptionX11Font = '-fn or -font font, defines the application font. The '
    +'font should be specified using an X logical font description.';
  rsqtOptionX11BgColor = '-bg or -background color, sets the default '
    +'background color and an application palette (light and dark '
    +'shades are calculated).';
  rsqtOptionX11FgColor = '-fg or -foreground color, sets the default '
    +'foreground color.';
  rsqtOptionX11BtnColor = '-btn or -button color, sets the default button '
    +'color.';
  rsqtOptionX11Name = '-name name, sets the application name.';
  rsqtOptionX11Title = '-title title, sets the application title.';
  rsqtOptionX11Visual = '-visual TrueColor, forces the application to use a '
    +'TrueColor visual on an 8-bit display.';
  rsqtOptionX11NCols = '-ncols count, limits the number of colors allocated '
    +'in the color cube on an 8-bit display, if the application is using the '
    +'QApplication::ManyColor color specification. If count is 216 then a '
    +'6x6x6 color cube is used (i.e. 6 levels of red, 6 of green, and 6 of '
    +'blue); for other values, a cube approximately proportional to a 2x3x1 '
    +'cube is used.';
  rsqtOptionX11CMap = '-cmap, causes the application to install a private '
    +'color map on an 8-bit display.';
  rsqtOptionX11IM = '-im, sets the input method server (equivalent to setting '
    +'the XMODIFIERS environment variable).';
  rsqtOptionX11InputStyle = '-inputstyle, defines how the input is inserted '
    +'into the given widget, e.g. onTheSpot makes the input appear directly '
    +'in the widget, while overTheSpot makes the input appear in a box '
    +'floating over the widget and is not inserted until the editing is done.';

  // win32 interface
  rsWin32Warning = 'Warning:';
  rsWin32Error = 'Error:';
  
  // StringHashList, LResource, Menus, ExtCtrls, ImgList, Spin
  // StdCtrls, Calendar, CustomTimer, Forms, Grids, LCLProc, Controls, ComCtrls,
  // ExtDlgs, EditBtn, Masks
  sInvalidActionRegistration = 'Invalid action registration';
  sInvalidActionUnregistration = 'Invalid action unregistration';
  sInvalidActionEnumeration = 'Invalid action enumeration';
  sInvalidActionCreation = 'Invalid action creation';
  sMenuNotFound   = 'Sub-menu is not in menu';
  sMenuIndexError = 'Menu index out of range';
  sMenuItemIsNil  = 'MenuItem is nil';
  sNoTimers = 'No timers available';
  sInvalidIndex = 'Invalid ImageList Index';
  sInvalidImageSize = 'Invalid image size';
  sDuplicateMenus = 'Duplicate menus';
  sCannotFocus = 'Cannot focus a disabled or invisible window';
  sInvalidCharSet = 'The char set in mask "%s" is not valid!';

  rsListMustBeEmpty = 'List must be empty';
  rsInvalidPropertyValue = 'Invalid property value';
  rsPropertyDoesNotExist = 'Property %s does not exist';
  rsInvalidStreamFormat = 'Invalid stream format';
  rsErrorReadingProperty = 'Error reading %s%s%s: %s';
  rsInvalidFormObjectStream = 'invalid Form object stream';
  rsScrollBarOutOfRange = 'ScrollBar property out of range';
  rsInvalidDate = 'Invalid Date : %s';
  rsInvalidDateRangeHint = 'Invalid Date: %s. Must be between %s and %s';
  rsErrorOccurredInAtAddressFrame = 'Error occurred in %s at %sAddress %s%s'
    +' Frame %s';
  rsException = 'Exception';
  rsFormStreamingError = 'Form streaming "%s" error: %s';
  rsFixedColsTooBig = 'FixedCols can''t be >= ColCount';
  rsFixedRowsTooBig = 'FixedRows can''t be >= RowCount';
  rsGridFileDoesNotExists = 'Grid file doesn''t exists';
  rsNotAValidGridFile = 'Not a valid grid file';
  rsIndexOutOfRange = 'Index Out of range Cell[Col=%d Row=%d]';
  rsGridIndexOutOfRange = 'Grid index out of range.';
  rsERRORInLCL = 'ERROR in LCL: ';
  rsCreatingGdbCatchableError = 'Creating gdb catchable error:';
  rsAControlCanNotHaveItselfAsParent = 'A control can''t have itself as a parent';
  rsControlHasNoParentWindow = 'Control ''%s'' has no parent window';
  rsControlClassCantContainChildClass = 'Control of class ''%s'' can''t have control of class ''%s'' as a child';
  lisLCLResourceSNotFound = 'Resource %s not found';
  rsFormResourceSNotFoundForResourcelessFormsCreateNew = 'Form resource %s '
    +'not found. For resourceless forms CreateNew constructor must be used.'
    +' See the global variable RequireDerivedFormResource.';
  rsErrorCreatingDeviceContext = 'Error creating device context for %s.%s';
  rsIndexOutOfBounds = '%s Index %d out of bounds 0 .. %d';
  rsUnknownPictureExtension = 'Unknown picture extension';
  rsUnknownPictureFormat = 'Unknown picture format';
  rsBitmaps = 'Bitmaps';
  rsPixmap = 'Pixmap';
  rsPortableNetworkGraphic = 'Portable Network Graphic';
  rsPortableBitmap = 'Portable BitMap';
  rsPortableGrayMap = 'Portable GrayMap';
  rsPortablePixmap = 'Portable PixMap';
  rsIcon = 'Icon';
  rsIcns = 'Mac OS X Icon';
  rsCursor = 'Cursor';
  rsJpeg = 'Joint Picture Expert Group';
  rsTiff = 'Tagged Image File Format';
  rsGIF = 'Graphics Interchange Format';
  rsGraphic = 'Graphic';
  rsUnsupportedClipboardFormat = 'Unsupported clipboard format: %s';
  rsGroupIndexCannotBeLessThanPrevious = 'GroupIndex cannot be less than a '
    +'previous menu item''s GroupIndex';
  rsIsAlreadyAssociatedWith = '%s is already associated with %s';
  rsCanvasDoesNotAllowDrawing = 'Canvas does not allow drawing';
  rsUnsupportedBitmapFormat = 'Unsupported bitmap format.';
  rsErrorWhileSavingBitmap = 'Error while saving bitmap.';
  rsDuplicateIconFormat = 'Duplicate icon format.';
  rsIconImageEmpty = 'Icon image cannot be empty';
  rsIconImageSize = 'Icon image must have the same size';
  rsIconNoCurrent = 'Icon has no current image';
  rsIconImageFormat = 'Icon image must have the same format';
  rsIconImageFormatChange = 'Cannot change format of icon image';
  rsIconImageSizeChange = 'Cannot change size of icon image';
  rsRasterImageUpdateAll = 'Cannot begin update all when canvas only update in progress';
  rsRasterImageEndUpdate = 'Endupdate while no update in progress';
  rsRasterImageSaveInUpdate = 'Cannot save image while update in progress';
  rsNoWidgetSet = 'No widgetset object. '
    +'Please check if the unit "interfaces" was added to the programs uses clause.';
  rsPressOkToIgnoreAndRiskDataCorruptionPressCancelToK = '%s%sPress OK to '
    +'ignore and risk data corruption.%sPress Cancel to kill the program.';
  rsCanNotFocus = 'Can not focus';
  rsListIndexExceedsBounds = 'List index exceeds bounds (%d)';
  rsResourceNotFound = 'Resource %s not found';
  rsCalculator = 'Calculator';
  rsError      = 'Error';
  rsPickDate   = 'Select a date';
  rsSize = '  size ';
  rsModified = '  modified ';

  // I'm not sure if in all languages the Dialog texts for a button
  // have the same meaning as a key
  // So every VK gets its own constant
  ifsVK_UNKNOWN    = 'Unknown';
  ifsVK_LBUTTON    = 'Mouse Button Left';
  ifsVK_RBUTTON    = 'Mouse Button Right';
  ifsVK_CANCEL     = 'Cancel'; //= dlgCancel
  ifsVK_MBUTTON    = 'Mouse Button Middle';
  ifsVK_BACK       = 'Backspace';
  ifsVK_TAB        = 'Tab';
  ifsVK_CLEAR      = 'Clear';
  ifsVK_RETURN     = 'Return';
  ifsVK_SHIFT      = 'Shift';
  ifsVK_CONTROL    = 'Control';
  ifsVK_MENU       = 'Menu';
  ifsVK_PAUSE      = 'Pause key';
  ifsVK_CAPITAL    = 'Capital';
  ifsVK_KANA       = 'Kana';
  ifsVK_JUNJA      = 'Junja';
  ifsVK_FINAL      = 'Final';
  ifsVK_HANJA      = 'Hanja';
  ifsVK_ESCAPE     = 'Escape';
  ifsVK_CONVERT    = 'Convert';
  ifsVK_NONCONVERT = 'Nonconvert';
  ifsVK_ACCEPT     = 'Accept';
  ifsVK_MODECHANGE = 'Mode Change';
  ifsVK_SPACE      = 'Space key';
  ifsVK_PRIOR      = 'Prior';
  ifsVK_NEXT       = 'Next';
  ifsVK_END        = 'End';
  ifsVK_HOME       = 'Home';
  ifsVK_LEFT       = 'Left';
  ifsVK_UP         = 'Up';
  ifsVK_RIGHT      = 'Right';
  ifsVK_DOWN       = 'Down'; //= dlgdownword
  ifsVK_SELECT     = 'Select'; //= lismenuselect
  ifsVK_PRINT      = 'Print';
  ifsVK_EXECUTE    = 'Execute';
  ifsVK_SNAPSHOT   = 'Snapshot';
  ifsVK_INSERT     = 'Insert';
  ifsVK_DELETE     = 'Delete'; //= dlgeddelete
  ifsVK_HELP       = 'Help';
  ifsCtrl          = 'Ctrl';
  ifsAlt           = 'Alt';
  rsWholeWordsOnly = 'Whole words only';
  rsCaseSensitive = 'Case sensitive';
  rsEntireScope   = 'Search entire file';
  rsText = 'Text';
  rsDirection = 'Direction';
  rsForward = 'Forward';
  rsBackward = 'Backward';
  ifsVK_LWIN       = 'left windows key';
  ifsVK_RWIN       = 'right windows key';
  ifsVK_APPS       = 'application key';
  ifsVK_NUMPAD     = 'Numpad %d';
  ifsVK_NUMLOCK    = 'Numlock';
  ifsVK_SCROLL     = 'Scroll';

  // menu key captions
  SmkcBkSp = 'BkSp';
  SmkcTab = 'Tab';
  SmkcEsc = 'Esc';
  SmkcEnter = 'Enter';
  SmkcSpace = 'Space';
  SmkcPgUp = 'PgUp';
  SmkcPgDn = 'PgDn';
  SmkcEnd = 'End';
  SmkcHome = 'Home';
  SmkcLeft = 'Left';
  SmkcUp = 'Up';
  SmkcRight = 'Right';
  SmkcDown = 'Down';
  SmkcIns = 'Ins';
  SmkcDel = 'Del';
  SmkcShift = 'Shift+';
  SmkcCtrl = 'Ctrl+';
  SmkcAlt = 'Alt+';
  SmkcMeta = 'Meta+';

  // docking
  rsDocking = 'Docking';

  // help
  rsHelpHelpNodeHasNoHelpDatabase = 'Help node %s%s%s has no Help Database';
  rsHelpThereIsNoViewerForHelpType = 'There is no viewer for help type %s%s%s';
  rsHelpHelpDatabaseDidNotFoundAViewerForAHelpPageOfType = 'Help Database %s%'
    +'s%s did not found a viewer for a help page of type %s';
  rsHelpAlreadyRegistered = '%s: Already registered';
  rsHelpNotRegistered = '%s: Not registered';
  rsHelpHelpDatabaseNotFound = 'Help Database %s%s%s not found';
  rsHelpHelpKeywordNotFoundInDatabase = 'Help keyword %s%s%s not found in '
    +'Database %s%s%s.';
  rsHelpHelpKeywordNotFound = 'Help keyword %s%s%s not found.';
  rsHelpHelpForDirectiveNotFoundInDatabase = 'Help for directive %s%s%s not found in '
    +'Database %s%s%s.';
  rsHelpHelpForDirectiveNotFound = 'Help for directive %s%s%s not found.';
  rsHelpHelpContextNotFoundInDatabase = 'Help context %s not found in '
    +'Database %s%s%s.';
  rsHelpHelpContextNotFound = 'Help context %s not found.';
  rsHelpNoHelpFoundForSource = 'No help found for line %d, column %d of %s.';
  rsHelpNoHelpNodesAvailable = 'No help entries available for this topic';
  rsHelpError = 'Help Error';
  rsHelpDatabaseNotFound = 'There is no help database installed for this topic';
  rsHelpContextNotFound = 'A help database was found for this topic, but this topic was not found';
  rsHelpViewerNotFound = 'No viewer was found for this type of help content';
  rsHelpNotFound = 'No help found for this topic';
  rsHelpViewerError = 'Help Viewer Error';
  rsHelpSelectorError = 'Help Selector Error';
  rsUnknownErrorPleaseReportThisBug = 'Unknown Error, please report this bug';

  hhsHelpTheHelpDatabaseWasUnableToFindFile = 'The help database %s%s%s was '
    +'unable to find file %s%s%s.';
  hhsHelpTheMacroSInBrowserParamsWillBeReplacedByTheURL = 'The macro %s in '
    +'BrowserParams will be replaced by the URL.';
  hhsHelpNoHTMLBrowserFoundPleaseDefineOne = 'No HTML '
    +'Browser found.%sPlease define one in Tools -> Options -> Help -> Help Options';
  hhsHelpNoHTMLBrowserFound = 'Unable to find a HTML browser.';
  hhsHelpBrowserNotFound = 'Browser %s%s%s not found.';
  hhsHelpBrowserNotExecutable = 'Browser %s%s%s not executable.';
  hhsHelpErrorWhileExecuting = 'Error while executing %s%s%s:%s%s';

  // parser
  SParExpected                  = 'Wrong token type: %s expected';
  SParInvalidInteger            = 'Invalid integer number: %s';
  SParWrongTokenType            = 'Wrong token type: %s expected but %s found';
  SParInvalidFloat              = 'Invalid floating point number: %s';
  SParWrongTokenSymbol          = 'Wrong token symbol: %s expected but %s found';
  SParUnterminatedString        = 'Unterminated string';
  SParLocInfo                   = ' (at %d,%d, stream offset %d)';
  SParUnterminatedBinValue      = 'Unterminated byte value';

  // colorbox
  rsCustomColorCaption = 'Custom ...';
  rsBlackColorCaption = 'Black';
  rsMaroonColorCaption = 'Maroon';
  rsGreenColorCaption = 'Green';
  rsOliveColorCaption = 'Olive';
  rsNavyColorCaption = 'Navy';
  rsPurpleColorCaption = 'Purple';
  rsTealColorCaption = 'Teal';
  rsGrayColorCaption = 'Gray';
  rsSilverColorCaption = 'Silver';
  rsRedColorCaption = 'Red';
  rsLimeColorCaption = 'Lime';
  rsYellowColorCaption = 'Yellow';
  rsBlueColorCaption = 'Blue';
  rsFuchsiaColorCaption = 'Fuchsia';
  rsAquaColorCaption = 'Aqua';
  rsWhiteColorCaption = 'White';
  rsMoneyGreenColorCaption = 'Money Green';
  rsSkyBlueColorCaption = 'Sky Blue';
  rsCreamColorCaption = 'Cream';
  rsMedGrayColorCaption = 'Medium Gray';
  rsNoneColorCaption = 'None';
  rsDefaultColorCaption = 'Default';
  rsScrollBarColorCaption = 'ScrollBar';
  rsBackgroundColorCaption = 'Desktop';
  rsActiveCaptionColorCaption = 'Active Caption';
  rsInactiveCaptionColorCaption = 'Inactive Caption';
  rsMenuColorCaption = 'Menu';
  rsWindowColorCaption = 'Window';
  rsWindowFrameColorCaption = 'Window Frame';
  rsMenuTextColorCaption = 'Menu Text';
  rsWindowTextColorCaption = 'Window Text';
  rsCaptionTextColorCaption = 'Caption Text';
  rsActiveBorderColorCaption = 'Active Border';
  rsInactiveBorderColorCaption = 'Inactive Border';
  rsAppWorkspaceColorCaption = 'Application Workspace';
  rsHighlightColorCaption = 'Highlight';
  rsHighlightTextColorCaption = 'Highlight Text';
  rsBtnFaceColorCaption = 'Button Face';
  rsBtnShadowColorCaption = 'Button Shadow';
  rsGrayTextColorCaption = 'Gray Text';
  rsBtnTextColorCaption = 'Button Text';
  rsInactiveCaptionText = 'Inactive Caption';
  rsBtnHighlightColorCaption = 'Button Highlight';
  rs3DDkShadowColorCaption = '3D Dark Shadow';
  rs3DLightColorCaption = '3D Light';
  rsInfoTextColorCaption = 'Info Text';
  rsInfoBkColorCaption = 'Info Background';
  rsHotLightColorCaption = 'Hot Light';
  rsGradientActiveCaptionColorCaption = 'Gradient Active Caption';
  rsGradientInactiveCaptionColorCaption = 'Gradient Inactive Caption';
  rsMenuHighlightColorCaption = 'Menu Highlight';
  rsMenuBarColorCaption = 'Menu Bar';
  rsFormColorCaption = 'Form';
  lisProgramFileNotFound = 'program file not found %s';
  lisCanNotExecute = 'can not execute %s';

  lisCEFilter = '(Filter)';

implementation

end.

