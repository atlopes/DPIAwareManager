* File: FOXYDIALOG
* Version 2.41 - 2020-06-13
* by Cesar - VfpImaging
* https://vfpimaging.blogspot.com/2020/05/messagebox-using-simple-vista-task.html
* Displays a Task dialog simple dialog, with custom button captions and icons, and some friendly inputboxes
* 
* Usage:
* Function:
* FOXYDIALOG(tcTitle, tcMainInstruction, tcContent, tcnIcon, tcButtons, tnDefault, tnTimeout)
* Parameters:
*  - tcTitle - string to be used for the task dialog title.
*  - tcMainInstruction - string to be used for the main instruction.
*  - tcContent - string used for additional text that appears below the main instruction, in a smaller font. 
*  - tcnIcon - Character or Integer that identifies the icon to display in the task dialog. 
*		This parameter can be an integer or some predefined text values, allowing several options.
*		If this parameter is EMPTY() or omitted, no icon will be displayed.
*		For numeric, the variety of icons is HUGE, all icons stored in the %systemroot%\system32\imageres.dll file. The imageres.dll file contains many icons, used almost everywhere in Windows 10. It has icons for different types of folders, hardware devices, peripherals, actions, and so on. Below in Appendixes 1 and 2 there is a list of the available strings and enumerated icons. In this parameter you can also determine the background color of the dialog main instruction.
*		Send a string comma separated, having the desired main icon first, and after the comma a letter representing the background color: R=Red; G=Green; Y=Yellow; S=Silver; B=Blue; Empty() no background, and finally "-" means no left margin. You can also pass a BMP or ICO file - just make sure to have it available on disk, not embedded in your EXE.
*  - tcButtons - This parameter determines some important behaviors of the dialog.
*		For ordinary dialogs, used for you to pass some information to the users, it specifies the push buttons displayed in the dialog box. A single string containing comma separated captions. If you wish to show a disabled button, add a "\" before the caption. All buttons are Unicode friendly, and you can use some special button captions with special extensions, for the very commonly used buttons - Ok, Cancel, Print, Save, Search. Adding a "#" will add some basic unicode icons. Adding an asterisk - "*" will add some colored icons. 
*		For INPUTBOXES mode, in the first word of the parameter you can add some special characters as well:
*		- "@I" - turns the dialog into a modern INPUTBOX().
*		- "@IU" or "@I!" - the textbox will accept only UPPERCASE characters
*		- "@IL" - the textbox will accept only LOWERCASE characters
*		"@IN" or "@ID" - numeric (negative and comma accepted) or DIGITS (only integers)
*		"@IP" - Password inputbox, shows asterisks for every character
*		"@D" - DateBox dialog - showing a cool combobox for date picking
*		"@T" - DateTimeBox dialog - showing the same combobox above and a time inputbox
*		"@M" - MonthBox dialog - showing a single calendar for date picking
*		"@R" - DateRangeBox dialog - showing a double month calendar, allowing users to pick some date ranges
*  - tcnDefault
*		For DialogBox mode - numeric, specifies the button Id that will be focused. Default = 1
*		- For special InputBox mode - specifies the default values shown when the input dialog is shown: Character for "@I" or Date for "@D", "@M", "@R" or DateTime for "@T" tcButtons type
*  - tnTimeout - Specifies the number of milliseconds the dialog will be displayed without input from the keyboard or the mouse before clearing itself. You can specify any valid timeout value. A value of less than 1 never times out until user enters input and behaves the same as omitting the nTimeout parameter. The Timeout parameter can be a numeric value or a Character, with the time in milisseconds, and the string that will come together with the time shown. The tag " < SECS > " will be replaced by the time in seconds, with the small unicode clock. Don't miss the samples below.
* Returns:
*		For Regular DialogBox - nId - the Id of the selected button, or 0 (zero) if Cancelled or -1 for timed out
*		For InputBoxes, according to each type, as follows:
*		- "@I", "@I!", "@IP" - returns the character entered, or an empty string if "Cancel"
*		- "@IN", "@ID" - returns a numeric value, or an empty string if cancelled. - Notice that cancel returns a Character empty string!
*		- "@D", "@M" - returns a Date format value
*		- "@T" - returns a DateTime format value
*		- "@R" - returns an object with two properties: "StartDate" and "EndDate"


#DEFINE BM_SETIMAGE                     0xF7

* Task Dialog Messages
* https://docs.microsoft.com/en-us/windows/win32/controls/bumper-task-dialogs-reference-messages
#DEFINE TDM_SET_MARQUEE_PROGRESS_BAR	0x00000467
#DEFINE TDM_SET_PROGRESS_BAR_STATE	    0x00000468
#DEFINE TDM_SET_PROGRESS_BAR_RANGE	    0x00000469
#DEFINE TDM_SET_PROGRESS_BAR_POS		0x0000046A
#DEFINE TDM_SET_PROGRESS_BAR_MARQUEE	0x0000046B
#DEFINE TDM_SET_ELEMENT_TEXT	        0x0000046C
#DEFINE TDM_UPDATE_ICON	           	    0x00000474

* Task Dialog Notifications - Used in Callbacks, for TaskDialogIndirect API
* https://docs.microsoft.com/en-us/windows/win32/controls/bumper-task-dialogs-reference-notifications


#DEFINE PBST_NORMAL	0x0001
#DEFINE PBST_ERROR	0x0002
#DEFINE PBST_PAUSED	0x0003

#DEFINE TDE_CONTENT                     0
#DEFINE TDE_EXPANDED_INFORMATION        1
#DEFINE TDE_FOOTER                      2
#DEFINE TDE_MAIN_INSTRUCTION            3

* Enum TASKDIALOG_ICON_ELEMENTS
#DEFINE TDIE_ICON_MAIN           		0
#DEFINE TDIE_ICON_FOOTER         		1

#DEFINE ICON_EMPTY 14

* Task DIalog Common Buttons
#DEFINE TDCBF_OK_BUTTON         		1
#DEFINE TDCBF_YES_BUTTON        		2
#DEFINE TDCBF_NO_BUTTON         		4
#DEFINE TDCBF_CANCEL_BUTTON     		8
#DEFINE TDCBF_RETRY_BUTTON      		0x0010
#DEFINE TDCBF_CLOSE_BUTTON      		0x0020

#DEFINE S_OK                    0

* Task dialog Icons
#DEFINE TD_WARNING_ICON         -1          && !
#DEFINE TD_ERROR_ICON           -2          && X
#DEFINE TD_INFORMATION_ICON     -3          && i
#DEFINE TD_SHIELD_ICON          -4          && Shield
#DEFINE TD_SHIELD_GRADIENT_ICON -5          && Shield Green BackGnd
#DEFINE TD_SHIELD_WARNING_ICON  -6          && ! Yellow BackGnd
#DEFINE TD_SHIELD_ERROR_ICON    -7          && X Red BackGnd
#DEFINE TD_SHIELD_OK_ICON       -8          && Ok Green BackGnd
#DEFINE TD_SHIELD_GRAY_ICON     -9          && Shield Silver BackGnd
#DEFINE IDI_APPLICATION         0x00007f00  && App
#DEFINE IDI_QUESTION            0x00007f02  && ?

#DEFINE GW_HWNDFIRST            	0
#DEFINE GW_HWNDLAST             	1
#DEFINE GW_HWNDNEXT             	2
#DEFINE GW_CHILD                	5

* Windows Messages Codes
* https://www.autoitscript.com/autoit3/docs/appendix/WinMsgCodes.htm
#DEFINE WM_ACTIVATE					0x0006
#DEFINE WM_SETFOCUS     			0x0007
#DEFINE WM_KILLFOCUS    			0x0008
#DEFINE WM_SETFONT          		48
#DEFINE WM_SETTEXT                  0x000C
#DEFINE WM_GETTEXT			        0x000D
#DEFINE WM_GETTEXTLENGTH  			0x000E
#DEFINE WM_GETDLGCODE               0x0087
#DEFINE WM_KEYDOWN                  0x0100
#DEFINE WM_KEYUP					0x0101
#DEFINE WM_COMMAND      			0x0111
#DEFINE WM_SYSCOMMAND   			0x0112
#DEFINE WM_LBUTTONDOWN  			0x0201
#DEFINE WM_LBUTTONUP     			0x0202
#DEFINE WM_RBUTTONDOWN  			0x0204
#DEFINE WM_PARENTNOTIFY 			0x0210


#DEFINE SC_CLOSE					0xF060

#DEFINE XMB_TIMERINTERVAL       	200 && Miliseconds

* Window Styles
* https://docs.microsoft.com/en-us/windows/win32/winmsg/window-styles
#DEFINE WS_OVERLAPPED    0x0
#DEFINE WS_TABSTOP       0x00010000
#DEFINE WS_MAXIMIZEBOX   0x00010000
#DEFINE WS_MINIMIZEBOX   0x00020000
#DEFINE WS_GROUP         0x00020000
#DEFINE WS_THICKFRAME    0x00040000
#DEFINE WS_SYSMENU       0x00080000
#DEFINE WS_HSCROLL       0x00100000
#DEFINE WS_VSCROLL       0x00200000
#DEFINE WS_DLGFRAME      0x00400000
#DEFINE WS_BORDER        0x00800000
#DEFINE WS_CAPTION      (WS_BORDER + WS_DLGFRAME)
#DEFINE WS_MAXIMIZE      0x01000000
#DEFINE WS_CLIPCHILDREN  0x02000000
#DEFINE WS_CLIPSIBLINGS  0x04000000
#DEFINE WS_DISABLED      0x08000000
#DEFINE WS_VISIBLE       0x10000000
#DEFINE WS_MINIMIZE      0x20000000
#DEFINE WS_CHILD         0x40000000
#DEFINE WS_POPUP         0x80000000

* Extended Window styles
* https://docs.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
#DEFINE WS_EX_CLIENTEDGE     0x200      && The window has a border with a sunken edge.
#DEFINE WS_EX_COMPOSITED     0x02000000 
#DEFINE	WS_EX_STATICEDGE     0x00020000 && The window has a three-dimensional border style intended to be used for items that do not accept user input.
#DEFINE WS_EX_WINDOWEDGE     0x00000100 && The window has a border with a raised edge.
#DEFINE WS_EX_CONTROLPARENT  0x00010000
#DEFINE WS_EX_LEFT         	 0
#DEFINE WS_EX_LTRREADING     0
#DEFINE WS_EX_RIGHTSCROLLBAR 0
#DEFINE WS_EX_TRANSPARENT    0x00020
#DEFINE WS_EX_LAYERED        0x80000

* Edit control styles
* https://docs.microsoft.com/en-us/windows/win32/controls/edit-control-styles
#DEFINE ES_LEFT             0x0000
#DEFINE ES_CENTER           0x0001
#DEFINE ES_RIGHT            0x0002
#DEFINE ES_AUTOHSCROLL      0x0080
#DEFINE ES_PASSWORD         0x0020 && Displays an asterisk (*) for each character typed into the edit control. 
	&& This style is valid only for single-line edit controls.
	&& To change the characters that is displayed, or set or clear this style, use the EM_SETPASSWORDCHAR message.
#DEFINE ES_MULTILINE        0x0004
#DEFINE ES_UPPERCASE        0x0008
#DEFINE ES_LOWERCASE        0x0010
#DEFINE ES_AUTOVSCROLL      0x0040
#DEFINE ES_AUTOHSCROLL      0x0080
#DEFINE ES_NOHIDESEL        0x0100
#DEFINE ES_OEMCONVERT       0x0400
#DEFINE ES_READONLY         0x0800
#DEFINE ES_WANTRETURN       0x1000
#DEFINE ES_NUMBER           0x2000

* SystemTime enum
#DEFINE DTM_FIRST           0x1000
#DEFINE DTM_GETSYSTEMTIME   0x1001
#DEFINE DTM_SETSYSTEMTIME   0x1002
#DEFINE DTM_SETRANGE        0x1004

#DEFINE EM_GETSEL           0x00B0
#DEFINE EM_SETSEL           0x00B1
#DEFINE EM_SELECTALL        0x00B2

#DEFINE IMAGE_BITMAP        0
#DEFINE IMAGE_ICON          1
#DEFINE LR_LOADFROMFILE     0x0010
#DEFINE LR_DEFAULTSIZE      0x0040


