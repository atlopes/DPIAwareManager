
SET PROCEDURE TO (SYS(16)) ADDITIVE

#DEFINE WM_DPICHANGED						0x02E0
#DEFINE WM_SETICON							0x0080

#DEFINE SIZEOF_MONITORINFO					40

#DEFINE DPI_STANDARD							96
#DEFINE DPI_STANDARD_SCALE					100
#DEFINE DPI_MAX_SCALE						300
#DEFINE DPI_SCALE_INCREMENT				25

#DEFINE DPIAW_NO_REPOSITION				0
#DEFINE DPIAW_RELATIVE_TOP_LEFT			0x01
#DEFINE DPIAW_CONSTRAINT_DIMENSION		0x02

#DEFINE ICON_SMALL	0
#DEFINE ICON_BIG		1

#DEFINE DC_LOGPIXELSX	88

Define Class DPIAwareManager As Custom

	* process DPI awareness type
	AwarenessType = 0

	* logging
	Logging = .F.

	* compensation for what is cut from a form when changing DPI (from 125 to 300%)
	* to be confirmed...
	WidthAdjustments = "2,6,8,10,12,14,16,18"
	HeightAdjustments = "8,17,25,32,40,49,56,63"

	* the collection of alternative fonts
	ADD OBJECT PROTECTED AlternativeFontNames AS Collection
	HIDDEN AlternativeFontNamesScale
	AlternativeFontNamesScale = DPI_STANDARD_SCALE

	* system function to gather information regarding DPI
	HIDDEN SystemInfoFunction
	SystemInfoFunction = 0

	* available displays
	ADD OBJECT Displays AS Collection
	ExtendedDisplaysOnly = .T.

	FUNCTION Init

		DECLARE LONG GetWindowDC IN WIN32API AS dpiaw_GetWindowDC ;
			LONG hWnd
		DECLARE LONG ReleaseDC IN WIN32API AS dpiaw_ReleaseDC ;
			LONG hWnd, LONG hDC
		DECLARE LONG GetDeviceCaps IN WIN32API AS dpiaw_GetDeviceCaps ;
			LONG hDC, INTEGER CapIndex
		DECLARE LONG MonitorFromWindow IN WIN32API AS dpiaw_MonitorFromWindow ;
			LONG hWnd, INTEGER Flags
		DECLARE LONG MonitorFromPoint IN WIN32API AS dpiaw_MonitorFromPoint ;
			LONG X, LONG Y, INTEGER Flags
		DECLARE INTEGER GetMonitorInfo IN WIN32API AS dpiaw_GetMonitorInfo ;
			LONG hMonitor, STRING @ MonitorInfo
		DECLARE INTEGER EnumDisplaySettings IN WIN32API AS dpiaw_EnumDisplaySettings ;
			STRING lpszDeviceName, INTEGER iModeNum, STRING @lpDevMode
		DECLARE INTEGER EnumDisplayDevices IN WIN32API AS dpiaw_EnumDisplayDevices ;
			STRING lpDevice, INTEGER iDevNum, ;
			STRING @lpDisplayDevice, INTEGER dwFlags
		DECLARE INTEGER ExtractIcon IN shell32 AS dpiaw_ExtractIcon ;
			INTEGER hInst, STRING FileName, INTEGER IndexIcon
		DECLARE INTEGER SendMessage IN user32 AS dpiaw_SendMessage ;
			INTEGER hWnd, INTEGER Msg, INTEGER wParam, INTEGER lParam

		TRY
			DECLARE LONG GetDpiForMonitor IN SHCORE.DLL AS dpiaw_GetDpiForMonitor ;
				LONG hMonitor, INTEGER dpiType, INTEGER @ dpiX, INTEGER @ dpiY
			This.SystemInfoFunction = 1
		CATCH
		ENDTRY

		TRY
			DECLARE INTEGER GetDpiForWindow IN WIN32API AS dpiaw_GetDpiForWindow ;
				LONG hWnd
			This.SystemInfoFunction = 2
		CATCH
		ENDTRY

		* get the awareness type of the process
		TRY
			DECLARE INTEGER IsProcessDPIAware IN WIN32API AS dpiaw_IsProcessDPIAware
			IF dpiaw_IsProcessDPIAware() != 0
				This.AwarenessType = 1
			ENDIF
			TRY
				DECLARE INTEGER GetProcessDpiAwareness IN Shcore.dll AS dpiaw_GetProcessDpiAwareness LONG Process, LONG @ Awareness
				LOCAL Awareness AS Integer
				m.Awareness = 0
				IF dpiaw_GetProcessDpiAwareness(0, @m.Awareness) == 0
					This.AwarenessType = m.Awareness
				ENDIF
			CATCH
			ENDTRY
		CATCH
		ENDTRY

		This.GetDisplaysInfo()

	ENDFUNC

****************************************************************************************
#DEFINE	METHODS_MANAGEMENT
****************************************************************************************

	* Manage
	* Puts a form under DPI-awareness management
	* It should be called before the form is shown
	FUNCTION Manage (AForm AS Form, Constraints AS Integer) AS Void

		* manage only forms, for now
		IF m.AForm.BaseClass != "Form"
			RETURN
		ENDIF

		* add DPI-aware related properties
		This.AddDPIProperty(m.AForm, "DPIAwareManager", This)
		This.AddDPIProperty(m.AForm, "hMonitor", dpiaw_MonitorFromWindow(m.AForm.HWnd, 0))
		This.AddDPIProperty(m.AForm, "DPIMonitorInfo", This.GetMonitorInfo(m.AForm.hMonitor, .F.))
		This.AddDPIProperty(m.AForm, "DPIMonitorClientAreaInfo", This.GetMonitorInfo(m.AForm.hMonitor, .T.))
		This.AddDPIProperty(m.AForm, "DPIScale", This.GetMonitorDPIScale(m.AForm))
		This.AddDPIProperty(m.AForm, "DPINewScale", m.AForm.DPIScale)
		This.AddDPIProperty(m.AForm, "DPIAutoConstraint", ;
			IIF(PCOUNT() == 1, ;
				IIF(m.AForm == _Screen OR m.AForm.ShowWindow == 2, DPIAW_NO_REPOSITION, DPIAW_RELATIVE_TOP_LEFT), ;
				m.Constraints))
		This.AddDPIProperty(m.AForm, "DPIManagerEvent", "Manage")
		This.AddDPIProperty(m.AForm, "DPIScaling", .F.)
		
		* save the original value of dimensional and positional properties of the form
		This.SaveContainer(m.AForm)

		* bind the form to the two listeners for changes of the DPI scale
		IF m.AForm == _Screen
			BINDEVENT(_Screen, "Moved", This, "CheckDPIScaleChange")
		ENDIF
		BINDEVENT(m.AForm.hWnd, WM_DPICHANGED, This, "WMCheckDPIScaleChange")
		* and to clean-up methods
		BINDEVENT(m.AForm, "Destroy", This, "CleanUp") 

		* if the form was created in a non 100% scale monitor, perform an initial scaling without preadjustment
		IF m.AForm.DPINewScale != DPI_STANDARD_SCALE
			IF m.AForm = _Screen AND PEMSTATUS(_Screen, "DPIAwareScreenManager", 5)
				_Screen.DPIAwareScreenManager.SelfManage(DPI_STANDARD_SCALE, m.AForm.DPINewScale) 
			ENDIF
			This.Scale(m.AForm, DPI_STANDARD_SCALE, m.AForm.DPINewScale, .T.)
		ENDIF

	ENDFUNC

	* ManageFont
	* Prepare a font to be managed whenever it occurs as a FontName control property
	FUNCTION ManageFont (OriginalFontName AS String, Scale AS Integer, AdjustedFontName AS String)

		LOCAL FontIndex AS Integer
		LOCAL AlternativeFont AS DPIAwareAlternativeFont

		* locate an existing font name controller object in the collection
		m.FontIndex = This.AlternativeFontNames.GetKey(UPPER(m.OriginalFontName))
		* create it, if it does not exist
		IF m.FontIndex == 0
			m.AlternativeFont = CREATEOBJECT("DPIAwareAlternativeFont", m.OriginalFontName)
			This.AlternativeFontNames.Add(m.AlternativeFont, UPPER(m.OriginalFontName))
		ELSE
			m.AlternativeFont = This.AlternativeFontNames.Item(m.FontIndex)
		ENDIF

		* add the alternative font name for a given scale (and up)
		m.AlternativeFont.AddAlternative(m.Scale, m.AdjustedFontName)

	ENDFUNC

	* CleanUp
	* Clean up a managed form
	FUNCTION CleanUp ()

		LOCAL ARRAY SourceEvent(1)
		AEVENTS(m.SourceEvent, 0)

		LOCAL DPIAwareForm AS Form
		m.DPIAwareForm = m.SourceEvent(1)

		TRY
			m.DPIAwareForm.DPIMonitorInfo = .NULL.
		CATCH
		ENDTRY
		TRY
			m.DPIAwareForm.DPIMonitorClientAreaInfo = .NULL.
		CATCH
		ENDTRY

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_SYSTEM_INFORMATION
****************************************************************************************

	* GetMonitorDPIScale
	* Returns the DPI scale of a monitor that a form is using.
	* The scale is a percentage (100%, 125%, ...).
	FUNCTION GetMonitorDPIScale (DPIAwareForm AS Form) AS Integer
	LOCAL dpiX AS Integer
	LOCAL hDC AS Integer

		* use the best available function to get the information
		TRY
			DO CASE
			CASE This.SystemInfoFunction = 2
				m.dpiX = dpiaw_GetDpiForWindow(m.DPIAwareForm.HWnd)
			CASE This.SystemInfoFunction = 1		&& not for Per-Monitor aware (AwarenessType = 2)
				m.dpiX = 0
				dpiaw_GetDpiForMonitor(m.DPIAwareForm.hMonitor, 0, @m.dpiX, @m.dpiX)
			OTHERWISE
				m.hDC = dpiaw_GetWindowDC(m.DPIAwareForm.HWnd)
				m.dpiX = dpiaw_GetDeviceCaps(m.hDC, DC_LOGPIXELSX)
				dpiaw_ReleaseDC(m.DPIAwareForm.HWnd, m.hDC)
			ENDCASE
		CATCH
			m.dpiX = DPI_STANDARD
		ENDTRY

		* returns a percentage relative to 96DPI (the standard DPI)
		RETURN MIN(MAX(INT(m.dpiX / DPI_STANDARD * DPI_STANDARD_SCALE), DPI_STANDARD_SCALE), DPI_MAX_SCALE)

	ENDFUNC

	* GetMonitorInfo
	* Returns dimensional and position information of a monitor.
	FUNCTION GetMonitorInfo (hMonitor AS Integer, IsWorkArea AS Logical) AS Object

		LOCAL MonitorInfoStructure AS String
		LOCAL Rect AS String
		LOCAL MonitorInfo AS Empty

		m.MonitorInfoStructure = BINTOC(SIZEOF_MONITORINFO, "4RS") + REPLICATE(0h00, SIZEOF_MONITORINFO - 4)

		dpiaw_GetMonitorInfo(m.hMonitor, @m.MonitorInfoStructure)

		IF !m.IsWorkArea
			m.Rect = SUBSTR(m.MonitorInfoStructure, 5, 16)
		ELSE
			m.Rect = SUBSTR(m.MonitorInfoStructure, 21, 16)
		ENDIF

		m.MonitorInfo = CREATEOBJECT("Empty")
		ADDPROPERTY(m.MonitorInfo, "Left", CTOBIN(SUBSTR(m.Rect, 1, 4), "4RS"))
		ADDPROPERTY(m.MonitorInfo, "Top",  CTOBIN(SUBSTR(m.Rect, 5, 4), "4RS"))
		ADDPROPERTY(m.MonitorInfo, "Right", CTOBIN(SUBSTR(m.Rect, 9, 4), "4RS"))
		ADDPROPERTY(m.MonitorInfo, "Bottom", CTOBIN(SUBSTR(m.Rect, 13, 4), "4RS"))
		ADDPROPERTY(m.MonitorInfo, "Width", m.MonitorInfo.Right - m.MonitorInfo.Left)
		ADDPROPERTY(m.MonitorInfo, "Height", m.MonitorInfo.Bottom - m.MonitorInfo.Top)

		RETURN m.MonitorInfo

	ENDFUNC

	* GetDisplaysInfo
	* Fetchs information on (active) displays and returns its number
	FUNCTION GetDisplaysInfo () AS Integer

		* refresh the collection of displays
		This.Displays.Remove(-1)

#DEFINE DISPLAY_DEVICE_ACTIVE					1
#DEFINE DISPLAY_DEVICE_PRIMARY_DEVICE		4
#DEFINE DISPLAY_DEVICE_MIRRORING_DRIVER	8

#DEFINE ENUM_CURRENT_SETTINGS					-1

#DEFINE MONITOR_DEFAULTTONEAREST				2

#DEFINE SIZEOF_DISPLAYDEVICE					424
#DEFINE SIZEOF_MONITORINFOEX					72

		LOCAL CStruct AS String
		LOCAL StateFlags AS Integer
		LOCAL MIndex AS Integer
		LOCAL MInfo AS Empty
		LOCAL VFPMonitor AS Integer
		LOCAL dpiX AS Integer

		* get VFP's monitor handle, for later
		m.VFPMonitor = dpiaw_MonitorFromWindow(_vfp.hWnd, MONITOR_DEFAULTTONEAREST)

		m.MIndex = 0

		* go through all available displays
		DO WHILE .T.

			m.CStruct = BINTOC(SIZEOF_DISPLAYDEVICE, "4RS") + REPLICATE(0h00, SIZEOF_DISPLAYDEVICE - 4)

			* this marks the end of the list, no more monitors
			IF dpiaw_EnumDisplayDevices(.NULL., m.MIndex, @m.CStruct, 0) == 0
				EXIT
			ENDIF

			m.StateFlags = CTOBIN(SUBSTR(m.CStruct, 165, 2), "2RS")
			* ignore inactive or mirrored displays? continue going through all monitors 
			IF This.ExtendedDisplaysOnly AND (!BITTEST(m.StateFlags, 0) OR BITTEST(m.StateFlags, 3))
				m.MIndex = m.MIndex + 1
				LOOP
			ENDIF

			* prepare an object to hold the information
			m.MInfo = CREATEOBJECT("Empty")

			ADDPROPERTY(m.MInfo, "DeviceIndex", m.MIndex)

			ADDPROPERTY(m.MInfo, "DeviceName", GETWORDNUM(SUBSTR(m.CStruct, 5, 32) + 0h00, 1, 0h00))
			ADDPROPERTY(m.MInfo, "DeviceString", GETWORDNUM(SUBSTR(m.CStruct, 37, 128) + 0h00, 1, 0h00))
			ADDPROPERTY(m.MInfo, "DeviceKey", GETWORDNUM(SUBSTR(m.CStruct, 297, 128) + 0h00, 1, 0h00))
			ADDPROPERTY(m.MInfo, "PrimaryDevice", BITTEST(m.StateFlags, 2))
			ADDPROPERTY(m.MInfo, "ActiveDevice", BITTEST(m.StateFlags, 0))
			ADDPROPERTY(m.MInfo, "StateFlags", m.StateFlags)

			* fetch the monitor name now that a device name is found
			m.CStruct = BINTOC(SIZEOF_DISPLAYDEVICE, "4RS") + REPLICATE(0h00, SIZEOF_DISPLAYDEVICE- 4)

			dpiaw_EnumDisplayDevices(m.MInfo.DeviceName, 0, @m.CStruct, 0)

			ADDPROPERTY(m.MInfo, "MonitorName", GETWORDNUM(SUBSTR(m.CStruct, 37, 128) + 0h00, 1, 0h00))

			* fetch the settings for the monitor
			m.CStruct = REPLICATE(CHR(0), 1024)

			dpiaw_EnumDisplaySettings(m.MInfo.DeviceName, ENUM_CURRENT_SETTINGS, @m.CStruct)

			ADDPROPERTY(m.MInfo, "Left", CTOBIN(SUBSTR(m.CStruct, 45, 4), "4RS"))
			ADDPROPERTY(m.MInfo, "Top", CTOBIN(SUBSTR(m.CStruct, 49, 4), "4RS"))
			ADDPROPERTY(m.MInfo, "Width", CTOBIN(SUBSTR(m.CStruct, 109, 4), "4RS"))
			ADDPROPERTY(m.MInfo, "Height", CTOBIN(SUBSTR(m.CStruct, 113, 4), "4RS"))
			ADDPROPERTY(m.MInfo, "BitsPerPixel", CTOBIN(SUBSTR(m.CStruct, 105, 4), "4RS"))
			ADDPROPERTY(m.MInfo, "Orientation", CTOBIN(SUBSTR(m.CStruct, 53, 4), "4RS"))
			ADDPROPERTY(m.MInfo, "FixedOutput", CTOBIN(SUBSTR(m.CStruct, 57, 4), "4RS"))
			ADDPROPERTY(m.MInfo, "Flags", CTOBIN(SUBSTR(m.CStruct, 117, 4), "4RS"))
			ADDPROPERTY(m.MInfo, "Frequency", CTOBIN(SUBSTR(m.CStruct, 121, 4), "4RS"))

			* we have the top left coordinates, get the monitor handle
			ADDPROPERTY(m.MInfo, "hMonitor", dpiaw_MonitorFromPoint(m.MInfo.Left, m.MInfo.Top, MONITOR_DEFAULTTONEAREST))

			ADDPROPERTY(m.MInfo, "_ScreenHost", m.MInfo.hMonitor == m.VFPMonitor)

			* and try to get its DPI setting
			TRY
				m.dpiX = DPI_STANDARD
				dpiaw_GetDpiForMonitor(m.MInfo.hMonitor, 0, @m.dpiX, @m.dpiX)
			CATCH
				m.dpiX = 0
			ENDTRY

			* store it and calculate the logical width and height
			ADDPROPERTY(m.MInfo, "DPI", m.dpiX)
			ADDPROPERTY(m.MInfo, "DPIScale", INT(m.dpiX * DPI_STANDARD_SCALE / DPI_STANDARD))
			ADDPROPERTY(m.MInfo, "DPIAware_Width", FLOOR(m.MInfo.Width * DPI_STANDARD / EVL(m.dpiX, DPI_STANDARD)))
			ADDPROPERTY(m.MInfo, "DPIAware_Height", FLOOR(m.MInfo.Height * DPI_STANDARD / EVL(m.dpiX, DPI_STANDARD)))

			* add to the collection of displays
			This.Displays.Add(m.MInfo)

			m.MIndex = m.MIndex + 1

		ENDDO

		* >= 1, or something really wrong happened...
		RETURN This.Displays.Count

	ENDFUNC

	* SetMonitorInfo
	* Sets positional, dimensional, and DPI information of current monitor
	FUNCTION SetMonitorInfo (DPIAwareForm AS Form, Source AS Form) 

		IF PCOUNT() == 1
			m.DPIAwareForm.hMonitor = dpiaw_MonitorFromWindow(m.DPIAwareForm.hWnd, 0)
		ELSE
			m.DPIAwareForm.hMonitor = m.Source.hMonitor
		ENDIF
		m.DPIAwareForm.DPIMonitorInfo = .NULL.
		m.DPIAwareForm.DPIMonitorInfo = This.GetMonitorInfo(m.DPIAwareForm.hMonitor, .F.)
		m.DPIAwareForm.DPIMonitorClientAreaInfo = .NULL.
		m.DPIAwareForm.DPIMonitorClientAreaInfo = This.GetMonitorInfo(m.DPIAwareForm.hMonitor, .T.)

	ENDFUNC

	* GetFormDPIScale
	* Returns the DPI Scale of the form that contains an object.
	FUNCTION GetFormDPIScale (DPIAwareObject AS Object) AS Integer

		LOCAL ObjectForm AS Form

		m.ObjectForm = This.GetThisform(m.DPIAwareObject)

		RETURN IIF(!ISNULL(m.ObjectForm), m.ObjectForm.DPIScale, DPI_STANDARD_SCALE)
			
	ENDFUNC