* Month Calendar Messages
#define MCM_GETCURSEL	0x1001
#define MCM_SETCURSEL	0x1002
#define MCM_GETMAXSELCOUNT 0x1003
#define MCM_SETMAXSELCOUNT 0x1004
#define MCM_GETSELRANGE	0x1005
#define MCM_SETSELRANGE	0x1006
#define MCM_GETMONTHRANGE 0x1007
#define MCM_SETDAYSTATE	0x1008
#define MCM_GETMINREQRECT 0x1009
#define MCM_SETCOLOR 0x100a
#define MCM_GETCOLOR 0x100b
#define MCM_SETTODAY 0x100c
#define MCM_GETTODAY 0x100d
#define MCM_HITTEST 0x100e
#define MCM_SETFIRSTDAYOFWEEK 0x100f
#define MCM_GETFIRSTDAYOFWEEK 0x1010
#define MCM_GETRANGE 0x1011
#define MCM_SETRANGE 0x1012
#define MCM_GETMONTHDELTA 0x1013
#define MCM_SETMONTHDELTA 0x1014
#define MCN_SELCHANGE	  (-749)
#define MCN_GETDAYSTATE	(-747)
#define MCN_SELECT		(-746)



* https://www.rpi.edu/dept/cis/software/g77-mingw32/include/commctrl.h



FUNCTION FoxyDialog(tcTitle, tcInstruction, tcContent, tnIcon, tcButtons, tnDefaultBtn, tnTimeout) && , tcTimeoutCaption2)

LOCAL ldDefaultDate, lnPos
	SET LIBRARY TO vfp2c32.fll ADDITIVE
    LOCAL loMsgB, lnOption
    m.loMsgB = CREATEOBJECT("xmbMsgBoxEx")

	LOCAL lcDialogType
	lcDialogType = ALLTRIM(UPPER(GETWORDNUM(m.tcButtons,1,",")))
	DO CASE
	CASE LEFT(lcDialogType, 2) = "@I" && Inputbox
		m.loMsgB.nDialogType = 2 && InputBox
		lnPos = AT(",",tcButtons,1)
		tcButtons = SUBSTR(tcButtons,lnPos)
		tcContent = tcContent + CHR(13) + CHR(13) + CHR(13)
		
		DO CASE
		CASE VARTYPE(m.tnDefaultBtn) = "N" AND INLIST(lcDialogType, "@ID", "@II", "@IN") && Digits or Integer
			m.loMsgB._cDefaultInput = TRANSFORM(m.tnDefaultBtn)
		OTHERWISE
			m.loMsgB._cDefaultInput = EVL(m.tnDefaultBtn,"")
		ENDCASE

		tnDefaultBtn = 1
		* Store the formatting information
		m.loMsgB._cEditBoxFmt = UPPER(SUBSTR(m.lcDialogType, 3))
		m.loMsgB._cEditBoxNumeric = "-0123456789" + SET("Point")
		m.loMsgB._SetPoint = SET("Point")
	CASE INLIST(lcDialogType, "@D", "@T", "@M", "@R") && DateBox, DateTimeBox, MonthBox, DateRangeBox
		tcButtons = SUBSTR(tcButtons,3)

		DO CASE
		CASE lcDialogType = "@D"
			tcContent = tcContent + CHR(13) + CHR(13) + CHR(13)
			m.loMsgB.nDialogType = 3

		CASE lcDialogType = "@T"
			tcContent = tcContent + CHR(13) + CHR(13) + CHR(13)
			m.loMsgB.nDialogType = 4

		CASE lcDialogType = "@M"
			tcContent = tcContent + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13)
			m.loMsgB.nDialogType = 5

		CASE lcDialogType = "@R"
			tcContent = tcContent + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13) + CHR(13)
			m.loMsgB.nDialogType = 6

		OTHERWISE
		ENDCASE
		
		DO CASE
		CASE VARTYPE(tnDefaultBtn) = "C"
			ldDefaultDate = EVL(CTOD(m.tnDefaultBtn), {})
		CASE VARTYPE(tnDefaultBtn) = "D"
			ldDefaultDate = m.tnDefaultBtn
		CASE VARTYPE(m.tnDefaultBtn) = "T" AND lcDialogType = "@T"
			m.loMsgB._dDefaultDateTime = m.tnDefaultBtn
			ldDefaultDate = TTOD(m.tnDefaultBtn)
		CASE VARTYPE(tnDefaultBtn) = "T"
			ldDefaultDate = TTOD(m.tnDefaultBtn)
		OTHERWISE
			ldDefaultDate = {}
		ENDCASE
		m.loMsgB._dDefaultDate = m.ldDefaultDate 
		tnDefaultBtn = 1

	OTHERWISE && Normal Dialog

	ENDCASE

    m.lnOption = m.loMsgB.SendMessage(m.tcTitle, m.tcInstruction, m.tcContent, m.tnIcon, m.tcButtons, m.tnDefaultBtn, m.tnTimeout) &&, m.tcTimeoutCaption2)
    m.loMsgB  = NULL

    RETURN m.lnOption
ENDFUNC