****************************************************************************************
#DEFINE METHODS_AKNOWLEDGE_AND_REACT_TO_DPI_CHANGES
****************************************************************************************

	* WMCheckDPIScaleChange
	* Receives a Windows message when the DPI has changed for the hWnd of a form.
	FUNCTION WMCheckDPIScaleChange (hWnd, uMsg, wParam, lParam)

		LOCAL DPIAwareForm AS Form
		LOCAL CreatedForm AS 

		m.DPIAwareForm = .NULL.

		* look for all forms until the matching hWnd is found
		FOR EACH m.CreatedForm AS Form IN _Screen.Forms
			IF m.CreatedForm.HWnd = m.hWnd
				m.DPIAwareForm = m.CreatedForm
				EXIT
			ENDIF
		ENDFOR

		IF ISNULL(m.DPIAwareForm)
			RETURN 0
		ENDIF

		m.DPIAwareForm.DPIManagerEvent = "WindowsMessage"

		* refresh information on the monitor where the form is being displayed
		This.SetMonitorInfo(m.DPIAwareForm)

		* proceed to the actual method that performs the rescaling (the new DPI scale is passed as a percentage)
		RETURN This.ChangeFormDPIScale(m.DPIAwareForm, MIN(MAX(BITAND(m.wParam, 0x07FFF) / DPI_STANDARD * DPI_STANDARD_SCALE, DPI_STANDARD_SCALE), DPI_MAX_SCALE))
	ENDFUNC

	* CheckDPIScaleChange
	* Notice when a DPI has changed and triggered a Moved event.
	FUNCTION CheckDPIScaleChange ()

		LOCAL ARRAY SourceEvent(1)
		AEVENTS(m.SourceEvent, 0)

		LOCAL DPIAwareForm AS Form
		m.DPIAwareForm = m.SourceEvent(1)

		* refresh information on the monitor where the form is being displayed
		This.SetMonitorInfo(m.DPIAwareForm)

		IF This.ChangeFormDPIScale(m.DPIAwareForm, This.GetMonitorDPIScale(m.DPIAwareForm)) = 0

			m.DPIAwareForm.DPIManagerEvent = "Moved"

			IF m.DPIAwareForm = _Screen

				FOR EACH m.DPIAwareForm AS Form IN _Screen.Forms
					IF m.DPIAwareForm.BaseClass == "Form" AND m.DPIAwareForm.ShowWindow = 0 AND PEMSTATUS(m.DPIAwareForm, "DPIAware", 5) AND m.DPIAwareForm.DPIAware
						* refresh information on the monitor where the form is being displayed
						This.SetMonitorInfo(m.DPIAwareForm, _Screen)
						This.ChangeFormDPIScale(m.DPIAwareForm, _Screen.DPIScale)
					ENDIF
				ENDFOR

			ENDIF

		ENDIF

	ENDFUNC

	* ChangeFormDPIScale
	* Change the DPI scale of a form.
	FUNCTION ChangeFormDPIScale (DPIAwareForm AS Form, NewDPIScale AS Integer) AS Integer

		LOCAL Ops AS Exception

		* act only if the scale of the form has changed (the _Screen may have only moved)
		IF m.NewDPIScale != m.DPIAwareForm.DPIScale

			TRY
				m.DPIAwareForm.DPIAware_BeforeScaling(m.DPIAwareForm.DPIScale, m.NewDPIScale)
			CATCH
			ENDTRY

			LOCAL IsMaximized AS Logical

			m.IsMaximized = (m.DPIAwareForm.WindowState == 2)

			m.DPIAwareForm.DPINewScale = m.NewDPIScale
			m.DPIAwareForm.LockScreen = .T.

			* perform the actual scaling
			TRY

				This.Scale(m.DPIAwareForm, m.DPIAwareForm.DPIScale, m.NewDPIScale)
				This.EnforceFormConstraints(m.DPIAwareForm)

				IF m.DPIAwareForm = _Screen AND PEMSTATUS(_Screen, "DPIAwareScreenManager", 5)
					_Screen.DPIAwareScreenManager.SelfManage(_Screen.DPIScale, m.NewDPIScale) 
				ENDIF

			CATCH TO m.Ops
				* activate the debugger
				SET STEP ON
			ENDTRY

			m.DPIAwareForm.LockScreen = .F.

			m.DPIAwareForm.DPIScale = m.NewDPIScale

			IF m.IsMaximized
				m.DPIAwareForm.WindowState = 2
			ENDIF

			TRY
				m.DPIAwareForm.DPIAware_AfterScaling(m.DPIAwareForm.DPIScale, m.NewDPIScale)
			CATCH
			ENDTRY

			RETURN 0

		ENDIF

		RETURN -1

	ENDFUNC

	* EnforceFormConstraints
	* Constraints the dimension and position of the form (according to the DPIAutoConstraint property):
	* - DPIAW_RELATIVE_TOP_LEFT form is placed relative top left to its container (_Screen or monitor)
	* - DPIAW_CONSTRAINT_DIMENSION form won't be bigger than the target monitor
	FUNCTION EnforceFormConstraints (DPIAwareForm AS Form)

		LOCAL XYRatio AS Number
		LOCAL NewXYRatio AS Number
		LOCAL OverDimension AS Number
		LOCAL TargetDimension AS Number

		m.XYRatio = This.GetXYRatio(m.DPIAwareForm.DPIScale)
		m.NewXYRatio = This.GetXYRatio(m.DPIAwareForm.DPINewScale)

		IF BITAND(m.DPIAwareForm.DPIAutoConstraint, DPIAW_RELATIVE_TOP_LEFT) != 0
			m.DPIAwareForm.Top = (m.DPIAwareForm.Top / m.XYRatio) * m.NewXYRatio
			m.DPIAwareForm.Left = (m.DPIAwareForm.Left / m.XYRatio) * m.NewXYRatio
		ENDIF

		IF BITAND(m.DPIAwareForm.DPIAutoConstraint, DPIAW_CONSTRAINT_DIMENSION) != 0

			m.Monitor = This.GetMonitorInfo(m.DPIAwareForm.hMonitor, .T.)

			m.OverDimension = m.DPIAwareForm.Width - m.Monitor.Width
			IF m.OverDimension > 0
				m.TargetDimension = m.DPIAwareForm.Width - m.OverDimension
				IF m.DPIAwareForm.MinWidth = -1 OR (m.DPIAwareForm.MinWidth < m.TargetDimension)
					m.DPIAwareForm.Width = m.TargetDimension
				ENDIF
			ENDIF

			m.OverDimension = m.DPIAwareForm.Height - m.Monitor.Height
			IF m.OverDimension > 0
				m.TargetDimension = m.DPIAwareForm.Height - m.OverDimension
				IF m.DPIAwareForm.MinHeight = -1 OR (m.DPIAwareForm.MinHeight < m.TargetDimension)
					m.DPIAwareForm.Height = m.TargetDimension
				ENDIF
			ENDIF

		ENDIF

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_SAVE_ORIGINAL_PROPERTY_VALUES
****************************************************************************************

	* SaveContainer
	* Save the properties of a container object.
	FUNCTION SaveContainer (Ctrl AS Object)

		LOCAL SubCtrl AS Object

		This.SaveOriginalInfo(m.Ctrl)

		FOR EACH m.SubCtrl In m.Ctrl.Controls
			This.SaveControl(m.SubCtrl)
		ENDFOR

	ENDFUNC

	* SaveControl
	* Save the properties of an object.
	FUNCTION SaveControl (Ctrl AS Object)

		LOCAL SubCtrl AS Object

		IF !m.Ctrl.BaseClass $ "Custom,Timer"
			This.SaveOriginalInfo(m.Ctrl)
		ELSE
			RETURN
		ENDIF

		DO CASE 

		CASE m.Ctrl.BaseClass == 'Container'
			This.SaveContainer(m.Ctrl)

		CASE m.Ctrl.BaseClass == 'Pageframe'

			FOR EACH SubCtrl IN m.Ctrl.Pages
				This.SaveContainer(m.SubCtrl)
			ENDFOR

		CASE m.Ctrl.BaseClass == 'Grid'

			FOR EACH SubCtrl IN m.Ctrl.Columns
				This.SaveOriginalInfo(m.SubCtrl)
				This.SaveContainer(m.SubCtrl)
			ENDFOR

		CASE m.Ctrl.BaseClass $ 'Commandgroup,Optiongroup'

			FOR EACH SubCtrl IN m.Ctrl.Buttons
				This.SaveOriginalInfo(m.SubCtrl)
			ENDFOR

		ENDCASE

	ENDFUNC

	* SaveOriginalProperty
	* Saves the original value of a property by creating a DPIAware_<property name> new property.
	FUNCTION SaveOriginalProperty (Ctrl AS Object, Property AS String)

		IF PEMSTATUS(m.Ctrl, m.Property, 5) AND TYPE("m.Ctrl." + m.Property) != "U" AND ! PEMSTATUS(m.Ctrl, "DPIAware_" + m.Property, 5)
			This.AddDPIProperty(m.Ctrl, "DPIAware_" + m.Property, EVALUATE("m.Ctrl." + m.Property))
		ENDIF

	ENDFUNC

	* SaveOriginalInfo
	* Saves the original information of an object (non-existing properties will be ignored).
	FUNCTION SaveOriginalInfo (Ctrl AS Object)

		IF !PEMSTATUS(m.Ctrl, "DPIAware", 5)
			This.AddDPIProperty(m.Ctrl, "DPIAware", .T.)
		ENDIF
		This.SaveOriginalProperty(m.Ctrl, "Anchor")
		This.SaveOriginalProperty(m.Ctrl, "BorderWidth")
		This.SaveOriginalProperty(m.Ctrl, "ColumnWidths")
		This.SaveOriginalProperty(m.Ctrl, "DrawWidth")
		This.SaveOriginalProperty(m.Ctrl, "FontName")
		This.SaveOriginalProperty(m.Ctrl, "FontSize")
		This.SaveOriginalProperty(m.Ctrl, "GridLineWidth")
		This.SaveOriginalProperty(m.Ctrl, "HeaderHeight")
		This.SaveOriginalProperty(m.Ctrl, "Height")
		This.SaveOriginalProperty(m.Ctrl, "Left")
		This.SaveOriginalProperty(m.Ctrl, "Margin")
		This.SaveOriginalProperty(m.Ctrl, "MaxHeight")
		This.SaveOriginalProperty(m.Ctrl, "MaxLeft")
		This.SaveOriginalProperty(m.Ctrl, "MaxTop")
		This.SaveOriginalProperty(m.Ctrl, "MaxWidth")
		This.SaveOriginalProperty(m.Ctrl, "MinHeight")
		This.SaveOriginalProperty(m.Ctrl, "MinWidth")
		This.SaveOriginalProperty(m.Ctrl, "Partition")
		This.SaveOriginalProperty(m.Ctrl, "PictureMargin")
		This.SaveOriginalProperty(m.Ctrl, "PictureSpacing")
		This.SaveOriginalProperty(m.Ctrl, "RowHeight")
		This.SaveOriginalProperty(m.Ctrl, "Top")
		This.SaveOriginalProperty(m.Ctrl, "Width")

		This.SaveGraphicAlternatives(m.Ctrl, "DisabledPicture")
		This.SaveGraphicAlternatives(m.Ctrl, "DownPicture")
		This.SaveGraphicAlternatives(m.Ctrl, "DragIcon")
		This.SaveGraphicAlternatives(m.Ctrl, "Icon")
		This.SaveGraphicAlternatives(m.Ctrl, "MouseIcon")
		This.SaveGraphicAlternatives(m.Ctrl, "Picture")
		This.SaveGraphicAlternatives(m.Ctrl, "PictureVal")

		LOCAL CtrlsForm AS Form

		* if DPI awareness is controlled by the control itself or by its parents, give it the opportunity to save additional information
		IF PEMSTATUS(m.Ctrl, "DPIAwareSelfControl", 5)

			TRY
				DO CASE

				* the control manages itself
				CASE m.Ctrl.DPIAwareSelfControl == 1

					m.Ctrl.DPIAwareSaveOriginalInfo()

				* the form manages the control
				CASE m.Ctrl.DPIAwareSelfControl == 2

					m.CtrlsForm = This.GetThisform(m.Ctrl)
					IF !ISNULL(m.CtrlsForm)
						m.CtrlsForm.DPIAwareSaveOriginalInfo(m.Ctrl)
					ENDIF

				* the _Screen manages the control
				CASE m.Ctrl.DPIAwareSelfControl == 3

					_Screen.DPIAwareScreenManager.DPIAwareSaveOriginalInfo(m.Ctrl)

				ENDCASE
			CATCH				&& ignore any errors, the method may not have been implemented
			ENDTRY

		ENDIF

	ENDFUNC

	* SaveGraphicAlternatives
	* Identifies and saves the alternate graphic properties (Picture, PictureVal, and Icon).
	* Alternative graphics are set at design time in properties to which a DPI scale has been added.
	* For instance, Picture100, Picture125, and Picture150 serve as alternatives to the Picture property
	*   when the DPI scale is 100, 125, and 150 or above.
	FUNCTION SaveGraphicAlternatives (Ctrl AS Object, Property AS String)

		LOCAL AlternativesList AS String
		LOCAL AlternativeLevel AS String
		LOCAL ARRAY Properties[1]
		LOCAL PropertyIndex AS Integer
		LOCAL PropertyCheck AS String
		LOCAL PropertyCheckLen AS Integer
		LOCAL Property100 AS Logical
		LOCAL Level100 AS String

		IF !PEMSTATUS(m.Ctrl, m.Property, 5)
			RETURN
		ENDIF

		m.AlternativesList = ""
		m.PropertyCheck = UPPER(m.Property)
		m.PropertyCheckLen = LEN(m.PropertyCheck)
		m.Property100 = .F.
		m.Level100 = "100"

		* look for all alternatives and create a comma separated list 
		FOR m.PropertyIndex = 1 TO AMEMBERS(m.Properties, m.Ctrl, 0)
			IF LEFT(m.Properties[m.PropertyIndex], m.PropertyCheckLen) == m.PropertyCheck
				m.AlternativeLevel = SUBSTR(m.Properties[m.PropertyIndex], m.PropertyCheckLen + 1)
				IF m.AlternativeLevel == LTRIM(STR(VAL(m.AlternativeLevel))) AND VAL(m.AlternativeLevel) >= DPI_STANDARD_SCALE
					m.AlternativesList = m.AlternativesList + IIF(EMPTY(m.AlternativesList), "", ",") + m.AlternativeLevel
					IF !m.Property100
						m.Property100 = m.AlternativeLevel == m.Level100
					ENDIF
				ENDIF
			ENDIF
		ENDFOR

		* if a list was found, store it in a new object property
		IF !EMPTY(m.AlternativesList)
			* but first make sure there is a version of the graphical alternative for the 100% scale
			* if it was not set explicitly at design time
			IF !m.Property100
				This.AddDPIProperty(m.Ctrl, m.Property + m.Level100, EVALUATE("m.Ctrl." + m.Property))
				m.AlternativesList = m.AlternativesList + "," + m.Level100
			ENDIF
			This.AddDPIProperty(m.Ctrl, "DPIAlternative_" + m.Property, m.AlternativesList)
		ENDIF

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_SCALE_FORMS_AND_CONTROLS
****************************************************************************************

	* Scale
	* Scale a container from one scale to another.
	FUNCTION Scale (Ctnr AS Object, DPIScale AS Number, DPINewScale AS Number, SkipPreAdjust AS Logical)

		LOCAL IsForm AS Logical
		LOCAL SubCtrl AS Object
		LOCAL Scalable AS Logical
		LOCAL AlternativeFont AS DPIAwareAlternativeFont

		* prepare font name alternatives for a new scale
		* aternatives will persist until a new scale is set
		IF m.DPINewScale != This.AlternativeFontNamesScale
			FOR EACH m.AlternativeFont IN This.AlternativeFontNames
				m.AlternativeFont.FindAlternative(m.DPINewScale)
			ENDFOR
			This.AlternativeFontNamesScale = m.DPINewScale
		ENDIF

		m.IsForm = m.Ctnr.BaseClass == 'Form'
		IF m.IsForm
			m.Ctnr.DPIScaling = .T.
			This.SetAnchor(m.Ctnr, .T.)
		ENDIF

		* forms require a pre-adjustement because of the way Windows/VFP(?) pass from one scale to another,
		*   removing a few fixed pixels from the form dimensions (width and height) - this is done automatically as soon
		*   as the DPI scales changes and before the DPIAwareManager has a chance to step in
		IF m.IsForm AND ! m.SkipPreAdjust
			This.PreAdjustFormDimensions(m.Ctnr, m.DPIScale, m.DPINewScale)
		ENDIF

		* if the container is not DPI aware or if it's fully self-controlled, don't touch it
		TRY
			m.Scalable = NVL(m.Ctnr.DPIAware, .F.)
			IF m.Scalable
				m.Scalable = This.SelfScaleControl(m.Ctnr, m.DPIScale, m.DPINewScale)
			ENDIF
		CATCH
			m.Scalable = .F.
		ENDTRY

		IF !m.Scalable
			IF m.IsForm
				This.SetAnchor(m.Ctnr, .F.)
				m.Ctnr.DPIScaling = .F.
			ENDIF
			RETURN
		ENDIF

		* all anchors in a form are set to zero, so that the scale won't trigger the resizing and repositioning of contained controls
		IF m.IsForm

			m.Ctnr.LockScreen = .T.

			* perform the actual resizing of the form
			This.AdjustSize(m.Ctnr, m.DPIScale, m.DPINewScale)

		ENDIF

		* do the resizing for all contained controls
		FOR EACH m.SubCtrl IN m.Ctnr.Controls
			This.ScaleControl(m.SubCtrl, m.DPIScale, m.DPINewScale)
		ENDFOR

		* when a form is finished, get back all anchors
		IF m.IsForm

			This.SetAnchor(m.Ctnr, .F.)
			m.Ctnr.DPIScaling = .F.
			m.Ctnr.LockScreen = .F.

		ENDIF

	ENDFUNC

	* ScaleControl
	* Scales a control from one scale to another.
	FUNCTION ScaleControl (Ctrl AS Object, DPIScale as Number, DPINewScale as Number)

		LOCAL Scalable AS Logical
		LOCAL AutoSizeCtrl AS Logical

		* If the control is not DPI aware or if it is fully self-controlled, don't touch it
		TRY
			m.Scalable = NVL(m.Ctrl.DPIAware, .F.)
			IF m.Scalable
				m.Scalable = This.SelfScaleControl(m.Ctrl, m.DPIScale, m.DPINewScale)
			ENDIF
		CATCH
			m.Scalable = .F.
		ENDTRY

		IF !m.Scalable
			RETURN
		ENDIF

		LOCAL SubCtrl AS Object

		IF PEMSTATUS(m.Ctrl, "AutoSize", 5)
			m.AutoSizeCtrl = m.Ctrl.AutoSize
			m.Ctrl.AutoSize = .F.
		ELSE
			m.AutoSizeCtrl = .F.
		ENDIF

		IF !m.Ctrl.BaseClass $ 'Custom,Timer'
			This.AdjustSize(m.Ctrl, m.DPIScale, m.DPINewScale)
		ENDIF

		DO CASE
		CASE m.Ctrl.BaseClass == 'Container'

			This.Scale(m.Ctrl, m.DPIScale, m.DPINewScale)

		CASE m.Ctrl.BaseClass == 'Pageframe'

			* the pageframe is already scaled, but scaling pages may still affect the pageframe size
			LOCAL TabSize AS Number, NewTabSize AS Number
			m.TabSize = 0
			WITH m.Ctrl AS PageFrame
				* if the pageframe has tabs, get their current size before being scaled by the Pages
				IF .Tabs
					IF BITAND(.TabOrientation, 0x02) != 0
						m.TabSize = .Width - .PageWidth
					ELSE
						m.TabSize = .Height - .PageHeight
					ENDIF
				ENDIF
			ENDWITH

			FOR EACH m.SubCtrl AS Page IN m.Ctrl.Pages
				This.AdjustSize(m.SubCtrl, m.DPIScale, m.DPINewScale)
				This.Scale(m.SubCtrl, m.DPIScale, m.DPINewScale)
			ENDFOR

			* recover the size of the pageframe by compensating for what the tabs scaling may have added or cut
			IF m.TabSize != 0
				WITH m.Ctrl AS PageFrame
					IF BITAND(.TabOrientation, 0x02) != 0
						m.NewTabSize = .Width - .PageWidth
						.Width = .Width - (m.NewTabSize - m.TabSize)
					ELSE
						m.NewTabSize = .Height - .PageHeight
						.Height = .Height - (m.NewTabSize - m.TabSize)
					ENDIF
				ENDWITH
			ENDIF

		CASE m.Ctrl.BaseClass == 'Grid'

			* for a grid, calculate the weight of the fixed size elements
			LOCAL FixedWeight AS Number, FutureWidth AS Number
			m.FixedWeight = 0
			WITH m.Ctrl AS Grid
				IF .RecordMark
					m.FixedWeight = 10
				ENDIF
				IF .DeleteMark
					m.FixedWeight = m.FixedWeight + 8
				ENDIF
				IF BITAND(.ScrollBars, 0x02) != 0
					m.FixedWeight = m.FixedWeight + SYSMETRIC(5) + 1
				ENDIF
				m.FixedWeight = m.FixedWeight + .ColumnCount * .GridLineWidth + 2		&& grid's border width

				* calculate how the fixed size elements impact the size of the columns
				* growing will add extra size (as a proportion) to each column
				m.FutureWidth = ROUND(.Width / This.GetXYRatio(m.DPIScale) * This.GetXYRatio(m.DPINewScale), 0)
				m.FixedWeight =  (m.FutureWidth - m.FixedWeight) / (.Width - m.FixedWeight) - (m.DPINewScale / m.DPIScale)

			ENDWITH

			FOR EACH m.SubCtrl AS Column IN m.Ctrl.Columns
				* the column will have extra plus or minus space, since some components of the grid width do not scale
				This.AdjustSize(m.SubCtrl, m.DPIScale, m.DPINewScale, m.FixedWeight)
				This.Scale(m.SubCtrl, m.DPIScale, m.DPINewScale)
			ENDFOR

		CASE m.Ctrl.BaseClass $ 'Commandgroup,Optiongroup'

			FOR EACH m.SubCtrl In m.Ctrl.Buttons
				This.AdjustSize(m.SubCtrl, m.DPIScale, m.DPINewScale)
			ENDFOR

		ENDCASE

		IF m.AutoSizeCtrl
			m.Ctrl.AutoSize = .T.
		ENDIF

	ENDFUNC

	* SelfScaleControl
	* Checks if the scale of the control is processed by the control itself.
	* If it returns .T., the manager will continue for the control; if .F., stops the scale process for the container. 
	FUNCTION SelfScaleControl (Ctrl AS Object, DPIScale AS Integer, DPINewScale AS Integer) AS Logical

		LOCAL CtrlsForm AS Form

		* if DPI awareness is controlled by the container itself, just pass the process to the container
		IF PEMSTATUS(m.Ctrl, "DPIAwareSelfControl", 5)

			DO CASE

			* the scale process is made by the control itself
			CASE m.Ctrl.DPIAwareSelfControl = 1

				RETURN m.Ctrl.DPIAwareSelfManager(m.DPIScale, m.DPINewScale)

			* the scale process is made by the form
			CASE m.Ctrl.DPIAwareSelfControl = 2

				m.CtrlsForm = This.GetThisform(m.Ctrl)
				IF !ISNULL(m.CtrlsForm)
					RETURN m.CtrlsForm.DPIAwareControlsManager(m.DPIScale, m.DPINewScale, m.Ctrl)
				ENDIF

			* the scale process is made by the _Screen
			CASE m.Ctrl.DPIAwareSelfControl = 3

				RETURN _Screen.DPIAwareScreenManager.DPIAwareControlsManager(m.DPIScale, m.DPINewScale, m.Ctrl)

			ENDCASE

		ENDIF

		* the DPI manager process the control
		RETURN .T.

	ENDFUNC

	* SetAnchor
	* Sets or unsets (sets to zero) the property Anchor of a container and of its contained controls. 
	FUNCTION SetAnchor (Cntr AS Object, Unset AS Logical)

		LOCAL SubCtrl AS Object

		FOR EACH m.SubCtrl IN m.Cntr.Controls
			This.SetAnchorControl(m.SubCtrl, m.Unset)
		ENDFOR

	ENDFUNC

	* SetAnchorControl
	* Sets or unsets (sets to zero) the property Anchor of a control. 
	FUNCTION SetAnchorControl (Ctrl AS Object, Unset AS Logical)

		LOCAL SubCtrl AS Object

		TRY
			m.Ctrl.Anchor = IIF(m.Unset, 0, m.Ctrl.DPIAWare_Anchor)
		CATCH
		ENDTRY

		DO CASE
		CASE m.Ctrl.BaseClass == 'Container'

			This.SetAnchor(m.Ctrl, m.Unset)

		CASE m.Ctrl.BaseClass == 'Pageframe'

			FOR EACH m.SubCtrl AS Page IN m.Ctrl.Pages
				This.SetAnchor(m.SubCtrl, m.Unset)
			ENDFOR

		CASE m.Ctrl.BaseClass == 'Grid'

			FOR EACH m.SubCtrl AS Column IN m.Ctrl.Columns
				This.SetAnchor(m.SubCtrl, m.Unset)
			ENDFOR 

		CASE m.Ctrl.BaseClass $ 'Commandgroup,Optiongroup'

			FOR EACH m.SubCtrl IN m.Ctrl.Buttons
				This.SetAnchorControl(m.SubCtrl, m.Unset)
			ENDFOR

		ENDCASE

	ENDFUNC

	* PreAdjustFormDimensions
	* Pre-adjusts form dimensions (width and height) - Windows (and/or VFP?) seems to cut a fixed amount of
	*   pixels when moving from one scale to the other.
	FUNCTION PreAdjustFormDimensions (Ctrl AS Form, DPIScale AS Number, NewDPIScale AS Number)

		* but only for top-level forms or non-sizeable forms
		IF (m.Ctrl.ShowWindow == 2 OR m.Ctrl == _Screen) OR m.Ctrl.BorderStyle != 3
		
			LOCAL Scale AS Integer
			LOCAL WidthAdjustment AS Integer
			LOCAL HeightAdjustment AS Integer

			* scale level: 0 = 100, 1 = 125, 2 = 150, etc.
			m.Scale = This.GetDPILevel(m.NewDPIScale)
			m.WidthAdjustment = VAL(GETWORDNUM(This.WidthAdjustments, m.Scale, ","))
			m.HeightAdjustment = VAL(GETWORDNUM(This.HeightAdjustments, m.Scale, ","))

			* add the adjustments to the cutted dimensions, to compensate for the cutting 
			m.Ctrl.Width = m.Ctrl.Width + m.WidthAdjustment
			m.Ctrl.Height = m.Ctrl.Height + m.HeightAdjustment

			m.Scale = This.GetDPILevel(m.DPIScale)
			m.WidthAdjustment = VAL(GETWORDNUM(This.WidthAdjustments, m.Scale, ","))
			m.HeightAdjustment = VAL(GETWORDNUM(This.HeightAdjustments, m.Scale, ","))

			* but remove the adjustments made previously
			m.Ctrl.Width = m.Ctrl.Width - m.WidthAdjustment
			m.Ctrl.Height = m.Ctrl.Height - m.HeightAdjustment

		ENDIF

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_ADJUST_DIMENSION_AND_PROPERTIES_TO_NEW_SCALE
****************************************************************************************

	* AdjustSize
	* Adjusts the size and position of a control from a scale to another.
	Function AdjustSize (Ctrl AS Object, DPIScale as Number, NewDPIScale AS Number, ExtraWidthRatio AS Number)

		LOCAL IsForm AS Logical

		LOCAL XYRatio AS Number, NewXYRatio AS Number

		LOCAL IsGrowing AS Logical

		* XY ratios are the multipliers for both scales
		m.XYRatio = This.GetXYRatio(m.DPIScale)
		m.NewXYRatio = This.GetXYRatio(m.NewDPIScale)

		* how are we growing?
		m.IsGrowing = m.DPIScale < m.NewDPIScale

		m.IsForm = m.Ctrl.BaseClass == "Form"
		IF m.IsForm
			This.AdjustFixedPropertyValue(m.Ctrl, "MaxTop", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustFixedPropertyValue(m.Ctrl, "MaxLeft", m.XYRatio, m.NewXYRatio, -1)
		ENDIF

		IF ! m.Ctrl.BaseClass == "Grid"
			* if we are not growing, calculate the margin and border first to arrange more space for the text
			IF !m.IsGrowing
				This.AdjustFixedPropertyValue(m.Ctrl, "Margin", m.XYRatio, m.NewXYRatio, .NULL., .T.)
				This.AdjustFixedPropertyValue(m.Ctrl, "PictureMargin", m.XYRatio, m.NewXYRatio, .NULL., .T.)
				This.AdjustFixedPropertyValue(m.Ctrl, "PictureSpacing", m.XYRatio, m.NewXYRatio, .NULL., .T.)
				This.AdjustFixedPropertyValue(m.Ctrl, "BorderWidth", m.XYRatio, m.NewXYRatio, .NULL., .T.)
			ENDIF
			* adjust the font name before adjusting its size
			This.AdjustFontNameAlternative(m.Ctrl)
			* adjust font size always from its original setting (hence, taken as a "fixed" property)
			This.AdjustFixedPropertyValue(m.Ctrl, "FontSize", m.XYRatio, m.NewXYRatio)
			* if it is growing, margins are arranged afterward
			IF m.IsGrowing
				This.AdjustFixedPropertyValue(m.Ctrl, "BorderWidth", m.XYRatio, m.NewXYRatio, .NULL., .T.)
				This.AdjustFixedPropertyValue(m.Ctrl, "PictureSpacing", m.XYRatio, m.NewXYRatio, .NULL., .T.)
				This.AdjustFixedPropertyValue(m.Ctrl, "PictureMargin", m.XYRatio, m.NewXYRatio, .NULL., .T.)
				This.AdjustFixedPropertyValue(m.Ctrl, "Margin", m.XYRatio, m.NewXYRatio, .NULL., .T.)
			ENDIF
		ELSE
			* grids:
			* row height and header height, unless they're marked as Auto
			This.AdjustPropertyValue(m.Ctrl, "RowHeight", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustPropertyValue(m.Ctrl, "HeaderHeight", m.XYRatio, m.NewXYRatio, -1)
			* other properties
			This.AdjustFixedPropertyValue(m.Ctrl, "Partition", m.XYRatio, m.NewXYRatio, 0)
			This.AdjustFixedPropertyValue(m.Ctrl, "GridLineWidth", m.XYRatio, m.NewXYRatio)
		ENDIF

		* if we are growing, make sure we grow maximum dimensions before growing
		IF m.IsGrowing
			This.AdjustFixedPropertyValue(m.Ctrl, "MaxWidth", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustFixedPropertyValue(m.Ctrl, "MaxHeight", m.XYRatio, m.NewXYRatio, -1)
			IF PCOUNT() < 4
				This.AdjustPropertyValue(m.Ctrl, "Width", m.XYRatio, m.NewXYRatio)
			ELSE
				This.AdjustPropertyValue(m.Ctrl, "Width", m.XYRatio, m.NewXYRatio, .NULL., m.ExtraWidthRatio)
			ENDIF
			This.AdjustPropertyValue(m.Ctrl, "Height", m.XYRatio, m.NewXYRatio)
			This.AdjustFixedPropertyValue(m.Ctrl, "MinWidth", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustFixedPropertyValue(m.Ctrl, "MinHeight", m.XYRatio, m.NewXYRatio, -1)
		* or the other way around, if shrinking
		ELSE
			This.AdjustFixedPropertyValue(m.Ctrl, "MinWidth", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustFixedPropertyValue(m.Ctrl, "MinHeight", m.XYRatio, m.NewXYRatio, -1)
			IF PCOUNT() < 4
				This.AdjustPropertyValue(m.Ctrl, "Width", m.XYRatio, m.NewXYRatio)
			ELSE
				This.AdjustPropertyValue(m.Ctrl, "Width", m.XYRatio, M.NewXYRatio, .NULL., m.ExtraWidthRatio)
			ENDIF
			This.AdjustPropertyValue(m.Ctrl, "Height", m.XYRatio, m.NewXYRatio)
			This.AdjustFixedPropertyValue(m.Ctrl, "MaxWidth", m.XYRatio, m.NewXYRatio, -1)
			This.AdjustFixedPropertyValue(m.Ctrl, "MaxHeight", m.XYRatio, m.NewXYRatio, -1)
		ENDIF

		* for all controls except forms, deal with their position
		IF ! m.IsForm
			This.AdjustPropertyValue(m.Ctrl, "Top", m.XYRatio, m.NewXYRatio)
			This.AdjustPropertyValue(m.Ctrl, "Left", m.XYRatio, m.NewXYRatio)
		ENDIF

		* process other positional or dimensional properties
		This.AdjustFixedPropertyValue(m.Ctrl, "DrawWidth", m.XYRatio, m.NewXYRatio, .NULL., .T.)
		This.AdjustFixedPropertyValue(m.Ctrl, "ColumnWidths", m.XYRatio, m.NewXYRatio)

		* take care of the alternate graphics the control may have defined for the new scale
		This.AdjustGraphicAlternatives(m.Ctrl, m.NewDPIScale)

		* reset the form's icon
		IF m.IsForm
			This.ResetIcon(m.Ctrl)
		ENDIF

	ENDFUNC

	* AdjustPropertyValue
	* Adjusts the current value of a property to a new value.
	FUNCTION AdjustPropertyValue (Ctrl AS Object, Property AS String, Ratio AS Number, NewRatio AS Number, Excluded AS Number, ExtraRatio AS Number) AS Logical

		LOCAL CtrlProperty AS String
		LOCAL Adjusted AS Logical
		LOCAL OriginalValue AS Number
		LOCAL CurrentValue AS Number
		LOCAL NewCurrentValue AS Number
		LOCAL NewAdjustedRatio AS Number

		m.Adjusted = .F.

		IF PEMSTATUS(m.Ctrl, "DPIAware_" + m.Property, 5)
			TRY
				* regular properties are scaled from the current value
				* unless they are excluded for being automatic or unset
				m.OriginalValue = EVALUATE("m.Ctrl.DPIAware_" + m.Property)
				IF PCOUNT() < 5 OR ISNULL(m.Excluded) OR m.Excluded != m.OriginalValue

					* get the current value, stored in the property, and calculate the new one for a new scale
					m.CtrlProperty = "m.Ctrl." + m.Property
					m.CurrentValue = EVALUATE(m.CtrlProperty)
					IF PCOUNT() < 6
						m.NewAdjustedRatio = m.NewRatio
					ELSE
						m.NewAdjustedRatio = m.NewRatio + m.ExtraRatio
					ENDIF
					m.NewCurrentValue = m.CurrentValue / m.Ratio * m.NewAdjustedRatio

					* store the final (rounded) value
					STORE ROUND(m.NewCurrentValue, 0) TO (m.CtrlProperty)

					m.Adjusted = .T.

					* log the adjustment
					IF This.Logging
						This.Log(m.Ctrl.Name, m.Ctrl.Class, m.Property, TRANSFORM(m.OriginalValue), m.Ratio, m.NewAdjustedRatio, .F., ;
							TRANSFORM(m.CurrentValue), TRANSFORM(m.NewCurrentValue), TRANSFORM(EVALUATE(m.CtrlProperty)))
					ENDIF

				ENDIF
			CATCH
			ENDTRY
		ENDIF

		RETURN m.Adjusted

	ENDFUNC

	* AdjustFixedPropertyValue
	* Adjusts the original value of a property to a new value.
	FUNCTION AdjustFixedPropertyValue (Ctrl AS Object, Property AS String, Ratio AS Number, NewRatio AS Number, Excluded AS Number, Low AS Logical) AS Logical

		LOCAL CtrlProperty AS String
		LOCAL Adjusted AS Logical
		LOCAL OriginalValue AS NumberOrString
		LOCAL NewCurrentValue AS NumberOrString
		LOCAL ARRAY ValuesList[1]
		LOCAL ValueIndex AS Integer
		LOCAL MemberValue AS Number

		m.Adjusted = .F.

		IF PEMSTATUS(m.Ctrl, "DPIAware_" + m.Property, 5)
			TRY

				* fixed properties are scaled from the original value
				* unless they are excluded for being automatic or unset
				m.OriginalValue = EVALUATE("m.Ctrl.DPIAware_" + m.Property)
				IF PCOUNT() < 5 OR ISNULL(m.Excluded) OR m.Excluded != m.OriginalValue

					* the destination of the new value
					m.CtrlProperty = "m.Ctrl." + m.Property

					* for most cases, properties are numeric
					IF VARTYPE(m.OriginalValue) == "N"

						* calculate the new value
						m.NewCurrentValue = m.OriginalValue * m.NewRatio

						* store the final (rounded or truncated) value
						IF !m.Low
							STORE ROUND(m.NewCurrentValue, 0) TO (m.CtrlProperty)
						ELSE
							STORE FLOOR(m.NewCurrentValue) TO (m.CtrlProperty)
						ENDIF

					* string properties consist in a comma-separated list of numbers
					ELSE

						* prepare to rebuild the list
						m.NewCurrentValue = ""

						* adjust every member of the list
						FOR m.ValueIndex = 1 TO ALINES(m.ValuesList, m.OriginalValue, 0, ",")

							m.MemberValue = VAL(m.ValuesList[m.ValueIndex]) * m.NewRatio

							IF m.Low
								m.NewCurrentValue = m.NewCurrentValue + LTRIM(STR(FLOOR(m.MemberValue))) + ","
							ELSE
								m.NewCurrentValue = m.NewCurrentValue + LTRIM(STR(ROUND(m.MemberValue, 0))) + ","
							ENDIF

						ENDFOR

						* store the list with new values
						m.NewCurrentValue = RTRIM(m.NewCurrentValue, 0, ",")
						STORE m.NewCurrentValue TO (m.CtrlProperty)

					ENDIF

					m.Adjusted = .T.

					* log the adjustment
					IF This.Logging
						This.Log(m.Ctrl.Name, m.Ctrl.Class, m.Property, TRANSFORM(m.OriginalValue), m.Ratio, m.NewAdjustedRatio, .F., ;
							TRANSFORM(m.CurrentValue), TRANSFORM(m.NewCurrentValue), TRANSFORM(EVALUATE(m.CtrlProperty)))
					ENDIF

				ENDIF
			CATCH
			ENDTRY
		ENDIF

		RETURN m.Adjusted

	ENDFUNC

	* AdjustFontNameAlternative
	* Adjusts the name of a font by using the appropriate alternative
	FUNCTION AdjustFontNameAlternative (Ctrl AS Object)

		LOCAL AlternativeFontName AS String
		LOCAL FontNameKey AS String
		LOCAL FontIndex AS Integer

		IF PEMSTATUS(m.Ctrl, "DPIAware_FontName", 5)
			m.FontNameKey = UPPER(m.Ctrl.DPIAware_FontName)
			m.FontIndex = 0
			* use the original font name to locate the current alternative
			* try to locate the best alternative for the font style
			TRY
				IF m.Ctrl.FontBold AND m.Ctrl.FontItalic
					m.FontIndex = This.AlternativeFontNames.GetKey(m.FontNameKey + ",BI")
				ENDIF
				IF m.FontIndex == 0 AND m.Ctrl.FontBold
					m.FontIndex = This.AlternativeFontNames.GetKey(m.FontNameKey + ",B")
				ENDIF
				IF m.FontIndex == 0 AND m.Ctrl.FontItalic
					m.FontIndex = This.AlternativeFontNames.GetKey(m.FontNameKey + ",I")
				ENDIF
				IF m.FontIndex == 0 AND !m.Ctrl.FontBold AND !m.Ctrl.FontItalic
					m.FontIndex = This.AlternativeFontNames.GetKey(m.FontNameKey + ",N")
				ENDIF
			CATCH
			ENDTRY
			* try an unstyled alternative, if a styled one was not found
			m.FontIndex = EVL(m.FontIndex, This.AlternativeFontNames.GetKey(m.FontNameKey))
			* if it exists
			IF m.FontIndex != 0
				TRY
					* set it, if needed
					m.AlternativeFontName = This.AlternativeFontNames.Item(m.FontIndex).AlternativeFontName
					IF ! m.Ctrl.FontName == m.AlternativeFontName
						m.Ctrl.FontName = m.AlternativeFontName
					ENDIF
				CATCH
				ENDTRY
			ENDIF
		ENDIF

	ENDFUNC
		
	* AdjustGraphicAlternatives
	* Adjusts the value of graphic properties by selecting an appropriate alternative.
	FUNCTION AdjustGraphicAlternatives (Ctrl AS Object, NewDPIScale AS Number)

		This.FindGraphicAlternative(m.Ctrl, "Picture", m.NewDPIScale)
		This.FindGraphicAlternative(m.Ctrl, "PictureVal", m.NewDPIScale)
		This.FindGraphicAlternative(m.Ctrl, "Icon", m.NewDPIScale)
		This.FindGraphicAlternative(m.Ctrl, "MouseIcon", m.NewDPIScale)
		This.FindGraphicAlternative(m.Ctrl, "DragIcon", m.NewDPIScale)
		This.FindGraphicAlternative(m.Ctrl, "DisabledPicture", m.NewDPIScale)
		This.FindGraphicAlternative(m.Ctrl, "DownPicture", m.NewDPIScale)

	ENDFUNC

	* FindGraphicAlternative
	* Finds a best alternative graphic for the new scale.
	FUNCTION FindGraphicAlternative (Ctrl AS Object, Property AS String, DPIScale AS Number)

		LOCAL CtrlProperty AS String
		LOCAL Alternatives AS String
		LOCAL ARRAY AlternativeScales[1]
		LOCAL AlternativesIndex AS Integer
		LOCAL BestAlternative AS String
		LOCAL BestDifference AS Integer, Difference AS Integer

		* if there isn't an alternative list, quit looking into it
		m.Alternatives = "DPIAlternative_" + m.Property
		IF !PEMSTATUS(m.Ctrl, m.Alternatives, 5)
			RETURN
		ENDIF

		m.CtrlProperty = "m.Ctrl." + m.Property
		BestDifference = -1
		BestAlternative = ""

		* go through the list of scales for which there is an alternative
		FOR m.AlternativesIndex = 1 TO ALINES(m.AlternativeScales, EVALUATE("m.Ctrl." + m.Alternatives), 0, ",")

			* calculate the difference for the new scale
			m.Difference = VAL(m.AlternativeScales[m.AlternativesIndex]) - m.DPIScale

			* there is a match! get the value in the alternate graphic property and stop searching
			IF m.Difference = 0
				m.BestAlternative = EVALUATE(m.CtrlProperty + m.AlternativeScales[m.AlternativesIndex])
				EXIT
			ENDIF

			* but if not and this one was the best yet, use it and continue looking
			IF m.Difference > 0 AND (m.BestDifference < 0 OR m.Difference < m.BestDifference)
				m.BestAlternative = EVALUATE(m.CtrlProperty + m.AlternativeScales[m.AlternativesIndex])
				m.BestDifference = m.Difference
			ENDIF
		ENDFOR

		* if we found an alternative, that will be the new value for the property
		IF !EMPTY(m.BestAlternative)
			STORE m.BestAlternative TO (m.CtrlProperty)
		ENDIF

	ENDFUNC

	* ResetIcon
	* Reset the icon for (hopefully) better quality
	FUNCTION ResetIcon (Ctrl AS Object)

		LOCAL SafetyStatus AS String
		LOCAL IconFile AS String
		LOCAL hIcon AS Integer

		* only for Forms
		IF !m.Ctrl.BaseClass == "Form" OR EMPTY(m.Ctrl.Icon)
			RETURN
		ENDIF
			
		m.SafetyStatus = SET("Safety")
		SET SAFETY OFF

		* use a temporary file to make sure Windows sees the icon
		m.IconFile = ADDBS(SYS(2023)) + "~dpiawm" + SYS(3) + ".ico"
		TRY
			STRTOFILE(FILETOSTR(m.Ctrl.Icon), m.IconFile)
		CATCH
			m.IconFile = ""
		ENDTRY

		IF m.SafetyStatus == "ON"
			SET SAFETY ON
		ENDIF

		IF !EMPTY(m.IconFile)
			* success in creating the file? get the icon from the temporary file and reset it
			m.hIcon = dpiaw_ExtractIcon(0, m.IconFile, 0)
			dpiaw_SendMessage(m.Ctrl.hWnd, WM_SETICON, ICON_SMALL, m.hIcon)
			* use it also for the "big" version of top level forms
			IF m.Ctrl == _Screen OR m.Ctrl.ShowWindow == 2
				dpiaw_SendMessage(m.Ctrl.hWnd, WM_SETICON, ICON_BIG, m.hIcon)
			ENDIF
			* clean up
			TRY
				ERASE (m.IconFile)
			CATCH
			ENDTRY
		ENDIF

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_HELPERS
****************************************************************************************

	* AddControl
	* Adds a control in run-time (scaled at 96/100%)
	FUNCTION AddControl (NewControl AS Object)

		This.SaveControl(m.NewControl)
		This.ScaleControl(m.NewControl, DPI_STANDARD_SCALE, This.GetFormDPIScale(m.NewControl))

	ENDFUNC

****************************************************************************************
#DEFINE METHODS_UTILITIES
****************************************************************************************

	* GetThisform
	* Returns the form to which an object belongs.
	FUNCTION GetThisform (Ctrl AS Object) AS Integer

		LOCAL ThisObject AS Object

		* look for a form in the (parent) hierarchy of the object
		m.ThisObject = m.Ctrl
		DO WHILE !m.ThisObject.BaseClass == "Form" AND PEMSTATUS(m.ThisObject, "Parent", 5)
			m.ThisObject = m.ThisObject.Parent
		ENDDO

		RETURN IIF(m.ThisObject.BaseClass == "Form", m.ThisObject, .NULL.)
			
	ENDFUNC

	* AddDPIProperty
	* Adds a DPI-awareness related property to an object (fails silently)
	FUNCTION AddDPIProperty (Ctrl AS Object, Property AS String, InitialValue) AS Void

		TRY
			m.Ctrl.AddProperty(m.Property, m.InitialValue)
		CATCH
		ENDTRY

	ENDFUNC

	* Log
	* Logs a scale operation
	FUNCTION Log (ControlName AS String, ClassName AS String, Property AS String, ;
				Original AS String, Ratio AS Double, NewRatio AS Double, ;
				FixedProperty AS Logical, ;
				ScaledBefore AS String, Calculated AS String, Stored AS String)

	ENDFUNC

	* GetXYRatio
	* Gets a ratio multiplier, given a scale
	FUNCTION GetXYRatio (Scale AS Integer) AS Number

		RETURN m.Scale / DPI_STANDARD_SCALE

	ENDFUNC

	* GetDPILevel
	* Gets the DPI level (0, 1, 2...) given a scale.
	FUNCTION GetDPILevel (DPIScale AS Integer) AS Integer

		RETURN ROUND((m.DPIScale - DPI_STANDARD_SCALE) / DPI_SCALE_INCREMENT, 0)

	ENDFUNC

	* GetScaledValue
	* Scale a value, given a scale
	FUNCTION GetScaledValue (Unscaled AS Number, Scale AS Integer) AS Number

		RETURN m.Unscaled * This.GetXYRatio(m.Scale)

	ENDFUNC

	* GetUnscaledValue
	* Unscale a value, given a scale
	FUNCTION GetUnscaledValue (Scaled AS Number, Scale AS Integer) AS Number

		RETURN m.Scaled / This.GetXYRatio(m.Scale)

	ENDFUNC

ENDDEFINE

* DPIAwareAlternativeFont
* A class to register alternative fonts depending on the scale
DEFINE CLASS DPIAwareAlternativeFont AS Custom

	AlternativeCount = 0
	DIMENSION Scales [1]
	DIMENSION FontNames [1]

	AlternativeFontName = ""

	FUNCTION Init (BaseFontName AS String)

		This.AlternativeCount = 1
		This.Scales[1] = 100
		* discard the style clause to set the base font name
		This.FontNames[1] = LEFT(m.BaseFontName, EVL(RAT(",", m.BaseFontName), LEN(m.BaseFontName) + 1) - 1)

	ENDFUNC

	FUNCTION AddAlternative (Scale AS Integer, AlternativeFontName AS String)

		This.AlternativeCount = This.AlternativeCount + 1
		DIMENSION This.Scales[This.AlternativeCount]
		DIMENSION This.FontNames[This.AlternativeCount]
		This.Scales[This.AlternativeCount] = m.Scale
		This.FontNames[This.AlternativeCount] = m.AlternativeFontName

	ENDFUNC

	FUNCTION FindAlternative (DPIScale AS Integer)

		LOCAL AltIndex AS Integer
		LOCAL BestAlternative AS Integer
		LOCAL Difference AS Integer
		LOCAL BestDifference AS Integer

		m.BestAlternative = 1
		m.BestDifference = -1

		FOR m.AltIndex = 1 TO This.AlternativeCount
			m.Difference = m.DPIScale - This.Scales[m.AltIndex]
			IF m.Difference == 0
				m.BestAlternative = m.AltIndex
				EXIT
			ENDIF
			IF m.Difference > 0
				IF m.BestDifference == -1 OR m.Difference < m.BestDifference
					m.BestDifference = m.Difference
					m.BestAlternative = m.AltIndex
				ENDIF
			ENDIF
		ENDFOR

		This.AlternativeFontName = This.FontNames[m.BestAlternative]

		RETURN This.AlternativeFontName

	ENDFUNC

ENDDEFINE
			

* DPIAwareScreenManager
* An extension manager for the _Screen object.
DEFINE CLASS DPIAwareScreenManager AS Custom

	FUNCTION DPIAwareControlsManager(DPIScale AS Integer, DPINewScale AS Integer, Ctrl AS Object)
		RETURN .F.
	ENDFUNC

	FUNCTION SelfManage (DPIScale AS Integer, DPINewScale AS Integer)
		RETURN .F.
	ENDFUNC

	FUNCTION DPIAwareSaveOriginalInfo (Ctrl AS Object)
		RETURN .T.
	ENDFUNC

ENDDEFINE