DEFINE CLASS xmbMsgBoxEx AS CUSTOM
    Interval         = 0
    nXmbTimeout      = 0
    hDialog          = 0
    nSeconds         = SECONDS()
    cHeading         = ""
    _hDialogUI       = 0
    cFontName        = "Arial"
    nFontSize        = 9
    nDefaultBtn      = 1
    nRows            = 1
    nButtons         = 0
    cTimeoutCaption  = ""
    nIconBack        = 0
    nIconMain        = 0
    lFakeTimeOut     = .F.
    nDefaultInterval = XMB_TIMERINTERVAL
	hLibImageRes     = 0
	hLibShell32      = 0
	nDialogType      = 1 && 1=Normal dialog, 2=INPUTBOX dialog, 3=DateBox, 4=MonthCalendar, 5=DateRangeCalendar
	_lUpdatedIcon    = .F.
	_hEditBox        = 0
	_cEditBoxFmt     = "" && !U=ES_UPPERCASE, DI=ES_NUMERIC, P=ES_PASSWORD, L=ES_LOWERCASE, N=All accepted, internally formatted
	_cEditBoxNumeric = "0123456789"
	_SetPoint        = "."
	_cInputText      = ""
	_dInputDate      = {}
	_dInputDate2     = {}
	_tInputDateTime  = ""
	_hDateBox        = 0
	_hTimeBox        = 0
	_dDefaultDate    = {}
	_dDefaultDateTime = {//::}
	_nOriginalTimeout = 0 && value<=0 = no timer
	_cDefaultInput   = ""
	_nLastButton     = 0
	_hCustomControl  = 0
	_hExternalIcon   = 0
	_cExternalIconFile = ""
	_hStaticImage    = 0
	_hStaticLabel    = 0
	PROCEDURE DeclareAPI
	
		* We need to put the API declaration here to avoid acrazy error ???
        DECLARE SHORT TaskDialog IN comctl32 ;
            AS xmbTaskDialog ;
            INTEGER hWndParent, INTEGER hInstance, ;
            STRING pszWindowTitle, STRING pszMainInstruction, ;
            STRING pszContent, INTEGER dwCommonButtons, ;
            INTEGER pszIcon, INTEGER @pnButton

		DECLARE LONG LoadLibrary IN kernel32 AS LoadLibraryA STRING lpLibFileName

		DECLARE LONG FreeLibrary IN kernel32 LONG hLibModule

		DECLARE LONG LoadImage   IN user32   AS LoadImageA ;
			LONG hinst, LONG lpsz, LONG dwImageType, LONG dwDesiredWidth, LONG dwDesiredHeight, LONG dwFlags

		DECLARE LONG DestroyIcon IN user32 LONG hIcon
		
		DECLARE INTEGER CreateWindowEx IN user32 AS CreateWindowEx;
			INTEGER dwExStyle, STRING lpClassName,;
			STRING lpWindowName, INTEGER dwStyle,;
			INTEGER x, INTEGER y, INTEGER nWidth, INTEGER nHeight,;
			INTEGER hWndParent, INTEGER hMenu, INTEGER hInstance,;
			INTEGER lpParam  			

        DECLARE INTEGER GetWindowRect IN user32 INTEGER hwnd, STRING @lpRect
		DECLARE INTEGER GetClientRect IN user32 INTEGER hWindow, STRING @lpRect
		DECLARE INTEGER GetWindowLong IN user32 INTEGER hWnd, INTEGER nIndex

		DECLARE LONG GetStockObject  IN gdi32.dll LONG nIndex
		DECLARE INTEGER SendMessageW IN user32 INTEGER hwindow, INTEGER msg, INTEGER wParam, INTEGER LPARAM
		DECLARE INTEGER SendMessageW IN user32 as SendMessageWText INTEGER hwindow, INTEGER msg, INTEGER wParam, STRING LPARAM
		DECLARE integer SetFocus IN WIN32API integer
	ENDPROC 

	
    PROCEDURE Init
        This.AddProperty("aKeys[1,4]", .F.)
        This.aKeys(1, 3) = 0
        This.AddObject("oTimer", "xmbTimer")
        This.AddProperty("aButtonsHwnd[1]", 0)
		This.DeclareAPI
    ENDPROC


    PROCEDURE SendMessage(tcTitle, tcInstruction, tcContent, tnIcon, tcButtons, tnDefaultBtn, tnTimeout) && , tcTimeoutCaption)
		LOCAL loRange as "EMPTY"
		LOCAL lnIcontoSend
		m.tcTitle       = EVL(m.tcTitle, "")
		m.tcInstruction = EVL(m.tcInstruction, "")
		m.tcContent     = EVL(m.tcContent, "")
		m.tcButtons     = EVL(m.tcButtons, "Ok")
		
        LOCAL lnButtons, lnResult, N, lnButtonId, lcCaption2
        LOCAL laAnswer[1], laButtonId[1], lnOffset, lnPos, lnReturn, lnlast
        LOCAL lnBtnCount
        m.lnBtnCount = GETWORDCOUNT(m.tcButtons, ",")
        IF m.lnBtnCount > 6
        	MESSAGEBOX("Maximum buttons available is 6!",16,"Dialog error")
        	RETURN .F.
        ENDIF 

        m.lcCaption2 = ""
        IF VARTYPE(m.tnTimeout) = "C"
            m.lcCaption2 = GETWORDNUM(m.tnTimeout,2,",")
            m.tnTimeout = VAL(GETWORDNUM(m.tnTimeout,1,","))
        ENDIF

        IF NOT VARTYPE(m.tnDefaultBtn) $ "NL"
        	MESSAGEBOX("Invalid parameter for the default button!",16,"Dialog error")
        	RETURN .F.
        ENDIF 
        This.nDefaultBtn = IIF(EMPTY(m.tnDefaultBtn), 1, m.tnDefaultBtn)
		IF NOT BETWEEN(This.nDefaultBtn,1,m.lnBtnCount)
			This.nDefaultBtn = 1
		ENDIF 


		This.PrepareMainIcon(m.tnIcon)
		m.lnIcontoSend = IIF(INLIST(This.nIconBack,0,ICON_EMPTY), This.nIconMain, This.nIconBack)


		* If there is no timeout, we'll still use a fake timer to make some initial adjustments after the dialog is created
        This._nOriginalTimeout = EVL(m.tnTimeout,0)
		IF EMPTY(m.tnTimeout)
			m.tnTimeout = 1000
			This.lFakeTimeout = .T.
		ENDIF
        This.nXmbTimeout = IIF(VARTYPE(m.tnTimeout)="N", m.tnTimeout, 0)
        
        This.cTimeoutCaption = EVL(m.lcCaption2, "")
        IF NOT EMPTY(m.lcCaption2)
            LOCAL lcFontName, lnFontSize
            =GetDialogFont(@m.lcFontName, @m.lnFontSize)
            This.cFontName = EVL(m.lcFontName, "Arial")
            This.nFontSize = EVL(m.lnFontSize, 9)

            IF NOT "<SECS>" $ m.lcCaption2
                This.cTimeoutCaption = " - " + "<SECS>" + m.lcCaption2
            ENDIF
        ENDIF

        LOCAL lnButtonsA
        This.nButtons = m.lnBtnCount
        DIMENSION THIS.aButtonsHwnd(m.lnBtnCount)

        THIS.ADDPROPERTY("aButtons[1,2]", "")
        DIMENSION THIS.aButtons(m.lnBtnCount, 2)
        DIMENSION m.laButtonId(6)
        m.laButtonId(1) = 32
        m.laButtonId(2) = 32 + 16
        m.laButtonId(3) = 32 + 16 + 8
        m.laButtonId(4) = 32 + 16 + 8 + 4
        m.laButtonId(5) = 32 + 16 + 8 + 4 + 2
        m.laButtonId(6) = 32 + 16 + 8 + 4 + 2 + 1

		LOCAL lcBtnComplete, lcBtnCaption, lnBtnIcon
        FOR m.N = 1 TO m.lnBtnCount
            lcBtnComplete = GETWORDNUM(m.tcButtons, m.N, ",")
            lcBtnCaption = GETWORDNUM(m.lcBtnComplete, 1, "_")
            lnBtnIcon    = VAL(GETWORDNUM(m.lcBtnComplete, 2, "_"))

			* Update predefined Unicode buttons
			IF "*" $ m.lcBtnCaption 
				DO CASE
				CASE LOWER(m.lcBtnCaption) = "ok*"
					m.lcBtnCaption = "Ok <UC>2713</UC>"
				CASE LOWER(m.lcBtnCaption) = "cancel*"
					m.lcBtnCaption = "Cancel <UC>d83dddd9</UC>"
				CASE LOWER(m.lcBtnCaption) = "print*"
					m.lcBtnCaption = "Print <UC>2399</UC>"
				CASE LOWER(m.lcBtnCaption) = "save*"
					m.lcBtnCaption = "Save <UC>d83dddab</UC>"
				CASE LOWER(m.lcBtnCaption) = "search*"
					m.lcBtnCaption = "Search <UC>d83ddd0e</UC>"
				OTHERWISE
				ENDCASE            
			ENDIF 

			* Update predefined colored icons
			IF "#" $ m.lcBtnCaption 
				DO CASE
				CASE LOWER(m.lcBtnCaption) = "ok#"
					m.lcBtnCaption = "Ok_116802"
				CASE LOWER(m.lcBtnCaption) = "cancel#"
					m.lcBtnCaption = "Cancel_89"
				CASE LOWER(m.lcBtnCaption) = "print#"
					m.lcBtnCaption = "Print_51"
				CASE LOWER(m.lcBtnCaption) = "save#"
					m.lcBtnCaption = "Save_116761"
				CASE LOWER(m.lcBtnCaption) = "search#"
					m.lcBtnCaption = "Search_116774"
				OTHERWISE
				ENDCASE
	            lnBtnIcon    = VAL(GETWORDNUM(m.lcBtnCaption, 2, "_"))
	            lcBtnCaption = GETWORDNUM(m.lcBtnCaption, 1, "_")
			ENDIF 

            THIS.aButtons(m.N, 1) = lcBtnCaption
            THIS.aButtons(m.N, 2) = m.lnBtnIcon 
            m.lnButtonsA   = m.laButtonId(m.N)
        ENDFOR

        m.tcTitle       = ToUnicode(m.tcTitle)
        m.tcInstruction = ToUnicode(m.tcInstruction)
        m.tcContent     = ToUnicode(m.tcContent)

        * a substitute for the MAKEINTRESOURCE
        m.lnIcontoSend = BITAND(0x0000ffff, m.lnIcontoSend)
        m.lnButtons  = m.lnButtonsA
        m.lnButtonId = 0  && the must

        BINDEVENT(0, WM_KEYUP,    This, 'WndProc')
        BINDEVENT(0, WM_ACTIVATE, This, 'WndProc')

        m.lnResult = xmbTaskDialog(_SCREEN.HWND, 0, m.tcTitle, ;
            m.tcInstruction, m.tcContent, m.lnButtons, m.lnIcontoSend, @m.lnButtonId)

        UNBINDEVENTS(0, WM_ACTIVATE)

	        DO CASE
            CASE m.lnResult < 0
    	        m.lnReturn = 0
	        CASE m.lnBtnCount = 2 AND m.lnButtonId = 4 && 1st button
                m.lnReturn = 1
       	    OTHERWISE
           	    DIMENSION m.laAnswer(6)
               	m.laAnswer(1) = 1
	            m.laAnswer(2) = 6
                m.laAnswer(3) = 7
       	        m.laAnswer(4) = 4
           	    m.laAnswer(5) = 2
	            m.laAnswer(6) = 8
                m.lnPos    = ASCAN(m.laAnswer, m.lnButtonId)
       	        m.lnOffset = 6 - m.lnBtnCount + 1
           	    m.lnReturn = m.lnPos - m.lnOffset + 1
	        ENDCASE

	        * Last check to know if CANCEL or <ESC> was pressed
    	    INKEY(.2)
        	m.lnlast = This.aKeys(ALEN(This.aKeys, 1), 3)
	        DO CASE
    	    CASE This.nXmbTimeout = -1
        	    m.lnReturn = -1
			CASE m.lnlast = 27
    	        m.lnReturn = 0
        	OTHERWISE
	        ENDCASE
	        UNBINDEVENTS( 0, WM_KEYUP )        && Free the Keyboard

		DO CASE
		CASE This.nDialogType = 2 && INPUTBOX
		
			LOCAL llNumeric, lnOrigDecimals, lnDecimals, lnPos
			IF "N" $ This._cEditBoxFmt OR ;
					"D" $ This._cEditBoxFmt OR ;
					"I" $ This._cEditBoxFmt  && Numeric Inputbox
				llNumeric = .T.
			ENDIF 
		
			IF This._nLastButton = 2 && Cancel
				RETURN ""
			ELSE
				IF llNumeric && trick to use VAL() and bypass the SET("Decimals")
					lnOrigDecimals = SET("Decimals")
					lnPos = AT(SET("Point"),This._cInputText)
					lnDecimals = IIF(lnPos=0,0,LEN(SUBSTR(This._cInputText, lnPos + 1)))
					SET DECIMALS TO (lnDecimals)
					lnReturn = VAL(This._cInputText)
					SET DECIMALS TO (lnOrigDecimals)
					RETURN lnReturn
				ELSE 
					RETURN This._cInputText
				ENDIF 
			ENDIF

		CASE This.nDialogType = 3 && DATEBOX
			IF This._nLastButton = 2 && Cancel
				RETURN ""
			ELSE 
				RETURN This._dInputDate
			ENDIF

		CASE This.nDialogType = 4 && DATETIME BOX
			IF This._nLastButton = 2 && Cancel
				RETURN ""
			ELSE 
				RETURN This._tInputDateTime
			ENDIF

		CASE This.nDialogType = 5 && MONTHCALENDAR BOX
			IF This._nLastButton = 2 && Cancel
				RETURN ""
			ELSE 
				RETURN This._dInputDate
			ENDIF

		CASE This.nDialogType = 6 && MONTHCALENDAR RANGE BOX
			loRange = CREATEOBJECT("EMPTY")
			IF This._nLastButton = 2 && Cancel
				ADDPROPERTY(loRange, "StartDate", {})
				ADDPROPERTY(loRange, "EndDate"  , {})
			ELSE 
				ADDPROPERTY(loRange, "StartDate", This._dInputDate)
				ADDPROPERTY(loRange, "EndDate"  , This._dInputDate2)
			ENDIF
			RETURN loRange

		OTHERWISE
	        RETURN m.lnReturn && Default dialog

		ENDCASE

    ENDPROC
 

    * Windows event handler procedure
    * MSDN WindowProc callback function
    * http://msdn.microsoft.com/en-us/library/windows/desktop/ms633573(v=vs.85).aspx
    * http://hermantan.blogspot.com/2008/07/centering-vfp-messagebox-in-any-form.html
    * Here we will make all the modifications in the Windows dialog
    PROCEDURE WndProc( th_Wnd, tn_Msg, t_wParam, t_lParam)

        LOCAL lcCaption, lcText, lhFirst, lhLast, lhLastFound, lhWindow, lhWndButton, lnButton, lhWndMain
        LOCAL lnRows, n, liIcon
        IF (m.tn_Msg == WM_ACTIVATE) AND (m.t_wParam == 0) AND (m.t_lParam <> 0)

            m.lhWndMain = m.t_lParam
            This.hDialog = m.lhWndMain

            * Getting the 1st Client Window
            m.lhWindow = 0
            m.lhLastFound = 0
            DO WHILE .T.
                m.lhWindow = xmbFindWindowEx(m.lhWndMain, m.lhWindow, NULL, NULL)

                IF m.lhWindow = 0
                    * 123=ERROR_INVALID_NAME
                    * 127=ERROR_PROC_NOT_FOUND
                    * DECLARE INTEGER GetLastError IN kernel32
                    * ? "Exit on error:", GetLastError()
                    EXIT
                ELSE
                    m.lhLastFound = m.lhWindow
                ENDIF
            ENDDO

			This._hDialogUI = m.lhLastFound && This is the dialog UI, that contains the buttons, and will receive the EditBox if nDialogType = 2
	
            * Set the focus at the desired button
            FOR m.n = 1 TO This.nDefaultBtn - 1
                KEYBOARD '{TAB}'
            ENDFOR

            * Getting the Child objects from the client Window
            m.lhWindow = m.lhLastFound
            m.lhFirst  = xmbGetWindow(m.lhWindow, GW_CHILD)
            m.lhWindow = xmbGetWindow(m.lhFirst, GW_HWNDFIRST)
            m.lhLast   = xmbGetWindow(m.lhFirst, GW_HWNDLAST)

            m.lnButton = 0
            DO WHILE .T.
                m.lhWndButton = xmbFindWindowEx(m.lhWindow, 0, NULL, NULL)
                m.lcText  = ALLTRIM(GetWinText(m.lhWndButton))

                * Changing the captions
                IF NOT EMPTY(m.lcText) && AND GetWindowClass(lhWndButton) = "Button"
                    m.lnButton  = m.lnButton + 1

                    * Store the button hWnd
                    This.aButtonsHwnd(m.lnButton) = m.lhWndButton
                    m.lcCaption = THIS.aButtons(m.lnButton, 1)
                    * Disable button if needed
                    IF LEFT(m.lcCaption, 1) = "\"
                        m.lcCaption = SUBSTR(m.lcCaption, 2) && get the rest of the string
                        =xmbEnableWindow(m.lhWndButton, 0)
                    ENDIF

					m.lcCaption = TOUNICODE(m.lcCaption)
					=xmbSetWindowTextZ(m.lhWndButton, m.lcCaption)
					
					* Adding the button icons
					m.liIcon = This.aButtons(m.lnButton, 2)
					IF NOT EMPTY(m.liIcon)
						=This.SetButtonIcon(m.lhWndButton, 1, m.liIcon)
					ENDIF 
                 ELSE
                    *!* * Close a window having its handle
                    *!* #DEFINE WM_SYSCOMMAND  0x0112
                    *!* #DEFINE SC_CLOSE       0xF060
                    *!* XmbSendMessage(lhWndButton, WM_SYSCOMMAND, SC_CLOSE, 0)
                ENDIF

                * Disable the 'X' close button
                IF m.lhWindow = m.lhLast
                    * Declare Integer GetSystemMenu In User32 Integer HWnd, Integer bRevert
                    * Declare INTEGER EnableMenuItem IN User32 Long hMenu, LONG wIDEnableItem, LONG wEnable
                    * DECLARE LONG GetMenuItemCount IN user32 LONG hMenu
                    * DECLARE LONG RemoveMenu IN user32 LONG HMENU, LONG NPOSITION, LONG WFLAGS
                    #DEFINE SC_CLOSE          0xF060
                    #DEFINE MF_BYCOMMAND      0
                    #DEFINE MF_BYPOSITION     0x400
                    #DEFINE MF_CHECKED        8
                    #DEFINE MF_DISABLED       2
                    #DEFINE MF_GRAYED         1
                    #DEFINE MF_REMOVE         0x00001000

                    * EnableMenuItem(GetSystemMenu(t_lParam, 0), SC_CLOSE, MF_BYCOMMAND + MF_DISABLED + MF_GRAYED)
                    xmbEnableMenuItem(xmbGetSystemMenu(m.t_lParam, 0), SC_CLOSE, MF_DISABLED)
                    EXIT
                ENDIF
                m.lhWindow = xmbGetWindow(m.lhWindow, GW_HWNDNEXT)
            ENDDO

            * All buttons initialized, start timer, if needed
            IF This.nXmbTimeout > 1
                This.nXmbTimeout = This.nXmbTimeout && - (SECONDS() - This.nSeconds)*1000 && Discount the elapsed time
                This.oTimer.Interval = 35
                This.oTimer.Enabled = .T.
                This.oTimer.nCurrentTimeout = ROUND(This.nXmbTimeout / 1000,0)

                IF NOT EMPTY(This.cTimeoutCaption)
                    This.cHeading = ALLTRIM(GetWinText(This.hDialog))

                    * Obtain the Dialog width
                    LOCAL lcNewHeading, lnLeft, lnRemain, lnRepeat, lnRight, lnSizeCompl, lnSizeSpace, lnSizeTitle
                    LOCAL lnWidth, lcRect
                    m.lcRect = REPLICATE(CHR(0),16)
                    = GetWindowRect(This.hDialog, @m.lcRect)
                    m.lnLeft = CTOBIN(SUBSTR(m.lcRect, 1,4),"4RS")
                    m.lnRight = CTOBIN(SUBSTR(m.lcRect, 9,4),"4RS")
                    m.lnWidth = m.lnRight - m.lnLeft
                    *lnTop = CTOBIN(SUBSTR(lcRect, 5,4),"4RS")
                    *lnBottom = CTOBIN(SUBSTR(lcRect, 13,4),"4RS")

                    m.lnSizeTitle = getTextSize(This.cHeading, This.cFontName, This.nFontSize)
                    m.lnSizeCompl = getTextSize(ALLTRIM(This.cTimeoutCaption), This.cFontName, This.nFontSize)
                    m.lnSizeSpace = getTextSize(SPACE(10), This.cFontName, This.nFontSize)

                    m.lnRemain = m.lnWidth - m.lnSizeTitle - m.lnSizeCompl
                    m.lnRepeat = FLOOR(m.lnRemain / m.lnSizeSpace) - 1

                    IF m.lnRepeat > 0
                        m.lcNewHeading = This.cHeading + REPLICATE(SPACE(10),m.lnRepeat) + ALLTRIM(This.cTimeoutCaption)
                    ELSE
                        m.lcNewHeading = This.cHeading + This.cTimeoutCaption
                    ENDIF

                    This.cHeading = m.lcNewHeading
                ENDIF

            ENDIF

        ENDIF

        IF m.tn_Msg == WM_KEYUP
            m.lnRows = This.nRows + 1
            DIMENSION This.aKeys(m.lnRows, 4)
            This.aKeys(m.lnRows, 1) = m.th_Wnd
            This.aKeys(m.lnRows, 2) = m.tn_Msg
            This.aKeys(m.lnRows, 3) = m.t_wParam
            This.aKeys(m.lnRows, 4) = m.t_lParam
        ENDIF

        LOCAL pOrgProc
        m.pOrgProc = xmbGetWindowLong( _VFP.HWND, -4 )
        = xmbCallWindowProc( m.pOrgProc, m.th_Wnd, m.tn_Msg, m.t_wParam, m.t_lParam )
    ENDPROC
 

	PROCEDURE PrepareMainIcon(tnIcon)
      	LOCAL lnIconMain, lnIconBack, lcIconMain, lcIconBack, lnIconToDraw
       	lnIconMain = 0
       	lnIconBack = 0

        IF VARTYPE(m.tnIcon) = "C"
        	IF LEFT(ALLTRIM(m.tnIcon),1) = "," && GETWORDNUM fails if the 1st item is empty
				lcIconMain = ""
				lcIconBack = GETWORDNUM(m.tnIcon,1,",")
			ELSE 
	        	lcIconMain = GETWORDNUM(m.tnIcon,1,",")
				IF FILEINDISK(m.lcIconMain) && We have a custom icon to load
					This._hExternalIcon = GetHIcon(m.lcIconMain)
					This._cExternalIconFile = m.lcIconMain
				ENDIF 
    	    	lcIconBack = LEFT(UPPER(GETWORDNUM(m.tnIcon,2,",")),1)
			ENDIF 
        	
			DO CASE
			CASE m.lcIconBack = "S" && Silver
				lnIconBack = -9
			CASE m.lcIconBack = "G" && Green
				lnIconBack = -8
			CASE m.lcIconBack = "R" && Red
				lnIconBack = -7
			CASE m.lcIconBack = "Y" && Yellow
				lnIconBack = -6
			CASE m.lcIconBack = "B" && Blue
				lnIconBack = -5
			CASE m.lcIconBack = "-" && Empty, no margin
				lnIconBack = 0
			OTHERWISE && Empty or Invalid
				lnIconBack = ICON_EMPTY
			ENDCASE

      
	       	IF VAL(m.lcIconMain) > 0 AND This._hExternalIcon = 0
    	   		m.lnIconMain = VAL(m.lcIconMain)
       		ELSE 	
	            m.tnIcon = ALLTRIM(UPPER(m.tnIcon))
    	        DO CASE
    	        	CASE This._hExternalIcon > 0
						m.lnIconMain = ICON_EMPTY
        	        CASE m.tnIcon = "!4" && Warning
            	        m.lnIconMain = 1403
                	CASE m.tnIcon = "!3" && Warning
                    	m.lnIconMain = 84
                	CASE m.tnIcon = "!2" && Warning
            	        m.lnIconMain = -6
        	        CASE m.tnIcon = "!" && Warning
    	                m.lnIconMain = -1

	                CASE m.tnIcon = "X5" && Error
            	        m.lnIconMain = 1402
        	        CASE m.tnIcon = "X4" && Error
    	                m.lnIconMain = 98
	                CASE m.tnIcon = "X3" && Error
                	    m.lnIconMain = 89
            	    CASE m.tnIcon = "X2" && Error
        	            m.lnIconMain = -7
    	            CASE m.tnIcon = "X" && Error
	                    m.lnIconMain = -2

        	        CASE m.tnIcon = "I2" && Information
    	                m.lnIconMain = 81
	                CASE m.tnIcon = "I" && Information
                	    m.lnIconMain = -3
            	    CASE m.tnIcon = "?2" && Question
        	            m.lnIconMain = 104
    	            CASE m.tnIcon = "?" && Question
	                    m.lnIconMain = 0x7f02 && IDI_QUESTION

	                CASE m.tnIcon = "OK4" && Success
    	                m.lnIconMain = 1405
        	        CASE m.tnIcon = "OK3" && Success
            	        m.lnIconMain = 1400
                	CASE m.tnIcon = "OK2" && Success
	                    m.lnIconMain = -8 && TD_SHIELD_OK_ICON
    	            CASE m.tnIcon = "OK" && Success
        	            m.lnIconMain = 106
	
    	            CASE m.tnIcon = "SHIELD" && Question
        	            m.lnIconMain = -4

	                CASE m.tnIcon = "KEY2" && Key
    	                m.lnIconMain = 5360 && Key icon
        	        CASE m.tnIcon = "KEY" && Key
            	        m.lnIconMain = 82 && Key icon
                	CASE m.tnIcon = "LOCK3" && Lock
                    	m.lnIconMain = 5381 && Lock icon
	                CASE m.tnIcon = "LOCK2" && Lock
    	                m.lnIconMain = 1304 && Lock icon
        	        CASE m.tnIcon = "LOCK" && Lock
            	        m.lnIconMain = 59 && Lock icon
                	CASE m.tnIcon = "ZIP" && Zip
                    	m.lnIconMain = 174

            	    CASE m.tnIcon = "SEARCH2" && Search
        	            m.lnIconMain = 5332
    	            CASE m.tnIcon = "SEARCH" && Search
	                    m.lnIconMain = 177

                	CASE m.tnIcon = "USER2" && User
            	        m.lnIconMain = 5356
        	        CASE m.tnIcon = "USER" && User
    	                m.lnIconMain = 1029
	
        	        CASE m.tnIcon = "CLOUD2" && Cloud
    	                m.lnIconMain = 1404
	                CASE m.tnIcon = "CLOUD" && Cloud
                	    m.lnIconMain = 1043

            	    CASE m.tnIcon = "STAR"
        	            m.lnIconMain = 1024
    	            CASE m.tnIcon = "FOLDER"
	                    m.lnIconMain = 1023

                	CASE m.tnIcon = "MAIL"
            	        m.lnIconMain = 20
        	        CASE m.tnIcon = "CONNECT2"
    	                m.lnIconMain = 179
	                CASE m.tnIcon = "CONNECT"
	                    m.lnIconMain = 25
    	            CASE m.tnIcon = "PRINTER2"
        	            m.lnIconMain = 45
            	    CASE m.tnIcon = "PRINTER"
                	    m.lnIconMain = 51
	                CASE m.tnIcon = "CAMERA"
    	                m.lnIconMain = 57
        	        CASE m.tnIcon = "FILM"
            	        m.lnIconMain = 46
                	CASE m.tnIcon = "FAX"
	                    m.lnIconMain = 76
    	            CASE m.tnIcon = "DOCUMENT"
        	            m.lnIconMain = 90
            	    CASE m.tnIcon = "SCAN"
                	    m.lnIconMain = 95
	                CASE m.tnIcon = "COMPUTER2"
    	                m.lnIconMain = 149
                	CASE m.tnIcon = "COMPUTER"
                	    m.lnIconMain = 109
            	    CASE m.tnIcon = "DIAGNOSE"
        	            m.lnIconMain = 150
    	                
	                CASE m.tnIcon = "MUSIC"
                    	m.lnIconMain = 1026
                	CASE m.tnIcon = "CANCEL"
            	        m.lnIconMain = 1027
        	        CASE m.tnIcon = "WRITE"
    	                m.lnIconMain = 5306
	                CASE m.tnIcon = "PLAY"
                 	   m.lnIconMain = 5341
                	CASE m.tnIcon = "CLOCK"
            	        m.lnIconMain = 5368
        	        CASE m.tnIcon = "MOBILE"
    	                m.lnIconMain = 6400
	
            	    OTHERWISE
        	            m.lnIconMain = 0
    	        ENDCASE
			ENDIF 

		ELSE
			m.lnIconMain = EVL(m.tnIcon, 0) && If passed no parameter or .F.
        ENDIF  &&  IF VARTYPE(m.tnIcon) = "C"

		This.nIconMain = m.lnIconMain
		This.nIconBack = m.lnIconBack
	ENDPROC 


	PROCEDURE ReplaceMainIcon
		LOCAL lcFmt, lhDialogInternal, lhEditBox, lhFont, lhParentHWnd, lnId, lhImage
		LOCAL dwExStyle, dwStyle, lhAppInstance, w1, h1, x1, y1, lcExt
		lhImage = This._hExternalIcon
		lhDialogInternal = This._hDialogUI

		x1   = 5
		y1   = 5
		w1   = 32
		h1   = 32
		lnId = 125
		
		#DEFINE SS_ICON           0x03
		#DEFINE SS_BITMAP         0x0E
		#DEFINE SS_WHITERECT      0x06
		#DEFINE SS_WHITEFRAME     0x09
		#DEFINE SS_CENTERIMAGE    0x200
		lcExt = UPPER(JUSTEXT(This._cExternalIconFile))
		lnImgType = IIF(lcExt = "ICO", SS_ICON, SS_BITMAP)
        dwStyle   = BITOR(WS_VISIBLE, WS_CHILD, lnImgType, SS_CENTERIMAGE)
        dwExStyle = 0

		* handle to application instance
		#DEFINE GWL_HINSTANCE -6
		lhParentHWnd = _Screen.HWnd 
		lhAppInstance = GetWindowLong(lhParentHWnd, GWL_HINSTANCE)

		*!*	HWND CreateWindowEx(
		*!*	  DWORD dwExStyle,      // extended window style
		*!*	  LPCTSTR lpClassName,  // registered class name
		*!*	  LPCTSTR lpWindowName, // window name
		*!*	  DWORD dwStyle,        // window style
		*!*	  int x,                // horizontal position of window
		*!*	  int y,                // vertical position of window
		*!*	  int nWidth,           // window width
		*!*	  int nHeight,          // window height
		*!*	  HWND hWndParent,      // handle to parent or owner window
		*!*	  HMENU hMenu,          // menu handle or child identifier
		*!*	  HINSTANCE hInstance,  // handle to application instance
		*!*	  LPVOID lpParam        // window-creation data

		lhStatic = CreateWindowEx(dwExStyle, "STATIC", "", dwStyle, ;
			x1, y1, w1, h1, lhDialogInternal, lnId, lhAppInstance, 0)

		*!*	* Test code for adding a static label control
		*!*	dwStyle2 = BITOR(WS_VISIBLE, WS_CHILD)
		*!*	lhStatic2 = CreateWindowEx(dwExStyle, "STATIC", "", dwStyle2, ;
		*!*		x1, y1 + 30, w1 * 3, 22, lhDialogInternal, lnId + 10, lhAppInstance, 0)
		*!*	= SendMessageWText(lhStatic2, WM_SETTEXT, 0, TOUNICODE("TESTING LABEL"))

		#DEFINE STM_SETICON  0x170
		#DEFINE STM_SETIMAGE 0x172
		IF lhStatic > 0
	        DECLARE INTEGER GetDC IN user32 INTEGER
            DECLARE INTEGER ReleaseDC IN user32 INTEGER, INTEGER
            DECLARE INTEGER CreateSolidBrush IN WIN32API INTEGER
            DECLARE INTEGER GetPixel IN WIN32API INTEGER, INTEGER, INTEGER

			#DEFINE BINDEVENTSEX_CALL_BEFORE	0x0001
			#DEFINE BINDEVENTSEX_CALL_AFTER		0x0002
			#DEFINE BINDEVENTSEX_RETURN_VALUE	0x0004
			#DEFINE BINDEVENTSEX_NO_RECURSION	0x0008
			#DEFINE BINDEVENTSEX_CLASSPROC		0x0010
			
			This._hStaticImage = m.lhStatic 
			* This._hStaticLabel = m.lhStatic2

			#DEFINE WM_CTLCOLORSTATIC	0x0138
			BINDEVENTSEX(This._hDialogUI, WM_CTLCOLORSTATIC, This, 'WndProc3', "Hwnd, uMsg, wParam, lParam", BINDEVENTSEX_RETURN_VALUE)
			IF lcExt = "ICO"
			    = SendMessageW(lhStatic, STM_SETIMAGE, IMAGE_ICON  , lhImage)
			ELSE 
			    = SendMessageW(lhStatic, STM_SETIMAGE, IMAGE_BITMAP, lhImage)
			ENDIF 
		ENDIF
	ENDPROC 


	PROCEDURE WndProc3(thWnd, tnMessage, twParam, tlParam)
		* ? thWnd, TRANSFORM(tnMessage, "@0"), twParam, tlParam
		* ? "Static Image", This._hStaticImage
		* ? "Static Label", This._hStaticLabel
		IF NOT PEMSTATUS(This, "_nIconBackColor", 5)
			LOCAL lnColor
			This.AddProperty("_nIconBackColor", 0)
			lhDC2 = GetWindowDC(This.hDialog)
			lnColor = GetPixel(lhDC2, 3, 30)
			This._nIconBackColor = lnColor
		ENDIF 
		*	LOCAL pOrgProc
		*	pOrgProc = xmbGetWindowLong(_VFP.HWnd, -4)
		*	= xmbCallWindowProc(pOrgProc, thWnd, tnMessage, twParam, tlParam)
		LOCAL lnBackColor
		DO CASE
		CASE tlParam = This._hStaticImage
			lnBackColor = This._nIconBackColor
		CASE tlParam = This._hStaticLabel
			lnBackColor = RGB(255,255,255)
		OTHERWISE
			lnBackColor = RGB(255,0,0)
		ENDCASE
	RETURN CreateSolidBrush(m.lnBackColor)


    PROCEDURE CloseDialog
    	LOCAL lnPrevLastButton
		m.lnPrevLastButton = This._nLastButton 
        * searching a command button to be virtually pressed
        This.nXmbTimeout = -1 && Flag to tell we finished
        LOCAL lhTarget
        m.lhTarget = This.aButtonsHwnd(This.nDefaultBtn)
        * simulates mouse click on the target button
        = xmbSendMessage(m.lhTarget, WM_LBUTTONDOWN, 0, 0)
        DOEVENTS  && just in case
        = xmbSendMessage(m.lhTarget, WM_LBUTTONUP, 0, 0)
		This._nLastButton = m.lnPrevLastButton
    ENDPROC


	PROCEDURE UpdateIcon(tnIcon)
		LOCAL lnIcon
		lnIcon = EVL(tnIcon, This.nIconMain)
		IF EMPTY(lnIcon)
			lnIcon = ICON_EMPTY
		ENDIF 
		lnIcon = BITAND(0x0000ffff, lnIcon)
		=xmbSendMessage(This.hDialog, TDM_UPDATE_ICON, TDIE_ICON_MAIN, m.lnIcon)
		RETURN 
	ENDPROC 


	FUNCTION SetButtonIcon(tnHwnd, tnModule, tnIndex)
		LOCAL lhIco, lhModule
		IF m.tnIndex < 100000 && Use ImageRes.Dll
			IF This.hLibImageRes = 0
				lhModule = LoadLibraryA("imageres.dll")
			ELSE 
				lhModule = This.hLibImageRes
			ENDIF 
		ELSE  && Use Shell32.Dll
			IF This.hLibShell32 = 0
				lhModule = LoadLibraryA("shell32.dll")
				* lhModule = LoadLibraryA("%SystemRoot%\system32\shell32.dll")
			ELSE 
				lhModule = This.hLibShell32
			ENDIF 
			tnIndex = tnIndex - 100000 && fix the correct index
		ENDIF 
	    lhIco = LoadImageA(lhModule, tnIndex, 1, 16, 16, 0)
	    =xmbSendMessage(tnHwnd, BM_SETIMAGE, 1, lhIco)
	    DestroyIcon(lhIco)
		RETURN 
    ENDFUNC 


    PROCEDURE Destroy
    	IF This.hLibImageRes > 0
			FreeLibrary(This.hLibImageRes)
		ENDIF
		IF This.hLibShell32 > 0
			FreeLibrary(This.hLibShell32)
		ENDIF 
	ENDPROC 


	PROCEDURE DialogCreated
		IF EMPTY(This.nIconBack) AND This.lFakeTimeout = .T. AND This.nDialogType = 1
			This.oTimer.Interval = 0 && No more need of this timer
		ENDIF 

		IF NOT EMPTY(This.nIconBack) AND This._lUpdatedIcon = .F.
			This._lUpdatedIcon = .T.
			This.UpdateIcon()
			IF This.lFakeTimeout = .T.
				This.oTimer.Interval = 0
			ELSE 
				This.oTimer.Interval = This.nDefaultInterval
			ENDIF 
		ENDIF 

		IF This._hExternalIcon > 0
			This.ReplaceMainIcon()
		ENDIF 

		LOCAL lhControl
		IF This.nDialogType = 2 && Inputbox
			This.AddTextBox()
			This.oTimer.Interval = This.nDefaultInterval
			lhControl = This._hEditBox
		ENDIF

		IF INLIST(This.nDialogType,3,4,5,6) && Datebox
			This.AddDateBox()
			This.oTimer.Interval = This.nDefaultInterval
			lhControl = This._hDateBox
		ENDIF
		
		IF This.nDialogType > 1
			This._hCustomControl = lhControl
			&& VFP2C32 BindEventsEx flags
			#DEFINE BINDEVENTSEX_CALL_BEFORE	0x0001
			#DEFINE BINDEVENTSEX_CALL_AFTER		0x0002
			#DEFINE BINDEVENTSEX_RETURN_VALUE	0x0004
			#DEFINE BINDEVENTSEX_NO_RECURSION	0x0008
			#DEFINE BINDEVENTSEX_CLASSPROC		0x0010
			* WM_SETFOCUS will give us the focused button
			BINDEVENTSEX(This.aButtonsHwnd[1], WM_SETFOCUS  , This, 'WndProc2')
			BINDEVENTSEX(This.aButtonsHwnd[2], WM_SETFOCUS  , This, 'WndProc2')
			* WM_GETDLGCODE will give the key pressed on each control
			* To handle the <ESC> and <TAB> keys
			BINDEVENTSEX(m.lhControl, WM_GETDLGCODE, This, 'WndProc2')
			BINDEVENTSEX(This.aButtonsHwnd[1], WM_GETDLGCODE, This, 'WndProc2')
			BINDEVENTSEX(This.aButtonsHwnd[2], WM_GETDLGCODE, This, 'WndProc2')
		ENDIF 
	ENDPROC 


	PROCEDURE AddTextBox
		* About Edit controls
		* https://docs.microsoft.com/en-us/windows/win32/controls/about-edit-controls#changing-the-formatting-rectangle

		LOCAL lcFmt, lhDialogInternal, lhEditBox, lhFont, lhParentHWnd, lnBottom, lnId, lnTop
		LOCAL dwExStyle, dwStyle, h1, lhAppInstance, w1, x1, y1
		lhDialogInternal = This._hDialogUI

        * Obtain the Dialog dimensions
        LOCAL lnLeft, lnRight, lnWidth, lnHeight, lcRect
        m.lcRect = REPLICATE(CHR(0),16)
        =GetClientRect(lhDialogInternal, @m.lcRect)
        m.lnLeft   = CTOBIN(SUBSTR(m.lcRect, 1,4),"4RS")
        m.lnRight  = CTOBIN(SUBSTR(m.lcRect, 9,4),"4RS")
        m.lnTop    = CTOBIN(SUBSTR(m.lcRect, 5,4),"4RS")
        m.lnBottom = CTOBIN(SUBSTR(m.lcRect,13,4),"4RS")
            
        m.lnWidth  = m.lnRight  - m.lnLeft
        m.lnHeight = m.lnBottom - m.lnTop

		* ? "Dimensions", lnLeft, lnRight, lnTop, lnBottom, lnWidth, lnHeight
		x1 = 45
		y1 = lnHeight - 80
		w1 = lnWidth - x1 - x1
		h1 = 21
		lnId = 110
        dwStyle   = BITOR(WS_VISIBLE, WS_CHILD, WS_TABSTOP, ES_LEFT, ES_AUTOHSCROLL,ES_NOHIDESEL) && WS_BORDER

		lcFmt = This._cEditBoxFmt && !U=ES_UPPERCASE, DI=ES_NUMERIC, P=ES_PASSWORD, L=ES_LOWERCASE
		IF "!" $ lcFmt OR "U" $ lcFmt
			dwStyle = BITOR(dwStyle, ES_UPPERCASE)
		ENDIF 
		IF "D" $ lcFmt OR "I" $ lcFmt
			dwStyle = BITOR(dwStyle, ES_NUMBER)
		ENDIF 
		IF "L" $ lcFmt
			dwStyle = BITOR(dwStyle, ES_LOWERCASE)
		ENDIF 
		IF "P" $ lcFmt
			dwStyle = BITOR(dwStyle, ES_PASSWORD) && Displays an asterisk (*) for each character typed into the edit control. 
									&& This style is valid only for single-line edit controls.
									&& To change the characters that is displayed, or set or clear this style, use the EM_SETPASSWORDCHAR message.
		ENDIF 

        dwExStyle = BITOR(WS_EX_CLIENTEDGE,0) && ,WS_EX_CONTROLPARENT)   && Sunken edge

		* handle to application instance
		#DEFINE GWL_HINSTANCE -6
		lhParentHWnd = _Screen.HWnd 
		lhAppInstance = GetWindowLong(lhParentHWnd, GWL_HINSTANCE)

		*!*	HWND CreateWindowEx(
		*!*	  DWORD dwExStyle,      // extended window style
		*!*	  LPCTSTR lpClassName,  // registered class name
		*!*	  LPCTSTR lpWindowName, // window name
		*!*	  DWORD dwStyle,        // window style
		*!*	  int x,                // horizontal position of window
		*!*	  int y,                // vertical position of window
		*!*	  int nWidth,           // window width
		*!*	  int nHeight,          // window height
		*!*	  HWND hWndParent,      // handle to parent or owner window
		*!*	  HMENU hMenu,          // menu handle or child identifier
		*!*	  HINSTANCE hInstance,  // handle to application instance
		*!*	  LPVOID lpParam        // window-creation data
		lhEditBox = CreateWindowEx(dwExStyle, "Edit", This._cDefaultInput, ;
			dwStyle, x1, y1, w1, h1, lhDialogInternal, lnId, lhAppInstance, 0)

		#DEFINE DEFAULT_GUI_FONT    17
		#DEFINE OUT_OUTLINE_PRECIS  8
		#DEFINE CLIP_STROKE_PRECIS  2
		#DEFINE PROOF_QUALITY       2
	    lhFont = GetStockObject(DEFAULT_GUI_FONT)
	    IF lhFont > 0
			SendMessageW(lhEditBox, WM_SETFONT, lhFont, 0)
        ENDIF
		This._hEditBox = lhEditBox
		=SetFocus(lhEditBox)
		SendMessageW(lhEditBox, EM_SETSEL, 0, -1)
	ENDPROC 
	

	PROCEDURE AddDateBox

		* About Date and Time picker
		* https://docs.microsoft.com/en-us/windows/win32/controls/date-and-time-picker-control-reference
		LOCAL lcDefaultDate, lhDateTime, lhDateTime0, lhDialogInternal, lhFont, lhParentHWnd, lhTime
		LOCAL lnBorder, lnBottom, lnHOffset, lnId, lnTop
		LOCAL dwExStyle, dwStyle, h1, h2, lhAppInstance, w1, w2, x1, x2, y1, y2
		lhDialogInternal = This._hDialogUI

        * Obtain the Dialog dimensions
        LOCAL lnLeft, lnRight, lnWidth, lnHeight, lcRect
        m.lcRect = REPLICATE(CHR(0),16)
        =GetClientRect(lhDialogInternal, @m.lcRect)
        m.lnLeft   = CTOBIN(SUBSTR(m.lcRect, 1,4),"4RS")
        m.lnRight  = CTOBIN(SUBSTR(m.lcRect, 9,4),"4RS")
        m.lnTop    = CTOBIN(SUBSTR(m.lcRect, 5,4),"4RS")
        m.lnBottom = CTOBIN(SUBSTR(m.lcRect,13,4),"4RS")

        m.lnWidth  = m.lnRight  - m.lnLeft
        m.lnHeight = m.lnBottom - m.lnTop

		* ? "Dimensions", lnLeft, lnRight, lnTop, lnBottom, lnWidth, lnHeight
		lnId = 110

		* Enum DTSTYLES
		* https://docs.microsoft.com/en-us/windows/win32/controls/date-and-time-picker-control-styles
		#DEFINE DTS_SHORTDATEFORMAT        0x00
		#DEFINE DTS_UPDOWN                 0x01
		#DEFINE DTS_SHOWNONE               0x02
		#DEFINE DTS_LONGDATEFORMAT         0x04
		#DEFINE DTS_TIMEFORMAT             0x09
		#DEFINE DTS_APPCANPARSE            0x10
		#DEFINE DTS_RIGHTALIGN             0x20
		#DEFINE DTS_SHORTDATECENTURYFORMAT 0x0C

		* handle to application instance
		#DEFINE GWL_HINSTANCE -6
		lhParentHWnd = _Screen.HWnd 
		lhAppInstance = GetWindowLong(lhParentHWnd, GWL_HINSTANCE)

		* http://chokuto.ifdef.jp/advanced/function/CreateWindowEx.html && CreateWindowEx
		*!*	HWND CreateWindowEx(
		*!*	  DWORD dwExStyle,      // extended window style
		*!*	  LPCTSTR lpClassName,  // registered class name
		*!*	  LPCTSTR lpWindowName, // window name
		*!*	  DWORD dwStyle,        // window style
		*!*	  int x,                // horizontal position of window
		*!*	  int y,                // vertical position of window
		*!*	  int nWidth,           // window width
		*!*	  int nHeight,          // window height
		*!*	  HWND hWndParent,      // handle to parent or owner window
		*!*	  HMENU hMenu,          // menu handle or child identifier
		*!*	  HINSTANCE hInstance,  // handle to application instance
		*!*	  LPVOID lpParam        // window-creation data

        dwStyle   = BITOR(WS_CHILD, WS_OVERLAPPED, WS_VISIBLE, DTS_SHORTDATEFORMAT) && Original
        dwExStyle = BITOR(WS_EX_CLIENTEDGE, WS_EX_LEFT, WS_EX_LTRREADING, WS_EX_RIGHTSCROLLBAR)

		IF EMPTY(This._dDefaultDateTime)
			lcDefaultDate = This.GetDateTimeBuf(This._dDefaultDate)
		ELSE 
			lcDefaultDate = This.GetDateTimeBuf(This._dDefaultDateTime)
		ENDIF 

		lhDateTime = 0
		lhTime     = 0

		DO CASE
		CASE This.nDialogType = 3 && Date
			x1 = 115
			y1 = lnHeight - 80
			w1 = lnWidth - x1 - x1
			h1 = 21
	        lhDateTime = CreateWindowEx(m.dwExStyle, "SysDateTimePick32", "", ;
                                   dwStyle, x1, y1, w1, h1, m.lhDialogInternal, lnId, m.lhAppInstance, 0)


		CASE This.nDialogType = 4 && DateTime
			lnBorder = 45
			w1 = 120
			w2 = 80
			lnHOffset = FLOOR((lnWidth - lnBorder - lnBorder - w1 - w2) / 3)

			x1 = lnBorder + lnHOffset
			y1 = lnHeight - 80
			h1 = 21

			x2 = x1 + w1 + lnHOffset
			y2 = y1
			h2 = h1

	        lhDateTime = CreateWindowEx(m.dwExStyle, "SysDateTimePick32", "", ;
                                   dwStyle, x1, y1, w1, h1, m.lhDialogInternal, lnId, m.lhAppInstance, 0)

	        dwStyle   = BITOR(WS_CHILD, WS_OVERLAPPED, WS_VISIBLE, DTS_TIMEFORMAT) && Time
	        lhTime = CreateWindowEx(m.dwExStyle, "SysDateTimePick32", "", ;
                                   dwStyle, x2, y2, w2, h2, m.lhDialogInternal, lnId + 1, m.lhAppInstance, 0)


		CASE This.nDialogType = 5 && Month calendar

			* MCM_GETMINREQRECT
			* retrieves the minimum size required to display a full month in a month calendar control. 
			* Size information is presented in the form of a RECT structure.
			* Parameters
			*  - wParam - Not used.
			*  - lpRectInfo - Long pointer to a RECT structure that receives bounding rectangle information.

			* First, create a fake object (the Taskdialog API does not let "SetWindowPos" to reposition
			lhDateTime0 = CreateWindowEx(m.dwExStyle, "SysMonthCal32", "", ;
				WS_CHILD, 1, 1, 1, 1, m.lhDialogInternal, lnId, m.lhAppInstance, 0)

			LOCAL lnObjWidth, lnObjHeight, lcRect
			m.lcRect = REPLICATE(CHR(0),16)
			SendMessageWText(lhDateTime0, MCM_GETMINREQRECT, 0, @lcRect)
    	    m.lnObjWidth  = CTOBIN(SUBSTR(m.lcRect, 9,4),"4RS")
	        m.lnObjHeight = CTOBIN(SUBSTR(m.lcRect,13,4),"4RS")

			x1 = FLOOR((lnWidth - lnObjWidth) / 2)
			y1 = lnHeight - 55 - lnObjHeight

			* Finally, create the definitive object, at the desired position
			* SYSMONTHCAL32 references
			* http://svn.vdf-guidance.com/cWindowsEx/trunk/cWindowsEx/cWindowsEx%20Library/AppSrc/cMonthCal.h
			* http://svn.vdf-guidance.com/Crossmerge/trunk/CMOS/AppSrc/cMonthCalendar.h && Header 
	        dwStyle   = BITOR(WS_CHILD, WS_OVERLAPPED, WS_VISIBLE, DTS_SHORTDATEFORMAT,WS_CLIPCHILDREN,WS_CLIPSIBLINGS) && Original

	        lhDateTime = CreateWindowEx(m.dwExStyle, "SysMonthCal32", "", ;
				dwStyle, x1, y1, lnObjWidth, lnObjHeight, m.lhDialogInternal, lnId, m.lhAppInstance, 0)


		CASE This.nDialogType = 6 && Month date range

			#DEFINE MCS_MULTISELECT 2
			#DEFINE MCS_NOSELCHANGEONNAV 0x0100
			#DEFINE MCS_SHORTDAYSOFWEEK 0x0080

			* First, create a fake object (the Taskdialog API does not let "SetWindowPos" to reposition
			* To make it fit in the dialog, we reduce the calendar width using MCS_SHORTDAYSOFWEEK
			lhDateTime0 = CreateWindowEx(m.dwExStyle, "SysMonthCal32", "", ;
				WS_CHILD + MCS_SHORTDAYSOFWEEK, 1, 1, 1, 1, m.lhDialogInternal, lnId, m.lhAppInstance, 0)

			LOCAL lnObjWidth, lnObjHeight, lcRect
			m.lcRect = REPLICATE(CHR(0),16)
			SendMessageWText(lhDateTime0, MCM_GETMINREQRECT, 0, @lcRect)
    	    m.lnObjWidth  = CTOBIN(SUBSTR(m.lcRect, 9,4),"4RS")
	        m.lnObjHeight = CTOBIN(SUBSTR(m.lcRect,13,4),"4RS")


			* Finally, create the definitive object, at the desired position
			* SYSMONTHCAL32 references
			* http://svn.vdf-guidance.com/cWindowsEx/trunk/cWindowsEx/cWindowsEx%20Library/AppSrc/cMonthCal.h
			* http://svn.vdf-guidance.com/Crossmerge/trunk/CMOS/AppSrc/cMonthCalendar.h && Header 
	        dwStyle   = BITOR(WS_CHILD, WS_OVERLAPPED, WS_VISIBLE, DTS_SHORTDATEFORMAT,WS_CLIPCHILDREN,WS_CLIPSIBLINGS) && Original

			#DEFINE MCS_MULTISELECT 2
			#DEFINE MCS_NOSELCHANGEONNAV 0x0100
			#DEFINE MCS_SHORTDAYSOFWEEK 0x0080
			m.lnObjWidth = (m.lnObjWidth * 2) - 6 && fit 2 calendars
			x1 = FLOOR((lnWidth - lnObjWidth) / 2)
			y1 = lnHeight - 55 - lnObjHeight
			dwStyle = dwStyle + MCS_MULTISELECT + MCS_NOSELCHANGEONNAV + MCS_SHORTDAYSOFWEEK

	        lhDateTime = CreateWindowEx(m.dwExStyle, "SysMonthCal32", "", ;
				dwStyle, x1, y1, lnObjWidth, lnObjHeight, m.lhDialogInternal, lnId, m.lhAppInstance, 0)

			SendMessageW(lhDateTime, MCM_SETMAXSELCOUNT, 366, 0) && Maximum range is one year
		OTHERWISE

		ENDCASE
		
		IF NOT EMPTY(lhTime)
		    lhFont = GetStockObject(DEFAULT_GUI_FONT)
		    IF lhFont > 0
				SendMessageW(lhTime, WM_SETFONT, lhFont, 0)
	        ENDIF
	        * Store the current date and time to the 2nd object as well
	        =SendMessageWText(lhTime, DTM_SETSYSTEMTIME, 0, lcDefaultDate)
			This._hTimeBox = lhTime
		ENDIF

		IF NOT EMPTY(lhDateTime)
		    lhFont = GetStockObject(DEFAULT_GUI_FONT)
		    IF lhFont > 0
				SendMessageW(lhDateTime, WM_SETFONT, lhFont, 0)
	        ENDIF
    
	        * Store the current date
	        =SendMessageWText(lhDateTime, DTM_SETSYSTEMTIME, 0, lcDefaultDate)
			This._hDateBox = lhDateTime
			=SetFocus(lhDateTime)
		ENDIF 
	ENDPROC 


	PROCEDURE UpdateText
		LOCAL lcBuf, lnPos1, lnPos2, lqSel
		IF This._hEditBox <> 0
			lqSel = SendMessageW(This._hEditBox, EM_GETSEL, 0, 0)
			lcBuf = BINTOC(lqSel,"4RS")
			lnPos1 = CTOBIN(LEFT(lcBuf,2),"2RS")
			lnPos2 = CTOBIN(SUBSTR(lcBuf,3),"2RS")

			LOCAL lnLen as Integer, lcText as String 
            lnLen = SendMessageW(This._hEditBox, WM_GETTEXTLENGTH, 0, 0) * 2
			IF lnLen > 0 THEN
				lcText = SPACE(lnLen) + CHR(0)
				SendMessageWText(This._hEditBox, WM_GETTEXT, lnLen + 1, @lcText)
				lcText = STRCONV(m.lcText, 6) && FromUnicode
				
				* Validate the text
				DO CASE
				CASE "N" $ This._cEditBoxFmt
				* The inner CHRTRAN() function removes anything that is a number.  The return value is
				* what will be removed in the outer CHRTRAN function.
				* The accepted values
					LOCAL lcAccepted, lcDigitsOnly, lcPoint
					m.lcPoint = This._SetPoint
					m.lcAccepted = This._cEditBoxNumeric && "-0123456789."
					m.lcDigitsOnly = CHRTRAN(m.lcText, CHRTRAN(m.lcText, m.lcAccepted, SPACE(0)), SPACE(0))
					m.lcDigitsOnly = STRTRAN(m.lcDigitsOnly, lcPoint, "", 2, 9)
					m.lcDigitsOnly = STRTRAN(m.lcDigitsOnly, "-"    , "", 2, 9)
					IF AT("-", m.lcDigitsOnly) > 1
						m.lcDigitsOnly = STRTRAN(m.lcDigitsOnly, "-", "", 1, 9)
					ENDIF 
					IF m.lcDigitsOnly <> lcText && Update the input
						m.lcDigitsOnly = TOUNICODE(m.lcDigitsOnly) + CHR(0)
						=xmbSetWindowTextZ(This._hEditBox, m.lcDigitsOnly) && Update the contents

						* Since we excluded the intruder character, we need to reposition the Caret cursor
						lnPos2 = MAX(0, lnPos2-1) && Back one character
						SendMessageW(This._hEditBox, EM_SETSEL, lnPos2, lnPos2)
					ENDIF
				OTHERWISE
				ENDCASE
				
			ENDIF 
			This._cInputText = m.lcText
		ENDIF
	ENDPROC 
	

	PROCEDURE UpdateDate
		LOCAL lnRet
		IF This._hDateBox = 0
			RETURN
		ENDIF 

		LOCAL lcDate as String, lcDate2, ltDateTime, ldDate, ldDate2
		IF This.nDialogType = 6 && Date range
			lcDate = REPLICATE(CHR(0),32)
			lnRet = SendMessageWText(This._hDateBox, MCM_GETSELRANGE, 0, @lcDate)

			ltDateTime = This.GetDateTime(LEFT(lcDate,16))
			ldDate = TTOD(m.ltDateTime)
			This._dInputDate = m.ldDate

			ltDateTime = This.GetDateTime(SUBSTR(lcDate,17,16))
			ldDate2 = TTOD(m.ltDateTime)
			This._dInputDate2 = m.ldDate2
			RETURN
		ENDIF 

		lcDate = REPLICATE(CHR(0),16)
		SendMessageWText(This._hDateBox, DTM_GETSYSTEMTIME, 0, @lcDate)

		IF This._hTimeBox > 0 && having the time control, we need to merge both controls information
			lcDate2 = REPLICATE(CHR(0),16)
			SendMessageWText(This._hTimeBox, DTM_GETSYSTEMTIME, 0, @lcDate2)
			lcDate = LEFT(lcDate, 8) + SUBSTR(lcDate2, 9, 6) && Merged the Date part with the time from the 2nd control
		ENDIF 

		ltDateTime = This.GetDateTime(lcDate)
		ldDate = TTOD(m.ltDateTime)
		This._dInputDate = m.ldDate
		This._tInputDateTime = m.ltDateTime

		* SystemTime structure
		* https://docs.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-systemtime
		*!*	typedef struct _SYSTEMTIME {
		*!*	  WORD wYear;
		*!*	  WORD wMonth;
		*!*	  WORD wDayOfWeek;
		*!*	  WORD wDay;
		*!*	  WORD wHour;
		*!*	  WORD wMinute;
		*!*	  WORD wSecond;
		*!*	  WORD wMilliseconds;
		*!*	} SYSTEMTIME, *PSYSTEMTIME, *LPSYSTEMTIME
	ENDPROC 

	PROCEDURE GetDateTime(tcBuffer)
	
		* ? tcBuffer, LEN(tcBuffer), EMPTY(tcBuffer)
		IF VARTYPE(tcBuffer) <> "C"
			RETURN .F.
		ENDIF 
		LOCAL ltDateTime
		TRY 
			m.ltDateTime = DATETIME(CTOBIN(SUBSTR(tcBuffer,1,2),"2RS"), ; && Year
						CTOBIN(SUBSTR(tcBuffer,3,2),"2RS"), ; && Month
						CTOBIN(SUBSTR(tcBuffer,7,2),"2RS"), ; && Day
						CTOBIN(SUBSTR(tcBuffer,9,2),"2RS"), ; && Hour
						CTOBIN(SUBSTR(tcBuffer,11,2),"2RS"), ; && Minute
						CTOBIN(SUBSTR(tcBuffer,13,2),"2RS")) && Seconds
		CATCH 
			m.ltDateTime = {//::}
		ENDTRY 
		
		RETURN m.ltDateTime 

	PROCEDURE GetDateTimeBuf(tdDate)
		RETURN BINTOC(YEAR(m.tdDate),"2RS")    + ; && Year
				BINTOC(MONTH(m.tdDate),"2RS")  + ; && Month
				BINTOC(DOW(m.tdDate),"2RS")    + ; && Day of week
				BINTOC(DAY(m.tdDate),"2RS")    + ; && Day
				BINTOC(HOUR(m.tdDate),"2RS")   + ; && Hour
				BINTOC(MINUTE(m.tdDate),"2RS") + ; && Minute
				BINTOC(SEC(m.tdDate),"2RS")        && Seconds

	PROCEDURE WndProc2(thWnd, tnMessage, twParam, tlParam)
		* ? thWnd, TRANSFORM(tnMessage, "@0"), twParam, tlParam
		* ? 1,GetWinText(thWND)
		* ? 2,GetWinText(tnMessage)

		LOCAL lnBtnId
		m.lnBtnId = This.GetButtonIdFromWwnd(thWnd)

		DO CASE
		CASE m.tnMessage = WM_SETFOCUS
			This._nLastButton = m.lnBtnId

		CASE m.tnMessage = WM_GETDLGCODE AND twParam = 27 && ESC
			This._nLastButton = 2
			This.CloseDialog()

		* Focus the editbox
		CASE m.tnMessage = WM_GETDLGCODE AND twParam = 9 AND m.lnBtnId = 2 && TAB
			SetFocus(This._hCustomControl)
			IF This.nDialogType = 2 && INPUTBOX - select the whole string
				SendMessageW(This._hEditBox, EM_SETSEL, 0, -1)
			ENDIF 

		* Unfocus the editbox if the focus is at "Cancel"
		CASE m.tnMessage = WM_GETDLGCODE AND twParam = 9 AND m.thWnd = This._hEditBox && TAB
			IF This.nDialogType = 2 && INPUTBOX - select the whole string
				SendMessageW(This._hEditBox, EM_SETSEL, 0, 0)
			ENDIF 

		OTHERWISE
		ENDCASE
	ENDPROC 


	FUNCTION GetButtonIdFromWwnd(tnHwnd)
		* Having the hWnd, we get the button
		LOCAL n, lnID
		lnId = 0
		FOR n = 1 TO ALEN(This.aButtonsHwnd,1)
			IF This.aButtonsHwnd(n) = m.tnHwnd
				lnId = n
				EXIT
			ENDIF
		ENDFOR 
		RETURN lnId
	ENDFUNC 

ENDDEFINE


*********************************************************************
FUNCTION xmbGetWindowText(HWND, lpString, nMaxCount)&& (hWnd, @lpString, nMaxCount)
*********************************************************************
    DECLARE INTEGER GetWindowText IN user32 ;
        AS xmbGetWindowText ;
        INTEGER HWND, STRING @lpString, INTEGER nMaxCount
    RETURN xmbGetWindowText(m.HWND, @m.lpString, m.nMaxCount)
ENDFUNC

*********************************************************************
FUNCTION xmbEnableWindow(HWND, fEnable)
*********************************************************************
    DECLARE INTEGER EnableWindow IN user32 AS xmbEnablewindow INTEGER HWND, INTEGER fEnable
    RETURN xmbEnableWindow(m.HWND, m.fEnable)
ENDFUNC

*********************************************************************
FUNCTION xmbSendMessage(hwindow, msg, wParam, LPARAM)
*********************************************************************
    * http://msdn.microsoft.com/en-us/library/bb760780(vs.85).aspx
    * http://www.news2news.com/vfp/?group=-1&function=312
    DECLARE INTEGER SendMessage IN user32 AS xmbsendmessage ;
        INTEGER hwindow, INTEGER msg, ;
        INTEGER wParam, INTEGER LPARAM
    RETURN xmbSendMessage(m.hwindow, m.msg, m.wParam, m.LPARAM)
ENDFUNC


*********************************************************************
FUNCTION xmbPostMessage(hwindow, msg, wParam, LPARAM)
*********************************************************************
    * http://msdn.microsoft.com/en-us/library/bb760780(vs.85).aspx
    * http://www.news2news.com/vfp/?group=-1&function=312
    DECLARE INTEGER PostMessage IN user32 AS xmbPostMessage ;
        INTEGER hwindow, INTEGER msg, ;
        INTEGER wParam, INTEGER LPARAM
    RETURN xmbPostMessage(m.hwindow, m.msg, m.wParam, m.LPARAM)
ENDFUNC



*********************************************************************
FUNCTION xmbDeleteObject(hobject)
*********************************************************************
    DECLARE INTEGER DeleteObject IN gdi32 AS xmbdeleteobject INTEGER hobject
    RETURN xmbDeleteObject(m.hobject)
ENDFUNC

*********************************************************************
FUNCTION xmbCallWindowProc(lpPrevWndFunc, nhWnd, uMsg, wParam, LPARAM)
*********************************************************************
    DECLARE LONG CallWindowProc IN User32 ;
        AS xmbCallWindowProc ;
        LONG lpPrevWndFunc, LONG nhWnd, ;
        LONG uMsg, LONG wParam, LONG LPARAM

    RETURN xmbCallWindowProc(m.lpPrevWndFunc, m.nhWnd, m.uMsg, m.wParam, m.LPARAM)
ENDFUNC

*********************************************************************
FUNCTION xmbGetWindowLong(nhWnd, nIndex)
*********************************************************************
    DECLARE LONG GetWindowLong IN User32 ;
        AS xmbGetWindowLong ;
        LONG nhWnd, INTEGER nIndex
    RETURN xmbGetWindowLong(m.nhWnd, m.nIndex)
ENDFUNC

*!* *********************************************************************
*!* FUNCTION xmbTaskDialog(hWndParent, hInstance, pszWindowTitle, pszMainInstruction, pszContent, dwCommonButtons, pszIcon, pnButton)
*!* *********************************************************************
*!*     DECLARE SHORT TaskDialog IN comctl32 ;
*!*         AS xmbTaskDialog ;
*!*         INTEGER hWndParent, INTEGER hInstance, ;
*!*         STRING pszWindowTitle, STRING pszMainInstruction, ;
*!*         STRING pszContent, INTEGER dwCommonButtons, ;
*!*         INTEGER pszIcon, INTEGER @pnButton
*!*     RETURN xmbTaskDialog(m.hWndParent, m.hInstance, m.pszWindowTitle, m.pszMainInstruction, m.pszContent, m.dwCommonButtons, m.pszIcon, m.pnButton)

*********************************************************************
FUNCTION xmbGetWindow(HWND, wFlag)
*********************************************************************
    DECLARE INTEGER GetWindow IN user32 ;
        AS xmbGetWindow ;
        INTEGER HWND, INTEGER wFlag
    RETURN xmbGetWindow(m.HWND, m.wFlag)

*********************************************************************
FUNCTION xmbIsWindow(hWnd)
*********************************************************************
    DECLARE INTEGER IsWindow IN user32 ;
        AS xmbIsWindow ;
        INTEGER hwnd
    RETURN xmbIsWindow(hWnd)

*********************************************************************
FUNCTION GetWinText(hwindow)
*********************************************************************
    LOCAL cBuffer
    m.cBuffer = REPLICATE(CHR(0), 255)
    = xmbGetWindowText(m.hwindow, @m.cBuffer, LEN(m.cBuffer))
    RETURN STRTRAN(m.cBuffer, CHR(0), "")
ENDFUNC

*********************************************************************
FUNCTION xmbSetWindowText(HWND, lpString)
*********************************************************************
    DECLARE INTEGER SetWindowText IN user32 ;
        AS xmbSetWindowText ;
        INTEGER HWND, STRING lpString
    RETURN xmbSetWindowText(m.HWND, m.lpString)
ENDFUNC

*********************************************************************
FUNCTION xmbSetWindowTextZ(HWND, lpString) && For Unicodes
*********************************************************************
    DECLARE INTEGER SetWindowTextW IN user32 ;
        AS xmbSetWindowTextZ ;
        INTEGER HWND, STRING lpString
    RETURN xmbSetWindowTextZ(m.HWND, m.lpString)
ENDFUNC


*********************************************************************
FUNCTION SetWinText(hwindow, tcText)
*********************************************************************
    = xmbSetWindowText(m.hwindow, m.tcText + CHR(0))
    RETURN
ENDFUNC

*********************************************************************
FUNCTION xmbRealGetWindowClass(hwindow, pszType, cchType)
*********************************************************************
    DECLARE INTEGER RealGetWindowClass IN user32 ;
        AS xmbRealGetWindowClass ;
        INTEGER hWindow, STRING @ pszType, ;
        INTEGER cchType
    RETURN xmbRealGetWindowClass(m.hwindow, m.pszType, m.cchType)
ENDFUNC

*********************************************************************
FUNCTION GetWindowClass(lnWindow)
*********************************************************************
    LOCAL lnLength, lcText
    m.lcText = SPACE(250)
    m.lnLength = xmbRealGetWindowClass(m.lnWindow, ;
        @m.lcText, LEN(m.lcText))
    RETURN IIF(m.lnLength > 0, ;
        LEFT(m.lcText, m.lnLength), "#empty#")
ENDFUNC

*********************************************************************
FUNCTION xmbFindWindowEx(hWndParent, hwndChildAfter, lpszClass, lpszWindow)
*********************************************************************
    DECLARE INTEGER FindWindowEx IN user32 ;
        AS xmbFindWindowEx ;
        INTEGER hwndParent, INTEGER hwndChildAfter, ;
        STRING @lpszClass, STRING @lpszWindow
    RETURN xmbFindWindowEx(m.hWndParent, m.hwndChildAfter, m.lpszClass, m.lpszWindow)
ENDFUNC

*********************************************************************
FUNCTION xmbGetSystemMenu(HWnd, bRevert)
*********************************************************************
    DECLARE INTEGER GetSystemMenu In User32 ;
        AS xmbGetSystemMenu ;
        INTEGER HWnd, INTEGER bRevert
    RETURN xmbGetSystemMenu(HWnd, bRevert)
ENDFUNC

*********************************************************************
FUNCTION xmbEnableMenuItem(hMenu, wIDEnableItem, wEnable)
*********************************************************************
    DECLARE INTEGER EnableMenuItem IN User32 ;
        AS xmbEnableMenuItem ;
        LONG hMenu, LONG wIDEnableItem, LONG wEnable
    RETURN xmbEnableMenuItem(hMenu, wIDEnableItem, wEnable)
ENDFUNC


*********************************************************************
* The timer class controls the timeout parameter
DEFINE CLASS xmbTimer as Timer
    * Interval is in milliseconds.
    * To get 5 seconds -> 5 seconds * 1000
    Interval = 0
    Enabled = .F.
    nCurrentTimeout = 0
	lStarted = .F.
    PROCEDURE Timer
		LOCAL lcNewText
        IF xmbIsWindow(This.Parent.hDialog) = 0
            * Possibly the dialog has been closed manually
            This.Parent.hDialog = 0
            This.Interval = 0  && stop the timer
        ELSE

			IF NOT This.lStarted && Run the initial setups after creation
				This.Parent.DialogCreated()
				This.lStarted = .T.
			ENDIF 

            * The dialog is still around, checking timeout
            This.Parent.nXmbTimeout = This.Parent.nXmbTimeout - This.Interval

            * Update the header of the dialog if needed
            IF NOT EMPTY(This.Parent.cTimeoutCaption)
                LOCAL lnTimeout
                m.lnTimeout = ROUND(This.Parent.nXmbTimeout / 1000, 0)
                IF m.lnTimeout <> This.nCurrentTimeout
					m.lcNewText = STRTRAN(This.Parent.cHeading, "<SECS>", "<UC>23f1</UC> " + TRANSFORM(m.lnTimeout)) && included the Unicode Watch
					m.lcNewText = TOUNICODE(m.lcNewText)
					* lcNewText = STRTRAN(This.Parent.cHeading, "<SECS>", TRANSFORM(lnTimeout))
					* = SetWinText(This.Parent.hDialog, lcNewText)
					=xmbSetWindowTextZ(This.Parent.hDialog, m.lcNewText)

					*!*	* Changing the captions after the dialog run
					*!*	loNewCaption = CREATEOBJECT("PChar", lcNewText)
					*!*	=xmbSendMessage(This.Parent.hDialog, TDM_SET_ELEMENT_TEXT, TDE_CONTENT, loNewCaption.GetAddr())
                ENDIF
            ENDIF

            
            IF This.Parent.nDialogType > 1 && Custom control

				DO CASE
				CASE This.Parent.nDialogType = 2 && INPUTBOX()
	            	This.Parent.UpdateText()

				CASE INLIST(This.Parent.nDialogType, 3, 4, 5, 6) && DATEBOX()
	            	This.Parent.UpdateDate()

				OTHERWISE

				ENDCASE

				IF This.Parent._nOriginalTimeout > 0 && We have a timeout active, let it work normally
				ELSE && We reset the timeout, because we need the timer to keep working till the user closes the dialog
					This.Parent.nXmbTimeout = 100000
				ENDIF 
            ENDIF 
      

            IF This.Parent.nXmbTimeout <= 0
                This.Parent.CloseDialog()
            ENDIF
            
        ENDIF
    ENDPROC
ENDDEFINE


*********************************************************************
FUNCTION getTextSize
	* Author: Mike Lewis
	* https://www.tek-tips.com/viewthread.cfm?qid=1525491
    * Determines the width in pixels of a given text string,
    * based on a given font, font style and point size.

    * Parameters: text string, font name, size in points,
    * font style in format used by FONTMETRIC()
    * (e.g. "B" for bold, "BI" for bold italic;
    * defaults to normal).
    LPARAMETERS tcString, tcFont, tnSize, tcStyle
    LOCAL lnTextWidth, lnAvCharWidth
    IF EMPTY(m.tcStyle)
        m.tcStyle = ""
    ENDIF
    m.lnTextWidth = TXTWIDTH(m.tcString, m.tcFont, m.tnSize, m.tcStyle)
    m.lnAvCharWidth = FONTMETRIC(6, m.tcFont, m.tnSize, m.tcStyle)
    RETURN m.lnTextWidth * m.lnAvCharWidth
ENDFUNC 



*********************************************************************
FUNCTION GetDialogFont(tcFontName, tnFontSize)
* Code derived from
* How to find which fonts Windows uses for drawing captions, menus and message boxes
* https://github.com/VFPX/Win32API/blob/master/samples/sample_556.md
* by VFPX / Anatolyi Mogylevets

    #DEFINE SPI_GETNONCLIENTMETRICS 0x0029
    #DEFINE NONCLIENTMETRICS_SIZE 0x0154
    #DEFINE LOGFONT_SIZE 0x003c
    #DEFINE LOGPIXELSY 0x005a

    LOCAL lfHeight, lcBuffer
    DECLARE INTEGER GetLastError IN kernel32
    DECLARE INTEGER GetWindowDC IN user32 INTEGER hWindow
    DECLARE INTEGER SystemParametersInfo IN user32;
        INTEGER uiAction, INTEGER uiParam,;
        STRING @pvParam, INTEGER fWinIni
    DECLARE INTEGER GetDeviceCaps IN gdi32;
        INTEGER hdc, INTEGER nIndex
    DECLARE INTEGER ReleaseDC IN user32;
        INTEGER hWindow, INTEGER hDC

    LOCAL lcNonClientMetrics
    * populating NONCLIENTMETRICS structure
    * the size of the structure occupies first 4 bytes
    m.lcNonClientMetrics=BINTOC(NONCLIENTMETRICS_SIZE,"4RS")

    * padding the structure to the required size
    m.lcNonClientMetrics=PADR(m.lcNonClientMetrics, NONCLIENTMETRICS_SIZE, CHR(0))

    * retrieving the metrics associated with the nonclient area
    * of nonminimized windows
    IF SystemParametersInfo(SPI_GETNONCLIENTMETRICS,;
            NONCLIENTMETRICS_SIZE, @m.lcNonClientMetrics, 0) = 0
        * ? "SystemParametersInfo call failed:", GetLastError()
        RETURN
    ENDIF

    * among other metrics, populated NONCLIENTMETRICS structure
    * contains data for 5 fonts used for drawing:
    * captions, small captions, menus, status bar and message boxes
    m.lcBuffer = 	SUBSTR(m.lcNonClientMetrics, 281, LOGFONT_SIZE)
    m.tcFontName = STRTRAN(SUBSTR(m.lcBuffer,29,32), CHR(0),"")

    LOCAL lhwindow, lhdc, lnPxPerInchY
    m.lhwindow=_screen.HWnd
    m.lhdc=GetWindowDC(m.lhwindow)
    m.lnPxPerInchY = GetDeviceCaps(m.lhdc, LOGPIXELSY)
    =ReleaseDC(m.lhwindow, m.lhdc)
    m.lfHeight=CTOBIN(SUBSTR(m.lcBuffer,1,4),"4RS")

    m.tnFontSize = ROUND((ABS(m.lfHeight) * 72) / m.lnPxPerInchY, 0)

    RETURN  
   
    
*********************************************************************
FUNCTION ToUnicode(tcStr)
*********************************************************************
LOCAL lnUnicodeCnt, lnPos, n, lcReturn, lnPos0, j, lnWidth
LOCAL laPos[1], lcText, lcUnicode, lnEnd, lnLen, lnStart, lnUnicodeIndex
m.lnUnicodeCnt = OCCURS("<UC>", m.tcStr)
m.lcReturn = ""

IF m.lnUnicodeCnt = 0 
    RETURN STRCONV(m.tcStr + CHR(0), 5)
ENDIF 

DIMENSION m.laPos(m.lnUnicodeCnt,4)
FOR m.n = 1 TO m.lnUnicodeCnt 
	m.lcUnicode = STREXTRACT(m.tcStr, "<UC>", "</UC>", m.n)
	m.lnStart = AT("<UC>", m.tcStr, m.n)
	m.lnEnd   = AT("</UC>", m.tcStr, m.n)
	m.laPos(m.n,1) = m.lnStart
	m.laPos(m.n,2) = m.lnEnd
	m.laPos(m.n,3) = m.lcUnicode
	m.laPos(m.n,4) = HEXTOUNICODE(m.lcUnicode)
ENDFOR 

m.lnLen = LEN(m.tcStr)
m.lnUnicodeIndex = 1

FOR m.j = 1 TO m.lnLen
	IF (m.lnUnicodeIndex <= m.lnUnicodeCnt) AND (m.j = m.laPos(m.lnUnicodeIndex,1)) && Get Unicode
		m.lcReturn = m.lcReturn + m.laPos(m.lnUnicodeIndex,4)
		m.j = m.laPos(m.lnUnicodeIndex,2)
		m.lnUnicodeIndex = m.lnUnicodeIndex + 1
		LOOP 		
	ELSE 
		m.lnStart = IIF(m.j = 1, 1, m.laPos(m.lnUnicodeIndex-1,2)+5)
		IF m.lnStart > m.lnLen
			EXIT
		ENDIF 
		
		IF m.lnUnicodeIndex > m.lnUnicodeCnt
			m.j = m.lnLen && Finished
			m.lcText = SUBSTR(m.tcStr, m.lnStart)
		ELSE 
			m.lnWidth = m.laPos(m.lnUnicodeIndex,1) - m.lnStart
			m.j = m.laPos(m.lnUnicodeIndex,1) - 1
			m.lcText = SUBSTR(m.tcStr, m.lnStart, m.lnWidth)
		ENDIF
		m.lcReturn = m.lcReturn + STRCONV(m.lcText, 5)
	ENDIF 
ENDFOR

RETURN m.lcReturn + CHR(0)
ENDFUNC
 

*********************************************************************
FUNCTION HexToUnicode(tcHex)
*********************************************************************
    LOCAL lhHex, lhUnicode, i, lcHex
    lhUnicode = 0h
    FOR i = 1 TO GETWORDCOUNT(tcHex, SPACE(1))
		lcHex = GETWORDNUM(tcHex, i, SPACE(1))
		IF LEN(lcHex) = 8
	        lhHex = EVALUATE("0h" + SUBSTR(lcHex,3,2) + LEFT(lcHex,2) + SUBSTR(lcHex,7,2) + SUBSTR(lcHex,5,2))
		ELSE 
	        lhHex = EVALUATE("0h" + SUBSTR(lcHex,3,2) + LEFT(lcHex,2))
		ENDIF 
        lhUnicode = lhUnicode + lhHex
    ENDFOR
    RETURN lhUnicode
ENDFUNC  



*********************************************************************
FUNCTION xmbLoadImage(hinst, lpszname, utype, cxdesired, cydesired, fuload)
*********************************************************************
        DECLARE INTEGER LoadImage IN user32 AS xmbloadimage;
            INTEGER hinst,;
            STRING lpszname,;
            INTEGER utype,;
            INTEGER cxdesired,;
            INTEGER cydesired,;
            INTEGER fuload
        RETURN xmbLoadImage(hinst, lpszname, uType, cxdesired, cydesired, fuload)
    ENDFUNC


*********************************************************************
FUNCTION FileInDisk(zcFileName)
*********************************************************************
	IF TYPE("zcfilename") <> "C"
    	RETURN .F.
	ENDIF
	DIMENSION laJunk[1] &&' so it is local
	RETURN (ADIR(laJunk, zcfilename, "ARS") > 0)
ENDFUNC 


FUNCTION GetHIcon(tcImgFile)
    LOCAL lhIcon, lcExt, liType
    lhIcon = 0
	IF EMPTY(m.tcImgFile) OR NOT FILE(m.tcImgFile)
		RETURN 0
	ENDIF 
	lcExt = UPPER(JUSTEXT(m.tcImgFile))
	IF lcExt = "ICO"
		liType = IMAGE_ICON
	ELSE
		liType = IMAGE_BITMAP
	ENDIF
    lhIcon = xmbLoadImage(0, FULLPATH(m.tcImgFile), liType, ;
                0,0, lr_loadfromFile + lr_defaultsize)
	IF lhIcon = 0
		SET STEP ON
	ENDIF 
	
	RETURN m.lhIcon
ENDFUNC 